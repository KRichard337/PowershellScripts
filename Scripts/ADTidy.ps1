param(
	[string[]]$OU,

	[int]$LookBackDays = 180,

	[string]$Path,

	[switch]$CheckExchange
)

$date = (Get-Date).AddDays(-$LookBackDays)
$UserProps = @('name', 'samaccountname', 'title', 'department', 'lastlogondate', 'created', 'modified', 'userprincipalname')
$Expired = foreach ($item in $OU) {
	Get-ADUser -SearchBase $item -filter { (lastlogondate -notlike '*' -or lastlogondate -le $date) -and (enabled -eq $True) -and (whencreated -le $date) -and (modified -le $date) } -Properties $UserProps | Select-Object -Property $UserProps
}
$termdate = Get-Date -Format yyyyMMdd
$exportpath = "$Path$TermDate.csv" 
#Adding Field to input last login for email.
$expired | Add-Member -Name 'MailLogon' -MemberType NoteProperty -Value $null

if ($PSBoundParameters.ContainsKey('CheckExchange')) {
	$user = 'automationuser@opelousasgeneral.com'
	$file = 'C:\Scripts\cred\365.txt'
	$ExchangeAdmin = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $user, (Get-Content $file | ConvertTo-SecureString)
	Connect-ExchangeOnlineShell -Credential $ExchangeAdmin

	foreach ($mailbox in $expired) {
		$mailbox.MailLogon = Get-MailboxStatistics -Identity $mailbox.userprincipalname | Select-Object -ExpandProperty LastLogonTime
	}

	$expired = $expired | Where-Object { $_.MailLogon -eq $null -or $_.MailLogon -le $date }
}

if ($expired.count -eq 0) { exit }

foreach ($user in $expired) {
	Set-ADUser $user.samaccountname -Description "Disabled $termdate by ADTidy Script" -Enabled $false
	Get-ADUser $user.samaccountname | Move-ADObject -TargetPath 'ou=inactive users,dc=oghs,dc=local'
}
	
$expired | Sort-Object -Property Name | Export-Csv -Path $exportpath -NoTypeInformation
$emailbody = 'See attached File for list of disabled users'
Send-MailMessage -To identitymanagement@opelousasgeneral.com `
	-From alerts@opelousasgeneral.com `
	-Subject "$($disableusers.count) users disabled due to inactivity" `
	-Body " $emailbody "`
	-SmtpServer azureconnectsvr.oghs.local `
	-Attachments $exportpath
