-- Daily Bed Occupancy
select 
	bs.snapshot_date, 
    h.hospital_name, 
    bs.hospital_id,
    w.ward_name,
    bs.ward_id,
    bs.beds_total,
    bs.beds_occupied,
    bs.beds_blocked,
    round(100 * bs.beds_occupied / bs.beds_total,2) as occupancy_percentage,
    case 
		when bs.beds_total <= 0 then 'Invalid Capacity'
		when bs.beds_total < bs.beds_occupied then 'over 100% Occupancy'
        when round(bs.beds_occupied / bs.beds_total, 2) > 0.9 then 'High Occupancy'
        else 'Normal Occupancy' 
	end as occupancy_status,
    case when bs.beds_total < bs.beds_occupied + beds_blocked then 'Capacity Inconsistency' else 'Valid' end as capacity_check
from bed_day_snapshot as bs
join hospitals as h on bs.hospital_id = h.hospital_id
join wards as w on bs.ward_id = w.ward_id
order by bs.snapshot_date, h.hospital_name, w.ward_name;





-- Hospital-level daily occupancy
select 
	bs.snapshot_date, 
    h.hospital_name, 
    bs.hospital_id,
    sum(bs.beds_total) as total_beds,
    sum(bs.beds_occupied) as occupied_beds,
    sum(bs.beds_blocked) as blocked_beds,
    round(100 * sum(bs.beds_occupied) / sum(bs.beds_total),2) as occupancy_percentage
from bed_day_snapshot as bs
join hospitals as h on bs.hospital_id = h.hospital_id
group by bs.snapshot_date, bs.hospital_id
order by bs.snapshot_date, h.hospital_name;





-- Monthly Bed Occupancy
select 
	date_format(bs.snapshot_date, '%Y-%m') as occupancy_month, 
    h.hospital_name, 
    w.ward_name,
    round(avg(100 * bs.beds_occupied / bs.beds_total),2) as occupancy_percentage,
    max(round(100*bs.beds_occupied / bs.beds_total,2)) as maximum_daily_occupancy,
    min(round(100*bs.beds_occupied / bs.beds_total,2)) as minimum_daily_occupancy
from bed_day_snapshot as bs
join hospitals as h on bs.hospital_id = h.hospital_id
join wards as w on bs.ward_id = w.ward_id
group by date_format(bs.snapshot_date, '%Y-%m'), h.hospital_name, w.ward_name
order by h.hospital_name, w.ward_name, occupancy_month;





-- Month-End Bed Occupancy
with month_end_snapshot as(
	select 
		* 
	from (
		select 
			*,
			date_format(snapshot_date, '%Y-%m') as occupancy_month,
			row_number() over(partition by hospital_id, ward_id, year(snapshot_date), month(snapshot_date) order by snapshot_date desc) as row_num
		from bed_day_snapshot) as ans 
        where row_num = 1
)
select 
	ms.occupancy_month,
    h.hospital_name, 
    ms.hospital_id,
    w.ward_name,
    ms.ward_id,
    ms.beds_total,
    ms.beds_occupied,
    ms.beds_blocked,
    round(100 * ms.beds_occupied / ms.beds_total,2) as month_end_occupancy_percentage
from month_end_snapshot as ms
join hospitals as h on ms.hospital_id = h.hospital_id
join wards as w on ms.ward_id = w.ward_id
order by occupancy_month;





-- Identify Wards Above 90% Occupancy for 5+ Consecutive Days
with high_occupancy as (
	select
		*,
        round(beds_occupied / beds_total * 100, 2) as occupancy_percentage,
        date_sub(snapshot_date, interval row_number() over(partition by hospital_id, ward_id order by snapshot_date) day) as streak_groups
	from bed_day_snapshot
    where  beds_occupied / beds_total > 0.9
),
streak_group as (
	select 
		streak_groups, 
        hospital_id, 
        ward_id,
        min(snapshot_date) as streak_start_date,
        max(snapshot_date) as streak_end_date,
        count(*) as consecutive_days,
        round(avg(occupancy_percentage),2) as average_occupancy,
        max(occupancy_percentage) as peak_occupancy
	from high_occupancy
    group by streak_groups, hospital_id, ward_id 
    having count(*) >= 5
)
select 
	hospital_name, 
    ward_name, 
    streak_start_date,
    streak_end_date, 
    consecutive_days, 
    average_occupancy, 
    peak_occupancy
from streak_group as sg 
join hospitals as h on sg.hospital_id = h.hospital_id
join wards as w on sg.ward_id = w.ward_id
order by consecutive_days desc;
    
    
    


-- Department-wise ALOS versus benchmark
with admissions_los as (
select 
	admission_id, 
    dept_id,
    round(timestampdiff(second, admit_ts, discharge_ts)/86400,2) as los
from admissions as a
where discharge_ts is not null 
and admit_ts is not null 
and admit_ts <= discharge_ts
),
dept_wise_alos as(
	select 
		d.dept_id, 
		d.dept_name, 
		d.benchmark_alos_days,
		round(avg(los),2) as actual_alos
	from departments as d
	join admissions_los as a on d.dept_id = a.dept_id
	group by d.dept_id, d.dept_name, d.benchmark_alos_days
) 
select 
	*,
    round(actual_alos - benchmark_alos_days,2) as difference
from dept_wise_alos;





-- Top 10 Diagnosis–Department Pairs Driving Extra Bed-Days
with admission_los as (
	select 
		admission_id, 
        dept_id,
        diagnosis_code,
        round(timestampdiff(second, admit_ts, discharge_ts)/86400.0,2) as los
	from admissions 
    where discharge_ts is not null
    and admit_ts is not null
    and admit_ts <= discharge_ts
),
excess_bed_days as (
	select 
		admission_id,
        a.dept_id,
        dept_name,
        benchmark_alos_days,
        diagnosis_code,
        los,
        greatest(los-benchmark_alos_days,0) as extra_bed_days
	from admission_los as a 
    join departments as d on a.dept_id = d.dept_id
)
select 
	dept_id,
    diagnosis_code,
    dept_name,
    benchmark_alos_days,
    count(*) as total_admissions,
    round(avg(los),2) as actual_alos,
    sum(extra_bed_days) as total_extra_bed_days,
    round(avg(extra_bed_days),2) as average_extra_bed_days
from excess_bed_days
group by dept_id, diagnosis_code, dept_name, benchmark_alos_days
order by total_extra_bed_days desc
limit 10;




-- Top 10 most occupied wards
select 
	w.ward_name, 
    h.hospital_name,
    round(avg(100 * bs.beds_occupied/bs.beds_total),2) as average_occupancy
from bed_day_snapshot as bs
join wards as w on bs.ward_id = w.ward_id
join hospitals as h on bs.hospital_id = h.hospital_id
group by w.ward_name, h.hospital_name
order by average_occupancy desc limit 10;




-- Departments with the highest patient volumes
select 
	a.dept_id,
    d.dept_name,
    count(admission_id) as total_admissions,
    count(distinct patient_id) as unique_patients
from admissions as a
join departments as d on a.dept_id = d.dept_id
group by dept_id, dept_name
order by unique_patients desc;	


