# Copyright (C) Microsoft Corporation.  All rights reserved.

function Update-Submission
{
    [CmdletBinding(
        SupportsShouldProcess,
        DefaultParametersetName="AddPackages")]
    [OutputType([Object[]])]
    param(
        [Parameter(Mandatory)]
        [string] $AppId,

        [Parameter(Mandatory)]
        [ValidateScript({if (Test-Path -Path $_ -PathType Leaf) { $true } else { throw "$_ cannot be found." }})]
        [string] $JsonPath,

        [ValidateScript({if (Test-Path -Path $_ -PathType Leaf) { $true } else { throw "$_ cannot be found." }})]
        [string] $ZipPath,

        [ValidateScript({if (Test-Path -Path $_ -PathType Container) { $true } else { throw "$_ cannot be found." }})]
        [string] $ContentPath,

        [switch] $AutoCommit,

        [string] $SubmissionId = "",

        [ValidateSet('Default', 'Immediate', 'Manual', 'SpecificDate')]
        [string] $TargetPublishMode = $script:keywordDefault,

        [DateTime] $TargetPublishDate,

        [ValidateSet('Default', 'Public', 'Private', 'Hidden')]
        [string] $Visibility = $script:keywordDefault,

        [ValidateSet('NoAction', 'Finalize', 'Halt')]
        [string] $ExistingPackageRolloutAction = $script:keywordNoAction,

        [ValidateRange(0, 100)]
        [double] $PackageRolloutPercentage = -1,

        [switch] $IsMandatoryUpdate,

        [DateTime] $MandatoryUpdateEffectiveDate,

        [ValidateScript({if ([System.String]::IsNullOrEmpty($SubmissionId) -or !$_) { $true } else { throw "Can't use -Force and supply a SubmissionId." }})]
        [switch] $Force,

        [Parameter(ParameterSetName="AddPackages")]
        [switch] $AddPackages,

        [Parameter(ParameterSetName="ReplacePackages")]
        [switch] $ReplacePackages,

        [switch] $UpdateListings,

        [switch] $UpdatePublishModeAndVisibility,

        [switch] $UpdatePricingAndAvailability,

        [switch] $UpdateAppProperties,

        [switch] $UpdateGamingOptions,

        [switch] $UpdateTrailers,

        [switch] $UpdateNotesForCertification,

        [string] $ClientRequestId,

        [string] $CorrelationId,

        [string] $AccessToken = "",

        [switch] $NoStatus
    )

    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

    Write-Log -Message "Executing: $($MyInvocation.Line)" -Level Verbose

    Write-Log -Message "Reading in the submission content from: $JsonPath" -Level Verbose
    if ($PSCmdlet.ShouldProcess($JsonPath, "Get-Content"))
    {
        $submission = [string](Get-Content $JsonPath -Encoding UTF8) | ConvertFrom-Json
    }

    # Extra layer of validation to protect users from trying to submit a payload to the wrong application
    if ([String]::IsNullOrWhiteSpace($submission.appId))
    {
        $configPath = Join-Path -Path ([System.Environment]::GetFolderPath('Desktop')) -ChildPath 'newconfig.json'

        Write-Log -Level Warning -Message @(
            "The config file used to generate this submission did not have an AppId defined in it.",
            "The AppId entry in the config helps ensure that payloads are not submitted to the wrong application.",
            "Please update your app's StoreBroker config file by adding an `"appId`" property with",
            "your app's AppId to the `"appSubmission`" section.  If you're unclear on what change",
            "needs to be done, you can re-generate your config file using",
            "   New-StoreBrokerConfigFile -AppId $AppId -Path `"$configPath`"",
            "and then diff the new config file against your current one to see the requested appId change.")
    }
    else
    {
        if ($AppId -ne $submission.appId)
        {
            $output = @()
            $output += "The AppId [$($submission.appId)] in the submission content [$JsonPath] does not match the intended AppId [$AppId]."
            $output += "You either entered the wrong AppId at the commandline, or you're referencing the wrong submission content to upload."

            $newLineOutput = ($output -join [Environment]::NewLine)
            Write-Log -Message $newLineOutput -Level Error
            throw $newLineOutput
        }
    }

    # Identify potentially incorrect usage of this method by checking to see if no modification
    # switch was provided by the user
    if ((-not $AddPackages) -and
        (-not $ReplacePackages) -and
        (-not $UpdateListings) -and
        (-not $UpdatePublishModeAndVisibility) -and
        (-not $UpdatePricingAndAvailability) -and
        (-not $UpdateAppProperties) -and
        (-not $UpdateGamingOptions) -and
        (-not $UpdateTrailers) -and
        (-not $UpdateNotesForCertification))
    {
        Write-Log -Level Warning -Message @(
            "You have not specified any `"modification`" switch for updating the submission.",
            "This means that the new submission will be identical to the current one.",
            "If this was not your intention, please read-up on the documentation for this command:",
            "     Get-Help Update-ApplicationSubmission -ShowWindow")
    }

    try
    {
        if ([System.String]::IsNullOrEmpty($SubmissionId))
        {
            $submissionToUpdate = New-ApplicationSubmission -AppId $AppId -ExistingPackageRolloutAction $ExistingPackageRolloutAction -Force:$Force -AccessToken $AccessToken -NoStatus:$NoStatus
        }
        else
        {
            $submissionToUpdate = Get-ApplicationSubmission -AppId $AppId -SubmissionId $SubmissionId -AccessToken $AccessToken -NoStatus:$NoStatus
            if ($submissionToUpdate.status -ne $script:keywordPendingCommit)
            {
                $output = @()
                $output += "We can only modify a submission that is in the '$script:keywordPendingCommit' state."
                $output += "The submission that you requested to modify ($SubmissionId) is in '$($submissionToUpdate.status)' state."

                $newLineOutput = ($output -join [Environment]::NewLine)
                Write-Log -Message $newLineOutput -Level Error
                throw $newLineOutput
            }
        }

        if ($PSCmdlet.ShouldProcess("Patch-ApplicationSubmission"))
        {
            $params = @{}
            $params.Add("ClonedSubmission", $submissionToUpdate)
            $params.Add("NewSubmission", $submission)
            $params.Add("TargetPublishMode", $TargetPublishMode)
            if ($null -ne $TargetPublishDate) { $params.Add("TargetPublishDate", $TargetPublishDate) }
            $params.Add("Visibility", $Visibility)
            $params.Add("UpdateListings", $UpdateListings)
            $params.Add("UpdatePublishModeAndVisibility", $UpdatePublishModeAndVisibility)
            $params.Add("UpdatePricingAndAvailability", $UpdatePricingAndAvailability)
            $params.Add("UpdateAppProperties", $UpdateAppProperties)
            $params.Add("UpdateGamingOptions", $UpdateGamingOptions)
            $params.Add("UpdateTrailers", $UpdateTrailers)
            $params.Add("UpdateNotesForCertification", $UpdateNotesForCertification)
            if ($PackageRolloutPercentage -ge 0) { $params.Add("PackageRolloutPercentage", $PackageRolloutPercentage) }
            $params.Add("IsMandatoryUpdate", $IsMandatoryUpdate)
            if ($null -ne $MandatoryUpdateEffectiveDate) { $params.Add("MandatoryUpdateEffectiveDate", $MandatoryUpdateEffectiveDate) }

            # Because these are mutually exclusive and tagged as such, we have to be sure to *only*
            # add them to the parameter set if they're true.
            if ($AddPackages) { $params.Add("AddPackages", $AddPackages) }
            if ($ReplacePackages) { $params.Add("ReplacePackages", $ReplacePackages) }

            $patchedSubmission = Patch-ApplicationSubmission @params
        }

        if ($PSCmdlet.ShouldProcess("Set-ApplicationSubmission"))
        {
            $params = @{}
            $params.Add("AppId", $AppId)
            $params.Add("UpdatedSubmission", $patchedSubmission)
            $params.Add("AccessToken", $AccessToken)
            $params.Add("NoStatus", $NoStatus)
            $replacedSubmission = Set-ApplicationSubmission @params
        }

        $submissionId = $replacedSubmission.id
        $uploadUrl = $replacedSubmission.fileUploadUrl

        Write-Log -Message @(
            "Successfully cloned the existing submission and modified its content.",
            "You can view it on the Dev Portal here:",
            "    https://dev.windows.com/en-us/dashboard/apps/$AppId/submissions/$submissionId/",
            "or by running this command:",
            "    Get-ApplicationSubmission -AppId $AppId -SubmissionId $submissionId | Format-ApplicationSubmission",
            "",
            ($script:manualPublishWarning -f 'Update-ApplicationSubmission'))

        if (![System.String]::IsNullOrEmpty($ZipPath))
        {
            Write-Log -Message "Uploading the package [$ZipPath] since it was provided." -Level Verbose
            Set-SubmissionPackage -ZipPath $ZipPath -UploadUrl $uploadUrl -NoStatus:$NoStatus
        }
        elseif (!$AutoCommit)
        {
            Write-Log -Message @(
                "Your next step is to upload the package using:",
                "  Upload-SubmissionPackage -ZipPath <package> -UploadUrl `"$uploadUrl`"")
        }

        if ($AutoCommit)
        {
            if ($stopwatch.Elapsed.TotalSeconds -gt $script:accessTokenTimeoutSeconds)
            {
                # The package upload probably took a long time.
                # There's a high likelihood that the token will be considered expired when we call
                # into Complete-ApplicationSubmission ... so, we'll send in a $null value and
                # let it acquire a new one.
                $AccessToken = $null
            }

            Write-Log -Message "Commiting the submission since -AutoCommit was requested." -Level Verbose
            Complete-ApplicationSubmission -AppId $AppId -SubmissionId $submissionId -AccessToken $AccessToken -NoStatus:$NoStatus
        }
        else
        {
            Write-Log -Message @(
                "When you're ready to commit, run this command:",
                "  Commit-ApplicationSubmission -AppId $AppId -SubmissionId $submissionId")
        }

        # Record the telemetry for this event.
        $stopwatch.Stop()
        $telemetryMetrics = @{ [StoreBrokerTelemetryMetric]::Duration = $stopwatch.Elapsed.TotalSeconds }
        $telemetryProperties = @{
            [StoreBrokerTelemetryProperty]::AppId = $AppId
            [StoreBrokerTelemetryProperty]::SubmissionId = $SubmissionId
            [StoreBrokerTelemetryProperty]::ZipPath = (Get-PiiSafeString -PlainText $ZipPath)
            [StoreBrokerTelemetryProperty]::AutoCommit = $AutoCommit
            [StoreBrokerTelemetryProperty]::Force = $Force
            [StoreBrokerTelemetryProperty]::PackageRolloutPercentage = $PackageRolloutPercentage
            [StoreBrokerTelemetryProperty]::IsMandatoryUpdate = [bool]$IsMandatoryUpdate
            [StoreBrokerTelemetryProperty]::AddPackages = $AddPackages
            [StoreBrokerTelemetryProperty]::UpdateListings = $UpdateListings
            [StoreBrokerTelemetryProperty]::UpdatePublishModeAndVisibility = $UpdatePublishModeAndVisibility
            [StoreBrokerTelemetryProperty]::UpdatePricingAndAvailability = $UpdatePricingAndAvailability
            [StoreBrokerTelemetryProperty]::UpdateGamingOptions = $UpdateGamingOptions
            [StoreBrokerTelemetryProperty]::UpdateTrailers = $UpdateTrailers
            [StoreBrokerTelemetryProperty]::UpdateAppProperties = $UpdateAppProperties
            [StoreBrokerTelemetryProperty]::UpdateNotesForCertification = $UpdateNotesForCertification
            [StoreBrokerTelemetryProperty]::ClientRequestId = $ClientRequesId
            [StoreBrokerTelemetryProperty]::CorrelationId = $CorrelationId
            }

        Set-TelemetryEvent -EventName Update-ApplicationSubmission -Properties $telemetryProperties -Metrics $telemetryMetrics

        return $submissionId, $uploadUrl
    }
    catch
    {
        Write-Log -Exception $_ -Level Error
        throw
    }
}

# Internal helper
# Operates on an existing submissionId
function Patch-ProductPackages
{
    [CmdletBinding(
        SupportsShouldProcess,
        DefaultParametersetName="AddPackages")]
    param(
        [Parameter(Mandatory)]
        [string] $ProductId,

        [Parameter(Mandatory)]
        [string] $SubmissionId,

        [Parameter(Mandatory)]
        [PSCustomObject] $SubmissionData,

        [ValidateScript({if (Test-Path -Path $_ -PathType Container) { $true } else { throw "$_ cannot be found." }})]
        [string] $ContentPath, # NOTE: The main wrapper should unzip the zip (if there is one), so that all internal helpers only operate on a Contentpath

        [Parameter(ParameterSetName="AddPackages")]
        [switch] $AddPackages,

        [Parameter(ParameterSetName="ReplacePackages")]
        [switch] $ReplacePackages,

        [Parameter(ParameterSetName="UpdatePackages")]
        [switch] $UpdatePackages,

        [Parameter(ParameterSetName="UpdatePackages")]
        [int] $RedundantPackagesToKeep = 1,

        [string] $ClientRequestId,

        [string] $CorrelationId,

        [string] $AccessToken,

        [switch] $NoStatus
    )

    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

    if (($AddPackages -or $ReplacePackages -or $UpdatePackages) -and ($SubmissionData.applicationPackages.Count -eq 0))
    {
        $output = @()
        $output += "Your submission doesn't contain any packages, so you cannot Add, Replace or Update packages."
        $output += "Please check your input settings to New-SubmissionPackage and ensure you're providing a value for AppxPath."
        $output = $output -join [Environment]::NewLine
        Write-Log -Message $output -Level Error
        throw $output
    }

    if ((-not $AddPackages) -and (-not $ReplacePackages) -and (-not $UpdatePackages))
    {
        return
    }

    $params = @{
        'ProductId' = $ProductId
        'SubmissionId' = $SubmissionId
        'ClientRequestId' = $ClientRequestId
        'CorrelationId' = $CorrelationId
        'AccessToken' = $AccessToken
        'NoStatus' = $NoStatus
    }

    if ($ReplacePackages)
    {
        # Get all of the current packages in the submission and delete them
        $packages = Get-ProductPackage @params
        foreach ($package in $packages)
        {
            $null = Remove-ProductPackage @params -PackageId $package.id
        }
    }
    elseif ($UpdatePackages)
    {
        # TODO -- Better understand the current object model so that we can accurately determine
        # which packages are redundant.
        # TODO: BE CAREFUL ABOUT KEEPING PRE-WIN 10 PACKAGES!!!
    }

    # Regardless of which method we're following, the last thing that we'll do is get these new
    # associated with this submission
    foreach ($package in $SubmissionData.applicationPackages)
    {
        $params['FileName'] = (Split-Path -Path $package.fileName -Leaf)
        $packageSubmission = New-ProductPackage @params
        $null = Set-StoreFile -FilePath (Join-Path -Path $ContentPath -ChildPath $package.fileName) -SasUri $packageSubmission.fileSasUri -NoStatus:$NoStatus
        $packageSubmission.state = [StoreBrokerFileState]::Uploaded.ToString()
        $null = Set-ProductPackage @params -Object $packageSubmission
    }

    # Record the telemetry for this event.
    $stopwatch.Stop()
    $telemetryMetrics = @{ [StoreBrokerTelemetryMetric]::Duration = $stopwatch.Elapsed.TotalSeconds }
    $telemetryProperties = @{
        [StoreBrokerTelemetryProperty]::ProductId = $ProductId
        [StoreBrokerTelemetryProperty]::SubmissionId = $SubmissionId
        [StoreBrokerTelemetryProperty]::ContentPath = (Get-PiiSafeString -PlainText $ContentPath)
        [StoreBrokerTelemetryProperty]::AddPackages = $AddPackages
        [StoreBrokerTelemetryProperty]::ReplacePackages = $ReplacePackages
        [StoreBrokerTelemetryProperty]::UpdatePackages = $UpdatePackages
        [StoreBrokerTelemetryProperty]::RedundantPackagesToKeep = $RedundantPackagesToKeep
        [StoreBrokerTelemetryProperty]::ClientRequestId = $ClientRequesId
        [StoreBrokerTelemetryProperty]::CorrelationId = $CorrelationId
    }

    Set-TelemetryEvent -EventName Patch-SubmissionPackage -Properties $telemetryProperties -Metrics $telemetryMetrics
    return
}

# Internal helper
# Operates on an existing submissionId
function Patch-Listings
{
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [string] $ProductId,

        [Parameter(Mandatory)]
        [string] $SubmissionId,

        [Parameter(Mandatory)]
        [PSCustomObject] $SubmissionData,

        [ValidateScript({if (Test-Path -Path $_ -PathType Container) { $true } else { throw "$_ cannot be found." }})]
        [string] $ContentPath, # NOTE: The main wrapper should unzip the zip (if there is one), so that all internal helpers only operate on a Contentpath

        [Parameter(Mandatory)]
        [Alias('LangCode')]
        [string] $LanguageCode,

        [switch] $UpdateTrailers,

        [string] $ClientRequestId,

        [string] $CorrelationId,

        [string] $AccessToken,

        [switch] $NoStatus
    )

    $indentLevel = 2

    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

    $params = @{
        'ProductId' = $ProductId
        'SubmissionId' = $SubmissionId
        'ClientRequestId' = $ClientRequestId
        'CorrelationId' = $CorrelationId
        'AccessToken' = $AccessToken
        'NoStatus' = $NoStatus
    }

    # Determine what our current listings are.
    $currentListings = Get-Listing @params

    # We need to keep track of languages in $currentListings that don't have a match in
    # $SubmissionData (so that we can remove them), as well which languages occur in $SubmissionData
    # that aren't in $currentListings so that we can add them.  We don't simply delete all and start
    # over due to the increased time/cost that we'd have by doing so.
    [System.Collections.ArrayList]$listingsToDelete = @()
    [System.Collections.ArrayList]$clonedLangCodes = @()

    # First we delete all of the existing images
    Write-Log -Message 'Updating the cloned listings with information supplied by user data.' -Level Verbose -Indent $indentLevel
    foreach ($listing in $currentListings)
    {
        $suppliedListing = $SubmissionData.listings.($listing.languageCode).baseListing
        if ($null -eq $suppliedListing)
        {
            $listingsToDelete.Add($listing.languageCode)
            continue
        }

        # Updating the existing Listing submission with the user's supplied content
        $listing.shortTitle = $suppliedListing.shortTitle
        $listing.voiceTitle = $suppliedListing.voiceTitle
        $listing.releaseNotes = $suppliedListing.releaseNotes
        $listing.keywords = $suppliedListing.keywords
        $listing.trademark = $suppliedListing.copyrightAndTrademarkInfo
        $listing.licenseTerm = $suppliedListing.licenseTerms
        $listing.features = $suppliedListing.features
        $listing.recommendedHardware = $suppliedListing.minimumHardware
        $listing.devStudio = $suppliedListing.devStudio
        #TODO: $listing.shouldOverridePackageLogos = ???
        $listing.title = $suppliedListing.title
        $listing.description = $suppliedListing.description
        $listing.shortDescription = $suppliedListing.shortDescription

        $langCode = $listing.languageCode
        $clonedLangCodes.Add($langCode)

        $null = Set-Listing @params -Object $listing
        $null = Patch-ListingImages @params -LanguageCode $langCode

        if ($UpdateTrailers)
        {
            $null = Patch-ListingVideos @params -LanguageCode $langCode
        }
    }

    # Now we have to see what languages exist in the user's supplied content that we didn't already
    # have cloned submissions for
    Write-Log -Message 'Now adding listings for languages that didn''t have pre-existing clones.' -Level Verbose -Indent $indentLevel
    $SubmissionData.listings |
        Get-Member -Type NoteProperty |
            ForEach-Object {
                $langCode = $_.Name
                $suppliedListing = $SubmissionData.listings.$langCode.baselisting
                if (-not $clonedLangCodes.Contains($langCode))
                {
                    $listingParams = $params.PSObject.Copy() # Get a new instance, not a reference
                    $listingParams['LanguageCode'] = $langCode
                    $listingParams['ShortTitle'] = $suppliedListing.shortTitle
                    $listingParams['VoiceTitle'] = $suppliedListing.voiceTitle
                    $listingParams['ReleaseNotes'] = $suppliedListing.releaseNotes
                    $listingParams['Keywords'] = $suppliedListing.keywords
                    $listingParams['Trademark'] = $suppliedListing.copyrightAndTrademarkInfo
                    $listingParams['LicenseTerm'] = $suppliedListing.licenseTerms
                    $listingParams['Features'] = $suppliedListing.features
                    $listingParams['RecommendedHardware'] = $suppliedListing.minimumHardware
                    $listingParams['DevStudio'] = $suppliedListing.devStudio
                    #TODO: $listingParams['shouldOverridePackageLogos'] = ???
                    $listingParams['Title'] = $suppliedListing.title
                    $listingParams['Description'] = $suppliedListing.description
                    $listingParams['ShortDescription'] = $suppliedListing.shortDescription

                    $null = New-Listing @listingParams
                    $null = Patch-ListingImages @params -LanguageCode $langCode

                    if ($UpdateTrailers)
                    {
                        $null = Patch-ListingVideos @params -LanguageCode $langCode
                    }
                }
            }

    Write-Log -Message 'Now removing listings for languages that were cloned by the submission but don''t have current user data.' -Level Verbose -Indent $indentLevel
    foreach ($langCode in $listingsToDelete)
    {
        $null = Remove-Listing @params -LanguageCode $langCode
        $null = Patch-ListingImages @params -LanguageCode $langCode -RemoveOnly
    }

    # Record the telemetry for this event.
    $stopwatch.Stop()
    $telemetryMetrics = @{ [StoreBrokerTelemetryMetric]::Duration = $stopwatch.Elapsed.TotalSeconds }
    $telemetryProperties = @{
        [StoreBrokerTelemetryProperty]::ProductId = $ProductId
        [StoreBrokerTelemetryProperty]::SubmissionId = $SubmissionId
        [StoreBrokerTelemetryProperty]::ContentPath = (Get-PiiSafeString -PlainText $ContentPath)
        [StoreBrokerTelemetryProperty]::ClientRequestId = $ClientRequesId
        [StoreBrokerTelemetryProperty]::CorrelationId = $CorrelationId
    }

    Set-TelemetryEvent -EventName Patch-Listings -Properties $telemetryProperties -Metrics $telemetryMetrics
    return
}

# Internal helper
# Operates on an existing submissionId
function Patch-ListingImages
{
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [string] $ProductId,

        [Parameter(Mandatory)]
        [string] $SubmissionId,

        [Parameter(Mandatory)]
        [PSCustomObject] $SubmissionData,

        [ValidateScript({if (Test-Path -Path $_ -PathType Container) { $true } else { throw "$_ cannot be found." }})]
        [string] $ContentPath, # NOTE: The main wrapper should unzip the zip (if there is one), so that all internal helpers only operate on a Contentpath

        [Parameter(Mandatory)]
        [Alias('LangCode')]
        [string] $LanguageCode,

        [switch] $RemoveOnly,

        [string] $ClientRequestId,

        [string] $CorrelationId,

        [string] $AccessToken,

        [switch] $NoStatus
    )

    $indentLevel = 4

    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

    $params = @{
        'ProductId' = $ProductId
        'SubmissionId' = $SubmissionId
        'LanguageCode' = $LanguageCode
        'ClientRequestId' = $ClientRequestId
        'CorrelationId' = $CorrelationId
        'AccessToken' = $AccessToken
        'NoStatus' = $NoStatus
    }

    $currentImages = Get-ListingImage @params

    # First we delete all of the existing images
    Write-Log -Message "Removing all [$LanguageCode] listing images." -Level Verbose -Indent $indentLevel
    foreach ($image in $currentImages)
    {
        $null = Remove-ListingImage @params -ImageId $image.id
    }

    if (-not $RemoveOnly)
    {
        # Then we proceed with adding/uploading all of the current images
        Write-Log -Message "Creating [$LanguageCode] listing images." -Level Verbose -Indent $indentLevel
        foreach ($image in $SubmissionData.listings.$LanguageCode.baseListing.images)
        {
            # TODO: Determine if we should expose Orientation to the PDP and then here.
            $imageSubmission = New-ListingImage @params -FileName (Split-Path -Path $image.fileName -Leaf) -Type $image.imageType
            $null = Set-StoreFile -FilePath (Join-Path -Path $ContentPath -ChildPath $image.fileName) -SasUri $imageSubmission.fileSasUri -NoStatus:$NoStatus
            $imageSubmission.state = [StoreBrokerFileState]::Uploaded.ToString()
            $null = Set-ListingImage @params -Object $imageSubmission
        }
    }

    # Record the telemetry for this event.
    $stopwatch.Stop()
    $telemetryMetrics = @{ [StoreBrokerTelemetryMetric]::Duration = $stopwatch.Elapsed.TotalSeconds }
    $telemetryProperties = @{
        [StoreBrokerTelemetryProperty]::ProductId = $ProductId
        [StoreBrokerTelemetryProperty]::SubmissionId = $SubmissionId
        [StoreBrokerTelemetryProperty]::LanguageCode = $LanguageCode
        [StoreBrokerTelemetryProperty]::ContentPath = (Get-PiiSafeString -PlainText $ContentPath)
        [StoreBrokerTelemetryProperty]::LanguageCode = $LanguageCode
        [StoreBrokerTelemetryProperty]::RemoveOnly = $RemoveOnly
        [StoreBrokerTelemetryProperty]::ClientRequestId = $ClientRequesId
        [StoreBrokerTelemetryProperty]::CorrelationId = $CorrelationId
    }

    Set-TelemetryEvent -EventName Patch-ListingImages -Properties $telemetryProperties -Metrics $telemetryMetrics
    return
}

# Internal helper
# Operates on an existing submissionId
function Patch-ListingVideos
{
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [string] $ProductId,

        [Parameter(Mandatory)]
        [string] $SubmissionId,

        [Parameter(Mandatory)]
        [PSCustomObject] $SubmissionData,

        [ValidateScript({if (Test-Path -Path $_ -PathType Container) { $true } else { throw "$_ cannot be found." }})]
        [string] $ContentPath, # NOTE: The main wrapper should unzip the zip (if there is one), so that all internal helpers only operate on a Contentpath

        [Parameter(Mandatory)]
        [Alias('LangCode')]
        [string] $LanguageCode,

        [switch] $RemoveOnly,

        [string] $ClientRequestId,

        [string] $CorrelationId,

        [string] $AccessToken,

        [switch] $NoStatus
    )

    $indentLevel = 4

    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

    $params = @{
        'ProductId' = $ProductId
        'SubmissionId' = $SubmissionId
        'LanguageCode' = $LanguageCode
        'ClientRequestId' = $ClientRequestId
        'CorrelationId' = $CorrelationId
        'AccessToken' = $AccessToken
        'NoStatus' = $NoStatus
    }

    $currentVideos = Get-ListingVideo @params

    # First we delete all of the existing videos
    Write-Log -Message "Removing all [$LanguageCode] listing videos." -Level Verbose -Indent $indentLevel
    foreach ($video in $currentVideos)
    {
        $null = Remove-ListingVideo @params -VideoId $video.id
    }

    if (-not $RemoveOnly)
    {
        # Then we proceed with adding/uploading all of the current videos
        Write-Log -Message "Creating [$LanguageCode] listing videos." -Level Verbose -Indent $indentLevel
        foreach ($trailer in $SubmissionData.trailerAssets)
        {
            $fileName = $trailer.videoFileName
            $trailerAssets = $trailer.trailerAssets.$LanguageCode
            if ($null -ne $trailerAssets)
            {
                $title = $trailerAssets.title
                $thumbnailFileName = $trailerAssets.imageList[0].fileName
                $thumbnailDescription = $trailerAssets.imageList[0].description

                $videoParams = $params.PSObject.Copy() # Get a new instance, not a reference
                $videoParams['FileName'] = (Split-Path -Path $fileName -Leaf)
                $videoParams['ThumbnailFileName'] = (Split-Path -Path $thumbnailFileName -Leaf)
                $videoParams['ThumbnailTitle'] = $title
                $videoParams['ThumbnailDescription'] = $description
                # TODO: $videoParams['ThumbnailOrientation'] = ???
    
                $videoSubmission = New-ListingVideo @videoParams
                $null = Set-StoreFile -FilePath (Join-Path -Path $ContentPath -ChildPath $fileName) -SasUri $videoSubmission.fileSasUri -NoStatus:$NoStatus
                $null = Set-StoreFile -FilePath (Join-Path -Path $ContentPath -ChildPath $thumbnailFileName) -SasUri $videoSubmission.thumbnail.fileSasUri -NoStatus:$NoStatus
                $videoSubmission.state = [StoreBrokerFileState]::Uploaded.ToString()
                $videoSubmission.thumbnail.state = [StoreBrokerFileState]::Uploaded.ToString()
                $null = Set-ListingVideo @params -Object $videoSubmission
            }
        }
    }

    # Record the telemetry for this event.
    $stopwatch.Stop()
    $telemetryMetrics = @{ [StoreBrokerTelemetryMetric]::Duration = $stopwatch.Elapsed.TotalSeconds }
    $telemetryProperties = @{
        [StoreBrokerTelemetryProperty]::ProductId = $ProductId
        [StoreBrokerTelemetryProperty]::SubmissionId = $SubmissionId
        [StoreBrokerTelemetryProperty]::LanguageCode = $LanguageCode
        [StoreBrokerTelemetryProperty]::ContentPath = (Get-PiiSafeString -PlainText $ContentPath)
        [StoreBrokerTelemetryProperty]::ClientRequestId = $ClientRequesId
        [StoreBrokerTelemetryProperty]::CorrelationId = $CorrelationId
    }

    Set-TelemetryEvent -EventName Patch-ListingVideos -Properties $telemetryProperties -Metrics $telemetryMetrics
    return
}

function Patch-Submission
{
<#
    .SYNOPSIS
        Modifies a cloned application submission by copying the specified data from the
        provided "new" submission.  Returns the final, patched submission JSON.

    .DESCRIPTION
        Modifies a cloned application submission by copying the specified data from the
        provided "new" submission.  Returns the final, patched submission JSON.

        The Git repo for this module can be found here: http://aka.ms/StoreBroker

    .PARAMETER ClonedSubmisson
        The JSON that was returned by the Store API when the application submission was cloned.

    .PARAMETER NewSubmission
        The JSON for the new/updated application submission.  The only parts from this submission
        that will be copied to the final, patched submission will be those specified by the
        switches.

    .PARAMETER TargetPublishMode
        Indicates how the submission will be published once it has passed certification.
        The value specified here takes precendence over the value from NewSubmission if
        -UpdatePublishModeAndVisibility is specified.  If -UpdatePublishModeAndVisibility
        is not specified and the value 'Default' is used, this submission will simply use the
        value from the previous submission.

    .PARAMETER TargetPublishDate
        Indicates when the submission will be published once it has passed certification.
        Specifying a value here is only valid when TargetPublishMode is set to 'SpecificDate'.
        The value specified here takes precendence over the value from NewSubmission if
        -UpdatePublishModeAndVisibility is specified.  If -UpdatePublishModeAndVisibility
        is not specified and the value 'Default' is used, this submission will simply use the
        value from the previous submission.  Users should provide this in local time and it
        will be converted automatically to UTC.

    .PARAMETER Visibility
        Indicates the store visibility of the app once the submission has been published.
        The value specified here takes precendence over the value from NewSubmission if
        -UpdatePublishModeAndVisibility is specified.  If -UpdatePublishModeAndVisibility
        is not specified and the value 'Default' is used, this submission will simply use the
        value from the previous submission.

    .PARAMETER PackageRolloutPercentage
        If specified, this submission will use gradual package rollout, setting their
        initial rollout percentage to be the indicated amount.

    .PARAMETER IsMandatoryUpdate
        Indicates whether you want to treat the packages in this submission as mandatory
        for self-installing app updates.

    .PARAMETER MandatoryUpdateEffectiveDate
        The date and time when the packages in this submission become mandatory. It is
        not required to provide a value for this when using IsMandatoryUpdate, however
        this value will be ignored if specified and IsMandatoryUpdate is not also provided.
        Users should provide this in local time and it will be converted automatically to UTC.

    .PARAMETER AddPackages
        Causes the packages that are listed in JsonPath to be added to the package listing
        in the final, patched submission.  This switch is mutually exclusive with ReplacePackages.

    .PARAMETER ReplacePackages
        Causes any existing packages in the cloned submission to be removed and only the packages
        that are listed in JsonPath will be in the final, patched submission.
        This switch is mutually exclusive with AddPackages.

    .PARAMETER UpdateListings
        Replaces the listings array in the final, patched submission with the listings array
        from NewSubmission.  Ensures that the images originally part of each listing in the
        ClonedSubmission are marked as "PendingDelete" in the final, patched submission.

    .PARAMETER UpdatePublishModeAndVisibility
        Updates fields under the "Publish Mode and Visibility" category in the PackageTool config file.
        Updates the following fields using values from JsonPath: targetPublishMode,
        targetPublishDate, and visibility.

    .PARAMETER UpdatePricingAndAvailability
        Updates fields under the "Pricing and Availability" category in the PackageTool config file.
        Updates the following fields using values from JsonPath: targetPublishMode,
        targetPublishDate, visibility, pricing, allowTargetFutureDeviceFamilies,
        allowMicrosoftDecideAppAvailabilityToFutureDeviceFamilies, and enterpriseLicensing.

    .PARAMETER UpdateAppProperties
        Updates fields under the "App Properties" category in the PackageTool config file.
        Updates the following fields using values from JsonPath: applicationCategory,
        hardwarePreferences, hasExternalInAppProducts, meetAccessibilityGuidelines,
        canInstallOnRemovableMedia, automaticBackupEnabled, and isGameDvrEnabled.

    .PARAMETER UpdateGamingOptions
        Updates fields under the "Ganming Options" category in the PackageTool config file.
        Updates the following fields using values from JsonPath under gamingOptions:
        genres, isLocalMultiplayer, isLocalCooperative, isOnlineMultiplayer, isOnlineCooperative,
        localMultiplayerMinPlayers, localMultiplayerMaxPlayers, localCooperativeMinPlayers,
        localCooperativeMaxPlayers, isBroadcastingPrivilegeGranted, isCrossPlayEnabled, and kinectDataForExternal.

    .PARAMETER UpdateTrailers
        Replaces the trailers array in the final, patched submission with the trailers array
        from JsonPath.

    .PARAMETER UpdateNotesForCertification
        Updates the notesForCertification field using the value from JsonPath.

    .EXAMPLE
        $patchedSubmission = Prepare-ApplicationSubmission $clonedSubmission $jsonContent
        Because no switches were specified, ($patchedSubmission -eq $clonedSubmission).

    .EXAMPLE
        $patchedSubmission = Prepare-ApplicationSubmission $clonedSubmission $jsonContent -AddPackages
        $patchedSubmission will be identical to $clonedSubmission, however all of the packages that
        were contained in $jsonContent will have also been added to the package array.

    .EXAMPLE
        $patchedSubmission = Prepare-ApplicationSubmission $clonedSubmission $jsonContent -AddPackages -UpdateListings
        $patchedSubmission will be contain the listings and packages that were part of $jsonContent,
        but the rest of the submission content will be identical to what had been in $clonedSubmission.
        Additionally, any images that were part of listings from $clonedSubmission will still be
        listed in $patchedSubmission, but their file status will have been changed to "PendingDelete".

    .NOTES
        This is an internal-only helper method.
#>

    [CmdletBinding(DefaultParametersetName="AddPackages")]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseApprovedVerbs", "", Justification="Internal-only helper method.  Best description for purpose.")]
    param(
        [Parameter(Mandatory)]
        [PSCustomObject] $ClonedSubmission,

        [Parameter(Mandatory)]
        [PSCustomObject] $NewSubmission,

        [ValidateSet('Default', 'Immediate', 'Manual', 'SpecificDate')]
        [string] $TargetPublishMode = $script:keywordDefault,

        [DateTime] $TargetPublishDate,

        [ValidateSet('Default', 'Public', 'Private', 'Hidden')]
        [string] $Visibility = $script:keywordDefault,

        [ValidateRange(0, 100)]
        [double] $PackageRolloutPercentage = -1,

        [switch] $IsMandatoryUpdate,

        [DateTime] $MandatoryUpdateEffectiveDate,

        [Parameter(ParameterSetName="AppPackages")]
        [switch] $AddPackages,

        [Parameter(ParameterSetName="ReplacePackages")]
        [switch] $ReplacePackages,

        [switch] $UpdateListings,

        [switch] $UpdatePublishModeAndVisibility,

        [switch] $UpdatePricingAndAvailability,

        [switch] $UpdateAppProperties,

        [switch] $UpdateGamingOptions,

        [switch] $UpdateTrailers,

        [switch] $UpdateNotesForCertification
    )

    Write-Log -Message "Patching the content of the submission." -Level Verbose

    # Our method should have zero side-effects -- we don't want to modify any parameter
    # that was passed-in to us.  To that end, we'll create a deep copy of the ClonedSubmisison,
    # and we'll modify that throughout this function and that will be the value that we return
    # at the end.
    $PatchedSubmission = DeepCopy-Object $ClonedSubmission

    # We use a ValidateRange attribute to ensure a valid percentage, but then use -1 as a default
    # value to indicate when the user hasn't specified a value (and thus, does not want to use
    # this feature).
    if ($PackageRolloutPercentage -ge 0)
    {
        $PatchedSubmission.packageDeliveryOptions.packageRollout.isPackageRollout = $true
        $PatchedSubmission.packageDeliveryOptions.packageRollout.packageRolloutPercentage = $PackageRolloutPercentage

        Write-Log -Level Warning -Message @(
            "Your rollout selections apply to all of your packages, but will only apply to your customers running OS",
            "versions that support package flights (Windows.Desktop build 10586 or later; Windows.Mobile build 10586.63",
            "or later, and Xbox), including any customers who get the app via Store-managed licensing via the",
            "Windows Store for Business.  When using gradual package rollout, customers on earlier OS versions will not",
            "get packages from the latest submission until you finalize the package rollout.")
    }

    $PatchedSubmission.packageDeliveryOptions.isMandatoryUpdate = [bool]$IsMandatoryUpdate
    if ($null -ne $MandatoryUpdateEffectiveDate)
    {
        if ($IsMandatoryUpdate)
        {
            $PatchedSubmission.packageDeliveryOptions.mandatoryUpdateEffectiveDate = $MandatoryUpdateEffectiveDate.ToUniversalTime().ToString('o')
        }
        else
        {
            Write-Log -Message "MandatoryUpdateEffectiveDate specified without indicating IsMandatoryUpdate.  The value will be ignored." -Level Warning
        }
    }

    if (($AddPackages -or $ReplacePackages) -and ($NewSubmission.applicationPackages.Count -eq 0))
    {
        $output = @()
        $output += "Your submission doesn't contain any packages, so you cannot Add or Replace packages."
        $output += "Please check your input settings to New-SubmissionPackage and ensure you're providing a value for AppxPath."
        $output = $output -join [Environment]::NewLine
        Write-Log -Message $output -Level Error
        throw $output
    }

    # When updating packages, we'll simply add the new packages to the list of existing packages.
    # At some point when the API provides more signals to us with regard to what platform/OS
    # an existing package is for, we may want to mark "older" packages for the same platform
    # as "PendingDelete" so as to not overly clutter the dev account with old packages.  For now,
    # we'll leave any package maintenance to uses of the web portal.
    if ($AddPackages)
    {
        $PatchedSubmission.applicationPackages += $NewSubmission.applicationPackages
    }

    # Caller wants to remove any existing packages in the cloned submission and only have the
    # packages that are defined in the new submission.
    if ($ReplacePackages)
    {
        $PatchedSubmission.applicationPackages | ForEach-Object { $_.fileStatus = $script:keywordPendingDelete }
        $PatchedSubmission.applicationPackages += $NewSubmission.applicationPackages
    }

    # When updating the listings metadata, what we really want to do is just blindly replace
    # the existing listings array with the new one.  We can't do that unfortunately though,
    # as we need to mark the existing screenshots as "PendingDelete" so that they'll be deleted
    # during the upload.  Otherwise, even though we don't include them in the updated JSON, they
    # will still remain there in the Dev Portal.
    if ($UpdateListings)
    {
        # Save off the original listings so that we can make changes to them without affecting
        # other references
        $existingListings = DeepCopy-Object $PatchedSubmission.listings

        # Then we'll replace the patched submission's listings array (which had the old,
        # cloned metadata), with the metadata from the new submission.
        $PatchedSubmission.listings = DeepCopy-Object $NewSubmission.listings

        # Now we'll update the screenshots in the existing listings
        # to indicate that they should all be deleted. We'll also add
        # all of these deleted images to the corresponding listing
        # in the patched submission.
        #
        # Unless the Store team indicates otherwise, we assume that the server will handle
        # deleting the images in regions that were part of the cloned submission, but aren't part
        # of the patched submission that we provide. Otherwise, we'd have to create empty listing
        # objects that would likely fail validation.
        $existingListings |
            Get-Member -Type NoteProperty |
                ForEach-Object {
                    $lang = $_.Name
                    if ($null -ne $PatchedSubmission.listings.$lang.baseListing.images)
                    {
                        $existingListings.$lang.baseListing.images |
                            ForEach-Object {
                                $_.FileStatus = $script:keywordPendingDelete
                                $PatchedSubmission.listings.$lang.baseListing.images += $_
                            }
                    }
                }

        # We also have to be sure to carry forward any "platform overrides" that the cloned
        # submission had.  These platform overrides have listing information for previous OS
        # releases like Windows 8.0/8.1 and Windows Phone 8.0/8.1.
        #
        # This has slightly different logic from the normal listings as we don't expect users
        # to use StoreBroker to modify these values.  We will copy any platform override that
        # exists from the cloned submission to the patched submission, provided that the patched
        # submission has that language.  If a platform override entry already exists for a specific
        # platform in the patched submission, we will just carry forward the previous images for
        # that platformOverride and mark them as PendingDelete, just like we do for normal listings.
        $existingListings |
            Get-Member -Type NoteProperty |
                ForEach-Object {
                    $lang = $_.Name

                    # We're only bringing over platformOverrides for languages that we still have
                    # in the patched submission.
                    if ($null -ne $PatchedSubmission.listings.$lang.baseListing)
                    {
                        $existingListings.$lang.platformOverrides |
                            Get-Member -Type NoteProperty |
                                ForEach-Object {
                                    $platform = $_.Name

                                    if ($null -eq $PatchedSubmission.listings.$lang.platformOverrides.$platform)
                                    {
                                        # If the override doesn't exist in the patched submission, just
                                        # bring the whole thing over.
                                        $PatchedSubmission.listings.$lang.platformOverrides |
                                            Add-Member -Type NoteProperty -Name $platform -Value $($existingListings.$lang.platformOverrides.$platform)
                                    }
                                    else
                                    {
                                        # The PatchedSubmission has an entry for this platform.
                                        # We'll only copy over the images from the cloned submission
                                        # and mark them all as PendingDelete.
                                        $existingListings.$lang.platformOverrides.$platform.images |
                                            ForEach-Object {
                                                $_.FileStatus = $script:keywordPendingDelete
                                                $PatchedSubmission.listings.$lang.platformOverrides.$platform.images += $_
                                            }
                                    }
                                }
                    }
                }

    }

    # For the last four switches, simply copy the field if it is a scalar, or
    # DeepCopy-Object if it is an object.

    if ($UpdatePublishModeAndVisibility)
    {
        $PatchedSubmission.targetPublishMode = Get-ProperEnumCasing -EnumValue ($NewSubmission.targetPublishMode)
        $PatchedSubmission.targetPublishDate = $NewSubmission.targetPublishDate
        $PatchedSubmission.visibility = Get-ProperEnumCasing -EnumValue ($NewSubmission.visibility)
    }

    # If users pass in a different value for any of the publish/visibility values at the commandline,
    # they override those coming from the config.
    if ($TargetPublishMode -ne $script:keywordDefault)
    {
        if (($TargetPublishMode -eq $script:keywordSpecificDate) -and ($null -eq $TargetPublishDate))
        {
            $output = "TargetPublishMode was set to '$script:keywordSpecificDate' but TargetPublishDate was not specified."
            Write-Log -Message $output -Level Error
            throw $output
        }

        $PatchedSubmission.targetPublishMode = Get-ProperEnumCasing -EnumValue $TargetPublishMode
    }

    if ($null -ne $TargetPublishDate)
    {
        if ($TargetPublishMode -ne $script:keywordSpecificDate)
        {
            $output = "A TargetPublishDate was specified, but the TargetPublishMode was [$TargetPublishMode],  not '$script:keywordSpecificDate'."
            Write-Log -Message $output -Level Error
            throw $output
        }

        $PatchedSubmission.targetPublishDate = $TargetPublishDate.ToUniversalTime().ToString('o')
    }

    if ($Visibility -ne $script:keywordDefault)
    {
        $PatchedSubmission.visibility = Get-ProperEnumCasing -EnumValue $Visibility
    }

    if ($UpdatePricingAndAvailability)
    {
        $PatchedSubmission.pricing = DeepCopy-Object $NewSubmission.pricing
        $PatchedSubmission.allowTargetFutureDeviceFamilies = DeepCopy-Object $NewSubmission.allowTargetFutureDeviceFamilies
        $PatchedSubmission.allowMicrosoftDecideAppAvailabilityToFutureDeviceFamilies = $NewSubmission.allowMicrosoftDecideAppAvailabilityToFutureDeviceFamilies
        $PatchedSubmission.enterpriseLicensing = $NewSubmission.enterpriseLicensing
    }

    if ($UpdateAppProperties)
    {
        $PatchedSubmission.applicationCategory = $NewSubmission.applicationCategory
        $PatchedSubmission.hardwarePreferences = $NewSubmission.hardwarePreferences
        $PatchedSubmission.hasExternalInAppProducts = $NewSubmission.hasExternalInAppProducts
        $PatchedSubmission.meetAccessibilityGuidelines = $NewSubmission.meetAccessibilityGuidelines
        $PatchedSubmission.canInstallOnRemovableMedia = $NewSubmission.canInstallOnRemovableMedia
        $PatchedSubmission.automaticBackupEnabled = $NewSubmission.automaticBackupEnabled
        $PatchedSubmission.isGameDvrEnabled = $NewSubmission.isGameDvrEnabled
    }

    if ($UpdateGamingOptions)
    {
        # It's possible that an existing submission object may not have this property at all.
        # Make sure it's there before continuing.
        if ($null -eq $PatchedSubmission.gamingOptions)
        {
            $PatchedSubmission | Add-Member -Type NoteProperty -Name 'gamingOptions' -Value $null
        }

        if ($null -eq $NewSubmission.gamingOptions)
        {
            $output = @()
            $output += "You selected to update the Gaming Options for this submission, but it appears you don't have"
            $output += "that section in your config file.  You should probably re-generate your config file with"
            $output += "New-StoreBrokerConfigFile, transfer any modified properties to that new config file, and then"
            $output += "re-generate your StoreBroker payload with New-SubmissionPackage."
            $output = $output -join [Environment]::NewLine
            Write-Log -Message $output -Level Error
            throw $output
        }

        # Gaming options is an array with a single item, but it's important that we ensure that
        # PowerShell doesn't convert that to just be a single object, so we force it back into
        # an array.
        $PatchedSubmission.gamingOptions = DeepCopy-Object -Object (, $NewSubmission.gamingOptions)
    }

    if ($UpdateTrailers)
    {
        # It's possible that an existing submission object may not have this property at all.
        # Make sure it's there before continuing.
        if ($null -eq $PatchedSubmission.trailers)
        {
            $PatchedSubmission | Add-Member -Type NoteProperty -Name 'trailers' -Value $null
        }

        # Trailers has to be an array, so it's important that in the cases when we have 0 or 1
        # trailers, we don't let PowerShell convert it away from an array to a single object.
        $PatchedSubmission.trailers = DeepCopy-Object -Object (, $NewSubmission.trailers)
    }

    if ($UpdateNotesForCertification)
    {
        $PatchedSubmission.notesForCertification = $NewSubmission.notesForCertification
    }

    # To better assist with debugging, we'll store exactly the original and modified JSON submission bodies.
    $tempFile = [System.IO.Path]::GetTempFileName() # New-TemporaryFile requires PS 5.0
    ($ClonedSubmission | ConvertTo-Json -Depth $script:jsonConversionDepth) | Set-Content -Path $tempFile -Encoding UTF8
    Write-Log -Message "The original cloned JSON content can be found here: [$tempFile]" -Level Verbose

    $tempFile = [System.IO.Path]::GetTempFileName() # New-TemporaryFile requires PS 5.0
    ($PatchedSubmission | ConvertTo-Json -Depth $script:jsonConversionDepth) | Set-Content -Path $tempFile -Encoding UTF8
    Write-Log -Message "The patched JSON content can be found here: [$tempFile]" -Level Verbose

    return $PatchedSubmission
}

