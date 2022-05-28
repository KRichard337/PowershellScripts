param(
	[string[]]$OU,

	[string]$DisabledUsersOU,

	[int]$LookBackDays = 180,

	[string]$Path,

	[switch]$CheckExchange,

	[string]$ToEmail,

	[string]$FromEmail,

	[string]$SMTPServer
)

$date = (Get-Date).AddDays(-$LookBackDays)
$UserProps = @('name', 'samaccountname', 'title', 'department', 'lastlogondate', 'created', 'modified', 'userprincipalname')
$Expired = foreach ($item in $OU) {
	Get-ADUser -SearchBase $item -filter { (lastlogondate -notlike '*' -or lastlogondate -le $date) -and (enabled -eq $True) -and (whencreated -le $date) -and (modified -le $date) } -Properties $UserProps | Select-Object -Property $UserProps
}
$TermDate = Get-Date -Format yyyyMMdd
$exportpath = "$Path$TermDate.csv" 

if ($PSBoundParameters.ContainsKey('CheckExchange')) {
	$user = #ExchangeAdminAccontName
	$file = #PathToCredentialFile
	$ExchangeAdmin = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $user, (Get-Content $file | ConvertTo-SecureString)
	Connect-ExchangeOnlineShell -Credential $ExchangeAdmin
	#Adding Field to input last login for email.
	$expired | Add-Member -Name 'MailLogon' -MemberType NoteProperty -Value $null

	foreach ($mailbox in $expired) {
		$mailbox.MailLogon = Get-MailboxStatistics -Identity $mailbox.userprincipalname | Select-Object -ExpandProperty LastLogonTime
	}

	$expired = $expired | Where-Object { $_.MailLogon -eq $null -or $_.MailLogon -le $date }
}

if ($expired.count -eq 0) { exit }

foreach ($user in $expired) {
	Set-ADUser $user.samaccountname -Description "Disabled $TermDate by ADTidy Script" -Enabled $false

	if ($PSBoundParameters.ContainsKey('DisabledUsersOU')) {
		Get-ADUser $user.samaccountname | Move-ADObject -TargetPath $DisabledUsersOU
	}
}
	
$expired | Sort-Object -Property Name | Export-Csv -Path $exportpath -NoTypeInformation
$emailbody = 'See attached File for list of disabled users'
Send-MailMessage -To $ToEmail `
	-From $FromEmail `
	-Subject "$($disableusers.count) users disabled due to inactivity" `
	-Body " $emailbody "`
	-SmtpServer $SMTPServer `
	-Attachments $exportpath
