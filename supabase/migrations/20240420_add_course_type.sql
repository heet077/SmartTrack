-- Drop existing constraint if it exists
ALTER TABLE public.courses DROP CONSTRAINT IF EXISTS course_type_check;

-- Add course_type column to courses table (if not exists)
ALTER TABLE public.courses ADD COLUMN IF NOT EXISTS course_type TEXT NOT NULL DEFAULT 'core';

-- Add check constraint to ensure course_type is valid
ALTER TABLE public.courses ADD CONSTRAINT course_type_check CHECK (
    course_type IN (
        'core',
        'technical_elective',
        'open_elective',
        'science_elective',
        'mnc_elective',
        'ict_technical_elective',
        'hasse',
        'general_elective_technical',
        'general_elective_maths',
        'ves_elective',
        'wcsp_elective',
        'ml_elective',
        'ss_elective'
    )
); 