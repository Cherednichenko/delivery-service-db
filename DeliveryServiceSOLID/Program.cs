using DeliveryServiceSOLID.AntiPattern;
using DeliveryServiceSOLID.Interfaces;
using DeliveryServiceSOLID.Models;
using DeliveryServiceSOLID.Repositories;
using DeliveryServiceSOLID.Services;

Console.OutputEncoding = System.Text.Encoding.UTF8;

Console.WriteLine("===========================================");
Console.WriteLine("  SOLID Principles — Delivery Service Demo");
Console.WriteLine("  Variant 12: Small Cargo Delivery Service");
Console.WriteLine("===========================================\n");

// ===== DEMO 1: ANTI-PATTERN (Before SOLID) =====
Console.WriteLine("--- DEMO 1: Anti-Pattern (SRP + DIP violation) ---\n");

var badManager = new DeliveryManager();
badManager.ProcessDelivery("UA-ANTI-001", 5.0, 1, "Address A", 50);
badManager.ProcessDelivery("UA-ANTI-002", 10.0, 2, "Address B", 100);
badManager.ShowReport();

Console.WriteLine("\nProblems: One class handles data storage, calculation, logging, and display.\n");

// ===== DEMO 2: SOLID REFACTORING =====
Console.WriteLine("--- DEMO 2: SOLID Architecture ---\n");

// SRP + DIP: Dependencies injected via constructor
IParcelRepository parcelRepo = new InMemoryParcelRepository();
IDeliveryRepository deliveryRepo = new InMemoryDeliveryRepository();
ILogger logger = new ConsoleLogger();

// OCP: We can swap calculators without changing DeliveryService
ICostCalculator standardCalc = new StandardCostCalculator();
ICostCalculator expressCalc = new ExpressCostCalculator();
ICostCalculator discountedCalc = new DiscountedCostCalculator();

// Use standard calculator
var service = new DeliveryService(parcelRepo, deliveryRepo, standardCalc, logger);

service.RegisterParcel("UA-SOLID-001", 5.0m, 1, "Kyiv, Khreshchatyk 1");
service.RegisterParcel("UA-SOLID-002", 10.0m, 2, "Lviv, Franka 10");
service.RegisterParcel("UA-SOLID-003", 2.5m, 1, "Odesa, Deribasivska 5");

service.CreateDelivery(1, 1, 50);  // Standard cost
service.CreateDelivery(2, 1, 100); // Standard cost
service.CreateDelivery(3, 1, 30);  // Standard cost

service.PrintParcels();
service.PrintReport();

Console.WriteLine("--- DEMO 3: OCP — Adding Express Calculator without changing DeliveryService ---\n");

// OCP: New calculator, zero changes to existing code
var expressParcelRepo = new InMemoryParcelRepository();
var expressDeliveryRepo = new InMemoryDeliveryRepository();
var expressService = new DeliveryService(expressParcelRepo, expressDeliveryRepo, expressCalc, logger);

expressService.RegisterParcel("UA-EXPRESS-001", 3.0m, 3, "Kharkiv, Sumska 20");
expressService.CreateDelivery(1, 2, 80); // Express cost (1.5x)

expressService.PrintReport();

Console.WriteLine("--- DEMO 4: LSP — Employee hierarchy substitution ---\n");

var employees = new List<Employee>
{
    new Courier { EmployeeID = 1, FullName = "Oleh Koval", Phone = "+380671234567", VehicleType = "Car" },
    new Manager { EmployeeID = 2, FullName = "Ivan Petrenko", Phone = "+380501234567", Department = "Logistics" },
    new Operator { EmployeeID = 3, FullName = "Maria Shevchenko", Phone = "+380631234567", Shift = "Night" }
};

foreach (var emp in employees)
{
    Console.WriteLine($"  {emp.GetRoleDescription()}"); // LSP: all work via base type
}

Console.WriteLine("\n--- DEMO 5: DIP — Swapping logger (FileLogger instead of ConsoleLogger) ---\n");

// DIP: Can replace ConsoleLogger with FileLogger without touching DeliveryService
ILogger fileLogger = new FileLogger();
var fileLogService = new DeliveryService(
    new InMemoryParcelRepository(),
    new InMemoryDeliveryRepository(),
    discountedCalc,
    fileLogger);

fileLogService.RegisterParcel("UA-DIP-001", 1.0m, 4, "Dnipro, Molod 10");
fileLogService.CreateDelivery(1, 1, 20); // Discounted cost (0.9x)

fileLogService.PrintReport();
Console.WriteLine("(Also logged to delivery_log.txt — DIP demonstrated)\n");

Console.WriteLine("===========================================");
Console.WriteLine("  SOLID Principles Demonstrated:");
Console.WriteLine("  S - Separate classes for each responsibility");
Console.WriteLine("  O - ICostCalculator: new calculators = no changes to DeliveryService");
Console.WriteLine("  L - Employee base class: Courier/Manager/Operator are substitutable");
Console.WriteLine("  I - Small interfaces: ILogger, ICostCalculator, IParcelRepository");
Console.WriteLine("  D - DeliveryService depends on abstractions, not concrete classes");
Console.WriteLine("===========================================");
