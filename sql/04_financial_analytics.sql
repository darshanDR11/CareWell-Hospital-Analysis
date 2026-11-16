-- Inspect available claim statuses
select 
	status,
    count(*) as total_claims,
    sum(claimed_amt) as total_claimed_amt,
    sum(approved_amt) as total_approved_amt
from claims
group by status;



-- Overall claim financial summary
select 
	count(*) as total_claims,
	sum(claimed_amt) as total_claimed_amt,
    sum(approved_amt) as total_approved_amt,
    sum(claimed_amt)-sum(approved_amt) as total_claim_approval_gap,
	round(100* sum(approved_amt) / sum(claimed_amt),2) as approval_percentage
from claims;



-- view 
create or replace view vw_claim_analysis as
select 
	c.claim_id,
    c.bill_id,
    b.admission_id,

    a.patient_id,
    a.hospital_id,
    h.hospital_name,

    a.dept_id,
    d.dept_name,

    a.doctor_id,

    c.insurer,
    c.status,
    c.reason,

    c.claimed_amt,
    c.approved_amt,

    b.total_amount AS bill_amount,
    b.payer_type,

    c.submitted_date,
    c.settled_date,
    
    status as claim_status,
    
	c.claimed_amt-c.approved_amt as claim_gap,
    
    case 
		when c.settled_date is not null and c.submitted_date is not null and c.settled_date >= c.submitted_date then datediff(c.settled_date, c.submitted_date)
		else null 
	end as settlement_days
from claims as c
join bills as b on c.bill_id = b.bill_id
join admissions as a on b.admission_id = a.admission_id
join hospitals as h on a.hospital_id = h.hospital_id
join departments as d on a.dept_id = d.dept_id
order by c.claim_id;



-- verify the view 
select * from vw_claim_analysis;



-- Claim category summary
select 
	claim_status,
    count(*) as total_claims,
	sum(claimed_amt) as total_claimed_amt,
    sum(approved_amt) as total_approved_amt,
    sum(claim_gap) as total_claim_gap,
    round(100 * count(*) / (select count(*) from vw_claim_analysis), 2) as claim_percentage
from vw_claim_analysis
group by claim_status;



-- Rejected claims by insurer
select 
	insurer,
    count(*) as rejected_claims,
	sum(claimed_amt) as total_rejected_amt,
    sum(claim_gap) as potential_recovery_amt
from vw_claim_analysis
where claim_status = 'REJECTED'
group by insurer
order by rejected_claims desc;



-- Insurer-wise claim rejection percentage
select 
	insurer,
    count(*) as total_claims,
    sum(case when claim_status = 'REJECTED' then 1 else 0 end) as total_rejected_claims,
    round(100 * sum(case when claim_status = 'REJECTED' then 1 else 0 end) / count(claim_id), 2) as rejection_percentage
from vw_claim_analysis
group by insurer
order by rejection_percentage desc;



-- Short-paid claims by insurer
select 
	insurer,
    count(*) as short_paid_claims,
	sum(claimed_amt) as total_claimed_amt,
    sum(approved_amt) as total_approved_amt,
    sum(claim_gap) as total_short_paid_amount
from vw_claim_analysis
where claim_status = 'PARTIALLY APPROVED'
group by insurer
order by short_paid_claims desc;



-- Rejection reasons by insurer
select 
	insurer,
    coalesce(reason, 'Reson not Specified') as rejection_reason,
    count(*) as rejected_claims,
	sum(claimed_amt) as total_rejected_amt,
    sum(claim_gap) as potential_recovery_amt
from vw_claim_analysis
where claim_status = 'REJECTED'
group by insurer, coalesce(reason, 'Reson not Specified')
order by rejected_claims desc;



-- Most common rejection reasons
select 
    coalesce(reason, 'Reson not Specified') as rejection_reason,
    count(*) as rejected_claims,
	sum(claimed_amt) as total_rejected_amt,
    sum(claim_gap) as potential_recovery_amt,
    round(100*count(*) / (select count(*) from vw_claim_analysis where claim_status = 'REJECTED'), 2) as rejection_percentage
from vw_claim_analysis
where claim_status = 'REJECTED'
group by coalesce(reason, 'Reson not Specified')
order by rejected_claims desc;



-- Overall revenue leakage summary
select 
	count(*) as total_claims,
    sum(claimed_amt) as total_claimed_amt,
    sum(approved_amt) as total_approved_amt,
    sum(case when claim_status = 'PARTIALLY APPROVED' then claim_gap else 0 end) as short_paid_amt,
    sum(case when claim_status = 'REJECTED' then claim_gap else 0 end) as rejected_amt,
    sum(case when claim_status in ('REJECTED','PARTIALLY APPROVED') then claim_gap else 0 end) as potential_recovery_amt
from vw_claim_analysis;



-- Monthly revenue leakage trend
select 
	date_format(submitted_date, '%Y-%m') as claim_month,
	count(*) as total_claims,
    sum(claimed_amt) as total_claimed_amt,
    sum(approved_amt) as total_approved_amt,
    sum(case when claim_status = 'PARTIALLY APPROVED' then claim_gap else 0 end) as short_paid_amt,
    sum(case when claim_status = 'REJECTED' then claim_gap else 0 end) as rejected_amt,
    sum(case when claim_status in ('REJECTED','PARTIALLY APPROVED') then claim_gap else 0 end) as potential_recovery_amt
from vw_claim_analysis
group by date_format(submitted_date, '%Y-%m')
order by claim_month;



-- Average settlement time by insurer
select
	insurer,
    count(*) as settled_claims,
    round(avg(settlement_days),2) as average_settlement_days,
    min(settlement_days) as min_settlement_days,
    max(settlement_days) as max_settlement_days
from vw_claim_analysis
where settled_date is not null and submitted_date is not null
group by insurer;



-- Settlement time categories
select 
	case 
		when settlement_days <= 7 then '00-07 days'
        when settlement_days <= 15 then '08-15 days'
        when settlement_days <= 30 then '16-30 days'
        when settlement_days <= 60 then '30-60 days'
        else 'Above 60 days'
	end as settlement_category,
    count(*) as total_claims,
    round(avg(settlement_days),2) as average_settlement_days
from vw_claim_analysis
where settled_date is not null and submitted_date is not null
group by settlement_category 
order by settlement_category;



-- Monthly insurer performance
select 
	insurer,
	date_format(submitted_date, '%Y-%m') as claim_month,
	count(*) as total_claims,
    sum(claimed_amt) as total_claimed_amt,
    sum(approved_amt) as total_approved_amt,
    sum(case when claim_status = 'PARTIALLY APPROVED' then claim_gap else 0 end) as short_paid_amt,
    sum(case when claim_status = 'REJECTED' then claim_gap else 0 end) as rejected_amt,
    sum(case when claim_status in ('REJECTED','PARTIALLY APPROVED') then claim_gap else 0 end) as potential_recovery_amt,
    round(avg(settlement_days),2) as average_settlement_days
from vw_claim_analysis
group by insurer, date_format(submitted_date, '%Y-%m')
order by insurer, claim_month;



-- Best and worst insurers by approval percentage
select 
	insurer,
	count(*) as total_claims,
    sum(claimed_amt) as total_claimed_amt,
    sum(approved_amt) as total_approved_amt,
    sum(claim_gap) as total_claim_gap,
    round(100*sum(approved_amt)/ sum(claimed_amt), 2) as approval_percentage
from vw_claim_analysis
group by insurer
order by approval_percentage desc;



-- Hospital-wise revenue leakage
select 
	hospital_id,
    hospital_name,
	count(*) as total_claims,
    sum(claimed_amt) as total_claimed_amt,
    sum(approved_amt) as total_approved_amt,
    round(100*sum(approved_amt)/ sum(claimed_amt), 2) as approval_percentage,
	sum(case when claim_status = 'PARTIALLY APPROVED' then claim_gap else 0 end) as short_paid_amt,
    sum(case when claim_status = 'REJECTED' then claim_gap else 0 end) as rejected_amt,
    sum(case when claim_status in ('REJECTED','PARTIALLY APPROVED') then claim_gap else 0 end) as potential_recovery_amt
from vw_claim_analysis
group by hospital_id,hospital_name
order by hospital_id,hospital_name;


-- Department-wise revenue leakage
select 
	dept_id,
    dept_name,
	count(*) as total_claims,
    sum(claimed_amt) as total_claimed_amt,
    sum(approved_amt) as total_approved_amt,
    round(100*sum(approved_amt)/ sum(claimed_amt), 2) as approval_percentage,
	sum(case when claim_status = 'PARTIALLY APPROVED' then claim_gap else 0 end) as short_paid_amt,
    sum(case when claim_status = 'REJECTED' then claim_gap else 0 end) as rejected_amt,
    sum(case when claim_status in ('REJECTED','PARTIALLY APPROVED') then claim_gap else 0 end) as potential_recovery_amt
from vw_claim_analysis
group by dept_id,dept_name
order by dept_id,dept_name;



-- Top 10 hospital-department combinations by leakage
select 
	hospital_id,
    hospital_name,
	dept_id,
    dept_name,
	count(*) as total_claims,
    sum(claimed_amt) as total_claimed_amt,
    sum(approved_amt) as total_approved_amt,
    round(100*sum(approved_amt)/ sum(claimed_amt), 2) as approval_percentage,
	sum(case when claim_status = 'PARTIALLY APPROVED' then claim_gap else 0 end) as short_paid_amt,
    sum(case when claim_status = 'REJECTED' then claim_gap else 0 end) as rejected_amt,
    sum(case when claim_status in ('REJECTED','PARTIALLY APPROVED') then claim_gap else 0 end) as potential_recovery_amt
from vw_claim_analysis
group by hospital_id,hospital_name, dept_id,dept_name
order by potential_recovery_amt desc limit 10;



