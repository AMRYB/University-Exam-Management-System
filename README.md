# University Exam Management System (Oracle PL/SQL)

> **Course Project** — *Advanced Databases*  

This repository contains an Oracle **PL/SQL** implementation of a simple **University Exam Management System**.  
It demonstrates core DB programming concepts: **users/privileges, triggers, procedures, functions, cursors, and transaction control**.

---

## Project Overview

The system supports:
- Managing **students, professors, courses, registrations, exams, and exam results**
- Enforcing **prerequisite-based registration eligibility**
- Computing **letter grades** and **pass/fail** status automatically
- Generating **course performance reports**
- Writing **audit logs** for registration operations
- Issuing **warnings** and **suspending** students based on academic performance
- Demonstrating a **blocking/waiting** (lock) scenario for concurrency concepts

All logic is implemented in a **single SQL script**:
- `project.sql`

---

## Schema (Main Tables)

- `Professors(id, name, department)`
- `Courses(id, name, professor_id, credit_hours, prerequisite_course_id)`
- `Students(id, name, academic_status, total_credits)`
- `Register(id, student_id, course_id)`
- `Exams(id, course_id, exam_date, exam_type)`
- `ExamResults(id, registration_id, score, grade, status)`
- `AuditTrail(id, table_name, operation, old_data, new_data, log_date)`
- `Warnings(id, student_id, warning_reason, warning_date)`
- `DBUserCreationLog(id, username, created_by, created_at)`

> ✅ Tip: Add an ERD image here if you have it: `docs/erd.png`

---

## Implemented Features (What to Look For in `project.sql`)

### 1) User Management & Privileges
- Creates `MANAGER`, `USER1`, `USER2`
- Grants minimum required privileges per task requirements
- Logs `CREATE USER` operations into `DBUserCreationLog` using a **database trigger**

### 2) Exam Eligibility Validation
- Trigger blocks registration if prerequisite course was not completed (passed).

### 3) Audit Trail for Registration
- `BEFORE INSERT` and `BEFORE DELETE` triggers on `Register` write to `AuditTrail`.

### 4) Grade Calculation
- Function computes letter grade from numeric `score`
- Updates `ExamResults.grade` and `ExamResults.status`

### 5) Data Integrity: Grade Update Protection
- Trigger prevents unauthorized grade updates.

### 6) Automated Warning Issuance
- Procedure inserts a warning if a student fails **2+ courses**.

### 7) Course Performance Report (Cursor)
- Procedure prints a report (students, results, pass/fail counts) via `DBMS_OUTPUT`.

### 8) Exam Schedule Management
- PL/SQL block displays all exams for a given course (midterm/final).

### 9) Multi-Exam Grade Update (Transaction)
- PL/SQL block updates multiple rows in one transaction with rollback on error.

### 10) Student Suspension
- Procedure suspends students who received **3+ warnings** and logs to `AuditTrail`.

### 11) GPA Calculation
- Function calculates GPA using course credit hours + letter grades.

### BONUS) Blocking/Waiting Scenario
- Demonstrates lock contention and shows how to identify blocker/waiting sessions.

---

## How to Run

### Prerequisites
- Oracle Database (Local / XE / Cloud)
- SQL*Plus (recommended) or SQL Developer

### Execution (SQL*Plus Recommended)

1. Open SQL*Plus as SYSDBA:
   ```sql
   sqlplus / as sysdba
   ```

2. Run the script:
   ```sql
   @project.sql
   ```

> ⚠️ Note: The script uses `conn ...` commands (SQL*Plus style). If you are using SQL Developer, you may need to run sections manually or ensure connection switching is supported.

### View Outputs
Enable output when running report procedures:
```sql
SET SERVEROUTPUT ON;
```

---

## Example Calls (Edit IDs to Match Your Data)

```sql
-- Calculate & update grade for a specific ExamResults row:
SELECT FN_CALC_GRADE(1) AS grade FROM dual;

-- Issue warnings (students failing >= 2 courses):
EXEC PR_ISSUE_WARNINGS;

-- Generate course report:
EXEC PR_COURSE_PERFORMANCE_REPORT(101);

-- Suspend students with >= 3 warnings:
EXEC PR_SUSPEND_STUDENTS;

-- Calculate GPA:
SELECT FN_CALC_GPA(932230126) AS gpa FROM dual;
```

---

## Repository “About” Description (GitHub)

Pick one and adjust:

- **Option A:** University Exam Management System (Oracle PL/SQL) — Advanced Databases course project.
- **Option B:** Oracle PL/SQL project: scheduling exams, eligibility checks, results, audit logs, and reports.
- **Option C:** Advanced Databases assignment: PL/SQL triggers, procedures, functions, cursors, transactions.

### Suggested Topics
`oracle` • `plsql` • `sql` • `triggers` • `stored-procedures` • `cursors` • `transactions` • `database` • `university` • `exam-management`

---

## Notes

- Replace the placeholder metadata (university / instructor / team).
- Add screenshots (optional): output of reports, log tables, etc.

---

## License
For educational use. (Choose a license if your course allows it.)

