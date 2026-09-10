using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using PriorAuth.API.Data;
using PriorAuth.API.DTOs;
using PriorAuth.API.Models;

namespace PriorAuth.API.Controllers;

[ApiController]
[Route("api/[controller]")]
public class EligibilityController : ControllerBase
{
    private readonly PriorAuthDbContext _db;
    private readonly ILogger<EligibilityController> _logger;

    public EligibilityController(PriorAuthDbContext db, ILogger<EligibilityController> logger)
    {
        _db = db;
        _logger = logger;
    }

    [HttpPost("check")]
    public async Task<ActionResult<EligibilityCheckResponse>> Check([FromBody] EligibilityCheckRequest request)
    {
        if (string.IsNullOrWhiteSpace(request.PatientId) || request.HealthPlanId <= 0)
            return BadRequest("patientId is required and healthPlanId must be a positive integer.");

        Guid correlationId;
        if (string.IsNullOrEmpty(request.CorrelationId))
        {
            correlationId = Guid.NewGuid();
        }
        else if (!Guid.TryParse(request.CorrelationId, out correlationId))
        {
            return BadRequest("correlationId must be a valid GUID.");
        }

        try
        {
            string status;
            string? errorCode = null;
            string? errorMessage = null;

            var member = await _db.Members.FindAsync(request.PatientId);
            if (member == null)
            {
                status = "ERROR";
                errorCode = "MBR-001";
                errorMessage = "Member not found.";
            }
            else
            {
                var healthPlan = await _db.HealthPlans.FindAsync(request.HealthPlanId);
                if (healthPlan == null)
                {
                    status = "ERROR";
                    errorCode = "PLN-001";
                    errorMessage = "Health plan not found.";
                }
                else
                {
                    status = member.PlanCode == healthPlan.PlanCode ? "ELIGIBLE" : "INELIGIBLE";
                }
            }

            var checkedAt = DateTime.UtcNow;

            _db.EligibilityChecks.Add(new EligibilityCheck
            {
                CorrelationId = correlationId,
                Status = status,
                CheckedAt = checkedAt,
                DataSource = "LOCAL_DB"
            });
            await _db.SaveChangesAsync();

            return Ok(new EligibilityCheckResponse(
                status,
                request.PatientId,
                request.HealthPlanId,
                correlationId.ToString(),
                checkedAt,
                errorCode,
                errorMessage
            ));
        }
        catch (Exception ex)
        {
            _logger.LogError("Eligibility check failed: {CorrelationId} {ExceptionType}", correlationId, ex.GetType().Name);

            return StatusCode(500, new EligibilityCheckResponse(
                "ERROR",
                request.PatientId,
                request.HealthPlanId,
                correlationId.ToString(),
                DateTime.UtcNow,
                "SYS-001",
                "An unexpected error occurred."
            ));
        }
    }
}
