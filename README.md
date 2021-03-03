# PowerShell-No-Library-Just-Functions

Usefull powerShell functions for people, that do not want to use a 3rd library.

Just copy the source code form this repo and impor the functions in to your runspace!


## FTPModule

In the module are functions for removing / adding / reading folders and files recursively.

### Examples

#### Get files from ftp path

```PowerShell
Get-FtpChildItem -ftpFilePath "ftp://myHost.com/root/leaf/" -userName "User" -password "pw" -hidden $false -File
```

#### Get hidden files and folders from FTP path

```PowerShell
Get-FtpChildItemHidden -ftpFolderPath "ftp://myHost.com/root/leaf/" -userName "User" -password "pw" -File -Directory
```



#### Get folder from ftp path

```PowerShell
Get-FtpChildItem -ftpFilePath "ftp://myHost.com/root/leaf/" -userName "User" -password "pw" -Directory
```


#### Delete file from ftp

```PowerShell
Remove-FtpFolderWithFilesRecursive -ftpFilePath "ftp://myHost.com/root/leaf/world.mine" -userName "User" -password "pw"
```


#### Delete folder recursively from ftp

```PowerShell
Remove-FtpFolderWithFilesRecursive -ftpFilePath "ftp://myHost.com/root/leaf/" -userName "User" -password "pw"
```

#### Create new empty folder on ftp path

```PowerShell
Add-FtpDirectory -ftpFilePath "ftp://myHost.com/shouldCreate/" -userName "User" -password "pw"
```

#### Upload local file to ftp path

```PowerShell
Add-FtpFile -ftpFilePath "ftp://myHost.com/folder/somewhere/uploaded.txt" -localFile "C:\temp\file.txt" -userName "User" -password "pw"
```

#### Upload local folder including files to ftp (only one layer without sub folders)

```PowerShell
Add-FtpFolderWithFiles -sourceFolder "C:\temp\" -destinationFolder "ftp://myHost.com/folder/somewhere/" -userName "User" -password "pw"
```

#### Upload local folder with recursive structure including files to ftp with same structure

```PowerShell
Add-FtpFolderWithFilesRecursive -sourceFolder "C:\temp\" -destinationFolder "ftp://myHost.com/folder/" -userName "User" -password "pw"
```

