using Microsoft.ApplicationInsights;
using Microsoft.AspNetCore.Mvc;
using MVCProtectingSecrets.Models;
using System.Text.Json;

namespace MVCProtectingSecrets.Controllers
{
    public class APIDemoController : Controller
    {
        private readonly ILogger<APIDemoController> _logger;
        private readonly IConfiguration _configuration;
        private static readonly HttpClient _httpClient = new HttpClient();
        private readonly TelemetryClient _telemetryClient;

        public APIDemoController(ILogger<APIDemoController> logger, TelemetryClient telemetryClient
                            , IConfiguration configuration)
        {
            _logger = logger;
            _telemetryClient = telemetryClient;
            _configuration = configuration;
        }

        public async Task<IActionResult> Index()
        {
            //if you want to make this work, add information about your API in the appsettings.json file
            //for practice, you could then add those settings to the vault and leverage them from user secrets
            _telemetryClient.TrackPageView("APIDemo/Index");
            var apiEndpoint = _configuration["YourAPI:BaseURL"];
            var someGetMethod = _configuration["YourAPI:SomeGetMethod"];

            var apiEndpointSomeGetMethod = $"{apiEndpoint}{someGetMethod}";

            var response = await _httpClient.GetAsync(apiEndpointSomeGetMethod);

            if (response.IsSuccessStatusCode)
            {
                var data = await response.Content.ReadAsStringAsync();

                //clearly, you would need to make your own models to deserialize the data
                //this is just an example of how to deserialize the data
                var vehicles = JsonSerializer.Deserialize<AllVehicles>(data, new JsonSerializerOptions
                {
                    PropertyNameCaseInsensitive = true
                });
                //add add it into the results
                return View(vehicles?.Results ?? new List<Vehicle>());
            }

            // Handle error response
            ViewBag.Error = "Error fetching data.";
            return View(new List<Vehicle>());
        }
    }
}
