-- Create function to calculate course attendance
CREATE OR REPLACE FUNCTION public.calculate_course_attendance(course_id UUID)
RETURNS FLOAT AS $$
DECLARE
    total_sessions BIGINT;
    total_attendance BIGINT;
    attendance_rate FLOAT;
BEGIN
    -- Get total number of lecture sessions for the course
    SELECT COUNT(*) INTO total_sessions
    FROM lecture_sessions
    WHERE course_id = $1 AND finalized = true;

    -- Get total number of attendance records for the course
    SELECT COUNT(*) INTO total_attendance
    FROM attendance_records ar
    JOIN lecture_sessions ls ON ar.session_id = ls.id
    WHERE ls.course_id = $1 AND ls.finalized = true;

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

-- Create function to calculate overall attendance
CREATE OR REPLACE FUNCTION public.calculate_overall_attendance()
RETURNS FLOAT AS $$
DECLARE
    total_sessions BIGINT;
    total_attendance BIGINT;
    attendance_rate FLOAT;
BEGIN
    -- Get total number of finalized lecture sessions
    SELECT COUNT(*) INTO total_sessions
    FROM lecture_sessions
    WHERE finalized = true;

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

-- Add foreign key relationships for course schedules
ALTER TABLE course_assignments
ADD CONSTRAINT fk_course_assignments_course
FOREIGN KEY (course_id)
REFERENCES courses(id)
ON DELETE CASCADE;

-- Create view for upcoming lectures using the correct foreign key
DROP VIEW IF EXISTS upcoming_lectures;
CREATE VIEW upcoming_lectures AS
SELECT 
    ca.*,
    c.code as course_code,
    c.name as course_name,
    i.name as instructor_name
FROM course_assignments ca
JOIN courses c ON ca.course_id = c.id
JOIN instructors i ON ca.instructor_id = i.id; 