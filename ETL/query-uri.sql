--activities per day per employee
SELECT
    d.full_date,
    e.legacy_employee_id,
    a.activity_type_code,
    a.activity_type_name,
    f.legacy_timesheet_id,
    f.legacy_project_id,
    f.hours_worked
FROM target.fact_employee_activity f
JOIN target.dim_employee e
    ON f.employee_key = e.employee_key
JOIN target.dim_date d
    ON f.date_key = d.date_key
JOIN target.dim_activity_type a
    ON f.activity_type_key = a.activity_type_key
ORDER BY
    d.full_date,
    e.legacy_employee_id,
    a.activity_type_code;
GO

--daily summary per employee
SELECT
    d.full_date,
    e.legacy_employee_id,
    SUM(CASE WHEN a.activity_type_code = 'TIMESHEET_WORK' THEN ISNULL(f.hours_worked, 0) ELSE 0 END) AS total_hours_worked,
    SUM(CASE WHEN a.activity_type_code = 'ATTENDANCE' THEN 1 ELSE 0 END) AS attendance_events,
    SUM(CASE WHEN a.activity_type_code = 'ABSENCE' THEN 1 ELSE 0 END) AS absence_days,
    SUM(CASE WHEN a.activity_type_code = 'PARDONED_ABSENCE' THEN 1 ELSE 0 END) AS pardoned_absence_days,
    SUM(CASE WHEN a.activity_type_code = 'HOLIDAY' THEN 1 ELSE 0 END) AS holiday_days
FROM target.fact_employee_activity f
JOIN target.dim_employee e
    ON f.employee_key = e.employee_key
JOIN target.dim_date d
    ON f.date_key = d.date_key
JOIN target.dim_activity_type a
    ON f.activity_type_key = a.activity_type_key
GROUP BY
    d.full_date,
    e.legacy_employee_id
ORDER BY
    d.full_date,
    e.legacy_employee_id;
GO

--all activity types for one employee
SELECT
    d.full_date,
    e.legacy_employee_id,
    a.activity_type_name,
    f.hours_worked
FROM target.fact_employee_activity f
JOIN target.dim_employee e
    ON f.employee_key = e.employee_key
JOIN target.dim_date d
    ON f.date_key = d.date_key
JOIN target.dim_activity_type a
    ON f.activity_type_key = a.activity_type_key
WHERE e.legacy_employee_id = 101
ORDER BY d.full_date, a.activity_type_name;
GO

--Timesheet hours only
SELECT
    d.full_date,
    e.legacy_employee_id,
    SUM(f.hours_worked) AS total_hours
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
GO