-- =============================================================================
-- PROJECT: Financial Data Integrity Audit (theLook eCommerce)
-- STEP 02: ADVANCED BUSINESS INTELLIGENCE & PROCESS AUDIT
-- AUTHOR: Damian Jankowiak
-- PURPOSE: Transforming audited data into actionable business insights. 
--          Focus: Logistics Efficiency, Profitability Gaps, and Bottlenecks.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- TASK A: LEAD TIME & LOGISTICS PERFORMANCE BENCHMARKING
-- BUSINESS QUESTION: Which Distribution Centers (DC) are underperforming, 
--                    and what is the financial risk of delivery delays?
-- DATA SOURCE: Orders & Distribution Centers
-- -----------------------------------------------------------------------------

/* EXPECTED INSIGHTS:
1. Identify DCs where 'Creation-to-Shipment' exceeds the 24h internal SLA.
2. Compare each DC's performance against the Global Average using Window Functions.
3. High 'Shipment-to-Delivery' time indicates carrier issues (External Logistics Risk).
*/

-- A.1 ANALYTICAL QUERY
WITH dc_performance AS (
    SELECT 
        dc.name AS dc_name,
        o.order_id,
        -- Calculating time metrics in hours for precision
        TIMESTAMP_DIFF(o.shipped_at, o.created_at, HOUR) AS creation_to_ship_hrs,
        TIMESTAMP_DIFF(o.delivered_at, o.shipped_at, HOUR) AS ship_to_delivery_hrs
    FROM `bigquery-public-data.thelook_ecommerce.orders` o
    JOIN `bigquery-public-data.thelook_ecommerce.order_items` oi ON o.order_id = oi.order_id
    JOIN `bigquery-public-data.thelook_ecommerce.inventory_items` ii ON oi.inventory_item_id = ii.id
    JOIN `bigquery-public-data.thelook_ecommerce.distribution_centers` dc ON ii.product_distribution_center_id = dc.id
    WHERE o.status = 'Complete' -- Auditing only successful lifecycles
),
aggregated_metrics AS (
    SELECT 
        dc_name,
        ROUND(AVG(creation_to_ship_hrs), 2) AS avg_internal_lead_time,
        ROUND(AVG(ship_to_delivery_hrs), 2) AS avg_external_lead_time,
        -- Window Function: Global Average for comparison
        ROUND(AVG(AVG(creation_to_ship_hrs)) OVER(), 2) AS global_avg_internal
    FROM dc_performance
    GROUP BY dc_name
)
SELECT 
    dc_name,
    avg_internal_lead_time,
    avg_external_lead_time,
    global_avg_internal,
    -- Performance Ranking: How much slower/faster is this DC vs Global?
    ROUND(avg_internal_lead_time - global_avg_internal, 2) AS diff_vs_global,
    CASE 
        WHEN avg_internal_lead_time > (global_avg_internal * 1.1) THEN 'CRITICAL - SLOW PROCESS'
        WHEN avg_internal_lead_time > global_avg_internal THEN 'WARNING - ABOVE AVG'
        ELSE 'OPTIMAL'
    END AS performance_status
FROM aggregated_metrics
ORDER BY avg_internal_lead_time DESC;

/* MOCK OUTPUT / INSIGHT EXAMPLE:
| dc_name     | avg_internal_lead_time | global_avg_internal | diff_vs_global | performance_status      |
|-------------|------------------------|---------------------|----------------|-------------------------|
| Chicago     | 28.50                  | 24.10               | +4.40          | CRITICAL - SLOW PROCESS |
| Memphis     | 24.05                  | 24.10               | -0.05          | OPTIMAL                 |
| Los Angeles | 23.90                  | 24.10               | -0.20          | OPTIMAL                 |
*/


-- -----------------------------------------------------------------------------
-- TASK B: PROFITABILITY GAP & RETURN LEAKAGE ANALYSIS
-- BUSINESS QUESTION: Which product categories are "Profit Killers" due to 
--                    high return rates and low margins?
-- DATA SOURCE: Order_Items, Products, Inventory_Items
-- -----------------------------------------------------------------------------

/* EXPECTED INSIGHTS:
1. Identify "Gross Margin" (Theoretical Profit) vs "Net Profit" (After Returns).
2. Calculate 'Return Rate' per category to find where logistics costs eat the margin.
3. This audit prevents IFRS revenue overstatement by highlighting "Toxic Categories".
*/

-- B.1 ANALYTICAL QUERY
WITH product_financials AS (
    SELECT 
        p.category,
        oi.sale_price,
        ii.cost,
        -- Gross Profit per unit (Theoretical)
        (oi.sale_price - ii.cost) AS gross_profit_unit,
        -- Status check for return logic
        CASE WHEN oi.status = 'Returned' THEN 1 ELSE 0 END AS is_returned
    FROM `bigquery-public-data.thelook_ecommerce.order_items` oi
    JOIN `bigquery-public-data.thelook_ecommerce.products` p ON oi.product_id = p.id
    JOIN `bigquery-public-data.thelook_ecommerce.inventory_items` ii ON oi.inventory_item_id = ii.id
),
category_performance AS (
    SELECT 
        category,
        COUNT(*) AS total_sold,
        SUM(is_returned) AS total_returned,
        ROUND(AVG(sale_price), 2) AS avg_retail_price,
        ROUND(SUM(gross_profit_unit), 2) AS total_gross_profit,
        -- Calculating Return Rate %
        ROUND(SAFE_DIVIDE(SUM(is_returned), COUNT(*)) * 100, 2) AS return_rate_pct
    FROM product_financials
    GROUP BY category
)
SELECT 
    category,
    total_sold,
    return_rate_pct,
    total_gross_profit,
    -- Estimating "Return Impact": Profit lost due to returns
    ROUND(total_gross_profit * (return_rate_pct / 100), 2) AS estimated_profit_leakage,
    -- Final Business Ranking
    CASE 
        WHEN return_rate_pct > 15 THEN 'HIGH RISK - CATEGORY AUDIT NEEDED'
        WHEN return_rate_pct > 10 THEN 'WARNING - MONITOR RETURNS'
        ELSE 'STABLE'
    END AS financial_health_status
FROM category_performance
ORDER BY return_rate_pct DESC;

/* MOCK OUTPUT / INSIGHT EXAMPLE:
| category    | total_sold | return_rate_pct | total_gross_profit | estimated_profit_leakage | financial_health_status           |
|-------------|------------|-----------------|--------------------|--------------------------|-----------------------------------|
| Swimwear    | 5200       | 18.50           | 125,400.00         | 23,199.00                | HIGH RISK - CATEGORY AUDIT NEEDED |
| Accessories | 8900       | 9.20            | 210,500.00         | 19,366.00                | STABLE                            |
*/


-- -----------------------------------------------------------------------------
-- TASK C: OPERATIONAL BOTTLENECK ANALYSIS (MOVING AVERAGE)
-- BUSINESS QUESTION: Are we experiencing sudden volume spikes that could 
--                    paralyze our logistics? How does daily volume compare 
--                    to the weekly trend?
-- DATA SOURCE: Orders
-- -----------------------------------------------------------------------------

/* EXPECTED INSIGHTS:
1. Identify "Anomaly Days" where order volume exceeds the 7-day moving average by 50%.
2. This acts as an Early Warning System for Warehouse Staffing (Capacity Planning).
3. Helps distinguish between seasonal growth and sudden technical/marketing spikes.
*/

-- C.1 ANALYTICAL QUERY
WITH daily_orders AS (
    SELECT 
        DATE(created_at) AS order_date,
        COUNT(order_id) AS daily_volume
    FROM `bigquery-public-data.thelook_ecommerce.orders`
    WHERE created_at >= '2023-01-01' -- Focusing on recent operational period
    GROUP BY 1
),
moving_averages AS (
    SELECT 
        order_date,
        daily_volume,
        -- Window Function: 7-day Moving Average (Centralized Trend)
        ROUND(AVG(daily_volume) OVER (
            ORDER BY order_date 
            ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
        ), 2) AS weekly_rolling_avg
    FROM daily_orders
)
SELECT 
    order_date,
    daily_volume,
    weekly_rolling_avg,
    -- Calculating Variance: How much does today deviate from the trend?
    ROUND(SAFE_DIVIDE(daily_volume - weekly_rolling_avg, weekly_rolling_avg) * 100, 2) AS pct_deviation,
    CASE 
        WHEN daily_volume > (weekly_rolling_avg * 1.5) THEN 'BOTTLENECK RISK - EXTREME SPIKE'
        WHEN daily_volume > (weekly_rolling_avg * 1.2) THEN 'VOLATILITY WARNING'
        ELSE 'STABLE'
    END AS operational_status
FROM moving_averages
ORDER BY order_date DESC;

/* MOCK OUTPUT / INSIGHT EXAMPLE:
| order_date | daily_volume | weekly_rolling_avg | pct_deviation | operational_status             |
|------------|--------------|--------------------|---------------|--------------------------------|
| 2024-05-20 | 450          | 300.20             | +49.90        | VOLATILITY WARNING             |
| 2024-05-19 | 510          | 295.10             | +72.82        | BOTTLENECK RISK - EXTREME SPIKE|
| 2024-05-18 | 280          | 290.50             | -3.61         | STABLE                         |
*/