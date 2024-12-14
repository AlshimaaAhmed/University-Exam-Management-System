--Tables creation--
CREATE TABLE Professor(
     id NUMBER GENERATED ALWAYS AS IDENTITY START WITH 1 INCREMENT BY 1 PRIMARY KEY,
     name VARCHAR2(255) NOT NULL,
     Department VARCHAR2(255) NOT NULL
);

CREATE TABLE Register(
     id NUMBER GENERATED ALWAYS AS IDENTITY START WITH 1 INCREMENT BY 1 PRIMARY KEY,
     student_Id INT,
     course_Id INT,
     FOREIGN KEY (student_Id) REFERENCES USER1.Student(id),
     FOREIGN KEY (course_Id) REFERENCES USER1.Course(id)
);

SELECT * FROM USER_SYS_PRIVS;


CREATE TABLE Exam(
     id NUMBER GENERATED ALWAYS AS IDENTITY START WITH 1 INCREMENT BY 1 PRIMARY KEY,
     course_Id INT,
    FOREIGN KEY (course_Id) REFERENCES USER1.Course(id),
    exam_date Date NOT NULL,
    exam_type VARCHAR2(50) NOT NULL
);

CREATE TABLE ExamResults(
    id NUMBER GENERATED ALWAYS AS IDENTITY START WITH 1 INCREMENT BY 1 PRIMARY KEY,
     registration_id INT,
     FOREIGN KEY (registration_id) REFERENCES Register(id),
    grade INT NOT NULL ,
    status VARCHAR2(50)
);

CREATE TABLE Warning(
     id NUMBER GENERATED ALWAYS AS IDENTITY START WITH 1 INCREMENT BY 1 PRIMARY KEY,
     student_id INT,
     FOREIGN KEY (student_id) REFERENCES USER1.Student(id),
    warning_reason VARCHAR2(255),
    warning_date Date NOT NULL
);

CREATE TABLE AuditTrail (
    id NUMBER GENERATED ALWAYS AS IDENTITY START WITH 1 INCREMENT BY 1 PRIMARY KEY,
    table_name VARCHAR2(255),
    operation VARCHAR2(50),
    old_data VARCHAR2(255),
    new_data VARCHAR2(255),
    timestamp TIMESTAMP 
);


------------------------------------------------------------
-----1.Creating Eligibility_Validation_Trigger-------
CREATE OR REPLACE TRIGGER Eligibility_Validation_Trigger
BEFORE INSERT ON Register
FOR EACH ROW
DECLARE
   prerequisite_id INTEGER;
   prerequisite_count INTEGER;
   custom_exeption EXCEPTION;
BEGIN
    SELECT prerequisite_course_id
    INTO prerequisite_id
    FROM Course
    WHERE id = :NEW.course_id;

 IF prerequisite_id  is Not NULL THEN
    SELECT COUNT(*)
        INTO prerequisite_count
        FROM ExamResults
        JOIN Register ON ExamResults.registration_id = Register.id
        WHERE Register.student_id = :NEW.student_id
          AND Register.course_id = prerequisite_id
          AND ExamResults.status = 'PASS';
    
    If prerequisite_count == 0 THEN
         RAISE_APPLICATION_ERROR(-20001, 'Prerequisite not met for the course.');
   END IF;
   END IF;
       
    
END;
-------------------------------------------------------------
-- Testing The Eligibility_Validation_Trigger---

INSERT INTO Professor VALUES (1, 'hanan', 'Computer Science');
INSERT INTO Student VALUES (1, 'alshimaa ahmed', 'active', 170);

INSERT INTO Course (id, name, credit_hours, prerequisite_course_id, Professoer_Id)
VALUES (1, 'db1', 3, NULL, 1);

INSERT INTO Course (id, name, credit_hours, prerequisite_course_id, Professoer_Id)
VALUES (2, 'db2', 3, 1, 1);

SET SERVEROUTPUT ON;
INSERT INTO Register (id, student_id, course_id)
VALUES (1, 1, 2);

----------------------------------------------------------------
-----2.Creating Grad calculation function-------

CREATE OR REPLACE FUNCTION Grade_Calculation(ExamResults_id IN INTEGER)
RETURN CHAR
IS
  Student_Score INTEGER;
  Student_Grade CHAR(2);
BEGIN 
  SELECT score into student_score FROM ExamResults  WHERE id = ExamResults_id;
  CASE
    WHEN (student_score < 50)THEN Student_Grade := 'F';
    WHEN (student_score < 60)THEN Student_Grade := 'C';
    WHEN (student_score < 70)THEN Student_Grade := 'D';
    WHEN (student_score < 80)THEN Student_Grade := 'B';
    WHEN (student_score < 90)THEN Student_Grade := 'B+';
    WHEN (student_score < 50)THEN Student_Grade := 'A';
    ELSE Student_Grade := 'A+';
    END CASE;
 UPDATE ExamResults SET grade = Student_Grade WHERE id = ExamResults_id;
  RETURN Student_Grade;
  
END;

----------------------------------------------------------------
---TESTING GRADE CALCULATION FUNCTION----------------------
INSERT INTO ExamResults (id, registration_id, grade, status, score) VALUES (1, 1,NULL ,'PASS', '100');
SET SERVEROUTPUT ON;
BEGIN
    DBMS_OUTPUT.PUT_LINE(Grade_Calculation(1));  -- print 'A+'
END;

INSERT INTO ExamResults (id, registration_id, grade, status, score) VALUES (2 ,2, NULL,'PASS', '79');
SET SERVEROUTPUT ON;
BEGIN
    DBMS_OUTPUT.PUT_LINE(Grade_Calculation(2));  --  print 'B'
END;
------------------------------------------------------------------------
---3.Automated_Warning_Issuance_procedure------

create or replace PROCEDURE WARNING_Issuance_Procedure
IS
 
  CURSOR failing_students_cursor IS
    SELECT Register.student_id, COUNT(*) AS fail_count
    FROM ExamResults 
     JOIN Register  ON ExamResults.registration_id = Register.id
    WHERE ExamResults.status = 'FAIL'
    GROUP BY Register.student_id
    HAVING COUNT(*) >= 2;


BEGIN
   FOR failing_student IN failing_students_cursor LOOP
     INSERT INTO Warning(STUDENT_ID,WARNING_REASON,WARNING_DATE) VALUES(failing_student.student_id,'fail in'||failing_student.fail_count||'course', sysdate);
     END LOOP;
END;
------------------------------------------------------------------------------
BEGIN
    WARNING_Issuance_Procedure;
END;
ALTER TABLE AUDITTRAIL MODIFY
(
  ID GENERATED ALWAYS AS IDENTITY INCREMENT BY 1 START WITH 1 NOMINVALUE NOMAXVALUE 
)

DROP TABLE AUDITTRAIL;
-----------------------------------------------------------------------------
-----4.Audit Trail for Registration Trigger----------
CREATE OR REPLACE TRIGGER Audit_Trail_Trigger
BEFORE INSERT OR DELETE ON Register
FOR EACH ROW
DECLARE
BEGIN 
IF INSERTING THEN 
 INSERT INTO AuditTrail (table_name,operation, new_data,timestamp) VALUES ('Register','INSERTING','STUDENT ID = '||:NEW.student_Id||' ,COURCE ID = '|| :NEW.course_Id,SYSTIMESTAMP);
 ELSIF DELETING THEN 
 INSERT INTO AuditTrail (table_name,operation, old_data,timestamp) VALUES ('Register','DELETING','STUDENT ID = '||:OLD.student_Id||' ,COURCE ID = '|| :OLD.course_Id,SYSTIMESTAMP);
  END IF;
 END;
 -----------------------------------------------------------------------
 ----TESTING AUDIT TRAIL FOR REGISTRATION------
 INSERT INTO Register (id, student_id, course_id)
VALUES (4, 1, 4);

DELETE FROM Register
WHERE id = 4;
-------------------------------------------------------------------------
------5.Course Performance Report--------
create or replace NONEDITIONABLE PROCEDURE REPORT_CREATING(course_ID integer)
 IS
 STUDENT_ID INTEGER;
 GRADE ExamResults.grade%type;
 STATE ExamResults.status%type;
 PASS_N INTEGER;
 FAIL_N INTEGER;

 CURSOR REPORT_CURSER IS
  SELECT register.student_id ,ExamResults.grade,ExamResults.status
  FROM  register
  JOIN ExamResults  ON register.id= ExamResults.REGISTRATION_ID
  WHERE register.COURSE_ID = course_ID;
 BEGIN
 PASS_N := 0;
 FAIL_N := 0;
 DBMS_OUTPUT.PUT_LINE(COURSE_ID||'STUDENT_ID GRADE STATE');
 OPEN REPORT_CURSER;
 LOOP
  FETCH REPORT_CURSER INTO STUDENT_ID,GRADE,STATE;
  EXIT WHEN REPORT_CURSER%NOTFOUND;
  IF (STATE = 'PASS') THEN PASS_N := PASS_N + 1;
  ELSE FAIL_N := FAIL_N + 1;
  END IF;
      DBMS_OUTPUT.PUT_LINE(STUDENT_ID||'         '||GRADE||'      '||STATE);
      END LOOP;
    DBMS_OUTPUT.PUT_LINE('THE NUMBER OF STUDENTS HOW PASS = '|| PASS_N); 
    DBMS_OUTPUT.PUT_LINE('THE NUMBER OF STUDENTS HOW FAIL = '|| FAIL_N); 
 END;
 
---------------------------------------------------------------------------------
SET SERVEROUTPUT ON;
BEGIN
REPORT_CREATING(3);
END;
DELETE FROM register
WHERE id = 3;
------------------------------------------------------------------
---6.EXAM SCHEDULE MANAGMENT----------------------------
SET SERVEROUTPUT ON;

DECLARE
  CURSOR EXAM_SCHEDUALE_CURSER IS
  SELECT Course.NAME , EXAM.EXAM_DATE,EXAM.EXAM_TYPE
  FROM EXAM
  JOIN COURSE ON exam.course_id = course.id;
  
  COURSE_NAME COURSE.name%type;
  EXAM_DATE EXAM.exam_date%type;
  EXAM_TYPE EXAM.exam_type%type;
 BEGIN
 OPEN EXAM_SCHEDUALE_CURSER;
  FETCH EXAM_SCHEDUALE_CURSER INTO COURSE_NAME , EXAM_DATE, EXAM_TYPE;
 IF (EXAM_SCHEDUALE_CURSER%NOTFOUND) THEN
  DBMS_OUTPUT.PUT_LINE('NO EXAMS SCHEDUALED');
  ELSE
  DBMS_OUTPUT.PUT_LINE('CourseName ExamDate ExamType');
 LOOP
  DBMS_OUTPUT.PUT_LINE(COURSE_NAME||'         '||EXAM_DATE||'    '||EXAM_TYPE);
   FETCH EXAM_SCHEDUALE_CURSER INTO COURSE_NAME , EXAM_DATE, EXAM_TYPE;
  EXIT WHEN EXAM_SCHEDUALE_CURSER%NOTFOUND;
  END LOOP;
  END IF;
 END;
 ----------------------------------------------------------------------
 ---TESTING EXAM SCHEDUALE MANGMENT-----------------------
 INSERT INTO Exam (id, course_Id, exam_date, exam_type)
VALUES (1, 1, TO_DATE('2024-12-15','YYYY-MM-DD'),'Final');
INSERT INTO Exam (id, course_Id, exam_date, exam_type)
VALUES (2, 2, TO_DATE('2024-12-15','YYYY-MM-DD'),'MID');
INSERT INTO Exam (id, course_Id, exam_date, exam_type)
VALUES (3, 3, TO_DATE('2024-12-15','YYYY-MM-DD'), 'PEACTICAL');
INSERT INTO Exam (id, course_Id, exam_date, exam_type)
VALUES (4, 4, TO_DATE('2024-12-15','YYYY-MM-DD'),'Final');
-------------------------------------------------------------------
---7.Multi-Exam Grade Update with Transactions 

SET SERVEROUTPUT ON;

DECLARE 
    TYPE ID_ARRAY IS VARRAY(4) OF ExamResults.ID%TYPE;
    TYPE GRADE_ARRAY IS VARRAY(4) OF ExamResults.grade%TYPE;

    id ID_ARRAY := ID_ARRAY(1, 2, 3, 4);
    grade GRADE_ARRAY := GRADE_ARRAY(99, 98, 80, 88);
BEGIN 
    for i in 1..id.count LOOP
        update ExamResults set grade = grade(i) WHERE id = id(i);
        IF SQL%ROWCOUNT = 0 then
            raise_application_error(-20001,'error in update');
        END IF;
    END LOOP;
    commit;
    DBMS_OUTPUT.PUT_LINE('committed successfully');
EXCEPTION
    when others then
        rollback;
        DBMS_OUTPUT.PUT_LINE('We are rolling back');
END;



---------------------------------------------------------

CREATE SEQUENCE AuditTrail_SEQ start with 5 INCREMENT BY 1;

---------------------------------------------------------
----8.Student Suspension Based on Warnings 
CREATE OR REPLACE PROCEDURE SuspendStudentsWithMultipleWarnings IS
BEGIN
    FOR student_rec in (
        SELECT s.id AS student_id,s.academic_status AS old_status,w.warning_date AS old_date FROM Student s
        join (SELECT student_id, MAX(warning_date) AS warning_date FROM Warning GROUP BY student_id HAVING COUNT(*) >= 3) w on s.id = w.student_id)
    LOOP
        UPDATE Student
        SET academic_status = 'Suspended'
        WHERE id = student_rec.student_id;
        INSERT INTO AuditTrail (id,table_name,operation,old_data,new_data,timestamp)
        VALUES (AuditTrail_SEQ.NEXTVAL,'Student','UPDATE',student_rec.old_date,SYSTIMESTAMP,SYSTIMESTAMP);
    END LOOP;
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Student suspension process completed.');
END SuspendStudentsWithMultipleWarnings;

BEGIN
    SuspendStudentsWithMultipleWarnings;
END;

INSERT INTO Warning (id, student_id, warning_reason, warning_date) VALUES (1, 1, 'Late Submission', SYSDATE);
INSERT INTO Warning (id, student_id, warning_reason, warning_date) VALUES (2, 1, 'Missed Exam', SYSDATE);
INSERT INTO Warning (id, student_id, warning_reason, warning_date) VALUES (3, 1, 'Low Attendance', SYSDATE);

-------------------------------------------------------------------------------------------
----9. User Management and Privileges 
alter session set  "_oracle_script"=true;
CREATE USER Manager IDENTIFIED BY 1111;
CREATE ROLE Manager_Role1;
Grant create user , create session ,create table, INSERT ANY TABLE  to Manager_Role WITH ADMIN OPTION;
grant Manager_Role to Manager;
GRANT SELECT ON MAIN_MANAGER.Professor, REFERENCES ON MAIN_MANAGER.Professor TO MANAGER WITH GRANT OPTION ;
GRANT REFERENCES ON MAIN_MANAGER.Professor TO MANAGER WITH GRANT OPTION;

DROP USER Manager;
GRANT REFERENCES ON Professor TO Manager WITH GRANT OPTION;
GRANT REFERENCES, INSERT, UPDATE ON Register TO Manager WITH GRANT OPTION
GRANT ALTER USER TO Manager;
---------------------------
-- 11. Identifying Blocker and Waiting Sessions
--A.blocking
SELECT  s.sid, s.serial#,s.status,s.username, s.blocking_session
FROM v$session WHERE  s.blocking_session IS NOT NULL;

--B.waiting(blocked)
SELECT s.sid, s.serial#, s.status, s.username
FROM v$session s
WHERE s.sid IN (SELECT sid FROM v$session WHERE blocking_session IS NOT NULL);

-- 12. Performance Tuning
-- Optimizing queries using EXPLAIN PLAN
EXPLAIN PLAN FOR
SELECT * FROM Students WHERE name = 'Fatma Amr';

-- Showing the execution plan
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);