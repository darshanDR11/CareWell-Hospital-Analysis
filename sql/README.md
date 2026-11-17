# CareWell Hospital Analytics — SQL Project

## 1. Project Title and Overview

**CareWell Hospital Analytics** is an end-to-end SQL analytics project designed to analyze hospital operations, patient flow, doctor performance, billing, and insurance claim performance across a multi-hospital healthcare network.

Hospitals generate large volumes of operational and financial data. Without structured analysis, management may struggle to identify bed-capacity problems, prolonged patient stays, readmissions, rejected insurance claims, and potential revenue leakage.

This project uses SQL to transform hospital data into actionable business insights through database verification, operational analysis, financial reporting, advanced SQL techniques, and database automation.

### Project Objectives

- Monitor daily and monthly bed occupancy across hospitals and wards.
- Identify wards experiencing sustained high occupancy and capacity inconsistencies.
- Analyze Length of Stay (LOS) against department benchmarks.
- Identify diagnosis patterns associated with excess bed-days.
- Evaluate patient readmissions, admission trends, and doctor workload.
- Analyze insurance claim approvals, rejections, short payments, and settlement times.
- Build reusable SQL views for management and COO reporting.
- Automate occupancy alerts and prevent invalid discharge-date updates.
- Demonstrate safe database transactions for patient ward transfers.

### Key Outcomes

- A verified relational hospital database.
- Operational and financial SQL analysis.
- Patient-flow and clinician-performance insights.
- Reusable reporting views using CTEs and window functions.
- Automated ward occupancy alerts.
- Data-integrity protection through a trigger.
- Transaction-based patient ward transfers.

---

## 2. Tech Stack and Prerequisites

### Technology Stack

| Technology | Purpose |
|---|---|
| MySQL 9.5.0 | Relational database management |
| SQL | Data verification, analysis, reporting, and automation |
| Common Table Expressions (CTEs) | Organizing complex analytical queries |
| Window Functions | Ranking, trends, comparisons, and analytical calculations |
| Views | Reusable reporting datasets |
| Stored Procedures | Automating database operations |
| Triggers | Enforcing data-integrity rules |
| Transactions | Maintaining consistency during multiple database updates |
| Git and GitHub | Version control and project documentation |

### Prerequisites

Before running the project, ensure that you have:

1. MySQL 9.5.0 or preferably 8.0 or later
2. MySQL Workbench or another compatible MySQL client.
3. Access to the project CSV datasets.
4. Permission to create databases, tables, views, procedures, and triggers.
5. Permission to insert, update, and delete records where required.
6. Permission to execute stored procedures and manage transactions.

**Required database privileges:**

- `CREATE DATABASE` and `CREATE TABLE`
- `SELECT`, `INSERT`, `UPDATE`, and `DELETE`
- `CREATE VIEW`
- `CREATE ROUTINE` and `EXECUTE`
- `TRIGGER`

The exact privileges depend on the database environment and how the scripts are executed.

---

## 3. Database Schema

The project uses a relational database containing hospital, patient, admission, ward, doctor, billing, and insurance claim information.

### Core Tables

| Table | Description |
|---|---|
| `hospitals` | Stores hospital information and location details. |
| `departments` | Stores department names and benchmark ALOS values. |
| `doctors` | Stores doctor information and hospital/department relationships. |
| `patients` | Stores patient demographic and insurance-related information. |
| `wards` | Stores ward information and hospital relationships. |
| `admissions` | Stores patient admission, discharge, diagnosis, doctor, and ward information. |
| `bed_day_snapshot` | Stores dated ward-level bed capacity, occupied beds, and blocked beds. |
| `bills` | Stores admission-related billing amounts and payer information. |
| `claims` | Stores insurance claim amounts, approval information, status, and settlement dates. |

### Database Schema Relationships

| Parent Entity (1) | Relationship | Child Entity (Many) |
| :--- | :--- | :--- |
| `HOSPITALS` | employs | `DOCTORS` |
| `HOSPITALS` | contains | `WARDS` |
| `HOSPITALS` | receives | `ADMISSIONS` |
| `HOSPITALS` | records | `BED_DAY_SNAPSHOT` |
| `DEPARTMENTS` | includes | `DOCTORS` |
| `DEPARTMENTS` | handles | `ADMISSIONS` |
| `PATIENTS` | has | `ADMISSIONS` |
| `DOCTORS` | handles | `ADMISSIONS` |
| `WARDS` | assigned_to | `ADMISSIONS` |
| `WARDS` | recorded_in | `BED_DAY_SNAPSHOT` |
| `ADMISSIONS` | generates | `BILLS` |
| `BILLS` | associated_with | `CLAIMS` |

### Relationship Overview

- A hospital contains multiple wards and employs multiple doctors.
- A department can have multiple doctors and admissions.
- A patient can have multiple admission records.
- An admission is associated with a hospital, department, doctor, and ward.
- An admission can generate a billing record.
- A bill can have associated insurance claim records.
- Ward occupancy is recorded over time through `bed_day_snapshot`.

**Note:** The diagram shows the intended analytical relationships. Confirm cardinalities and actual constraints using the database verification script.

---

## 4. Project Workflow

The project contains seven SQL files numbered according to their intended execution order.

### Execution Workflow

| Execution Order | SQL File | Module | Purpose |
| :--- | :--- | :--- | :--- |
| 00 | `00_create_db.sql` | Database Setup | Create the database, tables, relationships and import data. |
| 01 | `01_database_verification.sql` | Database Verification | Verify tables, records, relationships and data integrity. |
| 02 | `02_hospital_operational.sql` | Hospital Operational Analysis | Analyze bed occupancy, length of stay and hospital performance. |
| 03 | `03_patient_doctor_analysis.sql` | Patient and Doctor Analysis | Analyze patient admissions, readmissions and doctor performance. |
| 04 | `04_financial_analytics.sql` | Financial Analytics | Analyze insurance claims, rejections, short payments and potential revenue recovery. |
| 05 | `05_cte_windowFunction_view.sql` | Advanced SQL Analytics | Apply CTEs, window functions and views for reusable reporting. |
| 06 | `06_procedure_trigger.sql` | Database Automation | Implement stored procedures, triggers and transaction management. |

### Execution Steps

1. **Database Setup:** Create the database, tables, constraints, and load the source datasets.
2. **Database Verification:** Validate table creation, relationships, record counts, and data integrity.
3. **Hospital Operational Analysis:** Analyze bed occupancy, capacity issues, patient stays, and department performance.
4. **Patient and Doctor Analysis:** Examine readmissions, doctor workload, admission trends, and clinician relationships.
5. **Financial Analytics:** Evaluate billing, insurance claims, rejected amounts, settlement times, and potential revenue leakage.
6. **Advanced SQL Reporting:** Apply CTEs and window functions and create reusable reporting views.
7. **Database Automation:** Create the ward alert procedure, discharge validation trigger, and transaction-based ward transfer logic.

---

## 5. File-by-File Documentation

### 00_create_df.sql — Database Setup and Data Loading

**Purpose:** Establish the database environment and prepare the relational structure for hospital analytics. This script creates the database and required tables, defines relationships and constraints, and loads the source datasets.

**Key objects:** Database, core tables, primary keys, foreign keys, and other schema constraints.

**Main operations:**
- Create the database.
- Define the hospital database schema.
- Establish primary-key and foreign-key relationships.
- Load source CSV data into the appropriate tables.

**SQL File:** [00_create_db.sql](https://github.com/darshanDR11/CareWell-Hospital-Analysis/blob/main/sql/00_create_db.sql)

**Expected outcome:** The database and required tables are created and populated with source records.

### 01_database_verification.sql — Database and Data Integrity Verification

**Purpose:** Confirm that the database has been created correctly and that its tables and relationships are structurally consistent. The script validates record counts, primary-key and foreign-key constraints, and identifies orphaned or mismatched records across related tables.

**Key objects:** Verification queries and data-integrity checks. This script is intended primarily for validation rather than creating analytical views.

**Main analyses:**
- Verify database and table existence.
- Check primary-key and foreign-key constraints.
- Validate record counts.
- Identify orphaned admission, billing, claim, doctor, ward, and hospital references.
- Detect mismatched relationships between related tables.

**SQL File:** [01_database_verification.sql](https://github.com/darshanDR11/CareWell-Hospital-Analysis/blob/main/sql/01_database_verification.sql)

**Expected outcome:** Database structure and relationship checks are returned, with potential integrity issues identified for investigation.

### 02_hospital_operational.sql — Hospital Operational Analysis

**Purpose:** Analyze hospital capacity, ward utilization, and patient-stay efficiency. The script helps identify overcrowded wards, prolonged patient stays, and diagnosis patterns associated with additional bed usage.

**Key objects:** Operational analytical queries using the hospital, ward, admission, department, and bed-snapshot data.

**Main analyses:**
- Daily and monthly ward occupancy.
- Hospital-level occupancy reporting.
- Capacity inconsistencies and occupancy above defined thresholds.
- Wards exceeding 90% occupancy for five or more consecutive days.
- Admission Length of Stay (LOS) versus department benchmarks.
- Top diagnosis–department combinations contributing to excess bed-days.

**SQL File:** [02_hospital_operational.sql](https://github.com/darshanDR11/CareWell-Hospital-Analysis/blob/main/sql/02_hospital_operational.sql)

**Expected outcome:** Operational reports highlighting occupancy pressure, capacity issues, LOS performance, and diagnosis-related bed utilization.

### 03_patient_doctor_analysis.sql — Patient Flow and Doctor Analysis

**Purpose:** Examine patient movement through the hospital network and evaluate doctor workload and admission patterns. The analysis identifies readmission trends and provides visibility into hospital, department, and doctor relationships.

**Key objects:** Patient-flow and doctor-performance analytical queries using admission and doctor-related data.

**Main analyses:**
- Patient readmission analysis.
- Readmissions within 30 days.
- Readmission rates by department and doctor.
- Doctor workload and admission volumes.
- Admission trends over time.
- Doctor-to-hospital and doctor-to-department relationships.

**SQL File:** [03_patient_doctor_analysis.sql](https://github.com/darshanDR11/CareWell-Hospital-Analysis/blob/main/sql/03_patient_doctor_analysis.sql)

**Expected outcome:** Reports showing patient readmission patterns, admission trends, and doctor workload distribution.

### 04_financial_analytics.sql — Insurance and Billing Analytics

**Purpose:** Evaluate hospital billing and insurance claim performance to identify potential revenue leakage and settlement inefficiencies. The analysis compares claimed and approved amounts and examines financial performance across insurers, hospitals, and departments.

**Key objects:** Financial analytical queries and the reusable claim-analysis view `vw_claim_analysis` (if created by this script or an earlier script).

**Main analyses:**
- Insurance claim approval rates.
- Rejected and partially approved claims.
- Claimed versus approved amounts.
- Potential recovery from rejected and short-paid claims.
- Claim settlement time.
- Insurer performance.
- Hospital- and department-level financial impact.

**SQL File:** [04_financial_analytics.sql](https://github.com/darshanDR11/CareWell-Hospital-Analysis/blob/main/sql/04_financial_analytics.sql)

**Expected outcome:** Financial reports highlighting claim performance, potential recovery amounts, insurer differences, and settlement delays.

### 05_cte_windowFunction_view.sql — Advanced SQL and Reusable Reporting Views

**Purpose:** Apply advanced SQL techniques to combine operational, patient, and financial information into reusable analytical datasets. The script uses CTEs and window functions to support rankings, period comparisons, and management-level reporting.

**Key objects:** CTE-based analytical queries, window-function calculations, and reusable reporting views. The documented view set includes:

- `vw_admission_analytics`
- `vw_daily_hospital_occupancy`
- `vw_monthly_claim_performance`
- `vw_coo_hospital_monthly_summary`
- `vw_patient_admission_summary`
- `vw_department_monthly_performance`

**Main analyses:**
- Hospital and department rankings.
- Top-performing departments within hospitals.
- Month-over-month comparisons using `LAG()` and `LEAD()`.
- Cumulative financial analysis.
- Occupancy quartiles using `NTILE()`.
- First and latest period comparisons.
- COO-level hospital and monthly reporting.

**SQL File:** [05_cte_windowFunction_view.sql](https://github.com/darshanDR11/CareWell-Hospital-Analysis/blob/main/sql/05_cte_windowFunction_view.sql)

**Expected outcome:** Advanced analytical results and reusable views for hospital, department, admission, occupancy, and claim reporting.

### 06_procedure_trigger.sql — Stored Procedures, Triggers, and Transactions

**Purpose:** Automate selected database operations and enforce important data-integrity rules. The script creates a ward occupancy alert procedure, a discharge-date validation trigger, and transaction-based patient ward transfer logic.

**Key objects:**

| Object | Type | Purpose |
|---|---|---|
| `sp_ward_alert` | Stored Procedure | Finds wards exceeding the 90% occupancy threshold for a selected hospital and date. |
| `trg_validate_discharge_date` | Trigger | Prevents an update that sets the discharge timestamp earlier than the admission timestamp. |
| `sp_transfer_patient` | Stored Procedure | Transfers a patient between wards using a transaction, with occupancy updates and rollback handling. |

**Main operations:**
- Generate ward occupancy alerts.
- Reject invalid discharge-date updates.
- Validate patient and ward information before a transfer.
- Decrease occupied-bed counts in the old ward.
- Increase occupied-bed counts in the destination ward.
- Update the admission's assigned ward.
- Commit valid transfers and roll back failed operations.

**SQL File:** [06_procedure_trigger.sql](https://github.com/darshanDR11/CareWell-Hospital-Analysis/blob/main/sql/06_procedure_trigger.sql)

**Expected outcome:** Database automation objects are created and can be tested with valid and invalid records.

---

## 6. Key Metrics and Business Insights

The following KPIs support hospital operational, patient-flow, and financial decision-making.

| KPI | Definition | Business Purpose | SQL File |
|---|---|---|---|
| Bed Occupancy Rate | `(Beds Occupied / Total Beds) × 100` | Measures ward and hospital bed utilization. | `02_hospital_operational.sql` |
| High-Occupancy Ward | Ward occupancy exceeding 90%. | Identifies wards under capacity pressure. | `02_hospital_operational.sql`, `06_procedure_trigger.sql` |
| Sustained High Occupancy | Occupancy above 90% for five or more consecutive days. | Identifies persistent capacity problems. | `02_hospital_operational.sql` |
| Capacity Inconsistency | Records where occupied and blocked beds together exceed total capacity, subject to the definitions of these fields. | Identifies records requiring capacity validation. | `02_hospital_operational.sql` |
| Average Length of Stay (ALOS) | Average completed admission duration. | Measures average patient-stay duration. | `02_hospital_operational.sql` |
| ALOS Benchmark Difference | Actual department ALOS minus benchmark ALOS. | Highlights departments with longer-than-benchmark stays. | `02_hospital_operational.sql` |
| Excess Bed-Days | Positive LOS above the applicable department benchmark, aggregated across admissions. | Identifies diagnosis patterns associated with additional bed usage. | `02_hospital_operational.sql` |
| 30-Day Readmission Rate | Eligible index admissions followed by a new admission within 30 days, divided by eligible index admissions. | Measures short-term patient readmission patterns. | `03_patient_doctor_analysis.sql` |
| Doctor Workload | Admission volume attributed to each doctor during a selected period. | Compares doctor workload distribution. | `03_patient_doctor_analysis.sql` |
| Admission Trend | Admission counts grouped by a defined time period. | Tracks changes in patient demand. | `03_patient_doctor_analysis.sql` |
| Claim Approval Rate | Approved claims divided by the defined claim denominator, multiplied by 100. | Measures insurer claim approval performance. | `04_financial_analytics.sql` |
| Rejected Claim Amount | Total claimed amount associated with rejected claims. | Measures the financial value of rejected claims. | `04_financial_analytics.sql` |
| Short-Paid Claim Amount | Total claimed amount minus approved amount for partially approved claims. | Measures the amount not approved by insurers. | `04_financial_analytics.sql` |
| Potential Revenue Recovery | Sum of claimed amount minus approved amount for rejected and partially approved claims. | Estimates the amount that may warrant recovery or appeal. | `04_financial_analytics.sql` |
| Average Settlement Time | Average number of days between claim submission and settlement for settled claims. | Measures insurer settlement efficiency. | `04_financial_analytics.sql` |
| Hospital Ranking | Relative hospital position based on a selected KPI. | Supports hospital-level performance comparison. | `05_cte_windowFunction_view.sql` |
| Occupancy Quartile | Distribution of occupancy observations into four groups using `NTILE(4)`. | Helps compare occupancy levels across wards or periods. | `05_cte_windowFunction_view.sql` |

### Important KPI Interpretation Notes

- Occupancy calculations use occupied beds divided by total beds. Blocked beds are tracked separately; confirm whether occupied and blocked beds are mutually exclusive before interpreting combined capacity.
- ALOS comparisons are operational screening metrics. They do not adjust for diagnosis severity, patient complexity, or case mix.
- Readmission rates depend on the chosen observation window, index-admission eligibility, and treatment of patients whose 30-day follow-up period is incomplete.
- Claim approval-rate denominators must be defined consistently. Approved-only claims and partially approved claims should not be silently treated as the same category.
- Potential revenue recovery is not confirmed cash loss or recovered revenue. It represents the difference between claimed and approved amounts that may require further investigation.

---

## 7. Stored Procedure and Trigger Usage

This project includes database automation to support operational monitoring and data integrity.

### 7.1 Stored Procedure: `sp_ward_alert`

The procedure returns wards in a selected hospital whose occupancy exceeds 90% on a specified snapshot date.

**Syntax:**

```sql
CALL sp_ward_alert('hospital_id','YYYY-MM-DD');
```

**Example:**

```sql
CALL sp_ward_alert('H001', '2026-11-17');
```

**Expected behavior:**

- Filters records by hospital and snapshot date.
- Calculates occupancy percentage.
- Returns wards exceeding the 90% threshold.
- Sorts results by occupancy percentage.

### 7.2 Trigger: `trg_validate_discharge_date`

The trigger validates discharge timestamps before an admission record is updated.

**Valid update example:**

```sql
UPDATE admissions
SET discharge_ts = DATE_ADD(admit_ts, INTERVAL 2 DAY)
WHERE admission_id = 'admission_id';
```

**Invalid update example:**

```sql
UPDATE admissions
SET discharge_ts = DATE_SUB(admit_ts, INTERVAL 1 DAY)
WHERE admission_id = 'admission_id';
```

**Expected behavior:**

The valid update should succeed if the admission exists. The invalid update should be rejected with the trigger error:

```text
Invalid discharge date: discharge cannot be before admission
```

**Note:** The documented trigger is a `BEFORE UPDATE` trigger. It validates updates to existing admission records; it does not independently validate inserts.

### 7.3 Transaction: `sp_transfer_patient`

The transfer procedure moves a patient from an existing ward to another ward within the same hospital.

**Syntax:**

```sql
CALL sp_transfer_patient(
    'admission_id',
    'destination_ward_id',
    'YYYY-MM-DD'
);
```

**Example:**

```sql
CALL sp_transfer_patient(
    'ADM000001',
    'WARD002',
    '2026-11-17'
);
```

**Expected behavior:**

1. Validate the admission and destination ward.
2. Confirm that the patient is still admitted.
3. Check the selected date's ward snapshots.
4. Lock the relevant ward records.
5. Check destination capacity.
6. Decrease the old ward's occupied-bed count.
7. Increase the destination ward's occupied-bed count.
8. Update the admission's ward assignment.
9. Commit all changes together.

If an error occurs, the procedure executes `ROLLBACK`, preventing partial updates from being retained.

**Important:** The transaction updates the selected date's `bed_day_snapshot` records. It does not automatically update other historical snapshots or create a separate ward-transfer history.

---

## 8. Project Structure

The repository is organized to make the SQL scripts easy to execute, understand, and maintain.

```text
CareWell-Hospital-Analytics/
│
├── cleaned_dataset/
│   ├── admissions.csv
│   ├── bed_day_snapshot.csv
│   ├── bills.csv
│   ├── claims.csv
│   ├── departments.csv
│   ├── doctors.csv
│   ├── hospitals.csv
│   ├── patients.csv
│   └── wards.csv
│
├── dataset/
│   ├── admissions.csv
│   ├── bed_day_snapshot.csv
│   ├── bills.csv
│   ├── claims.csv
│   ├── departments.csv
│   ├── doctors.csv
│   ├── hospitals.csv
│   ├── patients.csv
│   └── wards.csv
│
├── sql/
│   ├── 00_create_df.sql
│   ├── 01_database_verification.sql
│   ├── 02_hospital_operational.sql
│   ├── 03_patient_doctor_analysis.sql
│   ├── 04_financial_analytics.sql
│   ├── 05_cte_windowFunction_view.sql
│   ├── 06_procedure_trigger.sql
│   └── README.md
│
└── README.md
```

**Note:** This is a suggested repository structure. Adjust folder and file locations to match the actual GitHub repository.

---

## 9. Future Enhancements

Potential improvements to extend the project include:

1. **Power BI Integration:** Connect the analytical views to Power BI and build interactive dashboards for hospital executives.
2. **Hospital-Level Row-Level Security:** Implement hospital-specific access so users can view only authorized hospital data.
3. **Ward Transfer History:** Create a dedicated transfer-history table to preserve patient movement records over time.
4. **Bed Assignment Management:** Introduce a live bed-assignment model to support more accurate real-time occupancy and capacity checks.
5. **Readmission Risk Analysis:** Extend the SQL analysis with patient-level risk indicators and, where appropriate, predictive modelling.
6. **Automated Alert Logging:** Store generated occupancy alerts in a dedicated alert table for historical tracking and investigation.
7. **Financial Recovery Tracking:** Track claim appeals, resubmissions, recovered amounts, and final settlement outcomes.
8. **Query Optimization:** Review execution plans, add appropriate indexes, and optimize analytical queries for larger datasets.
9. **Data Quality Monitoring:** Extend database validation with scheduled checks and persistent data-quality reporting.
10. **Automated Reporting:** Schedule periodic hospital operational and financial reports.

---

## 10. Author 

**Name:** Darshan Dudhat

**GitHub:** https://github.com/darshanDR11
