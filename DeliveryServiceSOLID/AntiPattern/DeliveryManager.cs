namespace DeliveryServiceSOLID.AntiPattern;

public class DeliveryManager
{
    private readonly List<Dictionary<string, object>> _parcels = new();
    private readonly List<Dictionary<string, object>> _deliveries = new();
    private int _parcelId = 1;
    private int _deliveryId = 1;

    public void ProcessDelivery(string tracking, double weight, int customerId, string address, double distance)
    {
        double cost = 50 + (weight * 15) + (distance * 5);

        var parcel = new Dictionary<string, object>
        {
            ["ID"] = _parcelId++,
            ["Tracking"] = tracking,
            ["Weight"] = weight,
            ["Status"] = "Прийнято",
            ["CustomerID"] = customerId,
            ["Address"] = address
        };
        _parcels.Add(parcel);

        var delivery = new Dictionary<string, object>
        {
            ["ID"] = _deliveryId++,
            ["ParcelID"] = parcel["ID"],
            ["Cost"] = cost,
            ["Status"] = "В обробці",
            ["Date"] = DateTime.Now
        };
        _deliveries.Add(delivery);

        parcel["Status"] = "Передано в доставку";

        string log = $"[{DateTime.Now}] Delivery created: {tracking}, cost: {cost:C2}";
        Console.WriteLine(log);
        File.AppendAllText("antipattern_log.txt", log + "\n");
    }

    public void ShowReport()
    {
        Console.WriteLine("\n=== ANTI-PATTERN REPORT ===");
        foreach (var d in _deliveries)
        {
            Console.WriteLine($"Delivery {d["ID"]}: cost={d["Cost"]:C2}, status={d["Status"]}");
        }
    }
}
