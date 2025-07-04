-- Create a function to get program attendance statistics
CREATE OR REPLACE FUNCTION get_program_attendance(program_id_param UUID)
RETURNS JSON
LANGUAGE plpgsql
AS $$
DECLARE
    result JSON;
BEGIN
    WITH program_sessions AS (
        SELECT ls.id AS session_id
        FROM lecture_sessions ls
        JOIN courses c ON ls.course_id = c.id
        WHERE c.program_id = program_id_param
    ),
    attendance_stats AS (
        SELECT 
            COUNT(DISTINCT ps.session_id) as total_sessions,
            COUNT(DISTINCT CASE WHEN ar.present = true THEN ar.id END) as total_present
        FROM program_sessions ps
        LEFT JOIN attendance_records ar ON ar.lecture_session_id = ps.session_id
    )
    SELECT json_build_object(
        'total_sessions', COALESCE(total_sessions, 0),
        'total_present', COALESCE(total_present, 0)
    ) INTO result
    FROM attendance_stats;

    RETURN result;
END;
$$; 