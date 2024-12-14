-----9.User Management and Privileges - 
CREATE TABLE Student(
    id NUMBER GENERATED ALWAYS AS IDENTITY START WITH 1 INCREMENT BY 1 PRIMARY KEY,
    name VARCHAR2(255) NOT NULL,
    academic_status VARCHAR2(50) NOT NULL,
    total_credits NUMBER NOT NULL
);



CREATE TABLE Course(
     id NUMBER GENERATED ALWAYS AS IDENTITY START WITH 1 INCREMENT BY 1 PRIMARY KEY,
     name VARCHAR2(255) NOT NULL,
     credit_hours INT NOT NULL,
     prerequisite_course_id INT,
     Professoer_Id INT,
      FOREIGN KEY (prerequisite_course_id) REFERENCES Course(id),
      FOREIGN KEY (Professoer_Id) REFERENCES MAIN_MANAGER.Professor(id)
);

commit;

-----10. Blocker-Waiting Situation 
UPDATE Student SET academic_status = 'Suspended' WHERE id = 1;
----USER2
COMMIT;

------------------
BEGIN
    -- Update a record in the Courses table (User 1 locks the Courses table)
    UPDATE Course SET name = 'Advanced Math' WHERE id = 1;

    -- Simulate waiting by attempting to lock the Register table (which is locked by User 2)
    UPDATE main_manager.Register SET student_id = 1 WHERE id = 10;

    -- Commit the transaction if needed
    COMMIT;
END;
