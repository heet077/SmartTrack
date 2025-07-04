-- Create student_passcodes table
CREATE TABLE student_passcodes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    student_id UUID NOT NULL REFERENCES students(id) ON DELETE CASCADE,
    course_id UUID NOT NULL REFERENCES courses(id) ON DELETE CASCADE,
    passcode VARCHAR(6) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    is_used BOOLEAN DEFAULT FALSE,
    CONSTRAINT valid_passcode CHECK (passcode ~ '^[0-9]{6}$')
);

-- Create index for faster lookups
CREATE INDEX idx_student_passcodes_student_id ON student_passcodes(student_id);
CREATE INDEX idx_student_passcodes_course_id ON student_passcodes(course_id);
CREATE INDEX idx_student_passcodes_expires_at ON student_passcodes(expires_at);

-- Create RLS policies
ALTER TABLE student_passcodes ENABLE ROW LEVEL SECURITY;

-- Professors can read and create passcodes for their courses
CREATE POLICY "Professors can manage passcodes for their courses" ON student_passcodes
    FOR ALL
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM course_assignments ca
            WHERE ca.course_id = student_passcodes.course_id
            AND ca.instructor_id = auth.uid()
        )
    );

-- Students can read and verify their own passcodes
CREATE POLICY "Students can read their own passcodes" ON student_passcodes
    FOR SELECT
    TO authenticated
    USING (student_id = auth.uid());

-- Admins have full access
CREATE POLICY "Admins have full access to passcodes" ON student_passcodes
    FOR ALL
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM admins a
            WHERE a.id = auth.uid()
        )
    ); 