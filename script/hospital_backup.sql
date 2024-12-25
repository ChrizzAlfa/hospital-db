-- creating the database
create database hospital;
use hospital;


-- creating the rooms table
drop table if exists room;
create table room (
    room_id int primary key not null auto_increment,
    status enum('available', 'occupied') default 'available'
);

-- creating the doctors table
drop table if exists doctor;
create table doctor (
    doctor_id int primary key not null auto_increment,
    name varchar(255) not null,   
    specialization varchar(255) not null
);

-- creating the patients table
drop table if exists patient;
create table patient (
    patient_id int primary key not null auto_increment,
    room_id int,
    name varchar(255) not null,
    email varchar(255) not null,
    gender enum('male', 'female', 'other') not null,
    status enum('admitted', 'discharged') default 'discharged',
    birthday date,
    constraint fk_room
        foreign key (room_id) references room(room_id)
        on delete cascade
);

-- creating the appointments table
drop table if exists appointment;
create table appointment (
    appointment_id int primary key auto_increment,
    patient_id int not null,
    doctor_id int not null,
    appointment_date date,
    appointment_time time,
    constraint fk_doctor
    	foreign key (doctor_id) references doctor(doctor_id)
    	on delete restrict,
    constraint fk_patient
    	foreign key (patient_id) references patient(patient_id)
        on delete restrict
);

-- creating the prescriptions table
drop table if exists prescription;
create table prescription (
    prescription_id int primary key not null auto_increment,
    prescription_date date,
    medication varchar(255) not null
);

-- creating the checkups table
drop table if exists checkup;
create table checkup (
    checkup_id int primary key not null auto_increment,
    checkup_date date,
    checkup_type varchar(255) not null,
    status enum('processing', 'finished') default 'processing'
);

-- creating the records table
drop table if exists record;
create table record (
    record_id int primary key auto_increment,
    checkup_id int,
    prescription_id int,
    patient_id int not null,
    doctor_id int not null,
    record_date date,
    constraint fk_checkup
    	foreign key (checkup_id) references checkup(checkup_id)
        on delete cascade,
   	constraint fk_prescription
    	foreign key (prescription_id) references prescription(prescription_id)
        on delete cascade,
	constraint fk_patient_record
    	foreign key (patient_id) references patient(patient_id)
        on delete cascade,
    constraint fk_doctor_record
    	foreign key (doctor_id) references doctor(doctor_id)
        on delete cascade
);


-- creating the stored procedure for inserting a new doctor
delimiter //
create procedure insert_doctor (
    in p_name varchar(255),
    in p_specialization varchar(255)
)
begin
    start transaction;
    insert into doctor (
        name, specialization
    )
    VALUES (
        p_name, p_specialization
    );
    commit;
end //
delimiter ;

-- creating the stored procedure for inserting a patient
delimiter //
create procedure insert_patient (
    in p_name varchar(255),
    in p_email varchar(255),
    in p_gender enum('male', 'female', 'other'),
    in p_birthday date,
    out p_patient_id int
)
begin
    declare existing_patient_id int default null;
    select patient_id into existing_patient_id
    from patient
    where email = p_email;
    
    if existing_patient_id is not null then
        set p_patient_id = existing_patient_id;
    else
        start transaction;
        insert into patient (name, email, gender, birthday)
        values (p_name, p_email, p_gender, p_birthday);
        set p_patient_id = last_insert_id();
        commit;
    end if;
end //
delimiter ;

-- creating the stored procedure for inserting a new appointment
delimiter //
create procedure insert_appointment (
    in p_patient_id int,
    in p_doctor_id int,
    in p_appointment_date date,
    in p_appointment_time time
)
begin
    declare doctor_booked int;
    declare duplicate_appointment int;

    select count(*) into doctor_booked
    from appointment
    where doctor_id = p_doctor_id
      and appointment_date = p_appointment_date
      and appointment_time = p_appointment_time;
    if doctor_booked > 0 then
        signal sqlstate '45000' set message_text = 'Doctor is already booked for this time slot';
    end if;

    select count(*) into duplicate_appointment
    from appointment
    where patient_id = p_patient_id
      and doctor_id = p_doctor_id;
    if duplicate_appointment > 0 then
        signal sqlstate '45000' set message_text = 'Patient already has an appointment with this doctor';
    end if;	

    start transaction;
    insert into appointment (
        patient_id, doctor_id, appointment_date, appointment_time
    ) values (
        p_patient_id, p_doctor_id, p_appointment_date, p_appointment_time
    );
    commit;
end //
delimiter ;

-- creating the stored procedure for inserting a new checkup
delimiter //
create procedure insert_checkup(
    in p_checkup_date date,
    in p_checkup_type varchar(255)
)
begin
    start transaction;
    insert into checkup (
        checkup_date, checkup_type
    )
    values (
        p_checkup_date, p_checkup_type
    );
    commit;
end //
delimiter ;

-- creating the stored procedure for inserting a new prescription
delimiter //
create procedure insert_prescription(
    in p_prescription_date date,
    in p_medication varchar(255)
)
begin
    start transaction;
    insert into prescription (
        prescription_date, medication
    )
    values (
        p_prescription_date, p_medication
    );
    commit;
end //
delimiter ;

-- creating the stored procedure for inserting a new record
delimiter //
create procedure insert_record(
    in p_checkup_id int,
    in p_prescription_id int,
    in p_patient_id int,
    in p_doctor_id int,
    in p_record_date date
)
begin
    start transaction;
    insert into record (
        checkup_id, prescription_id, patient_id, doctor_id, record_date
    )
    values (
        p_checkup_id, p_prescription_id, p_patient_id, p_doctor_id, p_record_date
    );
    commit;
end //
delimiter ;

-- creating the stored procedure for updating appointment date and time
delimiter //
create procedure update_appointment (
    in p_appointment_id int,
    in p_new_date date,
    in p_new_time time
)
begin
    declare doctor_booked int;
    declare current_doctor_id int;
    declare current_patient_id int;
    declare duplicate_appointment int;

    select doctor_id, patient_id into current_doctor_id, current_patient_id
    from appointment
    where appointment_id = p_appointment_id;

    select count(*) into doctor_booked
    from appointment
    where doctor_id = current_doctor_id
      and appointment_date = p_new_date
      and appointment_time = p_new_time
      and appointment_id <> p_appointment_id;

    if doctor_booked > 0 then
        signal sqlstate '45000' set message_text = 'Doctor is already booked for this time slot';
    end if;

    select count(*) into duplicate_appointment
    from appointment
    where patient_id = current_patient_id
      and doctor_id = current_doctor_id
      and appointment_id <> p_appointment_id;

    if duplicate_appointment > 0 then
        signal sqlstate '45000' set message_text = 'Patient already has an appointment with this doctor';
    end if;

    start transaction;
    update appointment
    set appointment_date = ifnull(p_new_date, appointment_date),
        appointment_time = ifnull(p_new_time, appointment_time)
    where appointment_id = p_appointment_id;
    commit;
end //
delimiter ;

-- creating the stored procedure for updating checkup status
delimiter //
create procedure update_checkup_status (
    in p_checkup_id int,
    in p_status enum('processing', 'finished')
)
begin
    start transaction;
    update checkup
    set status = p_status
    where checkup_id = p_checkup_id;
    commit;
end //
delimiter ;

-- creating the stored procedure for deleting an appointment
delimiter //
create procedure delete_appointment(
    in p_appointment_id int
)
begin
    declare appointment_exists int;

    -- Check if the appointment exists
    select count(*) into appointment_exists
    from appointment
    where appointment_id = p_appointment_id;

    if appointment_exists = 0 then
        signal sqlstate '45000' set message_text = 'Appointment does not exist';
    else
        -- Begin the transaction to delete the appointment
        start transaction;
        delete from appointment
        where appointment_id = p_appointment_id;
        commit;
    end if;
end //
delimiter ;

-- creating the stored procedure for admitting a patient
delimiter //
create procedure admit_patient(
	in p_patient_id int,
	in p_room_id int
)
begin
	start transaction;
	update patient
	set status = 'admitted', room_id = p_room_id
	where patient_id = p_patient_id;
	commit;
end //
delimiter ;

-- creating the stored procedure for discharging a patient
delimiter //
create procedure discharge_patient(
	in p_patient_id int
)
begin
	start transaction;
	update patient
	set status = 'discharged', room_id = null
	where patient_id = p_patient_id;
	commit;
end //
delimiter ;

-- creating the trigger to update room status
delimiter $$
create trigger update_room_status
before update on patient
for each row
begin
    if new.status <> old.status then
        if new.status = 'admitted' then
            update room
            set status = 'occupied'
            where room_id = new.room_id;
        elseif new.status = 'discharged' then
            update room
            set status = 'available'
            where room_id = old.room_id;
           	set new.room_id = null;
        end if;
    end if;
end $$
delimiter ;

-- creating the function to see all the available rooms
delimiter $$
create function get_available_room()
returns varchar(255)
deterministic
begin
    declare available_room varchar(255);
    select group_concat(room_id) into available_room
    from room
    where status = 'available';
    return available_room;
end $$
delimiter ;

-- Create a view for all records
CREATE VIEW detailed_records AS
SELECT 
    r.record_id AS RecordID,
    r.created_at AS CreatedAt,
    r.updated_at AS UpdatedAt,
    p.name AS PatientName,
    p.email AS PatientEmail,
    p.gender AS PatientGender,
    p.status AS PatientStatus,
    p.birthday AS PatientBirthday,
    d.name AS DoctorName,
    d.specialization AS DoctorSpecialization,
    c.checkup_date AS CheckupDate,
    c.checkup_type AS CheckupType,
    c.status AS CheckupStatus,
    c.result AS CheckupResult,
    pr.medication AS PrescribedMedication
FROM 
    record r
LEFT JOIN patient p ON r.patient_id = p.patient_id
LEFT JOIN doctor d ON r.doctor_id = d.doctor_id
LEFT JOIN checkup c ON r.checkup_id = c.checkup_id
LEFT JOIN prescription pr ON r.prescription_id = pr.prescription_id
ORDER BY r.created_at DESC;

-- testing use case
insert into room() values();

call insert_doctor('Dr. Emily Davis', 'Pediatrics');

call insert_patient('Chris', 'alfa@gmail.com', 'male', '2005-06-14', @patient_id);
call insert_patient('Alfa', 'alfa@gmail.com', 'male', '2005-06-14', @patient_id);
call insert_patient('Jane', 'jane@gmail.com', 'other', '2005-07-14', @patient_id);

call insert_appointment(1, 1, '2024-10-25', '10:00:00');
call insert_appointment(2, 2, '2024-10-25', '11:30:00');

call update_appointment(3, '2024-10-25', '10:10:00');
call update_appointment(2, '2024-10-25', '11:30:00');

call delete_appointment(3);

call insert_checkup('2024-10-25', 'Blood Test');

call insert_record(1, null, 1, 1, '2024-10-25');

call update_checkup_status(1, 'finished');

select get_available_room();

call admit_patient(1, 1);
call discharge_patient(1);
