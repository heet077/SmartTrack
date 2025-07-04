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
DECLARE
  v_student_count INTEGER;
  v_course_count INTEGER;
  v_session_count INTEGER;
  v_record_count INTEGER;
BEGIN
  -- First check students
  SELECT COUNT(*) INTO v_student_count
  FROM public.students
  WHERE program_id = p_program_id AND semester = p_semester;
  RAISE NOTICE 'Found % students in program % semester %', v_student_count, p_program_id, p_semester;

  -- Then check courses
  SELECT COUNT(*) INTO v_course_count
  FROM courses
  WHERE program_id = p_program_id AND semester = p_semester;
  RAISE NOTICE 'Found % courses', v_course_count;

  -- Check lecture sessions
  SELECT COUNT(*) INTO v_session_count
  FROM courses c
  JOIN lecture_sessions ls ON ls.course_id = c.id
  WHERE c.program_id = p_program_id 
  AND c.semester = p_semester
  AND ls.finalized = true;
  RAISE NOTICE 'Found % lecture sessions', v_session_count;

  -- Check attendance records
  SELECT COUNT(*) INTO v_record_count
  FROM courses c
  JOIN lecture_sessions ls ON ls.course_id = c.id
  JOIN attendance_records ar ON ar.session_id = ls.id
  WHERE c.program_id = p_program_id 
  AND c.semester = p_semester;
  RAISE NOTICE 'Found % attendance records', v_record_count;

  -- Return if no data
  IF v_student_count = 0 OR v_course_count = 0 THEN
    RAISE NOTICE 'No students or courses found';
    RETURN;
  END IF;

  -- Simplified query to debug
  RETURN QUERY
  WITH student_list AS (
    SELECT s.id, s.name, s.enrollment_no
    FROM students s
    WHERE s.program_id = p_program_id AND s.semester = p_semester
  ),
  course_list AS (
    SELECT c.id, c.name
    FROM courses c
    WHERE c.program_id = p_program_id AND c.semester = p_semester
  ),
  session_list AS (
    SELECT ls.id as session_id, ls.course_id, ls.date
    FROM lecture_sessions ls
    JOIN course_list c ON c.id = ls.course_id
    WHERE ls.finalized = true
  )
  SELECT 
    sl.id as student_id,
    sl.name as student_name,
    sl.enrollment_no,
    c.id as course_id,
    c.name as course_name,
    s.date as attendance_date,
    COALESCE(ar.present, false) as status,
    CASE 
      WHEN ar.id IS NOT NULL THEN 
        CASE 
          WHEN ar.status = 'verified' THEN 'Verified'
          ELSE 'Manual'
        END
      ELSE 'Not Recorded'
    END as verification_method
  FROM student_list sl
  CROSS JOIN course_list c
  JOIN session_list s ON s.course_id = c.id
  LEFT JOIN attendance_records ar ON ar.session_id = s.session_id AND ar.student_id = sl.id
  ORDER BY sl.enrollment_no, s.date, c.name;

  -- Get final count
  GET DIAGNOSTICS v_record_count = ROW_COUNT;
  RAISE NOTICE 'Returning % detailed attendance records', v_record_count;
END;
$$ LANGUAGE plpgsql;

-- Grant necessary permissions
GRANT EXECUTE ON FUNCTION get_detailed_student_attendance(UUID, INTEGER) TO authenticated; 