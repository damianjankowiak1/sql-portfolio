-- =============================================================================
-- PROJECT: Financial Data Integrity Audit (theLook eCommerce)
-- STEP 02: ADVANCED BUSINESS INTELLIGENCE & PROCESS AUDIT
-- AUTHOR: Damian Jankowiak
-- PURPOSE: Transforming audited data into actionable business insights. 
--          Focus: Logistics Efficiency, Profitability Gaps, and Bottlenecks.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- TASK A: WAREHOUSE SLA & NETWORK PERFORMANCE BENCHMARKING
-- BUSINESS QUESTION: Which Distribution Centers (DC) are consistently breaching 
--                    the 24h Internal Processing SLA, and how does this 
--                    impact our Global Logistics Network?
-- AUDIT SHIELD: AUDIT 3 (Timeline Logic) ensures no negative Lead Times 
--               falsify these operational benchmarks.
-- -----------------------------------------------------------------------------

/* EXPECTED INSIGHTS:
1. Identifying the "Bottleneck DCs" where picking/packing exceeds the 24h target.
2. Quantifying the SLA Breach Rate (%) as a primary Logistics KPI.
3. Benchmarking local DC performance against the Global Network Average.
*/

-- A.1 ANALYTICAL QUERY (Package-Level Precision)
WITH item_dc_performance AS (
    SELECT 
        dc.name AS dc_name,
        oi.id AS item_id,
        -- Internal DC Time: Time from order placement to warehouse departure
        TIMESTAMP_DIFF(oi.shipped_at, oi.created_at, HOUR) AS internal_hrs,
        -- External Logistics Time: Time from warehouse to customer's door
        TIMESTAMP_DIFF(oi.delivered_at, oi.shipped_at, HOUR) AS external_hrs
    FROM `bigquery-public-data.thelook_ecommerce.order_items` oi
    JOIN `bigquery-public-data.thelook_ecommerce.inventory_items` ii 
        ON oi.inventory_item_id = ii.id
    JOIN `bigquery-public-data.thelook_ecommerce.distribution_centers` dc 
        ON ii.product_distribution_center_id = dc.id
    WHERE oi.status = 'Complete'
),
dc_metrics AS (
    SELECT 
        dc_name,
        COUNT(item_id) AS items_shipped,
        COUNTIF(internal_hrs > 24) AS items_breach_sla,
        ROUND(AVG(internal_hrs), 2) AS avg_internal_lead_time,
        ROUND(AVG(external_hrs), 2) AS avg_external_lead_time,
        -- SLA Calculation: Percentage of items failing the 24h internal target
        ROUND(SAFE_DIVIDE(COUNTIF(internal_hrs > 24), COUNT(*)) * 100, 2) AS sla_breach_pct,
        -- Window Functions: Global Network Benchmarks
        ROUND(AVG(AVG(internal_hrs)) OVER(), 2) AS global_avg_internal_lead,
        ROUND(AVG(SAFE_DIVIDE(COUNTIF(internal_hrs > 24), COUNT(*)) * 100) OVER(), 2) AS global_sla_avg_breach_rate
    FROM item_dc_performance
    GROUP BY dc_name
),
final_logic_layer AS (
    SELECT 
        *,
        ROUND(avg_internal_lead_time - global_avg_internal_lead, 2) AS internal_to_global_variance,
        -- Operational Status Logic
        CASE 
            WHEN sla_breach_pct > (global_sla_avg_breach_rate * 1.2) THEN 'CRITICAL - BOTTLENECK'
            WHEN sla_breach_pct > global_sla_avg_breach_rate THEN 'WARNING - HIGH BREACH'
            ELSE 'EFFICIENT'
        END AS sla_operational_status,
        -- Time Performance Logic
        CASE 
            WHEN avg_internal_lead_time > (global_avg_internal_lead * 1.1) THEN 'CRITICAL - SLOW PROCESS'
            WHEN avg_internal_lead_time > global_avg_internal_lead THEN 'WARNING - ABOVE AVG'
            ELSE 'OPTIMAL'
        END AS time_performance_status
    FROM dc_metrics
)
-- FINAL REPORTING LAYER
SELECT 
    dc_name,
    items_shipped,
    avg_internal_lead_time,
    global_avg_internal_lead,
    internal_to_global_variance,
    sla_breach_pct,
    sla_operational_status,
    time_performance_status,
    avg_external_lead_time AS carrier_performance_hrs
FROM final_logic_layer
ORDER BY sla_breach_pct DESC;

/* MOCK OUTPUT / INSIGHT EXAMPLE:
|    dc_name    | items_shipped | avg_internal_lead_time | sla_breach_pct | sla_operational_status |
|---------------|---------------|------------------------|----------------|------------------------|
| Savannah GA   | 2936          | 15.16 hrs              | 46.15%         | WARNING - HIGH BREACH  |
| Charleston SC | 4145          | 13.94 hrs              | 44.49%         | WARNING - HIGH BREACH  |
*/


-- -----------------------------------------------------------------------------
-- TASK B: PROFITABILITY AUDIT & RETURN LEAKAGE (IFRS COMPLIANCE)
-- BUSINESS QUESTION: Which product categories act as "Profit Killers" due to 
--                    high return rates, and what is the real Net Margin 
--                    after accounting for "Toxic Returns"?
-- AUDIT SHIELD: AUDIT 2 (Financial Health) ensures no $0 or negative prices 
--               distort the Gross Margin calculation.
-- -----------------------------------------------------------------------------

/* EXPECTED INSIGHTS:
1. Distinguishing between Gross Profit (Theoretical) and Net Profit (Realized).
2. Identifying categories where the Return Rate exceeds the 10% safety threshold.
3. Quantifying "Profit Leakage" – the capital locked in returned inventory.
*/

-- B.1 ANALYTICAL QUERY
WITH product_economics AS (
    SELECT 
        p.category,
        oi.id AS item_id,
        oi.sale_price,
        ii.cost,
        oi.status,
        (oi.sale_price - ii.cost) AS unit_gross_margin
    FROM `bigquery-public-data.thelook_ecommerce.order_items` oi
    JOIN `bigquery-public-data.thelook_ecommerce.products` p ON oi.product_id = p.id
    JOIN `bigquery-public-data.thelook_ecommerce.inventory_items` ii ON oi.inventory_item_id = ii.id
    WHERE oi.status != 'Cancelled'
),
category_financials AS (
    SELECT 
        category,
        COUNT(item_id) AS items_sold,
        COUNTIF(status = 'Returned') AS items_returned,
        -- FINANCIALS
        ROUND(SUM(unit_gross_margin), 2) AS forecast_gross_profit, -- add an exclusion for 'Returned'
        ROUND(SUM(CASE WHEN status = 'Complete' THEN unit_gross_margin ELSE 0 END), 2) AS net_profit_usd,
        ROUND(SUM(CASE WHEN status = 'Returned' THEN unit_gross_margin ELSE 0 END), 2) AS net_leakage_usd
    FROM product_economics
    GROUP BY category
),
efficiency_layer AS (
    SELECT 
        *,
        -- RETURN RATE %
        ROUND(SAFE_DIVIDE(items_returned, items_sold) * 100, 2) AS return_rate_pct,
        -- EFFICIENCY RATIO: Loss Net / Profit Net
        ROUND(SAFE_DIVIDE(net_leakage_usd, net_profit_usd) * 100, 2) AS leakage_to_profit_ratio_pct,
        -- WINDOW FUNCTIONS (BENCHMARKS)
        ROUND(AVG(SAFE_DIVIDE(items_returned, items_sold) * 100) OVER(), 2) AS global_avg_return_rate,
        ROUND(AVG(SAFE_DIVIDE(net_leakage_usd, net_profit_usd) * 100) OVER(), 2) AS global_avg_leakage_ratio
    FROM category_financials
),
final_risk_scoring AS (
    SELECT 
        *,
        -- SCORING LOGIC
        CASE 
            WHEN leakage_to_profit_ratio_pct > (global_avg_leakage_ratio * 1.5) THEN 'CRITICAL - UNHEALTHY MARGIN'
            WHEN leakage_to_profit_ratio_pct > global_avg_leakage_ratio THEN 'WARNING - LOW EFFICIENCY'
            ELSE 'OPTIMAL'
        END AS efficiency_status,
		CASE 
            WHEN (net_profit_usd * (return_rate_pct / 100)) > 10000 THEN 'URGENT - HIGH VALUE LOSS'
            ELSE 'ROUTINE'
        END AS audit_priority
    FROM efficiency_layer
)
-- FINAL REPORTING LAYER
SELECT 
    category,
    items_sold,
    items_returned,
    return_rate_pct,
    global_avg_return_rate,
    forecast_gross_profit AS forecast_profit_usd, -- currently counts returned, to be changed
    net_profit_usd,
    net_leakage_usd,
    leakage_to_profit_ratio_pct,
    global_avg_leakage_ratio AS global_avg_leakage_pct,
    efficiency_status,
    audit_priority
FROM final_risk_scoring
ORDER BY 
	CASE
		WHEN efficiency_status = 'CRITICAL - UNHEALTHY MARGIN' THEN 1
		WHEN efficiency_status = 'WARNING - LOW EFFICIENCY' THEN 2
		ELSE 3
	END ASC, 
    CASE
        WHEN audit_priority = 'URGENT - HIGH VALUE LOSS' THEN 1
        ELSE 2
    END ASC;

/* MOCK OUTPUT / INSIGHT EXAMPLE:
| category      | return_rate_pct | leakage_to_profit_ratio_pct | efficiency_status         | audit_priority  |
|---------------|-----------------|-----------------------------|---------------------------|-----------------|
| Clothing Sets | 10.99%          | 52.2%                       | WARNING - LOW EFFICIENCY  | ROUTINE         |
| Intimates     | 12.10%          | 41.54%                      | WARNING - LOW EFFICIENCY  | ROUTINE         |
*/


-- -----------------------------------------------------------------------------
-- TASK C: DYNAMIC CAPACITY & YEAR-OVER-YEAR (YoY) VOLATILITY AUDIT
-- BUSINESS QUESTION: Is our current logistics volume scaling sustainably 
--                    compared to last year (YoY) and the last 4 weeks (L4W)? 
--                    Where are the critical capacity breaches?
-- AUDIT SHIELD: AUDIT 1 (Uniqueness) prevents phantom volume spikes from 
--               duplicated order records.
-- -----------------------------------------------------------------------------

/* EXPECTED INSIGHTS:
1. YoY Growth Tracking: Comparing daily performance against the same date in 2025.
2. L4W Benchmarking: Using a 28-day baseline to detect short-term operational stress.
3. Capacity Alerts: Distinguishing between 'Extreme Spikes' and 'Underutilization' 
   to optimize warehouse labor costs.
*/

-- C.1 ANALYTICAL QUERY
WITH daily_logistics_load AS (
    SELECT 
        DATE(created_at) AS order_date,
        COUNT(order_id) AS daily_volume
    FROM `bigquery-public-data.thelook_ecommerce.orders`
    WHERE created_at >= '2022-01-01'
    GROUP BY 1
),
time_shifted_benchmarks AS (
    SELECT 
        curr_year.order_date,
        curr_year.daily_volume,
        prev_year.daily_volume AS ly_daily_volume -- same day last year
    FROM daily_logistics_load curr_year
    LEFT JOIN daily_logistics_load prev_year 
        ON DATE_SUB(curr_year.order_date, INTERVAL 1 YEAR) = prev_year.order_date 
),
moving_average_layer AS (
    SELECT 
        order_date,
        daily_volume,
        ly_daily_volume,
        -- Last 7 days
        ROUND(AVG(daily_volume) OVER (
            ORDER BY order_date 
            ROWS BETWEEN 6 PRECEDING AND 1 PRECEDING
        ), 2) AS weekly_volume,
        -- Last 4 weeks (L4W)
        ROUND(AVG(daily_volume) OVER (
            ORDER BY order_date 
            ROWS BETWEEN 28 PRECEDING AND 1 PRECEDING
        ), 2) AS l4w_avg_volume,
        -- YTD (Year-to-Date)
        SUM(daily_volume) OVER (
            PARTITION BY EXTRACT(YEAR FROM order_date) 
            ORDER BY order_date
        ) AS ytd_volume,
    FROM time_shifted_benchmarks
),
volatility_scoring AS (
    SELECT 
        *,
        -- L4W devation (Key KPI)
        ROUND(SAFE_DIVIDE(daily_volume - l4w_avg_volume, l4w_avg_volume) * 100, 2) AS variance_vs_l4w_pct,
        -- Year-over-Year devation
        ROUND(SAFE_DIVIDE(daily_volume - ly_daily_volume, ly_daily_volume) * 100, 2) AS yoy_growth_pct,
        CASE 
            WHEN daily_volume > (l4w_avg_volume * 1.4) THEN 'CRITICAL - CAPACITY BREACH'
            WHEN daily_volume > (l4w_avg_volume * 1.2) THEN 'WARNING - VOLUME SPIKE'
            WHEN daily_volume < (l4w_avg_volume * 0.7) THEN 'ADVISORY - UNDERUTILIZATION'
            ELSE 'STABLE'
        END AS operational_status
    FROM moving_average_layer
)
-- FINAL REPORTING LAYER
SELECT 
    order_date,
    daily_volume,
    ly_daily_volume AS py_daily_volume,
    yoy_growth_pct AS yoy_delta_pct,
    l4w_avg_volume AS benchmark_l4w,
    variance_vs_l4w_pct AS l4w_variance_pct,
    ytd_volume,
    operational_status
FROM volatility_scoring
WHERE order_date >= '2024-01-01'
ORDER BY order_date DESC;

/* MOCK OUTPUT / INSIGHT EXAMPLE:
| order_date | daily_volume | yoy_delta_pct | l4w_variance_pct | operational_status         |
|------------|--------------|---------------|------------------|----------------------------|
| 2026-03-22 | 1763         | +2103.75%     | +456.91%         | CRITICAL - CAPACITY BREACH |
| 2026-03-21 | 1089         | +1046.32%     | +281.96%         | CRITICAL - CAPACITY BREACH |
*/




/* 
-----------------------------------------------------------------------------
AI COLLABORATION LOG & HUMAN AUDIT:
-----------------------------------------------------------------------------
1. GRANULARITY PIVOT (Human): Rejected the initial Order-level analysis 
   in favor of Item-level (SKU) tracking. This ensures DC performance 
   isn't skewed by multi-fulfillment orders across different warehouses.
2. BUSINESS METRIC DESIGN (Human): Defined the "SLA Breach Rate" (24h) 
   as the primary logistics KPI, moving away from generic lead-time averages 
   suggested by AI.
3. FINANCIAL INTEGRATION (Human): Built the "Profit Erosion" model in Task B, 
   calculating Margin Leakage. Identified the need to separate Theoretical 
   Forecast from Realized Net Profit.
4. CONTEXTUAL INTELLIGENCE (Human): Introduced L4W (Last 4 Weeks) benchmarks 
   to Task C to distinguish between seasonal trends and operational failures.
5. IMPLEMENTATION (AI): Syntax generation for complex Window Functions 
   (AVG() OVER()) and timestamp arithmetic (TIMESTAMP_DIFF).
-----------------------------------------------------------------------------
*/