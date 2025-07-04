-- Drop existing instructors table if it exists
DROP TABLE IF EXISTS public.instructors CASCADE;

-- Create instructors table with correct structure
CREATE TABLE IF NOT EXISTS public.instructors (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    email TEXT UNIQUE NOT NULL,
    phone TEXT,
    role TEXT DEFAULT 'instructor',
    username TEXT,
    password TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW())
);

-- Create trigger for updated_at
CREATE TRIGGER update_instructors_updated_at
    BEFORE UPDATE ON public.instructors
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Create instructor_program_mappings table if it doesn't exist
CREATE TABLE IF NOT EXISTS public.instructor_program_mappings (
    instructor_id UUID REFERENCES public.instructors(id) ON DELETE CASCADE,
    program_id UUID REFERENCES public.programs(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()),
    PRIMARY KEY (instructor_id, program_id)
);

-- Enable RLS on instructors table
ALTER TABLE public.instructors ENABLE ROW LEVEL SECURITY;

-- Create RLS policies
CREATE POLICY "Instructors can view their own data"
    ON public.instructors
    FOR SELECT
    USING (auth.uid()::text = id::text OR auth.uid() IN (
        SELECT id FROM admins
    ));

CREATE POLICY "Admins can manage instructors"
    ON public.instructors
    FOR ALL
    TO authenticated
    USING (auth.uid() IN (
        SELECT id FROM admins
    )); 