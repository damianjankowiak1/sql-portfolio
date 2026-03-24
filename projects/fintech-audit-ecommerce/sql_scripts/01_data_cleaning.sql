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
-- WHY: RFM (03) relies on counting orders per user. Duplicate IDs or orphaned
--      orders will inflate Customer Lifetime Value (CLV) and corrupt joins.
-- -----------------------------------------------------------------------------

-- 1.1 KPI: Uniqueness & Relationship Health
WITH integrity_stats AS (
    SELECT 
        COUNT(*) AS total_orders,
        COUNT(DISTINCT o.order_id) AS unique_orders,
        COUNTIF(o.order_id IS NULL) AS order_null_pks,
        COUNTIF(u.id IS NULL) AS orphan_orders
    FROM `bigquery-public-data.thelook_ecommerce.orders` o
    LEFT JOIN `bigquery-public-data.thelook_ecommerce.users` u ON o.user_id = u.id
)
SELECT 
	'Structural Integrity' AS audit_type,
    'orders' AS audit_table,
    total_orders,
    (total_orders - unique_orders) AS duplicate_count,
    order_null_pks,
    orphan_orders,
    ROUND(SAFE_DIVIDE(unique_orders - orphan_orders, total_orders) * 100, 4) AS structural_accuracy_pct,
    CASE 
        WHEN total_orders = unique_orders AND orphan_orders = 0 AND order_null_pks = 0 THEN 'PASS'
        WHEN order_null_pks > 0 THEN 'FAIL - PK NULLS FOUND'
        WHEN (total_orders - unique_orders) > 0 THEN 'FAIL - DUPLICATES FOUND'
        WHEN orphan_orders > 0 THEN 'FAIL - ORPHAN RECORDS FOUND'
        ELSE 'FAIL - UNEXPECTED ERROR'
    END AS audit_status
FROM integrity_stats;

-- 1.2 EVIDENCE: Uniqueness & Relationship
WITH duplicate_test AS (
  SELECT 
    'DUPLICATE PK' AS issue_tag,
    'orders' AS table,
    order_id, 
    user_id
  FROM `bigquery-public-data.thelook_ecommerce.orders`
  GROUP BY order_id, user_id
  HAVING COUNT(*) > 1
),
null_pk_test AS (
  SELECT 
    'NULL PK' AS issue_tag,
    'orders' AS table,
    order_id, 
    user_id
  FROM `bigquery-public-data.thelook_ecommerce.orders`
  WHERE order_id IS NULL
),
orphan_test AS (
  SELECT 
    'ORPHAN ORDER (No User)' AS issue_tag,
    'orders' AS table,
    o.order_id, 
    o.user_id
  FROM `bigquery-public-data.thelook_ecommerce.orders` o
  LEFT JOIN `bigquery-public-data.thelook_ecommerce.users` u ON o.user_id = u.id
  WHERE u.id IS NULL
)
SELECT * FROM duplicate_test
UNION ALL
SELECT * FROM null_pk_test
UNION ALL
SELECT * FROM orphan_test;

-- NOTE: u.id IS NULL identifies two types of failures: (1) o.user_id is NULL in 
-- the source table, or (2) o.user_id exists but has no matching record in 
-- the Users table (Orphan Record).


-- -----------------------------------------------------------------------------
-- AUDIT 2: FINANCIAL HEALTH (Nulls & Range Validation)
-- WHY: To calculate Margins (02) and Monetary value (03), we eliminate 
--      zero/negative prices that signal system misconfigurations.
-- -----------------------------------------------------------------------------

-- 2.1 KPI: Price & Cost Completeness
SELECT 
    'Financial Integrity' AS audit_type,
    'order_items' AS audit_table,
    COUNT(*) AS total_items,
    COUNTIF(sale_price IS NULL OR sale_price <= 0) AS invalid_price_count,
    COUNTIF(inventory_item_id IS NULL) AS missing_inventory_links_count,
    ROUND(SAFE_DIVIDE(COUNTIF(sale_price IS NULL OR sale_price <= 0  OR inventory_item_id IS NULL), COUNT(*)) * 100, 4) AS financial_data_risk_pct,
    CASE
        WHEN COUNTIF(sale_price IS NULL OR sale_price <= 0 OR inventory_item_id IS NULL) = 0 THEN 'PASS'
        WHEN COUNTIF(inventory_item_id IS NULL) > 0 THEN 'FAIL - NO INVENTORY LINK'
        ELSE 'FAIL - NULLS/NEGATIVES FOUND'
    END as audit_status
FROM `bigquery-public-data.thelook_ecommerce.order_items`;

-- 2.2 EVIDENCE: Transactions with zero or negative sale price
SELECT 
    CASE 
        WHEN sale_price <= 0 OR sale_price IS NULL THEN 'Price Issue'
        WHEN inventory_item_id IS NULL THEN 'Inventory Link Missing'
    END AS issue_tag,
    'order_items' AS table,
    id AS item_id, 
    order_id, 
    product_id, 
    sale_price,
    inventory_item_id, 
    created_at
FROM `bigquery-public-data.thelook_ecommerce.order_items`
WHERE sale_price <= 0 OR sale_price IS NULL OR inventory_item_id IS NULL;


-- -----------------------------------------------------------------------------
-- AUDIT 3: TIMELINE LOGIC (Event Sequence & NULLs Audit)
-- WHY: Logistics efficiency reports (Lead Time) are fraudulent if 
--      events occur out of chronological order.
-- -----------------------------------------------------------------------------

-- 3.1 KPI: Timeline Consistency & Completeness
WITH timeline_check AS (
    SELECT 
        COUNT(*) AS total_orders,
        COUNTIF(
            (shipped_at < created_at)
            OR (delivered_at < shipped_at)
            OR (status = 'Returned' AND returned_at < delivered_at)
            ) AS sequence_errors,
        COUNTIF(
            status = 'Complete' 
            AND (created_at IS NULL OR shipped_at IS NULL OR delivered_at IS NULL)
            ) AS missing_logistics_data_errors,
        COUNTIF(
            status = 'Returned' 
            AND returned_at IS NULL) AS missing_return_data_errors
    FROM `bigquery-public-data.thelook_ecommerce.orders`
    WHERE status IN ('Complete', 'Returned')
)
SELECT 
    'Timeline Logic & Completeness' AS audit_type,
    'orders' AS audit_table,
    total_orders,
    sequence_errors,
    missing_logistics_data_errors + missing_return_data_errors AS missing_timestamps,
    ROUND(SAFE_DIVIDE(total_orders - (sequence_errors + missing_logistics_data_errors + missing_return_data_errors), total_orders) * 100, 4) AS timeline_reliability_pct,
    CASE
        WHEN sequence_errors = 0 AND missing_logistics_data_errors + missing_return_data_errors = 0 THEN 'PASS'
        WHEN missing_logistics_data_errors + missing_return_data_errors > 0 THEN 'FAIL - NULLS FOUND'
        ELSE 'FAIL - SEQUENCE ERROR'
    END AS audit_status
FROM timeline_check;

-- 3.2 EVIDENCE: "Time-traveling" & NULLS records
SELECT 
    CASE 
        WHEN (status = 'Complete' AND (shipped_at IS NULL OR delivered_at IS NULL)) THEN 'Missing Timestamps'
        WHEN (status = 'Returned' AND returned_at IS NULL) THEN 'Missing Return Date'
        WHEN (shipped_at < created_at OR delivered_at < shipped_at OR returned_at < delivered_at) THEN 'Sequence Error (Time Travel)'
        ELSE 'Other Logic Gap'
    END AS issue_tag,
    'orders' AS table,
    status,
    order_id, 
    created_at, 
    shipped_at, 
    delivered_at,
    returned_at,
    SAFE.TIMESTAMP_DIFF(shipped_at, created_at, HOUR) AS creation_to_shipment_hours,
    SAFE.TIMESTAMP_DIFF(delivered_at, shipped_at, HOUR) AS shipment_to_delivery_hours
FROM `bigquery-public-data.thelook_ecommerce.orders`
WHERE 
    (shipped_at < created_at OR delivered_at < shipped_at)
    OR (status = 'Complete' AND (shipped_at IS NULL OR delivered_at IS NULL))
    OR (status = 'Returned' AND (returned_at IS NULL OR returned_at < delivered_at));


-- -----------------------------------------------------------------------------
-- AUDIT 4: PROCESS CONSISTENCY (Status & Standardization)
-- WHY: RFM/Revenue reports must exclude 'Cancelled' or 'Unknown' states 
--      to reflect real cash flow, not just system activity.
-- -----------------------------------------------------------------------------

-- 4.1 KPI: Status Dictionary Audit
SELECT 
    status,
    COUNT(*) AS total_orders,
    ROUND(COUNT(*) / SUM(COUNT(*)) OVER() * 100, 4) AS volume_share_pct,
    CASE 
        WHEN status IN ('Shipped', 'Complete', 'Returned', 'Cancelled', 'Processing') THEN 'PASS'
        ELSE 'FAIL - UNKNOWN STATUS'
    END AS audit_status
FROM `bigquery-public-data.thelook_ecommerce.orders`
GROUP BY status;

-- 4.2 EVIDENCE: Unexpected status values
SELECT 
    'Order status unrecognized' as issue_tag,
    'orders' as table,
    order_id, 
    status, 
    user_id,
    created_at
FROM `bigquery-public-data.thelook_ecommerce.orders`
WHERE status NOT IN ('Shipped', 'Complete', 'Returned', 'Cancelled', 'Processing');




/* 
-----------------------------------------------------------------------------
AI COLLABORATION LOG & HUMAN AUDIT (Refined from v02):
-----------------------------------------------------------------------------
1. ARCHITECTURAL SCOPE (Human): Expanded the audit from simple duplicate 
   checks to a 4-domain "Quality Gatekeeper" system, integrating 
   FK relationship health and status dictionary standardization.
2. DATA RESILIENCE (Human): Replaced standard JOINs with LEFT JOINs in 
   structural integrity checks to explicitly capture and count "Orphan 
   Records" – a critical requirement for enterprise financial auditing.
3. PROCESS LOGIC (Human): Designed Audit 3 (Timeline Integrity) to go beyond 
   AI-baseline by specifically tracking "Status vs Timestamp" consistency, ensuring 
   Returned_at dates align with Delivery flow (IFRS 16 compliance check).
4. IMPLEMENTATION (AI): Assisted with BigQuery Standard SQL syntax for 
   COUNTIF and window-based volume share calculations.
-----------------------------------------------------------------------------
*/