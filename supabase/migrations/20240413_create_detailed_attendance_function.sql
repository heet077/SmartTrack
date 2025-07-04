-- Drop existing function if it exists
DROP FUNCTION IF EXISTS get_detailed_student_attendance(UUID, INTEGER);

-- Create function to get detailed student attendance
CREATE OR REPLACE FUNCTION get_detailed_student_attendance(
  p_program_id UUID,
  p_semester INTEGER
)
RETURNS TABLE (
  student_id UUID,
  student_name TEXT,
  enrollment_no TEXT,
  course_id UUID,
  course_name TEXT,
  attendance_date DATE,
  status BOOLEAN,
  verification_method TEXT
) AS $$
BEGIN
  RETURN QUERY
  WITH student_list AS (
    -- Get all students in the program and semester
    SELECT 
      s.id,
      s.name,
      s.enrollment_no
    FROM 
      public.students s
    WHERE 
      s.program_id = p_program_id
      AND s.semester = p_semester::INT4
  ),
  course_dates AS (
    -- Get all course sessions for the program and semester
    SELECT DISTINCT 
      c.id as course_id,
      c.name as course_name,
      ls.date as session_date
    FROM 
      courses c
      JOIN lecture_sessions ls ON ls.course_id = c.id
    WHERE 
      c.program_id = p_program_id
      AND c.semester = p_semester::INT4
      AND ls.finalized = true
  )
  SELECT 
    sl.id as student_id,
    sl.name as student_name,
    sl.enrollment_no,
    cd.course_id,
    cd.course_name,
    cd.session_date as attendance_date,
    COALESCE(ar.present, false) as status,
    CASE 
      WHEN ar.id IS NOT NULL THEN 
        CASE 
          WHEN ar.verification_method = 'qr' THEN 'QR Code'
          WHEN ar.verification_method = 'passcode' THEN 'Passcode'
          WHEN ar.verification_method = 'manual' THEN 'Manual'
          ELSE 'Unknown'
        END
      ELSE 'Not Recorded'
    END as verification_method
  FROM 
    student_list sl
    CROSS JOIN course_dates cd
    LEFT JOIN lecture_sessions ls ON ls.date = cd.session_date AND ls.course_id = cd.course_id
    LEFT JOIN attendance_records ar ON ar.session_id = ls.id AND ar.student_id = sl.id
  ORDER BY 
    sl.enrollment_no,
    cd.session_date,
    cd.course_name;
END;
$$ LANGUAGE plpgsql;

-- Grant necessary permissions
GRANT EXECUTE ON FUNCTION get_detailed_student_attendance(UUID, INTEGER) TO authenticated; 