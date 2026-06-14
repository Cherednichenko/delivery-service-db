namespace DeliveryServiceSOLID.Interfaces;

using DeliveryServiceSOLID.Models;

public interface IDeliveryRepository
{
    Delivery GetById(int id);
    List<Delivery> GetAll();
    void Add(Delivery delivery);
    void Update(Delivery delivery);
}
