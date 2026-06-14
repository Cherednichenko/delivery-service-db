namespace DeliveryServiceSOLID.Models;

public class Delivery
{
    public int DeliveryID { get; set; }
    public int ParcelID { get; set; }
    public int EmployeeID { get; set; }
    public DateTime PickupDate { get; set; }
    public DateTime? DeliveryDate { get; set; }
    public string Status { get; set; }
    public decimal Cost { get; set; }
}
