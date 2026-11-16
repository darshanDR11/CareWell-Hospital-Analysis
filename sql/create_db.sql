CREATE DATABASE carewell_hospital;

USE carewell_hospital;




-- 1. Hospitals
CREATE TABLE hospitals (
    hospital_id VARCHAR(20) PRIMARY KEY,
    hospital_name VARCHAR(255),
    city VARCHAR(100)
);
LOAD DATA INFILE "D:\\PROJECTS\\CareWell_Hospital\\cleaned_dataset\\hospitals.csv" 
INTO TABLE hospitals
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES;




-- 2. Departments
CREATE TABLE departments (
    dept_id VARCHAR(20) PRIMARY KEY,
    dept_name VARCHAR(100),
    benchmark_alos_days DECIMAL(5, 2)
);
LOAD DATA INFILE "D:\\PROJECTS\\CareWell_Hospital\\cleaned_dataset\\departments.csv" 
INTO TABLE departments
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 lines;




-- 3. Wards
CREATE TABLE wards (
    ward_id VARCHAR(20) PRIMARY KEY,
    hospital_id VARCHAR(20),
    ward_name VARCHAR(100),
    beds_total INT,
    FOREIGN KEY (hospital_id) REFERENCES hospitals(hospital_id)
);
LOAD DATA INFILE "D:\\PROJECTS\\CareWell_Hospital\\cleaned_dataset\\wards.csv" INTO TABLE wards
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(hospital_id, ward_id, ward_name, beds_total);




-- 4. Doctors
CREATE TABLE doctors (
    doctor_id VARCHAR(20) PRIMARY KEY,
    doctor_name VARCHAR(255),
    dept_id VARCHAR(20),
    hospital_id VARCHAR(20),
    join_date DATE,
    senior_doctor_id VARCHAR(20),
    FOREIGN KEY (dept_id) REFERENCES departments(dept_id),
    FOREIGN KEY (hospital_id) REFERENCES hospitals(hospital_id)
);
LOAD DATA INFILE "D:\\PROJECTS\\CareWell_Hospital\\cleaned_dataset\\doctors.csv" INTO TABLE doctors
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES;




-- 5. Patients
CREATE TABLE patients (
    patient_id VARCHAR(20) PRIMARY KEY,
    gender VARCHAR(10),
    dob DATE,
    city VARCHAR(100),
    insurance_id VARCHAR(50)
);
LOAD DATA INFILE "D:\\PROJECTS\\CareWell_Hospital\\cleaned_dataset\\patients.csv" INTO TABLE patients
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES;




-- 6. Admissions
CREATE TABLE admissions (
    admission_id VARCHAR(20) PRIMARY KEY,
    patient_id VARCHAR(20),
    hospital_id VARCHAR(20),
    dept_id VARCHAR(20),
    admit_ts TIMESTAMP,
    discharge_ts TIMESTAMP,
    doctor_id VARCHAR(20),
    admit_type VARCHAR(50),
    diagnosis_code VARCHAR(20),
    ward_id VARCHAR(20),
    FOREIGN KEY (patient_id) REFERENCES patients(patient_id),
    FOREIGN KEY (hospital_id) REFERENCES hospitals(hospital_id),
    FOREIGN KEY (dept_id) REFERENCES departments(dept_id),
    FOREIGN KEY (doctor_id) REFERENCES doctors(doctor_id),
    FOREIGN KEY (ward_id) REFERENCES wards(ward_id)
);
LOAD DATA INFILE 'D:\\PROJECTS\\CareWell_Hospital\\cleaned_dataset\\admissions.csv'
INTO TABLE admissions
FIELDS TERMINATED BY ',' 
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES
(admission_id,patient_id,hospital_id,dept_id,admit_ts,@v_discharge_ts,doctor_id,admit_type,diagnosis_code,ward_id)
SET discharge_ts = IF(@v_discharge_ts='', NULL, @v_discharge_ts);



-- 7. Bed Day Snapshot
CREATE TABLE bed_day_snapshot (
    snapshot_date DATE,
    hospital_id VARCHAR(20),
    ward_id VARCHAR(20),
    beds_total INT,
    beds_occupied INT,
    beds_blocked INT,
    PRIMARY KEY (snapshot_date, ward_id),
    FOREIGN KEY (hospital_id) REFERENCES hospitals(hospital_id),
    FOREIGN KEY (ward_id) REFERENCES wards(ward_id)
);
LOAD DATA INFILE 'D:\\PROJECTS\\CareWell_Hospital\\cleaned_dataset\\bed_day_snapshot.csv'
INTO TABLE bed_day_snapshot
FIELDS TERMINATED BY ',' 
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES;




-- 8. Bills
CREATE TABLE bills (
    bill_id VARCHAR(20) PRIMARY KEY,
    admission_id VARCHAR(20),
    room_charges DECIMAL(12, 2),
    pharmacy DECIMAL(12, 2),
    procedures DECIMAL(12, 2),
    total_amount DECIMAL(12, 2),
    payer_type VARCHAR(50),
    FOREIGN KEY (admission_id) REFERENCES admissions(admission_id)
);
LOAD DATA INFILE 'D:\\PROJECTS\\CareWell_Hospital\\cleaned_dataset\\bills.csv'
INTO TABLE bills
FIELDS TERMINATED BY ',' 
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES;




-- 9. Claims
CREATE TABLE claims (
    claim_id VARCHAR(20) PRIMARY KEY,
    bill_id VARCHAR(20),
    insurer VARCHAR(100),
    claimed_amt DECIMAL(12, 2),
    approved_amt DECIMAL(12, 2),
    status VARCHAR(50),
    reason VARCHAR(255),
    submitted_date DATE,
    settled_date DATE,
    FOREIGN KEY (bill_id) REFERENCES bills(bill_id)
);
LOAD DATA INFILE 'D:\\PROJECTS\\CareWell_Hospital\\cleaned_dataset\\claims.csv'
INTO TABLE claims
FIELDS TERMINATED BY ',' 
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES
(claim_id,bill_id,insurer,claimed_amt,approved_amt,status,@v_reason,submitted_date,@v_settled_date)
SET reason = IF(@v_reason='', NULL, @v_reason), settled_date = IF(@v_settled_date='', NULL, @v_settled_date);



