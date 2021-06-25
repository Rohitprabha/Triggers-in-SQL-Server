select * from Employee
select * from EmployeesAudit

--restrict all the DML operations on the Employee
CREATE TRIGGER trAllDMLOperationsOnEmployee 
ON Employee
FOR INSERT, UPDATE, DELETE
AS
BEGIN
  PRINT 'YOU CANNOT PERFORM DML OPERATION'
  ROLLBACK TRANSACTION
END

update Employee set EmpName = 'sri', Salary = 40000, DeptID=10 where EmpID = 104

DROP TRIGGER trAllDMLOperationsOnEmployee


--after insert
Create Trigger tr_Employee_ForInsert on Employee For insert
As
Begin
	Declare @EmpID int
	select @EmpID = EmpID from inserted
	insert into EmployeesAudit values(@EmpID,'New Employee with ID= '+ Cast(@EmpID as nvarchar(5)) + 'is added at '+ Cast(Getdate() as nvarchar(20)))
END

insert into Employee values(102,'Krishna',20000,11,'HYD')
select * from Employee
select * from EmployeesAudit

--after delete

Create Trigger tr_Employee_ForDelete on Employee For delete
As
Begin
	Declare @EmpID int
	select @EmpID = EmpID from deleted
	insert into EmployeesAudit values(@EmpID,'An Existing employee with ID= '+ Cast(@EmpID as nvarchar(5)) + 'is deleted at '+ Cast(Getdate() as nvarchar(20)))
END

delete Employee where EmpID=102

select * from Employee
select * from EmployeesAudit

--after update
Create Trigger tr_Employee_ForUpdate on Employee For Update
As
Begin
	select * from deleted
	select * from inserted
END

update Employee set EmpName = 'sri', Salary = 40000, DeptID=10 where EmpID = 104

drop trigger tr_Employee_ForUpdate

create TRIGGER tr_Employee_ForUpdate
ON Employee
FOR Update
AS
BEGIN
      -- Declare the variables to hold old and updated data
      DECLARE @ID INT
      DECLARE @Old_Name VARCHAR(200), @New_Name VARCHAR(200)
      DECLARE @Old_Salary INT, @New_Salary INT
      DECLARE @Old_DepartmentId INT, @New_DepartmentId INT
      DECLARE @Old_EmpAddress VARCHAR(200), @New_EmpAddress VARCHAR(200)

      -- Declare Variable to build the audit string
      DECLARE @AuditData VARCHAR(MAX)
      
      -- Store the updated data into a temporary table
      SELECT *
      INTO #UpdatedDataTempTable
      FROM INSERTED
     
      -- Loop thru the records in the UpdatedDataTempTable temp table
      WHILE(Exists(SELECT EmpID FROM #UpdatedDataTempTable))
      BEGIN
            --Initialize the audit string to empty string
            SET @AuditData = ''
           
            -- Select first row data from temp table
            SELECT TOP 1 @ID = EmpID, 
              @New_Name = EmpName, 
              @New_Salary = Salary,
              @New_DepartmentId = DeptId,
			  @New_EmpAddress = EmpAddress
            FROM #UpdatedDataTempTable
           
            -- Select the corresponding row from deleted table
            SELECT @Old_Name = EmpName, 
              @Old_Salary = Salary,
              @Old_DepartmentId = DeptId,
			  @Old_EmpAddress = EmpAddress
            FROM DELETED WHERE EmpID = @ID
   
      -- Build the audit data dynamically           
            Set @AuditData = 'Employee with Id = ' + CAST(@ID AS VARCHAR(6)) + ' changed'
      -- If old name and new name are not same, then its changed
            IF(@Old_Name <> @New_Name)
      BEGIN
                  Set @AuditData = @AuditData + ' Name from ' + @Old_Name + ' to ' + @New_Name
      END
                
      -- If old Salary and new Salary are not same, then its changed  
            IF(@Old_Salary <> @New_Salary)
      BEGIN
                  Set @AuditData = @AuditData + ' Salary from ' + Cast(@Old_Salary AS VARCHAR(10))+ ' to ' 
            + Cast(@New_Salary AS VARCHAR(10))
      END
            
      -- If old Department ID and new Department ID are not same, then its changed      
      IF(@Old_DepartmentId <> @New_DepartmentId)
      BEGIN
                  Set @AuditData = @AuditData + ' DepartmentId from ' + Cast(@Old_DepartmentId AS VARCHAR(10))+ ' to ' 
              + Cast(@New_DepartmentId AS VARCHAR(10))
            END

	  -- If old Address and new Address are not same, then its changed     
      IF(@Old_EmpAddress <> @New_EmpAddress)
      BEGIN
                  Set @AuditData = @AuditData + ' Address from ' + @Old_EmpAddress + ' to ' + @New_EmpAddress
      END

      -- Then Insert the audit data into the EmployeeAudit table
            INSERT INTO EmployeesAudit(EmpID, AuditData) VALUES(@ID, @AuditData)
            
            -- Delete the current row from temp table, so we can move to the next row
            DELETE FROM #UpdatedDataTempTable WHERE EmpID = @ID
      End
End

update Employee set EmpName = 'sri', Salary = 40000, DeptID=10 where EmpID = 104

select * from Employee
select * from EmployeesAudit

insert into Employee values(102,'Krishna',20000,11,'HYD')


--Drop
DROP TRIGGER tr_Employee_ForInsert
DROP TRIGGER tr_Employee_ForUpdate
DROP TRIGGER tr_Employee_ForDelete

select * from Employee
select * from EmployeesAudit

--Instead of insert trigger
CREATE VIEW vwEmployeesByDepartment AS SELECT emp.EmpID, emp.EmpName, emp.Salary, emp.EmpAddress, emp.DeptID,
dept.DeptName AS DepartmentName FROM Employee emp INNER JOIN Department dept ON emp.DeptID = dept.DeptID

select * from vwEmployeesByDepartment
insert into vwEmployeesByDepartment values(110,'Mandy',40000,'BVRM',12,'HR')	--error because complex view doesn't support DML operations.

create Trigger tr_vwEmployeesByDepartment_InsteadOfInsert on vwEmployeesByDepartment instead of insert
As
Begin
	select * from inserted
	select * from deleted
END

insert into vwEmployeesByDepartment values(110,'Mandy',40000,'BVRM',12,'HR')
select * from vwEmployeesByDepartment

alter Trigger tr_vwEmployeesByDepartment_InsteadOfInsert on vwEmployeesByDepartment instead of insert
As
Begin
	declare @DeptID int
	select @DeptID = Department.DeptID from  Department join inserted on inserted.DepartmentName = Department.DeptName
	if(@DeptID is NULL)
	begin
		raiserror('Invalid Department Name',16,1)
		return
	end
	insert into Employee(EmpID,EmpName,Salary,DeptID) select EmpID,EmpName,Salary,@DeptID from inserted
END
insert into vwEmployeesByDepartment values(113,'Mandy',40000,'BVRM',12,'IT')		
insert into vwEmployeesByDepartment values(114,'Messy',50000,'BVRM',12,'c#')	----Not inserted because c# is not present in department table
select * from EMployee
select * from Department
select * from vwEmployeesByDepartment

--instead of update Trigger
update vwEmployeeDetails set  Salary = 40000, DeptName='IT' where EmpID=102	--error

CREATE VIEW vwEmployeeDetails
AS
SELECT emp.EmpID, emp.EmpName, Salary, dept.DeptName
FROM Employee emp
INNER JOIN Department dept
ON emp.DeptID = dept.DeptID

select * from vwEmployeeDetails

CREATE TRIGGER tr_vwEmployeeDetails_InsteadOfUpdate
ON  vwEmployeeDetails
INSTEAD OF UPDATE
AS
BEGIN
  -- if EmployeeId is updated
  IF(UPDATE(EmpID))
  BEGIN
    RAISERROR('Id cannot be changed', 16, 1)
    RETURN
  END
 
  -- If Department Name is updated
  IF(UPDATE(DeptName)) 
  BEGIN
    DECLARE @DepartmentID INT
    SELECT @DepartmentID = dept.DeptID
    FROM Department dept
    INNER JOIN INSERTED inst
    ON dept.DeptName = inst.DeptName
  
    IF(@DepartmentID is NULL )
    BEGIN
      RAISERROR('Invalid Department Name', 16, 1)
      RETURN
    END
  
    UPDATE Employee set DeptID = @DepartmentID
    FROM INSERTED
    INNER JOIN Employee
    on Employee.EmpID = inserted.EmpID
  End
 
  -- If Salary is updated
  IF(UPDATE(Salary))
  BEGIN
    UPDATE Employee SET Salary = inserted.Salary
    FROM INSERTED
    INNER JOIN Employee
    ON Employee.EmpID = INSERTED.EmpID
  END

  -- If Name is updated
  IF(UPDATE(EmpName))
  BEGIN
    UPDATE Employee SET EmpName = inserted.EmpName
    FROM INSERTED
    INNER JOIN Employee
    ON Employee.EmpID = INSERTED.EmpID
  END
END

update vwEmployeeDetails set  Salary = 40000, DeptName='IT' where EmpID=102
select * from vwEmployeeDetails

--Instead Of Delete Trigger

CREATE VIEW vwEmployeeDetails2
AS
SELECT emp.EmpID, emp.EmpName, Salary, dept.DeptName
FROM Employee emp
INNER JOIN Department dept
ON emp.DeptID = dept.DeptID

select * from vwEmployeeDetails2


DELETE FROM vwEmployeeDetails2 WHERE EmpID=106			--error

CREATE TRIGGER tr_vwEmployeeDetails_InsteadOfDelete
ON vwEmployeeDetails2
INSTEAD OF DELETE
AS
BEGIN
  -- Using Inner Join
  DELETE Employee FROM Employee emp INNER JOIN DELETED del ON emp.EmpID = del.EmpID
  -- Using the Subquery
  -- DELETE FROM Employee  WHERE EmpID IN (SELECT EmpID FROM DELETED)
END

DELETE FROM vwEmployeeDetails2 WHERE EmpID=106

select * from vwEmployeeDetails2

select * from Employee

--DDL Triggers

CREATE  TRIGGER  trForCreateTable 
ON DATABASE
FOR CREATE_TABLE
AS
BEGIN
  PRINT 'New Table Created'
END

CREATE TRIGGER  trForDropTable
ON DATABASE
FOR DROP_TABLE
AS
BEGIN
  PRINT 'Table Dropped'
END

create table test(Id int)
drop table test

--To drop a Database Scoped DDL trigger
DROP TRIGGER trForCreateTable ON DATABASE
DROP TRIGGER trForDropTable ON DATABASE

--creating, altering, or dropping tables from a specific database using a single trigger.
CREATE TRIGGER trDDLEvents
ON DATABASE
FOR CREATE_TABLE, ALTER_TABLE, DROP_TABLE
AS
BEGIN 
   PRINT 'You have just created, altered or dropped a table'
END

create table test(Id int)
DROP table test

--restrict creating a new table on a specific database.
USE Test
GO
CREATE  TRIGGER  trRestrictCreateTable 
ON DATABASE
FOR CREATE_TABLE
AS
BEGIN
	ROLLBACK
    PRINT 'YOU CANNOT CREATE A TABLE IN THIS DATABASE'
END

create table test(Id int)

--restrict ALTER operations on a specific database.
CREATE TRIGGER  trRestrictAlterTable  
ON DATABASE
FOR  ALTER_TABLE
AS
BEGIN
  PRINT 'YOU CANNOT ALTER TABLES'
  ROLLBACK TRANSACTION
END

alter table test alter column Id varchar(50)

--restrict dropping the tables from a specific database.
CREATE TRIGGER  trRestrictDropTable
ON DATABASE
FOR DROP_TABLE
AS
BEGIN
  PRINT 'YOU CANNOT DROP TABLES'
  ROLLBACK TRANSACTION
END

DROP table test

--To disable a Database Scoped DDL trigger
DISABLE TRIGGER trRestrictCreateTable ON DATABASE

create table test(Id int)

DISABLE TRIGGER trRestrictAlterTable ON DATABASE

alter table test alter column Id varchar(50)

DISABLE TRIGGER trRestrictDropTable ON DATABASE

DROP table test

--To enable a Database Scoped DDL trigger
ENABLE TRIGGER trRestrictCreateTable ON DATABASE

create table test(Id int)

--To Rename a Table
CREATE TRIGGER trRename
ON DATABASE
FOR RENAME
AS
BEGIN
    PRINT 'You just renamed Database'
END

create table test(Id int)
sp_rename 'test', 'TestChanged'

--To Create a Server-Scoped DDL Trigger
CREATE TRIGGER trServerScopedDDLTrigger
ON ALL SERVER
FOR CREATE_TABLE, ALTER_TABLE, DROP_TABLE
AS
BEGIN 
   PRINT 'You cannot create, alter or drop a table in any database of this server'
   ROLLBACK TRANSACTION
END

--To disable Server-Scoped DDL trigger
DISABLE TRIGGER trServerScopedDDLTrigger ON ALL SERVER

--To enable Server-Scoped DDL trigger
ENABLE TRIGGER trServerScopedDDLTrigger ON ALL SERVER 

--To drop Server-scoped DDL trigger
DROP TRIGGER trServerScopedDDLTrigger ON ALL SERVER