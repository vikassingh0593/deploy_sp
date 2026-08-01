-- Stored Procedure: sp_run_simulation
-- Reads from product_planning, applies conditional transformations based on
-- a JSON payload, and returns the simulated result as a result set (no writes).
--
-- Payload format:
-- {
--   "filters":    { "region": "APAC", "product_id": "P100" },
--   "demand":     { "product_id": "P100", "demand": 500 },
--   "supply":     { "product_id": "P100", "supply": 300 },
--   "simulation": { "product_id": "P100", "price_change": 10 }
-- }
--
-- Rules:
--   - If filters are missing, all rows are returned.
--   - If demand is missing or = -1, original demand value is kept.
--   - If supply is missing or = -1, original supply value is kept.
--   - If simulation is missing or price_change = -1, original price is kept.
--   - Nothing is written to the table. The result is returned as a dataframe.

CREATE OR REPLACE PROCEDURE dev_catalog.analytics.sp_run_simulation(IN payload STRING)
LANGUAGE SQL
SQL SECURITY DEFINER
BEGIN

  -- =====================================================
  -- Parse all values from the JSON payload
  -- =====================================================
  DECLARE v_filter_region       STRING;
  DECLARE v_filter_product_id   STRING;
  DECLARE v_demand_product_id   STRING;
  DECLARE v_demand_value        INT;
  DECLARE v_supply_product_id   STRING;
  DECLARE v_supply_value        INT;
  DECLARE v_sim_product_id      STRING;
  DECLARE v_sim_price_change    DECIMAL(18, 2);

  SET v_filter_region       = payload:filters.region::STRING;
  SET v_filter_product_id   = payload:filters.product_id::STRING;
  SET v_demand_product_id   = payload:demand.product_id::STRING;
  SET v_demand_value        = payload:demand.demand::INT;
  SET v_supply_product_id   = payload:supply.product_id::STRING;
  SET v_supply_value        = payload:supply.supply::INT;
  SET v_sim_product_id      = payload:simulation.product_id::STRING;
  SET v_sim_price_change    = payload:simulation.price_change::DECIMAL(18, 2);

  -- =====================================================
  -- Return the simulated result set (read-only, no writes)
  -- =====================================================
  SELECT
    product_id,
    region,

    -- Demand: override if payload has a matching product_id and demand != -1, else keep original
    CASE
      WHEN v_demand_value IS NOT NULL
       AND v_demand_value != -1
       AND product_id = v_demand_product_id
      THEN v_demand_value
      ELSE demand
    END AS demand,

    -- Supply: override if payload has a matching product_id and supply != -1, else keep original
    CASE
      WHEN v_supply_value IS NOT NULL
       AND v_supply_value != -1
       AND product_id = v_supply_product_id
      THEN v_supply_value
      ELSE supply
    END AS supply,

    -- Price: adjust if simulation has a matching product_id and price_change != -1, else keep original
    CASE
      WHEN v_sim_price_change IS NOT NULL
       AND v_sim_price_change != -1
       AND product_id = v_sim_product_id
      THEN price + v_sim_price_change
      ELSE price
    END AS price,

    -- Flag rows that were simulated
    CASE
      WHEN (v_demand_value IS NOT NULL AND v_demand_value != -1 AND product_id = v_demand_product_id)
        OR (v_supply_value IS NOT NULL AND v_supply_value != -1 AND product_id = v_supply_product_id)
        OR (v_sim_price_change IS NOT NULL AND v_sim_price_change != -1 AND product_id = v_sim_product_id)
      THEN TRUE
      ELSE FALSE
    END AS simulation_flag,

    CURRENT_TIMESTAMP() AS simulated_at

  FROM dev_catalog.analytics.product_planning

  -- Apply filters only if they are present in the payload
  WHERE (v_filter_region IS NULL     OR region     = v_filter_region)
    AND (v_filter_product_id IS NULL OR product_id = v_filter_product_id)

  ORDER BY product_id, region;

END;
