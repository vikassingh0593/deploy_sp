CREATE OR REPLACE PROCEDURE dev_catalog.analytics.sp_calculate_metrics(IN target_date DATE)
LANGUAGE SQL
SQL SECURITY DEFINER
BEGIN
  INSERT INTO dev_catalog.analytics.daily_metrics
  SELECT 
    customer_id, 
    SUM(amount) AS total_spend
  FROM dev_catalog.analytics.orders
  WHERE order_date = target_date
  GROUP BY customer_id;
END;
