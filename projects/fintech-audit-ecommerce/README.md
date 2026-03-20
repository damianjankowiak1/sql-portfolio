# Financial Data Integrity Audit: E-commerce Case Study (BigQuery)

## 📌 Project Overview
This project simulates a **financial audit** on a large-scale e-commerce dataset ([BigQuery Public Data "theLook eCommerce"](https://console.cloud.google.com/marketplace/product/bigquery-public-data/thelook-ecommerce)). Drawing from my experience in **IFRS 16 compliance** and **Application Support at Aptitude Software**, I focus on identifying "Revenue Leakage", data anomalies, and integrity gaps that could lead to financial reporting errors.

## 🎯 Business Problem (Scope)
In financial systems, discrepancies between order placement, shipping, and payment processing are critical. This audit targets:
1. **Orphan Records:** Orders without valid user/product links.
2. **Revenue Leakage:** Orders marked as "Shipped" but with $0 sale price or missing payment timestamps.
3. **Audit Trail Gaps:** Inconsistent timestamps that violate business logic (e.g., delivered before shipped).

## 🛠️ Tech Stack & Methodology
- **Platform:** Google BigQuery
- **Techniques:** CTEs, Window Functions (`LAG`, `LEAD`, `RANK`), Data Deduplication, RFM Analysis.
- **Tools:** SQL, dbdiagram.io (ERD).

## 📊 Methodology (The "Audit" Approach)
1. **Step 1: Data Cleaning & Constraints Check** - Manually verifying primary/foreign key integrity in a non-enforced BigQuery environment.
2. **Step 2: Advanced Financial Logic** - Using CTEs to track lifecycle of transactions.
3. **Step 3: Strategic Insights** - RFM Segmentation to identify high-value vs. high-risk accounts.

## 📁 Project Structure
- [01_data_cleaning.sql](./sql_scripts/01_data_cleaning.sql) - Integrity tests and deduplication.
- [02_advanced_analysis.sql](./sql_scripts/02_advanced_analysis.sql) - Financial anomaly detection using Window Functions.
- [03_rfm_segmentation.sql](./sql_scripts/03_rfm_segmentation.sql) - Business value segmentation.

## 📈 Key Insights Found
(wip)