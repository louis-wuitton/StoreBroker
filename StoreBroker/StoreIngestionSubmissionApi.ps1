function Get-Submissions
{
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [ValidateScript({if ($_.Length -gt 12) { $true } else { throw "It looks like you supplied an AppId instead of a ProductId.  Use Get-Products with -AppId to find the ProductId for this AppId." }})]
        [string] $ProductId,

        [string] $FlightId,

        [string] $SandboxId,

        [ValidateSet('InProgress', 'Published')]
        [string] $Type,

        [ValidateSet('Preview', 'Live')]
        [string] $Scope,

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
            [StoreBrokerTelemetryProperty]::FlightId = $FlightId
            [StoreBrokerTelemetryProperty]::SandboxId = $SandboxId
            [StoreBrokerTelemetryProperty]::Type = $Type
            [StoreBrokerTelemetryProperty]::Scope = $Scope
            [StoreBrokerTelemetryProperty]::ClientRequestId = $ClientRequesId
            [StoreBrokerTelemetryProperty]::CorrelationId = $CorrelationId
        }

        $getParams = @()
        if (-not [String]::IsNullOrWhiteSpace($FlightId))
        {
            $getParams += "flightId=$FlightId"
        }

        if (-not [String]::IsNullOrWhiteSpace($SandboxId))
        {
            $getParams += "sandboxId=$SandboxId"
        }

        if (-not [String]::IsNullOrWhiteSpace($Type))
        {
            $getParams += "type=$Type"
        }

        if (-not [String]::IsNullOrWhiteSpace($Scope))
        {
            $getParams += "scope=$Scope"
        }

        $params = @{
            "UriFragment" = "products/$ProductId/submissions`?" + ($getParams -join '&')
            "Description" = "Getting submissions for $ProductId"
            "ClientRequestId" = $ClientRequestId
            "CorrelationId" = $CorrelationId
            "AccessToken" = $AccessToken
            "TelemetryEventName" = "Get-Submissions"
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

function New-Submission
{
    [CmdletBinding(
        SupportsShouldProcess,
        DefaultParameterSetName='Retail')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSShouldProcess", "", Justification="Methods called within here make use of PSShouldProcess, and the switch is passed on to them inherently.")]
    param(
        [Parameter(
            Mandatory,
            ParameterSetName = 'Retail',
            Position = 0)]
        [Parameter(
            Mandatory,
            ParameterSetName = 'Flight',
            Position = 0)]
        [Parameter(
            Mandatory,
            ParameterSetName = 'Sandbox',
            Position = 0)]
        [ValidateScript({if ($_.Length -gt 12) { $true } else { throw "It looks like you supplied an AppId instead of a ProductId.  Use Get-Products with -AppId to find the ProductId for this AppId." }})]
        [string] $ProductId,

        [Parameter(
            Mandatory,
            ParameterSetName = 'Flight',
            Position = 1)]
        [string] $FlightId,

        [Parameter(
            Mandatory,
            ParameterSetName = 'Sandbox',
            Position = 1)]
        [string] $SandboxId,

        [Parameter(
            ParameterSetName = 'Retail',
            Position = 2)]
        [Parameter(
            ParameterSetName = 'Flight',
            Position = 3)]
        [Parameter(
            ParameterSetName = 'Sandbox',
            Position = 3)]
        [ValidateSet('Preview', 'Live')]
        [string] $Scope = 'Live',

        [Parameter(
            ParameterSetName = 'Retail',
            Position = 3)]
        [Parameter(
            ParameterSetName = 'Flight',
            Position = 4)]
        [Parameter(
            ParameterSetName = 'Sandbox',
            Position = 4)]
        [int] $WaitSeconds = -2, # -1 is special and means no wait.  Server-side default is 60 seconds.

        [Parameter(
            ParameterSetName = 'Retail',
            Position = 4)]
        [Parameter(
            ParameterSetName = 'Flight',
            Position = 5)]
        [Parameter(
            ParameterSetName = 'Sandbox',
            Position = 5)]
        [string] $ClientRequestId,

        [Parameter(
            ParameterSetName = 'Retail',
            Position = 5)]
        [Parameter(
            ParameterSetName = 'Flight',
            Position = 6)]
        [Parameter(
            ParameterSetName = 'Sandbox',
            Position = 6)]
        [string] $CorrelationId,

        [Parameter(ParameterSetName = 'Retail')]
        [Parameter(ParameterSetName = 'Flight')]
        [Parameter(ParameterSetName = 'Sandbox')]
        [switch] $Force,

        [Parameter(
            ParameterSetName = 'Retail',
            Position = 6)]
        [Parameter(
            ParameterSetName = 'Flight',
            Position = 7)]
        [Parameter(
            ParameterSetName = 'Sandbox',
            Position = 7)]
        [string] $AccessToken,

        [Parameter(ParameterSetName = 'Retail')]
        [Parameter(ParameterSetName = 'Flight')]
        [Parameter(ParameterSetName = 'Sandbox')]
        [switch] $NoStatus
    )

    Write-Log -Message "Executing: $($MyInvocation.Line)" -Level Verbose

    # TODO: Get force working once flight is implemented
    if ($Force)
    {
        $message = "-Force is not implemented yet"
        Write-Log -Message $message -Level Error
        throw $message

    }

    if ([System.String]::IsNullOrEmpty($AccessToken))
    {
        $AccessToken = Get-AccessToken -NoStatus:$NoStatus
    }

    $getParams = @()
    if ($WaitSeconds -gt -2)
    {
        $getParams += "waitSeconds=$WaitSeconds"
    }

    # Convert the input into a Json body.
    $hashBody = @{}
    $hashBody['scope'] = $Scope

    if (-not [String]::IsNullOrWhiteSpace($FlightId))
    {
        $hashBody['flightId'] = $FlightId
    }

    if (-not [String]::IsNullOrWhiteSpace($SandboxId))
    {
        $hashBody['sandboxId'] = $SandboxId
    }

    $body = $hashBody | ConvertTo-Json
    Write-Log -Message "Body: $body" -Level Verbose

    $telemetryProperties = @{
        [StoreBrokerTelemetryProperty]::ProductId = $ProductId
        [StoreBrokerTelemetryProperty]::FlightId = $FlightId
        [StoreBrokerTelemetryProperty]::SandboxId = $SandboxId
        [StoreBrokerTelemetryProperty]::Scope = $Scope
        [StoreBrokerTelemetryProperty]::WaitSeconds = $WaitSeconds
        [StoreBrokerTelemetryProperty]::ClientRequestId = $ClientRequesId
        [StoreBrokerTelemetryProperty]::CorrelationId = $CorrelationId
    }

    $params = @{
        "UriFragment" = "products/$ProductId/submissions`?" + ($getParams -join '&')
        "Method" = 'Post'
        "Description" = "Creating a new submision for product: $ProductId"
        "Body" = $body
        "ClientRequestId" = $ClientRequestId
        "CorrelationId" = $CorrelationId
        "AccessToken" = $AccessToken
        "TelemetryEventName" = "New-Submission"
        "TelemetryProperties" = $telemetryProperties
        "NoStatus" = $NoStatus
    }

    return (Invoke-SBRestMethod @params)
}

function Remove-Submission
{
    [CmdletBinding(SupportsShouldProcess)]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSShouldProcess", "", Justification="Methods called within here make use of PSShouldProcess, and the switch is passed on to them inherently.")]
    [Alias("Delete-Submission")]
    param(
        [Parameter(Mandatory)]
        [ValidateScript({if ($_.Length -eq 12) { throw "It looks like you supplied an AppId instead of a ProductId.  Use Get-Products with -AppId to find the ProductId for this AppId." } else { $true }})]
        [string] $ProductId,

        [Parameter(Mandatory)]
        [string] $SubmissionId,

        [string] $ClientRequestId,

        [string] $CorrelationId,

        [string] $AccessToken,

        [switch] $NoStatus
    )

    Write-Log -Message "Executing: $($MyInvocation.Line)" -Level Verbose

    $telemetryProperties = @{
        [StoreBrokerTelemetryProperty]::ProductId = $ProductId
        [StoreBrokerTelemetryProperty]::SubmissionId = $SubmissionId
        [StoreBrokerTelemetryProperty]::ClientRequestId = $ClientRequesId
        [StoreBrokerTelemetryProperty]::CorrelationId = $CorrelationId
    }

    $params = @{
        "UriFragment" = "products/$ProductId/submissions/$SubmissionId"
        "Method" = "Delete"
        "Description" = "Deleting submission $SubmissionId for product: $ProductId"
        "ClientRequestId" = $ClientRequestId
        "CorrelationId" = $CorrelationId
        "AccessToken" = $AccessToken
        "TelemetryEventName" = "Remove-Submission"
        "TelemetryProperties" = $telemetryProperties
        "NoStatus" = $NoStatus
    }

    $null = Invoke-SBRestMethod @params
}

function Get-Submission
{
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [ValidateScript({if ($_.Length -gt 12) { $true } else { throw "It looks like you supplied an AppId instead of a ProductId.  Use Get-Products with -AppId to find the ProductId for this AppId." }})]
        [string] $ProductId,

        [Parameter(Mandatory)]
        [string] $SubmissionId,

        [string] $ClientRequestId,

        [string] $CorrelationId,

        [string] $AccessToken,

        [switch] $NoStatus,

        [switch] $Detail,

        [switch] $Reports,

        [switch] $Validation
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

        $params = @{
            "UriFragment" = "products/$ProductId/submissions/$SubmissionId"
            "Method" = 'Get'
            "Description" = "Getting submission $SubmissionId for $ProductId"
            "ClientRequestId" = $ClientRequestId
            "CorrelationId" = $CorrelationId
            "AccessToken" = $AccessToken
            "TelemetryEventName" = "Get-Submission"
            "TelemetryProperties" = $telemetryProperties
            "NoStatus" = $NoStatus
        }

        Write-Output (Invoke-SBRestMethod @params)

        $params = @{
            'ProductId' = $ProductId
            'SubmissionId' = $SubmissionId
            'ClientRequestId' = $ClientRequesId
            'CorrelationId' = $CorrelationId
            'AccessToken' = $AccessToken
            'NoStatus' = $NoStatus
        }

        if ($Detail)
        {
            Write-Output (Get-SubmissionDetail @params)
        }

        if ($Reports)
        {
            Write-Output (Get-SubmissionReports @params)
        }

        if ($Validation)
        {
            Write-Output (Get-SubmissionValidation @params)
        }
    }
    catch [System.InvalidOperationException]
    {
        throw
    }
}

function Stop-Submission
{
    [Alias('Cancel-Submission')]
    [CmdletBinding(SupportsShouldProcess)]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSShouldProcess", "", Justification="Methods called within here make use of PSShouldProcess, and the switch is passed on to them inherently.")]
    param(
        [Parameter(Mandatory)]
        [ValidateScript({if ($_.Length -gt 12) { $true } else { throw "It looks like you supplied an AppId instead of a ProductId.  Use Get-Products with -AppId to find the ProductId for this AppId." }})]
        [string] $ProductId,

        [Parameter(Mandatory)]
        [string] $SubmissionId,

        [string] $ClientRequestId,

        [string] $CorrelationId,

        [string] $AccessToken,

        [switch] $NoStatus
    )

    Write-Log -Message "Executing: $($MyInvocation.Line)" -Level Verbose

    $telemetryProperties = @{
        [StoreBrokerTelemetryProperty]::ProductId = $ProductId
        [StoreBrokerTelemetryProperty]::SubmissionId = $SubmissionId
        [StoreBrokerTelemetryProperty]::ClientRequestId = $ClientRequesId
        [StoreBrokerTelemetryProperty]::CorrelationId = $CorrelationId
    }

    $params = @{
        "UriFragment" = "products/$ProductId/submissions/$SubmissionId/cancel"
        "Method" = 'Post'
        "Description" = "Cancelling submission $SubmissionId"
        "ClientRequestId" = $ClientRequestId
        "CorrelationId" = $CorrelationId
        "AccessToken" = $AccessToken
        "TelemetryEventName" = "Stop-Submission"
        "TelemetryProperties" = $telemetryProperties
        "NoStatus" = $NoStatus
    }

    return (Invoke-SBRestMethod @params)
}

function Get-SubmissionDetail
{
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [ValidateScript({if ($_.Length -gt 12) { $true } else { throw "It looks like you supplied an AppId instead of a ProductId.  Use Get-Products with -AppId to find the ProductId for this AppId." }})]
        [string] $ProductId,

        [Parameter(Mandatory)]
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
            [StoreBrokerTelemetryProperty]::SubmissionId = $SubmissionId
            [StoreBrokerTelemetryProperty]::ClientRequestId = $ClientRequesId
            [StoreBrokerTelemetryProperty]::CorrelationId = $CorrelationId
        }

        $params = @{
            "UriFragment" = "products/$ProductId/submissions/$SubmissionId/detail"
            "Method" = 'Get'
            "Description" = "Getting details of submission $SubmissionId for $ProductId"
            "ClientRequestId" = $ClientRequestId
            "CorrelationId" = $CorrelationId
            "AccessToken" = $AccessToken
            "TelemetryEventName" = "Get-SubmissionDetail"
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

function Set-SubmissionDetail
{
    [CmdletBinding(SupportsShouldProcess)]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSShouldProcess", "", Justification="Methods called within here make use of PSShouldProcess, and the switch is passed on to them inherently.")]
    param(
        [Parameter(Mandatory)]
        [ValidateScript({if ($_.Length -gt 12) { $true } else { throw "It looks like you supplied an AppId instead of a ProductId.  Use Get-Products with -AppId to find the ProductId for this AppId." }})]
        [string] $ProductId,

        [Parameter(Mandatory)]
        [string] $SubmissionId,

        # $null means leave as-is, empty string means clear it out.
        [string] $CertificationNotes = $null,

        [DateTime] $ReleaseDate,

        [string] $ClientRequestId,

        [string] $CorrelationId,

        [switch] $ManualPublish,

        [switch] $AutoPromote,

        [string] $AccessToken,

        [switch] $NoStatus
    )

    Write-Log -Message "Executing: $($MyInvocation.Line)" -Level Verbose

    $telemetryProperties = @{
        [StoreBrokerTelemetryProperty]::ProductId = $ProductId
        [StoreBrokerTelemetryProperty]::SubmissionId = $SubmissionId
        [StoreBrokerTelemetryProperty]::UpdateCertificationNotes = ($null -ne $CertificationNotes)
        [StoreBrokerTelemetryProperty]::ClientRequestId = $ClientRequesId
        [StoreBrokerTelemetryProperty]::CorrelationId = $CorrelationId
    }

    # Convert the input into a Json body.
    $hashBody = @{}

    if ($null -ne $ReleaseDate)
    {
        $hashBody['releaseTimeInUtc'] = $ReleaseDate.ToUniversalTime().ToString('o')
    }

    # Very specifically choosing to NOT use [String]::IsNullOrWhiteSpace here, because
    # we need a way to be able to clear these notes out.  So, a $null means do nothing,
    # while empty string / whitespace means clear out the notes.
    if ($null -ne $CertificationNotes)
    {
        $hashBody['certificationNotes'] = $CertificationNotes
    }

    # We only set the value if the user explicitly provided a value for this parameter
    # (so for $false, they'd have to pass in -ManualPublish:$false).
    # Otherwise, there'd be no way to know when the user wants to simply keep the
    # existing value.
    if ($null -ne $PSBoundParameters['ManualPublish'])
    {
        $hashBody['isManualPublish'] = $ManualPublish
        $telemetryProperties[[StoreBrokerTelemetryProperty]::IsManualPublish] = $ManualPublish
    }

    # We only set the value if the user explicitly provided a value for this parameter
    # (so for $false, they'd have to pass in -AutoPromote:$false).
    # Otherwise, there'd be no way to know when the user wants to simply keep the
    # existing value.
    if ($null -ne $PSBoundParameters['AutoPromote'])
    {
        $hashBody['isAutoPromote'] = $AutoPromote
        $telemetryProperties[[StoreBrokerTelemetryProperty]::IsAutoPromote] = $AutoPromote
    }

    $body = $hashBody | ConvertTo-Json
    Write-Log -Message "Body: $body" -Level Verbose

    $params = @{
        "UriFragment" = "products/$ProductId/submissions/$SubmissionId/detail"
        "Method" = 'Put'
        "Description" = "Updating detail for submission: $SubmissionId"
        "Body" = $body
        "ClientRequestId" = $ClientRequestId
        "CorrelationId" = $CorrelationId
        "AccessToken" = $AccessToken
        "TelemetryEventName" = "Set-SubmissionDetail"
        "TelemetryProperties" = $telemetryProperties
        "NoStatus" = $NoStatus
    }

    return (Invoke-SBRestMethod @params)
}

function Push-Submission
{
    [Alias('Promote-Submission')]
    [CmdletBinding(SupportsShouldProcess)]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSShouldProcess", "", Justification="Methods called within here make use of PSShouldProcess, and the switch is passed on to them inherently.")]
    param(
        [Parameter(Mandatory)]
        [ValidateScript({if ($_.Length -gt 12) { $true } else { throw "It looks like you supplied an AppId instead of a ProductId.  Use Get-Products with -AppId to find the ProductId for this AppId." }})]
        [string] $ProductId,

        [Parameter(Mandatory)]
        [string] $SubmissionId,

        [string] $ClientRequestId,

        [string] $CorrelationId,

        [string] $AccessToken,

        [switch] $NoStatus
    )

    Write-Log -Message "Executing: $($MyInvocation.Line)" -Level Verbose

    $telemetryProperties = @{
        [StoreBrokerTelemetryProperty]::ProductId = $ProductId
        [StoreBrokerTelemetryProperty]::SubmissionId = $SubmissionId
        [StoreBrokerTelemetryProperty]::ClientRequestId = $ClientRequesId
        [StoreBrokerTelemetryProperty]::CorrelationId = $CorrelationId
    }

    $params = @{
        "UriFragment" = "products/$ProductId/submissions/$SubmissionId/promote"
        "Method" = 'Post'
        "Description" = "Promoting submission $SubmissionId"
        "ClientRequestId" = $ClientRequestId
        "CorrelationId" = $CorrelationId
        "AccessToken" = $AccessToken
        "TelemetryEventName" = "Push-Submission"
        "TelemetryProperties" = $telemetryProperties
        "NoStatus" = $NoStatus
    }

    return (Invoke-SBRestMethod @params)
}

function Publish-Submission
{
    [CmdletBinding(SupportsShouldProcess)]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSShouldProcess", "", Justification="Methods called within here make use of PSShouldProcess, and the switch is passed on to them inherently.")]
    param(
        [Parameter(Mandatory)]
        [ValidateScript({if ($_.Length -gt 12) { $true } else { throw "It looks like you supplied an AppId instead of a ProductId.  Use Get-Products with -AppId to find the ProductId for this AppId." }})]
        [string] $ProductId,

        [Parameter(Mandatory)]
        [string] $SubmissionId,

        [string] $ClientRequestId,

        [string] $CorrelationId,

        [string] $AccessToken,

        [switch] $NoStatus
    )

    Write-Log -Message "Executing: $($MyInvocation.Line)" -Level Verbose

    $telemetryProperties = @{
        [StoreBrokerTelemetryProperty]::ProductId = $ProductId
        [StoreBrokerTelemetryProperty]::SubmissionId = $SubmissionId
        [StoreBrokerTelemetryProperty]::ClientRequestId = $ClientRequesId
        [StoreBrokerTelemetryProperty]::CorrelationId = $CorrelationId
    }

    $params = @{
        "UriFragment" = "products/$ProductId/submissions/$SubmissionId/publish"
        "Method" = 'Post'
        "Description" = "Publishing submission $SubmissionId"
        "ClientRequestId" = $ClientRequestId
        "CorrelationId" = $CorrelationId
        "AccessToken" = $AccessToken
        "TelemetryEventName" = "Publish-Submission"
        "TelemetryProperties" = $telemetryProperties
        "NoStatus" = $NoStatus
    }

    return (Invoke-SBRestMethod @params)
}

function Get-SubmissionReports
{
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [ValidateScript({if ($_.Length -gt 12) { $true } else { throw "It looks like you supplied an AppId instead of a ProductId.  Use Get-Products with -AppId to find the ProductId for this AppId." }})]
        [string] $ProductId,

        [Parameter(Mandatory)]
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

        $params = @{
            "UriFragment" = "products/$ProductId/submissions/$SubmissionId/reports"
            "Description" = "Getting reports of submission $SubmissionId for $ProductId"
            "ClientRequestId" = $ClientRequestId
            "CorrelationId" = $CorrelationId
            "AccessToken" = $AccessToken
            "TelemetryEventName" = "Get-SubmissionReports"
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

function Submit-Submission
{
    [Alias('Commit-Submission')]
    [Alias('Copmlete-Submission')]
    [CmdletBinding(SupportsShouldProcess)]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSShouldProcess", "", Justification="Methods called within here make use of PSShouldProcess, and the switch is passed on to them inherently.")]
    param(
        [Parameter(Mandatory)]
        [ValidateScript({if ($_.Length -gt 12) { $true } else { throw "It looks like you supplied an AppId instead of a ProductId.  Use Get-Products with -AppId to find the ProductId for this AppId." }})]
        [string] $ProductId,

        [Parameter(Mandatory)]
        [string] $SubmissionId,

        [string] $ClientRequestId,

        [string] $CorrelationId,

        [string] $AccessToken,

        [switch] $Auto,

        [switch] $NoStatus
    )

    Write-Log -Message "Executing: $($MyInvocation.Line)" -Level Verbose

    $telemetryProperties = @{
        [StoreBrokerTelemetryProperty]::ProductId = $ProductId
        [StoreBrokerTelemetryProperty]::SubmissionId = $SubmissionId
        [StoreBrokerTelemetryProperty]::Auto = $Auto
        [StoreBrokerTelemetryProperty]::ClientRequestId = $ClientRequesId
        [StoreBrokerTelemetryProperty]::CorrelationId = $CorrelationId
    }

    $getParams = @()
    if ($Auto)
    {
        $getParams += "auto=$Auto"
    }

    $params = @{
        "UriFragment" = "products/$ProductId/submissions/$SubmissionId/submit`?" + ($getParams -join '&')
        "Method" = 'Post'
        "Description" = "Submitting submission $SubmissionId"
        "ClientRequestId" = $ClientRequestId
        "CorrelationId" = $CorrelationId
        "AccessToken" = $AccessToken
        "TelemetryEventName" = "Submit-Submission"
        "TelemetryProperties" = $telemetryProperties
        "NoStatus" = $NoStatus
    }

    return (Invoke-SBRestMethod @params)
}

function Get-SubmissionValidation
{
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [ValidateScript({if ($_.Length -gt 12) { $true } else { throw "It looks like you supplied an AppId instead of a ProductId.  Use Get-Products with -AppId to find the ProductId for this AppId." }})]
        [string] $ProductId,

        [Parameter(Mandatory)]
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
            [StoreBrokerTelemetryProperty]::SubmissionId = $SubmissionId
            [StoreBrokerTelemetryProperty]::ClientRequestId = $ClientRequesId
            [StoreBrokerTelemetryProperty]::CorrelationId = $CorrelationId
        }

        $params = @{
            "UriFragment" = "products/$ProductId/submissions/$SubmissionId/validation"
            "Method" = 'Get'
            "Description" = "Getting validation of submission $SubmissionId for $ProductId"
            "ClientRequestId" = $ClientRequestId
            "CorrelationId" = $CorrelationId
            "AccessToken" = $AccessToken
            "TelemetryEventName" = "Get-SubmissionValidation"
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
