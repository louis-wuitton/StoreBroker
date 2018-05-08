$script:FlightObjectType = 'PackageFlight'

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

        [Parameter(
            Mandatory,
            ParameterSetName="Object")]
        [PSCustomObject] $FlightObject,

        [Parameter(
            Mandatory,
            ParameterSetName="Individual")]
        [string] $Name,

        [Parameter(
            Mandatory,
            ParameterSetName="Individual")]
        [string[]] $GroupId,

        [Parameter(
            Mandatory,
            ParameterSetName="Individual")]
        [int] $RelativeRank,

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
            [StoreBrokerTelemetryProperty]::RelativeRank = $RelativeRank
            [StoreBrokerTelemetryProperty]::ClientRequestId = $ClientRequesId
            [StoreBrokerTelemetryProperty]::CorrelationId = $CorrelationId
        }

        $localFlightObject = DeepCopy-Object -Object $ListingObject
        if ($localFlightObject.type -ne $objectType)
        {
            $localFlightObject |
                Add-Member -Type NoteProperty -Name 'type' -Value $script:FlightObjectType
        }

        $body = $localFlightObject
        if ($null -eq $body)
        {
            # Convert the input into a Json body.
            $hashBody = @{}
            $hashBody['type'] = $script:FlightObjectType
            $hashBody['name'] = $Name
            $hashBody['groupIds'] = @($GroupId)
            $hashBody['relativeRank'] = $RelativeRank
        }

        $body = $hashBody | ConvertTo-Json
        Write-Log -Message "Body: $body" -Level Verbose

        $params = @{
            "UriFragment" = "products/$ProductId/flights"
            "Method" = 'Post'
            "Description" = "Creating new flight for $ProductId"
            "Body" = $body
            "ClientRequestId" = $ClientRequestId
            "CorrelationId" = $CorrelationId
            "AccessToken" = $AccessToken
            "TelemetryEventName" = "New-Flight"
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
        [string] $FlightId,

        [Parameter(
            Mandatory,
            ParameterSetName="Object")]
        [PSCustomObject] $FlightObject,

        [Parameter(
            Mandatory,
            ParameterSetName="Individual")]
        [string] $Name,

        [Parameter(
            Mandatory,
            ParameterSetName="Individual")]
        [string[]] $GroupId,

        [Parameter(
            Mandatory,
            ParameterSetName="Individual")]
        [int] $RelativeRank,

        [Parameter(
            Mandatory,
            ParameterSetName="Individual")]
        [string] $RevisionToken,

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
            [StoreBrokerTelemetryProperty]::FlightId = $FlightId
            [StoreBrokerTelemetryProperty]::RelativeRank = $RelativeRank
            [StoreBrokerTelemetryProperty]::RevisionToken = $RevisionToken
            [StoreBrokerTelemetryProperty]::ClientRequestId = $ClientRequesId
            [StoreBrokerTelemetryProperty]::CorrelationId = $CorrelationId
        }

        $localFlightObject = DeepCopy-Object -Object $ListingObject
        if ($localFlightObject.type -ne $objectType)
        {
            $localFlightObject |
                Add-Member -Type NoteProperty -Name 'type' -Value $script:FlightObjectType
        }

        $body = $localFlightObject
        if ($null -eq $body)
        {
            # Convert the input into a Json body.
            $hashBody = @{}
            $hashBody['type'] = $script:FlightObjectType
            $hashBody['name'] = $Name
            $hashBody['groupIds'] = @($GroupId)
            $hashBody['relativeRank'] = $RelativeRank
            $hashBody['revisionToken'] = $RevisionToken
        }

        $body = $hashBody | ConvertTo-Json

        $params = @{
            "UriFragment" = "products/$ProductId/flights/$FlightId"
            "Method" = 'Put'
            "Description" = "Updating flight $FlightId for $ProductId"
            "Body" = $body
            "ClientRequestId" = $ClientRequestId
            "CorrelationId" = $CorrelationId
            "AccessToken" = $AccessToken
            "TelemetryEventName" = "Set-Flight"
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
