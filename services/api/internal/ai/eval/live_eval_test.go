//go:build live_eval

package eval_test

import (
	"context"
	"os"
	"strings"
	"testing"
	"time"

	"github.com/clarafin/api/internal/adapter/gemini"
	"github.com/clarafin/api/internal/ai"
)

func TestLiveGeminiEvalSuite_RepresentativeCases(t *testing.T) {
	apiKey := strings.TrimSpace(os.Getenv("GEMINI_API_KEY"))
	if apiKey == "" {
		t.Skip("GEMINI_API_KEY is not set; skipping live_eval test")
	}

	model := strings.TrimSpace(os.Getenv("GEMINI_MODEL"))
	if model == "" {
		model = "gemini-2.5-flash"
	}

	txStore, tx, ctx := openEvalTxStore(t)
	wib := time.FixedZone("WIB", 7*3600)
	fixedNow := time.Date(2026, 11, 23, 8, 0, 0, 0, wib)
	nowFn := func() time.Time { return fixedNow }

	userID := seedEvalUserWithActiveWallets(t, ctx, txStore, tx, fixedNow)

	geminiClient, err := gemini.NewClient(ctx, gemini.Config{
		APIKey:              apiKey,
		DefaultModel:        model,
		ContextCacheEnabled: false,
	})
	if err != nil {
		t.Fatalf("gemini.NewClient failed: %v", err)
	}

	finTools := ai.NewFinancialTools(
		txStore,
		ai.WithFinancialNowFunc(nowFn),
		ai.WithFinancialJakartaLocation(wib),
	)
	actTools := ai.NewActionTools(
		txStore,
		ai.WithActionNowFunc(nowFn),
		ai.WithActionJakartaLocation(wib),
		ai.WithActionFinancialTools(finTools),
	)
	matchTools := ai.NewMatchingTool(
		txStore,
		ai.WithMatchingNowFunc(nowFn),
		ai.WithMatchingJakartaLocation(wib),
	)
	draftRepo := &txAIDraftRepo{store: txStore}
	quota := &evalQuotaManager{}

	orch := ai.NewOrchestrator(ai.OrchestratorConfig{
		Model:      model,
		LLM:        geminiClient,
		Quota:      quota,
		Financial:  finTools,
		Actions:    actTools,
		Matching:   matchTools,
		DraftRepo:  draftRepo,
		NowFunc:    nowFn,
		JakartaLoc: wib,
	})

	liveCases := []struct {
		id          string
		surfaceMode string
		prompt      string
		verify      func(t *testing.T, res *ai.ChatResult, elapsed time.Duration)
	}{
		{
			id:          "Live-01-Greeting",
			surfaceMode: "quick_sheet",
			prompt:      "Halo Clarafin!",
			verify: func(t *testing.T, res *ai.ChatResult, elapsed time.Duration) {
				if !res.IsPrefiltered {
					t.Fatalf("expected IsPrefiltered=true for greeting")
				}
				if elapsed > 10*time.Millisecond {
					t.Fatalf("expected prefilter latency < 10ms, got %s", elapsed)
				}
			},
		},
		{
			id:          "Live-02-SlangMultiItem",
			surfaceMode: "quick_sheet",
			prompt:      "kopi kenangan 25k + parkir goceng pake gopay",
			verify: func(t *testing.T, res *ai.ChatResult, _ time.Duration) {
				if res.Response.TransactionDraft == nil {
					t.Fatalf("expected TransactionDraft for slang multi-item, got nil (narrative=%q)", res.Response.Narrative)
				}
				if res.Response.TransactionDraft.TotalAmountIDR != 30000 || len(res.Response.TransactionDraft.Items) != 2 {
					t.Fatalf("unexpected TransactionDraft: %+v", res.Response.TransactionDraft)
				}
			},
		},
		{
			id:          "Live-03-MissingWalletBankJago",
			surfaceMode: "quick_sheet",
			prompt:      "abis makan siang 45rb pake bank jago",
			verify: func(t *testing.T, res *ai.ChatResult, _ time.Duration) {
				if res.Response.TransactionDraft != nil {
					t.Fatalf("TransactionDraft must be withheld when Bank Jago is missing, got %+v", res.Response.TransactionDraft)
				}
				if res.Response.WalletCreationDraft == nil || res.Response.WalletCreationDraft.InstitutionID != "jago" {
					t.Fatalf("expected WalletCreationDraft for jago, got %+v", res.Response.WalletCreationDraft)
				}
			},
		},
		{
			id:          "Live-04-OneShotGoal",
			surfaceMode: "full_screen",
			prompt:      "buatin goal dana darurat 30jt target 10 bulan lagi prioritas urgent",
			verify: func(t *testing.T, res *ai.ChatResult, _ time.Duration) {
				if res.Response.GoalDraft == nil {
					t.Fatalf("expected GoalDraft, got nil (narrative=%q)", res.Response.Narrative)
				}
				if res.Response.GoalDraft.TargetAmountIDR != 30000000 || res.Response.GoalDraft.MonthlySavingEstimateIDR != 3000000 {
					t.Fatalf("unexpected GoalDraft: %+v", res.Response.GoalDraft)
				}
			},
		},
		{
			id:          "Live-05-GeneralKnowledgeTaxUMKM",
			surfaceMode: "full_screen",
			prompt:      "aturan pajak PPh Final UMKM 0,5% menurut PP 55 Tahun 2022 itu gimana?",
			verify: func(t *testing.T, res *ai.ChatResult, _ time.Duration) {
				if forbiddenTickerRegexp.MatchString(res.Response.Narrative) {
					t.Fatalf("narrative contained forbidden stock ticker or product advice: %q", res.Response.Narrative)
				}
				if len(res.Response.RecommendedConsultants) != 0 || res.Response.RecommendedPackage != nil {
					t.Fatalf("expected no consultant cards for general knowledge query")
				}
			},
		},
		{
			id:          "Live-06-DeepPaylaterMatching",
			surfaceMode: "full_screen",
			prompt:      "cicilan paylater dan pinjolku udah 40% dari gaji, enaknya dilunasin yang mana dulu?",
			verify: func(t *testing.T, res *ai.ChatResult, _ time.Duration) {
				if res.Response.RecommendedPackage == nil {
					t.Fatalf("expected RecommendedPackage for deep paylater question, got nil")
				}
				if len(res.Response.RecommendedConsultants) == 0 || len(res.Response.RecommendedConsultants) > 3 {
					t.Fatalf("expected 1..3 RecommendedConsultants, got %d", len(res.Response.RecommendedConsultants))
				}
				for _, c := range res.Response.RecommendedConsultants {
					if c.NextAvailableSlotISO == "" {
						t.Fatalf("consultant %s missing NextAvailableSlotISO", c.ConsultantID)
					}
				}
			},
		},
		{
			id:          "Live-07-MoneyFlowSankey",
			surfaceMode: "full_screen",
			prompt:      "uangku lari ke mana aja bulan ini?",
			verify: func(t *testing.T, res *ai.ChatResult, _ time.Duration) {
				if res.Response.MoneyFlowCard == nil {
					t.Fatalf("expected MoneyFlowCard, got nil (narrative=%q)", res.Response.Narrative)
				}
				if res.Response.MoneyFlowCard.TotalIncomeIDR != 8000000 || res.Response.MoneyFlowCard.TotalExpenseIDR != 1130000 {
					t.Fatalf("unexpected MoneyFlowCard totals: %+v", res.Response.MoneyFlowCard)
				}
			},
		},
	}

	for _, lc := range liveCases {
		callCtx, cancel := context.WithTimeout(ctx, 45*time.Second)
		start := time.Now()
		res, err := orch.ChatStream(callCtx, userID, ai.ChatRequest{
			SessionID:       "sess_" + lc.id,
			ClientRequestID: "req_" + lc.id,
			Message:         lc.prompt,
			SurfaceMode:     lc.surfaceMode,
		}, func(ai.SSEEvent) error { return nil })
		elapsed := time.Since(start)
		cancel()

		if err != nil {
			t.Fatalf("[%s] live ChatStream failed after %s: %v", lc.id, elapsed, err)
		}
		if err := ai.ValidateStructuredResponse(&res.Response); err != nil {
			t.Fatalf("[%s] ValidateStructuredResponse failed: %v", lc.id, err)
		}
		if strings.Contains(res.Response.Narrative, "\u2014") {
			t.Fatalf("[%s] live narrative contains forbidden em dash: %q", lc.id, res.Response.Narrative)
		}
		for _, tok := range anyRpOccurrenceRegexp.FindAllString(res.Response.Narrative, -1) {
			cleaned := strings.TrimRight(tok, ".,;:!?)")
			if !strictRpFormatRegexp.MatchString(cleaned) {
				t.Fatalf("[%s] live narrative contains non-canonical IDR token %q in %q", lc.id, cleaned, res.Response.Narrative)
			}
		}

		lc.verify(t, res, elapsed)
		t.Logf("[%s] PASS in %s (model=%s, prefiltered=%v)", lc.id, elapsed.Round(time.Millisecond), model, res.IsPrefiltered)
	}

	qaCtx, qaCancel := context.WithTimeout(ctx, 45*time.Second)
	defer qaCancel()
	qaStart := time.Now()
	qaRes, err := orch.QuickAddDraft(qaCtx, userID, ai.QuickAddRequest{
		ClientRequestID: "req_Live-08-QuickAddSlang",
		Text:            "kopi kenangan 25k + parkir goceng pake gopay",
		Source:          "ai_text",
	})
	qaElapsed := time.Since(qaStart)
	if err != nil {
		t.Fatalf("[Live-08-QuickAddSlang] failed after %s: %v", qaElapsed, err)
	}
	if qaRes.Status != "ready" || len(qaRes.Drafts) != 2 {
		t.Fatalf("[Live-08-QuickAddSlang] expected 2 ready drafts, got %+v", qaRes)
	}
	t.Logf("[Live-08-QuickAddSlang] PASS in %s (model=%s)", qaElapsed.Round(time.Millisecond), model)
}
