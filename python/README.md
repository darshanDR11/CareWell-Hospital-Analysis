# 🧹 CareWell Hospitals — Data Cleaning, Quality Assessment & Standardization

## 1. Overview

Before performing exploratory data analysis, SQL modeling, and dashboard development, a data cleaning and quality assessment process was implemented to standardize the source CSV files and identify potential data quality issues across the CareWell Hospital dataset.

The cleaning pipeline was developed using **Python, Pandas, and NumPy** and executed across all 9 dataset tables.

In addition to standard cleaning operations, cross-table validation and business-rule checks were performed to identify inconsistencies that could affect hospital operations, patient flow, billing, and insurance claim analysis.

The process focuses on correcting confirmed data issues while preserving records that may represent valid business scenarios.

---

## 2. Objectives

The data cleaning process was designed to:

- Validate schema consistency.
- Verify required columns exist.
- Standardize inconsistent text fields.
- Convert date and numeric columns into appropriate datatypes.
- Handle invalid text representations of missing values.
- Identify and remove duplicate records.
- Detect invalid date relationships.
- Investigate missing values using business context.
- Perform cross-table data validation.
- Generate standardized datasets for downstream analytics.
- Log execution status and processing errors.

---

## 3. Pipeline Architecture

The cleaning pipeline processes each CSV file individually using a metadata-driven configuration.

```text
Raw CSV Files
      │
      ▼
Schema Validation
      │
      ▼
Text Standardization
      │
      ▼
Missing Value Standardization
      │
      ▼
Datatype Conversion
      │
      ▼
Duplicate Detection
      │
      ▼
Business Rule Validation
      │
      ▼
Cross-Table Validation
      │
      ▼
Issue Investigation & Resolution
      │
      ▼
Clean CSV Export
      │
      ▼
Analytics Ready Dataset
```

---

## 4. Source & Destination Structure

```text
CareWell_Hospital/
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
├── docs/
│   ├── data_dictionary.csv
│   └── README.md
└── python/
    ├── carewell_pipeline.log
    ├── cleaning_pipeline.py
    └── README.md
```

---

# 5. Cleaning Operations Performed

## 5.1 Schema Validation

For every table, the pipeline validated the presence of all required columns.

### Implementation

```python
missing_columns = [
    col for col in required_columns
    if col not in df.columns
]
```

### Purpose

- Prevent processing of incomplete files.
- Detect schema drift.
- Ensure downstream joins remain valid.

---

## 5.2 Text Standardization

Configured text columns were standardized to remove unwanted whitespace and enforce consistent formatting.

### Implementation

```python
df[col] = df[col].str.strip().str.upper()
```

### Transformations

| Operation            | Purpose                      |
| -------------------- | ---------------------------- |
| Trim leading spaces  | Remove accidental whitespace |
| Trim trailing spaces | Improve matching accuracy    |
| Convert to uppercase | Enforce consistent values    |

### Example

| Raw Value       | Clean Value |
| --------------- | ----------- |
| `" h01 "`       | `H01`       |
| `"Dr0001 "`     | `DR0001`    |
| `" emergency "` | `EMERGENCY` |

### Special Case: Doctor Names

The `doctors` table contained inconsistent formatting in the `doctor_name` column.

To standardize doctor names, the following transformation was applied:

```python
df['doctor_name'] = (
    df['doctor_name']
    .str.strip()
    .str.title()
    .str.upper()
)
```

This ensures consistent uppercase formatting while correcting inconsistent capitalization.

---

## 5.3 Missing Value Standardization

Multiple representations of missing values were replaced with standard null values.

### Implementation

```python
df[col] = df[col].replace(
    ['', 'NA', 'N/A', 'na', 'n/a'],
    np.nan
)
```

### Standardized Values

| Raw Value    | Converted Value |
| ------------ | --------------- |
| Empty string | NaN             |
| NA           | NaN             |
| N/A          | NaN             |
| na           | NaN             |
| n/a          | NaN             |

### Benefits

- Consistent null handling.
- Accurate aggregation results.
- Reliable data profiling metrics.

---

## 5.4 Date Conversion

Configured date fields were converted from string format to datetime datatype.

### Implementation

```python
df[col] = pd.to_datetime(df[col])
```

### Converted Columns

| Table            | Columns                      |
| ---------------- | ---------------------------- |
| admissions       | admit_ts, discharge_ts       |
| claims           | submitted_date, settled_date |
| doctors          | join_date                    |
| patients         | dob                          |
| bed_day_snapshot | snapshot_date                |

### Benefits

- Time-series analysis.
- Date calculations.
- Length of stay calculations.
- Trend reporting.

---

## 5.5 Numeric Conversion

Configured numeric columns were converted to numeric datatypes.

### Implementation

```python
df[col] = pd.to_numeric(df[col])
```

### Converted Columns

| Table            | Columns                                          |
| ---------------- | ------------------------------------------------ |
| bills            | room_charges, pharmacy, procedures, total_amount |
| claims           | claimed_amt, approved_amt                        |
| wards            | beds_total                                       |
| departments      | benchmark_alos_days                              |
| bed_day_snapshot | beds_total, beds_occupied, beds_blocked          |

### Benefits

- Mathematical calculations.
- KPI generation.
- Dashboard reporting.

---

## 5.6 Duplicate Detection

Duplicate rows were identified using:

```python
df.duplicated().sum()
```

### Purpose

- Prevent double counting.
- Improve data reliability.
- Maintain record integrity.

---

## 5.7 Duplicate Removal

Detected fully duplicated records were removed using:

```python
df.drop_duplicates(inplace=True)
```

### Purpose

- Ensure record uniqueness.
- Improve data quality.
- Reduce storage redundancy.

---

# 6. Data Quality Issues Identified & Investigated

Apart from standard cleaning operations, additional data quality issues were discovered during detailed investigation.

These issues were evaluated using business rules and relationships between different tables.

Not every missing or inconsistent value was treated as an error. Resolution decisions were made based on the available evidence.

## 6.1 Doctors Table — Inconsistent Doctor Names

**Issue Identified:**

The `doctor_name` column contained inconsistent capitalization and formatting across multiple records.

**Impact:**

- Inconsistent doctor identification.
- Potential grouping and reporting issues.
- Reduced text consistency.

**Resolution:**

Applied `.str.title().str.upper()` after trimming whitespace to standardize doctor names.

**Status:** Resolved.

---

## 6.2 Doctors Table — Missing Senior Doctor References

**Issue Identified:**

A total of **216 records** contained NULL values in the `senior_doctor_id` column.

**Investigation:**

The column represents the senior-junior doctor relationship.

A missing senior doctor reference may indicate that the doctor is not assigned to a senior doctor, rather than a data quality error.

**Resolution:**

NULL values were retained because removing or replacing them could incorrectly modify the organizational hierarchy.

**Status:** Retained — requires no correction unless business rules indicate otherwise.

---

## 6.3 Patients Table — Missing Insurance Information

**Issue Identified:**

A total of **79,371 records** contained NULL values in the `insurance_i`d column.

**Investigation:**

These records may represent patients who do not have insurance coverage.

However, missing information does not automatically confirm that a patient is uninsured.

**Resolution:**

NULL values were retained instead of replacing them with `NO` or deleting the records.

Further validation against billing and claims records may help distinguish uninsured patients from missing insurance information.

**Status:** Retained — business validation required.

---

## 6.4 Admissions Table — Admission Date After Discharge Date

**Issue Identified:**

A total of **1,400 records** contained admission timestamps (`admit_ts`) greater than discharge timestamps (`discharge_ts`).

**Business Rule:**

An admission timestamp should normally be earlier than or equal to the discharge timestamp.

```sql
SELECT *
FROM admissions
WHERE admit_ts > discharge_ts;
```

**Investigation:**

Initially, these records appeared to contain incorrect date values.

However, cross-table validation showed that the corresponding admission records were also present in the claims table, indicating that the admissions had associated financial activity.

This provided supporting evidence that the records should not be deleted without further investigation.

**Resolution:**

The admission and discharge timestamps were swapped for these 1,400 records.

```python
mask = df['admit_ts'] > df['discharge_ts']

df.loc[mask, ['admit_ts', 'discharge_ts']] = (
    df.loc[mask, ['discharge_ts', 'admit_ts']].to_numpy()
)
```

**Status:** Corrected — timestamp swapping applied.

**Note:** The presence of related claims supports retaining these records, but does not independently prove that swapping the timestamps reflects the actual hospital event sequence. This correction should be documented as an assumption unless verified against source records.

---

## 6.5 Admissions Table — Missing Discharge Timestamps

**Issue Identified:**

A total of **2,564 records** contained NULL values in `discharge_ts`.

**Investigation:**

Cross-table validation showed that the corresponding admission IDs were present in the bills table but absent from the claims table.

Possible explanations include:

- Patients are still admitted to the hospital.
- Discharge information has not yet been recorded.
- Discharge events were not properly updated in the system.
- The admission has billing activity but no insurance claim.

**Resolution:**

These records were not deleted because missing discharge timestamps may represent ongoing admissions.

Removing them without investigation could affect:

- Patient flow analysis.
- Length of stay calculations.
- Bed occupancy reporting.
- Billing analysis.

NULL values were retained until the actual admission status can be confirmed.

**Status:** Retained — investigation required.

---

## 6.6 Claims Table — Missing Claim Reasons

**Issue Identified:**

A total of **212,339 records** contained NULL values in the `reason` column.

**Investigation:**

The claim reason may represent additional information about why a claim was submitted, processed, or rejected.

A missing reason does not necessarily indicate that the entire claim record is invalid.

**Resolution:**

Records were retained instead of being deleted.

Replacing missing values with arbitrary descriptions could introduce incorrect business information.

**Status:** Retained — business validation required.

---

## 6.7 Claims Table — Missing Settlement Dates

**Issue Identified:**

A total of **13,684 records** contained NULL values in the `settled_date` column.

**Investigation:**

Possible explanations include:

- Claims are still pending.
- Claims have been rejected.
- Settlement information has not been updated.
- Settlement processing is incomplete.

**Resolution:**

NULL values were retained because deleting these records could lead to incorrect claim volume and financial reporting.

Further investigation using claim status and approval information is required.

**Status:** Retained — business validation required.

---

# 7. Data Quality Investigation Summary

| Table      | Column                 | Issue                         |  Records | Resolution   |
| ---------- | ---------------------- | ----------------------------- | -------: | ------------ |
| doctors    | doctor_name            | Inconsistent formatting       | Multiple | Standardized |
| doctors    | senior_doctor_id       | Missing references            |      216 | Retained     |
| patients   | insurance_id           | Missing insurance information |   79,371 | Retained     |
| admissions | admit_ts, discharge_ts | Admission after discharge     |    1,400 | Swapped      |
| admissions | discharge_ts           | Missing discharge timestamp   |    2,564 | Retained     |
| claims     | reason                 | Missing claim reason          |  212,339 | Retained     |
| claims     | settled_date           | Missing settlement date       |   13,684 | Retained     |

**Important:** The record counts above represent identified issues, not necessarily distinct affected records across the entire dataset.

---

# 8. Cleaning Results Summary

## 8.1 Table-Level Impact

| Table            | Raw Rows | Clean Rows | Rows Removed |
| ---------------- | -------: | ---------: | -----------: |
| admissions       |  350,000 |    350,000 |            0 |
| bed_day_snapshot |   87,600 |     87,600 |            0 |
| bills            |  350,000 |    350,000 |            0 |
| claims           |  244,133 |    243,233 |          900 |
| departments      |       18 |         18 |            0 |
| doctors          |      900 |        900 |            0 |
| hospitals        |       12 |         12 |            0 |
| patients         |  260,000 |    260,000 |            0 |
| wards            |      120 |        120 |            0 |

## 8.2 Duplicate Removal Summary

| Table            | Duplicates Found | Duplicates Removed |
| ---------------- | ---------------: | -----------------: |
| claims           |              900 |                900 |
| All Other Tables |                0 |                  0 |

### Key Observation

The `claims` table contained **900 fully duplicated records**, which were successfully removed.

No duplicate records were removed from the remaining eight tables.

---

# 9. Datatype Standardization Results

The following columns were converted from string representations into appropriate datetime datatypes.

| Table            | Column         |
| ---------------- | -------------- |
| admissions       | admit_ts       |
| admissions       | discharge_ts   |
| claims           | submitted_date |
| claims           | settled_date   |
| doctors          | join_date      |
| patients         | dob            |
| bed_day_snapshot | snapshot_date  |

Numeric columns were also converted according to the configured metadata.

---

# 10. Data Quality Improvements

After the cleaning and investigation process:

- Consistent text formatting.
- Standardized null representations.
- Proper datetime datatypes.
- Proper numeric datatypes.
- Duplicate records removed.
- Inconsistent doctor names standardized.
- Invalid admission/discharge timestamp ordering corrected.
- Missing values investigated using business context.
- Cross-table relationships considered before modifying records.
- Uncertain records retained instead of being deleted blindly.
- Schema validation enforced.
- Logging enabled for monitoring and troubleshooting.

---

# 11. Conclusion

The data cleaning and quality assessment process transformed the raw CareWell Hospital dataset into a more consistent and reliable format for downstream analytics.

In addition to standard cleaning operations, detailed data quality investigations identified inconsistencies involving doctor information, patient insurance details, admission timestamps, discharge information, and insurance claim records.

Rather than applying blanket deletion or replacement strategies, each issue was evaluated using business context and cross-table relationships.

Confirmed formatting and duplicate issues were corrected, while potentially valid missing values were preserved for further investigation.

The resulting datasets provide a foundation for SQL analysis, patient flow monitoring, bed occupancy analysis, billing analysis, insurance claim investigation, and Power BI dashboard development.
