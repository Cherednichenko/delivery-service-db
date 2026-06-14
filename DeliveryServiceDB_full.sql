USE master;
GO

IF DB_ID('DeliveryServiceDB') IS NOT NULL
BEGIN
    ALTER DATABASE DeliveryServiceDB SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE DeliveryServiceDB;
END
GO

CREATE DATABASE DeliveryServiceDB;
GO

USE DeliveryServiceDB;
GO

CREATE SCHEMA CustomerService;
GO
CREATE SCHEMA Logistics;
GO
CREATE SCHEMA HumanResources;
GO
CREATE SCHEMA Finance;
GO

CREATE TABLE HumanResources.Employees
(
    EmployeeID INT PRIMARY KEY IDENTITY(1,1),
    FullName NVARCHAR(200) NOT NULL,
    Position NVARCHAR(100) NOT NULL,
    Phone NVARCHAR(20) UNIQUE,
    HireDate DATE NOT NULL DEFAULT GETDATE()
);
GO

CREATE TABLE CustomerService.Customers
(
    CustomerID INT PRIMARY KEY IDENTITY(1,1),
    FullName NVARCHAR(200) NOT NULL,
    Phone NVARCHAR(20) UNIQUE,
    Email NVARCHAR(100),
    Address NVARCHAR(300) NOT NULL
);
GO

CREATE TABLE CustomerService.Parcels
(
    ParcelID INT PRIMARY KEY IDENTITY(1,1),
    TrackingNumber NVARCHAR(30) UNIQUE NOT NULL,
    WeightKg DECIMAL(8,2) NOT NULL CHECK (WeightKg > 0),
    Description NVARCHAR(500),
    Status NVARCHAR(50) NOT NULL DEFAULT N'Прийнято',
    CustomerID INT NOT NULL,
    RecipientAddress NVARCHAR(300) NOT NULL,
    CONSTRAINT FK_Parcels_Customers FOREIGN KEY (CustomerID)
        REFERENCES CustomerService.Customers(CustomerID)
);
GO

CREATE TABLE Logistics.Deliveries
(
    DeliveryID INT PRIMARY KEY IDENTITY(1,1),
    ParcelID INT NOT NULL,
    EmployeeID INT NOT NULL,
    PickupDate DATETIME NOT NULL DEFAULT GETDATE(),
    DeliveryDate DATETIME,
    Status NVARCHAR(50) NOT NULL DEFAULT N'В обробці',
    Cost DECIMAL(10,2) CHECK (Cost >= 0),
    CONSTRAINT FK_Deliveries_Parcels FOREIGN KEY (ParcelID)
        REFERENCES CustomerService.Parcels(ParcelID),
    CONSTRAINT FK_Deliveries_Employees FOREIGN KEY (EmployeeID)
        REFERENCES HumanResources.Employees(EmployeeID)
);
GO

CREATE TABLE Finance.PaymentLog
(
    PaymentID INT PRIMARY KEY IDENTITY(1,1),
    DeliveryID INT NOT NULL,
    Amount DECIMAL(10,2) NOT NULL CHECK (Amount > 0),
    PaymentDate DATETIME NOT NULL DEFAULT GETDATE(),
    PaymentMethod NVARCHAR(50) NOT NULL,
    CONSTRAINT FK_PaymentLog_Deliveries FOREIGN KEY (DeliveryID)
        REFERENCES Logistics.Deliveries(DeliveryID)
);
GO

CREATE PROCEDURE CustomerService.GetAllCustomers
AS
BEGIN
    SELECT CustomerID, FullName, Phone, Email, Address
    FROM CustomerService.Customers
    ORDER BY FullName;
END;
GO

CREATE PROCEDURE Logistics.SearchParcelByTracking
    @TrackingNumber NVARCHAR(30)
AS
BEGIN
    SELECT p.ParcelID, p.TrackingNumber, p.WeightKg, p.Status,
           c.FullName AS CustomerName, p.RecipientAddress
    FROM CustomerService.Parcels p
    JOIN CustomerService.Customers c ON p.CustomerID = c.CustomerID
    WHERE p.TrackingNumber LIKE '%' + @TrackingNumber + '%';
END;
GO

CREATE PROCEDURE CustomerService.GetCustomerDeliveries
    @CustomerID INT,
    @StartDate DATE = NULL,
    @EndDate DATE = NULL
AS
BEGIN
    SELECT d.DeliveryID, p.TrackingNumber, d.Status, d.Cost,
           d.PickupDate, d.DeliveryDate
    FROM Logistics.Deliveries d
    JOIN CustomerService.Parcels p ON d.ParcelID = p.ParcelID
    WHERE p.CustomerID = @CustomerID
      AND (@StartDate IS NULL OR d.PickupDate >= @StartDate)
      AND (@EndDate IS NULL OR d.PickupDate <= @EndDate)
    ORDER BY d.PickupDate DESC;
END;
GO

CREATE PROCEDURE Logistics.GetDeliveryReport
    @StartDate DATE = NULL,
    @EndDate DATE = NULL
AS
BEGIN
    SELECT
        e.FullName AS CourierName,
        COUNT(d.DeliveryID) AS TotalDeliveries,
        SUM(d.Cost) AS TotalRevenue,
        AVG(d.Cost) AS AvgCost
    FROM Logistics.Deliveries d
    JOIN CustomerService.Parcels p ON d.ParcelID = p.ParcelID
    JOIN HumanResources.Employees e ON d.EmployeeID = e.EmployeeID
    LEFT JOIN Finance.PaymentLog pl ON d.DeliveryID = pl.DeliveryID
    WHERE (@StartDate IS NULL OR d.PickupDate >= @StartDate)
      AND (@EndDate IS NULL OR d.PickupDate <= @EndDate)
    GROUP BY e.FullName
    HAVING COUNT(d.DeliveryID) > 0
    ORDER BY TotalRevenue DESC;
END;
GO

CREATE PROCEDURE Logistics.AddParcel
    @TrackingNumber NVARCHAR(30),
    @WeightKg DECIMAL(8,2),
    @Description NVARCHAR(500) = NULL,
    @CustomerID INT,
    @RecipientAddress NVARCHAR(300)
AS
BEGIN
    IF EXISTS (SELECT 1 FROM CustomerService.Parcels WHERE TrackingNumber = @TrackingNumber)
    BEGIN
        THROW 50001, N'Посилка з таким трек-номером вже існує.', 1;
        RETURN;
    END

    INSERT INTO CustomerService.Parcels (TrackingNumber, WeightKg, Description, CustomerID, RecipientAddress)
    VALUES (@TrackingNumber, @WeightKg, @Description, @CustomerID, @RecipientAddress);

    PRINT N'Посилку додано. ID: ' + CAST(SCOPE_IDENTITY() AS NVARCHAR);
END;
GO

CREATE PROCEDURE Logistics.UpdateDeliveryStatus
    @DeliveryID INT,
    @NewStatus NVARCHAR(50)
AS
BEGIN
    IF NOT EXISTS (SELECT 1 FROM Logistics.Deliveries WHERE DeliveryID = @DeliveryID)
    BEGIN
        THROW 50002, N'Доставку з таким ID не знайдено.', 1;
        RETURN;
    END

    UPDATE Logistics.Deliveries
    SET Status = @NewStatus,
        DeliveryDate = CASE WHEN @NewStatus = N'Доставлено' THEN GETDATE() ELSE DeliveryDate END
    WHERE DeliveryID = @DeliveryID;
END;
GO

CREATE PROCEDURE Logistics.DeleteParcel
    @ParcelID INT
AS
BEGIN
    IF NOT EXISTS (SELECT 1 FROM CustomerService.Parcels WHERE ParcelID = @ParcelID)
    BEGIN
        PRINT N'Посилку з таким ID не знайдено.';
        RETURN;
    END

    IF EXISTS (SELECT 1 FROM Logistics.Deliveries WHERE ParcelID = @ParcelID)
    BEGIN
        THROW 50003, N'Неможливо видалити: існують пов''язані доставки.', 1;
        RETURN;
    END

    DELETE FROM CustomerService.Parcels WHERE ParcelID = @ParcelID;
    PRINT N'Посилку видалено.';
END;
GO

CREATE FUNCTION Logistics.CalculateDeliveryCost
(
    @WeightKg DECIMAL(8,2),
    @DistanceKm DECIMAL(10,2) = 10,
    @IsExpress BIT = 0
)
RETURNS DECIMAL(10,2)
AS
BEGIN
    DECLARE @BaseRate DECIMAL(10,2) = 50.00;
    DECLARE @Total DECIMAL(10,2);

    SET @Total = @BaseRate + (@WeightKg * 15.00) + (@DistanceKm * 5.00);

    IF @IsExpress = 1
        SET @Total = @Total * 1.5;

    RETURN @Total;
END;
GO

CREATE PROCEDURE Logistics.ProcessDelivery
    @ParcelID INT,
    @EmployeeID INT,
    @DistanceKm DECIMAL(10,2) = 10,
    @IsExpress BIT = 0
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;

        IF NOT EXISTS (SELECT 1 FROM CustomerService.Parcels WHERE ParcelID = @ParcelID)
            THROW 50010, N'Посилку не знайдено.', 1;

        IF NOT EXISTS (SELECT 1 FROM HumanResources.Employees WHERE EmployeeID = @EmployeeID)
            THROW 50011, N'Працівника не знайдено.', 1;

        DECLARE @WeightKg DECIMAL(8,2);
        DECLARE @Cost DECIMAL(10,2);

        SELECT @WeightKg = WeightKg FROM CustomerService.Parcels WHERE ParcelID = @ParcelID;
        SET @Cost = Logistics.CalculateDeliveryCost(@WeightKg, @DistanceKm, @IsExpress);

        INSERT INTO Logistics.Deliveries (ParcelID, EmployeeID, Status, Cost)
        VALUES (@ParcelID, @EmployeeID, N'В обробці', @Cost);

        DECLARE @DeliveryID INT = SCOPE_IDENTITY();

        UPDATE CustomerService.Parcels
        SET Status = N'Передано в доставку'
        WHERE ParcelID = @ParcelID;

        INSERT INTO Finance.PaymentLog (DeliveryID, Amount, PaymentMethod)
        VALUES (@DeliveryID, @Cost, N'Готівка');

        COMMIT TRANSACTION;
        PRINT N'Доставку успішно оформлено. DeliveryID = ' + CAST(@DeliveryID AS NVARCHAR);
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        DECLARE @ErrMsg NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR(@ErrMsg, 16, 1);
    END CATCH
END;
GO

INSERT INTO CustomerService.Customers (FullName, Phone, Address)
VALUES (N'Іван Петренко', '+380501234567', N'Київ, вул. Хрещатик, 1');

INSERT INTO HumanResources.Employees (FullName, Position, Phone)
VALUES (N'Олег Коваль', N'Кур''єр', '+380671234567');

EXEC Logistics.AddParcel
    @TrackingNumber = 'UA1234567890',
    @WeightKg = 2.5,
    @CustomerID = 1,
    @RecipientAddress = N'Львів, вул. Франка, 10';

EXEC Logistics.ProcessDelivery @ParcelID = 1, @EmployeeID = 1, @DistanceKm = 540, @IsExpress = 0;

EXEC Logistics.GetDeliveryReport;

EXEC Logistics.SearchParcelByTracking @TrackingNumber = 'UA123';

EXEC Logistics.UpdateDeliveryStatus @DeliveryID = 1, @NewStatus = N'Доставлено';

GO
