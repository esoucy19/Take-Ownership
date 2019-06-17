<#
This script must be run as admin.

Recursively takes ownership and grants full control access of all folders in a
hierarchy. The new owner will be the Administrators group.

Normally, running takeown.exe ... /D Y will destructively replace the
permissions on all subfolders. To prevent this, the cmdlet runs takeown
with the /D N flag. This means that we will not be recursively granted
permissions on subfolders though.

This is where the loop comes in. After each run of takeown, we run icacls on
the folders, granting our target user full permissions on the folders. icacls
will usually encounter a folder we don't have ownership on and fail after
a partial run. If icacls fails, we rerun takeown, which will take ownership
of some new folders down the line. We then rerun icacls once again, and so on
and so forth until icacls finishes with no error message, which will signify
we've sucessfully taken ownership of and granted our target user permission
on all folders.

WARNING: This script is very powerful and very unsafe, use with caution.

$Paths: The target folder(s). The script will take ownership of this folder and all
subfolders. The parameter can accept multiple paths. Aliased to "Path".

$User: The user account to grand full control access to. By default this will
be the current user.

This script now uses a powershell workflow for added speed.
#>
[CmdletBinding()]
Param(
    [Parameter(Mandatory=$true)]
    [Alias("Path")]
    [String[]]$Paths,
    [String]$User = "$env:UserDomain\$env:UserName"
)

Begin{
    Function TakeOwnership {
        [CmdletBinding()]
        Param(
            [String]$Path,
            [String]$User
        )
        $ExitCode = 1
        while ($ExitCode -ne 0) {
            Start-Process "takeown.exe" -ArgumentList "/R /A /F $Path /D N" -Wait
            $Result = Start-Process "icacls.exe" -ArgumentList "$Path /grant $($User):F /T" -Wait -PassThru
            $ExitCode = $Result.ExitCode
        }
    }

    Workflow TakeOwnershipParallel {
        [CmdletBinding()]
        Param(
            [Parameter(Mandatory=$true)]
            [Alias("Path")]
            [String[]]$Paths,
            [String]$User
        )
        ForEach -Parallel ($Path in $Paths) {
            TakeOwnership -Path Path -User $User
        }
    }

    $SubPaths = @()
    ForEach ($Path in $Paths) {
        $SubPaths += Get-ChildItem -Directory -Path $Path | Select-Object -ExpandProperty FullName
    }
}

Process{
    TakeOwnershipParallel -Path $SubPaths -User $User
}

End{}
