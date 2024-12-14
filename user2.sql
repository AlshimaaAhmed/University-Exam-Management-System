-----9.User Management and Privileges 
INSERT INTO user1.Student (name, academic_status, total_credits) VALUES
('SAGDA FATHY', 'Undergraduate', 17),
('ESRAA FATHY', 'Graduate', 27),
('Youssef yasser', 'Undergraduate', 20),
('Abrar Ahmed', 'Graduate', 33),
('Sherif ', 'Undergraduate', 19);
INSERT INTO user1.Course (name, credit_hours, prerequisite_course_id, Professoer_Id)
VALUES ('Basic Programming', 3, NULL, NULL),
       ('Intermediate Programming', 3, 1, NULL),
       ('Advanced Programming', 3, 2, NULL);
INSERT INTO main_manager.Register (student_id, course_id)
VALUES (1, 1),
(2, 2),
(3, 3),
(4, 1),
(5, 2); 
---10.Blocker-Waiting Situation 
INSERT INTO main_manager.Register (student_id, course_id)
VALUES ( 1, 1);
---USER1
commit;

--------
BEGIN
    -- User 2: Update a record in the Register table (locking the Register table)
    UPDATE main_manager.Register SET student_id = 2 WHERE id = 11;

    -- Simulate waiting by attempting to lock the Courses table (which is locked by User 1)
    UPDATE user1.Course SET name = 'Advanced Physics' WHERE id = 2;

    -- Commit will not happen due to deadlock
    COMMIT;
END;