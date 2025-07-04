-- Drop both old and new functions to be safe
DROP FUNCTION IF EXISTS get_program_semester_attendance(UUID, INTEGER);
DROP FUNCTION IF EXISTS get_program_attendance_v2(UUID, INTEGER);

-- Create the new function with a different name
CREATE OR REPLACE FUNCTION get_program_attendance_v2(
  p_program_id UUID,
  p_semester INTEGER
)
RETURNS TABLE (
  student_id UUID,
  student_name TEXT,
  enrollment_no TEXT,
  attendance_percentage NUMERIC
) AS $$
DECLARE
  v_debug_info TEXT;
BEGIN
  -- Debug info
  v_debug_info := 'Program ID: ' || p_program_id || ', Semester: ' || p_semester;
  RAISE NOTICE 'Starting attendance calculation for %', v_debug_info;

  RETURN QUERY
  WITH student_list AS (
    -- First get all students in the program and semester
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
  attendance_calc AS (
    -- Then calculate attendance for these students
    SELECT 
      sl.id as student_id,
      sl.name as student_name,
      sl.enrollment_no as enrollment_no,
      COUNT(CASE WHEN ar.present = true THEN 1 END)::NUMERIC * 100 / NULLIF(COUNT(*), 0) as attendance_percentage
    FROM 
      student_list sl
      LEFT JOIN public.attendance_records ar ON ar.student_id = sl.id
      LEFT JOIN public.lecture_sessions ls ON ar.session_id = ls.id
      LEFT JOIN public.courses c ON ls.course_id = c.id
      AND c.program_id = p_program_id
      AND c.semester = p_semester::INT4
    GROUP BY 
      sl.id, sl.name, sl.enrollment_no
  )
  SELECT 
    ac.student_id,
    ac.student_name,
    ac.enrollment_no,
    COALESCE(ac.attendance_percentage, 0) as attendance_percentage
  FROM 
    attendance_calc ac
  ORDER BY 
    ac.enrollment_no;

  -- Debug info for empty results
  IF NOT FOUND THEN
    RAISE NOTICE 'No results found for %', v_debug_info;
  END IF;
END;
$$ LANGUAGE plpgsql;

-- Grant necessary permissions
GRANT EXECUTE ON FUNCTION get_program_attendance_v2(UUID, INTEGER) TO authenticated; 