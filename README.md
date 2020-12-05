# Install-DotNetSDK

`Install-DotNetSDK.ps1` is a PowerShell script designed to install the
[.NET][dotnet] (Core) SDK by searching, downloading & launching  the installer
for a given version number.


## Usage

    Install-DotNetSdk.ps1 [-JsonFile <string>] [-Force] [-UserAgent <string>] [<CommonParameters>]
    Install-DotNetSdk.ps1 [-Version <string>] [-Force] [-UserAgent <string>] [<CommonParameters>]

There are two ways to specify the SDK version to install. Either:

1. specify the path of a [`global.json`][global.json] file via the `-JsonFile`
   parameter.
2. specify the version using the `MAJOR.MINOR.PATCH` scheme via the `-Version`
   parameter.

In the first case, the SDK version will be read from `global.json` and proceed
like the second case.


## Limitations

- Works only on Windows
- Final installer runs interactively due to potential UAC prompts
- Installs releases only, not previews


  [dotnet]: https://dot.net/
  [global.json]: https://docs.microsoft.com/en-us/dotnet/core/tools/global-json
