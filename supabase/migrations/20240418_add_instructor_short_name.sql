-- Add short_name column to instructors table
ALTER TABLE public.instructors
ADD COLUMN short_name TEXT;

-- Create an index on short_name for faster lookups
CREATE INDEX idx_instructors_short_name ON public.instructors(short_name);

-- Add a comment to explain the purpose of short_name
COMMENT ON COLUMN public.instructors.short_name IS 'Short name or initials used in timetables (e.g., "RC", "SS")'; 