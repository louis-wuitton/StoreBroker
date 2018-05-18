# Copyright (C) Microsoft Corporation.  All rights reserved.

# Used as the default value of a string parameter to be able to track if a user passed-in a new
# value or not.
$script:valueNotUpdatedToken = "[StoreBroker_Value_Was_Not_Updated]"

function Update-Submission
{
    [CmdletBinding(
        SupportsShouldProcess,
        DefaultParametersetName="AddPackages")]
    [OutputType([Object[]])]
    param(
        [Parameter(Mandatory)]
        [string] $ProductId,

        [Parameter(Mandatory)]
        [ValidateScript({if (Test-Path -Path $_ -PathType Leaf) { $true } else { throw "$_ cannot be found." }})]
        [string] $JsonPath,

        [ValidateScript({if (Test-Path -Path $_ -PathType Leaf) { $true } else { throw "$_ cannot be found." }})]
        [string] $ZipPath,

        [ValidateScript({if (Test-Path -Path $_ -PathType Container) { $true } else { throw "$_ cannot be found." }})]
        [string] $ContentPath,

        [Alias('AutoCommit')]
        [switch] $AutoSubmit,

        [string] $SubmissionId = "",

        [ValidateSet('Default', 'Immediate', 'Manual', 'SpecificDate')]
        [string] $TargetPublishMode = $script:keywordDefault,

        [DateTime] $TargetPublishDate,

        [ValidateSet('Public', 'Private', 'StopSelling')]
        [string] $Visibility,

        [ValidateSet('NoAction', 'Finalize', 'Halt')]
        [string] $ExistingPackageRolloutAction = $script:keywordNoAction,

        [ValidateRange(0, 100)]
        [double] $PackageRolloutPercentage = -1,

        [switch] $IsMandatoryUpdate,

        [DateTime] $MandatoryUpdateEffectiveDate,

        [switch] $Force,

        [Parameter(ParameterSetName="AddPackages")]
        [switch] $AddPackages,

        [Parameter(ParameterSetName="ReplacePackages")]
        [switch] $ReplacePackages,

        [Parameter(ParameterSetName="UpdatePackages")]
        [switch] $UpdatePackages,

        [Parameter(ParameterSetName="UpdatePackages")]
        [int] $RedundantPackagesToKeep = 1,

        [string] $CertificationNotes = $script:valueNotUpdatedToken,

        [switch] $UpdateListings,

        [switch] $UpdatePublishModeAndVisibility,

        [switch] $UpdatePricingAndAvailability,

        [switch] $UpdateAppProperties,

        [switch] $UpdateGamingOptions,

        [switch] $UpdateTrailers,

        [Alias('UpdateNotesForCertification')]
        [switch] $UpdateCertificationNotes,

        [string] $ClientRequestId,

        [string] $CorrelationId,

        [string] $AccessToken,

        [switch] $NoStatus
    )

    $indentLevel = 1
    $isContentPathTemporary = $false

    if ((-not [String]::IsNullOrWhiteSpace($ZipPath)) -and (-not [String]::IsNullOrWhiteSpace($ContentPath)))
    {
        $message = "You should specify either ZipPath OR ContentPath.  Not both."
        Write-Log -Message $message -Level Error
        throw $message
    }

    if ($Force -and (-not [System.String]::IsNullOrEmpty($SubmissionId)))
    {
        $message = "You can't specify Force AND supply a SubmissionId."
        Write-Log -Message $message -Level Error
        throw $message
    }

    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

    if ($null -eq $CorrelationId)
    {
        # We'll assign our own unique CorrelationId for this update request
        # if one wasn't provided to us already.
        $CorrelationId = "$((Get-Date).ToString("yyyyMMddssmm.ffff"))-$ProductId"
    }

    $commonParams = @{
        'ClientRequestId' = $ClientRequestId
        'CorrelationId' = $CorrelationId
        'AccessToken' = $AccessToken
        'NoStatus' = $NoStatus
    }

    Write-Log -Message "[$($MyInvocation.MyCommand.Module.Version)] Executing: $($MyInvocation.Line.Trim())" -Level Verbose

    Write-Log -Message "Reading in the submission content from: $JsonPath" -Level Verbose
    if ($PSCmdlet.ShouldProcess($JsonPath, "Get-Content"))
    {
        $jsonSubmission = [string](Get-Content $JsonPath -Encoding UTF8) | ConvertFrom-Json
    }

    $product = Get-Product @commonParams -ProductId $ProductId
    $appId = ($product.externalIds | Where-Object { $_.type -eq 'StoreId' }).value

    # Extra layer of validation to protect users from trying to submit a payload to the wrong product
    $jsonProductId = $jsonSubmission.productId
    if ([String]::IsNullOrWhiteSpace($jsonProductId))
    {
        $configPath = Join-Path -Path ([System.Environment]::GetFolderPath('Desktop')) -ChildPath 'newconfig.json'

        Write-Log -Level Warning -Message @(
            "The config file used to generate this submission did not have a ProductId defined in it.",
            "The ProductId entry in the config helps ensure that payloads are not submitted to the wrong product.",
            "Please update your app's StoreBroker config file by adding a `"productId`" property with",
            "your app's ProductId to the `"appSubmission`" section ([$ProductId]).",
            "If you're unclear on what change, needs to be done, you can re-generate your config file using",
            "   New-StoreBrokerConfigFile -ProductId $ProductId -Path `"$configPath`"",
            "and then diff the new config file against your current one to see the requested productId change.")

        # May be an older json file that still uses the AppId.  If so, do the conversion to check that way.
        if (-not ([String]::IsNullOrWhiteSpace($jsonSubmission.appId)))
        {
            $jsonProductId = $product.id

            if ($jsonSubmission.appId -ne $appId)
            {
                $output = @()
                $output += "The AppId [$($jsonSubmission.appId))] in the submission content [$JsonPath] is not for the intended ProductId [$ProductId]."
                $output += "You either entered the wrong ProductId at the commandline, or you're referencing the wrong submission content to upload."

                $newLineOutput = ($output -join [Environment]::NewLine)
                Write-Log -Message $newLineOutput -Level Error
                throw $newLineOutput
            }
        }
    }

    if ((-not [String]::IsNullOrWhiteSpace($jsonProductId)) -and ($ProductId -ne $jsonProductId))
    {
        $output = @()
        $output += "The ProductId [$jsonProductId] in the submission content [$JsonPath] does not match the intended ProductId [$ProductId]."
        $output += "You either entered the wrong ProductId at the commandline, or you're referencing the wrong submission content to upload."

        $newLineOutput = ($output -join [Environment]::NewLine)
        Write-Log -Message $newLineOutput -Level Error
        throw $newLineOutput
    }

    if ($UpdateGamingOptions)
    {
        $message = @(
            'Gaming Options support has not been made available in v2 of the API.',
            'To make updates to Gaming Options for the time being, please use the Dev Portal.',
            'To quickly get to this product in the Dev Portal, you can use:'
            "   Open-DevPortal -AppId $AppId")
        Write-Log -Message $message -Level Error
        throw ($message -join [Environment]::NewLine)
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
        (-not $UpdateCertificationNotes) -and
        ($CertificationNotes -eq $script:valueNotUpdatedToken))
    {
        Write-Log -Level Warning -Message @(
            "You have not specified any `"modification`" switch for updating the submission.",
            "This means that the new submission will be identical to the current one.",
            "If this was not your intention, please read-up on the documentation for this command:",
            "     Get-Help Update-Submission -ShowWindow")
    }

    $commonParams['ProductId'] = $ProductId
    try
    {
        if ([System.String]::IsNullOrEmpty($SubmissionId))
        {
            $submission = New-Submission @commonParams -ExistingPackageRolloutAction $ExistingPackageRolloutAction -Force:$Force
            $SubmissionId = $submission.id
        }
        else
        {
            $submission = Get-Submission @commonParams -SubmissionId $SubmissionId
            if (($submission.state -ne [StoreBrokerSubmissionState]::InProgress) -or
                ($submission.subState -ne [StoreBrokerSubmissionSubState]::InDraft))
            {
                $output = @()
                $output += "We can only modify a submission that is: $([StoreBrokerSubmissionState]::InProgress)/$([StoreBrokerSubmissionSubState]::InDraft) state."
                $output += "The submission that you requested to modify ($SubmissionId) is: $($submission.state)/$($submission.subState)."

                $newLineOutput = ($output -join [Environment]::NewLine)
                Write-Log -Message $newLineOutput -Level Error
                throw $newLineOutput
            }
        }

        $commonParams['SubmissionId'] = $SubmissionId

        if ($PSCmdlet.ShouldProcess("Patch-Submission"))
        {
            # If we know that we'll be doing anything with binary content, ensure that it's accessible unzipped.
            if ($UpdateListings -or $UpdateTrailers -or $AddPackages -or $ReplacePackages -or $UpdatePackages)
            {
                if ([String]::IsNullOrEmpty($ContentPath))
                {
                    Add-Type -AssemblyName System.IO.Compression.FileSystem
                    $isContentPathTemporary = $true
                    $ContentPath = New-TemporaryDirectory
                    Write-Log -Message "Unzipping archive (Item: $ZipPath) to (Target: $ContentPath)." -Level Verbose -Indent $indentLevel
                    [System.IO.Compression.ZipFile]::ExtractToDirectory($ZipPath, $ContentPath)
                    Write-Log -Message "Unzip complete." -Level Verbose -Indent $indentLevel
                }

                $null = Patch-Listings @commonParams -SubmissionData $jsonSubmission -ContentPath $ContentPath -UpdateListings:$UpdateListings -UpdateTrailers:$UpdateTrailers

                $packageParams = $commonParams.PSObject.Copy() # Get a new instance, not a reference
                $packageParams.Add('SubmissionData', $jsonSubmission)
                $packageParams.Add('ContentPath', $ContentPath)
                if ($AddPackages) { $packageParams.Add('AddPackages', $AddPackages) }
                if ($ReplacePackages) { $packageParams.Add('ReplacePackages', $ReplacePackages) }
                if ($UpdatePackages) {
                    $packageParams.Add('UpdatePackages', $UpdatePackages)
                    $packageParams.Add('RedundantPackagesToKeep', $RedundantPackagesToKeep)
                }
                $null = Patch-ProductPackages @packageParams
            }

            if ($UpdateAppProperties)
            {
                $propertyParams = $commonParams.PSObject.Copy() # Get a new instance, not a reference
                $propertyParams.Add('SubmissionData', $jsonSubmission)
                $propertyParams.Add('ContentPath', $ContentPath)
                $propertyParams.Add('UpdateCategoryFromSubmissionData', $UpdateAppProperties)
                $null = Update-ProductProperty @commonParams -SubmissionData $jsonSubmission

                # TODO: No equivalent for:
                # $jsonContent.hardwarePreferences
                # $jsonContent.hasExternalInAppProducts
                # $jsonContent.meetAccessibilityGuidelines
                # $jsonContent.canInstallOnRemovableMedia
                # $jsonContent.automaticBackupEnabled
                # $jsonContent.isGameDvrEnabled
            }

            $detailParams = $commonParams.PSObject.Copy() # Get a new instance, not a reference
            $detailParams.Add('SubmissionData', $jsonSubmission)
            $detailParams.Add('UpdatePublishModeAndDateFromSubmissionData', $UpdatePublishModeAndVisibility)
            $detailParams.Add('UpdateCertificationNotesFromSubmissionData', $UpdateCerificationNotes)
            if ($null -ne $PSBoundParameters['TargetPublishMode']) { $availabilityParams.Add("TargetPublishMode", $TargetPublishMode) }
            if ($null -ne $PSBoundParameters['TargetPublishDate']) { $availabilityParams.Add("TargetPublishDate", $TargetPublishDate) }
            if ($null -ne $PSBoundParameters['CertificationNotes']) { $availabilityParams.Add("CertificationNotes", $CertificationNotes) }
            $null = Update-SubmissionDetail @detailParams # TODO: This API currently fails.  Should comment out while testing.

            if ($UpdatePublishModeAndVisibility -or ($null -ne $Visibility))
            {
                $availabilityParams = $commonParams.PSObject.Copy() # Get a new instance, not a reference
                $availabilityParams.Add('SubmissionData', $jsonSubmission)
                $availabilityParams.Add('UpdateVisibilityFromSubmissionData', $UpdatePublishModeAndVisibility)
                if ($null -ne $PSBoundParameters['Visibility']) { $availabilityParams.Add("Visibility", $Visibility) }
                $null = Update-ProductAvailability @availabilityParams
            }

            if ($UpdatePricingAndAvailability)
            {
                # TODO: Figure out how to do pricing in v2
                # $jsonContent.pricing

                # TODO: No equivalent for:
                # $jsonContent.allowTargetFutureDeviceFamilies
                # $jsonContent.allowMicrosoftDecideAppAvailabilityToFutureDeviceFamilies
                # $jsonContent.enterpriseLicensing
            }

            if ($UpdateGamingOptions)
            {
                # TODO: No equivalent
                # $jsonContent.gamingOptions

                if ($null -eq $jsonContent.gamingOptions)
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
            }

            if ($PackageRolloutPercentage -ge 0)
            {
                $null = Update-SubmissionRollout @packageParams -Percentage $PackageRolloutPercentage -Enabled
            }

            if ($IsMandatoryUpdate)
            {
                # TODO: No equivalent
                # $jsonContent.packageDeliveryOptions.isMandatoryUpdate
                # if ($null -ne $MandatoryUpdateEffectiveDate)
                # {
                #     if ($IsMandatoryUpdate)
                #     {
                #         $PatchedSubmission.packageDeliveryOptions.mandatoryUpdateEffectiveDate = $MandatoryUpdateEffectiveDate.ToUniversalTime().ToString('o')
                #     }
                #     else
                #     {
                #         Write-Log -Message "MandatoryUpdateEffectiveDate specified without indicating IsMandatoryUpdate.  The value will be ignored." -Level Warning
                #     }
                # }
            }
        }

        Write-Log -Message @(
            "Successfully cloned the existing submission and modified its content.",
            "You can view it on the Dev Portal here:",
            "    https://dev.windows.com/en-us/dashboard/apps/$appId/submissions/$submissionId/")

        if ($AutoSubmit)
        {
            Write-Log -Message "Submitting the submission since -AutoSubmit was requested." -Level Verbose
            Submit-Submission @commonParams -Auto
        }
        else
        {
            Write-Log -Message @(
                "When you're ready to commit, run this command:",
                "  Submit-Submission -ProductId $ProductId -SubmissionId $submissionId")
        }

        # Record the telemetry for this event.
        $stopwatch.Stop()
        $telemetryMetrics = @{ [StoreBrokerTelemetryMetric]::Duration = $stopwatch.Elapsed.TotalSeconds }
        $telemetryProperties = @{
            [StoreBrokerTelemetryProperty]::ProductId = $ProductId
            [StoreBrokerTelemetryProperty]::AppId = $AppId
            [StoreBrokerTelemetryProperty]::SubmissionId = $submissionId
            [StoreBrokerTelemetryProperty]::ZipPath = (Get-PiiSafeString -PlainText $ZipPath)
            [StoreBrokerTelemetryProperty]::ContentPath = (Get-PiiSafeString -PlainText $ContentPath)
            [StoreBrokerTelemetryProperty]::AutoSubmit = $AutoSubmit
            [StoreBrokerTelemetryProperty]::Force = $Force
            [StoreBrokerTelemetryProperty]::PackageRolloutPercentage = $PackageRolloutPercentage
            [StoreBrokerTelemetryProperty]::IsMandatoryUpdate = [bool]$IsMandatoryUpdate
            [StoreBrokerTelemetryProperty]::AddPackages = $AddPackages
            [StoreBrokerTelemetryProperty]::ReplacePackages = $ReplacePackages
            [StoreBrokerTelemetryProperty]::UpdatePackages = $UpdatePackages
            [StoreBrokerTelemetryProperty]::RedundantPackagesToKeep = $RedundantPackagesToKeep
            [StoreBrokerTelemetryProperty]::UpdateListings = $UpdateListings
            [StoreBrokerTelemetryProperty]::UpdatePublishModeAndVisibility = $UpdatePublishModeAndVisibility
            [StoreBrokerTelemetryProperty]::UpdatePricingAndAvailability = $UpdatePricingAndAvailability
            [StoreBrokerTelemetryProperty]::UpdateGamingOptions = $UpdateGamingOptions
            [StoreBrokerTelemetryProperty]::UpdateTrailers = $UpdateTrailers
            [StoreBrokerTelemetryProperty]::UpdateAppProperties = $UpdateAppProperties
            [StoreBrokerTelemetryProperty]::UpdateCertificationNotes = $UpdateCertificationNotes
            [StoreBrokerTelemetryProperty]::ProvidedCertificationNotes = (-not [String]::IsNullOrWhiteSpace($CertificationNotes))
            [StoreBrokerTelemetryProperty]::ClientRequestId = $ClientRequesId
            [StoreBrokerTelemetryProperty]::CorrelationId = $CorrelationId
        }

        Set-TelemetryEvent -EventName Update-Submission -Properties $telemetryProperties -Metrics $telemetryMetrics

        return
    }
    finally
    {
        if ($isContentPathTemporary -and (-not [String]::IsNullOrWhiteSpace($ContentPath)))
        {
            Write-Log -Message "Deleting temporary content directory: $ContentPath" -Level Verbose -Indent $indentLevel
            $null = Remove-Item -Force -Recurse $ContentPath -ErrorAction SilentlyContinue
            Write-Log -Message "Deleting temporary directory complete." -Level Verbose -Indent $indentLevel
        }
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
    # packages associated with this submission.
    foreach ($package in $SubmissionData.applicationPackages)
    {
        $packageSubmission = New-ProductPackage @params -FileName (Split-Path -Path $package.fileName -Leaf)
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
