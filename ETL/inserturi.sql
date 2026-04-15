USE employee_dw;
GO
--added 2025 previously
DECLARE @start_date DATE = '2026-01-01';
DECLARE @end_date DATE = '2026-12-31';

WHILE @start_date <= @end_date
BEGIN
    INSERT INTO target.dim_date (
        date_key,
        full_date,
        day_number,
        month_number,
        year_number,
        day_name,
        month_name,
        quarter_number,
        is_weekend
    )
    VALUES (
        CAST(CONVERT(VARCHAR(8), @start_date, 112) AS INT),
        @start_date,
        DAY(@start_date),
        MONTH(@start_date),
        YEAR(@start_date),
        DATENAME(WEEKDAY, @start_date),
        DATENAME(MONTH, @start_date),
        DATEPART(QUARTER, @start_date),
        CASE WHEN DATENAME(WEEKDAY, @start_date) IN ('Saturday', 'Sunday') THEN 1 ELSE 0 END
    );

    SET @start_date = DATEADD(DAY, 1, @start_date);
END;
GO

SELECT date_key,
        full_date,
        day_number,
        month_number,
        year_number,
        day_name,
        month_name,
        quarter_number,
        is_weekend from target.dim_date;

INSERT INTO target.dim_employee (legacy_employee_id)
SELECT DISTINCT legacy_employee_id
FROM staging.timesheets_raw;
GO

SELECT *
FROM target.dim_employee;

INSERT INTO target.dim_activity_type (activity_type_code, activity_type_name)
VALUES
('TIMESHEET_WORK', 'Timesheet Work'),
('ATTENDANCE', 'Attendance'),
('ABSENCE', 'Absence'),
('PARDONED_ABSENCE', 'Pardoned Absence'),
('HOLIDAY', 'Holiday');
GO

INSERT INTO target.fact_employee_activity (
    employee_key,
    date_key,
    activity_type_key,
    legacy_timesheet_id,
    legacy_project_id,
    hours_worked
)
SELECT
    e.employee_key,
    d.date_key,
    a.activity_type_key,
    s.legacy_timesheet_id,
    s.legacy_project_id,
    s.hours_worked
FROM staging.timesheets_raw s
JOIN target.dim_employee e
    ON s.legacy_employee_id = e.legacy_employee_id
JOIN target.dim_date d
    ON s.work_date = d.full_date
JOIN target.dim_activity_type a
    ON a.activity_type_code = 'TIMESHEET_WORK';
GO

SELECT TOP 20 *
FROM target.fact_employee_activity;

--debugging, my work dates table was outside range, had to repopulate
SELECT MIN(work_date) AS min_work_date,
       MAX(work_date) AS max_work_date
FROM staging.timesheets_raw;


--MARE SELECT
SELECT
    d.full_date,
    e.legacy_employee_id,
    SUM(f.hours_worked) AS total_hours_worked
FROM target.fact_employee_activity f
JOIN target.dim_employee e
    ON f.employee_key = e.employee_key
JOIN target.dim_date d
    ON f.date_key = d.date_key
JOIN target.dim_activity_type a
    ON f.activity_type_key = a.activity_type_key
WHERE a.activity_type_code = 'TIMESHEET_WORK'
GROUP BY
    d.full_date,
    e.legacy_employee_id
ORDER BY
    d.full_date,
    e.legacy_employee_id;



SELECT
    s.name AS schema_name,
    t.name AS table_name
FROM sys.tables t
JOIN sys.schemas s
    ON t.schema_id = s.schema_id
WHERE s.name = 'staging'
ORDER BY t.name;
GO

SELECT TOP 5 * FROM staging.attendance_report_march_2026;
GO

INSERT INTO staging.attendance_raw (
    source_session_id,
    legacy_employee_id,
    employee_name,
    session_date,
    session_name,
    attendance_status,
    minutes_attended,
    source_file_name
)
SELECT
    [session_id],
    employee_id,
    employee_name,
    session_date,
    session_name,
    attendance_status,
    minutes_attended,
    'attendance_report_march_2026.csv'
FROM staging.attendance_report_march_2026;
GO

INSERT INTO staging.attendance_raw (
    source_session_id,
    legacy_employee_id,
    employee_name,
    session_date,
    session_name,
    attendance_status,
    minutes_attended,
    source_file_name
)
SELECT
    [session_id],
    employee_id,
    employee_name,
    session_date,
    session_name,
    attendance_status,
    minutes_attended,
    'attendance_report_april_2026.csv'
FROM staging.attendance_report_april_2026;
GO

INSERT INTO staging.absence_raw (
    legacy_absence_id,
    legacy_employee_id,
    employee_name,
    absence_start_date,
    absence_end_date,
    absence_type,
    approval_status,
    comments,
    source_sheet_name
)
SELECT
    absence_id,
    employee_id,
    employee_name,
    start_date,
    end_date,
    absence_type,
    approval_status,
    notes,
    'Absence_Log'
FROM staging.absence_log;
GO

INSERT INTO staging.pardoned_absence_raw (
    legacy_pardoned_id,
    legacy_employee_id,
    employee_name,
    obligation_date,
    obligation_type,
    document_reference,
    approval_status,
    comments,
    source_sheet_name
)
SELECT
    pardoned_absence_id,
    employee_id,
    employee_name,
    start_date,
    reason,
    document_reference,
    approval_status,
    approved_by,
    'Pardoned'
FROM staging.pardoned;
GO

INSERT INTO staging.holiday_calendar_raw (
    holiday_date,
    holiday_name,
    holiday_type,
    applies_to,
    source_sheet_name
)
SELECT
    holiday_date,
    holiday_name,
    holiday_type,
    applies_to,
    'Holiday'
FROM staging.holiday;
GO

INSERT INTO target.dim_employee (legacy_employee_id)
SELECT src.legacy_employee_id
FROM (
    SELECT legacy_employee_id
    FROM staging.timesheets_raw

    UNION

    SELECT employee_id AS legacy_employee_id
    FROM staging.attendance_report_march_2026

    UNION

    SELECT employee_id AS legacy_employee_id
    FROM staging.attendance_report_april_2026

    UNION

    SELECT employee_id AS legacy_employee_id
    FROM staging.absence_log

    UNION

    SELECT employee_id AS legacy_employee_id
    FROM staging.pardoned
) src
WHERE NOT EXISTS (
    SELECT 1
    FROM target.dim_employee d
    WHERE d.legacy_employee_id = src.legacy_employee_id
);
GO

INSERT INTO target.fact_employee_activity (
    employee_key,
    date_key,
    activity_type_key,
    legacy_timesheet_id,
    legacy_project_id,
    hours_worked
)
SELECT
    e.employee_key,
    d.date_key,
    a.activity_type_key,
    s.legacy_timesheet_id,
    s.legacy_project_id,
    s.hours_worked
FROM staging.timesheets_raw s
JOIN target.dim_employee e
    ON s.legacy_employee_id = e.legacy_employee_id
JOIN target.dim_date d
    ON s.work_date = d.full_date
JOIN target.dim_activity_type a
    ON a.activity_type_code = 'TIMESHEET_WORK';
GO



INSERT INTO target.fact_employee_activity (
    employee_key,
    date_key,
    activity_type_key,
    legacy_timesheet_id,
    legacy_project_id,
    hours_worked
)
SELECT
    e.employee_key,
    d.date_key,
    a.activity_type_key,
    NULL,
    NULL,
    NULL
FROM (
    SELECT employee_id, session_date
    FROM staging.attendance_report_march_2026

    UNION ALL

    SELECT employee_id, session_date
    FROM staging.attendance_report_april_2026
) ar
JOIN target.dim_employee e
    ON ar.employee_id = e.legacy_employee_id
JOIN target.dim_date d
    ON ar.session_date = d.full_date
JOIN target.dim_activity_type a
    ON a.activity_type_code = 'ATTENDANCE';
GO


INSERT INTO target.fact_employee_activity (
    employee_key,
    date_key,
    activity_type_key,
    legacy_timesheet_id,
    legacy_project_id,
    hours_worked
)
SELECT
    e.employee_key,
    d.date_key,
    a.activity_type_key,
    NULL,
    NULL,
    NULL
FROM staging.absence_log ab
JOIN target.dim_employee e
    ON ab.employee_id = e.legacy_employee_id
JOIN target.dim_date d
    ON d.full_date BETWEEN ab.start_date AND ab.end_date
JOIN target.dim_activity_type a
    ON a.activity_type_code = 'ABSENCE';
GO



INSERT INTO target.fact_employee_activity (
    employee_key,
    date_key,
    activity_type_key,
    legacy_timesheet_id,
    legacy_project_id,
    hours_worked
)
SELECT
    e.employee_key,
    d.date_key,
    a.activity_type_key,
    NULL,
    NULL,
    NULL
FROM staging.pardoned p
JOIN target.dim_employee e
    ON p.employee_id = e.legacy_employee_id
JOIN target.dim_date d
    ON p.start_date = d.full_date
JOIN target.dim_activity_type a
    ON a.activity_type_code = 'PARDONED_ABSENCE';
GO



INSERT INTO target.fact_employee_activity (
    employee_key,
    date_key,
    activity_type_key,
    legacy_timesheet_id,
    legacy_project_id,
    hours_worked
)
SELECT
    e.employee_key,
    d.date_key,
    a.activity_type_key,
    NULL,
    NULL,
    NULL
FROM staging.holiday h
JOIN target.dim_date d
    ON h.holiday_date = d.full_date
JOIN target.dim_activity_type a
    ON a.activity_type_code = 'HOLIDAY'
JOIN target.dim_employee e
    ON 1 = 1
WHERE h.applies_to = 'ALL';
GO