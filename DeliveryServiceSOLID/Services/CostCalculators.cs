namespace DeliveryServiceSOLID.Services;

using DeliveryServiceSOLID.Interfaces;

public class StandardCostCalculator : ICostCalculator
{
    public string MethodName => "Standard";

    public decimal Calculate(decimal weightKg, decimal distanceKm)
    {
        return 50.00m + (weightKg * 15.00m) + (distanceKm * 5.00m);
    }
}

public class ExpressCostCalculator : ICostCalculator
{
    public string MethodName => "Express";

    public decimal Calculate(decimal weightKg, decimal distanceKm)
    {
        decimal baseCost = 50.00m + (weightKg * 15.00m) + (distanceKm * 5.00m);
        return baseCost * 1.5m;
    }
}

public class DiscountedCostCalculator : ICostCalculator
{
    public string MethodName => "Discounted";

    public decimal Calculate(decimal weightKg, decimal distanceKm)
    {
        decimal baseCost = 50.00m + (weightKg * 15.00m) + (distanceKm * 5.00m);
        return baseCost * 0.9m;
    }
}
