package ai

import (
	"errors"
	"fmt"
	"strings"
	"unicode/utf8"
)

const (
	// MaxSessionHistoryTurns bounds the sliding window forwarded to the LLM.
	MaxSessionHistoryTurns = 10
	// MaxHistoryTurnRunes bounds the maximum rune count allowed per history message.
	MaxHistoryTurnRunes = 1000
)

// ErrInvalidSessionHistory indicates that client-supplied session_history failed zero-trust validation.
var ErrInvalidSessionHistory = errors.New("invalid session history")

// RawHistoryTurn represents an untrusted client-supplied turn in session_history.
type RawHistoryTurn struct {
	Role string `json:"role"`
	Text string `json:"text"`
}

// SanitizedTurn represents a validated conversation turn safe for LLM prompt construction.
type SanitizedTurn struct {
	Role string `json:"role"`
	Text string `json:"text"`
}

// SanitizeSessionHistory enforces zero-trust validation across all raw turns before applying a
// 10-turn sliding window:
//   - Only exact roles "user" and "model" are permitted; system/tool/function/developer/unknown roles fail with ErrInvalidSessionHistory.
//   - Invalid UTF-8 or messages exceeding 1000 runes fail loudly with ErrInvalidSessionHistory (never silently truncated).
//   - Blank or whitespace-only turns with valid role and length are skipped cleanly.
//   - Only the latest 10 non-empty turns are retained in chronological order.
func SanitizeSessionHistory(raw []RawHistoryTurn) ([]SanitizedTurn, error) {
	if len(raw) == 0 {
		return []SanitizedTurn{}, nil
	}

	validated := make([]SanitizedTurn, 0, len(raw))
	for i, turn := range raw {
		if turn.Role != "user" && turn.Role != "model" {
			return nil, fmt.Errorf("%w: turn %d has disallowed role %q", ErrInvalidSessionHistory, i, turn.Role)
		}
		if !utf8.ValidString(turn.Text) {
			return nil, fmt.Errorf("%w: turn %d contains invalid UTF-8", ErrInvalidSessionHistory, i)
		}
		if utf8.RuneCountInString(turn.Text) > MaxHistoryTurnRunes {
			return nil, fmt.Errorf("%w: turn %d exceeds %d runes", ErrInvalidSessionHistory, i, MaxHistoryTurnRunes)
		}

		trimmed := strings.TrimSpace(turn.Text)
		if trimmed == "" {
			continue
		}

		validated = append(validated, SanitizedTurn{
			Role: turn.Role,
			Text: trimmed,
		})
	}

	if len(validated) > MaxSessionHistoryTurns {
		validated = validated[len(validated)-MaxSessionHistoryTurns:]
	}

	result := make([]SanitizedTurn, len(validated))
	copy(result, validated)
	return result, nil
}
