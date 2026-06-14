namespace DeliveryServiceSOLID.Repositories;

using DeliveryServiceSOLID.Interfaces;
using DeliveryServiceSOLID.Models;

public class InMemoryParcelRepository : IParcelRepository
{
    private readonly List<Parcel> _parcels = new();
    private int _nextId = 1;

    public Parcel GetById(int id) => _parcels.FirstOrDefault(p => p.ParcelID == id);

    public List<Parcel> GetAll() => _parcels.ToList();

    public void Add(Parcel parcel)
    {
        parcel.ParcelID = _nextId++;
        _parcels.Add(parcel);
    }

    public void Update(Parcel parcel)
    {
        var existing = GetById(parcel.ParcelID);
        if (existing != null)
        {
            existing.TrackingNumber = parcel.TrackingNumber;
            existing.WeightKg = parcel.WeightKg;
            existing.Status = parcel.Status;
            existing.RecipientAddress = parcel.RecipientAddress;
        }
    }

    public void Delete(int id) => _parcels.RemoveAll(p => p.ParcelID == id);
}
