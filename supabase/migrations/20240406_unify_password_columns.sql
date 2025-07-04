-- Update students table
-- First, update any NULL plain_passwords to use email
UPDATE students 
SET plain_password = email 
WHERE plain_password IS NULL;

-- Add new password column
ALTER TABLE students 
ADD COLUMN password text;

-- Copy data from plain_password to new password column
UPDATE students 
SET password = plain_password;

-- Drop old password columns
ALTER TABLE students 
DROP COLUMN password_hash,
DROP COLUMN plain_password;

-- Make password required
ALTER TABLE students 
ALTER COLUMN password SET NOT NULL;

-- Update admins table
-- First, add new password column
ALTER TABLE admins 
ADD COLUMN password text;

-- Copy data from password_hash to new password column
UPDATE admins 
SET password = password_hash;

-- Drop old password_hash column
ALTER TABLE admins 
DROP COLUMN password_hash;

-- Make password required
ALTER TABLE admins 
ALTER COLUMN password SET NOT NULL;

-- Update RLS policies for the new column names
DROP POLICY IF EXISTS "Students can view their own data." ON public.students;
CREATE POLICY "Students can view their own data."
  ON public.students
  FOR SELECT
  USING (auth.uid()::text = id::text OR auth.uid() IN (
    SELECT id FROM admins
  ));

DROP POLICY IF EXISTS "Admins can view their own data." ON public.admins;
CREATE POLICY "Admins can view their own data."
  ON public.admins
  FOR SELECT
  USING (auth.uid()::text = id::text); 