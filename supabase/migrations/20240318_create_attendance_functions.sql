-- Create function to calculate overall attendance
CREATE OR REPLACE FUNCTION public.calculate_overall_attendance()
RETURNS TABLE (percentage float) 
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN QUERY
  WITH total_attendance AS (
    SELECT 
      COUNT(*) as total_records,
      COUNT(*) FILTER (WHERE present = true) as present_records
    FROM attendance_records
  )
  SELECT 
    CASE 
      WHEN total_records > 0 THEN (present_records::float / total_records::float)
      ELSE 0.0
    END as percentage
  FROM total_attendance;
END;
$$; 