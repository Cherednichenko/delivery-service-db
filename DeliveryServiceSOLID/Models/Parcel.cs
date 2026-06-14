namespace DeliveryServiceSOLID.Models;

public class Parcel
{
    public int ParcelID { get; set; }
    public string TrackingNumber { get; set; }
    public decimal WeightKg { get; set; }
    public string Description { get; set; }
    public string Status { get; set; }
    public int CustomerID { get; set; }
    public string RecipientAddress { get; set; }
}
