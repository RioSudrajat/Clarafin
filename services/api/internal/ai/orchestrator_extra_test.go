package ai_test

import (
	"context"
	"encoding/json"
	"errors"
	"strings"
	"testing"
	"time"

	"github.com/google/uuid"

	"github.com/clarafin/api/internal/ai"
	"github.com/clarafin/api/internal/service"
)

func TestOrchestrator_QuickAddAndOCR_DraftStagingAndCompensation(t *testing.T) {
	userID := uuid.New()
	gopayID := uuid.New()

	t.Run("QuickAddDraft extracts multi-item text and persists ai_drafts", func(t *testing.T) {
		draftRepo := &memoryDraftRepo{}
		quota := &mockQuotaManager{
			status: service.QuotaStatus{PlanType: "free", QuotaTotal: 40, QuotaUsed: 2, QuotaRemaining: 38},
		}
		llm := &mockLLMClient{
			fn: func(_ context.Context, _ int, req ai.GenerateRequest) (*ai.GenerateResponse, error) {
				if req.Pass != ai.PassExtraction || req.Params.ResponseMIMEType != "application/json" || req.Params.ResponseSchema == nil {
					t.Fatalf("expected PassExtraction with JSON schema, got %+v", req)
				}
				return &ai.GenerateResponse{
					Text: `{"default_wallet_hint":"gopay","confidence_score":0.95,"items":[{"title":"Kopi Kenangan","amount_idr":25000,"type":"expense","raw_category":"kopi"},{"title":"Parkir","amount_idr":5000,"type":"expense","raw_category":"parkir"}]}`,
				}, nil
			},
		}
		actions := &stubActionProvider{
			prepareTxFn: func(context.Context, uuid.UUID, ai.PrepareTransactionInput) (*ai.PrepareTransactionResult, error) {
				now := time.Now().UTC()
				return &ai.PrepareTransactionResult{
					Status: "ready",
					TransactionDraft: &ai.TransactionDraftPayload{
						ItemCount:      2,
						TotalAmountIDR: 30000,
						Items: []ai.TransactionDraftItem{
							{Title: "Kopi Kenangan", AmountIDR: 25000, Type: "expense", CanonicalCategory: "Food & Beverage • Coffee Shop", CanonicalMainCategory: "Food & Beverage", WalletID: gopayID, WalletName: "GoPay", OccurredAt: now},
							{Title: "Parkir", AmountIDR: 5000, Type: "expense", CanonicalCategory: "Transportation • Parking & Toll", CanonicalMainCategory: "Transportation", WalletID: gopayID, WalletName: "GoPay", OccurredAt: now},
						},
					},
				}, nil
			},
		}

		orch := ai.NewOrchestrator(ai.OrchestratorConfig{
			Model:     "gemini-2.5-flash",
			LLM:       llm,
			Quota:     quota,
			Financial: &stubFinancialProvider{},
			Actions:   actions,
			Matching:  &stubMatchingProvider{},
			DraftRepo: draftRepo,
		})

		res, err := orch.QuickAddDraft(context.Background(), userID, ai.QuickAddRequest{
			ClientRequestID: "qa_multi_1",
			Text:            "kopi kenangan 25k + parkir goceng pake gopay",
			Source:          "ai_text",
		})
		if err != nil {
			t.Fatalf("QuickAddDraft: %v", err)
		}
		if res.Status != "ready" || len(res.Drafts) != 2 || res.BatchID == nil {
			t.Fatalf("expected 2 staged drafts with batch_id, got %+v", res)
		}
		if len(draftRepo.drafts) != 2 || draftRepo.drafts[0].Source != "ai_text" {
			t.Fatalf("drafts not saved properly: %+v", draftRepo.drafts)
		}
		if len(quota.commitCalls) != 1 || quota.commitCalls[0] != "qa_multi_1" {
			t.Fatalf("expected quota committed for qa_multi_1, got %v", quota.commitCalls)
		}
	})

	t.Run("OCRDraft sends inline image bytes and compensates quota on extraction error", func(t *testing.T) {
		draftRepo := &memoryDraftRepo{}
		quota := &mockQuotaManager{
			status: service.QuotaStatus{PlanType: "free", QuotaTotal: 40, QuotaUsed: 3, QuotaRemaining: 37},
		}
		llm := &mockLLMClient{
			fn: func(_ context.Context, _ int, req ai.GenerateRequest) (*ai.GenerateResponse, error) {
				if len(req.Contents) == 0 || len(req.Contents[0].Parts) < 2 || len(req.Contents[0].Parts[1].InlineBytes) == 0 {
					t.Fatalf("expected multimodal image part in OCR request, got %+v", req.Contents)
				}
				return nil, errors.New("upstream timeout")
			},
		}

		orch := ai.NewOrchestrator(ai.OrchestratorConfig{
			Model:     "gemini-2.5-flash",
			LLM:       llm,
			Quota:     quota,
			Financial: &stubFinancialProvider{},
			Actions:   &stubActionProvider{},
			Matching:  &stubMatchingProvider{},
			DraftRepo: draftRepo,
		})

		_, err := orch.OCRDraft(context.Background(), userID, ai.OCRRequest{
			ClientRequestID: "ocr_fail_1",
			MIMEType:        "image/jpeg",
			ImageBytes:      []byte{0xFF, 0xD8, 0xFF, 0xE0},
		})
		if err == nil {
			t.Fatal("expected error when OCR LLM call fails")
		}
		if len(quota.compensateCalls) != 1 || quota.compensateCalls[0] != "ocr_fail_1" {
			t.Fatalf("expected CompensateFailure for ocr_fail_1, got %v", quota.compensateCalls)
		}
		if quota.status.QuotaRemaining != 37 {
			t.Fatalf("expected QuotaRemaining restored to 37, got %d", quota.status.QuotaRemaining)
		}
	})
}

func TestOrchestrator_ReconcilesGoalBudgetAndBillDrafts(t *testing.T) {
	userID := uuid.New()
	targetDate := "2027-05-17"

	llm := &mockLLMClient{
		fn: func(_ context.Context, callIdx int, _ ai.GenerateRequest) (*ai.GenerateResponse, error) {
			switch callIdx {
			case 0:
				return &ai.GenerateResponse{
					FunctionCalls: []ai.ToolCall{
						{ID: "g1", Name: "propose_goal_draft", Args: map[string]any{"title": "Dana Darurat", "target_amount_idr": 15000000, "months": 6, "priority": "urgent"}},
						{ID: "b1", Name: "propose_budget_draft", Args: map[string]any{"category": "Food & Beverage", "limit_amount_idr": 1500000}},
						{ID: "l1", Name: "propose_bill_draft", Args: map[string]any{"title": "Wi-Fi IndiHome", "category": "Bills & Utilities • Internet & Wi-Fi", "amount_idr": 385000, "due_day": 20, "frequency": "monthly"}},
					},
				}, nil
			case 1:
				return &ai.GenerateResponse{Text: "All three drafts prepared."}, nil
			case 2:
				drifted := ai.AiStructuredResponse{
					Narrative:       "Draf goal, budget, dan tagihan siap.",
					ThinkingSummary: []ai.ThinkingStep{{StepNumber: 1, Title: "Siapkan draf", Detail: "OK", Status: "completed"}},
					GoalDraft: &ai.GoalDraftPayload{
						Title:                    "Dana Darurat",
						TargetAmountIDR:          1,
						MonthlySavingEstimateIDR: 1,
						Priority:                 "urgent",
					},
					BudgetDraft: &ai.BudgetDraftPayload{
						Category:       "Food & Beverage",
						MonthYear:      "2026-11",
						LimitAmountIDR: 1,
					},
					BillDraft: &ai.BillDraftPayload{
						Title:             "Wi-Fi IndiHome",
						CanonicalCategory: "Bills & Utilities • Internet & Wi-Fi",
						AmountIDR:         1,
						DueDay:            1,
						NextDueDate:       "2026-11-01",
						Frequency:         "monthly",
					},
				}
				raw, _ := json.Marshal(drifted)
				return &ai.GenerateResponse{Text: string(raw)}, nil
			default:
				t.Fatalf("unexpected call %d", callIdx)
				return nil, nil
			}
		},
	}

	actions := &stubActionProvider{
		goalFn: func(context.Context, uuid.UUID, ai.GoalDraftInput) (*ai.GoalDraftPayload, error) {
			return &ai.GoalDraftPayload{
				Title:                    "Dana Darurat",
				TargetAmountIDR:          15000000,
				RemainingAmountIDR:       15000000,
				TargetDate:               &targetDate,
				MonthsRemaining:          6,
				MonthlySavingEstimateIDR: 2500000,
				Priority:                 "urgent",
			}, nil
		},
		budgetFn: func(context.Context, uuid.UUID, ai.BudgetDraftInput) (*ai.BudgetDraftPayload, error) {
			return &ai.BudgetDraftPayload{
				Category:             "Food & Beverage",
				MonthYear:            "2026-11",
				LimitAmountIDR:       1500000,
				CurrentMonthSpendIDR: 1820000,
				Avg30DSpendIDR:       1450000,
			}, nil
		},
		billFn: func(context.Context, uuid.UUID, ai.BillDraftInput) (*ai.BillDraftPayload, error) {
			return &ai.BillDraftPayload{
				Title:                 "Wi-Fi IndiHome",
				CanonicalCategory:     "Bills & Utilities • Internet & Wi-Fi",
				CanonicalMainCategory: "Bills & Utilities",
				AmountIDR:             385000,
				DueDay:                20,
				NextDueDate:           "2026-11-20",
				Frequency:             "monthly",
			}, nil
		},
	}

	orch := ai.NewOrchestrator(ai.OrchestratorConfig{
		Model:     "gemini-2.5-flash",
		LLM:       llm,
		Quota:     &mockQuotaManager{status: service.QuotaStatus{PlanType: "free", QuotaTotal: 40, QuotaRemaining: 40}},
		Financial: &stubFinancialProvider{},
		Actions:   actions,
		Matching:  &stubMatchingProvider{},
	})

	var events []ai.SSEEvent
	res, err := orch.ChatStream(context.Background(), userID, ai.ChatRequest{
		ClientRequestID: "req_plan_reconcile",
		Message:         "buatin goal, budget, dan bill",
		SurfaceMode:     "full_screen",
	}, func(ev ai.SSEEvent) error {
		events = append(events, ev)
		return nil
	})
	if err != nil {
		t.Fatalf("ChatStream: %v", err)
	}
	if res.Response.GoalDraft.MonthlySavingEstimateIDR != 2500000 || res.Response.GoalDraft.TargetAmountIDR != 15000000 {
		t.Fatalf("GoalDraft not reconciled: %+v", res.Response.GoalDraft)
	}
	if res.Response.BudgetDraft.LimitAmountIDR != 1500000 || res.Response.BudgetDraft.Avg30DSpendIDR != 1450000 {
		t.Fatalf("BudgetDraft not reconciled: %+v", res.Response.BudgetDraft)
	}
	if res.Response.BillDraft.AmountIDR != 385000 || res.Response.BillDraft.NextDueDate != "2026-11-20" {
		t.Fatalf("BillDraft not reconciled: %+v", res.Response.BillDraft)
	}
	// Verify ThinkingStep numbers are strictly sequential without duplicate 1s.
	for i := 0; i < len(events)-1; i++ {
		if events[i].Type != ai.SSEEventThinkingStep {
			continue
		}
		step, ok := events[i].Data.(ai.SSEThinkingStepEvent)
		if !ok {
			t.Fatalf("unexpected thinking step payload type %T", events[i].Data)
		}
		if step.StepNumber != i+1 {
			t.Fatalf("step %d had StepNumber=%d, want %d", i, step.StepNumber, i+1)
		}
		if strings.Contains(step.Title, "\u2014") || strings.Contains(step.Detail, "\u2014") {
			t.Fatalf("step contains em dash: %+v", step)
		}
	}
}

func TestOrchestrator_QuickAddDraft_LongClientRequestIDScopesMutationID(t *testing.T) {
	userID := uuid.New()
	gopayID := uuid.New()
	reqID128 := strings.Repeat("a", 128)
	otherReqID128 := strings.Repeat("b", 128)

	runOnce := func(clientReqID string) []*string {
		draftRepo := &memoryDraftRepo{}
		quota := &mockQuotaManager{
			status: service.QuotaStatus{PlanType: "free", QuotaTotal: 40, QuotaRemaining: 40},
		}
		llm := &mockLLMClient{
			fn: func(context.Context, int, ai.GenerateRequest) (*ai.GenerateResponse, error) {
				return &ai.GenerateResponse{
					Text: `{"default_wallet_hint":"gopay","confidence_score":0.95,"items":[{"title":"Kopi","amount_idr":25000,"type":"expense","raw_category":"kopi"},{"title":"Parkir","amount_idr":5000,"type":"expense","raw_category":"parkir"}]}`,
				}, nil
			},
		}
		actions := &stubActionProvider{
			prepareTxFn: func(context.Context, uuid.UUID, ai.PrepareTransactionInput) (*ai.PrepareTransactionResult, error) {
				now := time.Now().UTC()
				return &ai.PrepareTransactionResult{
					Status: "ready",
					TransactionDraft: &ai.TransactionDraftPayload{
						ItemCount:      2,
						TotalAmountIDR: 30000,
						Items: []ai.TransactionDraftItem{
							{Title: "Kopi", AmountIDR: 25000, Type: "expense", CanonicalCategory: "Food & Beverage • Coffee Shop", CanonicalMainCategory: "Food & Beverage", WalletID: gopayID, WalletName: "GoPay", OccurredAt: now},
							{Title: "Parkir", AmountIDR: 5000, Type: "expense", CanonicalCategory: "Transportation • Parking & Toll", CanonicalMainCategory: "Transportation", WalletID: gopayID, WalletName: "GoPay", OccurredAt: now},
						},
					},
				}, nil
			},
		}
		orch := ai.NewOrchestrator(ai.OrchestratorConfig{
			Model:     "gemini-2.5-flash",
			LLM:       llm,
			Quota:     quota,
			Financial: &stubFinancialProvider{},
			Actions:   actions,
			Matching:  &stubMatchingProvider{},
			DraftRepo: draftRepo,
		})
		res, err := orch.QuickAddDraft(context.Background(), userID, ai.QuickAddRequest{
			ClientRequestID: clientReqID,
			Text:            "kopi 25k + parkir 5k",
			Source:          "ai_text",
		})
		if err != nil {
			t.Fatalf("QuickAddDraft(%d): %v", len(clientReqID), err)
		}
		if len(res.Drafts) != 2 {
			t.Fatalf("expected 2 drafts, got %d", len(res.Drafts))
		}
		return []*string{res.Drafts[0].ClientMutationID, res.Drafts[1].ClientMutationID}
	}

	firstRun := runOnce(reqID128)
	secondRun := runOnce(reqID128)
	otherRun := runOnce(otherReqID128)

	for idx, ptr := range firstRun {
		if ptr == nil || *ptr == "" {
			t.Fatalf("draft %d ClientMutationID must be non-empty", idx)
		}
		if len(*ptr) > 128 {
			t.Fatalf("draft %d ClientMutationID len = %d > 128 (%q)", idx, len(*ptr), *ptr)
		}
		if *ptr != *secondRun[idx] {
			t.Fatalf("expected deterministic ClientMutationID across identical runs: %q != %q", *ptr, *secondRun[idx])
		}
		if *ptr == *otherRun[idx] {
			t.Fatalf("expected distinct ClientMutationID for different 128-char client_request_id: %q", *ptr)
		}
	}
	if *firstRun[0] == *firstRun[1] {
		t.Fatalf("expected distinct ClientMutationID per draft item, both %q", *firstRun[0])
	}
}

func TestOrchestrator_QuickAddDraft_RetryIsolatesAttemptState(t *testing.T) {
	userID := uuid.New()
	gopayID := uuid.New()
	draftRepo := &memoryDraftRepo{}
	quota := &mockQuotaManager{
		status: service.QuotaStatus{PlanType: "free", QuotaTotal: 40, QuotaRemaining: 40},
	}

	llm := &mockLLMClient{
		fn: func(_ context.Context, callIdx int, _ ai.GenerateRequest) (*ai.GenerateResponse, error) {
			switch callIdx {
			case 0:
				// Valid JSON with populated default_wallet_hint and confidence_score, but empty items -> triggers retry.
				return &ai.GenerateResponse{
					Text: `{"default_wallet_hint":"ovo","confidence_score":0.42,"items":[]}`,
				}, nil
			case 1:
				// Retry omits default_wallet_hint and confidence_score -> must NOT inherit attempt 0's partial state.
				return &ai.GenerateResponse{
					Text: `{"items":[{"title":"Roti","amount_idr":12000,"type":"expense","raw_category":"makanan"}]}`,
				}, nil
			default:
				t.Fatalf("unexpected LLM call %d", callIdx)
				return nil, nil
			}
		},
	}

	var capturedInput ai.PrepareTransactionInput
	actions := &stubActionProvider{
		prepareTxFn: func(_ context.Context, _ uuid.UUID, input ai.PrepareTransactionInput) (*ai.PrepareTransactionResult, error) {
			capturedInput = input
			return &ai.PrepareTransactionResult{
				Status: "ready",
				TransactionDraft: &ai.TransactionDraftPayload{
					ItemCount:      1,
					TotalAmountIDR: 12000,
					Items: []ai.TransactionDraftItem{
						{Title: "Roti", AmountIDR: 12000, Type: "expense", CanonicalCategory: "Food & Beverage • Snacks", CanonicalMainCategory: "Food & Beverage", WalletID: gopayID, WalletName: "GoPay", OccurredAt: time.Now().UTC()},
					},
				},
			}, nil
		},
	}

	orch := ai.NewOrchestrator(ai.OrchestratorConfig{
		Model:     "gemini-2.5-flash",
		LLM:       llm,
		Quota:     quota,
		Financial: &stubFinancialProvider{},
		Actions:   actions,
		Matching:  &stubMatchingProvider{},
		DraftRepo: draftRepo,
	})

	res, err := orch.QuickAddDraft(context.Background(), userID, ai.QuickAddRequest{
		ClientRequestID: "qa_retry_isolated",
		Text:            "roti 12rb",
		Source:          "ai_text",
	})
	if err != nil {
		t.Fatalf("QuickAddDraft: %v", err)
	}
	if capturedInput.DefaultWalletHint != "" {
		t.Fatalf("expected attempt 0 default_wallet_hint %q not to leak into attempt 1", capturedInput.DefaultWalletHint)
	}
	if len(res.Drafts) != 1 || res.Drafts[0].ConfidenceScore != 0.9 {
		t.Fatalf("expected default confidence_score 0.9 without leakage from attempt 0, got %+v", res.Drafts)
	}
}
