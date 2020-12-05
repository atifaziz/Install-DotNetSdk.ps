# Copyright (c) 2020 Atif Aziz. All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

[CmdletBinding(DefaultParameterSetName="JsonFile")]
param([Parameter(ParameterSetName='Version')]
      [ValidatePattern("^(0|[1-9]+)(\.[0-9]+){2}$", ErrorMEssage="Version must use the MAJOR.MINOR.PATCH scheme.")]
      [string]$Version,
      [Parameter(ParameterSetName='JsonFile')][string]$JsonFile,
      [switch]$Force,
      [string]$UserAgent)

function FindDotNetSdk($version)
{
    $dotnetCommand = Get-Command dotnet -ErrorAction SilentlyContinue
    if (!$dotnetCommand) {
        return $false
    }
    $sdks = dotnet --list-sdks | % { ($_ -split ' ', 2)[0] }
    Write-Verbose ".NET (Core) SDK versions found: $($sdks -join ', ')"
    return $sdks -contains $version
}

$ErrorActionPreference = 'Stop'

if (!$userAgent) {
    $userAgent = "PowerShell/$($PSVersionTable.PSVersion.Major).$($PSVersionTable.PSVersion.Minor)"
}

if ($PSCmdlet.ParameterSetName -eq 'JsonFile')
{
    if (!$jsonFile)
    {
        $jsonFile = Join-Path $pwd 'global.json'
        Write-Verbose "Assuming to find: $jsonFile"

        if (!(Test-Path -PathType Leaf $jsonFile))
        {
            throw "No ""global.json"" found to determine required SDK version. " +
                  "Either specify the path to ""global.json"" (via the -JsonFile parameter) " +
                  "or the SDK version (via the -Version parameter)."
        }
    }

    $version = (Get-Content -Raw $jsonFile | ConvertFrom-Json).sdk.version
    if (!$version) {
        throw "Unable to determine the required .NET (Core) SDK version from ""$jsonFile""."
    }

    Write-Verbose "Per ""$jsonFile"", required SDK version is $version."
}

if (FindDotNetSdk $version) {
    if (!$force) {
        return
    }
}

Write-Verbose "The required .NET (Core) SDK is missing. The installer will be downloaded and launched."

if (!($version -match '^[0-9]+\.[0-9](?=\.)')) {
    throw "Invalid SDK version scheme: $version"
}

$channelVersion = $matches[0]
Write-Verbose "Assuming SDK version $version belongs to version channel $channelVersion."

$channelReleasesUrl =
    Invoke-RestMethod 'https://dotnetcli.blob.core.windows.net/dotnet/release-metadata/releases-index.json' `
            -UserAgent $userAgent | `
        Select-Object -ExpandProperty 'releases-index' | `
        ? { $_.'channel-version' -eq $channelVersion } | `
        Select-Object -ExpandProperty 'releases.json'

Write-Verbose "URL for channel $channelVersion is: $channelReleasesUrl"

[uri]$installerUrl =
Invoke-RestMethod $channelReleasesUrl -UserAgent $userAgent | `
        % { $_.releases.sdks } | `
        ? { $_.version -eq $version } | `
        % { $_.files } | `
        ? { $_.rid -eq 'win-x64' -and $_.name -like '*.exe' } | `
        Select-Object -ExpandProperty url

if (!$installerUrl) {
    throw "Unable to determine the download URL for .NET (Core) SDK $version."
}

Write-Verbose ".NET (Core) SDK Installer download is: $installerUrl"

$installerFileName = $installerUrl.Segments[-1]
Write-Verbose ".NET (Core) SDK Installer file name is: $installerFileName"

$installerPath = Join-Path (Get-PSDrive TEMP).Root $installerFileName

Invoke-WebRequest $installerUrl -OutFile $installerPath -UserAgent $userAgent

Write-Output "The installer will now be launched. Please complete the installation interactively." `
             "This script will resume once the installer has ended."

Start-Process -Wait $installerPath

if (!(FindDotNetSdk $version)) {
    Write-Warning ".NET (Core) SDK $version still does not appear to be installed. Installation aborted?"
}
