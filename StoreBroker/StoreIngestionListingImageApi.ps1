function Get-ListingImages
{
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [ValidateScript({if ($_.Length -gt 12) { $true } else { throw "It looks like you supplied an AppId instead of a ProductId.  Use Get-Products with -AppId to find the ProductId for this AppId." }})]
        [string] $ProductId,

        [Parameter(Mandatory)]
        [string] $SubmissionId,

        [Parameter(Mandatory)]
        [Alias('LangCode')]
        [string] $LanguageCode,

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
            [StoreBrokerTelemetryProperty]::LanguageCode = $LanguageCode
            [StoreBrokerTelemetryProperty]::ClientRequestId = $ClientRequesId
            [StoreBrokerTelemetryProperty]::CorrelationId = $CorrelationId
        }

        $getParams = @()

        if (-not [String]::IsNullOrWhiteSpace($SubmissionId))
        {
            $getParams += "submissionId=$SubmissionId"
        }

        $params = @{
            "UriFragment" = "products/$ProductId/listings/$LanguageCode/images`?" + ($getParams -join '&')
            "Description" = "Getting listing images for $ProductId"
            "ClientRequestId" = $ClientRequestId
            "CorrelationId" = $CorrelationId
            "AccessToken" = $AccessToken
            "TelemetryEventName" = "Get-ListingImages"
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

function New-ListingImage
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

        [Parameter(Mandatory)]
        [Alias('LangCode')]
        [string] $LanguageCode,

        [Parameter(
            Mandatory,
            ParameterSetName="Object")]
        [PSCustomObject[]] $ListingObject,

        [Parameter(ParameterSetName="Individual")]
        [string] $FileName,

        [Parameter(ParameterSetName="Individual")]
        [ValidateSet(
            'HeroImage414x180', 'HeroImage846x468', 'HeroImage558x756', 'HeroImage414x468', 'HeroImage558x558', 'HeroImage2400x1200',
            'Screenshot', 'ScreenshotWXGA', 'ScreenshotHD720', 'ScreenshotWVGA',
            'SmallMobileTile', 'SmallXboxLiveTile', 'LargeMobileTile', 'LargeXboxLiveTile', 'Tile',
            'DesktopIcon', 'Icon', 'AchievementIcon', 'ChallengePromoIcon', 'RewardDisplayIcon', 'Icon150X150', 'Icon71X71',
            'Doublewide', 'Panoramic', 'Square', 'MobileScreenshot', 'XboxScreenshot', 'PpiScreenshot', 'AnalogScreenshot',
            'BoxArt', 'BrandedKeyArt', 'PosterArt', 'FeaturedPromotionalArt', 'SquareHeroArt', 'TitledHeroArt')]
        [string] $Type,

        [Parameter(ParameterSetName="Individual")]

        [ValidateSet('PendingUpload', 'Uploaded', 'InProcessing', 'Processed', 'ProcessFailed')]
        [string] $State,

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
            [StoreBrokerTelemetryProperty]::LanguageCode = $LanguageCode
            [StoreBrokerTelemetryProperty]::Type = $Type
            [StoreBrokerTelemetryProperty]::State = $State
            [StoreBrokerTelemetryProperty]::ClientRequestId = $ClientRequesId
            [StoreBrokerTelemetryProperty]::CorrelationId = $CorrelationId
        }

        $getParams = @()

        if (-not [String]::IsNullOrWhiteSpace($SubmissionId))
        {
            $getParams += "submissionId=$SubmissionId"
        }

        $body = $ListingObject
        if ($null -eq $body)
        {
            # Convert the input into a Json body.
            $hashBody = @{}

            if (-not [String]::IsNullOrWhiteSpace($FileName))
            {
                $hashBody['fileName'] = $FileName
            }

            if (-not [String]::IsNullOrWhiteSpace($Type))
            {
                $hashBody['type'] = $Type
            }

            if (-not [String]::IsNullOrWhiteSpace($State))
            {
                $hashBody['state'] = $State
            }
        }

        $body = $hashBody | ConvertTo-Json

        $uriFragment = "products/$ProductId/listings/$LanguageCode/images`?" + ($getParams -join '&')
        $description = "Creating new $LanguageCode listing image for $ProductId"
        $isbulkOperation = $ListingObject.Count -gt 1
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
    catch [System.InvalidOperationException]
    {
        throw
    }
}
function Remove-ListingImage
{
    [CmdletBinding(SupportsShouldProcess)]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSShouldProcess", "", Justification="Methods called within here make use of PSShouldProcess, and the switch is passed on to them inherently.")]
    [Alias("Delete-ListingImage")]
    param(
        [Parameter(Mandatory)]
        [ValidateScript({if ($_.Length -eq 12) { throw "It looks like you supplied an AppId instead of a ProductId.  Use Get-Products with -AppId to find the ProductId for this AppId." } else { $true }})]
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
        [ValidateScript({if ($_.Length -gt 12) { $true } else { throw "It looks like you supplied an AppId instead of a ProductId.  Use Get-Products with -AppId to find the ProductId for this AppId." }})]
        [string] $ProductId,

        [Parameter(Mandatory)]
        [Alias('LangCode')]
        [string] $LanguageCode,

        [Parameter(Mandatory)]
        [string] $SubmissionId,

        [Parameter(Mandatory)]
        [string] $ImageId,

        [Parameter(
            Mandatory,
            ParameterSetName="Object")]
        [PSCustomObject] $ListingObject,

        [Parameter(ParameterSetName="Individual")]
        [string] $FileName,

        [Parameter(ParameterSetName="Individual")]
        [ValidateSet(
            'HeroImage414x180', 'HeroImage846x468', 'HeroImage558x756', 'HeroImage414x468', 'HeroImage558x558', 'HeroImage2400x1200',
            'Screenshot', 'ScreenshotWXGA', 'ScreenshotHD720', 'ScreenshotWVGA',
            'SmallMobileTile', 'SmallXboxLiveTile', 'LargeMobileTile', 'LargeXboxLiveTile', 'Tile',
            'DesktopIcon', 'Icon', 'AchievementIcon', 'ChallengePromoIcon', 'RewardDisplayIcon', 'Icon150X150', 'Icon71X71',
            'Doublewide', 'Panoramic', 'Square', 'MobileScreenshot', 'XboxScreenshot', 'PpiScreenshot', 'AnalogScreenshot',
            'BoxArt', 'BrandedKeyArt', 'PosterArt', 'FeaturedPromotionalArt', 'SquareHeroArt', 'TitledHeroArt')]
        [string] $Type,

        [Parameter(ParameterSetName="Individual")]
        [ValidateSet('PendingUpload', 'Uploaded', 'InProcessing', 'Processed', 'ProcessFailed')]
        [string] $State,

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
            [StoreBrokerTelemetryProperty]::SubmissionId = $SubmissionId
            [StoreBrokerTelemetryProperty]::LanguageCode = $LanguageCode
            [StoreBrokerTelemetryProperty]::Type = $Type
            [StoreBrokerTelemetryProperty]::State = $State
            [StoreBrokerTelemetryProperty]::RevisionToken = $RevisionToken
            [StoreBrokerTelemetryProperty]::ClientRequestId = $ClientRequesId
            [StoreBrokerTelemetryProperty]::CorrelationId = $CorrelationId
        }

        $getParams = @()

        if (-not [String]::IsNullOrWhiteSpace($SubmissionId))
        {
            $getParams += "submissionId=$SubmissionId"
        }

        $body = $ListingObject
        if ($null -eq $body)
        {
            # Convert the input into a Json body.
            $hashBody = @{}
            $hashBody['revisionToken'] = $RevisionToken

            # Very specifically choosing to NOT use [String]::IsNullOrWhiteSpace for any
            # of these checks, because we need a way to be able to clear these notes out.
            #So, a $null means do nothing, while empty string / whitespace means clear out the value.
            if ($null -ne $FileName)
            {
                $hashBody['fileName'] = $FileName
            }

            if ($null -ne $Type)
            {
                $hashBody['type'] = $Type
            }

            if ($null -ne $State)
            {
                $hashBody['state'] = $State
            }
        }

        $body = $hashBody | ConvertTo-Json

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
    catch [System.InvalidOperationException]
    {
        throw
    }
}

function Get-ListingImage
{
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [ValidateScript({if ($_.Length -gt 12) { $true } else { throw "It looks like you supplied an AppId instead of a ProductId.  Use Get-Products with -AppId to find the ProductId for this AppId." }})]
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

    try
    {
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
            "Method" = 'Get'
            "Description" = "Getting listing image $ImageId for $ProductId"
            "ClientRequestId" = $ClientRequestId
            "CorrelationId" = $CorrelationId
            "AccessToken" = $AccessToken
            "TelemetryEventName" = "Get-ListingImage"
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
