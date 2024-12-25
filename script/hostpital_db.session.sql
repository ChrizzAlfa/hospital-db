-- Create database
DROP DATABASE IF EXISTS hospital;
CREATE DATABASE hospital;
USE hospital;

-- Create tables
CREATE TABLE room (
    room_id INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    status ENUM('available', 'occupied') DEFAULT 'available'
);

CREATE TABLE doctor (
    doctor_id INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(255) NOT NULL,
    specialization VARCHAR(255) NOT NULL
);

CREATE TABLE patient (
    patient_id INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    room_id INT UNSIGNED,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE,
    gender ENUM('male', 'female', 'other') NOT NULL,
    status ENUM('admitted', 'discharged') DEFAULT 'discharged',
    birthday DATE,
    FOREIGN KEY (room_id) REFERENCES room(room_id) ON DELETE CASCADE
);

CREATE TABLE appointment (
    appointment_id INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    patient_id INT UNSIGNED NOT NULL,
    doctor_id INT UNSIGNED NOT NULL,
    appointment_date DATE,
    appointment_start_time TIME,
    appointment_end_time TIME,
    FOREIGN KEY (doctor_id) REFERENCES doctor(doctor_id) ON DELETE CASCADE,
    FOREIGN KEY (patient_id) REFERENCES patient(patient_id) ON DELETE CASCADE
);

CREATE TABLE prescription (
    prescription_id INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    medication VARCHAR(255) NOT NULL
);

CREATE TABLE checkup (
    checkup_id INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    checkup_date DATE,
    checkup_type VARCHAR(255) NOT NULL,
    status ENUM('processing', 'finished') DEFAULT 'processing',
    result VARCHAR(255)
);

CREATE TABLE record (
    record_id INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    checkup_id INT UNSIGNED,
    prescription_id INT UNSIGNED,
    patient_id INT UNSIGNED NOT NULL,
    doctor_id INT UNSIGNED NOT NULL,
    created_at DATETIME DEFAULT NOW(),
    updated_at DATETIME DEFAULT NOW(),
    FOREIGN KEY (checkup_id) REFERENCES checkup(checkup_id) ON DELETE CASCADE,
    FOREIGN KEY (prescription_id) REFERENCES prescription(prescription_id) ON DELETE CASCADE,
    FOREIGN KEY (patient_id) REFERENCES patient(patient_id) ON DELETE CASCADE,
    FOREIGN KEY (doctor_id) REFERENCES doctor(doctor_id) ON DELETE CASCADE
);

-- Create Views
CREATE VIEW vw_AvailableRooms AS
SELECT room_id
FROM room
WHERE status = 'available';

CREATE VIEW vw_AdmittedPatients AS
SELECT patient_id, room_id
FROM patient
WHERE status = 'admitted';

CREATE VIEW vw_AllPatients AS
SELECT patient_id, room_id, status
FROM patient;

-- Create functions
CREATE FUNCTION fn_AddMinutes(start_time TIME) RETURNS TIME
DETERMINISTIC 
BEGIN
    RETURN ADDTIME(start_time, '00:15:00');
END;

-- Create procedures
CREATE PROCEDURE sp_InsertDoctor (
    IN _name VARCHAR(255),
    IN _specialization VARCHAR(255)
)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;
    INSERT INTO doctor (name, specialization)
    VALUES (_name, _specialization);
    COMMIT;
END;

CREATE PROCEDURE sp_InsertPatient (
    IN _name VARCHAR(255),
    IN _email VARCHAR(255),
    IN _gender ENUM('male', 'female', 'other'),
    IN _birthday DATE
)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    DECLARE CONTINUE HANDLER FOR SQLSTATE '23000'
    BEGIN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'This email has already been registered';
    END;

    START TRANSACTION;
    INSERT INTO patient (
        name,
        email,
        gender,
        birthday
    ) VALUES (
        _name,
        _email,
        _gender,
        _birthday
    );
    COMMIT;
END;

CREATE PROCEDURE sp_ScheduleAppointment (
    IN _email VARCHAR(255),
    IN _doctor_id INT,
    IN _appointment_date DATE,
    IN _appointment_start_time TIME
)
BEGIN
    DECLARE exist_patient_id INT;
    DECLARE end_time TIME;
    DECLARE current_date_time DATETIME;


    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    SELECT patient_id
    FROM patient
    WHERE email = _email INTO exist_patient_id;

    SET end_time = fn_AddMinutes(_appointment_start_time);
    SET current_date_time = NOW();

    IF exist_patient_id IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'This email has not been registered';
    ELSEIF TIMESTAMP(_appointment_date, _appointment_start_time) < current_date_time THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Appointment date and time must be in the future';
    ELSEIF EXISTS (
        SELECT 1
        FROM appointment
        WHERE doctor_id = _doctor_id
            AND appointment_date = _appointment_date
            AND (
                (_appointment_start_time BETWEEN appointment_start_time AND appointment_end_time)
                OR (end_time BETWEEN appointment_start_time AND appointment_end_time)
                OR (appointment_start_time BETWEEN _appointment_start_time AND end_time)
                OR (appointment_end_time BETWEEN _appointment_start_time AND end_time)
            )
    ) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'This doctor has already been booked';
    ELSEIF EXISTS (
        SELECT 1
        FROM appointment
        WHERE patient_id = exist_patient_id
            AND appointment_date = _appointment_date
    ) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Cannot book more than one appointment on the same day';
    ELSE
        START TRANSACTION;
        INSERT INTO appointment (
            patient_id,
            doctor_id,
            appointment_date,
            appointment_start_time,
            appointment_end_time
        ) VALUES (
            exist_patient_id,
            _doctor_id,
            _appointment_date,
            _appointment_start_time,
            end_time
        );
        COMMIT;
    END IF;
END;

CREATE PROCEDURE sp_ListDoctors ()
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;
    SELECT doctor_id, name, specialization
    FROM doctor;
    COMMIT;
END;

CREATE PROCEDURE sp_GetDoctorAppointments (
    IN _doctor_id INT
)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;
    SELECT appointment_date, appointment_start_time, appointment_end_time
    FROM appointment
    WHERE doctor_id = _doctor_id;
    COMMIT;
END;


CREATE PROCEDURE sp_InsertRecord (
    IN _checkup_id INT,
    IN _prescription_id INT,
    IN _patient_id INT,
    IN _doctor_id INT
)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;
    IF NOT EXISTS (
        SELECT 1
        FROM patient
        WHERE patient_id = _patient_id
    ) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Invalid patient ID';
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM doctor
        WHERE doctor_id = _doctor_id
    ) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Invalid doctor ID';
    END IF;

    IF _checkup_id IS NOT NULL AND NOT EXISTS (
        SELECT 1
        FROM checkup
        WHERE checkup_id = _checkup_id
    ) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Invalid checkup ID';
    END IF;

    IF _prescription_id IS NOT NULL AND NOT EXISTS (
        SELECT 1
        FROM prescription
        WHERE prescription_id = _prescription_id
    ) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Invalid prescription ID';
    END IF;

    INSERT INTO record (
        checkup_id,
        prescription_id,
        patient_id,
        doctor_id,
        created_at,
        updated_at
    ) VALUES (
        _checkup_id,
        _prescription_id,
        _patient_id,
        _doctor_id,
        NOW(),
        NOW()
    );
    COMMIT;
END;

CREATE PROCEDURE sp_InsertCheckup (
    IN _record_id INT,
    IN _checkup_date DATE,
    IN _checkup_type VARCHAR(255),
    IN _patient_id INT,
    IN _doctor_id INT
)
BEGIN
    DECLARE _new_checkup_id INT;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;
    IF _record_id IS NOT NULL THEN
        IF EXISTS (SELECT 1 FROM record WHERE record_id = _record_id) THEN
            INSERT INTO checkup (
                checkup_date,
                checkup_type
            ) VALUES (
                _checkup_date,
                _checkup_type
            );
            SET _new_checkup_id = LAST_INSERT_ID();
            UPDATE record
            SET checkup_id = _new_checkup_id,
                updated_at = NOW()
            WHERE record_id = _record_id;
        ELSE
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Record not found';
        END IF;
    ELSEIF _patient_id IS NOT NULL AND _doctor_id IS NOT NULL THEN
        INSERT INTO checkup (
            checkup_date,
            checkup_type
        ) VALUES (
            _checkup_date,
            _checkup_type
        );
        SET _new_checkup_id = LAST_INSERT_ID();
        CALL sp_CreateRecord(
            _new_checkup_id,
            NULL,
            _patient_id,
            _doctor_id
        );
    ELSE
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Either record_id or both patient_id and doctor_id must be provided';
    END IF;
    COMMIT;
END;

CREATE PROCEDURE sp_UpdateCheckup (
    IN _checkup_id INT,
    IN _result VARCHAR(255)
)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;
    UPDATE checkup
    SET result = IFNULL(_result, result),
        status = 'finished'
    WHERE checkup_id = _checkup_id;

    IF ROW_COUNT() = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Checkup not found or no changes made';
    END IF;
    COMMIT;
END;

CREATE PROCEDURE sp_InsertPrescription (
    IN _record_id INT,
    IN _medication VARCHAR(255),
    IN _patient_id INT,
    IN _doctor_id INT
)
BEGIN
    DECLARE _new_prescription_id INT;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    IF _record_id IS NOT NULL THEN
        IF EXISTS (SELECT 1 FROM record WHERE record_id = _record_id) THEN
            IF EXISTS (SELECT 1 FROM record WHERE record_id = _record_id AND prescription_id IS NOT NULL) THEN
                SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Record already has a prescription';
            ELSE
                INSERT INTO prescription (medication)
                VALUES (_medication);
                SET _new_prescription_id = LAST_INSERT_ID();

                UPDATE record
                SET prescription_id = _new_prescription_id,
                    updated_at = NOW()
                WHERE record_id = _record_id;
            END IF;
        ELSE
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Record not found';
        END IF;
    ELSE
        INSERT INTO prescription (medication)
        VALUES (_medication);
        SET _new_prescription_id = LAST_INSERT_ID();

        CALL sp_CreateRecord(
            NULL,
            _new_prescription_id,
            _patient_id,
            _doctor_id
        );
    END IF;

    COMMIT;
END;

CREATE PROCEDURE sp_AdmitPatient (
    IN _patient_id INT,
    IN _room_id INT
)
BEGIN
    START TRANSACTION;
    IF (SELECT COUNT(*) FROM vw_AdmittedPatients WHERE room_id = _room_id) > 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Room is already occupied';
    ELSEIF (SELECT COUNT(*) FROM vw_AdmittedPatients WHERE patient_id = _patient_id) > 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Patient is already admitted';
    ELSEIF (SELECT COUNT(*) FROM vw_AvailableRooms WHERE room_id = _room_id) = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Room is not available';
    ELSE
        UPDATE patient
        SET status = 'admitted',
            room_id = _room_id
        WHERE patient_id = _patient_id;
    END IF;
    COMMIT;
END;

CREATE PROCEDURE sp_DischargePatient (
    IN _patient_id INT
)
BEGIN
    START TRANSACTION;
    IF (SELECT COUNT(*) FROM vw_AllPatients WHERE patient_id = _patient_id AND status = 'discharged') > 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Patient is already discharged';
    ELSE
        UPDATE patient
        SET status = 'discharged',
            room_id = NULL
        WHERE patient_id = _patient_id;
    END IF;
    COMMIT;
END;

CREATE PROCEDURE sp_ListRecords ()
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;
    SELECT 
        record_id,
        checkup_id,
        prescription_id,
        patient_id,
        doctor_id
    FROM record;
    COMMIT;
END;

CREATE PROCEDURE sp_ListAllPatients()
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;
    SELECT patient_id FROM vw_AllPatients WHERE status = 'discharged';
    COMMIT;
END;

CREATE PROCEDURE sp_ListAvailableRooms ()
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;
    SELECT * FROM vw_AvailableRooms;
    COMMIT;
END;

CREATE PROCEDURE sp_ListAdmittedPatients()
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;
    SELECT * FROM vw_AdmittedPatients;
    COMMIT;
END;

-- Create triggers
CREATE TRIGGER tr_AfterCheckupUpdate
AFTER UPDATE ON checkup FOR EACH ROW 
BEGIN
    UPDATE record
    SET updated_at = NOW()
    WHERE checkup_id = NEW.checkup_id;
END;

CREATE TRIGGER tr_UpdateRoomStatus 
BEFORE UPDATE ON patient FOR EACH ROW 
BEGIN 
    IF NEW.status <> OLD.status THEN 
        IF NEW.status = 'admitted' THEN
            UPDATE room
            SET status = 'occupied'
            WHERE room_id = NEW.room_id;
        ELSEIF NEW.status = 'discharged' THEN
            UPDATE room
            SET status = 'available'
            WHERE room_id = OLD.room_id;
            SET NEW.room_id = NULL;
        END IF;
    END IF;
END;

CALL sp_AddDoctor('John Smith', 'Cardiology');
CALL sp_AddDoctor('Jane Doe', 'Neurosurgery');
CALL sp_AddDoctor('Bob Johnson', 'Pediatrics');
CALL sp_AddDoctor('Alice Brown', 'Oncology');
CALL sp_AddDoctor('Mike Davis', 'Dermatology');
CALL sp_AddDoctor('Emily Chen', 'Orthopedic Surgery');
CALL sp_AddDoctor('David Lee', 'Gastroenterology');
CALL sp_AddDoctor('Sarah Taylor', 'Urology');
CALL sp_AddDoctor('Kevin White', 'Endocrinology');
CALL sp_AddDoctor('Lisa Nguyen', 'Nephrology');

CALL sp_AddPatient('Olivia Martin', 'olivia.martin@example.com', 'female', '1995-08-25');
CALL sp_AddPatient('Logan Brown', 'logan.brown@example.com', 'male', '1980-01-01');
CALL sp_AddPatient('Ava Davis', 'ava.davis@example.com', 'female', '2000-06-15');
CALL sp_AddPatient('William White', 'william.white@example.com', 'other', '1992-11-20');

INSERT INTO room (status) VALUES (DEFAULT);

create function get_available_room()
returns varchar(255)
deterministic
begin
    declare available_room varchar(255);
    select group_concat(room_id) into available_room
    from room
    where status = 'available';
    return available_room;
end