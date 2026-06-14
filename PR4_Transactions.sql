USE DeliveryServiceDB;
GO

-- ============================================================
-- Практична робота No4.1 — Транзакції
-- Варіант 12: Служба доставки малогабаритних вантажів
-- ============================================================

-- ===== Рівень 1: Базова транзакція з COMMIT =====

-- Таблиця журналу операцій
CREATE TABLE Logistics.OperationLog
(
    LogID INT PRIMARY KEY IDENTITY(1,1),
    OperationDate DATETIME NOT NULL DEFAULT GETDATE(),
    OperationType NVARCHAR(50) NOT NULL,
    TableName NVARCHAR(100) NOT NULL,
    RecordID INT,
    Description NVARCHAR(500)
);
GO

-- Базова транзакція: зміна статусу доставки + запис у журнал
BEGIN TRANSACTION;

UPDATE Logistics.Deliveries
SET Status = N'В дорозі'
WHERE DeliveryID = 1;

INSERT INTO Logistics.OperationLog (OperationType, TableName, RecordID, Description)
VALUES (N'UPDATE', N'Deliveries', 1, N'Статус доставки змінено на "В дорозі"');

COMMIT TRANSACTION;
GO

-- Перевірка
SELECT * FROM Logistics.Deliveries WHERE DeliveryID = 1;
SELECT * FROM Logistics.OperationLog;
GO

-- ===== Рівень 2: TRY...CATCH + ROLLBACK =====

-- Спроба списати більше товару, ніж є на складі
BEGIN TRY
    BEGIN TRANSACTION;

    DECLARE @ParcelID INT = 1;
    DECLARE @CurrentWeight DECIMAL(8,2);

    SELECT @CurrentWeight = WeightKg FROM CustomerService.Parcels WHERE ParcelID = @ParcelID;

    IF @CurrentWeight < 100
    BEGIN
        THROW 50020, N'Недостатньо ваги посилки для операції.', 1;
    END

    UPDATE CustomerService.Parcels
    SET WeightKg = WeightKg - 100
    WHERE ParcelID = @ParcelID;

    INSERT INTO Logistics.OperationLog (OperationType, TableName, RecordID, Description)
    VALUES (N'UPDATE', N'Parcels', @ParcelID, N'Списано 100 кг ваги');

    COMMIT TRANSACTION;
    PRINT N'Операцію успішно виконано';
END TRY
BEGIN CATCH
    ROLLBACK TRANSACTION;
    PRINT N'Транзакцію скасовано через помилку:';
    PRINT ERROR_MESSAGE();
END CATCH;
GO

-- Перевірка: дані мають залишитись без змін
SELECT ParcelID, WeightKg FROM CustomerService.Parcels WHERE ParcelID = 1;
SELECT * FROM Logistics.OperationLog;
GO

-- ===== Рівень 3: Рівні ізоляції =====

-- Експеримент 1: READ UNCOMMITTED (брудне читання)
-- Вікно 1 (запустіть в окремому запиті, НЕ фіксуйте транзакцію):
/*
USE DeliveryServiceDB;
GO

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
BEGIN TRANSACTION;

UPDATE CustomerService.Parcels
SET WeightKg = 999.99
WHERE ParcelID = 1;

-- НЕ ВИКОНУЙТЕ COMMIT — переходьте у Вікно 2
-- Після перевірки у Вікні 2:
ROLLBACK TRANSACTION;
GO
*/

-- Вікно 2 (запустіть в окремому запиті, ПОКИ Вікно 1 відкрите):
/*
USE DeliveryServiceDB;
GO

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
SELECT ParcelID, WeightKg FROM CustomerService.Parcels WHERE ParcelID = 1;
-- Буде видно 999.99 (брудне читання — Dirty Read)
GO
*/

-- Експеримент 2: READ COMMITTED (запобігає брудному читанню)
-- Вікно 1:
/*
USE DeliveryServiceDB;
GO

SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
BEGIN TRANSACTION;

UPDATE CustomerService.Parcels
SET WeightKg = 777.77
WHERE ParcelID = 1;

-- НЕ ВИКОНУЙТЕ COMMIT — переходьте у Вікно 2
-- Вікно 2 буде ЧЕКАТИ, поки Вікно 1 не виконає COMMIT
COMMIT TRANSACTION;
GO
*/

-- Вікно 2 (буде заблоковано, доки Вікно 1 не виконає COMMIT):
/*
USE DeliveryServiceDB;
GO

SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
SELECT ParcelID, WeightKg FROM CustomerService.Parcels WHERE ParcelID = 1;
-- Чекає на завершення транзакції Вікна 1,
-- потім покаже актуальне значення (не 777.77, якщо Вікно 1 зробило ROLLBACK)
GO
*/

-- Експеримент 3: SERIALIZABLE (повна ізоляція)
-- Вікно 1:
/*
USE DeliveryServiceDB;
GO

SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
BEGIN TRANSACTION;

SELECT * FROM CustomerService.Parcels WHERE WeightKg > 0;

-- Тепер Вікно 2 не зможе додати нову посилку, яка б потрапила в цей діапазон
-- (Range Lock). Перевірте у Вікні 2.

COMMIT TRANSACTION;
GO
*/

-- Вікно 2 (буде заблоковано, доки Вікно 1 не закриється):
/*
USE DeliveryServiceDB;
GO

INSERT INTO CustomerService.Parcels (TrackingNumber, WeightKg, CustomerID, RecipientAddress)
VALUES ('UA9999999999', 5.0, 1, N'Тестова адреса');
-- Блокується через range lock, поки Вікно 1 не виконає COMMIT
GO
*/

GO
