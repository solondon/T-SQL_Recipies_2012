-- 30-1. Changing the Name of a Database Object
-- example 1
IF OBJECT_ID('dbo.Test', 'U') IS NOT NULL 
   DROP TABLE dbo.Test;
IF OBJECT_ID('dbo.MyTestTable', 'U') IS NOT NULL 
   DROP TABLE dbo.MyTestTable;

CREATE TABLE dbo.Test
       (
        Column1 INT,
        Column2 INT,
        CONSTRAINT UK_Test UNIQUE (Column1, Column2)
       );
GO
EXECUTE sp_rename 'dbo.Test', 'MyTestTable', 'object';
GO

-- example 2
EXECUTE sp_rename 'dbo.MyTestTable.Column1', 'NewColumnName', 'column';
GO

-- example 3
CREATE INDEX IX_1 ON dbo.MyTestTable (NewColumnName, Column2);
GO
EXECUTE sp_rename 'dbo.MyTestTable.IX_1', 'IX_NewIndexName', 'index';
GO

-- example 4
IF DB_ID('TSQLRecipes') IS NOT NULL 
   DROP DATABASE TSQLRecipes;
IF DB_ID('TSQL-Recipes') IS NOT NULL 
   DROP DATABASE [TSQL-Recipes];
CREATE DATABASE TSQLRecipes;
GO
SELECT  name
FROM    sys.databases
WHERE   name IN ('TSQLRecipes', 'TSQL-Recipes');
GO
EXECUTE sp_rename 'TSQLRecipes', 'TSQL-Recipes', 'database';
SELECT  name
FROM    sys.databases
WHERE   name IN ('TSQLRecipes', 'TSQL-Recipes');
GO

-- example 5
IF EXISTS ( SELECT  1
            FROM    sys.types
            WHERE   name = 'Age' ) 
   DROP TYPE dbo.Age;
IF EXISTS ( SELECT  1
            FROM    sys.types
            WHERE   name = 'PersonAge' ) 
   DROP TYPE dbo.PersonAge;
CREATE TYPE dbo.Age
FROM TINYINT NOT NULL;
SELECT  name
FROM    sys.types
WHERE   name IN ('Age', 'PersonAge');
EXECUTE sp_rename 'dbo.Age', 'PersonAge', 'userdatatype';
SELECT  name
FROM    sys.types
WHERE   name IN ('Age', 'PersonAge');


-- 30-2. Changing an Object�s Schema
CREATE TABLE Sales.TerminationReason
       (
        TerminationReasonID INT NOT NULL
                                PRIMARY KEY,
        TerminationReasonDESC VARCHAR(100) NOT NULL
       ); 
GO
ALTER SCHEMA HumanResources TRANSFER Sales.TerminationReason; 
GO
DROP TABLE HumanResources.TerminationReason;
GO


-- 30-3. Identifying Object Dependencies
USE master; 
GO
IF DB_ID('TSQLRecipe_A') IS NOT NULL 
   DROP DATABASE TSQLRecipe_A;
IF DB_ID('TSQLRecipe_B') IS NOT NULL 
   DROP DATABASE TSQLRecipe_B;

-- Create two new databases 
CREATE DATABASE TSQLRecipe_A;
GO
CREATE DATABASE TSQLRecipe_B;
GO

-- Create a new table in the first database
USE TSQLRecipe_A;
GO
CREATE TABLE dbo.Book
       (
        BookID INT NOT NULL
                   PRIMARY KEY,
        BookNM VARCHAR(50) NOT NULL
       ); 
GO

-- Create a procedure referencing an object 
-- in the second database 
USE TSQLRecipe_B; 
GO
CREATE PROCEDURE dbo.usp_SEL_Book
AS 
SELECT  BookID,
        BookNM
FROM    TSOLRecipe_A.dbo.Book; 
GO

SELECT  referenced_server_name,
        referenced_database_name,
        referenced_schema_name,
        referenced_entity_name,
        is_caller_dependent
FROM    sys.sql_expression_dependencies
WHERE   OBJECT_NAME(referencing_id) = 'usp_SEL_Book';
GO

USE TSQLRecipe_B; 
GO
CREATE PROCEDURE dbo.usp_SEL_Contract
AS 
SELECT  ContractID,
        ContractNM
FROM    TSQLRecipe_A.dbo.Contract;
GO

USE TSQLRecipe_B; 
GO
SELECT  referenced_server_name,
        referenced_database_name,
        referenced_schema_name,
        referenced_entity_name,
        is_caller_dependent
FROM    sys.sql_expression_dependencies
WHERE   OBJECT_NAME(referencing_id) = 'usp_SEL_Contract';


-- 30-4. Identifying Referencing and Referenced Entities
USE master;
GO
IF DB_ID('TSQLRecipe_A') IS NOT NULL 
   DROP DATABASE TSQLRecipe_A;
GO
CREATE DATABASE TSQLRecipe_A;
GO
USE TSQLRecipe_A;
GO
CREATE TABLE dbo.BookPublisher
       (
        BookPublisherlD INT NOT NULL
                            PRIMARY KEY,
        BookPublisherNM VARCHAR(30) NOT NULL
       ); 
GO
CREATE VIEW dbo.vw_BookPublisher
AS
SELECT  BookPublisherlD,
        BookPublisherNM
FROM    dbo.BookPublisher;
GO
CREATE PROCEDURE dbo.usp_INS_BookPublisher
       @BookPublisherNM VARCHAR(30)
AS 
INSERT  dbo.BookPublisher
        (BookPublisherNM)
VALUES  (@BookPublisherNM);
GO

SELECT  referenced_entity_name,
        referenced_minor_name
FROM    sys.dm_sql_referenced_entities('dbo.vw_BookPublisher', 'OBJECT');

SELECT  referencing_schema_name,
        referencing_entity_name
FROM    sys.dm_sql_referencing_entities('dbo.BookPublisher', 'OBJECT');


-- 30-5. Viewing an Object�s Definition
SELECT  OBJECT_DEFINITION(OBJECT_ID('dbo.usp_INS_BookPublisher'));

SELECT  OBJECT_DEFINITION(OBJECT_ID('sys.sp_depends'));

SELECT  definition
FROM    sys.all_sql_modules AS asm
WHERE   object_id = OBJECT_ID('dbo.usp_INS_BookPublisher');
GO

IF OBJECT_ID('dbo.EncryptedView', 'V') IS NOT NULL 
   DROP VIEW dbo.EncryptedView;
GO
CREATE VIEW dbo.EncryptedView
WITH ENCRYPTION
AS
SELECT  1 AS Result;
GO

SELECT  OBJECT_DEFINITION(OBJECT_ID('dbo.EncryptedView'));

SELECT  definition
FROM    sys.all_sql_modules AS asm
WHERE   object_id = OBJECT_ID('dbo.EncryptedView');



-- 30-6. Returning a Database Object�s Name, Schema Name, and Object ID
SELECT  object_id,
        OBJECT_SCHEMA_NAME(object_id) AS SchemaName,
        OBJECT_NAME(object_id) AS ObjectName
FROM    sys.tables
WHERE   object_id = OBJECT_ID('dbo.BookPublisher', 'U');

SELECT  t.object_id,
        s.name AS SchemaName,
        t.name AS ObjectName
FROM    sys.tables AS t
        JOIN sys.schemas AS s
            ON t.schema_id = s.schema_id
WHERE   s.name = 'dbo'
        AND t.name = 'BookPublisher';
