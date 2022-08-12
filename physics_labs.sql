
CREATE DATABASE project;
USE project;

-- CREATE THE TABLES

CREATE TABLE experiments (
	experiment_id INTEGER PRIMARY KEY NOT NULL,
    experiment_name VARCHAR(50)
);

CREATE TABLE departments (
	department_id VARCHAR(3) PRIMARY KEY NOT NULL,
    department_name VARCHAR(50)
);

CREATE TABLE staff (
	staff_id INTEGER PRIMARY KEY NOT NULL,
    staff_forename VARCHAR(50),
    staff_surname VARCHAR(50),
    department_id VARCHAR(3),
    position VARCHAR(50),
    manager_id INTEGER,
    FOREIGN KEY (department_id) REFERENCES departments(department_id)
);

CREATE TABLE students (
	student_id INTEGER PRIMARY KEY NOT NULL,
    student_forename VARCHAR(50),
    student_surname VARCHAR(50),
    year_of_study INTEGER,
    date_of_birth DATE,
    tutor_id INTEGER,
    FOREIGN KEY (tutor_id) REFERENCES staff(staff_id)
);

CREATE TABLE marks (
	student_id INTEGER NOT NULL,
    staff_id INTEGER,
    experiment_id INTEGER,
    mark INTEGER,
    mitigation BOOLEAN,
    FOREIGN KEY (student_id) REFERENCES students(student_id),
    FOREIGN KEY (staff_id) REFERENCES staff(staff_id),
    FOREIGN KEY (experiment_id) REFERENCES experiments(experiment_id)
);



SELECT * FROM experiments;
SELECT * FROM departments;
SELECT * FROM staff;
SELECT * FROM students;
SELECT * FROM marks;




-- STUDENT-TUTOR JOINS

SELECT students.student_forename, students.student_surname, staff.staff_forename AS tutor_forename, staff_surname AS tutor_surname 
FROM students 
INNER JOIN staff 
ON students.tutor_id=staff.staff_id;


-- SELF JOIN (extra, not in submission)

SELECT 
	s1.staff_forename, 
	s1.staff_surname, 
    s2.staff_forename as ManagerForename, 
    s2.staff_surname as ManagerSurname 
FROM staff s1 
LEFT JOIN staff s2 
ON s1.manager_id = s2.staff_id;



-- PASS OR FAIL FUNCTION

DELIMITER $$

CREATE FUNCTION pass_fail(
	score INTEGER, mit BOOLEAN
) 
RETURNS VARCHAR(22)
DETERMINISTIC
BEGIN
    DECLARE response VARCHAR(22);

	IF score >= 40 THEN
		SET response = 'PASS';
    ELSEIF (score < 40 AND mit = 0) THEN
        SET response = 'FAIL';
	ELSEIF mit = 1 THEN
		SET response = 'FURTHER CONSIDERATION';
    END IF;
	-- return the response
	RETURN (response);
END$$
DELIMITER ;

SELECT m.student_id, pass_fail(m.mark, m.mitigation) FROM marks m;



-- NEW STUDENT PROCEDURE

DELIMITER //
CREATE PROCEDURE input_student(
	p_student_id INTEGER, 
	p_student_forename VARCHAR(30), 
    p_student_surname VARCHAR(30), 
    p_year_of_study INTEGER,
    p_date_of_birth DATE,
    p_tutor_id INTEGER
    )
BEGIN
	INSERT INTO students (student_id, student_forename, student_surname, year_of_study, date_of_birth, tutor_id)
    VALUES (p_student_id, p_student_forename, p_student_surname, p_year_of_study, p_date_of_birth, p_tutor_id);
END//
DELIMITER ;


CALL input_student(105239, 'George', 'Barnes', 2, NULL, 464);

SELECT * FROM students GROUP BY student_id;

DELETE FROM students WHERE student_id=105239;




-- STUDENT TO STAFF TRANSACTION

START TRANSACTION;
INSERT INTO staff (
	staff_id, 
    staff_forename, 
    staff_surname, 
    department_id, 
    position, 
    manager_id
    )
VALUES (476, 'Carolyn', 'Thomas', 'P4', 'PhD Student', 456);
UPDATE students SET student_forename='Carolyn (Graduated)', student_surname='Thomas (Graduated)', year_of_study=NULL, tutor_id=NULL 
WHERE student_id = 105209 AND (SELECT m.mark FROM marks m WHERE m.student_id=105209) >= 60;

SELECT * FROM students;
SELECT * FROM staff;

COMMIT;
-- ROLLBACK;




-- VIEW WITH JOINS BETWEEN 4 TABLES TO SHOW MARKS WITH NAMES AND PASS/FAIL WITH SUBQUERY

CREATE OR REPLACE VIEW vw_data AS
SELECT 
	students.student_forename, 
    students.student_surname, 
    staff.staff_forename, 
    staff.staff_surname, 
    experiments.experiment_name, 
    marks.mark, marks.mitigation, 
    (SELECT pass_fail(marks.mark, marks.mitigation)) 
FROM marks 
INNER JOIN experiments ON experiments.experiment_id=marks.experiment_id
INNER JOIN staff ON staff.staff_id=marks.staff_id
INNER JOIN students ON students.student_id=marks.student_id
WITH CHECK OPTION;

SELECT * FROM vw_data;




-- DATA ANALYSIS USING GROUP BY AND HAVING WITH SUBQUERY

SELECT 
	AVG(m.mark), 
    MAX(m.mark), 
    MIN(m.mark) 
FROM marks m;

SELECT 
	AVG(m.mark) 
FROM marks m 
WHERE m.experiment_id = 5;



SELECT 
	m.staff_id, 
    AVG(m.mark) 
FROM marks m 
GROUP BY m.staff_id; 
-- May need moderation

SELECT 
	m.staff_id, 
    AVG(m.mark) 
FROM marks m 
GROUP BY m.staff_id 
HAVING ABS(AVG(m.mark)-(SELECT AVG(m.mark) FROM marks m)) > 10;
-- Markers 458, 460 and 474 need moderating



SELECT 
	m.experiment_id, 
    AVG(m.mark) 
FROM marks m 
GROUP BY m.experiment_id;  
-- May need scaling

SELECT 
	m.experiment_id, 
    AVG(m.mark) 
FROM marks m 
GROUP BY m.experiment_id 
HAVING ABS(AVG(m.mark)-(SELECT AVG(m.mark) FROM marks m)) > 8; 
-- Experiments 3, 4 and 5 seemed to be particularly difficult and may need scaling











