-- Add passcode field to lecture_sessions table if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                  WHERE table_name = 'lecture_sessions' AND column_name = 'passcode') THEN
        ALTER TABLE lecture_sessions ADD COLUMN passcode VARCHAR(6);
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                  WHERE table_name = 'lecture_sessions' AND column_name = 'finalized') THEN
        ALTER TABLE lecture_sessions ADD COLUMN finalized BOOLEAN DEFAULT FALSE;
    END IF;
END $$;

-- Add finalization fields to attendance_records table if they don't exist
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                  WHERE table_name = 'attendance_records' AND column_name = 'finalized') THEN
        ALTER TABLE attendance_records ADD COLUMN finalized BOOLEAN DEFAULT FALSE;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                  WHERE table_name = 'attendance_records' AND column_name = 'finalized_at') THEN
        ALTER TABLE attendance_records ADD COLUMN finalized_at TIMESTAMP WITH TIME ZONE;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                  WHERE table_name = 'attendance_records' AND column_name = 'status') THEN
        ALTER TABLE attendance_records ADD COLUMN status VARCHAR(20) DEFAULT 'pending';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                  WHERE table_name = 'attendance_records' AND column_name = 'present') THEN
        ALTER TABLE attendance_records ADD COLUMN present BOOLEAN DEFAULT FALSE;
    END IF;
END $$; 