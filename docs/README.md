# 🏥 CareWell Hospital Analytics Dataset

## Overview

The **CareWell Hospital Analytics Dataset** contains operational, clinical, financial, and capacity-management data collected across a multi-hospital healthcare network. The dataset consists of **9 CSV tables**, a **data dictionary**, and approximately **1,292,783 records** in total.

This dataset can be used for:

- Hospital operations analytics
- Patient admission trend analysis
- Average Length of Stay (ALOS) monitoring
- Revenue and billing analysis
- Insurance claim performance tracking
- Bed occupancy optimization
- Doctor and department performance analysis
- Healthcare business intelligence dashboards

---

## Dataset Summary

| Table | Rows | Description |
|---------|---------:|-------------|
| admissions.csv | 350,000 | Patient admission and discharge records |
| bills.csv | 350,000 | Billing and payment details for admissions |
| patients.csv | 260,000 | Patient demographic information |
| claims.csv | 244,133 | Insurance claim processing records |
| bed_day_snapshot.csv | 87,600 | Daily bed occupancy snapshots |
| doctors.csv | 900 | Doctor master data |
| wards.csv | 120 | Hospital ward information |
| departments.csv | 18 | Department master data and benchmarks |
| hospitals.csv | 12 | Hospital master information |

**Total Records:** 1,292,783+

---

# Entity Relationship Overview

```text
Hospitals
   │
   ├── Departments
   │       │
   │       └── Doctors
   │
   ├── Wards
   │
   └── Admissions
            │
            ├── Patients
            ├── Bills
            │      └── Claims
            └── Doctors 
```

# 📋 Table Details

## 1. admissions.csv

**Purpose:** Stores all patient admission and discharge records.

| Column | Data Type | Description | Example |
|----------|----------|----------|----------|
| admission_id | Text | Unique admission identifier | A0000001 |
| patient_id | Text | Patient identifier | P0158174 |
| hospital_id | Text | Hospital where admission occurred | H09 |
| dept_id | Text | Department handling admission | D14 |
| admit_ts | DateTime | Admission timestamp | 2024-10-01 00:00:37 |
| discharge_ts | DateTime | Discharge timestamp | 2024-10-02 10:33:52 |
| doctor_id | Text | Attending doctor | DR0813 |
| admit_type | Text | Admission category | Emergency |
| diagnosis_code | Text | Diagnosis code | H40 |
| ward_id | Text | Assigned ward | H09-W07 |

---

## 2. bills.csv

**Purpose:** Contains billing information generated for admissions.

| Column | Data Type | Description | Example |
|----------|----------|----------|----------|
| bill_id | Text | Unique bill identifier | B0000001 |
| admission_id | Text | Linked admission | A0000001 |
| room_charges | Number | Room-related charges | 3600.0 |
| pharmacy | Number | Pharmacy expenses | 3810.0 |
| procedures | Number | Procedure-related charges | 35830.0 |
| total_amount | Number | Total bill amount | 43240.0 |
| payer_type | Text | Payment source | Insurance |

---

## 3. patients.csv

**Purpose:** Stores demographic and insurance information of patients.

| Column | Data Type | Description | Example |
|----------|----------|----------|----------|
| patient_id | Text | Unique patient ID | P0000001 |
| gender | Text | Gender of patient | F |
| dob | Date | Date of birth | 1992-05-10 |
| city | Text | Patient city | Pune |
| insurance_id | Text | Insurance scheme ID | PMJAY |

---

## 4. claims.csv

**Purpose:** Tracks insurance claim submissions and settlements.

| Column | Data Type | Description | Example |
|----------|----------|----------|----------|
| claim_id | Text | Unique claim identifier | CL0000001 |
| bill_id | Text | Associated bill | B0000001 |
| insurer | Text | Insurance provider | ICICI Lombard |
| claimed_amt | Number | Claimed amount | 43240.0 |
| approved_amt | Number | Approved amount | 43240.0 |
| status | Text | Claim status | Approved |
| reason | Text | Claim rejection/approval remark | Treatment not covered |
| submitted_date | Date | Claim submission date | 2024-10-03 |
| settled_date | Date | Claim settlement date | 2024-10-21 |

---

## 5. bed_day_snapshot.csv

**Purpose:** Daily ward-level bed occupancy snapshots.

| Column | Data Type | Description | Example |
|----------|----------|----------|----------|
| snapshot_date | Date | Snapshot date | 2024-10-01 |
| hospital_id | Text | Hospital identifier | H01 |
| ward_id | Text | Ward identifier | H01-W01 |
| beds_total | Number | Total available beds | 38 |
| beds_occupied | Number | Occupied beds | 3 |
| beds_blocked | Number | Blocked/unavailable beds | 0 |

---

## 6. doctors.csv

**Purpose:** Doctor master information.

| Column | Data Type | Description | Example |
|----------|----------|----------|----------|
| doctor_id | Text | Unique doctor identifier | DR0001 |
| doctor_name | Text | Doctor name | Dr. Vikram Mehta |
| dept_id | Text | Department assignment | D01 |
| hospital_id | Text | Hospital assignment | H01 |
| join_date | Date | Joining date | 2017-01-30 |
| senior_doctor_id | Text | Reporting senior doctor | DR0217 |

---

## 7. wards.csv

**Purpose:** Ward master data.

| Column | Data Type | Description | Example |
|----------|----------|----------|----------|
| hospital_id | Text | Hospital identifier | H01 |
| ward_id | Text | Ward identifier | H01-W01 |
| ward_name | Text | Ward name | General Ward A |
| beds_total | Number | Capacity of ward | 38 |

---

## 8. departments.csv

**Purpose:** Department reference table and ALOS benchmark information.

| Column | Data Type | Description | Example |
|----------|----------|----------|----------|
| dept_id | Text | Department identifier | D01 |
| dept_name | Text | Department name | Cardiology |
| benchmark_alos_days | Number | Benchmark Average Length of Stay | 4.7 |

---

## 9. hospitals.csv

**Purpose:** Hospital master data.

| Column | Data Type | Description | Example |
|----------|----------|----------|----------|
| hospital_id | Text | Hospital identifier | H01 |
| hospital_name | Text | Hospital name | CareWell Ahmedabad North |
| city | Text | Hospital city | Ahmedabad |

---


