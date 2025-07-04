-- First, update any NULL plain_password values to use the email as password
UPDATE instructors 
SET plain_password = email 
WHERE plain_password IS NULL;

-- Now rename plain_password to password
ALTER TABLE instructors 
  RENAME COLUMN plain_password TO password;

-- Drop the password_hash column
ALTER TABLE instructors 
  DROP COLUMN password_hash;

-- Now we can safely set NOT NULL constraint since we've handled NULL values
ALTER TABLE instructors 
  ALTER COLUMN password SET NOT NULL;

-- Update any existing RLS policies to use the new password column name
DROP POLICY IF EXISTS "Instructors can view their own data." ON public.instructors;
CREATE POLICY "Instructors can view their own data."
  ON public.instructors
  FOR SELECT
  USING (auth.uid()::text = id::text OR auth.uid() IN (
    SELECT id FROM admins
  )); 