Create Database employee_dw;
GO

USE employee_dw;
GO

CREATE SCHEMA staging;
GO

CREATE SCHEMA target;
GO

CREATE TABLE staging.timesheets_raw (
    staging_timesheet_key INT IDENTITY(1,1) PRIMARY KEY,
    legacy_timesheet_id INT NOT NULL,
    legacy_employee_id INT NOT NULL,
    work_date DATE NOT NULL,
    legacy_project_id INT NULL,
    hours_worked DECIMAL(5,2) NOT NULL
);
Go

INSERT INTO staging.timesheets_raw (
    legacy_timesheet_id,
    legacy_employee_id,
    work_date,
    legacy_project_id,
    hours_worked
)
SELECT
    timesheetID,
    employeeID,
    WorkDate,
    ProjectID,
    HoursWorked
FROM Timesheet_1.dbo.Timesheet;
GO

Select legacy_timesheet_id,
    legacy_employee_id,
    work_date,
    legacy_project_id,
    hours_worked From staging.timesheets_raw;

--Tabel populat cu zilele anului 2025
CREATE TABLE target.dim_date ( --
    date_key INT PRIMARY KEY,
    full_date DATE NOT NULL UNIQUE,
    day_number INT NOT NULL,
    month_number INT NOT NULL,
    year_number INT NOT NULL,
    day_name NVARCHAR(20) NOT NULL,
    month_name NVARCHAR(20) NOT NULL,
    quarter_number INT NOT NULL,
    is_weekend BIT NOT NULL
);
GO

CREATE TABLE target.dim_employee (
    employee_key INT IDENTITY(1,1) PRIMARY KEY,
    legacy_employee_id INT NOT NULL UNIQUE
);
GO

CREATE TABLE target.dim_activity_type (
    activity_type_key INT IDENTITY(1,1) PRIMARY KEY,
    activity_type_code NVARCHAR(50) NOT NULL UNIQUE,
    activity_type_name NVARCHAR(100) NOT NULL
);
GO

CREATE TABLE target.fact_employee_activity (
    activity_fact_key INT IDENTITY(1,1) PRIMARY KEY,
    employee_key INT NOT NULL,
    date_key INT NOT NULL,
    activity_type_key INT NOT NULL,
    legacy_timesheet_id INT NULL,
    legacy_project_id INT NULL,
    hours_worked DECIMAL(5,2) NULL,

    CONSTRAINT FK_fact_employee
        FOREIGN KEY (employee_key) REFERENCES target.dim_employee(employee_key),

    CONSTRAINT FK_fact_date
        FOREIGN KEY (date_key) REFERENCES target.dim_date(date_key),

    CONSTRAINT FK_fact_activity_type
        FOREIGN KEY (activity_type_key) REFERENCES target.dim_activity_type(activity_type_key)
);
GO

--external tables
----------------------------------------------------------

USE employee_dw;
GO

CREATE TABLE staging.attendance_raw (
    staging_attendance_key INT IDENTITY(1,1) PRIMARY KEY,
    legacy_attendance_id INT NOT NULL,
    legacy_employee_id INT NOT NULL,
    employee_name NVARCHAR(100) NOT NULL,
    session_date DATE NOT NULL,
    session_name NVARCHAR(200) NOT NULL,
    attendance_status NVARCHAR(50) NOT NULL,
    minutes_attended INT NOT NULL,
    source_file_name NVARCHAR(255) NULL,
    load_datetime DATETIME2 NOT NULL DEFAULT SYSDATETIME()
);
GO
ALTER TABLE staging.attendance_raw
DROP COLUMN legacy_attendance_id;

CREATE TABLE staging.absence_raw (
    staging_absence_key INT IDENTITY(1,1) PRIMARY KEY,
    legacy_absence_id INT NOT NULL,
    legacy_employee_id INT NOT NULL,
    employee_name NVARCHAR(100) NOT NULL,
    absence_start_date DATE NOT NULL,
    absence_end_date DATE NOT NULL,
    absence_type NVARCHAR(100) NOT NULL,
    approval_status NVARCHAR(50) NOT NULL,
    comments NVARCHAR(255) NULL,
    source_sheet_name NVARCHAR(100) NULL,
    load_datetime DATETIME2 NOT NULL DEFAULT SYSDATETIME()
);
GO

CREATE TABLE staging.pardoned_absence_raw (
    staging_pardoned_key INT IDENTITY(1,1) PRIMARY KEY,
    legacy_pardoned_id INT NOT NULL,
    legacy_employee_id INT NOT NULL,
    employee_name NVARCHAR(100) NOT NULL,
    obligation_date DATE NOT NULL,
    obligation_type NVARCHAR(100) NOT NULL,
    university_name NVARCHAR(150) NULL,
    proof_document_flag BIT NOT NULL,
    approval_status NVARCHAR(50) NOT NULL,
    comments NVARCHAR(255) NULL,
    source_sheet_name NVARCHAR(100) NULL,
    load_datetime DATETIME2 NOT NULL DEFAULT SYSDATETIME()
);
GO

ALTER TABLE staging.pardoned_absence_raw
ADD document_reference NVARCHAR(50) NOT NULL;

CREATE TABLE staging.holiday_calendar_raw (
    staging_holiday_key INT IDENTITY(1,1) PRIMARY KEY,
    holiday_date DATE NOT NULL,
    holiday_name NVARCHAR(150) NOT NULL,
    country_code NVARCHAR(10) NOT NULL,
    applies_to_all_employees BIT NOT NULL,
    source_sheet_name NVARCHAR(100) NULL,
    load_datetime DATETIME2 NOT NULL DEFAULT SYSDATETIME()
);
GO

ALTER TABLE staging.holiday_calendar_raw
add applies_to NVARCHAR(20) NOT NULL;



SELECT TOP 5 * FROM staging.holiday;
GO