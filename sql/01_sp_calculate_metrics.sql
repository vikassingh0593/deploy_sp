CREATE OR REPLACE PROCEDURE ${catalog}.${schema}.sp_calculate_metrics(IN target_date DATE)
LANGUAGE SQL
AS
$$
  INSERT INTO ${catalog}.${schema}.daily_metrics
  SELECT 
    customer_id, 
    SUM(amount) AS total_spend
  FROM ${catalog}.${schema}.orders
  WHERE order_date = target_date
  GROUP BY customer_id;
$$;
