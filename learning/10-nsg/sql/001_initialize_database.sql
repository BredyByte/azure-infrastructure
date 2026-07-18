/*
  Run this script as the Microsoft Entra administrator after Terraform creates
  the Azure SQL server and database. It is safe to run more than once.
*/

IF OBJECT_ID(N'dbo.Messages', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Messages (
        Id INT NOT NULL PRIMARY KEY,
        Message NVARCHAR(255) NOT NULL
    );
END;
GO

IF NOT EXISTS (SELECT 1 FROM dbo.Messages WHERE Id = 1)
    INSERT INTO dbo.Messages (Id, Message) VALUES (1, N'Welcome David!');

IF NOT EXISTS (SELECT 1 FROM dbo.Messages WHERE Id = 2)
    INSERT INTO dbo.Messages (Id, Message) VALUES (2, N'Azure SQL works!');

IF NOT EXISTS (SELECT 1 FROM dbo.Messages WHERE Id = 3)
    INSERT INTO dbo.Messages (Id, Message) VALUES (3, N'Terraform deployed this infrastructure.');
GO

IF NOT EXISTS (
    SELECT 1
    FROM sys.database_principals
    WHERE name = N'app-dev-helloworld'
)
BEGIN
    CREATE USER [app-dev-helloworld] FROM EXTERNAL PROVIDER;
END;
GO

GRANT SELECT ON OBJECT::dbo.Messages TO [app-dev-helloworld];
GO
