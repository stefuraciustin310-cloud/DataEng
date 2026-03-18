Create Database Timesheet_1; 
Go

Use Timesheet_1;
Go

--DROPURI
-----------------------------------------------------------
DROP VIEW IF exists dbo.EmployeeProjectHours;
DROP VIEW IF exists vw_TimesheetDetails;
DROP TABLE IF exists Timesheet; --astea au fost puse ca sa pot actualiza tabelele cu cat mi-a mai venit o idee de column
DROP TABLE IF exists Employee;
DROP TABLE IF exists Project;
Go

-- TABELE
-----------------------------------------------------------
CREATE TABLE Employee (
    EmployeeID INT PRIMARY KEY IDENTITY(1,1),
    FirstName NVARCHAR(50) NOT NULL,
    LastName NVARCHAR(50) NOT NULL,
    Email NVARCHAR(100) UNIQUE NOT NULL,
    HireDate DATE NOT NULL DEFAULT GETDATE()
);

CREATE TABLE Project (
    ProjectID INT PRIMARY KEY IDENTITY(1,1),
    ProjectName NVARCHAR(100) NOT NULL
);

CREATE TABLE Timesheet (
    TimesheetID INT IDENTITY(1,1) PRIMARY KEY,
    EmployeeID INT NOT NULL,
    WorkDate DATE NOT NULL DEFAULT GetDate(),
    ProjectID INT NOT NULL,
    HoursWorked DECIMAL(4,2) NOT NULL CHECK (HoursWorked >= 0 AND HoursWorked <= 24),
    DetailsJSON NVARCHAR(MAX),   -- JSON ca text
    CONSTRAINT emp
        FOREIGN KEY (EmployeeID) REFERENCES Employee(EmployeeID),   -- FOREIGN KEY 1
    CONSTRAINT proj
        FOREIGN KEY (ProjectID) REFERENCES Project(ProjectID),   -- FOREIGN KEY 2
    CONSTRAINT CK
        CHECK (DetailsJSON IS NULL OR ISJSON(DetailsJSON) = 1)   --cred ca putea fi scris si mai sus

);
Go

-- SAMPLE DATA
----------------------------------------------------

INSERT INTO Employee (FirstName, LastName, Email)
VALUES
('Ana', 'Popescu', 'ana.popescu@email.com'),
('Mihai', 'Ionescu', 'mihai.ionescu@email.com');

INSERT INTO Project (ProjectName)
VALUES
('Project A'),
('Project B');

INSERT INTO Timesheet (EmployeeID, ProjectID, HoursWorked, DetailsJSON)
VALUES
(1, 1, 8, '{"device":"laptop","location":"home"}'),
(1, 2, 6, '{"device":"desktop","location":"office"}'),
(2, 1, 7, '{"device":"laptop","location":"remote"}');
GO

--INDEX
-------------------------------------------------------------
Create Index IX_ProjectName on Project(ProjectName);
Create Index IX_Email on Employee(Email);
Go

--VIEW
-------------------------------------------------------------
CREATE VIEW vw_TimesheetDetails
AS
SELECT --un simplu select, care combina coloane din toate cele 3 tabele
    t.TimesheetID,
    e.LastName + ' ' + e.FirstName AS EmployeeName,
    p.ProjectName,
    t.WorkDate,
    t.HoursWorked
FROM Timesheet t
LEFT JOIN Employee e ON t.EmployeeID = e.EmployeeID --desi am folosit left join, dat fiind ca avem un foreign key, nu se schimba nimic, mereu vom avea un corespondent
JOIN Project p ON t.ProjectID = p.ProjectID;        --daca era invers, daca faceam from employee left join timesheet, rezultatul nu ar fi fost acelasi, ar fi existat posibile elemente nule
                                                    --tot ce se schimba este coloana EmployeeName din View, care acum poate lua valori nule. Fara Left join, not null ar fi fost inherited.
GO



CREATE VIEW dbo.EmployeeProjectHours -- un materialized view in sql server se numeste indexed view
WITH SCHEMABINDING
AS
SELECT --m-am gandit sa fac un view pe totalul de ore lucrate per persoana, per proiect.
    t.EmployeeID,
    t.ProjectID,
    COUNT_BIG(*) AS EntryCount, --necesar pentru engine, mi-am dat seama cu ajutorul lui GPT
    SUM(t.HoursWorked) AS TotalHours
    --DENSE_RANK() OVER (ORDER BY SUM(t.HoursWorked) DESC) AS HoursRank       
    --Am incercat mai sus un window function, dar aparent nu este permis in indexed view, ceea ce mi s-a parut interesant
FROM dbo.Timesheet AS t -- de asemenea, aparent este necesar sa adaugam prefixul de schema cand facem indexed views
GROUP BY
    t.EmployeeID,
    t.ProjectID;
GO

CREATE UNIQUE CLUSTERED INDEX IX_EmployeeProjectHours --un cluster index e folosit pe view-ul anterior. partea asta "materializeaza" efectiv, si ii da view-ului un spatiu fizic
ON dbo.EmployeeProjectHours(EmployeeID, ProjectID);
GO


--SELECTURI
---------------------------------------------------------
SELECT  --acelasi lucru ca mai sus, dar putin mai clean si fara indexed view, pentru a folosi un window function
        --view pe totalul de ore lucrate per persoana, per proiect.
    e.EmployeeID,
    CONCAT(e.FirstName, ' ', e.LastName) AS EmployeeName, --mai fancy
    SUM(t.HoursWorked) AS TotalHours,
    DENSE_RANK() OVER (ORDER BY SUM(t.HoursWorked) DESC) AS HoursRank
FROM Employee e
JOIN Timesheet t ON e.EmployeeID = t.EmployeeID
GROUP BY
    e.EmployeeID,
    e.FirstName,
    e.LastName;
GO

--arata angajatii, impreuna cu timesheet entries, daca exista
SELECT
    e.EmployeeID,
    CONCAT(e.FirstName, ' ', e.LastName) AS EmployeeName,
    t.TimesheetID,
    t.WorkDate,
    t.HoursWorked
FROM Employee e
LEFT JOIN Timesheet t    --de data asta, o relatie de 1 la 1 nu e garantata, se vor adauga elemente nule
    ON e.EmployeeID = t.EmployeeID;
GO

-- numarul total de ore per employee, din nou
SELECT
    e.EmployeeID,
    CONCAT(e.FirstName, ' ', e.LastName) AS EmployeeName,
    SUM(t.HoursWorked) AS TotalHours
FROM Employee e
JOIN Timesheet t
    ON e.EmployeeID = t.EmployeeID
GROUP BY
    e.EmployeeID,
    e.FirstName,
    e.LastName;
GO