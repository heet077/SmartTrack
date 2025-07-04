-- Insert test program
INSERT INTO public.programs (id, name, code, duration)
VALUES 
    ('d290f1ee-6c54-4b01-90e6-d701748f0851', 'Bachelor of Computer Science', 'BCS', 4);

-- Insert test courses
INSERT INTO public.courses (id, name, code, program_id, semester, credits)
VALUES 
    ('d290f1ee-6c54-4b01-90e6-d701748f0852', 'Introduction to Programming', 'CS101', 'd290f1ee-6c54-4b01-90e6-d701748f0851', 1, 3),
    ('d290f1ee-6c54-4b01-90e6-d701748f0853', 'Data Structures', 'CS102', 'd290f1ee-6c54-4b01-90e6-d701748f0851', 1, 3);

-- Insert test instructor
INSERT INTO public.instructors (id, name, email, department)
VALUES 
    ('d290f1ee-6c54-4b01-90e6-d701748f0854', 'John Doe', 'john.doe@example.com', 'Computer Science');

-- Insert test students
INSERT INTO public.students (id, name, email, enrollment_no, program_id, semester)
VALUES 
    ('d290f1ee-6c54-4b01-90e6-d701748f0855', 'Alice Smith', 'alice@example.com', 'CS2024001', 'd290f1ee-6c54-4b01-90e6-d701748f0851', 1),
    ('d290f1ee-6c54-4b01-90e6-d701748f0856', 'Bob Johnson', 'bob@example.com', 'CS2024002', 'd290f1ee-6c54-4b01-90e6-d701748f0851', 1);

-- Insert test lecture sessions (for today)
INSERT INTO public.lecture_sessions (id, course_id, instructor_id, date, start_time, end_time, classroom)
VALUES 
    ('d290f1ee-6c54-4b01-90e6-d701748f0857', 'd290f1ee-6c54-4b01-90e6-d701748f0852', 'd290f1ee-6c54-4b01-90e6-d701748f0854', CURRENT_DATE, '09:00', '10:30', 'Room 101'),
    ('d290f1ee-6c54-4b01-90e6-d701748f0858', 'd290f1ee-6c54-4b01-90e6-d701748f0853', 'd290f1ee-6c54-4b01-90e6-d701748f0854', CURRENT_DATE, '11:00', '12:30', 'Room 102');

-- Insert test attendance records
INSERT INTO public.attendance_records (session_id, student_id, present, check_in_time)
VALUES 
    ('d290f1ee-6c54-4b01-90e6-d701748f0857', 'd290f1ee-6c54-4b01-90e6-d701748f0855', true, CURRENT_TIMESTAMP),
    ('d290f1ee-6c54-4b01-90e6-d701748f0857', 'd290f1ee-6c54-4b01-90e6-d701748f0856', false, NULL),
    ('d290f1ee-6c54-4b01-90e6-d701748f0858', 'd290f1ee-6c54-4b01-90e6-d701748f0855', true, CURRENT_TIMESTAMP),
    ('d290f1ee-6c54-4b01-90e6-d701748f0858', 'd290f1ee-6c54-4b01-90e6-d701748f0856', true, CURRENT_TIMESTAMP); 