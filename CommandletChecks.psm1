# Output-CmdltPsVersionCompatibility -CmdletsAsString "Get-Alias", "Get-Acl", "New-SelfSignedCertificate"
# Output-CmdltPsVersionCompatibility -File "C:\temp\BuildScript.ps1"
# Credits to https://stackoverflow.com/a/36191405/2964949 @Charlie Joynt
function Output-CmdltPsVersionCompatibility {
    param(
      [string]$file,
      [string[]]$cmdletsAsString
    )

    New-Variable tokens
    New-Variable parseerrors
    if($file) {
        $p = [System.Management.Automation.Language.Parser]::ParseFile($file,[ref]$tokens,[ref]$parseerrors)
    }
    elseif($cmdletsAsString) {
        $p = [System.Management.Automation.Language.Parser]::ParseInput(($cmdletsAsString -join "`n"),[ref]$tokens,[ref]$parseerrors)
    }
    $Commands = $tokens | ?{$_.TokenFlags -contains "CommandName"} | Sort -Unique | Select Value

    $ScriptBlock = {
      param($PSVersion,$Commands)

      $Output = New-Object -TypeName PSObject -Property @{PSVersion = $PSVersion}


      foreach($Command in $Commands) {
        if([String]::IsNullOrEmpty($Command.Value)){continue}

        if(Get-Command | ?{$_.Name -eq $Command.Value}) {
          $Available = $true
        } else {
          $Available = $false
        }

        $Output | Add-Member -MemberType NoteProperty -Name $($Command.Value) -Value $Available
      }

      return $Output
    }

    $Results = @()

    foreach($PSVersion in 2..4) {
      $job = Start-Job -PSVersion "$PSVersion.0" -ScriptBlock $ScriptBlock -ArgumentList $PSVersion,$Commands

      Wait-Job $job | Out-Null
      $Results += (Receive-Job $job | Select PSVersion,*-*)
      Remove-Job $job
    }

    $Results | FT -AutoSize

    Remove-Variable tokens
    Remove-Variable parseerrors
}

Output-CmdltPsVersionCompatibility -cmdletsAsString "Get-Alias", "Get-Acl", "New-SelfSignedCertificate"