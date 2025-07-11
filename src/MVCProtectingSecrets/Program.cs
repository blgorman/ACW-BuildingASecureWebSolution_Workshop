using Azure.Identity;
using Microsoft.ApplicationInsights.Extensibility;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using MVCProtectingSecrets.Data;
using MVCProtectingSecrets.Initializers;

namespace MVCProtectingSecrets
{
    public class Program
    {
        public static void Main(string[] args)
        {
            var builder = WebApplication.CreateBuilder(args);
            builder.Services.AddHttpClient();

            /********************************************************************************************************
            *  * Add Azure App Configuration
            *  * use the connection string to connect to Azure App Configuration
            *  * requires all app service and identity information to be authorized on app config [app data reader role, etc]
            *  * for key vault => requires the user, app config, and app service to be authorized on the key vault
            *  * For more information: See: https://github.com/AzureCloudWorkshops/ACW_ProtectingYourApplicationSecrets
            ********************************************************************************************************/
            //var appConfigConnection = builder.Configuration.GetConnectionString("AzureAppConfigConnection");

            //WITHOUT KEY VAULT:
            //builder.Configuration.AddAzureAppConfiguration(appConfigConnection);

            //WITH KEY VAULT:
            //builder.Host.ConfigureAppConfiguration((hostingContext, config) =>
            //{
            //    config.AddAzureAppConfiguration(options =>
            //    {
            //        options.Connect(appConfigConnection);
            //        options.ConfigureKeyVault(options =>
            //        {
            //            options.SetCredential(new DefaultAzureCredential());
            //        });
            //    });
            //});

            // Add database to the services
            var connectionString = builder.Configuration.GetConnectionString("IdentityDatabaseConnectionString") ?? throw new InvalidOperationException("Connection string 'IdentityDatabaseConnectionString' not found.");
            builder.Services.AddDbContext<ApplicationDbContext>(options =>
                options.UseSqlServer(connectionString));
            builder.Services.AddDatabaseDeveloperPageExceptionFilter();

            // Add migrations to the services
            builder.Services.AddHostedService<MigrationHostedService>();

            

            builder.Services.AddDefaultIdentity<IdentityUser>(options => options.SignIn.RequireConfirmedAccount = true)
                .AddEntityFrameworkStores<ApplicationDbContext>();
            builder.Services.AddControllersWithViews();

            // Configure anti-forgery tokens
            builder.Services.AddAntiforgery(options => 
            {
                options.HeaderName = "__RequestVerificationToken";
            });

            builder.Services.AddApplicationInsightsTelemetry();
            builder.Services.AddSingleton<ITelemetryInitializer, LogSanitizerInsightsInitializer>();

            var app = builder.Build();

            // Configure the HTTP request pipeline.
            if (app.Environment.IsDevelopment())
            {
                using var scope = app.Services.CreateScope();
                var db = scope.ServiceProvider.GetRequiredService<ApplicationDbContext>();
                db.Database.Migrate();
                app.UseMigrationsEndPoint();
            }
            else
            {
                app.UseExceptionHandler("/Home/Error");
                // The default HSTS value is 30 days. You may want to change this for production scenarios, see https://aka.ms/aspnetcore-hsts.
                app.UseHsts();
            }

            app.UseHttpsRedirection();
            app.UseStaticFiles();

            app.UseRouting();

            app.UseAuthorization();

            app.MapControllerRoute(
                name: "default",
                pattern: "{controller=Home}/{action=Index}/{id?}");
            app.MapRazorPages();

            app.Run();
        }
    }
}
