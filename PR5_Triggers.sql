USE DeliveryServiceDB;
GO

-- ============================================================
-- Практична робота No5.1 — Тригери
-- Варіант 12: Служба доставки малогабаритних вантажів
-- ============================================================

-- ===== Рівень 1: Система аудиту (AFTER UPDATE) =====

-- Таблиця аудиту
CREATE TABLE Logistics.AuditLog
(
    AuditID INT PRIMARY KEY IDENTITY(1,1),
    TableName NVARCHAR(100) NOT NULL,
    Operation NVARCHAR(20) NOT NULL,
    RecordID INT NOT NULL,
    OldValue NVARCHAR(500),
    NewValue NVARCHAR(500),
    ChangeDate DATETIME NOT NULL DEFAULT GETDATE(),
    UserName NVARCHAR(128) NOT NULL DEFAULT SUSER_NAME()
);
GO

-- Тригер аудиту для Deliveries (AFTER UPDATE)
CREATE TRIGGER Logistics.TR_Deliveries_Audit
ON Logistics.Deliveries
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO Logistics.AuditLog (TableName, Operation, RecordID, OldValue, NewValue)
    SELECT
        N'Deliveries',
        N'UPDATE',
        d.DeliveryID,
        N'Status: ' + ISNULL(d.Status, N'') + N', Cost: ' + ISNULL(CAST(d.Cost AS NVARCHAR), N''),
        N'Status: ' + ISNULL(i.Status, N'') + N', Cost: ' + ISNULL(CAST(i.Cost AS NVARCHAR), N'')
    FROM deleted d
    JOIN inserted i ON d.DeliveryID = i.DeliveryID
    WHERE d.Status <> i.Status OR d.Cost <> i.Cost;
END;
GO

-- Тригер аудиту для Parcels (AFTER UPDATE)
CREATE TRIGGER CustomerService.TR_Parcels_Audit
ON CustomerService.Parcels
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO Logistics.AuditLog (TableName, Operation, RecordID, OldValue, NewValue)
    SELECT
        N'Parcels',
        N'UPDATE',
        d.ParcelID,
        N'Status: ' + ISNULL(d.Status, N'') + N', Weight: ' + ISNULL(CAST(d.WeightKg AS NVARCHAR), N''),
        N'Status: ' + ISNULL(i.Status, N'') + N', Weight: ' + ISNULL(CAST(i.WeightKg AS NVARCHAR), N'')
    FROM deleted d
    JOIN inserted i ON d.ParcelID = i.ParcelID
    WHERE d.Status <> i.Status OR d.WeightKg <> i.WeightKg;
END;
GO

-- ===== Рівень 2: Бізнес-правила (AFTER INSERT) =====

-- Тригер: при додаванні нової доставки — автоматично оновлювати статус посилки
CREATE TRIGGER Logistics.TR_Deliveries_AfterInsert
ON Logistics.Deliveries
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE CustomerService.Parcels
    SET Status = N'Передано в доставку'
    WHERE ParcelID IN (SELECT ParcelID FROM inserted);
END;
GO

-- Тригер: заборона зміни статусу, якщо доставка вже завершена
CREATE TRIGGER Logistics.TR_Deliveries_PreventReopen
ON Logistics.Deliveries
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (
        SELECT 1
        FROM deleted d
        WHERE d.Status = N'Доставлено'
          AND EXISTS (SELECT 1 FROM inserted i WHERE i.DeliveryID = d.DeliveryID AND i.Status <> d.Status)
    )
    BEGIN
        ROLLBACK TRANSACTION;
        THROW 50030, N'Неможливо змінити доставку, яка вже має статус "Доставлено".', 1;
    END
END;
GO

-- ===== Рівень 3: INSTEAD OF + логічне видалення + часова заборона =====

-- Тригер: логічне видалення клієнтів (замість фізичного DELETE)
ALTER TABLE CustomerService.Customers ADD IsActive BIT NOT NULL DEFAULT 1;
GO

CREATE TRIGGER CustomerService.TR_Customers_SoftDelete
ON CustomerService.Customers
INSTEAD OF DELETE
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE CustomerService.Customers
    SET IsActive = 0
    WHERE CustomerID IN (SELECT CustomerID FROM deleted);

    PRINT N'Клієнта деактивовано (логічне видалення).';
END;
GO

-- Тригер: заборона змін у неробочий час (20:00 — 08:00)
CREATE TRIGGER Logistics.TR_Deliveries_WorkingHours
ON Logistics.Deliveries
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @CurrentHour INT = DATEPART(HOUR, GETDATE());

    IF @CurrentHour >= 20 OR @CurrentHour < 8
    BEGIN
        ROLLBACK TRANSACTION;
        THROW 50040, N'Операції з доставками дозволені лише з 08:00 до 20:00.', 1;
    END
END;
GO

-- ===== Тестування тригерів =====

-- Тест 1: Оновлення статусу доставки (перевірка аудиту)
PRINT N'--- Тест 1: Аудит AFTER UPDATE ---';
UPDATE Logistics.Deliveries
SET Status = N'В дорозі'
WHERE DeliveryID = 1;

SELECT * FROM Logistics.AuditLog;
GO

-- Тест 2: Спроба змінити доставлену доставку (помилка)
PRINT N'--- Тест 2: Заборона зміни статусу "Доставлено" ---';
UPDATE Logistics.Deliveries
SET Status = N'Доставлено'
WHERE DeliveryID = 1;

UPDATE Logistics.Deliveries
SET Status = N'В обробці'
WHERE DeliveryID = 1;
GO

-- Тест 3: Логічне видалення клієнта
PRINT N'--- Тест 3: INSTEAD OF DELETE (логічне видалення) ---';
DELETE FROM CustomerService.Customers WHERE CustomerID = 1;

SELECT CustomerID, FullName, IsActive FROM CustomerService.Customers WHERE CustomerID = 1;
GO

-- Тест 4: Додавання нової доставки (авто-оновлення статусу посилки)
PRINT N'--- Тест 4: AFTER INSERT — автооновлення статусу ---';
INSERT INTO Logistics.Deliveries (ParcelID, EmployeeID, Status, Cost)
VALUES (1, 1, N'В обробці', 500.00);

SELECT ParcelID, Status FROM CustomerService.Parcels WHERE ParcelID = 1;
GO

GO
