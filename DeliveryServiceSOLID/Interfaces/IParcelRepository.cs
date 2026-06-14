namespace DeliveryServiceSOLID.Interfaces;

using DeliveryServiceSOLID.Models;

public interface IParcelRepository
{
    Parcel GetById(int id);
    List<Parcel> GetAll();
    void Add(Parcel parcel);
    void Update(Parcel parcel);
    void Delete(int id);
}
