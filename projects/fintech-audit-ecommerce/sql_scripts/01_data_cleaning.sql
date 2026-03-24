-- =============================================================================
-- PROJECT: Financial Data Integrity Audit (theLook eCommerce)
-- STEP 01: DATA CLEANING & QUALITY GATEKEEPER
-- AUTHOR: Damian Jankowiak
-- PURPOSE: This script acts as a "Quality Gate". Before performing Lead Time 
--          Analysis (02) and RFM Segmentation (03), we must ensure 100% 
--          reliability in 4 critical domains.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- AUDIT 1: STRUCTURAL INTEGRITY (PK & FK Check)
-- WHY: RFM (03) relies on counting orders per user. If IDs are duplicated 
--      or orphaned, customer value metrics will be falsified.
-- -----------------------------------------------------------------------------

-- 1.1 KPI: Uniqueness & Relationship Health
WITH integrity_stats AS (
    SELECT 
        'Orders/Users' AS check_type,
        COUNT(o.order_id) AS total_records,
        COUNT(DISTINCT o.order_id) AS unique_orders,
        COUNTIF(u.id IS NULL) AS orphan_users
    FROM `bigquery-public-data.thelook_ecommerce.orders` AS o
    LEFT JOIN `bigquery-public-data.thelook_ecommerce.users` AS u ON o.user_id = u.id
)
SELECT 
    total_records,
    (total_records - unique_orders) AS duplicate_count,
    orphan_users,
    IF(total_records = unique_orders AND orphan_users = 0, 'PASS', 'FAIL') AS audit_status
FROM integrity_stats;

-- 1.2 EVIDENCE: List of orphan orders (Orders without existing Users)
SELECT o.order_id, o.user_id
FROM `bigquery-public-data.thelook_ecommerce.orders` AS o
LEFT JOIN `bigquery-public-data.thelook_ecommerce.users` AS u ON o.user_id = u.id
WHERE u.id IS NULL;


-- -----------------------------------------------------------------------------
-- AUDIT 2: FINANCIAL HEALTH (Nulls & Range Validation)
-- WHY: To calculate Profit Margins in 02_advanced_analysis, we cannot have 
--      NULL or negative prices. This ensures the "Order-to-Cash" logic is sound.
-- -----------------------------------------------------------------------------

-- 2.1 KPI: Price & Cost Completeness
SELECT 
    'Order Items' AS table_name,
    COUNT(*) AS total_rows,
    COUNTIF(sale_price IS NULL OR sale_price <= 0) AS invalid_price_count,
    COUNTIF(inventory_item_id IS NULL) AS missing_inventory_link
FROM `bigquery-public-data.thelook_ecommerce.order_items`;

-- 2.2 EVIDENCE: Transactions with zero or negative sale price
-- Value Add: Identifies potential "Revenue Leakage" or system pricing errors.
SELECT id, order_id, product_id, sale_price
FROM `bigquery-public-data.thelook_ecommerce.order_items`
WHERE sale_price <= 0 OR sale_price IS NULL;


-- -----------------------------------------------------------------------------
-- AUDIT 3: TIMELINE LOGIC (Event Sequence Audit)
-- WHY: Crucial for Lead Time Analysis (02). If 'Delivered' happens before 
--      'Shipped', the logistics efficiency report will be fraudulent.
-- -----------------------------------------------------------------------------

-- 3.1 KPI: Timeline Consistency (Completed Orders Only)
WITH timeline_check AS (
    SELECT 
        COUNT(*) AS total_completed,
        COUNTIF(shipped_at < created_at OR delivered_at < shipped_at) AS sequence_errors
    FROM `bigquery-public-data.thelook_ecommerce.orders`
    WHERE status = 'Complete'
)
SELECT 
    total_completed,
    sequence_errors,
    ROUND((1 - (sequence_errors / total_completed)) * 100, 2) AS chronology_accuracy_pct
FROM timeline_check;

-- 3.2 EVIDENCE: "Time-traveling" records
-- Value Add: Essential for IFRS 16 Cut-off tests and logistics auditing.
SELECT order_id, created_at, shipped_at, delivered_at
FROM `bigquery-public-data.thelook_ecommerce.orders`
WHERE status = 'Complete' 
  AND (shipped_at < created_at OR delivered_at < shipped_at);


-- -----------------------------------------------------------------------------
-- AUDIT 4: PROCESS CONSISTENCY (Status & Standardization)
-- WHY: RFM and Revenue reports must exclude non-finalized states (Cancelled/Error).
--      Ensures we only analyze "Real" business activity.
-- -----------------------------------------------------------------------------

-- 4.1 KPI: Status Dictionary Audit
SELECT 
    status,
    COUNT(*) AS count,
    CASE 
        WHEN status IN ('Shipped', 'Complete', 'Returned', 'Cancelled', 'Processing') THEN 'VALID'
        ELSE 'UNKNOWN - INVESTIGATE'
    END AS process_status
FROM `bigquery-public-data.thelook_ecommerce.orders`
GROUP BY 1;

-- 4.2 EVIDENCE: Unexpected status values
SELECT order_id, status, user_id
FROM `bigquery-public-data.thelook_ecommerce.orders`
WHERE status NOT IN ('Shipped', 'Complete', 'Returned', 'Cancelled', 'Processing');