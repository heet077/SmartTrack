-- Add program_type column to programs table if not exists
ALTER TABLE public.programs
ADD COLUMN IF NOT EXISTS program_type TEXT;

-- Create an enum type for program types if not exists
DO $$ BEGIN
    CREATE TYPE program_type AS ENUM ('BTech', 'MTech', 'MSc', 'PhD');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- Add check constraint for program_type if not exists
DO $$ BEGIN
    ALTER TABLE public.programs
    ADD CONSTRAINT check_program_type 
    CHECK (program_type IN ('BTech', 'MTech', 'MSc', 'PhD'));
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- Update existing records with default program type if null
UPDATE public.programs
SET program_type = 'BTech'
WHERE program_type IS NULL;

-- Make program_type NOT NULL after setting defaults
ALTER TABLE public.programs
ALTER COLUMN program_type SET NOT NULL;

-- Create an index on program_type for faster lookups
CREATE INDEX IF NOT EXISTS idx_programs_program_type ON public.programs(program_type);

-- Add a comment to explain the purpose of program_type
COMMENT ON COLUMN public.programs.program_type IS 'Type of program (BTech, MTech, MSc, PhD)';

-- Insert or update the programs from the timetable
INSERT INTO public.programs (name, code, duration, total_semesters, program_type)
VALUES 
    -- BTech Programs
    ('BTech ICT + CS', 'BTECH-ICT-CS', 4, 8, 'BTech'),
    ('BTech MnC', 'BTECH-MNC', 4, 8, 'BTech'),
    ('BTech EVD', 'BTECH-EVD', 4, 8, 'BTech'),
    ('BTech CS', 'BTECH-CS', 4, 8, 'BTech'),
    
    -- MTech Programs
    ('MTech ICT-SS', 'MTECH-ICT-SS', 2, 4, 'MTech'),
    ('MTech ICT-ML', 'MTECH-ICT-ML', 2, 4, 'MTech'),
    ('MTech ICT-VLSI&ES', 'MTECH-ICT-VLSI', 2, 4, 'MTech'),
    ('MTech ICT-WCSP', 'MTECH-ICT-WCSP', 2, 4, 'MTech'),
    ('MTech EC', 'MTECH-EC', 2, 4, 'MTech'),
    
    -- MSc Programs
    ('MSc IT', 'MSC-IT', 2, 4, 'MSc'),
    ('MSc DS', 'MSC-DS', 2, 4, 'MSc'),
    ('MSc AA', 'MSC-AA', 2, 4, 'MSc')
ON CONFLICT (code) DO UPDATE 
SET 
    name = EXCLUDED.name,
    duration = EXCLUDED.duration,
    total_semesters = EXCLUDED.total_semesters,
    program_type = EXCLUDED.program_type; 