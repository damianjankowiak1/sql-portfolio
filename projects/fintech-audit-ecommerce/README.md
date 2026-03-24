# Strategic E-commerce Audit & Customer Intelligence
### AI-Augmented Data Engineering Project (BigQuery)

## 🎯 Executive Summary
This project delivers a production-grade analytical framework for a global e-commerce entity ([theLook eCommerce](https://console.cloud.google.com/marketplace/product/bigquery-public-data/thelook-ecommerce)). 

Unlike standard SQL portfolios, this repository implements an **"Audit-First" philosophy**. Before any business insights are generated, the data passes through a multi-stage **Financial Integrity Gate**, ensuring that all strategic decisions (Logistics, Margins, RFM) are based on 100% verified data.

## 🤖 Human-Led, AI-Augmented Engineering
**Methodology & Technical Oversight**

This project demonstrates a high-level **Human-in-the-Loop** workflow. While Generative AI was utilized to accelerate SQL syntax generation, I maintained full architectural control and responsibility for the analytical integrity of the output.

### 🏗️ Strategic Contributions (Human-Led)
* **Process Architecture:** I designed the project lifecycle, prioritizing a "Quality-First" approach (Audit -> Advanced Analysis -> RFM Strategy).
* **Business Logic Definition:** I defined the critical KPIs, including the 24h Internal SLA, Profit Erosion metrics, and the custom 10-segment RFM Playbook.
* **Granularity Correction:** I identified and corrected a critical flaw in the initial AI-suggested logic, shifting the analysis from Order-level to Item-level to ensure accurate Distribution Center (DC) performance tracking.

### 🛠️ Technical Implementation (AI-Augmented)
* **Syntax Acceleration:** AI was used as a specialized engine for generating complex SQL boilerplate (Window Functions, CTE structures).
* **Rigorous Validation:** Every code segment was manually audited and iteratively refined. I performed a "Code-to-Business" reconciliation to ensure that technical outputs align with real-world e-commerce logic and financial standards (IFRS 16).
* **Defensive Engineering:** I implemented `SAFE` functions and chronological integrity checks to ensure the scripts remain resilient against data anomalies.

> *Detailed "AI Collaboration Logs" with specific logic changes are available in the footer of each .sql file.*

This partnership allowed for the rapid delivery of senior-level analytical patterns while maintaining strict human oversight on business accuracy and logic.

## 🏗️ Project Architecture (The Data Value Chain)

### Pillar 1: Data Trust & Integrity Gate ([`01_data_cleaning.sql`](./sql_scripts/01_data_cleaning.sql))
**Objective:** Transforming raw cloud data into an "Audit-Ready" state.
* **Structural Audits:** Detecting Primary Key duplicates and orphaned records (FK integrity) in BigQuery's non-constrained environment.
* **Chronological Validation:** Identifying "Timeline Anomalies" (e.g., items delivered before being shipped) that corrupt Logistics KPIs.
* **Financial Hygiene:** Filtering $0 transactions and unauthorized status codes to ensure Revenue & RFM reports reflect actual cash flow.

### Pillar 2: Operational Efficiency & SLA Benchmarking ([`02_advanced_analysis.sql`](./sql_scripts/02_advanced_analysis.sql))
**Objective:** Moving beyond simple averages to detect real operational bottlenecks.
* **Granular Logistics SLA:** Package-level (SKU) tracking of the **24h Internal Processing target**.
* **Network Benchmarking:** Comparing individual Distribution Center (DC) performance against the **Global Network Average** to isolate "underperformers".
* **Contextual Volatility:** Using **L4W (Last 4 Weeks)** rolling averages and **YoY (Year-over-Year)** shifts to distinguish seasonal growth from operational anomalies.

### Pillar 3: Customer Intelligence & Strategic Playbook ([`03_rfm_segmentation.sql`](./sql_scripts/03_rfm_segmentation.sql))
**Objective:** Translating historical data into automated marketing triggers.
* **RFM Engine:** Statistical classification using **NTILE(5)** to rank the customer base across Recency, Frequency, and Monetary dimensions.
* **Strategic Playbook:** A behavioral mapping layer that assigns a **Strategic Goal** (e.g., "Protect Margin") and **Suggested Action** (e.g., "Threshold for Free Delivery") to each segment.
* **Revenue Share Analysis:** Quantifying the Pareto effect (e.g., identifying the small % of "Champions" driving the majority of revenue).

## 📈 Key Business Findings (Simulated)

> *Business logic implemented, visualization pending*

## 🛠️ Tech Stack
- **Engine:** Google BigQuery (SQL)
- **Concepts:** CTEs, Window Functions (`OVER`, `NTILE`, `ROWS BETWEEN`), Self-Joins, Data Lineage.