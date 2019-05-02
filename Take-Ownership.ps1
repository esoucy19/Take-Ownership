<#
This script must be run as admin.

Recursively takes ownership and grants full control access of all folders in a
hierarchy. The new owner will be the Administrators group.

By default, the script will run on the current folder.

$Path: The target folder. The script will take ownership of this folder and all
subfolders. This is ".\" by default.

$User: The user account to grand full control access to. By default this will
be the current user.
#>
[CmdletBinding()]
Param(
[String]
$Path = ".\",
[String]
$User = "$env:UserDomain\$env:UserName"
)

Begin{}

Process{
    $exitcode = 1
    while ($exitcode -ne 0) {
        Start-Process "takeown.exe" -ArgumentList "/R /A /F $Path /D N" -Wait
        $result = Start-Process "icacls.exe" -ArgumentList "$Path /grant $($User):F /T" -Wait -PassThru
        $exitcode = $result.ExitCode
    }
}

End{}
