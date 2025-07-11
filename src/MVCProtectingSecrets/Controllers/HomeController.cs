using Azure.Storage.Blobs;
using Microsoft.ApplicationInsights;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using MVCProtectingSecrets.Data;
using MVCProtectingSecrets.Data.Migrations;
using MVCProtectingSecrets.Models;
using System;
using System.Diagnostics;
using System.Security.Claims;

namespace MVCProtectingSecrets.Controllers;

public class HomeController : Controller
{
    private readonly ILogger<HomeController> _logger;
    private readonly IConfiguration _configuration;
    private readonly TelemetryClient _telemetryClient;
    private readonly ApplicationDbContext _context;

    public HomeController(ILogger<HomeController> logger, TelemetryClient telemetryClient
                            , IConfiguration configuration, ApplicationDbContext context)
    {
        _logger = logger;
        _telemetryClient = telemetryClient;
        _configuration = configuration;
        _context = context;
    }

    public async Task<IActionResult> Index()
    {
        _telemetryClient.TrackPageView("Home/Index");
        var storageContainerName = _configuration["StorageDetails:ImagesContainerName"];
        var storageConnectionString = _configuration["ConnectionStrings:StorageAccountConnectionString"];
        var databaseInfo = _configuration["ConnectionStrings:DefaultConnection"];

        _telemetryClient.TrackTrace($"Storage Container Name: {storageContainerName}");

        //NOTE: Users that aren't logged in shouldn't see any storage details
        //      so we'll set these to empty strings and update if the user is logged in
        ViewBag.StorageAccountName = string.Empty;
        ViewBag.StorageContainerName = string.Empty;
        ViewBag.ShowStorage = false;

        var images = new List<ImageDetail>();

        var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
        var userEmail = User.FindFirstValue(ClaimTypes.Email);
        if (!string.IsNullOrWhiteSpace(userId))
        {
            _telemetryClient.TrackTrace($"User is logged in: {userId} | {userEmail}");
            ViewBag.ShowStorage = true;
            ViewBag.StorageContainerName = storageContainerName;
            images = await GetImages(storageContainerName, storageConnectionString);
        }

        return View(images);
    }

    public async Task<IActionResult> Privacy()
    {
        return View();
    }

    [ResponseCache(Duration = 0, Location = ResponseCacheLocation.None, NoStore = true)]
    public async Task<IActionResult> Error()
    {
        return View(new ErrorViewModel { RequestId = Activity.Current?.Id ?? HttpContext.TraceIdentifier });
    }

    //note: this is just for testing purposes, clearly not recommended for production
    public async Task<IActionResult> MigrateDatabase()
    {
        //if (_context?.Database != null)
        //{
        //    _context.Database.Migrate();
        //}
        return RedirectToAction("Index");
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> UploadImage([FromBody] ImageDetail imageDetail)
    {
        try
        {
            if (imageDetail == null || string.IsNullOrWhiteSpace(imageDetail.ImageFullPath) || string.IsNullOrWhiteSpace(imageDetail.FileName))
            {
                if (Request.Headers["Content-Type"].ToString().Contains("application/json"))
                {
                    return Json(new { success = false, message = "Invalid image details provided." });
                }
                ModelState.AddModelError("ImageDetail", "Invalid image details provided.");
                return RedirectToAction("Index");
            }

            var storageContainerName = _configuration["StorageDetails:ImagesContainerName"];
            var storageConnectionString = _configuration["ConnectionStrings:StorageAccountConnectionString"];
            
            // Upload to storage
            await UploadImage(storageContainerName, storageConnectionString, imageDetail);
            
            // Save image details to database
            if (_context?.Database != null)
            {
                var existingImage = await _context.ImageDetails.FirstOrDefaultAsync(x => x.FileName == imageDetail.FileName);
                if (existingImage == null)
                {
                    // Add new image detail to database
                    var newImageDetail = new ImageDetail
                    {
                        FileName = imageDetail.FileName,
                        Description = imageDetail.Description,
                        AltText = imageDetail.AltText
                    };
                    _context.ImageDetails.Add(newImageDetail);
                    await _context.SaveChangesAsync();
                }
                else
                {
                    // Update existing image details
                    existingImage.Description = imageDetail.Description;
                    existingImage.AltText = imageDetail.AltText;
                    await _context.SaveChangesAsync();
                }
            }

            // Return JSON response for AJAX requests
            if (Request.Headers["Content-Type"].ToString().Contains("application/json"))
            {
                return Json(new { success = true, message = "Image uploaded successfully!" });
            }
            
            return RedirectToAction("Index");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error uploading image");
            
            if (Request.Headers["Content-Type"].ToString().Contains("application/json"))
            {
                return Json(new { success = false, message = "An error occurred while uploading the image." });
            }
            
            ModelState.AddModelError("ImageDetail", "An error occurred while uploading the image.");
            return RedirectToAction("Index");
        }
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> DeleteImage([FromBody] int imageId)
    {
        try
        {
            if (_context?.Database == null)
            {
                return Json(new { success = false, message = "Database connection not available." });
            }

            // Find the image in the database
            var imageDetail = await _context.ImageDetails.FirstOrDefaultAsync(x => x.Id == imageId);
            if (imageDetail == null)
            {
                return Json(new { success = false, message = "Image not found." });
            }

            var storageContainerName = _configuration["StorageDetails:ImagesContainerName"];
            var storageConnectionString = _configuration["ConnectionStrings:StorageAccountConnectionString"];

            // Delete from Azure Storage
            await DeleteImageFromStorage(storageContainerName, storageConnectionString, imageDetail.FileName);

            // Delete from database
            _context.ImageDetails.Remove(imageDetail);
            await _context.SaveChangesAsync();

            return Json(new { success = true, message = "Image deleted successfully!" });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error deleting image");
            return Json(new { success = false, message = "An error occurred while deleting the image." });
        }
    }

    private async Task<List<ImageDetail>> GetImages(string containerName, string storageCNSTR)
    {
        var images = new List<ImageDetail>();

        if (_context?.Database != null)
        {
            images = await _context.ImageDetails.OrderBy(x => x.FileName).ToListAsync();
        }

        BlobServiceClient blobStorageClient = new BlobServiceClient(storageCNSTR);
        var containerClient = blobStorageClient.GetBlobContainerClient(containerName);
        foreach (var blob in containerClient.GetBlobs())
        {
            var i1 = images.FirstOrDefault(x => x.FileName == blob.Name);
            if (i1 == null)
            {
                continue;
            }
            var blobClient = containerClient.GetBlobClient(blob.Name);
            var downloadFileStream = new MemoryStream();
            blobClient.DownloadTo(downloadFileStream);
            var downloadFileBytes = downloadFileStream.ToArray();
            var base64Image = Convert.ToBase64String(downloadFileBytes);
            i1.ImageFullPath = $"data:image/png;base64,{base64Image}";
        }

        return images;
    }

    private async Task UploadImage(string containerName, string storageCNSTR, ImageDetail imageDetail)
    {
        BlobServiceClient blobStorageClient = new BlobServiceClient(storageCNSTR);
        var containerClient = blobStorageClient.GetBlobContainerClient(containerName);
        await containerClient.CreateIfNotExistsAsync();
        
        var blobClient = containerClient.GetBlobClient(imageDetail.FileName);
        using (var stream = new MemoryStream(Convert.FromBase64String(imageDetail.ImageFullPath.Split(',')[1])))
        {
            await blobClient.UploadAsync(stream, true);
        }
    }

    private async Task DeleteImageFromStorage(string containerName, string storageCNSTR, string fileName)
    {
        BlobServiceClient blobStorageClient = new BlobServiceClient(storageCNSTR);
        var containerClient = blobStorageClient.GetBlobContainerClient(containerName);
        
        var blobClient = containerClient.GetBlobClient(fileName);
        await blobClient.DeleteIfExistsAsync();
    }
}
