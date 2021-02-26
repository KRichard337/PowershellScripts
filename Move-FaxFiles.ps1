<#	
	.NOTES
	===========================================================================
	 Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2020 v5.7.174
	 Created on:   	1/21/2021 2:45 PM
	 Created by:   	Kevin Richard
	 Organization: 	
	 Filename:     	Move-FaxFiles
	===========================================================================
	.DESCRIPTION
		Moves files between folder structures. Will create destination folder if it doesn't exist.
#>

#Establish Environment Variables
$PathErrorFile = "C:\scripts\logs\PathError.txt"
$MoveErrorFile = "C:\scripts\logs\MoveError.txt"
$MailTo = #Email Address to receive error notifications
$MailFrom = #Address to send from
$SMTPServer = #SMTP Server
$CernerFaxUser = #User Account For Shared Folder
$CernerFaxPass = #Encrypted Password File
#Pulled from securefile. Needed to authenticate against Cerner's server.'
$CernerFaxCred = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $CernerFaxUser, (Get-Content $CernerFaxPass | ConvertTo-SecureString)
$CernerPSDrivePath = #Destination UNC 
$Source = #UNC path for source folder tree
$Destination = #PSDrive Name
$FaxFileExtension = "*.TIF"

$Folders = Get-ChildItem -LiteralPath $Source -Depth 0 | Where-Object { $_.PsIsContainer -and $_.GetFiles($FaxFileExtension).Count }

#Exit script if there are no files to transfer
if ($Folders.Count -eq 0)
{
	exit
} #IF

#Creating Network Share to Cerner incoming fax folder
if (!(Get-PSDrive CernerFax -ErrorAction SilentlyContinue))
{
	New-PSDrive -Name 'CernerFax' -PSProvider FileSystem -Root $CernerPSDrivePath -Credential $CernerFaxCred
} #IF


#Test Paths to ensure they exist
if ((Test-Path -LiteralPath $Source) -and (Test-Path -LiteralPath $Destination))
{
	if (Test-Path -LiteralPath $PathErrorFile)
	{
		#Clearing Error File
		Remove-Item -LiteralPath $PathErrorFile
	} #IF
} #IF

else
{
	#This prevents the script from spamming the user with emails.
	if (Test-Path -LiteralPath $PathErrorFile)
	{
		exit
	} #IF
	
	else
	{
		$Error[0] | Out-File $PathErrorFile -Append
		
		$params = @{
			
			From    = $MailFrom;
			To	    = $MailTo;
			Subject = "Fax Script Test Path Failed";
			Body    = $Error[0]
			SmtpServer = $SMTPServer
			
		} #PARAMS
		Send-MailMessage @params
		exit
		
	}#ELSE
	
} #ELSE
#Search Source Directory for Folders with Faxes

foreach ($folder in $folders)
{
	$FolderName = $folder.Name
	
	#Skip Folder if Destination does not exist
	if ((Test-Path $Destination\$FolderName) -ne $true)
	{
		continue
		#New-Item -ItemType Directory -Path "$Destination\$foldername"
	} #IF
	
	try
	{
		Get-ChildItem -LiteralPath "$($folder.FullName)" -Filter $FaxFileExtension | Move-Item -Destination $Destination\$FolderName -ErrorAction Stop 
		
	} #TRY
	catch
	{
		if (Test-Path -LiteralPath $MoveErrorFile)
		{
			exit
		} #IF
		
		else
		{
			$error[0] | Out-File $MoveErrorFile -Append
			
			
			$params = @{
				
				From    = $MailFrom;
				To	    = $MailTo;
				Subject = "Fax Script Move Failed";
				Body    = $Error[0]
				SmtpServer = $SMTPServer
				
			} #PARAMS
			Send-MailMessage @params
			exit
			
		} #ELSE
		
	} #CATCH
} #FOREACH
