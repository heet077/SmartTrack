-- Add OTP fields to lecture_sessions table if they don't exist
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                  WHERE table_name = 'lecture_sessions' AND column_name = 'end_otp') THEN
        ALTER TABLE lecture_sessions ADD COLUMN end_otp VARCHAR(6);
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                  WHERE table_name = 'lecture_sessions' AND column_name = 'otp_enabled') THEN
        ALTER TABLE lecture_sessions ADD COLUMN otp_enabled BOOLEAN DEFAULT FALSE;
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
END $$; 