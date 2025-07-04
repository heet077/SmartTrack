-- Drop existing constraints if they exist
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.constraint_column_usage WHERE constraint_name = 'valid_latitude') THEN
        ALTER TABLE public.admin_settings DROP CONSTRAINT valid_latitude;
    END IF;
    IF EXISTS (SELECT 1 FROM information_schema.constraint_column_usage WHERE constraint_name = 'valid_longitude') THEN
        ALTER TABLE public.admin_settings DROP CONSTRAINT valid_longitude;
    END IF;
    IF EXISTS (SELECT 1 FROM information_schema.constraint_column_usage WHERE constraint_name = 'valid_radius') THEN
        ALTER TABLE public.admin_settings DROP CONSTRAINT valid_radius;
    END IF;
END $$;

-- Add location settings columns if they don't exist
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'admin_settings' AND column_name = 'college_latitude') THEN
        ALTER TABLE public.admin_settings ADD COLUMN college_latitude DOUBLE PRECISION;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'admin_settings' AND column_name = 'college_longitude') THEN
        ALTER TABLE public.admin_settings ADD COLUMN college_longitude DOUBLE PRECISION;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'admin_settings' AND column_name = 'geofence_radius') THEN
        ALTER TABLE public.admin_settings ADD COLUMN geofence_radius INTEGER;
    END IF;
END $$;

-- Add check constraints for valid coordinates and radius
ALTER TABLE public.admin_settings
ADD CONSTRAINT valid_latitude CHECK (college_latitude >= -90 AND college_latitude <= 90),
ADD CONSTRAINT valid_longitude CHECK (college_longitude >= -180 AND college_longitude <= 180),
ADD CONSTRAINT valid_radius CHECK (geofence_radius > 0);

-- Update existing row with default values (using proper type casting)
UPDATE public.admin_settings
SET 
    college_latitude = 0.0::DOUBLE PRECISION,
    college_longitude = 0.0::DOUBLE PRECISION,
    geofence_radius = 100
WHERE id = 1; 