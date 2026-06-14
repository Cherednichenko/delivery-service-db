namespace DeliveryServiceSOLID.Services;

using DeliveryServiceSOLID.Interfaces;
using DeliveryServiceSOLID.Models;

public class DeliveryService
{
    private readonly IParcelRepository _parcelRepo;
    private readonly IDeliveryRepository _deliveryRepo;
    private readonly ICostCalculator _costCalculator;
    private readonly ILogger _logger;

    public DeliveryService(
        IParcelRepository parcelRepo,
        IDeliveryRepository deliveryRepo,
        ICostCalculator costCalculator,
        ILogger logger)
    {
        _parcelRepo = parcelRepo;
        _deliveryRepo = deliveryRepo;
        _costCalculator = costCalculator;
        _logger = logger;
    }

    public void RegisterParcel(string tracking, decimal weight, int customerId, string address)
    {
        var parcel = new Parcel
        {
            TrackingNumber = tracking,
            WeightKg = weight,
            Status = "Прийнято",
            CustomerID = customerId,
            RecipientAddress = address
        };

        _parcelRepo.Add(parcel);
        _logger.Info($"Parcel registered: {tracking}, weight: {weight}kg");
    }

    public void CreateDelivery(int parcelId, int employeeId, decimal distanceKm)
    {
        var parcel = _parcelRepo.GetById(parcelId);
        if (parcel == null)
        {
            _logger.Error($"Parcel {parcelId} not found");
            return;
        }

        decimal cost = _costCalculator.Calculate(parcel.WeightKg, distanceKm);

        var delivery = new Delivery
        {
            ParcelID = parcelId,
            EmployeeID = employeeId,
            Status = "В обробці",
            Cost = cost
        };

        _deliveryRepo.Add(delivery);
        parcel.Status = "Передано в доставку";
        _parcelRepo.Update(parcel);

        _logger.Info($"Delivery created for parcel {parcel.TrackingNumber}, cost: {cost:C2} ({_costCalculator.MethodName})");
    }

    public void CompleteDelivery(int deliveryId)
    {
        var delivery = _deliveryRepo.GetById(deliveryId);
        if (delivery == null)
        {
            _logger.Error($"Delivery {deliveryId} not found");
            return;
        }

        delivery.Status = "Доставлено";
        delivery.DeliveryDate = DateTime.Now;
        _deliveryRepo.Update(delivery);

        var parcel = _parcelRepo.GetById(delivery.ParcelID);
        if (parcel != null)
        {
            parcel.Status = "Доставлено";
            _parcelRepo.Update(parcel);
        }

        _logger.Info($"Delivery {deliveryId} completed");
    }

    public void PrintReport()
    {
        Console.WriteLine("\n=== DELIVERY REPORT ===");
        Console.WriteLine($"{"ID",-4} {"Tracking",-16} {"Weight",-8} {"Status",-20} {"Cost",-10}");
        Console.WriteLine(new string('-', 60));

        foreach (var d in _deliveryRepo.GetAll())
        {
            var p = _parcelRepo.GetById(d.ParcelID);
            string tracking = p?.TrackingNumber ?? "N/A";
            decimal weight = p?.WeightKg ?? 0;
            Console.WriteLine($"{d.DeliveryID,-4} {tracking,-16} {weight,-8:F2} {d.Status,-20} {d.Cost,-10:C2}");
        }

        var totalRevenue = _deliveryRepo.GetAll().Sum(d => d.Cost);
        Console.WriteLine(new string('-', 60));
        Console.WriteLine($"Total Revenue: {totalRevenue:C2}");
        Console.WriteLine();
    }

    public void PrintParcels()
    {
        Console.WriteLine("\n=== PARCELS ===");
        foreach (var p in _parcelRepo.GetAll())
        {
            Console.WriteLine($"  [{p.ParcelID}] {p.TrackingNumber} - {p.WeightKg}kg - {p.Status}");
        }
    }
}
