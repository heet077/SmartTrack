-- Function to check if a column exists in a table
CREATE OR REPLACE FUNCTION check_column_exists(table_name text, column_name text)
RETURNS boolean AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = 'public'
        AND table_name = $1
        AND column_name = $2
    );
END;
$$ LANGUAGE plpgsql;

-- Function to add program_type column
CREATE OR REPLACE FUNCTION add_program_type_column()
RETURNS void AS $$
BEGIN
    -- Add program_type column if it doesn't exist
    IF NOT EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = 'public'
        AND table_name = 'programs'
        AND column_name = 'program_type'
    ) THEN
        ALTER TABLE public.programs
        ADD COLUMN program_type TEXT;

        -- Create an index on program_type for faster lookups
        CREATE INDEX idx_programs_program_type ON public.programs(program_type);

        -- Add a comment to explain the purpose of program_type
        COMMENT ON COLUMN public.programs.program_type IS 'Type of program (BTech, MTech, MSc, PhD)';
    END IF;
END;
$$ LANGUAGE plpgsql; 