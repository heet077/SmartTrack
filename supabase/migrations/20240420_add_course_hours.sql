-- Add hours columns to courses table
ALTER TABLE public.courses
ADD COLUMN theory_hours INTEGER DEFAULT 0,
ADD COLUMN tutorial_hours INTEGER DEFAULT 0,
ADD COLUMN lab_hours INTEGER DEFAULT 0;

-- Add check constraints to ensure hours are non-negative
ALTER TABLE public.courses
ADD CONSTRAINT check_theory_hours CHECK (theory_hours >= 0),
ADD CONSTRAINT check_tutorial_hours CHECK (tutorial_hours >= 0),
ADD CONSTRAINT check_lab_hours CHECK (lab_hours >= 0);

-- Add comment to explain the hours format
COMMENT ON COLUMN public.courses.theory_hours IS 'Number of theory lecture hours per week';
COMMENT ON COLUMN public.courses.tutorial_hours IS 'Number of tutorial hours per week';
COMMENT ON COLUMN public.courses.lab_hours IS 'Number of laboratory hours per week'; 