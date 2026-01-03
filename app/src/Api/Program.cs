using Microsoft.AspNetCore.HttpOverrides;
using Serilog;
using SerilogTimings;
using Api.Logging;
using Api.Middleware;

var builder = WebApplication.CreateBuilder(args);

try
{
    Log.Information("Starting up the application");

builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();
builder.Host.UseSerilog((context, config) =>
    config.ReadFrom.Configuration(context.Configuration)
          .Enrich.With<EventTypeEnricher>());

var app = builder.Build();

app.UseForwardedHeaders(new ForwardedHeadersOptions
{
    ForwardedHeaders = ForwardedHeaders.XForwardedFor | ForwardedHeaders.XForwardedProto
});

app.UseMiddleware<RequestLogContextMiddleware>();

app.UseSerilogRequestLogging(opts =>
    opts.EnrichDiagnosticContext = (diagnosticContext, httpContext) =>
    {
        var clientIp = httpContext.Request.Headers["X-Forwarded-For"].FirstOrDefault() ??
                       httpContext.Connection.RemoteIpAddress?.ToString();
        diagnosticContext.Set("ClientIP", clientIp);
        diagnosticContext.Set("UserAgent", httpContext.Request.Headers["User-Agent"].FirstOrDefault());
        diagnosticContext.Set("RequestMethod", httpContext.Request.Method);
        diagnosticContext.Set("RequestPath", httpContext.Request.Path);

        // Add correlation ID from header or trace identifier
        httpContext.Request.Headers.TryGetValue("X-Correlation-ID", out var correlationId);
        diagnosticContext.Set("CorrelationId", correlationId.FirstOrDefault() ?? httpContext.TraceIdentifier);
    });

// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.MapGet("/", (HttpContext context, ILogger<Program> logger) => {
    using var operation = Operation.Begin("Processing root endpoint request");

    var sourceIp = context.Request.Headers["X-Forwarded-For"].FirstOrDefault() ?? context.Connection.RemoteIpAddress?.ToString();
    logger.LogInformation("Root endpoint accessed from {SourceIp}", sourceIp);

    var response = new {
        source_ip = sourceIp,
        timestamp = DateTime.UtcNow
    };

    operation.Complete();
    return response;
});

app.MapGet("/healthz", (ILogger<Program> logger) => {
    using var operation = Operation.Begin("Processing health check request");

    logger.LogInformation("Health check endpoint accessed");

    var response = new {
        status = "healthy",
        timestamp = DateTime.UtcNow
    };

    operation.Complete();
    return response;
});

    app.Run();
}
catch (Exception ex)
{
    Log.Fatal(ex, "Application terminated unexpectedly");
}
finally
{
    Log.CloseAndFlush();
}
