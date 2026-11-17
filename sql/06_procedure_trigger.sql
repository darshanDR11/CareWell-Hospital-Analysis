-- 1. Stored procedure: sp_ward_alert
-- Purpose: Find wards in a selected hospital whose occupancy exceeds the 90% alert threshold on a given date.

delimiter //
create procedure sp_ward_alert(
	in p_hospital_id varchar(20),
    in p_snapshot_date date
)
begin
	select
		h.hospital_id,
        h.hospital_name,
        
        w.ward_id,
        w.ward_name,
        w.beds_total,
        
        bs.snapshot_date,
        bs.beds_total,
        bs.beds_occupied,
        bs.beds_blocked,
        round(100.0 * bs.beds_occupied / bs.beds_total, 2) as occupancy_Percentage
	from bed_day_snapshot as bs
    join hospitals as h on bs.hospital_id = h.hospital_id
    join wards as w on bs.ward_id = w.ward_id
    where 
		h.hospital_id = p_hospital_id 
		and bs.snapshot_date = p_snapshot_date
		and bs.beds_occupied / bs.beds_total > 0.9
	order by h.hospital_id, w.ward_id;
end //
delimiter ;

call sp_ward_alert('H01', '2025-09-10');






-- 2. Trigger: Prevent discharge before admission
-- Purpose: Prevent an admission record from being updated with a discharge timestamp earlier than its admission timestamp.

delimiter //
create trigger trg_validate_discharge_date
before update on admissions
for each row
begin
	if new.discharge_ts is not null and new.discharge_ts < new.admit_ts 
		then signal sqlstate '45000' 
			set message_text = 'Invalid Dishcharge Date : Discharge cannot be before admissions';
	end if;
end //
delimiter ;

-- invalid discharge_ts
update admissions 
set discharge_ts = date_sub(admit_ts, interval 1 day)
where admission_id = 'A0000001';










-- 3. Transactions to transfer patient from one ward to another
drop procedure if exists sp_transfer_patient;

delimiter //
create procedure sp_transfer_patient(
	in p_admission_id varchar(20),
    in p_new_ward_id varchar(20),
    in p_snapshot_date date
)
begin
	declare v_count int default 0;
    
    declare v_hospital_id varchar(20);
    declare v_old_ward_id varchar(20);
    
    declare v_old_occupied int;
    declare v_new_occupied int;
    declare v_new_blocked int;
	declare v_new_total int;
	
    declare exit handler for sqlexception
    begin 
		rollback;
        resignal;
	end;
    
    start transaction;
    
    select count(*) into v_count from admissions where admission_id = p_admission_id;
    
    if v_count = 0 
		then signal sqlstate '45000' set message_text = 'Admission not found.'; 
    end if;
    
    select hospital_id, ward_id, discharge_ts into v_hospital_id, v_old_ward_id, @discharge_check from admissions where admission_id = p_admission_id for update;
    
	-- if @discharge_check is not null 
 		-- then signal sqlstate '45000' set message_text = 'Cannot transfer a discharged patient.';
 	-- end if;
    
    if v_old_ward_id = p_new_ward_id 
		then signal sqlstate '45000' set message_text = 'Patient is already assigned to this ward.';
	end if;
    
    select count(*) into v_count from bed_day_snapshot where hospital_id = v_hospital_id and ward_id in (v_old_ward_id, p_new_ward_id) and snapshot_date = p_snapshot_date;
    
    if v_count <> 2 
		then signal sqlstate '45000' set message_text = 'Ward snapshot is missiong for selecetd date.';
	end if;
    
    select 
        beds_occupied into v_old_occupied 
    from bed_day_snapshot 
    where snapshot_date = p_snapshot_date and ward_id = v_old_ward_id and hospital_id = v_hospital_id;
    
    select 
        beds_occupied, beds_total, beds_blocked into v_new_occupied, v_new_total, v_new_blocked 
    from bed_day_snapshot 
    where snapshot_date = p_snapshot_date and ward_id = p_new_ward_id and hospital_id = v_hospital_id;
        
	if v_old_occupied <= 0 
		then signal sqlstate '45000' set message_text = 'Invalid ward count.';
	end if;
    
    if v_new_occupied + v_new_blocked > v_new_total
		then signal sqlstate '45000' set message_text = 'Destination ward has inconsisent ward capacity.';
	end if;
    
    if v_new_occupied + v_new_blocked  = v_new_total
		then signal sqlstate '45000' set message_text = 'Destination ward has no available bed.';
	end if;
    
	update bed_day_snapshot
    set beds_occupied = beds_occupied - 1
    where hospital_id = v_hospital_id and snapshot_date = p_snapshot_date and ward_id = v_old_ward_id;
    
    update bed_day_snapshot 
    set beds_occupied = beds_occupied + 1 
    where hospital_id = v_hospital_id and snapshot_date = p_snapshot_date and ward_id = p_new_ward_id;
    
    update admissions
    set ward_id = p_new_ward_id
    where admission_id = p_admission_id;
    
    commit;
end //
delimiter ;


select * from admissions where admission_id = 'A0000502';
select * from bed_day_snapshot where ward_id in ('H02-W09', 'H02-W05') and snapshot_date = '2024-10-03';

-- BEFORE
-- A0000502	P0085736	H02	D16	2024-10-02 05:28:33	2024-10-05 12:43:24	DR0182	PLANNED	A41	H02-W09
-- 2024-10-03	H02	H02-W05	21	10	0
-- 2024-10-03	H02	H02-W09	20	5	0

call sp_transfer_patient('A0000502', 'H02-W05', '2024-10-03');

-- AFTER
-- A0000502	P0085736	H02	D16	2024-10-02 05:28:33	2024-10-05 12:43:24	DR0182	PLANNED	A41	H02-W05
-- 2024-10-03	H02	H02-W05	21	11	0
-- 2024-10-03	H02	H02-W09	20	4	0







