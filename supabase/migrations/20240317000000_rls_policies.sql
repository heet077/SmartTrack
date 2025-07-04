-- First drop existing policies if they exist
DROP POLICY IF EXISTS "professors_can_create_passcodes" ON student_passcodes;
DROP POLICY IF EXISTS "professors_can_view_passcodes" ON student_passcodes;
DROP POLICY IF EXISTS "students_can_view_own_passcodes" ON student_passcodes;
DROP POLICY IF EXISTS "students_can_update_own_passcodes" ON student_passcodes;

-- Enable RLS
ALTER TABLE student_passcodes ENABLE ROW LEVEL SECURITY;

-- Policy for professors to insert passcodes
CREATE POLICY "professors_can_create_passcodes"
ON student_passcodes
FOR INSERT
TO authenticated
WITH CHECK (
  EXISTS (
    SELECT 1 FROM instructors i
    JOIN lecture_sessions ls ON ls.instructor_id = i.id
    WHERE i.email = auth.jwt()->>'email'
    AND student_passcodes.course_id = ls.course_id
    AND ls.end_time IS NULL
  )
);

-- Policy for professors to view passcodes
CREATE POLICY "professors_can_view_passcodes"
ON student_passcodes
FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM instructors i
    JOIN lecture_sessions ls ON ls.instructor_id = i.id
    WHERE i.email = auth.jwt()->>'email'
    AND student_passcodes.course_id = ls.course_id
  )
);

-- Policy for students to view their own passcodes
CREATE POLICY "students_can_view_own_passcodes"
ON student_passcodes
FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM students s
    WHERE s.email = auth.jwt()->>'email'
    AND student_passcodes.student_id = s.id
  )
);

-- Policy for students to update their own passcodes (mark as used)
CREATE POLICY "students_can_update_own_passcodes"
ON student_passcodes
FOR UPDATE
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM students s
    WHERE s.email = auth.jwt()->>'email'
    AND student_passcodes.student_id = s.id
  )
); 