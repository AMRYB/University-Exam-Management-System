
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

