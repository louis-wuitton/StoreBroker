function Get-Listings
{
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [ValidateScript({if ($_.Length -gt 12) { $true } else { throw "It looks like you supplied an AppId instead of a ProductId.  Use Get-Products with -AppId to find the ProductId for this AppId." }})]
        [string] $ProductId,

        [Parameter(Mandatory)]
        [string] $SubmissionId,

        [string] $FeatureGroupId,

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
            [StoreBrokerTelemetryProperty]::ClientRequestId = $ClientRequesId
            [StoreBrokerTelemetryProperty]::CorrelationId = $CorrelationId
        }

        $getParams = @()

        if (-not [String]::IsNullOrWhiteSpace($SubmissionId))
        {
            $getParams += "submissionId=$SubmissionId"
        }

        if (-not [String]::IsNullOrWhiteSpace($FeatureGroupId))
        {
            $getParams += "featureGroupId=$FeatureGroupId"
        }

        $params = @{
            "UriFragment" = "products/$ProductId/listings?" + ($getParams -join '&')
            "Description" = "Getting listings for $ProductId"
            "ClientRequestId" = $ClientRequestId
            "CorrelationId" = $CorrelationId
            "AccessToken" = $AccessToken
            "TelemetryEventName" = "Get-Listings"
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

function New-Listing
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

        [string] $FeatureGroupId,

        [Parameter(
            Mandatory,
            ParameterSetName="Object")]
        [PSCustomObject] $ListingObject,

        [Parameter(ParameterSetName="Individual")]
        [string] $Title,

        [Parameter(ParameterSetName="Individual")]
        [string] $ShortTitle,

        [Parameter(ParameterSetName="Individual")]
        [string] $VoiceTitle,

        [Parameter(ParameterSetName="Individual")]
        [string] $ReleaseNotes,

        [Parameter(ParameterSetName="Individual")]
        [string[]] $Keywords,

        [Parameter(ParameterSetName="Individual")]
        [string] $Trademark,

        [Parameter(ParameterSetName="Individual")]
        [string] $LicenseTerm,

        [Parameter(ParameterSetName="Individual")]
        [string[]] $Features,

        [Parameter(ParameterSetName="Individual")]
        [string[]] $MinimumHardware,

        [Parameter(ParameterSetName="Individual")]
        [string[]] $RecommendedHardware,

        [Parameter(ParameterSetName="Individual")]
        [string] $DevStudio,

        [Parameter(ParameterSetName="Individual")]
        [switch] $ShouldOverridePackageLogos,

        [Parameter(ParameterSetName="Individual")]
        [string] $Description,

        [Parameter(ParameterSetName="Individual")]
        [string] $ShortDescription,

        [Parameter(ParameterSetName="Individual")]
        [string] $Type,

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
            [StoreBrokerTelemetryProperty]::FeatureGroupId = $FeatureGroupId
            [StoreBrokerTelemetryProperty]::ClientRequestId = $ClientRequesId
            [StoreBrokerTelemetryProperty]::CorrelationId = $CorrelationId
        }

        $getParams = @()

        if (-not [String]::IsNullOrWhiteSpace($SubmissionId))
        {
            $getParams += "submissionId=$SubmissionId"
        }

        if (-not [String]::IsNullOrWhiteSpace($FeatureGroupId))
        {
            $getParams += "featureGroupId=$FeatureGroupId"
        }

        $body = $ListingObject
        if ($null -eq $body)
        {
            # Convert the input into a Json body.
            $hashBody = @{}
            $hashBody['languageCode'] = $LanguageCode

            if (-not [String]::IsNullOrWhiteSpace($Title))
            {
                $hashBody['title'] = $Title
            }

            if (-not [String]::IsNullOrWhiteSpace($ShortTitle))
            {
                $hashBody['shortTitle'] = $ShortTitle
            }

            if (-not [String]::IsNullOrWhiteSpace($VoiceTitle))
            {
                $hashBody['voiceTitle'] = $VoiceTitle
            }

            if (-not [String]::IsNullOrWhiteSpace($ReleaseNotes))
            {
                $hashBody['releaseNotes'] = $ReleaseNotes
            }

            if ($null -ne $Keywords)
            {
                $hashBody['keywords'] = @($Keywords)
            }

            if (-not [String]::IsNullOrWhiteSpace($Trademark))
            {
                $hashBody['trademark'] = $Trademark
            }

            if (-not [String]::IsNullOrWhiteSpace($LicenseTerm))
            {
                $hashBody['licenseTerm'] = $LicenseTerm
            }

            if ($null -ne $Features)
            {
                $hashBody['features'] = @($Features)
            }

            if ($null -ne $MinimumHardware)
            {
                $hashBody['minimumHardware'] = @($MinimumHardware)
            }

            if ($null -ne $RecommendedHardware)
            {
                $hashBody['recommendedHardware'] = @($RecommendedHardware)
            }

            if (-not [String]::IsNullOrWhiteSpace($DevStudio))
            {
                $hashBody['devStudio'] = $DevStudio
            }

            # We only set the value if the user explicitly provided a value for this parameter
            # (so for $false, they'd have to pass in -ShouldOverridePackageLogos:$false).
            # Otherwise, there'd be no way to know when the user wants to simply keep the
            # existing value.
            if ($null -ne $PSBoundParameters['ShouldOverridePackageLogos'])
            {
                $hashBody['shouldOverridePackageLogos'] = $ShouldOverridePackageLogos
                $telemetryProperties[[StoreBrokerTelemetryProperty]::ShouldOverridePackageLogos] = $ShouldOverridePackageLogos
            }

            if (-not [String]::IsNullOrWhiteSpace($Description))
            {
                $hashBody['description'] = $Description
            }

            if (-not [String]::IsNullOrWhiteSpace($ShortDescription))
            {
                $hashBody['shortDescription'] = $ShortDescription
            }

            if (-not [String]::IsNullOrWhiteSpace($Type))
            {
                $hashBody['type'] = $Type
            }
        }

        $body = $hashBody | ConvertTo-Json

        $params = @{
            "UriFragment" = "products/$ProductId/listings?" + ($getParams -join '&')
            "Method" = 'Post'
            "Description" = "Creating new $LanguageCode listing for $ProductId"
            "Body" = $body
            "ClientRequestId" = $ClientRequestId
            "CorrelationId" = $CorrelationId
            "AccessToken" = $AccessToken
            "TelemetryEventName" = "New-Listing"
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

function Remove-Listing
{
    [CmdletBinding(SupportsShouldProcess)]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSShouldProcess", "", Justification="Methods called within here make use of PSShouldProcess, and the switch is passed on to them inherently.")]
    [Alias("Delete-Listing")]
    param(
        [Parameter(Mandatory)]
        [ValidateScript({if ($_.Length -eq 12) { throw "It looks like you supplied an AppId instead of a ProductId.  Use Get-Products with -AppId to find the ProductId for this AppId." } else { $true }})]
        [string] $ProductId,

        [Parameter(Mandatory)]
        [string] $SubmissionId,

        [Parameter(Mandatory)]
        [Alias('LangCode')]
        [string] $LanguageCode,

        [string] $FeatureGroupId,

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
        [StoreBrokerTelemetryProperty]::FeatureGroupId = $FeatureGroupId
        [StoreBrokerTelemetryProperty]::ClientRequestId = $ClientRequesId
        [StoreBrokerTelemetryProperty]::CorrelationId = $CorrelationId
    }

    $getParams = @()

    if (-not [String]::IsNullOrWhiteSpace($SubmissionId))
    {
        $getParams += "submissionId=$SubmissionId"
    }

    if (-not [String]::IsNullOrWhiteSpace($FeatureGroupId))
    {
        $getParams += "featureGroupId=$FeatureGroupId"
    }

    $params = @{
        "UriFragment" = "products/$ProductId/listings/$LanguageCode" + ($getParams -join '&')
        "Method" = "Delete"
        "Description" = "Deleting the $LanguageCode listing for $ProductId"
        "ClientRequestId" = $ClientRequestId
        "CorrelationId" = $CorrelationId
        "AccessToken" = $AccessToken
        "TelemetryEventName" = "Remove-Listing"
        "TelemetryProperties" = $telemetryProperties
        "NoStatus" = $NoStatus
    }

    $null = Invoke-SBRestMethod @params
}

function Set-Listing
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

        [string] $FeatureGroupId,

        [Parameter(
            Mandatory,
            ParameterSetName="Object")]
        [PSCustomObject] $ListingObject,

        [Parameter(ParameterSetName="Individual")]
        [string] $Title,

        [Parameter(ParameterSetName="Individual")]
        [string] $ShortTitle,

        [Parameter(ParameterSetName="Individual")]
        [string] $VoiceTitle,

        [Parameter(ParameterSetName="Individual")]
        [string] $ReleaseNotes,

        [Parameter(ParameterSetName="Individual")]
        [string[]] $Keywords,

        [Parameter(ParameterSetName="Individual")]
        [string] $Trademark,

        [Parameter(ParameterSetName="Individual")]
        [string] $LicenseTerm,

        [Parameter(ParameterSetName="Individual")]
        [string[]] $Features,

        [Parameter(ParameterSetName="Individual")]
        [string[]] $MinimumHardware,

        [Parameter(ParameterSetName="Individual")]
        [string[]] $RecommendedHardware,

        [Parameter(ParameterSetName="Individual")]
        [string] $DevStudio,

        [Parameter(ParameterSetName="Individual")]
        [switch] $ShouldOverridePackageLogos,

        [Parameter(ParameterSetName="Individual")]
        [string] $Description,

        [Parameter(ParameterSetName="Individual")]
        [string] $ShortDescription,

        [Parameter(
            Mandatory,
            ParameterSetName="Individual")]
        [string] $RevisionToken,

        [Parameter(ParameterSetName="Individual")]
        [string] $Type,

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
            [StoreBrokerTelemetryProperty]::FeatureGroupId = $FeatureGroupId
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
            $hashBody['languageCode'] = $LanguageCode
            $hashBody['revisionToken'] = $RevisionToken

            # Very specifically choosing to NOT use [String]::IsNullOrWhiteSpace for any
            # of these checks, because we need a way to be able to clear these notes out.
            #So, a $null means do nothing, while empty string / whitespace means clear out the value.
            if ($null -ne $Title)
            {
                $hashBody['title'] = $Title
            }

            if ($null -ne $ShortTitle)
            {
                $hashBody['shortTitle'] = $ShortTitle
            }

            if ($null -ne $VoiceTitle)
            {
                $hashBody['voiceTitle'] = $VoiceTitle
            }

            if ($null -ne $ReleaseNotes)
            {
                $hashBody['releaseNotes'] = $ReleaseNotes
            }

            if ($null -ne $Keywords)
            {
                $hashBody['keywords'] = @($Keywords)
            }

            if ($null -ne $Trademark)
            {
                $hashBody['trademark'] = $Trademark
            }

            if ($null -ne $LicenseTerm)
            {
                $hashBody['licenseTerm'] = $LicenseTerm
            }

            if ($null -ne $Features)
            {
                $hashBody['features'] = @($Features)
            }

            if ($null -ne $MinimumHardware)
            {
                $hashBody['minimumHardware'] = @($MinimumHardware)
            }

            if ($null -ne $RecommendedHardware)
            {
                $hashBody['recommendedHardware'] = @($RecommendedHardware)
            }

            if ($null -ne $DevStudio)
            {
                $hashBody['devStudio'] = $DevStudio
            }

            # We only set the value if the user explicitly provided a value for this parameter
            # (so for $false, they'd have to pass in -ShouldOverridePackageLogos:$false).
            # Otherwise, there'd be no way to know when the user wants to simply keep the
            # existing value.
            if ($null -ne $PSBoundParameters['ShouldOverridePackageLogos'])
            {
                $hashBody['shouldOverridePackageLogos'] = $ShouldOverridePackageLogos
                $telemetryProperties[[StoreBrokerTelemetryProperty]::ShouldOverridePackageLogos] = $ShouldOverridePackageLogos
            }

            if ($null -ne $Description)
            {
                $hashBody['description'] = $Description
            }

            if ($null -ne $ShortDescription)
            {
                $hashBody['shortDescription'] = $ShortDescription
            }

            if ($null -ne $Type)
            {
                $hashBody['type'] = $Type
            }
        }

        $body = $hashBody | ConvertTo-Json

        $params = @{
            "UriFragment" = "products/$ProductId/listings/$LanguageCode?" + ($getParams -join '&')
            "Method" = 'Put'
            "Description" = "Updating $LanguageCode listing for $ProductId"
            "Body" = $body
            "ClientRequestId" = $ClientRequestId
            "CorrelationId" = $CorrelationId
            "AccessToken" = $AccessToken
            "TelemetryEventName" = "Set-Listing"
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

function Get-Listing
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

        [string] $FeatureGroupId,

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
            [StoreBrokerTelemetryProperty]::FeatureGroupId = $FeatureGroupId
            [StoreBrokerTelemetryProperty]::ClientRequestId = $ClientRequesId
            [StoreBrokerTelemetryProperty]::CorrelationId = $CorrelationId
        }

        $getParams = @()

        if (-not [String]::IsNullOrWhiteSpace($SubmissionId))
        {
            $getParams += "submissionId=$SubmissionId"
        }

        if (-not [String]::IsNullOrWhiteSpace($FeatureGroupId))
        {
            $getParams += "featureGroupId=$FeatureGroupId"
        }

        $params = @{
            "UriFragment" = "products/$ProductId/listings/$LanguageCode?" + ($getParams -join '&')
            "Method" = 'Get'
            "Description" = "Getting $LanguageCode listing for $ProductId"
            "ClientRequestId" = $ClientRequestId
            "CorrelationId" = $CorrelationId
            "AccessToken" = $AccessToken
            "TelemetryEventName" = "Get-Listing"
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
