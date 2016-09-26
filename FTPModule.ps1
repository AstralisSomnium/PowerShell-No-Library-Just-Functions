function New-FtpRequest ($sourceUri, $method, $username, $password) {
    $ftprequest = [System.Net.FtpWebRequest]::Create($sourceuri)
    $ftprequest.Method = $method
    $ftprequest.Credentials = New-Object System.Net.NetworkCredential($username,$password)
    return $ftprequest
}

function Send-FtpRequest($ftpRequest) {
    Write-Host "$($ftpRequest.Method) for '$($ftpRequest.RequestUri)' executing"
    $response = $ftprequest.GetResponse()
    $closed = $response.Close()
    Write-Host "Response: '$($response.StatusDescription)'"
    return $response
}

function Parse-Output($output, [System.Management.Automation.SwitchParameter]$file, [System.Management.Automation.SwitchParameter]$directory) {
    $entities = @()
    foreach ($CurLine in $output) {
        $LineTok = ($CurLine -split '\ +')
        $currentEntity = $LineTok[8..($LineTok.Length-1)]
        if(-not $currentEntity) { continue }
        $isDirectory = $LineTok[0].StartsWith("d")
        if($file -and -not $isDirectory) {
            $entities += $currentEntity
        } elseif($directory -and $isDirectory) {
            $entities += $currentEntity
        }
    }
    return $entities
}

#Get-FtpChildItemHidden -ftpFilePath "ftp://myHost.com/root/leaf/" -userName "User" -password "pw" -File -Directory
function Get-FtpChildItemHidden($ftpFolderPath, $userName, $password, [System.Management.Automation.SwitchParameter]$file, [System.Management.Automation.SwitchParameter]$directory) {
    $ftpUrl = New-Object System.Uri($ftpFolderPath)
    $getHiddenFilesScript = "$env:TMP\getHiddenEntity.dat"
    $outPutEntity = "$env:TMP\hiddenEntity.txt"
    $commands = @("open $($ftpUrl.Host)", $userName, $password, "cd $($ftpUrl.PathAndQuery)", "ls -la", "bye" )
    $commands | foreach {
        Add-Content $getHiddenFilesScript -Value $_
    }
    ftp -s:$getHiddenFilesScript > $outPutEntity
    Remove-Item $getHiddenFilesScript -Force
    $ftpOutput = Get-Content $outPutEntity
    Remove-Item $outPutEntity -Force

    $startEntityOutput = ".."
    $endEntityOutput = "226 Directory send OK."
    $startIndex = $ftpOutput | where {$_.ToString().Contains($startEntityOutput)} | foreach { $ftpOutput.IndexOf($_) }
    $endIndex = $ftpOutput.IndexOf($endEntityOutput) - 1
    $entityOutput = @()
    for($i = $startIndex+1; $i -le $endIndex; $i++) {
        $entityOutput += $ftpOutput[$i]
    }
    $entities = @()
    (Parse-Output -output $entityOutput -Directory:$directory -File:$file ) | foreach {
        $entities += "$($ftpFolderPath)/$($_)"
    }
    return $entities
}

#Get-FtpChildItem -ftpFilePath "ftp://myHost.com/root/leaf/" -userName "User" -password "pw" -hidden $false -File
#Get-FtpChildItem -ftpFilePath "ftp://myHost.com/root/leaf/" -userName "User" -password "pw" -Directory
function Get-FtpChildItem($ftpFolderPath, $username, $password, [System.Management.Automation.SwitchParameter]$file, [System.Management.Automation.SwitchParameter]$directory, $hidden = $true) {
    if($hidden) {
        return Get-FtpChildItemHidden -ftpFolderPath $ftpFolderPath -userName $username -password $password -file:$file -directory:$directory
    }
    $ftprequest = New-FtpRequest -sourceUri $ftpFolderPath -method ([System.Net.WebRequestMethods+Ftp]::ListDirectoryDetails + " -a") -username $username -password $password
    $FTPResponse = $ftprequest.GetResponse()
    $ResponseStream = $FTPResponse.GetResponseStream()
    $StreamReader = New-Object System.IO.Streamreader $ResponseStream
    $DirListing = (($StreamReader.ReadToEnd()) -split [Environment]::NewLine)
    $StreamReader.Close()
    $FTPResponse.Close()
    $entities = @()
    (Parse-Output -output $entityOutput -Directory:$directory -File:$file ) | foreach {
        $entities += "$($ftpFolderPath)/$($_)"
    }
    return $entities
}

#Remove-FtpFolderWithFilesRecursive -ftpFilePath "ftp://myHost.com/root/leaf/world.mine" -userName "User" -password "pw"
function Remove-FtpFile($ftpFilePath, $username, $password) {
    $ftprequest = New-FtpRequest -sourceUri $ftpFilePath -method ([System.Net.WebRequestMethods+Ftp]::DeleteFile) -username $username -password $password    
    $response = Send-FtpRequest $ftprequest
}

#Remove-FtpFolderWithFilesRecursive -ftpFilePath "ftp://myHost.com/root/leaf/" -userName "User" -password "pw"
function Remove-FtpDirectory($ftpFolderPath, $username, $password) {
    $ftprequest = New-FtpRequest -sourceUri $ftpFolderPath -method ([System.Net.WebRequestMethods+Ftp]::RemoveDirectory) -username $username -password $password    
    $response = Send-FtpRequest $ftprequest
}

#Remove-FtpFolderWithFilesRecursive -ftpFilePath "ftp://myHost.com/root/" -userName "User" -password "pw"
function Remove-FtpFolderWithFilesRecursive($destinationFolder, $userName, $password) {
    $files = Get-FtpChildItem -ftpFolderPath $destinationFolder -username $userName -password $password -File
    foreach($file in $files) {
        Remove-FtpFile -ftpFilePath $file -username $userName -password $password
    }
    $subDirectories = Get-FtpChildItem -ftpFolderPath $destinationFolder -username $userName -password $password -Directory
    foreach($subDirectory in $subDirectories) {
        Remove-FtpFolderWithFilesRecursive -destinationFolder ($subDirectory+"/") -userName $userName -pas $password
    }
    Remove-FtpDirectory $destinationFolder $userName $password
}

#Add-FtpDirectory -ftpFilePath "ftp://myHost.com/shouldCreate/" -userName "User" -password "pw"
function Add-FtpDirectory($ftpFolderPath, $username, $password) {
    try {
          $ftprequest = New-FtpRequest -sourceUri $ftpFolderPath -method ([System.Net.WebRequestMethods+Ftp]::MakeDirectory) -username $username -password $password
          $response = Send-FtpRequest $ftprequest
     } catch {
        Write-Host "Creating folder '$ftpFolderPath' failed, maybe because this folder already exists."
     }
}

#Add-FtpFile -ftpFilePath "ftp://myHost.com/folder/somewhere/uploaded.txt" -localFile "C:\temp\file.txt" -userName "User" -password "pw"
function Add-FtpFile($ftpFilePath, $localFile, $username, $password) {
    $ftprequest = New-FtpRequest -sourceUri $ftpFilePath -method ([System.Net.WebRequestMethods+Ftp]::UploadFile) -username $username -password $password
    Write-Host "$($ftpRequest.Method) for '$($ftpRequest.RequestUri)' complete'"
    $content = $content = [System.IO.File]::ReadAllBytes($localFile)
    $ftprequest.ContentLength = $content.Length
    $requestStream = $ftprequest.GetRequestStream()
    $requestStream.Write($content, 0, $content.Length)
    $requestStream.Close()
    $requestStream.Dispose()
}

#Add-FtpFolderWithFiles -sourceFolder "C:\temp\" -destinationFolder "ftp://myHost.com/folder/somewhere/" -userName "User" -password "pw"
function Add-FtpFolderWithFiles($sourceFolder, $destinationFolder, $userName, $password) {
    Add-FtpDirectory $destinationFolder $userName $password
    $files = Get-ChildItem $sourceFolder -File
    foreach($file in $files) {
        $uploadUrl ="$destinationFolder/$($file.Name)"
        Add-FtpFile -ftpFilePath $uploadUrl -localFile $file.FullName -username $userName -password $password
    }
}

#Add-FtpFolderWithFilesRecursive -sourceFolder "C:\temp\" -destinationFolder "ftp://myHost.com/folder/" -userName "User" -password "pw"
function Add-FtpFolderWithFilesRecursive($sourceFolder, $destinationFolder, $userName, $password) {
    Add-FtpFolderWithFiles -sourceFolder $sourceFolder -destinationFolder $destinationFolder -userName $userName -password $password
    $subDirectories = Get-ChildItem $sourceFolder -Directory
    $fromUri = new-object System.Uri($sourceFolder)
    foreach($subDirectory in $subDirectories) {
        $toUri  = new-object System.Uri($subDirectory.FullName)
        $relativeUrl = $fromUri.MakeRelativeUri($toUri)
        $relativePath = [System.Uri]::UnescapeDataString($relativeUrl.ToString())
        $lastFolder = $relativePath.Substring($relativePath.LastIndexOf("/")+1)
        Add-FtpFolderWithFilesRecursive -sourceFolder $subDirectory.FullName -destinationFolder "$destinationFolder/$lastFolder" -userName $userName -password $password
    }
}