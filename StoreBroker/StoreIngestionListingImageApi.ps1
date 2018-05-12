Add-Type -TypeDefinition @"
   public enum StoreBrokerListingImageProperty
   {
       fileName,
       resourceType,
       revisionToken,
       orientation,
       state,
       type
   }
"@

function Get-ListingImage
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

        [string] $ImageId,

        [string] $ClientRequestId,

        [string] $CorrelationId,

        [string] $AccessToken,

        [switch] $SinglePage,

        [switch] $NoStatus
    )

    Write-Log -Message "Executing: $($MyInvocation.Line)" -Level Verbose

    $singleQuery = (-not [String]::IsNullOrWhiteSpace($ImageId))
    $telemetryProperties = @{
        [StoreBrokerTelemetryProperty]::ProductId = $ProductId
        [StoreBrokerTelemetryProperty]::SubmissionId = $SubmissionId
        [StoreBrokerTelemetryProperty]::LanguageCode = $LanguageCode
        [StoreBrokerTelemetryProperty]::ImageId = $ImageId
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
        "TelemetryEventName" = "Get-ListingImage"
        "TelemetryProperties" = $telemetryProperties
        "NoStatus" = $NoStatus
    }

    if ($singleQuery)
    {
        $params["UriFragment"] = "products/$ProductId/listings/$LanguageCode/images/$ImageId`?" + ($getParams -join '&')
        $params["Method" ] = 'Get'
        $params["Description"] =  "Getting listing image $ImageId for $ProductId"

        return Invoke-SBRestMethod @params
    }
    else
    {
        $params["UriFragment"] = "products/$ProductId/listings/$LanguageCode/images`?" + ($getParams -join '&')
        $params["Description"] =  "Getting listing images for $ProductId"
        $params["SinglePage" ] = $SinglePage

        return Invoke-SBRestMethodMultipleResult @params
    }
}

function New-ListingImage
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
        [ValidateSet(
            'HeroImage414x180', 'HeroImage846x468', 'HeroImage558x756', 'HeroImage414x468', 'HeroImage558x558', 'HeroImage2400x1200',
            'Screenshot', 'ScreenshotWXGA', 'ScreenshotHD720', 'ScreenshotWVGA',
            'SmallMobileTile', 'SmallXboxLiveTile', 'LargeMobileTile', 'LargeXboxLiveTile', 'Tile',
            'DesktopIcon', 'Icon', 'AchievementIcon', 'ChallengePromoIcon', 'RewardDisplayIcon', 'Icon150X150', 'Icon71X71',
            'Doublewide', 'Panoramic', 'Square', 'MobileScreenshot', 'XboxScreenshot', 'PpiScreenshot', 'AnalogScreenshot',
            'BoxArt', 'BrandedKeyArt', 'PosterArt', 'FeaturedPromotionalArt', 'SquareHeroArt', 'TitledHeroArt')]
        [string] $Type,

        [Parameter(ParameterSetName="Individual")]
        [int] $Orientation = 0,

        [string] $ClientRequestId,

        [string] $CorrelationId,

        [string] $AccessToken,

        [switch] $NoStatus
    )

    Write-Log -Message "Executing: $($MyInvocation.Line)" -Level Verbose

    $telemetryProperties = @{
        [StoreBrokerTelemetryProperty]::ProductId = $ProductId
        [StoreBrokerTelemetryProperty]::SubmissionId = $SubmissionId
        [StoreBrokerTelemetryProperty]::LanguageCode = $LanguageCode
        [StoreBrokerTelemetryProperty]::Type = $Type
        [StoreBrokerTelemetryProperty]::Orientation = $Orientation
        [StoreBrokerTelemetryProperty]::ClientRequestId = $ClientRequesId
        [StoreBrokerTelemetryProperty]::CorrelationId = $CorrelationId
    }

    $getParams = @()
    if (-not [String]::IsNullOrWhiteSpace($SubmissionId))
    {
        $getParams += "submissionId=$SubmissionId"
    }

    Test-ResourceType -Object $Object -ResourceType [StoreBrokerResourceType]::ListingImage

    $hashBody = $Object
    if ($null -eq $hashBody)
    {
        # Convert the input into a Json body.
        $hashBody = @{}
        $hashBody[[StoreBrokerListingImageProperty]::resourceType] = [StoreBrokerResourceType]::ListingImage
        $hashBody[[StoreBrokerListingImageProperty]::fileName] = $FileName
        $hashBody[[StoreBrokerListingImageProperty]::type] = $Type
        $hashBody[[StoreBrokerListingImageProperty]::orientation] = $Orientation
    }

    $body = Get-JsonBody -InputObject $hashBody

    $uriFragment = "products/$ProductId/listings/$LanguageCode/images`?" + ($getParams -join '&')
    $description = "Creating new $LanguageCode listing image for $ProductId"
    $isbulkOperation = $Object.Count -gt 1
    if ($isbulkOperation)
    {
        $uriFragment = "products/$ProductId/listings/$LanguageCode/images/bulk`?" + ($getParams -join '&')
        $description = "Bulk creating $LanguageCode listing images for $ProductId"
    }

    $params = @{
        "UriFragment" = $uriFragment
        "Method" = 'Post'
        "Description" = $description
        "Body" = $body
        "ClientRequestId" = $ClientRequestId
        "CorrelationId" = $CorrelationId
        "AccessToken" = $AccessToken
        "TelemetryEventName" = "New-ListingImage"
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
                "TelemetryEventName" = "New-ListingImage"
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

function Remove-ListingImage
{
    [CmdletBinding(SupportsShouldProcess)]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSShouldProcess", "", Justification="Methods called within here make use of PSShouldProcess, and the switch is passed on to them inherently.")]
    [Alias("Delete-ListingImage")]
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
        [string] $ImageId,

        [string] $ClientRequestId,

        [string] $CorrelationId,

        [string] $AccessToken,

        [switch] $NoStatus
    )

    Write-Log -Message "Executing: $($MyInvocation.Line)" -Level Verbose

    $telemetryProperties = @{
        [StoreBrokerTelemetryProperty]::ProductId = $ProductId
        [StoreBrokerTelemetryProperty]::SubmissionId = $SubmissionId
        [StoreBrokerTelemetryProperty]::LanguageCode = $LanguageCode
        [StoreBrokerTelemetryProperty]::ImageId = $ImageId
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

function Set-ListingImage
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

        [Parameter(Mandatory)]
        [string] $ImageId,

        [Parameter(
            Mandatory,
            ParameterSetName="Object")]
        [PSCustomObject] $Object,

        # Can't change filename or type once it's been created.  Would need to delete and re-create.

        [Parameter(
            Mandatory,
            arameterSetName="Individual")]
        [ValidateSet('PendingUpload', 'Uploaded')]
        [string] $State,

        [Parameter(ParameterSetName="Individual")]
        [int] $Orientation = 0,

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

    $telemetryProperties = @{
        [StoreBrokerTelemetryProperty]::ProductId = $ProductId
        [StoreBrokerTelemetryProperty]::SubmissionId = $SubmissionId
        [StoreBrokerTelemetryProperty]::LanguageCode = $LanguageCode
        [StoreBrokerTelemetryProperty]::ImageId = $ImageId
        [StoreBrokerTelemetryProperty]::State = $State
        [StoreBrokerTelemetryProperty]::Orientation = $Orientation
        [StoreBrokerTelemetryProperty]::RevisionToken = $RevisionToken
        [StoreBrokerTelemetryProperty]::ClientRequestId = $ClientRequesId
        [StoreBrokerTelemetryProperty]::CorrelationId = $CorrelationId
    }

    $getParams = @()
    if (-not [String]::IsNullOrWhiteSpace($SubmissionId))
    {
        $getParams += "submissionId=$SubmissionId"
    }

    Test-ResourceType -Object $Object -ResourceType [StoreBrokerResourceType]::ListingImage

    $hashBody = $Object
    if ($null -eq $hashBody)
    {
        # Convert the input into a Json body.
        $hashBody = @{}
        $hashBody[[StoreBrokerListingImageProperty]::revisionToken] = $RevisionToken
        $hashBody[[StoreBrokerListingImageProperty]::resourceType] = [StoreBrokerResourceType]::ListingImage
        $hashBody[[StoreBrokerListingImageProperty]::orientation] = $Orientation
        $hashBody[[StoreBrokerListingImageProperty]::state] = $State
    }

    $body = Get-JsonBody -InputObject $hashBody

    $params = @{
        "UriFragment" = "products/$ProductId/listings/$LanguageCode/images/$ImageId`?" + ($getParams -join '&')
        "Method" = 'Put'
        "Description" = "Updating listing image $ImageId for $ProductId"
        "Body" = $body
        "ClientRequestId" = $ClientRequestId
        "CorrelationId" = $CorrelationId
        "AccessToken" = $AccessToken
        "TelemetryEventName" = "Set-ListingImage"
        "TelemetryProperties" = $telemetryProperties
        "NoStatus" = $NoStatus
    }

    return Invoke-SBRestMethod @params
}
