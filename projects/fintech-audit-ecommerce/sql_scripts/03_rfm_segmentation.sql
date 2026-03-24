-- =============================================================================
-- PROJECT: Financial Data Integrity Audit (theLook eCommerce)
-- STEP 03: STRATEGIC CUSTOMER SEGMENTATION (RFM MODEL)
-- AUTHOR: Damian Jankowiak
-- PURPOSE: Classifying the customer base into 10 strategic segments based on 
--          Recency, Frequency, and Monetary value.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- TASK: RFM ENGINE (RECENCY, FREQUENCY, MONETARY)
-- BUSINESS QUESTION: Who are our "Champions" (High Value), and who are our 
--                    "At Risk" customers (Churn potential)?
-- AUDIT SHIELD: AUDIT 1 & 2 (Uniqueness & Financial Health) ensure that 
--               Lifetime Value (LTV) is not inflated by duplicates or $0 prices.
-- -----------------------------------------------------------------------------

/* VALUE ADD:
1. Targeted Marketing: Stop wasting budget on "Lost" customers, focus on "Loyalists".
2. Churn Prevention: Identify "Can't Lose Them" segment before they leave.
3. Revenue Optimization: Increase Average Order Value (AOV) via Upselling to "Promising" clients.
*/

-- 1.1 DATA AGGREGATION LAYER (Raw Metrics)
WITH customer_raw_metrics AS (
    SELECT 
        user_id,
        -- Recency: Days since last order
        DATE_DIFF(CURRENT_DATE(), MAX(DATE(created_at)), DAY) AS recency_days,
        -- Frequency: Total count of successful orders
        COUNT(order_id) AS frequency_count,
        -- Monetary: Total Net Revenue (Success only)
        ROUND(SUM(sale_price), 2) AS monetary_value
    FROM `bigquery-public-data.thelook_ecommerce.order_items`
    WHERE status NOT IN ('Cancelled', 'Returned') -- Audit: Analyze only "Real Cash"
    GROUP BY 1
),

-- 1.2 SCORING LAYER (Quantile Ranking 1-5)
rfm_scores AS (
    SELECT 
        *,
        -- R Score: 5 is most recent (Lower days = Higher score)
        NTILE(5) OVER (ORDER BY recency_days DESC) AS r_score,
        -- F Score: 5 is most frequent
        NTILE(5) OVER (ORDER BY frequency_count ASC) AS f_score,
        -- M Score: 5 is highest spender
        NTILE(5) OVER (ORDER BY monetary_value ASC) AS m_score
    FROM customer_raw_metrics
),

-- 1.3 SEGMENTATION LOGIC (Strategic Classification)
rfm_segments AS (
    SELECT 
        *,
        CONCAT(CAST(r_score AS STRING), CAST(f_score AS STRING), CAST(m_score AS STRING)) AS rfm_cell,
        CASE 
            WHEN r_score >= 4 AND f_score >= 4 AND m_score >= 4 THEN 'CHAMPIONS'
            WHEN r_score >= 4 AND f_score >= 2 AND m_score >= 2 THEN 'LOYAL CUSTOMERS'
            WHEN r_score >= 3 AND f_score >= 3 AND m_score >= 1 THEN 'POTENTIAL LOYALISTS'
            WHEN r_score >= 4 AND f_score = 1 THEN 'NEW CUSTOMERS'
            WHEN r_score = 3 AND f_score <= 2 THEN 'ABOUT TO SLEEP'
            WHEN r_score <= 2 AND f_score >= 4 AND m_score >= 4 THEN 'CANNOT LOSE THEM'
            WHEN r_score <= 2 AND f_score <= 2 AND m_score <= 2 THEN 'LOST / HIBERNATING'
            ELSE 'NEED ATTENTION'
        END AS customer_segment
    FROM rfm_scores
)

-- 1.4 FINAL REPORTING LAYER (Executive Summary)
SELECT 
    customer_segment,
    COUNT(user_id) AS customer_count,
    ROUND(AVG(recency_days), 0) AS avg_recency,
    ROUND(AVG(frequency_count), 1) AS avg_frequency,
    ROUND(AVG(monetary_value), 2) AS avg_monetary,
    -- KPI: Share of Total Revenue per Segment
    ROUND(SUM(monetary_value) / SUM(SUM(monetary_value)) OVER() * 100, 2) AS revenue_share_pct,
    -- STRATEGIC ACTION
    CASE 
        WHEN customer_segment = 'CHAMPIONS' THEN 'REWARD & CROSS-SELL'
        WHEN customer_segment = 'CANNOT LOSE THEM' THEN 'HIGH-VALUE DISCOUNT / RETENTION'
        WHEN customer_segment = 'NEW CUSTOMERS' THEN 'ONBOARDING CAMPAIGN'
        WHEN customer_segment = 'LOST / HIBERNATING' THEN 'DO NOT SPEND'
        ELSE 'MONITOR'
    END AS marketing_action
FROM rfm_segments
GROUP BY 1
ORDER BY avg_monetary DESC;

/* MOCK OUTPUT / STRATEGIC INSIGHT:
| customer_segment   | customer_count | revenue_share_pct | marketing_action                |
|--------------------|----------------|-------------------|---------------------------------|
| CHAMPIONS          | 1250           | 45.20%            | REWARD & CROSS-SELL             |
| CANNOT LOSE THEM   | 450            | 12.80%            | HIGH-VALUE DISCOUNT / RETENTION |
| LOST / HIBERNATING | 5600           | 5.10%             | DO NOT SPEND                    |
*/