CREATE OR REPLACE PROCEDURE ${catalog}.${schema}.sp_clean_staging(IN days_to_keep INT)
LANGUAGE SQL
AS
$$
DECLARE
  cutoff_date DATE;
BEGIN
  -- If retention period is null, default to 30 days
  IF days_to_keep IS NULL OR days_to_keep < 0 THEN
    SET days_to_keep = 30;
  END IF;

  SET cutoff_date = DATE_SUB(CURRENT_DATE(), days_to_keep);

  -- Delete older records from staging
  DELETE FROM ${catalog}.${schema}.staging_table 
  WHERE arrival_timestamp < CAST(cutoff_date AS TIMESTAMP);
END;
$$;
