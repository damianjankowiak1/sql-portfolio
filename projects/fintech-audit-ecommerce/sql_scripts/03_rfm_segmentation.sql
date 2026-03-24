-- =============================================================================
-- PROJECT: Strategic CRM Audit (theLook eCommerce)
-- STEP 03: ADVANCED RFM CUSTOMER SEGMENTATION & PLAYBOOK
-- AUTHOR: Damian Jankowiak
-- PURPOSE: Advanced behavioral segmentation engine to drive marketing ROI
--          and identify high-value customer clusters.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- TASK: RFM ENGINE WITH STRATEGIC PLAYBOOK
-- BUSINESS QUESTION: How can we translate raw transaction history into 
--                    targeted marketing actions and churn prevention?
-- -----------------------------------------------------------------------------

/* VALUE ADD:
1. Identifying "Whales" & "Champions" who drive the majority of Net Revenue.
2. Automating the decision-making process for CRM & Loyalty programs.
3. Quantifying "At Risk" segments to prioritize immediate retention efforts.
*/

-- 1.1 DATA AGGREGATION LAYER (Raw Metrics)
WITH customer_metrics AS (
    -- STEP 1: Aggregating Raw RFM Data
    SELECT 
        user_id,
        DATE_DIFF(CURRENT_DATE(), MAX(DATE(created_at)), DAY) AS recency_days,
        COUNT(order_id) AS frequency_count,
        SUM(sale_price) AS monetary_value -- No rounding here yet
    FROM `bigquery-public-data.thelook_ecommerce.order_items`
    WHERE 
        DATE(created_at) >= DATE_SUB(CURRENT_DATE(), INTERVAL 1 YEAR)
        AND DATE(created_at) <= CURRENT_DATE()
        AND status NOT IN ('Cancelled', 'Returned')
    GROUP BY 1
),

rfm_scores AS (
    -- STEP 2: Statistical Quintile Ranking
    SELECT 
        *,
        NTILE(5) OVER(ORDER BY recency_days DESC) AS r_score,
        NTILE(5) OVER(ORDER BY frequency_count ASC) AS f_score,
        NTILE(5) OVER(ORDER BY monetary_value ASC) AS m_score
    FROM customer_metrics
),

rfm_segments AS (
    -- STEP 3: Mapping Behavior to Strategic Segments
    SELECT 
        *,
        CASE 
            WHEN r_score >= 4 AND f_score >= 4 AND m_score >= 4 THEN 'CHAMPIONS'
            WHEN r_score >= 4 AND f_score >= 3 AND m_score >= 3 THEN 'LOYAL CUSTOMERS'
            WHEN r_score >= 4 AND f_score <= 2 THEN 'NEW / PROMISING'
            WHEN r_score >= 3 AND f_score <= 2 AND m_score >= 4 THEN 'BIG SPENDERS / WHALES'
            WHEN r_score <= 2 AND f_score >= 3 AND m_score >= 3 THEN 'AT RISK - HIGH VALUE'
            WHEN f_score >= 4 AND m_score <= 2 THEN 'LOW-VALUE BARGAIN HUNTERS'
            WHEN r_score <= 2 AND f_score <= 2 AND m_score <= 2 THEN 'HIBERNATING / LOST'
            ELSE 'POTENTIAL LOYALISTS / OTHERS'
        END AS rfm_segment
    FROM rfm_scores
),

final_playbook_logic AS (
    -- STEP 4: Strategic Playbook (Business Logic Layer)
    SELECT
        *,
        CASE rfm_segment
            WHEN 'CHAMPIONS' THEN 'Reward & Retain'
            WHEN 'LOYAL CUSTOMERS' THEN 'Increase AOV'
            WHEN 'NEW / PROMISING' THEN 'Build Habit'
            WHEN 'BIG SPENDERS / WHALES' THEN 'High-Touch Service'
            WHEN 'AT RISK - HIGH VALUE' THEN 'Immediate Win-Back'
            WHEN 'LOW-VALUE BARGAIN HUNTERS' THEN 'Protect Margin'
            WHEN 'HIBERNATING / LOST' THEN 'Minimize Waste'
            ELSE 'Re-evaluate Segment'
        END AS strategic_goal,
        CASE rfm_segment
            WHEN 'CHAMPIONS' THEN 'Exclusive early access; VIP events; Personal manager.'
            WHEN 'LOYAL CUSTOMERS' THEN 'Cross-sell; Tier-based rewards; Bundle offers.'
            WHEN 'NEW / PROMISING' THEN 'Onboarding sequence; 30-day second purchase discount.'
            WHEN 'BIG SPENDERS / WHALES' THEN 'White-glove delivery; Priority support.'
            WHEN 'AT RISK - HIGH VALUE' THEN 'Personalized win-back; 20%+ reactivation coupon.'
            WHEN 'LOW-VALUE BARGAIN HUNTERS' THEN 'Free delivery threshold; Clearance notifications.'
            WHEN 'HIBERNATING / LOST' THEN 'Final reactivation; Clean from list.'
            ELSE 'Standard communication.'
        END AS suggested_action,
        CASE rfm_segment
            WHEN 'CHAMPIONS' THEN 1 
			WHEN 'LOYAL CUSTOMERS' THEN 2 
            WHEN 'NEW / PROMISING' THEN 3 
			WHEN 'BIG SPENDERS / WHALES' THEN 4 
            WHEN 'AT RISK - HIGH VALUE' THEN 5 
			WHEN 'LOW-VALUE BARGAIN HUNTERS' THEN 6 
            WHEN 'HIBERNATING / LOST' THEN 7 
			ELSE 8
        END AS rfm_order
    FROM rfm_segments
),

formatted_report AS (
    -- STEP 5: Formatting Layer (The "Clean" Table)
    SELECT
        rfm_segment,
        COUNT(user_id) AS customer_count,
        SUM(monetary_value) AS segment_revenue,
        AVG(monetary_value) AS segment_avg_monetary,
        strategic_goal,
        suggested_action,
        rfm_order
    FROM final_playbook_logic
    GROUP BY 1, 5, 6, 7
)

-- FINAL OUTPUT: The "CEO View"
SELECT 
    rfm_segment,
    customer_count,
    ROUND(customer_count / SUM(customer_count) OVER() * 100, 2) AS pct_of_base,
    ROUND(segment_revenue, 2) AS revenue_usd,
    ROUND(segment_revenue / SUM(segment_revenue) OVER() * 100, 2) AS revenue_share_pct,
    ROUND(segment_avg_monetary, 2) AS avg_monetary_usd,
    strategic_goal,
    suggested_action
FROM formatted_report
ORDER BY rfm_order ASC;

/* MOCK OUTPUT / STRATEGIC INSIGHT:
| rfm_segment     | customer_count | pct_of_base    | avg_monetary_usd   | strategic_goal  |
|-----------------|----------------|----------------|--------------------|-----------------|
| CHAMPIONS       | 8161           | 14.54%         | 246.39             | Reward & Retain |
| LOYAL CUSTOMERS | 4629           | 6.0%           | 100.84             | Increase AOV    |
*/




/* 
-----------------------------------------------------------------------------
AI COLLABORATION LOG & HUMAN AUDIT:
-----------------------------------------------------------------------------
1. STRATEGIC PLAYBOOK (Human): Transformed raw RFM scores into an actionable 
   "Strategic Playbook" by mapping segments to specific business goals 
   (e.g., Churn Prevention vs. Loyalty Rewards).
2. OPERATIONAL RELEVANCE (Human): Implemented a dynamic 1-year rolling window 
   (INTERVAL 1 YEAR) to filter out historical noise and focus the analysis 
   on active customers, ensuring the report reflects current business health.
3. REPORTING LAYER (Human): Designed the "CEO View" summary, prioritizing 
   % of Revenue Share and Customer Count for high-level decision making.
4. IMPLEMENTATION (AI): Optimized the NTILE(5) scoring logic and CTE-based 
   layering for final report formatting.
-----------------------------------------------------------------------------
*/