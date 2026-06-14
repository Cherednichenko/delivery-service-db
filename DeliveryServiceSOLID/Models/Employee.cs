namespace DeliveryServiceSOLID.Models;

public abstract class Employee
{
    public int EmployeeID { get; set; }
    public string FullName { get; set; }
    public string Position { get; set; }
    public string Phone { get; set; }

    public abstract string GetRoleDescription();
}

public class Courier : Employee
{
    public string VehicleType { get; set; } = "Car";

    public override string GetRoleDescription()
    {
        return $"Courier {FullName}, Vehicle: {VehicleType}";
    }
}

public class Manager : Employee
{
    public string Department { get; set; } = "Logistics";

    public override string GetRoleDescription()
    {
        return $"Manager {FullName}, Department: {Department}";
    }
}

public class Operator : Employee
{
    public string Shift { get; set; } = "Day";

    public override string GetRoleDescription()
    {
        return $"Operator {FullName}, Shift: {Shift}";
    }
}
