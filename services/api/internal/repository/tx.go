package repository

import (
	"context"
	"errors"
	"fmt"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

// Store wraps sqlc Queries alongside the underlying pgxpool.Pool for atomic transactions.
type Store struct {
	*Queries
	Pool *pgxpool.Pool
}

var _ Querier = (*Store)(nil)

// NewStore creates a Store backed by the provided PostgreSQL connection pool.
func NewStore(pool *pgxpool.Pool) *Store {
	return &Store{
		Queries: New(pool),
		Pool:    pool,
	}
}

// WithTx executes fn inside a single database transaction, rolling back on error or panic.
func (s *Store) WithTx(ctx context.Context, fn func(q *Queries) error) error {
	if s == nil || s.Pool == nil {
		return errors.New("repository store pool is not initialized")
	}
	if fn == nil {
		return errors.New("transaction callback cannot be nil")
	}

	tx, err := s.Pool.BeginTx(ctx, pgx.TxOptions{})
	if err != nil {
		return fmt.Errorf("begin transaction: %w", err)
	}

	defer func() {
		if r := recover(); r != nil {
			// Detach cancellation so the connection returns clean state to the pool even on aborted contexts.
			_ = tx.Rollback(context.WithoutCancel(ctx))
			panic(r)
		}
	}()

	qtx := s.Queries.WithTx(tx)
	if err := fn(qtx); err != nil {
		rbErr := tx.Rollback(context.WithoutCancel(ctx))
		if rbErr != nil && !errors.Is(rbErr, pgx.ErrTxClosed) {
			return fmt.Errorf("tx error (%w); rollback error: %v", err, rbErr)
		}
		return err
	}

	if err := tx.Commit(ctx); err != nil {
		return fmt.Errorf("commit transaction: %w", err)
	}
	return nil
}

// EnsureDevUserAccount provisions auth.users, public.users, and user_preferences atomically for dev auth flows.
func (s *Store) EnsureDevUserAccount(ctx context.Context, arg EnsureDevUserParams) (User, error) {
	var user User
	err := s.WithTx(ctx, func(q *Queries) error {
		// public.users.id references auth.users(id), so dev identities must exist in auth.users first.
		if _, err := q.db.Exec(
			ctx,
			`INSERT INTO auth.users (id, email) VALUES ($1, $2) ON CONFLICT (id) DO NOTHING`,
			arg.ID,
			arg.Email,
		); err != nil {
			return fmt.Errorf("ensure auth.users row: %w", err)
		}

		u, err := q.EnsureDevUser(ctx, arg)
		if err != nil {
			return fmt.Errorf("ensure public.users row: %w", err)
		}

		if _, err := q.EnsureUserPreferences(ctx, u.ID); err != nil {
			return fmt.Errorf("ensure user_preferences row: %w", err)
		}

		user = u
		return nil
	})
	return user, err
}
