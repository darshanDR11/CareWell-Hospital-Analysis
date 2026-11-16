-- Patient admission frequency
select 
	patient_id,
    min(admit_ts) as first_admission,
    max(admit_ts) as latest_admission,
    count(admission_id) as total_admissions
from admissions
group by patient_id
having count(admission_id) >= 2
order by total_admissions desc, latest_admission desc;





-- Patient admission frequency categories
with patient_frequency as (
	select 
		patient_id,
		min(admit_ts) as first_admission,
		max(admit_ts) as latest_admission,
		count(admission_id) as total_admissions
	from admissions
	group by patient_id
)
select
	case 
		when total_admissions = 1 then '1 Admission'
        when total_admissions  between 2 and 4 then '2-4 Admission'
        when total_admissions  between 5 and 7 then '5-7 Admission'
        else '7+ Admission' 
	end as admission_category,
    count(*) as total_admissions
from patient_frequency
group by admission_category
order by admission_category;




-- 30-day readmission analysis
create or replace view vw_patient_readmission_detail as
with squenced_admissions as(
	select 
		*,
        lead(admission_id) over(partition by patient_id order by admit_ts, admission_id) as next_admission_id,
		lead(admit_ts) over(partition by patient_id order by admit_ts, admission_id) as next_admit_ts
	from admissions
),
observation_period as (
	select greatest(max(admit_ts), max(discharge_ts)) as observation_end from admissions
)
select 
	admission_id,
    patient_id,
    hospital_id,
    dept_id,
    doctor_id,
    admit_ts,
    discharge_ts,
    observation_end,
    next_admission_id,
    next_admit_ts,
    case 
		when discharge_ts is null then 'Not Eligible - Not Discharged'
        when discharge_ts > date_sub(observation_end, interval 30 day) then 'Not Eligible - Incomplete Follow-up'
        when next_admit_ts is null then 'No Readmission'
        when discharge_ts > next_admit_ts then 'Overlapping Admission'
        when next_admit_ts < date_add(discharge_ts, interval 30 day) then 'Readmission within 30 day'
        else 'No Readmission' end as readmission_status,
	case 
		when discharge_ts is not null and discharge_ts < next_admit_ts and next_admit_ts < date_add(discharge_ts, interval 30 day) then datediff(next_admit_ts, discharge_ts)
        else null end as days_to_readmission
from squenced_admissions cross join observation_period
order by patient_id;




-- view 
select * from vw_patient_readmission_detail order by patient_id, admit_ts;




-- Overall 30-day readmission rate
select 
	count(*) as total_admissions,
    sum(case when readmission_status = 'Readmission within 30 day' then 1 else 0 end) as readmitted,
    round(100*sum(case when readmission_status = 'Readmission within 30 day' then 1 else 0 end)/count(*),2) as readmitted_rate
from vw_patient_readmission_detail 
where readmission_status in ('Readmission within 30 day', 'No Readmission');
-- 	total_admissions	readmitted	readmitted_rate
-- 	305358	18967	6.21




-- Readmission rate by department
select 
	d.dept_id,
    d.dept_name,
	count(*) as total_admissions,
    sum(case when readmission_status = 'Readmission within 30 day' then 1 else 0 end) as readmitted,
    round(100*sum(case when readmission_status = 'Readmission within 30 day' then 1 else 0 end)/count(*),2) as readmitted_rate
from vw_patient_readmission_detail as a
join departments as d on a.dept_id = d.dept_id
where readmission_status in ('Readmission within 30 day', 'No Readmission')
group by d.dept_id, d.dept_name
order by d.dept_id;
-- D01	CARDIOLOGY	28724	1662	5.79
-- D02	ORTHOPAEDICS	26031	1526	5.86
-- D03	NEUROLOGY	11501	667	5.80
-- D04	GENERAL MEDICINE	34900	2045	5.86
-- D05	GENERAL SURGERY	26248	1464	5.58
-- D06	PAEDIATRICS	20524	1300	6.33
-- D07	OBSTETRICS & GYNAECOLOGY	23200	1436	6.19
-- D08	NEPHROLOGY	11588	622	5.37
-- D09	ONCOLOGY	11282	605	5.36
-- D10	PULMONOLOGY	17320	970	5.60
-- D11	GASTROENTEROLOGY	17250	1018	5.90
-- D12	UROLOGY	11755	723	6.15
-- D13	ENT	8900	628	7.06
-- D14	OPHTHALMOLOGY	8872	679	7.65
-- D15	EMERGENCY SHORT STAY	30072	2540	8.45
-- D16	ICU	8509	454	5.34
-- D17	PSYCHIATRY	2727	170	6.23
-- D18	DERMATOLOGY	5955	458	7.69





-- Readmission rate by doctor
select 
	d.doctor_id,
    d.doctor_name,
	count(*) as total_admissions,
    sum(case when readmission_status = 'Readmission within 30 day' then 1 else 0 end) as readmitted,
    round(100*sum(case when readmission_status = 'Readmission within 30 day' then 1 else 0 end)/count(*),2) as readmitted_rate
from vw_patient_readmission_detail as a
join doctors as d on a.doctor_id = d.doctor_id
where readmission_status in ('Readmission within 30 day', 'No Readmission')
group by d.doctor_id, d.doctor_name
order by d.doctor_id;
-- DR0154	DR. KAVITA SHARMA	151	21	13.91
-- DR0409	DR. SURESH IYER	51	7	13.73
-- DR0416	DR. ANIL SHAH	47	6	12.77
-- DR0643	DR. NIDHI SHARMA	120	15	12.50
-- DR0807	DR. NIDHI JOSHI	153	19	12.42
-- DR0648	DR. KAVITA DESAI	139	17	12.23
-- DR0429	DR. SURESH SHARMA	119	14	11.76
-- DR0209	DR. ANIL DESAI	129	15	11.63
-- DR0360	DR. POOJA MEHTA	258	30	11.63
-- DR0810	DR. AMIT SHAH	157	18	11.47




-- Doctor and senior doctor relationship (Self JOIN)
select 
	j.doctor_id,
    j.doctor_name,
    j.senior_doctor_id,
    coalesce(s.doctor_name,'Senior Doctor / No Senior Doctor assigned') as senior_doctor_name
from doctors as j
left join doctors as s on j.senior_doctor_id = s.doctor_id
order by j.doctor_id;




-- Doctor count by hospital and department
select 
	h.hospital_id, h.hospital_name, de.dept_id, de.dept_name, count(*) as total_doctors
from hospitals as h
cross join departments as de
left join doctors as d on d.hospital_id = h.hospital_id and d.dept_id = de.dept_id
group by h.hospital_id, h.hospital_name, de.dept_id, de.dept_name
order by h.hospital_id, de.dept_id;




-- Doctor workload analysis
select 
	a.doctor_id,
    d.doctor_name,
    count(admission_id) as total_admissions,
    count(distinct patient_id) as unique_patients,
    round(avg(case when discharge_ts is not null then timestampdiff(second, admit_ts, discharge_ts)/86400 end), 2) as alos
from admissions as a
join doctors as d on a.doctor_id = d.doctor_id
group by a.doctor_id
order by unique_patients desc;	




-- Top 10 doctors by patient volume
select 
	a.doctor_id,
    d.doctor_name,
    count(admission_id) as total_admissions,
    count(distinct patient_id) as unique_patients
from admissions as a
join doctors as d on a.doctor_id = d.doctor_id
group by a.doctor_id
order by total_admissions desc limit 10;	




-- Doctor-wise average length of stay vs department benchmark
with ans as (
	select 
		d.doctor_id,
		d.doctor_name,
		de.dept_id,
		de.dept_name,
		benchmark_alos_days,
		round(avg(case when discharge_ts is not null then timestampdiff(second, admit_ts, discharge_ts)/86400 end), 2) as alos
	from admissions as a
	join doctors as d on a.doctor_id = d.doctor_id
	join departments as de on de.dept_id = d.dept_id
	group by d.doctor_id, d.doctor_name, de.dept_id, de.dept_name
)
select 
	*,
    round(alos-benchmark_alos_days, 2) as differenece,
    case 
		when alos < benchmark_alos_days then 'Below Benchmark'
		when alos > benchmark_alos_days then 'Above Benchmark'
		else 'At Benchmark'
	end as performance_category
from ans
order by differenece;




-- Doctor admission trend by month
select 
	d.doctor_id,
    d.doctor_name,
	date_format(admit_ts, '%Y-%m') as admission_month,
    count(admission_id) as total_admissions,
    count(distinct patient_id) as unique_patients
from admissions as a
join doctors as d on a.doctor_id = d.doctor_id
group by d.doctor_id, date_format(admit_ts, '%Y-%m')
order by d.doctor_id, admission_month;


