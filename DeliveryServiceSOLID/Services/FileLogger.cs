namespace DeliveryServiceSOLID.Services;

using DeliveryServiceSOLID.Interfaces;

public class FileLogger : ILogger
{
    private readonly string _filePath = "delivery_log.txt";

    public void Info(string message)
    {
        File.AppendAllText(_filePath, $"[INFO] {DateTime.Now:HH:mm:ss} - {message}\n");
    }

    public void Warning(string message)
    {
        File.AppendAllText(_filePath, $"[WARN] {DateTime.Now:HH:mm:ss} - {message}\n");
    }

    public void Error(string message)
    {
        File.AppendAllText(_filePath, $"[ERR]  {DateTime.Now:HH:mm:ss} - {message}\n");
    }
}
