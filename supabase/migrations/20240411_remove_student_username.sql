-- Remove username column from students table since we'll use email for login
ALTER TABLE students DROP COLUMN username; 