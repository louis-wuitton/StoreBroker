Add-Type -TypeDefinition @"
   public enum StoreBrokerFeatureAvailabilityProperty
   {
       resourceType,
       revisionToken
   }
"@

function Get-FeatureAvailabilities
{
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [ValidateScript({if ($_.Length -gt 12) { $true } else { throw "It looks like you supplied an AppId instead of a ProductId.  Use Get-Products with -AppId to find the ProductId for this AppId." }})]
        [string] $ProductId,

        [Parameter(Mandatory)]
        [string] $SubmissionId,

        [string] $FeatureGroupId,

        [switch] $IncludeMarketStates,

        [switch] $IncludeTrial,

        [switch] $IncludePricing,

        [string] $ClientRequestId,

        [string] $CorrelationId,

        [string] $AccessToken,

        [switch] $SinglePage,

        [switch] $NoStatus
    )

    Write-Log -Message "Executing: $($MyInvocation.Line)" -Level Verbose

    try
    {
        $telemetryProperties = @{
            [StoreBrokerTelemetryProperty]::ProductId = $ProductId
            [StoreBrokerTelemetryProperty]::SubmissionId = $SubmissionId
            [StoreBrokerTelemetryProperty]::FeatureGroupId = $FeatureGroupId
            [StoreBrokerTelemetryProperty]::IncludeMarketStates = $IncludeMarketStates
            [StoreBrokerTelemetryProperty]::IncludeTrial = $IncludeTrial
            [StoreBrokerTelemetryProperty]::IncludePricing = $IncludePricing
            [StoreBrokerTelemetryProperty]::ClientRequestId = $ClientRequesId
            [StoreBrokerTelemetryProperty]::CorrelationId = $CorrelationId
        }

        $getParams = @()
        $getParams += "marketStates=$IncludeMarketStates"
        $getParams += "trial=$IncludeTrial"
        $getParams += "pricing=$IncludePricing"

        if (-not [String]::IsNullOrWhiteSpace($SubmissionId))
        {
            $getParams += "submissionId=$SubmissionId"
        }

        if (-not [String]::IsNullOrWhiteSpace($FeatureGroupId))
        {
            $getParams += "featureGroupId=$FeatureGroupId"
        }

        $params = @{
            "UriFragment" = "products/$ProductId/featureAvailabilities`?" + ($getParams -join '&')
            "Description" = "Getting feature availability for $ProductId"
            "ClientRequestId" = $ClientRequestId
            "CorrelationId" = $CorrelationId
            "AccessToken" = $AccessToken
            "TelemetryEventName" = "Get-FeatureAvailabilities"
            "TelemetryProperties" = $telemetryProperties
            "SinglePage" = $SinglePage
            "NoStatus" = $NoStatus
        }

        return Invoke-SBRestMethodMultipleResult @params
    }
    catch [System.InvalidOperationException]
    {
        throw
    }
}

function New-FeatureAvailability
{
    [CmdletBinding(
        SupportsShouldProcess,
        DefaultParametersetName="Object")]
    param(
        [Parameter(Mandatory)]
        [ValidateScript({if ($_.Length -gt 12) { $true } else { throw "It looks like you supplied an AppId instead of a ProductId.  Use Get-Products with -AppId to find the ProductId for this AppId." }})]
        [string] $ProductId,

        [Parameter(Mandatory)]
        [string] $SubmissionId,

        [string] $FeatureGroupId,

        [switch] $IncludeMarketStates,

        [switch] $IncludeTrial,

        [switch] $IncludePricing,

        [Parameter(
            Mandatory,
            ParameterSetName="Object")]
        [PSCustomObject] $Object,

        [string] $ClientRequestId,

        [string] $CorrelationId,

        [string] $AccessToken,

        [switch] $NoStatus
    )

    Write-Log -Message "Executing: $($MyInvocation.Line)" -Level Verbose

    try
    {
        $telemetryProperties = @{
            [StoreBrokerTelemetryProperty]::ProductId = $ProductId
            [StoreBrokerTelemetryProperty]::SubmissionId = $SubmissionId
            [StoreBrokerTelemetryProperty]::FeatureGroupId = $FeatureGroupId
            [StoreBrokerTelemetryProperty]::IncludeMarketStates = $IncludeMarketStates
            [StoreBrokerTelemetryProperty]::IncludeTrial = $IncludeTrial
            [StoreBrokerTelemetryProperty]::IncludePricing = $IncludePricing
            [StoreBrokerTelemetryProperty]::UsingObject = ($null -ne $Object)
            [StoreBrokerTelemetryProperty]::ClientRequestId = $ClientRequesId
            [StoreBrokerTelemetryProperty]::CorrelationId = $CorrelationId
        }

        Test-ResourceType -Object $Object -ResourceType [StoreBrokerResourceType]::FeatureAvailability

        $body = $Object| ConvertTo-Json -Depth $script:jsonConversionDepth

        $params = @{
            "UriFragment" = "products/$ProductId/featureavailabilities"
            "Method" = 'Post'
            "Description" = "Creating new feature availability for $ProductId"
            "Body" = $body
            "ClientRequestId" = $ClientRequestId
            "CorrelationId" = $CorrelationId
            "AccessToken" = $AccessToken
            "TelemetryEventName" = "New-FeatureAvailability"
            "TelemetryProperties" = $telemetryProperties
            "NoStatus" = $NoStatus
        }

        return Invoke-SBRestMethod @params
    }
    catch [System.InvalidOperationException]
    {
        throw
    }
}

function Set-FeatureAvailability
{
    [CmdletBinding(
        SupportsShouldProcess,
        DefaultParametersetName="Object")]
    param(
        [Parameter(Mandatory)]
        [ValidateScript({if ($_.Length -gt 12) { $true } else { throw "It looks like you supplied an AppId instead of a ProductId.  Use Get-Products with -AppId to find the ProductId for this AppId." }})]
        [string] $ProductId,

        [Parameter(Mandatory)]
        [string] $SubmissionId,

        [string] $FeatureGroupId,

        [switch] $IncludeMarketStates,

        [switch] $IncludeTrial,

        [switch] $IncludePricing,

        [Parameter(
            Mandatory,
            ParameterSetName="Object")]
        [PSCustomObject] $Object,

        [string] $ClientRequestId,

        [string] $CorrelationId,

        [string] $AccessToken,

        [switch] $NoStatus
    )

    Write-Log -Message "Executing: $($MyInvocation.Line)" -Level Verbose

    try
    {
        $telemetryProperties = @{
            [StoreBrokerTelemetryProperty]::ProductId = $ProductId
            [StoreBrokerTelemetryProperty]::SubmissionId = $SubmissionId
            [StoreBrokerTelemetryProperty]::FeatureGroupId = $FeatureGroupId
            [StoreBrokerTelemetryProperty]::FeatureAvailabilityId = $FeatureAvailabilityId
            [StoreBrokerTelemetryProperty]::IncludeMarketStates = $IncludeMarketStates
            [StoreBrokerTelemetryProperty]::IncludeTrial = $IncludeTrial
            [StoreBrokerTelemetryProperty]::IncludePricing = $IncludePricing
            [StoreBrokerTelemetryProperty]::UsingObject = ($null -ne $Object)
            [StoreBrokerTelemetryProperty]::ClientRequestId = $ClientRequesId
            [StoreBrokerTelemetryProperty]::CorrelationId = $CorrelationId
        }

        Test-ResourceType -Object $Object -ResourceType [StoreBrokerResourceType]::FeatureAvailability

        $body = $Object | ConvertTo-Json -Depth $script:jsonConversionDepth

        $params = @{
            "UriFragment" = "products/$ProductId/featureavailabilities/$FeatureAvailabilityId`?" + ($getParams -join '&')
            "Method" = 'Put'
            "Description" = "Updating feature availability $FeatureAvailabilityId for $ProductId"
            "Body" = $body
            "ClientRequestId" = $ClientRequestId
            "CorrelationId" = $CorrelationId
            "AccessToken" = $AccessToken
            "TelemetryEventName" = "Set-FeatureAvailability"
            "TelemetryProperties" = $telemetryProperties
            "NoStatus" = $NoStatus
        }

        return Invoke-SBRestMethod @params
    }
    catch [System.InvalidOperationException]
    {
        throw
    }
}

function Get-FeatureAvailability
{
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [ValidateScript({if ($_.Length -gt 12) { $true } else { throw "It looks like you supplied an AppId instead of a ProductId.  Use Get-Products with -AppId to find the ProductId for this AppId." }})]
        [string] $ProductId,

        [Parameter(Mandatory)]
        [string] $SubmissionId,

        [Parameter(Mandatory)]
        [string] $FeatureAvailabilityId,

        [string] $FeatureGroupId,

        [switch] $IncludeMarketStates,

        [switch] $IncludeTrial,

        [switch] $IncludePricing,

        [string] $ClientRequestId,

        [string] $CorrelationId,

        [string] $AccessToken,

        [switch] $NoStatus
    )

    Write-Log -Message "Executing: $($MyInvocation.Line)" -Level Verbose

    try
    {
        $telemetryProperties = @{
            [StoreBrokerTelemetryProperty]::ProductId = $ProductId
            [StoreBrokerTelemetryProperty]::SubmissionId = $SubmissionId
            [StoreBrokerTelemetryProperty]::FeatureAvailabilityId = $FeatureAvailabilityId
            [StoreBrokerTelemetryProperty]::FeatureGroupId = $FeatureGroupId
            [StoreBrokerTelemetryProperty]::IncludeMarketStates = $IncludeMarketStates
            [StoreBrokerTelemetryProperty]::IncludeTrial = $IncludeTrial
            [StoreBrokerTelemetryProperty]::IncludePricing = $IncludePricing
            [StoreBrokerTelemetryProperty]::ClientRequestId = $ClientRequesId
            [StoreBrokerTelemetryProperty]::CorrelationId = $CorrelationId
        }

        $getParams = @()
        $getParams += "marketStates=$IncludeMarketStates"
        $getParams += "trial=$IncludeTrial"
        $getParams += "pricing=$IncludePricing"

        if (-not [String]::IsNullOrWhiteSpace($SubmissionId))
        {
            $getParams += "submissionId=$SubmissionId"
        }

        if (-not [String]::IsNullOrWhiteSpace($FeatureGroupId))
        {
            $getParams += "featureGroupId=$FeatureGroupId"
        }

        $params = @{
            "UriFragment" = "products/$ProductId/featureavailabilities/$FeatureAvailabilityId`?" + ($getParams -join '&')
            "Method" = 'Get'
            "Description" = "Getting feature availability $FeatureAvailabilityId for $ProductId"
            "ClientRequestId" = $ClientRequestId
            "CorrelationId" = $CorrelationId
            "AccessToken" = $AccessToken
            "TelemetryEventName" = "Get-FeatureAvailability"
            "TelemetryProperties" = $telemetryProperties
            "NoStatus" = $NoStatus
        }

        return Invoke-SBRestMethod @params
    }
    catch [System.InvalidOperationException]
    {
        throw
    }
}
