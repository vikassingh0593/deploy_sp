CREATE OR REPLACE PROCEDURE dev_catalog.analytics.sp_clean_staging(IN days_to_keep INT)
LANGUAGE SQL
SQL SECURITY DEFINER
BEGIN
  DECLARE cutoff_date DATE;

  -- If retention period is null, default to 30 days
  IF days_to_keep IS NULL OR days_to_keep < 0 THEN
    SET days_to_keep = 30;
  END IF;

  SET cutoff_date = DATE_SUB(CURRENT_DATE(), days_to_keep);

  -- Delete older records from staging
  DELETE FROM dev_catalog.analytics.staging_table 
  WHERE arrival_timestamp < CAST(cutoff_date AS TIMESTAMP);
END;
