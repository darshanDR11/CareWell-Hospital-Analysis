-- Rank hospitals by occupancy
with hospital_occupancy as (
	select
		h.hospital_id,
        h.hospital_name,
        round(100 * sum(beds_occupied) / sum(beds_total), 2) as occupancy_percentage
	from bed_day_snapshot as bs
    join hospitals as h on bs.hospital_id = h.hospital_id
    group by h.hospital_id, h.hospital_name
)
select 
	*,
	dense_rank() over(order by occupancy_percentage desc) as occupancy_rank
from hospital_occupancy;




-- Rank departments by average length of stay
with department_alos as (
	select 
		d.dept_id,
        d.dept_name,
        d.benchmark_alos_days,
        round(avg(timestampdiff(second, admit_ts, discharge_ts)/86400),2) as actual_alos
	from admissions as a 
    join departments as d on a.dept_id = d.dept_id
    where discharge_ts is not null
    group by d.dept_id, d.dept_name, d.benchmark_alos_days
) 
select 
	*,
    round(actual_alos - benchmark_alos_days, 2) as difference_from_benchmark,
    dense_rank() over(order by actual_alos desc) as alos_rank
from department_alos;




-- Find the top 3 departments in each hospital by admissions
with department_volume as (
	select
		h.hospital_id, 
        h.hospital_name, 
        d.dept_id, 
        d.dept_name,
        count(*) as total_admissions
	from admissions as a
    join hospitals as h on a.hospital_id = h.hospital_id
    join departments as d on a.dept_id = d.dept_id
    group by h.hospital_id, h.hospital_name, d.dept_id, d.dept_name
)
select 
	* 
from (select 
		*, 
        row_number() over(partition by hospital_id order by total_admissions desc) as dept_rank
	from department_volume) as ranked_departments
where dept_rank <= 3 
order by hospital_id, dept_rank;




-- Monthly hospital admission trends using LAG()
with monthly_admission as (
	select 
		hospital_id,
		date_format(admit_ts, '%Y-%m') as admission_month,
		count(*) as total_admissions
	from admissions
    group by hospital_id, date_format(admit_ts, '%Y-%m')
    order by admission_month
),
monthly_comparison as(
	select 
		*,
        lag(total_admissions) over(partition by hospital_id order by admission_month) as previous_month_admission
	from monthly_admission
)
select 
	*,
    total_admissions - previous_month_admission as admission_change,
    round(100 * (total_admissions - previous_month_admission) / nullif(previous_month_admission, 0), 2) as growth_percentage
from monthly_comparison order by hospital_id, admission_month;

select * from admissions;




-- Monthly-hospital financial performance using LEAD()
with monthly_financials as (
	select
		hospital_id,
		date_format(submitted_date, '%Y-%m') as claim_month,
        count(*) as total_claims,
        sum(claimed_amt) as total_claimed_amt,
        sum(approved_amt) as total_approved_amt,
        sum(claim_gap) as potential_recovery_amount
	from vw_claim_analysis
    group by hospital_id, date_format(submitted_date, '%Y-%m')
),
next_month_comparison as (
	select 
		*,
		lead(potential_recovery_amount) over(partition by hospital_id order by claim_month) as next_month_potential_recovery_amount
	from monthly_financials 
)
select 
	*,
    potential_recovery_amount - next_month_potential_recovery_amount as recovery_amount_change
from next_month_comparison order by claim_month;




-- Divide hospitals into four occupancy groups using NTILE()
with hospital_occupancy as (
	select
		h.hospital_id,
        h.hospital_name,
        round(100 * sum(beds_occupied) / sum(beds_total), 2) as occupancy_percentage
	from bed_day_snapshot as bs
    join hospitals as h on bs.hospital_id = h.hospital_id
    group by h.hospital_id, h.hospital_name
)
select 
	*,
	ntile(4) over(order by occupancy_percentage desc) as occupancy_rank
from hospital_occupancy;

-- Interpretation:
-- - Quartile 1: Highest occupancy group.
-- - Quartile 2: Second-highest group.
-- - Quartile 3: Third-highest group.
-- - Quartile 4: Lowest occupancy group.




-- create view for admission analytics
create or replace view vw_admission_analytics as
select 
	a.admission_id,
    a.patient_id,
    a.admit_ts,
    a.discharge_ts,
    a.admit_type,
    a.diagnosis_code,
    
	h.hospital_id, 
    h.hospital_name,
    
    d.dept_id,
    d.dept_name,
    
    doc.doctor_id,
    doc.doctor_name,
    
    case 
		when discharge_ts is not null then round(timestampdiff(second, admit_ts, discharge_ts)/86400.0,2) 
        else null
	end as length_of_stay,
    
    case 
		when discharge_ts is null then 'Ongoing'
        when admit_ts > discharge_ts then 'Invalid'
        else 'Complted'
	end as admission_status
from admissions as a 
join hospitals as h on a.hospital_id = h.hospital_id
join departments as d on a.dept_id = d.dept_id
join wards as w on a.ward_id = w.ward_id
join doctors as doc on a.doctor_id = doc.doctor_id;

select * from vw_admission_analytics;




-- Daily hospital occupancy
create or replace view vw_daily_hospital_occupancy as 
select 
	bs.snapshot_date, 
    h.hospital_id,
    h.hospital_name,
    sum(beds_total) as total_beds,
    sum(beds_occupied) as total_occupied_beds,
    sum(beds_blocked) as total_blocked_beds,
    round(100.0 * sum(beds_occupied) / sum(beds_total)) as occupancy_percentage
from bed_day_snapshot as bs
join hospitals as h on bs.hospital_id = h.hospital_id
group by bs.snapshot_date, h.hospital_id, h.hospital_name
order by bs.snapshot_date, h.hospital_id;

select * from vw_daily_hospital_occupancy;




-- hospital wise Monthly claim performance
create or replace view vw_monthly_claim_performance as 
select
	hospital_id, 
    hospital_name,
    date_format(submitted_date, '%Y-%m') as claim_month,
    
    count(*) as total_claims,
    
    count(case when claim_status = 'APPROVED' then 1 else null end) as total_approved_claims,
    count(case when claim_status = 'REJECTED' then 1 else null end) as total_rejected_claims,
    count(case when claim_status = 'PARTIALLY APPROVED' then 1 else null end) as total_partially_approved_claims,

	sum(claimed_amt) as total_claimed_amount,
	sum(approved_amt) as total_approved_amount,
    round(100.0 * sum(approved_amt) / sum(claimed_amt), 2) as approved_amount_percentage,
    
    sum(case when claim_status = 'REJECTED' then claim_gap else 0 end) as rejected_amount,
    sum(case when claim_status = 'PARTIALLY APPROVED' then claim_gap else 0 end) as partially_approved_amount,
    
    sum(claim_gap) as potential_recovery_amount
    
from vw_claim_analysis
group by hospital_id, hospital_name, date_format(submitted_date, '%Y-%m')
order by hospital_id, claim_month;

select * from vw_monthly_claim_performance;




-- COO hospital monthly summary
create or replace view  vw_coo_hospital_monthly_summary as 
with admission_monthly as(
	select 
		hospital_id, 
        date_format(admit_ts, '%Y-%m') as month_start,
        count(*) as total_admissions,
        count(distinct patient_id) as total_unique_patients,
        round(avg(length_of_stay), 2) as alos
	from vw_admission_analytics
    group by hospital_id, date_format(admit_ts, '%Y-%m') 
),
occupancy_monthly as(
	select
		hospital_id, 
        date_format(snapshot_date, '%Y-%m') as month_start,
        round(avg(occupancy_percentage),2) as average_occupancy_percentage,
        max(occupancy_percentage) as peak_occupancy,
        count(case when occupancy_percentage > 90.0 then 1 else null end) as days_above_90_percent
	from vw_daily_hospital_occupancy
    group by hospital_id, date_format(snapshot_date, '%Y-%m')
),
financial_summury as (
	select 	
		hospital_id,
        claim_month as month_start,
        total_claims,
        total_claimed_amount,
        total_approved_amount,
        rejected_amount,
        partially_approved_amount,
        potential_recovery_amount
	from vw_monthly_claim_performance
),
month_keys as (
	select 
		distinct hospital_id, month_start 
	from (
			select hospital_id, month_start from admission_monthly
			union all 
			select hospital_id, month_start from occupancy_monthly
			union all 
			select hospital_id, month_start from financial_summury
        ) as ans
)
select 
	h.hospital_id,
    h.hospital_name,
    h.city,
    
    mk.month_start,
    
    am.total_admissions,
	am.total_unique_patients,
	am.alos,
	
    om.average_occupancy_percentage,
	om.peak_occupancy,
	om.days_above_90_percent,
	
    fs.total_claims,
	fs.total_claimed_amount,
	fs.total_approved_amount,
	fs.rejected_amount,
	fs.partially_approved_amount,
	fs.potential_recovery_amount
    
from month_keys as mk
join hospitals as h on mk.hospital_id = h.hospital_id
left join admission_monthly as am on mk.hospital_id = am.hospital_id and mk.month_start = am.month_start
left join occupancy_monthly as om on mk.hospital_id = om.hospital_id and mk.month_start = om.month_start
left join financial_summury as fs on mk.hospital_id = fs.hospital_id and mk.month_start = fs.month_start
order by h.hospital_id, mk.month_start;

select * from vw_coo_hospital_monthly_summary;




-- Latest monthly hospital performance
select 
	* 
from 
	(select 
		*,
		row_number() over(partition by hospital_id order by month_start desc) as row_num
	from vw_coo_hospital_monthly_summary) as ranked
where row_num = 1;




