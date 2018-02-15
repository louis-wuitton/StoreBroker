# Copyright (C) Microsoft Corporation.  All rights reserved.

<#
    .SYNOPSIS
        Script for converting an existing In-AppProduct (IAP) submission in the Store
        to the January 2017 PDP schema.

    .DESCRIPTION
        Script for converting an existing In-AppProduct (IAP) submission in the Store
        to the January 2017 PDP schema.

        The Git-repo for the StoreBroker module can be found here: http://aka.ms/StoreBroker

    .PARAMETER IapId
        The ID of the IAP that the PDP's will be getting created for.
        The most recent submission for this IAP will be used unless a SubmissionId is
        explicitly specified.

    .PARAMETER SubmissionId
        The ID of the application submission that the PDP's will be getting created for.
        The most recent submission for IapId will be used unless a value for this parameter is
        provided.

    .PARAMETER SubmissionId
        The submission object that you want to convert, which was previously retrieved.

    .PARAMETER Release
        The release to use.  This value will be placed in each new PDP and used in conjunction with '-OutPath'.
        Some examples could be "1601" for a January 2016 release, "March 2016", or even just "1".

    .PARAMETER PdpFileName
        The name of the PDP file that will be generated for each region.

    .PARAMETER OutPath
        The output directory.
        This script will create two subfolders of OutPath:
           <OutPath>\PDPs\<Release>\
           <OutPath>\Images\<Release>\
        Each of these sub-folders will have region-specific subfolders for their file content.

    .EXAMPLE
        .\ConvertFrom-ExistingIapSubmission -IapId 0ABCDEF12345 -Release "March Release" -OutPath "C:\NewPDPs"

        Converts the data from the last published submission for IapId 0ABCDEF12345.  The generated files
        will use the default name of "PDP.xml" and be located in lang-code specific sub-directories within
        c:\NewPDPs.

    .EXAMPLE
        .\ConvertFrom-ExistingIapSubmission -IapId 0ABCDEF12345 -SubmissionId 1234567890123456789 -Release "March Release" -PdpFileName "InAppProductDescription.xml" -OutPath "C:\NewPDPs"

        Converts the data from submission 1234567890123456789 for IapId 0ABCDEF12345 (which might be a
        published or pending submission).  The generated files will be named "InAppProductDescription.xml" and
        will be located in lang-code specific sub-directories within c:\NewPDPs.

    .EXAMPLE
        .\ConvertFrom-ExistingIapSubmission -Submission $sub -Release "March Release" -OutPath "C:\NewPDPs"

        Converts the data from a submission object that was captured earlier in your PowerShell session.
        It might have come from Get-InAppProductSubmission, or it might have been generated some other way.
        This method of running the script was created more for debugging purposes, but others may find it
        useful. The generated files will use the default name of "PDP.xml" and be located in lang-code
        specific sub-directories within c:\NewPDPs.
#>
[CmdletBinding(
    SupportsShouldProcess,
    DefaultParametersetName = "UseApi")]
param(
    [Parameter(
        Mandatory,
        ParameterSetName = "UseApi",
        Position = 0)]
    [string] $IapId,

    [Parameter(
        ParameterSetName = "UseApi",
        Position = 1)]
    [string] $SubmissionId = $null,

    [Parameter(
        Mandatory,
        ParameterSetName = "ProvideSubmission",
        Position = 0)]
    [PSCustomObject] $Submission = $null,

    [Parameter(Mandatory)]
    [string] $Release,

    [string] $PdpFileName = "PDP.xml",

    [Parameter(Mandatory)]
    [string] $OutPath
)

if ($null -eq (Get-Module StoreBroker))
{
    $message = "The StoreBroker module is not available in this PowerShell session.  Please import the module, authenticate correctly using Set-StoreBrokerAuthentication, and try again."
    throw $message
}

ConvertFrom-ExistingIapSubmission @MyInvocation.MyCommand.Parameters
