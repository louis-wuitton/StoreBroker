function Get-ProductAvailabilities
{
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [ValidateScript({if ($_.Length -gt 12) { $true } else { throw "It looks like you supplied an AppId instead of a ProductId.  Use Get-Products with -AppId to find the ProductId for this AppId." }})]
        [string] $ProductId,

        [string] $SubmissionId,

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
            [StoreBrokerTelemetryProperty]::ClientRequestId = $ClientRequesId
            [StoreBrokerTelemetryProperty]::CorrelationId = $CorrelationId
        }

        $getParams = @()

        if (-not [String]::IsNullOrWhiteSpace($SubmissionId))
        {
            $getParams += "submissionId=$SubmissionId"
        }

        $params = @{
            "UriFragment" = "products/$ProductId/productAvailabilities?" + ($getParams -join '&')
            "Description" = "Getting product availabilities for $ProductId"
            "ClientRequestId" = $ClientRequestId
            "CorrelationId" = $CorrelationId
            "AccessToken" = $AccessToken
            "TelemetryEventName" = "Get-ProductAvailabilities"
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

function New-ProductAvailability
{
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [ValidateScript({if ($_.Length -gt 12) { $true } else { throw "It looks like you supplied an AppId instead of a ProductId.  Use Get-Products with -AppId to find the ProductId for this AppId." }})]
        [string] $ProductId,

        [string] $SubmissionId,

        [object] $Audience,

        [ValidateSet('Public', 'Private', 'StopSelling', 'NoChange')]
        [string] $Visibility,

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
            [StoreBrokerTelemetryProperty]::HasAudience = ($null -ne $Audience)
            [StoreBrokerTelemetryProperty]::Visiblity = $Visibility
            [StoreBrokerTelemetryProperty]::ClientRequestId = $ClientRequesId
            [StoreBrokerTelemetryProperty]::CorrelationId = $CorrelationId
        }

        $getParams = @()

        if (-not [String]::IsNullOrWhiteSpace($SubmissionId))
        {
            $getParams += "submissionId=$SubmissionId"
        }

        # Convert the input into a Json body.
        $hashBody = @{}

        if ('NoChange' -ne $Visibility)
        {
            $hashBody['visibility'] = $Visibility
        }

        if ($null -ne $Audience)
        {
            $hashBody['audience'] = ConvertTo-Json -InputObject @($Audience)
        }

        $body = $hashBody | ConvertTo-Json
        Write-Log -Message "Body: $body" -Level Verbose


        $params = @{
            "UriFragment" = "products/$ProductId/productAvailabilities?" + ($getParams -join '&')
            "Method" = 'Post'
            "Description" = "Creating new product availability for $ProductId"
            "Body" = $body
            "ClientRequestId" = $ClientRequestId
            "CorrelationId" = $CorrelationId
            "AccessToken" = $AccessToken
            "TelemetryEventName" = "New-ProductAvailability"
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

function Set-ProductAvailability
{
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [ValidateScript({if ($_.Length -gt 12) { $true } else { throw "It looks like you supplied an AppId instead of a ProductId.  Use Get-Products with -AppId to find the ProductId for this AppId." }})]
        [string] $ProductId,

        [Parameter(Mandatory)]
        [string] $ProductAvailabilityId,

        [string] $SubmissionId,

        [Parameter(Mandatory)]
        [string] $RevisionToken,

        [object] $Audience,

        [ValidateSet('Public', 'Private', 'StopSelling', 'NoChange')]
        [string] $Visibility,

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
            [StoreBrokerTelemetryProperty]::ProductAvailabilityId = $ProductAvailabilityId
            [StoreBrokerTelemetryProperty]::SubmissionId = $SubmissionId
            [StoreBrokerTelemetryProperty]::RevisionToken = $RevisionToken
            [StoreBrokerTelemetryProperty]::HasAudience = ($null -ne $Audience)
            [StoreBrokerTelemetryProperty]::Visiblity = $Visibility
            [StoreBrokerTelemetryProperty]::ClientRequestId = $ClientRequesId
            [StoreBrokerTelemetryProperty]::CorrelationId = $CorrelationId
        }

        $getParams = @()

        if (-not [String]::IsNullOrWhiteSpace($SubmissionId))
        {
            $getParams += "submissionId=$SubmissionId"
        }

        # Convert the input into a Json body.
        $hashBody = @{}
        $hashBody['revisionToken'] = $RevisionToken

        if ('NoChange' -ne $Visibility)
        {
            $hashBody['visibility'] = $Visibility
        }

        if ($null -ne $Audience)
        {
            $hashBody['audience'] = ConvertTo-Json -InputObject @($Audience)
        }

        $body = $hashBody | ConvertTo-Json
        Write-Log -Message "Body: $body" -Level Verbose


        $params = @{
            "UriFragment" = "products/$ProductId/productAvailabilities/$ProductAvailabilityId?" + ($getParams -join '&')
            "Method" = 'Put'
            "Description" = "Updating product availability $ProductAvailabilityId for $ProductId"
            "Body" = $body
            "ClientRequestId" = $ClientRequestId
            "CorrelationId" = $CorrelationId
            "AccessToken" = $AccessToken
            "TelemetryEventName" = "Set-ProductAvailability"
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

function Get-ProductAvailability
{
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [ValidateScript({if ($_.Length -gt 12) { $true } else { throw "It looks like you supplied an AppId instead of a ProductId.  Use Get-Products with -AppId to find the ProductId for this AppId." }})]
        [string] $ProductId,

        [Parameter(Mandatory)]
        [string] $ProductAvailability,

        [string] $SubmissionId,

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
            [StoreBrokerTelemetryProperty]::ProductAvailability = $ProductAvailability
            [StoreBrokerTelemetryProperty]::SubmissionId = $SubmissionId
            [StoreBrokerTelemetryProperty]::ClientRequestId = $ClientRequesId
            [StoreBrokerTelemetryProperty]::CorrelationId = $CorrelationId
        }

        $getParams = @()

        if (-not [String]::IsNullOrWhiteSpace($SubmissionId))
        {
            $getParams += "submissionId=$SubmissionId"
        }

        $params = @{
            "UriFragment" = "products/$ProductId/ProductAvailability/$ProductAvailability?" + ($getParams -join '&')
            "Method" = 'Get'
            "Description" = "Getting product availability $ProductAvailabilityId for $ProductId"
            "ClientRequestId" = $ClientRequestId
            "CorrelationId" = $CorrelationId
            "AccessToken" = $AccessToken
            "TelemetryEventName" = "Get-ProductAvailability"
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

function New-Audience
{
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('GroupId', 'PreviewSubscriptionsGroup', 'PrivateMarketplaceGroup')]
        [string] $Type,

        [Parameter(Mandatory)]
        [string[]] $Value
    )

    $audience = @{
        'type' = $Type
        'values' = @($Value)
    }

    return $audience
}
