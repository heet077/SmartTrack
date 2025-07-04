-- Add location check enabled field to admin_settings
ALTER TABLE admin_settings 
ADD COLUMN location_check_enabled BOOLEAN DEFAULT false;
 
-- Update existing rows to have default value
UPDATE admin_settings 
SET location_check_enabled = false 
WHERE location_check_enabled IS NULL; 