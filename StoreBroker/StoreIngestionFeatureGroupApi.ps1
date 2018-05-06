function Get-FeatureGroups
{
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [ValidateScript({if ($_.Length -gt 12) { $true } else { throw "It looks like you supplied an AppId instead of a ProductId.  Use Get-Products with -AppId to find the ProductId for this AppId." }})]
        [string] $ProductId,

        [Parameter(Mandatory)]
        [string] $SubmissionId,

        [string] $ClientRequestId,

        [string] $CorrelationId,

        [string] $AccessToken,

        [switch] $GetAll,

        [switch] $NoStatus
    )

    Write-Log -Message "Executing: $($MyInvocation.Line)" -Level Verbose

    try
    {
        $telemetryProperties = @{
            [StoreBrokerTelemetryProperty]::ProductId = $ProductId
            [StoreBrokerTelemetryProperty]::SubmissionId = $SubmissionId
            [StoreBrokerTelemetryProperty]::ClientRequestId = $ClientRequesId
            [StoreBrokerTelemetryProperty]::CorrelationId = $CorrelationId
        }
    
        $params = @{
            "UriFragment" = "products/$ProductId/featureGroups?submissionId=$SubmissionId"
            "Description" = "Getting feature groups for product: $ProductId submissionId: $submissionId"
            "ClientRequestId" = $ClientRequestId
            "CorrelationId" = $CorrelationId
            "AccessToken" = $AccessToken
            "TelemetryEventName" = "Get-FeatureGroups"
            "TelemetryProperties" = $telemetryProperties
            "GetAll" = $GetAll
            "NoStatus" = $NoStatus
        }

        return Invoke-SBRestMethodMultipleResult @params
    }
    catch [System.InvalidOperationException]
    {
        throw
    }
}

function Get-FeatureGroup
{
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [ValidateScript({if ($_.Length -gt 12) { $true } else { throw "It looks like you supplied an AppId instead of a ProductId.  Use Get-Products with -AppId to find the ProductId for this AppId." }})]
        [string] $ProductId,

        [Parameter(Mandatory)]
        [string] $FeatureGroupId,

        [Parameter(Mandatory)]
        [string] $SubmissionId,

        [string] $ClientRequestId,

        [string] $CorrelationId,

        [string] $AccessToken,

        [switch] $GetAll,

        [switch] $NoStatus
    )

    Write-Log -Message "Executing: $($MyInvocation.Line)" -Level Verbose

    try
    {
        $telemetryProperties = @{
            [StoreBrokerTelemetryProperty]::ProductId = $ProductId
            [StoreBrokerTelemetryProperty]::FeatureGroupId = $FeatureGroupId
            [StoreBrokerTelemetryProperty]::SubmissionId = $SubmissionId
            [StoreBrokerTelemetryProperty]::ClientRequestId = $ClientRequesId
            [StoreBrokerTelemetryProperty]::CorrelationId = $CorrelationId
        }
    
        $params = @{
            "UriFragment" = "products/$ProductId/featureGroups/$FeatureGroupId?submissionId=$SubmissionId"
            "Method" = 'Get'
            "Description" = "Getting feature group: $FeatureGroupId for product: $ProductId submissionId: $submissionId"
            "ClientRequestId" = $ClientRequestId
            "CorrelationId" = $CorrelationId
            "AccessToken" = $AccessToken
            "TelemetryEventName" = "Get-FeatureGroup"
            "TelemetryProperties" = $telemetryProperties
            "NoStatus" = $NoStatus
        }

        return Invoke-SBRestMethodM @params
    }
    catch [System.InvalidOperationException]
    {
        throw
    }
}
