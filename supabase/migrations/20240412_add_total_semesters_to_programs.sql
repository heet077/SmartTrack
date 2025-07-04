-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Enable read access for authenticated users" ON public.programs;
DROP POLICY IF EXISTS "Enable insert access for admin users" ON public.programs;
DROP POLICY IF EXISTS "Enable update access for admin users" ON public.programs;
DROP POLICY IF EXISTS "Enable delete access for admin users" ON public.programs;

-- Add total_semesters column to programs table
ALTER TABLE programs 
ADD COLUMN IF NOT EXISTS total_semesters INTEGER NOT NULL DEFAULT 8;

-- Enable RLS
ALTER TABLE programs ENABLE ROW LEVEL SECURITY;

-- Create RLS policies
CREATE POLICY "Enable read access for authenticated users" 
ON public.programs
FOR SELECT
TO authenticated
USING (true);

CREATE POLICY "Enable insert access for admin users" 
ON public.programs
FOR INSERT
TO authenticated
WITH CHECK (auth.uid() IN (SELECT id FROM admins));

CREATE POLICY "Enable update access for admin users" 
ON public.programs
FOR UPDATE
TO authenticated
USING (auth.uid() IN (SELECT id FROM admins))
WITH CHECK (auth.uid() IN (SELECT id FROM admins));

CREATE POLICY "Enable delete access for admin users" 
ON public.programs
FOR DELETE
TO authenticated
USING (auth.uid() IN (SELECT id FROM admins));

-- Add check constraint to ensure total_semesters is positive
ALTER TABLE programs
DROP CONSTRAINT IF EXISTS check_total_semesters_positive;

ALTER TABLE programs
ADD CONSTRAINT check_total_semesters_positive 
CHECK (total_semesters > 0);

-- Add check constraint to ensure total_semesters is reasonable
ALTER TABLE programs
DROP CONSTRAINT IF EXISTS check_total_semesters_max;

ALTER TABLE programs
ADD CONSTRAINT check_total_semesters_max 
CHECK (total_semesters <= 12); 