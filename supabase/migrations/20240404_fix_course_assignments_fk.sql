-- Drop the duplicate foreign key constraint
ALTER TABLE course_assignments
DROP CONSTRAINT IF EXISTS fk_course_assignments_course;

-- Keep only the original foreign key constraint
-- course_assignments_course_id_fkey 