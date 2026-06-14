namespace DeliveryServiceSOLID.Repositories;

using DeliveryServiceSOLID.Interfaces;
using DeliveryServiceSOLID.Models;

public class InMemoryDeliveryRepository : IDeliveryRepository
{
    private readonly List<Delivery> _deliveries = new();
    private int _nextId = 1;

    public Delivery GetById(int id) => _deliveries.FirstOrDefault(d => d.DeliveryID == id);

    public List<Delivery> GetAll() => _deliveries.ToList();

    public void Add(Delivery delivery)
    {
        delivery.DeliveryID = _nextId++;
        delivery.PickupDate = DateTime.Now;
        _deliveries.Add(delivery);
    }

    public void Update(Delivery delivery)
    {
        var existing = GetById(delivery.DeliveryID);
        if (existing != null)
        {
            existing.Status = delivery.Status;
            existing.Cost = delivery.Cost;
            existing.DeliveryDate = delivery.DeliveryDate;
        }
    }
}
