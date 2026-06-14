namespace DeliveryServiceSOLID.Interfaces;

public interface ICostCalculator
{
    decimal Calculate(decimal weightKg, decimal distanceKm);
    string MethodName { get; }
}
