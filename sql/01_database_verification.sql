-- ==========================================
-- CAREWELL HOSPITALS
-- PART 1: DATABASE VERIFICATION
-- ==========================================




-- TASK 1: Database and Table Verification

use carewell_hospital;

select database();

show tables;

describe admissions;
describe bed_day_snapshot;
describe bills;
describe claims;
describe departments;
describe doctors;
describe hospitals;
describe patients;
describe wards;




-- TASK 2: Primary Key and Foreign Key Verification

select 
	table_name, 
    column_name, 
    constraint_name 
from information_schema.key_column_usage 
where table_schema = 'carewell_hospital' 
and constraint_name = 'primary' 
order by table_name;

select 
	table_name as child_table,
    column_name as foreign_key_columns,
    constraint_name,
    referenced_table_name as parent_table,
    referenced_column_name as referenced_column
from information_schema.key_column_usage 
where table_schema = 'carewell_hospital'
and referenced_table_name is not null
order by table_name;




-- TASK 3: Record Count and Data Consistency

select 'admissions' as table_name, count(*) as total_records from admissions 
union all
select 'bed_day_snapshot', count(*) from bed_day_snapshot 
union all
select 'bills', count(*) from bills 
union all
select 'claims', count(*) from claims 
union all
select 'departments', count(*) from departments 
union all
select 'doctors', count(*) from doctors 
union all
select 'hospitals', count(*) from hospitals 
union all
select 'patients', count(*) from patients 
union all
select 'wards', count(*) as total_records from wards;




-- TASK 4: Relationship Validation

-- bed_day_snapshot
select 
	count(*) as total_records 
from bed_day_snapshot as b
left join hospitals as h on b.hospital_id = h.hospital_id
where h.hospital_id is null;

select 
	count(*) as total_records 
from bed_day_snapshot as b
left join wards as w on b.ward_id = w.ward_id
where w.ward_id is null;


-- admissions
select 
	count(*) as total_records 
from admissions as a
left join patients as p on a.patient_id = p.patient_id
where p.patient_id is null;

select 
	count(*) as total_records 
from admissions as a
left join hospitals as h on a.hospital_id = h.hospital_id
where h.hospital_id is null;

select 
	count(*) as total_records 
from admissions as a
left join departments as d on a.dept_id = d.dept_id
where d.dept_id is null;

select 
	count(*) as total_records 
from admissions as a
left join doctors as d on a.doctor_id = d.doctor_id
where d.doctor_id is null;

select 
	count(*) as total_records 
from admissions as a
left join wards as w on a.ward_id = w.ward_id
where w.ward_id is null;


-- bills
select 
	count(*) as total_records 
from bills as b
left join admissions as a on b.admission_id = a.admission_id
where a.admission_id is null;


-- claims
select 
	count(*) as total_records 
from claims as c
left join bills as b on c.bill_id = b.bill_id
where b.bill_id is null;


-- wards
select 
	count(*) as total_records
from wards as w 
left join hospitals as h on w.hospital_id = h.hospital_id 
where h.hospital_id is null;


-- doctors
select 
	count(*) as total_records
from doctors as d 
left join hospitals as h on d.hospital_id = h.hospital_id 
where h.hospital_id is null;

select 
	count(*) as total_records
from doctors as d 
left join departments as de on d.dept_id = de.dept_id
where de.dept_id is null;


SELECT
    a.admission_id,
    a.hospital_id AS admission_hospital,
    d.hospital_id AS doctor_hospital,
    a.doctor_id
FROM admissions a
JOIN doctors d
    ON a.doctor_id = d.doctor_id
WHERE a.hospital_id <> d.hospital_id;

SELECT
    a.admission_id,
    a.dept_id AS admission_department,
    d.dept_id AS doctor_department,
    a.doctor_id
FROM admissions a
JOIN doctors d
    ON a.doctor_id = d.doctor_id
WHERE a.dept_id <> d.dept_id;

SELECT
    a.admission_id,
    a.hospital_id AS admission_hospital,
    w.hospital_id AS ward_hospital,
    a.ward_id
FROM admissions a
JOIN wards w
    ON a.ward_id = w.ward_id
WHERE a.hospital_id <> w.hospital_id;

SELECT
    bs.snapshot_date,
    bs.hospital_id AS snapshot_hospital,
    w.hospital_id AS ward_hospital,
    bs.ward_id
FROM bed_day_snapshot bs
JOIN wards w
    ON bs.ward_id = w.ward_id
WHERE bs.hospital_id <> w.hospital_id;

SELECT
    bs.snapshot_date,
    bs.hospital_id,
    bs.ward_id,
    w.beds_total AS master_beds,
    bs.beds_total AS snapshot_beds
FROM bed_day_snapshot bs
JOIN wards w
    ON bs.ward_id = w.ward_id
WHERE bs.hospital_id = w.hospital_id
AND bs.beds_total <> w.beds_total;

