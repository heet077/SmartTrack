-- Drop existing functions
DROP FUNCTION IF EXISTS public.calculate_course_attendance(UUID);
DROP FUNCTION IF EXISTS public.calculate_overall_attendance();

-- Create function to calculate course attendance with fixed course_id reference
CREATE OR REPLACE FUNCTION public.calculate_course_attendance(p_course_id UUID)
RETURNS FLOAT AS $$
DECLARE
    total_sessions BIGINT;
    total_attendance BIGINT;
    attendance_rate FLOAT;
BEGIN
    -- Get total number of lecture sessions for the course
    SELECT COUNT(*) INTO total_sessions
    FROM lecture_sessions ls
    WHERE ls.course_id = p_course_id AND ls.finalized = true;

    -- Get total number of attendance records for the course
    SELECT COUNT(*) INTO total_attendance
    FROM attendance_records ar
    JOIN lecture_sessions ls ON ar.session_id = ls.id
    WHERE ls.course_id = p_course_id AND ls.finalized = true;

    -- Calculate attendance rate
    IF total_sessions = 0 THEN
        attendance_rate := 0;
    ELSE
        attendance_rate := (total_attendance::FLOAT / (total_sessions * (
            SELECT COUNT(*) FROM students
        ))::FLOAT) * 100;
    END IF;

    RETURN attendance_rate;
END;
$$ LANGUAGE plpgsql;

-- Create function to calculate overall attendance with fixed course_id reference
CREATE OR REPLACE FUNCTION public.calculate_overall_attendance()
RETURNS FLOAT AS $$
DECLARE
    total_sessions BIGINT;
    total_attendance BIGINT;
    attendance_rate FLOAT;
BEGIN
    -- Get total number of finalized lecture sessions
    SELECT COUNT(*) INTO total_sessions
    FROM lecture_sessions ls
    WHERE ls.finalized = true;

    -- Get total number of attendance records
    SELECT COUNT(*) INTO total_attendance
    FROM attendance_records ar
    JOIN lecture_sessions ls ON ar.session_id = ls.id
    WHERE ls.finalized = true;

    -- Calculate attendance rate
    IF total_sessions = 0 THEN
        attendance_rate := 0;
    ELSE
        attendance_rate := (total_attendance::FLOAT / (total_sessions * (
            SELECT COUNT(*) FROM students
        ))::FLOAT) * 100;
    END IF;

    RETURN attendance_rate;
END;
$$ LANGUAGE plpgsql; 