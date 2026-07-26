# Financial Data Integrity Audit — theLook eCommerce
### SQL / BigQuery Data Engineering Project

## Executive Summary
This project delivers an analytical framework for a global e-commerce dataset ([theLook eCommerce](https://console.cloud.google.com/marketplace/product/bigquery-public-data/thelook-ecommerce)), built on an **"Audit-First" philosophy**: before any business insight is generated, the data passes through a multi-stage Financial Integrity Gate, ensuring that all strategic conclusions (Logistics, Margins, RFM) are based on verified data.

## Project Architecture (The Data Value Chain)

### Pillar 1: Data Trust & Integrity Gate ([`01_data_cleaning.sql`](./sql_scripts/01_data_cleaning.sql))
**Objective:** Transforming raw cloud data into an audit-ready state.
- **Structural Audits:** Detecting primary key duplicates and orphaned records (FK integrity) in BigQuery's non-constrained environment.
- **Chronological Validation:** Identifying timeline anomalies (e.g., items delivered before being shipped) that corrupt logistics KPIs.
- **Financial Hygiene:** Filtering $0 transactions and unauthorized status codes to ensure revenue and RFM reports reflect actual cash flow.

### Pillar 2: Operational Efficiency & SLA Benchmarking ([`02_advanced_analysis.sql`](./sql_scripts/02_advanced_analysis.sql))
**Objective:** Moving beyond simple averages to detect real operational bottlenecks.
- **Granular Logistics SLA:** Item-level tracking of a 24h internal processing target — corrected from an initial order-level approach that masked per-item Distribution Center (DC) performance.
- **Network Benchmarking:** Comparing individual DC performance against the global network average to isolate underperformers.
- **Contextual Volatility:** Using L4W (last 4 weeks) rolling averages and YoY shifts to distinguish seasonal growth from operational anomalies.

### Pillar 3: Customer Intelligence & Strategic Playbook ([`03_rfm_segmentation.sql`](./sql_scripts/03_rfm_segmentation.sql))
**Objective:** Translating historical data into actionable segments.
- **RFM Engine:** Statistical classification using `NTILE(5)` to rank the customer base across Recency, Frequency, and Monetary dimensions.
- **Strategic Playbook:** A behavioral mapping layer assigning a strategic goal (e.g., "Protect Margin") and suggested action (e.g., "Threshold for Free Delivery") to each of 10 customer segments.
- **Revenue Share Analysis:** Quantifying the Pareto effect — identifying the small share of "Champions" driving the majority of revenue.

## Key Business Findings
*Business logic implemented, visualization pending (Phase 2).*

## Tech Stack
- **Engine:** Google BigQuery (SQL)
- **Concepts:** CTEs, Window Functions (`OVER`, `NTILE`, `ROWS BETWEEN`), Self-Joins, Data Lineage

## Note on AI Use
Generative AI was used selectively to accelerate SQL syntax drafting (window functions, CTE boilerplate). All architectural decisions, KPI definitions, and business-logic validation were done manually — including catching and correcting a flawed order-level granularity suggestion that would have masked real per-item DC performance. AI output was treated as a first draft requiring verification, not a source of truth.