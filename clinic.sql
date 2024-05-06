DROP DATABASE IF EXISTS clinic;
CREATE DATABASE clinic;
USE clinic;

CREATE TABLE procedures (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    description VARCHAR(255) NOT NULL,
    price DOUBLE NOT NULL
);

CREATE TABLE doctors (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    speciality VARCHAR(255) NOT NULL
);

CREATE TABLE patients (
    id INT AUTO_INCREMENT PRIMARY KEY,
    firstName VARCHAR(255) NOT NULL,
    lastName VARCHAR(255) NOT NULL,
    email VARCHAR(255) NOT NULL,
    phone VARCHAR(13) NOT NULL,
    egn VARCHAR(10) NOT NULL
);

CREATE TABLE manipulations (
    id INT AUTO_INCREMENT PRIMARY KEY,
    operatingRoom INT NOT NULL,
    operatingDate DATE NOT NULL,
    operatingTime TIME NOT NULL,
    procedure_id INT NOT NULL,
    CONSTRAINT FOREIGN KEY (procedure_id) REFERENCES procedures(id),
    doctor_id INT NOT NULL,
    CONSTRAINT FOREIGN KEY (doctor_id) REFERENCES doctors(id),
    patient_id INT NOT NULL,
    CONSTRAINT FOREIGN KEY (patient_id) REFERENCES patients(id)
);

CREATE TABLE salaryPayments (
    id INT AUTO_INCREMENT PRIMARY KEY,
    dateOfPayment VARCHAR(255) NOT NULL,
    monthOfPayment INT NOT NULL,
    yearOfPayment INT NOT NULL,
    salaryAmount DOUBLE NOT NULL,
    monthlyBonus DOUBLE NOT NULL,
    doctor_id INT NOT NULL,
    CONSTRAINT FOREIGN KEY (doctor_id) REFERENCES doctors(id)
);

INSERT INTO procedures (name, description, price) VALUES
('Dental Checkup', 'Routine dental checkup', 50.00),
('X-Ray', 'Diagnostic imaging technique', 80.00),
('MRI Scan', 'Magnetic Resonance Imaging scan', 200.00),
('Blood Test', 'Routine blood test', 30.00),
('Physical Examination', 'General health checkup', 100.00),
('Ultrasound', 'Imaging technique using sound waves', 150.00);

INSERT INTO doctors (name, speciality) VALUES
('Dr. Smith', 'Dentist'),
('Dr. Johnson', 'Radiologist'),
('Dr. Lee', 'Neurologist'),
('Dr. Garcia', 'General Practitioner'),
('Dr. Kim', 'Cardiologist'),
('Dr. Patel', 'Pediatrician');

INSERT INTO patients (firstName, lastName, email, phone, egn) VALUES
('John', 'Doe', 'john.doe@example.com', '1234567890', '1234567890'),
('Jane', 'Smith', 'jane.smith@example.com', '0987654321', '0987654321'),
('Michael', 'Johnson', 'michael.j@example.com', '1122334455', '1122334455'),
('Emily', 'Davis', 'emily.d@example.com', '9988776655', '9988776655');

INSERT INTO manipulations (operatingRoom, operatingDate, operatingTime, procedure_id, doctor_id, patient_id) VALUES
(101, '2024-05-03', '09:00:00', 1, 1, 1),
(102, '2024-05-04', '10:30:00', 2, 2, 2),
(103, '2024-05-05', '13:00:00', 3, 3, 1),
(104, '2024-05-06', '11:00:00', 1, 4, 3),
(105, '2024-05-07', '14:30:00', 2, 5, 4),
(106, '2024-05-08', '16:00:00', 3, 6, 2);

INSERT INTO salaryPayments (dateOfPayment, monthOfPayment, yearOfPayment, salaryAmount, monthlyBonus, doctor_id) VALUES
('2024-05-01', 5, '2024', 5000.00, 500.00, 1),
('2024-05-01', 5, '2024', 6000.00, 600.00, 2),
('2024-05-01', 5, '2024', 5500.00, 550.00, 3),
('2024-05-01', 5, '2024', 6200.00, 620.00, 4);

CREATE VIEW dailyManipulations
AS 
SELECT p.firstName, p.lastName, proc.name AS procedureName, m.operatingTime, m.operatingDate, d.name AS doctorName
FROM manipulations m
JOIN patients p ON m.patient_id = p.id
JOIN procedures proc ON m.procedure_id = proc.id
JOIN doctors d ON m.doctor_id = d.id
JOIN salaryPayments s ON d.id = s.doctor_id
WHERE m.operatingDate = CURDATE()
ORDER BY m.operatingTime, d.name;

DELIMITER //
CREATE PROCEDURE monthlyBonusPayment (IN year INT, IN month INT) 
BEGIN 
    DECLARE done INT DEFAULT 0;
    DECLARE doctorID INT;
    DECLARE paymentSuccess BIT;
    DECLARE surgeryCount INT;
    DECLARE bonusPerSurgery INT DEFAULT 1000;
    
    -- CALL monthSalaryPayment(year, month, paymentSuccess);
    
    -- IF paymentSuccess = 1 THEN
        DECLARE doctorCursor CURSOR FOR
        SELECT d.id, COUNT(m.id)
        FROM doctors d
        JOIN manipulations m ON d.id = m.doctor_id
        WHERE MONTH(m.operatingDate) = month AND YEAR(m.operatingDate) = year
        GROUP BY d.id;
        
        DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;
        
        START TRANSACTION;
        
        OPEN doctorCursor;
        
        readLoop: LOOP
            FETCH doctorCursor INTO doctorID, surgeryCount;
	    IF done THEN 
		LEAVE readLoop;
	    END IF;
            
	    UPDATE salaryPayments
            SET monthlyBonus = monthlyBonus + (surgeryCount * bonusPerSurgery)
	    WHERE doctor_id = doctorID
            AND monthOfPayment = month
            AND yearOfPayment = year;
	END LOOP;
        
        CLOSE doctorCursor;
        COMMIT;
 
    -- ELSE
	    -- SELECT 'PAYMENT FAILED';
	-- END IF;
    
END//
DELIMITER ;

CALL monthlyBonusPayment(2024, 5); 

CREATE TABLE SalaryPaymentsLog (
    id INT AUTO_INCREMENT PRIMARY KEY,
    doctor_idOld INT,
    doctor_idNew INT,
    monthOfPaymentOld INT,
    monthOfPaymentNew INT,
    yearOfPaymentOld INT,
    yearOfPaymentNew INT,
    salaryAmountOld DOUBLE,
    salaryAmountNew DOUBLE,
    monthlyBonusOld DOUBLE,
    monthlyBonusNew DOUBLE,
    dateOfPaymentOld DATE,
    dateOfPaymentNew DATE,
    dateOfLog DATETIME 
);


DELIMITER //
CREATE TRIGGER after_salary_update
AFTER UPDATE ON salaryPayments
FOR EACH ROW 
BEGIN
    INSERT INTO salaryPaymentsLog (doctor_idOld, doctor_idNew, monthOfPaymentOld, monthOfPaymentNew, 
                                  yearOfPaymentOld, yearOfPaymentNew, salaryAmountOld, salaryAmountNew, 
                                  monthlyBonusOld, monthlyBonusNew, dateOfPaymentOld, dateOfPaymentNew, dateOfLog) 
	VALUES (
        OLD.doctor_id,
        CASE NEW.doctor_id WHEN OLD.doctor_id THEN NULL ELSE NEW.doctor_id END,
        OLD.monthOfPayment,
        CASE NEW.monthOfPayment WHEN OLD.monthOfPayment THEN NULL ELSE NEW.monthOfPayment END,
        OLD.yearOfPayment,
        CASE new.yearOfPayment WHEN OLD.yearOfPayment THEN NULL ELSE NEW.yearOfPayment END,
        OLD.salaryAmount,
        CASE NEW.salaryAmount WHEN  OLD.salaryAmount THEN NULL ELSE NEW.salaryAmount END,
        OLD.monthlyBonus,
        CASE NEW.monthlyBonus WHEN OLD.monthlyBonus THEN NULL ELSE NEW.monthlyBonus END,
        OLD.dateOfPayment,
        CASE NEW.dateOfPayment WHEN OLD.dateOfPayment THEN NULL ELSE NEW.dateOfPayment END,
        NOW()
        );
END;
//    
DELIMITER ;
                                  
UPDATE salaryPayments
SET doctor_id = 1, monthOfPayment = 5, yearOfPayment = 2024, salaryAmount = 7000, monthlyBonus = 25
WHERE id = 1;

SELECT * FROM salaryPaymentsLog;                                  


