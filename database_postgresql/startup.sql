-- Idempotent initialization for 'todos' table, trigger, and index

-- Create table if not exists
CREATE TABLE IF NOT EXISTS public.todos (
    id SERIAL PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    description TEXT NULL,
    completed BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Create or replace trigger function to update updated_at on row updates
CREATE OR REPLACE FUNCTION public.set_updated_at_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at := NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Drop existing trigger if it exists to ensure idempotency, then recreate
DO $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM pg_trigger
        WHERE tgname = 'trg_set_updated_at'
    ) THEN
        -- Drop trigger in case table existed before
        EXECUTE 'DROP TRIGGER trg_set_updated_at ON public.todos';
    END IF;
END$$;

-- Create trigger to automatically update updated_at
CREATE TRIGGER trg_set_updated_at
BEFORE UPDATE ON public.todos
FOR EACH ROW
EXECUTE FUNCTION public.set_updated_at_timestamp();

-- Create index on completed if it doesn't exist
CREATE INDEX IF NOT EXISTS idx_todos_completed ON public.todos (completed);
