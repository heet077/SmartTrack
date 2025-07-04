-- Drop any existing triggers on instructors table
DO $$
DECLARE
    trigger_name text;
BEGIN
    FOR trigger_name IN (
        SELECT tgname 
        FROM pg_trigger 
        WHERE tgrelid = 'public.instructors'::regclass
        AND tgname != 'update_instructors_updated_at'
    )
    LOOP
        EXECUTE 'DROP TRIGGER IF EXISTS ' || trigger_name || ' ON public.instructors';
    END LOOP;
END $$;

-- Drop any functions that might be trying to use password_hash
DO $$
DECLARE
    func_name text;
BEGIN
    FOR func_name IN (
        SELECT p.proname
        FROM pg_proc p
        JOIN pg_namespace n ON p.pronamespace = n.oid
        WHERE n.nspname = 'public'
        AND p.prosrc LIKE '%password_hash%'
    )
    LOOP
        EXECUTE 'DROP FUNCTION IF EXISTS public.' || func_name || ' CASCADE';
    END LOOP;
END $$;

-- Ensure the instructors table has the correct password column
DO $$
BEGIN
    -- Make sure password_hash column doesn't exist
    IF EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'instructors' 
        AND column_name = 'password_hash'
    ) THEN
        ALTER TABLE public.instructors DROP COLUMN password_hash;
    END IF;

    -- Make sure password column exists and is NOT NULL
    IF NOT EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'instructors' 
        AND column_name = 'password'
    ) THEN
        ALTER TABLE public.instructors ADD COLUMN password TEXT NOT NULL DEFAULT '';
    END IF;
END $$; 