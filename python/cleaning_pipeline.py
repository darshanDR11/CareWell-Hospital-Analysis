import pandas as pd
import numpy as np

from pathlib import Path

import time
import logging
from functools import wraps


PROJECT_ROOT = Path(__file__).resolve().parent.parent
SOURCE_DATA_DIR = PROJECT_ROOT / 'dataset'
DESTINATION_DATA_DIR = PROJECT_ROOT / 'cleaned_dataset'

DESTINATION_DATA_DIR.mkdir(parents=True, exist_ok=True)


logging.basicConfig(
    filename="carewell_pipeline.log",
    level=logging.INFO,
    format="%(asctime)s - %(levelname)s - %(message)s",
    force=True
)

def timer(func):
    @wraps(func)
    def wrapper(*args, **kwargs):
        start = time.perf_counter()

        try:
            return func(*args, **kwargs)
        finally:
            end = time.perf_counter()
            print(f"{func.__name__} executed in {end-start:.4f} seconds")

    return wrapper

def log(func):
    @wraps(func)
    def wrapper(*args, **kwargs):
        logging.info(f"Started: {func.__name__}")

        try:
            result = func(*args, **kwargs)
            logging.info(f"Completed: {func.__name__}")
            return result

        except Exception:
            logging.exception(f"Failed: {func.__name__}")
            raise

    return wrapper

tables = {
    "admissions": {
        "required_columns": ["admission_id","patient_id","hospital_id","dept_id","admit_ts","discharge_ts","doctor_id","admit_type","diagnosis_code","ward_id",],
        "text_columns": ["admission_id","patient_id","hospital_id","dept_id","doctor_id","admit_type","diagnosis_code","ward_id",],
        "date_columns": ["admit_ts", "discharge_ts"],
        "numerical_columns": [],
    },
    "bed_day_snapshot": {
        "required_columns": ["snapshot_date","hospital_id","ward_id","beds_total","beds_occupied","beds_blocked",],
        "text_columns": ["hospital_id", "ward_id"],
        "date_columns": ["snapshot_date"],
        "numerical_columns": ["beds_total", "beds_occupied", "beds_blocked"],
    },
    "bills": {
        "required_columns": ["bill_id","admission_id","room_charges","pharmacy","procedures","total_amount","payer_type",],
        "text_columns": ["bill_id", "admission_id", "payer_type"],
        "date_columns": [],
        "numerical_columns": ["room_charges","pharmacy","procedures","total_amount",],
    },
    "claims": {
        "required_columns": ["claim_id","bill_id","insurer","claimed_amt","approved_amt","status","reason","submitted_date","settled_date",],
        "text_columns": ["claim_id", "bill_id", "insurer", "status", "reason"],
        "date_columns": ["submitted_date", "settled_date"],
        "numerical_columns": ["claimed_amt", "approved_amt"],
    },
    "departments": {
        "required_columns": ["dept_id", "dept_name", "benchmark_alos_days"],
        "text_columns": ["dept_id", "dept_name"],
        "date_columns": [],
        "numerical_columns": ["benchmark_alos_days"],
    },
    "doctors": {
        "required_columns": ["doctor_id","doctor_name","dept_id","hospital_id","join_date","senior_doctor_id",],
        "text_columns": ["doctor_id","doctor_name","dept_id","hospital_id","senior_doctor_id",],
        "date_columns": ["join_date"],
        "numerical_columns": [],
    },
    "hospitals": {
        "required_columns": ["hospital_id", "hospital_name", "city"],
        "text_columns": ["hospital_id", "hospital_name", "city"],
        "date_columns": [],
        "numerical_columns": [],
    },
    "patients": {
        "required_columns": ["patient_id","gender","dob","city","insurance_id",],
        "text_columns": ["patient_id", "gender", "city", "insurance_id"],
        "date_columns": ["dob"],
        "numerical_columns": [],
    },
    "wards": {
        "required_columns": ["hospital_id","ward_id","ward_name","beds_total",],
        "text_columns": ["hospital_id", "ward_id", "ward_name"],
        "date_columns": [],
        "numerical_columns": ["beds_total"],
    },
}


@timer
@log
def load_dataset(file_name):
    
    try:
        file_path = SOURCE_DATA_DIR/file_name
        df = pd.read_csv(file_path) 
        print(f"\n{file_name} loaded succssfully.")

        try:

            required_columns = tables[Path(file_name).stem]['required_columns']

            missing_columns = [col for col in required_columns if col not in df.columns]

            if missing_columns:
                raise Exception(f"Missing columns: {missing_columns}")

            text_columns = tables[Path(file_name).stem]['text_columns']

            for col in text_columns:
                df[col] = df[col].str.strip().str.upper()
                df[col] = df[col].replace(['','NA', 'N/A', 'na', 'n/a'], np.nan)

            date_columns = tables[Path(file_name).stem]['date_columns']

            for col in date_columns:
                df[col] = pd.to_datetime(df[col])


            numerical_columns = tables[Path(file_name).stem]['numerical_columns']

            for col in numerical_columns:
                df[col] = pd.to_numeric(df[col])


            print("Cleaning completed.")
            have_duplicates = df.duplicated().sum()

            if have_duplicates != 0:
                print("Duplicates records :-",have_duplicates)
                df.drop_duplicates(inplace=True)

            df.to_csv(DESTINATION_DATA_DIR/file_name, index=False)

            return df

        except Exception as e:
            print("Cleaning pipeline error:", e)

        return None
        
    except FileNotFoundError:
        print(f"Eror :- {file_name} not found.")
    
    except Exception as e:
        print(f"Errror :- {e}")
    
    return None

def run_pipeline():
    admissions = load_dataset('admissions.csv')
    bed_day_snapshot = load_dataset('bed_day_snapshot.csv')
    bills = load_dataset('bills.csv')
    claims = load_dataset('claims.csv')
    departments = load_dataset('departments.csv')
    doctors = load_dataset('doctors.csv')
    hospitals = load_dataset('hospitals.csv')
    patients = load_dataset('patients.csv')
    wards = load_dataset('wards.csv')

    mask = admissions['admit_ts'] > admissions['discharge_ts']

    admissions.loc[mask, ['admit_ts', 'discharge_ts']] = (
        admissions.loc[mask, ['discharge_ts', 'admit_ts']].to_numpy()
    )

    print(f"Admission dates corrected: {mask.sum()} records")

    admissions.to_csv(DESTINATION_DATA_DIR / 'admissions.csv', index=False)

    return (admissions, bed_day_snapshot, bills, claims, departments, doctors, hospitals, patients, wards)

