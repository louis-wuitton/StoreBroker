Add-Type -TypeDefinition @"
   public enum StoreBrokerRolloutProperty
   {
       isEnabled,
       isSeekEnabled,
       percentage,
       resourceType,
       revisionToken,
       state
   }
"@

Add-Type -TypeDefinition @"
   public enum StoreBrokerRolloutState
   {
       Initialized,
       Completed,
       RolledBack
   }
"@

function Get-SubmissionRollout
{
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [ValidateScript({if ($_.Length -le 12) { throw "It looks like you supplied an AppId instead of a ProductId.  Use Get-Product with -AppId to find the ProductId for this AppId." } else { $true }})]
        [string] $ProductId,

        [Parameter(Mandatory)]
        [string] $SubmissionId,

        [string] $ClientRequestId,

        [string] $CorrelationId,

        [string] $AccessToken,

        [switch] $NoStatus
    )

    Write-Log -Message "Executing: $($MyInvocation.Line)" -Level Verbose

    $telemetryProperties = @{
        [StoreBrokerTelemetryProperty]::ProductId = $ProductId
        [StoreBrokerTelemetryProperty]::SubmissionId = $SubmissionId
        [StoreBrokerTelemetryProperty]::ClientRequestId = $ClientRequesId
        [StoreBrokerTelemetryProperty]::CorrelationId = $CorrelationId
    }

    $params = @{
        "UriFragment" = "products/$ProductId/submissions/$SubmissionId/rollout"
        "Method" = 'Get'
        "Description" = "Getting rollout info for product: $ProductId submissionId: $SubmissionId"
        "ClientRequestId" = $ClientRequestId
        "CorrelationId" = $CorrelationId
        "AccessToken" = $AccessToken
        "TelemetryEventName" = "Get-SubmissionRollout"
        "TelemetryProperties" = $telemetryProperties
        "NoStatus" = $NoStatus
    }

    return Invoke-SBRestMethod @params
}

function Set-SubmissionRollout
{
    [CmdletBinding(
        SupportsShouldProcess,
        DefaultParametersetName="Object")]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSShouldProcess", "", Justification="Methods called within here make use of PSShouldProcess, and the switch is passed on to them inherently.")]
    param(
        [Parameter(Mandatory)]
        [ValidateScript({if ($_.Length -le 12) { throw "It looks like you supplied an AppId instead of a ProductId.  Use Get-Product with -AppId to find the ProductId for this AppId." } else { $true }})]
        [string] $ProductId,

        [Parameter(Mandatory)]
        [string] $SubmissionId,

        [Parameter(
            Mandatory,
            ParameterSetName="Object")]
        [PSCustomObject] $Object,

        [Parameter(ParameterSetName="Individual")]
        [ValidateSet('Initialized', 'Completed', 'RolledBack')]
        [string] $State = 'Initialized',

        [Parameter(ParameterSetName="Individual")]
        [int] $Percentage = -1,

        [Parameter(ParameterSetName="Individual")]
        [switch] $Enabled,

        [Parameter(ParameterSetName="Individual")]
        [switch] $SeekEnabled,

        [string] $ClientRequestId,

        [string] $CorrelationId,

        [string] $AccessToken,

        [switch] $NoStatus
    )

    Write-Log -Message "Executing: $($MyInvocation.Line)" -Level Verbose

    $telemetryProperties = @{
        [StoreBrokerTelemetryProperty]::ProductId = $ProductId
        [StoreBrokerTelemetryProperty]::SubmissionId = $SubmissionId
        [StoreBrokerTelemetryProperty]::UsingObject = ($null -ne $Object)
        [StoreBrokerTelemetryProperty]::State = $State
        [StoreBrokerTelemetryProperty]::ClientRequestId = $ClientRequesId
        [StoreBrokerTelemetryProperty]::CorrelationId = $CorrelationId
    }

    Test-ResourceType -Object $Object -ResourceType [StoreBrokerResourceType]::Rollout

    $hashBody = $Object
    if ($null -eq $hashBody)
    {
        # Convert the input into a Json body.
        $hashBody = @{}
        $hashBody[[StoreBrokerRolloutProperty]::resourceType] = [StoreBrokerResourceType]::Rollout
        $hashBody[[StoreBrokerRolloutProperty]::state] = $State

        # We only set the value if the user explicitly provided a value for this parameter
        # (so for $false, they'd have to pass in -Enabled:$false).
        # Otherwise, there'd be no way to know when the user wants to simply keep the
        # existing value.
        if ($null -ne $PSBoundParameters['Enabled'])
        {
            $hashBody[[StoreBrokerRolloutProperty]::isEnabled] = $Enabled
            $telemetryProperties[[StoreBrokerTelemetryProperty]::IsEnabled] = $Enabled
        }

        # We only set the value if the user explicitly provided a value for this parameter
        # (so for $false, they'd have to pass in -SeekEnabled:$false).
        # Otherwise, there'd be no way to know when the user wants to simply keep the
        # existing value.
        if ($null -ne $PSBoundParameters['SeekEnabled'])
        {
            $hashBody[[StoreBrokerRolloutProperty]::isSeekEnabled] = $SeekEnabled
            $telemetryProperties[[StoreBrokerTelemetryProperty]::IsSeekEnabled] = $SeekEnabled
        }

        # Users aren't always going to want to change the percentage when calling this
        # method, BUT users need to be able to set the percentage to 0 if they want.
        # Therefore, we use a negative default value to catch when they haven't provided
        # a value (and thus the percentage shouldn't be changed).
        if ($Percentage -ge 0)
        {
            $hashBody[[StoreBrokerRolloutProperty]::percentage] = $Percentage
            $telemetryProperties[[StoreBrokerTelemetryProperty]::Percentage] = $Percentage
        }
    }

    $body = Get-JsonBody -InputObject $hashBody
    Write-Log -Message "Body: $body" -Level Verbose

    $params = @{
        "UriFragment" = "products/$ProductId/submissions/$SubmissionId/rollout"
        "Method" = 'Put'
        "Description" = "Updating rollout details for submission: $SubmissionId"
        "Body" = $body
        "ClientRequestId" = $ClientRequestId
        "CorrelationId" = $CorrelationId
        "AccessToken" = $AccessToken
        "TelemetryEventName" = "Set-SubmissionRollout"
        "TelemetryProperties" = $telemetryProperties
        "NoStatus" = $NoStatus
    }

    return (Invoke-SBRestMethod @params)
}
