function Get-ListingVideos
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
            "UriFragment" = "products/$ProductId/listings/$LanguageCode/videos?" + ($getParams -join '&')
            "Description" = "Getting listing videos for $ProductId"
            "ClientRequestId" = $ClientRequestId
            "CorrelationId" = $CorrelationId
            "AccessToken" = $AccessToken
            "TelemetryEventName" = "Get-ListingVideos"
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

function New-ListingVideo
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
        [string] $StreamingUri,

        [Parameter(ParameterSetName="Individual")]
        [ValidateSet('PendingUpload', 'Uploaded', 'InProcessing', 'Processed', 'ProcessFailed')]
        [string] $State,

        [Parameter(ParameterSetName="Individual")]
        [string] $ThumbnailFileName,

        [Parameter(ParameterSetName="Individual")]
        [string] $ThumbnailTitle,

        [Parameter(ParameterSetName="Individual")]
        [string] $ThumbnailDescription,

        [Parameter(ParameterSetName="Individual")]
        [ValidateSet('PendingUpload', 'Uploaded', 'InProcessing', 'Processed', 'ProcessFailed')]
        [string] $ThumbnailState,

        [Parameter(ParameterSetName="Individual")]
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

            if (-not [String]::IsNullOrWhiteSpace($RevisionToken))
            {
                $hashBody['revisionToken'] = $RevisionToken
            }
        }

        if ($null -eq $body)
        {
            # Convert the input into a Json body.
            $hashBody = @{}

            if (-not [String]::IsNullOrWhiteSpace($FileName))
            {
                $hashBody['fileName'] = $FileName
            }

            if (-not [String]::IsNullOrWhiteSpace($State))
            {
                $hashBody['state'] = $State
            }

            if ($null -ne $StreamingUri)
            {
                $hashBody['streamingUri'] = $StreamingUri
            }

            if (($null -ne $ThumbnailFileName) -or ($null -ne $ThumbnailTitle) -or ($null -ne $ThumbnailDescription) -or ($null -ne $ThumbnailState))
            {
                $hashBody['thumbnail'] = @{}
                if ($null -ne $ThumbnailFileName)
                {
                    $hashBody['thumbnail']['fileName'] = $ThumbnailFileName
                }

                if ($null -ne $ThumbnailTitle)
                {
                    $hashBody['thumbnail']['title'] = $ThumbnailTitle
                }

                if ($null -ne $ThumbnailDescription)
                {
                    $hashBody['thumbnail']['description'] = $ThumbnailDescription
                }

                if ($null -ne $ThumbnailState)
                {
                    $hashBody['thumbnail']['state'] = $ThumbnailState
                }
            }

            if ($null -ne $RevisionToken)
            {
                $hashBody['revisionToken'] = $RevisionToken
            }
        }


        $body = $hashBody | ConvertTo-Json

        $uriFragment = "products/$ProductId/listings/$LanguageCode/videos?" + ($getParams -join '&')
        $description = "Creating new $LanguageCode listing videos for $ProductId"
        if ($ListingObject.Count -gt 1)
        {
            $uriFragment = "products/$ProductId/listings/$LanguageCode/videos/bulk?" + ($getParams -join '&')
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

        return Invoke-SBRestMethod @params
    }
    catch [System.InvalidOperationException]
    {
        throw
    }
}
function Remove-ListingVideo
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

        [Parameter(Mandatory)]
        [string] $VideoId,

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
        "UriFragment" = "products/$ProductId/listings/$LanguageCode/images/$ImageId?" + ($getParams -join '&')
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
        [string] $StreamingUri,

        [Parameter(ParameterSetName="Individual")]
        [ValidateSet('PendingUpload', 'Uploaded', 'InProcessing', 'Processed', 'ProcessFailed')]
        [string] $State,

        [Parameter(ParameterSetName="Individual")]
        [string] $ThumbnailFileName,

        [Parameter(ParameterSetName="Individual")]
        [string] $ThumbnailTitle,

        [Parameter(ParameterSetName="Individual")]
        [string] $ThumbnailDescription,

        [Parameter(ParameterSetName="Individual")]
        [ValidateSet('PendingUpload', 'Uploaded', 'InProcessing', 'Processed', 'ProcessFailed')]
        [string] $ThumbnailState,

        [Parameter(ParameterSetName="Individual")]
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

            # Very specifically choosing to NOT use [String]::IsNullOrWhiteSpace for any
            # of these checks, because we need a way to be able to clear these notes out.
            #So, a $null means do nothing, while empty string / whitespace means clear out the value.
            if ($null -ne $FileName)
            {
                $hashBody['fileName'] = $FileName
            }

            if ($null -ne $State)
            {
                $hashBody['state'] = $State
            }

            if ($null -ne $StreamingUri)
            {
                $hashBody['streamingUri'] = $StreamingUri
            }

            if (($null -ne $ThumbnailFileName) -or ($null -ne $ThumbnailTitle) -or ($null -ne $ThumbnailDescription) -or ($null -ne $ThumbnailState))
            {
                $hashBody['thumbnail'] = @{}
                if ($null -ne $ThumbnailFileName)
                {
                    $hashBody['thumbnail']['fileName'] = $ThumbnailFileName
                }

                if ($null -ne $ThumbnailTitle)
                {
                    $hashBody['thumbnail']['title'] = $ThumbnailTitle
                }

                if ($null -ne $ThumbnailDescription)
                {
                    $hashBody['thumbnail']['description'] = $ThumbnailDescription
                }

                if ($null -ne $ThumbnailState)
                {
                    $hashBody['thumbnail']['state'] = $ThumbnailState
                }
            }

            if ($null -ne $RevisionToken)
            {
                $hashBody['revisionToken'] = $RevisionToken
            }
        }

        $body = $hashBody | ConvertTo-Json

        $params = @{
            "UriFragment" = "products/$ProductId/listings/$LanguageCode/Videos/$VideoId?" + ($getParams -join '&')
            "Method" = 'Post'
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
    catch [System.InvalidOperationException]
    {
        throw
    }
}

function Get-ListingVideo
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
        [string] $VideoId,

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
            "UriFragment" = "products/$ProductId/listings/$LanguageCode/videos/$VideoId?" + ($getParams -join '&')
            "Method" = 'Get'
            "Description" = "Getting listing video $VideoId for $ProductId"
            "ClientRequestId" = $ClientRequestId
            "CorrelationId" = $CorrelationId
            "AccessToken" = $AccessToken
            "TelemetryEventName" = "Get-ListingVideo"
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
