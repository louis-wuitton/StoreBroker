Add-Type -TypeDefinition @"
   public enum StoreBrokerListingVideoProperty
   {
       fileName,
       resourceType,
       revisionToken,
       state,
       thumbnail
   }
"@

Add-Type -TypeDefinition @"
   public enum StoreBrokerListingVideoThumbnailProperty
   {
       fileName,
       description,
       orientation,
       state,
       title
   }
"@

function Get-ListingVideo
{
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [ValidateScript({if ($_.Length -le 12) { throw "It looks like you supplied an AppId instead of a ProductId.  Use Get-Product with -AppId to find the ProductId for this AppId." } else { $true }})]
        [string] $ProductId,

        [Parameter(Mandatory)]
        [string] $SubmissionId,

        [Parameter(Mandatory)]
        [Alias('LangCode')]
        [string] $LanguageCode,

        [string] $VideoId,

        [switch] $SinglePage,

        [string] $ClientRequestId,

        [string] $CorrelationId,

        [string] $AccessToken,

        [switch] $NoStatus
    )

    Write-Log -Message "[$($MyInvocation.MyCommand.Module.Version)] Executing: $($MyInvocation.Line.Trim())" -Level Verbose

    $singleQuery = (-not [String]::IsNullOrWhiteSpace($VideoId))
    $telemetryProperties = @{
        [StoreBrokerTelemetryProperty]::ProductId = $ProductId
        [StoreBrokerTelemetryProperty]::SubmissionId = $SubmissionId
        [StoreBrokerTelemetryProperty]::LanguageCode = $LanguageCode
        [StoreBrokerTelemetryProperty]::VideoId = $VideoId
        [StoreBrokerTelemetryProperty]::SingleQuery = $singleQuery
        [StoreBrokerTelemetryProperty]::ClientRequestId = $ClientRequesId
        [StoreBrokerTelemetryProperty]::CorrelationId = $CorrelationId
    }

    $getParams = @()
    if (-not [String]::IsNullOrWhiteSpace($SubmissionId))
    {
        $getParams += "submissionId=$SubmissionId"
    }

    $params = @{
        "ClientRequestId" = $ClientRequestId
        "CorrelationId" = $CorrelationId
        "AccessToken" = $AccessToken
        "TelemetryEventName" = "Get-ListingVideo"
        "TelemetryProperties" = $telemetryProperties
        "NoStatus" = $NoStatus
    }

    if ($singleQuery)
    {
        $params["UriFragment"] = "products/$ProductId/listings/$LanguageCode/videos/$VideoId`?" + ($getParams -join '&')
        $params["Method" ] = 'Get'
        $params["Description"] =  "Getting listing video $VideoId for $ProductId"

        return Invoke-SBRestMethod @params
    }
    else
    {
        $params["UriFragment"] = "products/$ProductId/listings/$LanguageCode/videos`?" + ($getParams -join '&')
        $params["Description"] =  "Getting listing videos for $ProductId"
        $params["SinglePage" ] = $SinglePage

        return Invoke-SBRestMethodMultipleResult @params
    }
}

function New-ListingVideo
{
    [CmdletBinding(
        SupportsShouldProcess,
        DefaultParametersetName="Object")]
    param(
        [Parameter(Mandatory)]
        [ValidateScript({if ($_.Length -le 12) { throw "It looks like you supplied an AppId instead of a ProductId.  Use Get-Product with -AppId to find the ProductId for this AppId." } else { $true }})]
        [string] $ProductId,

        [Parameter(Mandatory)]
        [string] $SubmissionId,

        [Parameter(Mandatory)]
        [Alias('LangCode')]
        [string] $LanguageCode,

        [Parameter(
            Mandatory,
            ParameterSetName="Object")]
        [PSCustomObject[]] $Object,

        [Parameter(
            Mandatory,
            ParameterSetName="Individual")]
        [string] $FileName,

        [Parameter(
            Mandatory,
            ParameterSetName="Individual")]
        [string] $ThumbnailFileName,

        [Parameter(
            Mandatory,
            ParameterSetName="Individual")]
        [string] $ThumbnailTitle,

        [Parameter(ParameterSetName="Individual")]
        [string] $ThumbnailDescription,

        [Parameter(ParameterSetName="Individual")]
        [int] $ThumbnailOrientation = 0,

        [string] $ClientRequestId,

        [string] $CorrelationId,

        [string] $AccessToken,

        [switch] $NoStatus
    )

    Write-Log -Message "[$($MyInvocation.MyCommand.Module.Version)] Executing: $($MyInvocation.Line.Trim())" -Level Verbose

    $telemetryProperties = @{
        [StoreBrokerTelemetryProperty]::ProductId = $ProductId
        [StoreBrokerTelemetryProperty]::SubmissionId = $SubmissionId
        [StoreBrokerTelemetryProperty]::LanguageCode = $LanguageCode
        [StoreBrokerTelemetryProperty]::Orientation = $ThumbnailOrientation
        [StoreBrokerTelemetryProperty]::ClientRequestId = $ClientRequesId
        [StoreBrokerTelemetryProperty]::CorrelationId = $CorrelationId
    }

    $getParams = @()
    if (-not [String]::IsNullOrWhiteSpace($SubmissionId))
    {
        $getParams += "submissionId=$SubmissionId"
    }

    Test-ResourceType -Object $Object -ResourceType ([StoreBrokerResourceType]::ListingVideo)

    $hashBody = $Object
    if ($null -eq $hashBody)
    {
        # Convert the input into a Json body.
        $hashBody = @{}
        $hashBody[[StoreBrokerListingVideoProperty]::resourceType] = [StoreBrokerResourceType]::ListingVideo
        $hashBody[[StoreBrokerListingVideoProperty]::fileName] = $FileName

        $hashBody[[StoreBrokerListingVideoProperty]::thumbnail] = @{}
        $hashBody[[StoreBrokerListingVideoProperty]::thumbnail][[StoreBrokerListingVideoThumbnailProperty]::fileName] = $ThumbnailFileName
        $hashBody[[StoreBrokerListingVideoProperty]::thumbnail][[StoreBrokerListingVideoThumbnailProperty]::title] = $ThumbnailTitle
        $hashBody[[StoreBrokerListingVideoProperty]::thumbnail][[StoreBrokerListingVideoThumbnailProperty]::orientation] = $ThumbnailOrientation
        $hashBody[[StoreBrokerListingVideoProperty]::thumbnail][[StoreBrokerListingVideoThumbnailProperty]::description] = $ThumbnailDescription
    }

    $body = Get-JsonBody -InputObject $hashBody
    Write-Log -Message "Body: $body" -Level Verbose

    $uriFragment = "products/$ProductId/listings/$LanguageCode/videos`?" + ($getParams -join '&')
    $description = "Creating new $LanguageCode listing videos for $ProductId"
    $isbulkOperation = $Object.Count -gt 1
    if ($isbulkOperation)
    {
        $uriFragment = "products/$ProductId/listings/$LanguageCode/videos/bulk`?" + ($getParams -join '&')
        $description = "Bulk creating $LanguageCode listing videos for $ProductId"
    }

    $params = @{
        "UriFragment" = $uriFragment
        "Method" = 'Post'
        "Description" = $description
        "Body" = $body
        "ClientRequestId" = $ClientRequestId
        "CorrelationId" = $CorrelationId
        "AccessToken" = $AccessToken
        "TelemetryEventName" = "New-ListingVideo"
        "TelemetryProperties" = $telemetryProperties
        "NoStatus" = $NoStatus
    }

    $result = Invoke-SBRestMethod @params
    if ($isbulkOperation)
    {
        $finalResult = @()
        $finalResult += $result.value

        if ($null -ne $result.nextLink)
        {
            $params = @{
                "UriFragment" = $result.nextLink
                "Description" = "Getting remaining results"
                "ClientRequestId" = $ClientRequestId
                "CorrelationId" = $CorrelationId
                "AccessToken" = $AccessToken
                "TelemetryEventName" = "New-ListingVideo"
                "TelemetryProperties" = $telemetryProperties
                "NoStatus" = $NoStatus
            }

            $finalResult += Invoke-SBRestMethodMultipleResult @params
        }

        return $finalResult
    }
    else
    {
        return $result
    }
}

function Remove-ListingVideo
{
    [CmdletBinding(SupportsShouldProcess)]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSShouldProcess", "", Justification="Methods called within here make use of PSShouldProcess, and the switch is passed on to them inherently.")]
    [Alias("Delete-ListingVideo")]
    param(
        [Parameter(Mandatory)]
        [ValidateScript({if ($_.Length -le 12) { throw "It looks like you supplied an AppId instead of a ProductId.  Use Get-Product with -AppId to find the ProductId for this AppId." } else { $true }})]
        [string] $ProductId,

        [Parameter(Mandatory)]
        [string] $SubmissionId,

        [Parameter(Mandatory)]
        [Alias('LangCode')]
        [string] $LanguageCode,

        [Parameter(Mandatory)]
        [string] $VideoId,

        [string] $ClientRequestId,

        [string] $CorrelationId,

        [string] $AccessToken,

        [switch] $NoStatus
    )

    Write-Log -Message "[$($MyInvocation.MyCommand.Module.Version)] Executing: $($MyInvocation.Line.Trim())" -Level Verbose

    $telemetryProperties = @{
        [StoreBrokerTelemetryProperty]::ProductId = $ProductId
        [StoreBrokerTelemetryProperty]::SubmissionId = $SubmissionId
        [StoreBrokerTelemetryProperty]::LanguageCode = $LanguageCode
        [StoreBrokerTelemetryProperty]::VideoId = $VideoId
        [StoreBrokerTelemetryProperty]::ClientRequestId = $ClientRequesId
        [StoreBrokerTelemetryProperty]::CorrelationId = $CorrelationId
    }

    $getParams = @()
    if (-not [String]::IsNullOrWhiteSpace($SubmissionId))
    {
        $getParams += "submissionId=$SubmissionId"
    }

    $params = @{
        "UriFragment" = "products/$ProductId/listings/$LanguageCode/images/$ImageId`?" + ($getParams -join '&')
        "Method" = "Delete"
        "Description" = "Deleting image $ImageId from the $LanguageCode listing for $ProductId"
        "ClientRequestId" = $ClientRequestId
        "CorrelationId" = $CorrelationId
        "AccessToken" = $AccessToken
        "TelemetryEventName" = "Remove-ListingImage"
        "TelemetryProperties" = $telemetryProperties
        "NoStatus" = $NoStatus
    }

    $null = Invoke-SBRestMethod @params
}

function Set-ListingVideo
{
    [CmdletBinding(
        SupportsShouldProcess,
        DefaultParametersetName="Object")]
    param(
        [Parameter(Mandatory)]
        [ValidateScript({if ($_.Length -le 12) { throw "It looks like you supplied an AppId instead of a ProductId.  Use Get-Product with -AppId to find the ProductId for this AppId." } else { $true }})]
        [string] $ProductId,

        [Parameter(Mandatory)]
        [string] $SubmissionId,

        [Parameter(Mandatory)]
        [Alias('LangCode')]
        [string] $LanguageCode,

        [Parameter(
            Mandatory,
            ParameterSetName="Individual")]
        [string] $VideoId,

        [Parameter(
            Mandatory,
            ParameterSetName="Object")]
        [PSCustomObject] $Object,

        [Parameter(
            Mandatory,
            ParameterSetName="Individual")]
        [ValidateSet('PendingUpload', 'Uploaded')]
        [string] $State,

        [Parameter(
            Mandatory,
            ParameterSetName="Individual")]
        [string] $ThumbnailTitle,

        [Parameter(ParameterSetName="Individual")]
        [string] $ThumbnailDescription,

        [Parameter(
            Mandatory,
            ParameterSetName="Individual")]
        [ValidateSet('PendingUpload', 'Uploaded')]
        [string] $ThumbnailState,

        [Parameter(ParameterSetName="Individual")]
        [int] $ThumbnailOrientation = 0,

        [Parameter(
            Mandatory,
            ParameterSetName="Individual")]
        [string] $RevisionToken,

        [string] $ClientRequestId,

        [string] $CorrelationId,

        [string] $AccessToken,

        [switch] $NoStatus
    )

    Write-Log -Message "[$($MyInvocation.MyCommand.Module.Version)] Executing: $($MyInvocation.Line.Trim())" -Level Verbose

    if ($null -ne $Object)
    {
        $VideoId = $Object.id
    }

    $telemetryProperties = @{
        [StoreBrokerTelemetryProperty]::ProductId = $ProductId
        [StoreBrokerTelemetryProperty]::SubmissionId = $SubmissionId
        [StoreBrokerTelemetryProperty]::LanguageCode = $LanguageCode
        [StoreBrokerTelemetryProperty]::VideoId = $VideoId
        [StoreBrokerTelemetryProperty]::UsingObject = ($null -ne $Object)
        [StoreBrokerTelemetryProperty]::State = $State
        [StoreBrokerTelemetryProperty]::Orientation = $ThumbnailOrientation
        [StoreBrokerTelemetryProperty]::RevisionToken = $RevisionToken
        [StoreBrokerTelemetryProperty]::ClientRequestId = $ClientRequesId
        [StoreBrokerTelemetryProperty]::CorrelationId = $CorrelationId
    }

    $getParams = @()
    if (-not [String]::IsNullOrWhiteSpace($SubmissionId))
    {
        $getParams += "submissionId=$SubmissionId"
    }

    Test-ResourceType -Object $Object -ResourceType ([StoreBrokerResourceType]::ListingVideo)

    $hashBody = $Object
    if ($null -eq $hashBody)
    {
        # Convert the input into a Json body.
        $hashBody = @{}
        $hashBody[[StoreBrokerListingVideoProperty]::resourceType] = [StoreBrokerResourceType]::ListingVideo
        $hashBody['revisionToken'] = $RevisionToken
        $hashBody[[StoreBrokerListingVideoProperty]::state] = $State

        $hashBody[[StoreBrokerListingVideoProperty]::thumbnail] = @{}
        $hashBody[[StoreBrokerListingVideoProperty]::thumbnail][[StoreBrokerListingVideoThumbnailProperty]::title] = $ThumbnailTitle
        $hashBody[[StoreBrokerListingVideoProperty]::thumbnail][[StoreBrokerListingVideoThumbnailProperty]::description] = $ThumbnailDescription
        $hashBody[[StoreBrokerListingVideoProperty]::thumbnail][[StoreBrokerListingVideoThumbnailProperty]::orientation] = $ThumbnailOrientation
        $hashBody[[StoreBrokerListingVideoProperty]::thumbnail][[StoreBrokerListingVideoThumbnailProperty]::state] = $ThumbnailState
    }

    $body = Get-JsonBody -InputObject $hashBody

    $params = @{
        "UriFragment" = "products/$ProductId/listings/$LanguageCode/Videos/$VideoId`?" + ($getParams -join '&')
        "Method" = 'Put'
        "Description" = "Updating listing video $VideoId for $ProductId"
        "Body" = $body
        "ClientRequestId" = $ClientRequestId
        "CorrelationId" = $CorrelationId
        "AccessToken" = $AccessToken
        "TelemetryEventName" = "Set-ListingVideo"
        "TelemetryProperties" = $telemetryProperties
        "NoStatus" = $NoStatus
    }

    return Invoke-SBRestMethod @params
}
