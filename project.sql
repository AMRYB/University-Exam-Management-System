
SYS AS SYSDBA
7530159

ALTER SESSION SET CONTAINER = XEPDB1;


CREATE USER MANAGER IDENTIFIED BY "123"; 
GRANT CREATE SESSION, CREATE USER, ALTER USER, DROP USER TO MANAGER;
ALTER USER MANAGER QUOTA UNLIMITED ON USERS;

--fix privilege issue
GRANT GRANT ANY PRIVILEGE TO MANAGER;
--==============================================

sqlplus MANAGER/"123"@localhost:1521/XEPDB1


CREATE USER USER1 IDENTIFIED BY "u1";
CREATE USER USER2 IDENTIFIED BY "u2";

GRANT CREATE SESSION TO USER1;
GRANT CREATE SESSION TO USER2;

GRANT CREATE TABLE, CREATE SEQUENCE, CREATE PROCEDURE, CREATE TRIGGER TO USER1;

ALTER USER USER1 QUOTA UNLIMITED ON USERS;
ALTER USER USER2 QUOTA UNLIMITED ON USERS;

--fix grants issue

--1.create tables
sqlplus USER1/"u1"@localhost:1521/XEPDB1

CREATE TABLE Professors (
    id NUMBER PRIMARY KEY,
    name VARCHAR2(100) NOT NULL,
    department VARCHAR2(100) NOT NULL
);

CREATE TABLE Courses (
    id NUMBER PRIMARY KEY,
    name VARCHAR2(100) NOT NULL,
    professor_id NUMBER NOT NULL,
    credit_hours NUMBER CHECK (credit_hours > 0),
    prerequisite_course_id NUMBER,
    CONSTRAINT fk_course_professor
        FOREIGN KEY (professor_id) REFERENCES Professors(id),
    CONSTRAINT fk_course_prerequisite
        FOREIGN KEY (prerequisite_course_id) REFERENCES Courses(id)
);

CREATE TABLE Students (
    id NUMBER PRIMARY KEY,
    name VARCHAR2(100) NOT NULL,
    academic_status VARCHAR2(20)
        CHECK (academic_status IN ('Active','Suspended')),
    total_credits NUMBER DEFAULT 0 CHECK (total_credits >= 0)
);

CREATE TABLE Register (
    id NUMBER PRIMARY KEY,
    student_id NUMBER NOT NULL,
    course_id NUMBER NOT NULL,
    CONSTRAINT fk_register_student
        FOREIGN KEY (student_id) REFERENCES Students(id),
    CONSTRAINT fk_register_course
        FOREIGN KEY (course_id) REFERENCES Courses(id),
    CONSTRAINT uq_student_course
        UNIQUE (student_id, course_id)
);

CREATE TABLE Exams (
    id NUMBER PRIMARY KEY,
    course_id NUMBER NOT NULL,
    exam_date DATE NOT NULL,
    exam_type VARCHAR2(20)
        CHECK (exam_type IN ('Midterm','Final')),
    CONSTRAINT fk_exam_course
        FOREIGN KEY (course_id) REFERENCES Courses(id)
);

CREATE TABLE ExamResults (
    id NUMBER PRIMARY KEY,
    registration_id NUMBER NOT NULL,
    score NUMBER CHECK (score BETWEEN 0 AND 100),
    grade VARCHAR2(2),
    status VARCHAR2(10)
        CHECK (status IN ('Pass','Fail')),
    CONSTRAINT fk_examresults_registration
        FOREIGN KEY (registration_id) REFERENCES Register(id)
);

CREATE TABLE AuditTrail (
    id NUMBER PRIMARY KEY,
    table_name VARCHAR2(50),
    operation VARCHAR2(20),
    old_data CLOB,
    new_data CLOB,
    log_date TIMESTAMP DEFAULT SYSTIMESTAMP
);

CREATE TABLE Warnings (
    id NUMBER PRIMARY KEY,
    student_id NUMBER NOT NULL,
    warning_reason VARCHAR2(200),
    warning_date DATE DEFAULT SYSDATE,
    CONSTRAINT fk_warning_student
        FOREIGN KEY (student_id) REFERENCES Students(id)
);

CREATE TABLE DBUserCreationLog (
    id NUMBER PRIMARY KEY,
    username VARCHAR2(50),
    created_by VARCHAR2(50),
    created_at TIMESTAMP DEFAULT SYSTIMESTAMP
);

--2.grant privileges to MANAGER
sqlplus / as sysdba
ALTER SESSION SET CONTAINER = XEPDB1;
GRANT GRANT ANY OBJECT PRIVILEGE TO MANAGER;
GRANT GRANT ANY PRIVILEGE TO MANAGER;

--==============================================

GRANT INSERT, SELECT ON USER1.STUDENTS TO USER2;
GRANT INSERT, SELECT ON USER1.COURSES TO USER2;
GRANT INSERT, SELECT ON USER1.REGISTER TO USER2;


GRANT SELECT, INSERT ON USER1.PROFESSORS TO USER2;


sqlplus USER2/"u2"@localhost:1521/XEPDB1


INSERT INTO USER1.PROFESSORS (id, name, department) VALUES (1, 'Dr. Ahmed', 'DS'); 
INSERT INTO USER1.PROFESSORS (id, name, department) VALUES (2, 'Dr. Elsayed',  'RSE'); 

INSERT INTO USER1.COURSES (id, name, professor_id, credit_hours, prerequisite_course_id)
VALUES (101, 'Databases', 1, 3, NULL);

INSERT INTO USER1.COURSES (id, name, professor_id, credit_hours, prerequisite_course_id)
VALUES (102, 'Adv Databases', 1, 3, 101); 

INSERT INTO USER1.COURSES (id, name, professor_id, credit_hours, prerequisite_course_id)
VALUES (103, 'AI For Beginners', 2, 3, NULL); 

INSERT INTO USER1.STUDENTS (id, name, academic_status, total_credits)
VALUES (1, 'Amr',   'Active', 0);

INSERT INTO USER1.STUDENTS (id, name, academic_status, total_credits)
VALUES (2, 'Doha',  'Active', 0);

INSERT INTO USER1.STUDENTS (id, name, academic_status, total_credits)
VALUES (3, 'Kareem',  'Active', 0);

INSERT INTO USER1.STUDENTS (id, name, academic_status, total_credits)
VALUES (4, 'Abdallah',  'Active', 0);

INSERT INTO USER1.STUDENTS (id, name, academic_status, total_credits)
VALUES (5, 'Youssef',  'Active', 0);



INSERT INTO USER1.REGISTER (id, student_id, course_id) VALUES (1, 1, 101);
INSERT INTO USER1.REGISTER (id, student_id, course_id) VALUES (2, 2, 101);
INSERT INTO USER1.REGISTER (id, student_id, course_id) VALUES (3, 3, 103);
INSERT INTO USER1.REGISTER (id, student_id, course_id) VALUES (4, 4, 101);
INSERT INTO USER1.REGISTER (id, student_id, course_id) VALUES (5, 5, 103);

COMMIT;

SELECT COUNT(*) FROM USER1.STUDENTS;
SELECT COUNT(*) FROM USER1.REGISTER;

sqlplus USER1/"u1"@localhost:1521/XEPDB1

CREATE SEQUENCE AUDITTRAIL_SEQ START WITH 1 INCREMENT BY 1;


CREATE OR REPLACE TRIGGER TRG_CHECK_PREREQ
BEFORE INSERT ON REGISTER
FOR EACH ROW
DECLARE
    v_prereq_id  COURSES.PREREQUISITE_COURSE_ID%TYPE;
    v_count      NUMBER;
BEGIN
    SELECT prerequisite_course_id
    INTO v_prereq_id
    FROM courses
    WHERE id = :NEW.course_id;

    IF v_prereq_id IS NOT NULL THEN
        SELECT COUNT(*)
        INTO v_count
        FROM register r
        JOIN examresults er
          ON er.registration_id = r.id
        WHERE r.student_id = :NEW.student_id
          AND r.course_id  = v_prereq_id
          AND er.status    = 'Pass';

        IF v_count = 0 THEN
            RAISE_APPLICATION_ERROR(
                -20001,
                'Registration blocked: prerequisite course not completed.'
            );
        END IF;
    END IF;
END;
/



CREATE OR REPLACE TRIGGER TRG_REGISTER_AUDIT_INS
BEFORE INSERT ON REGISTER
FOR EACH ROW
BEGIN
    INSERT INTO audittrail (id, table_name, operation, old_data, new_data, log_date)
    VALUES (
        AUDITTRAIL_SEQ.NEXTVAL,
        'REGISTER',
        'INSERT',
        NULL,
        TO_CLOB('id=' || :NEW.id || '; student_id=' || :NEW.student_id || '; course_id=' || :NEW.course_id),
        SYSTIMESTAMP
    );
END;
/


CREATE OR REPLACE TRIGGER TRG_REGISTER_AUDIT_DEL
BEFORE DELETE ON REGISTER
FOR EACH ROW
BEGIN
    INSERT INTO audittrail (id, table_name, operation, old_data, new_data, log_date)
    VALUES (
        AUDITTRAIL_SEQ.NEXTVAL,
        'REGISTER',
        'DELETE',
        TO_CLOB('id=' || :OLD.id || '; student_id=' || :OLD.student_id || '; course_id=' || :OLD.course_id),
        NULL,
        SYSTIMESTAMP
    );
END;
/


--test triggers
SELECT trigger_name, status
FROM user_triggers
WHERE trigger_name IN ('TRG_CHECK_PREREQ','TRG_REGISTER_AUDIT_INS','TRG_REGISTER_AUDIT_DEL');



CREATE OR REPLACE FUNCTION FN_CALC_GRADE (p_examresult_id IN NUMBER)
RETURN VARCHAR2
IS
    v_score NUMBER;
    v_grade VARCHAR2(2);
    v_status VARCHAR2(10);
BEGIN
    SELECT score
    INTO v_score
    FROM examresults
    WHERE id = p_examresult_id
    FOR UPDATE;

    IF v_score BETWEEN 90 AND 100 THEN
        v_grade := 'A';
    ELSIF v_score BETWEEN 80 AND 89 THEN
        v_grade := 'B';
    ELSIF v_score BETWEEN 70 AND 79 THEN
        v_grade := 'C';
    ELSIF v_score BETWEEN 60 AND 69 THEN
        v_grade := 'D';
    ELSE
        v_grade := 'F';
    END IF;

    IF v_grade = 'F' THEN
        v_status := 'Fail';
    ELSE
        v_status := 'Pass';
    END IF;

    UPDATE examresults
    SET grade = v_grade,
        status = v_status
    WHERE id = p_examresult_id;

    RETURN v_grade;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20010, 'ExamResults ID not found.');
END;
/

