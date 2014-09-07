Option Explicit
On Error Resume Next

Const cdoBasic = 1 'basic (clear-text) authentication
Dim sBackupString, sToAddress, sFromAddress, oShell, oFso, sNagiosFail, sNagiosOK

sToAddress="spam@example.com"
sFromAddress="host.example.com"
sBackupString = "IISConfigurationBackup_" & DateString()
sNagiosFail = "F:\Scripts\IIS\Config-Backup\sendfail-iis-config-nagios.bat"
sNagiosOK = "F:\Scripts\IIS\Config-Backup\sendok-iis-config-nagios.bat"

Set oShell = WScript.CreateObject("WScript.Shell")

' IIS Configuration Backup via appcmd.exe
oShell.Run "C:\Windows\system32\inetsrv\appcmd.exe add backup """ & sBackupString & """",0,True
If Err.Number <> 0 Then
	oShell.Run sNagiosFail
  Err.Clear
Else
	oShell.Run sNagiosOK
End If

Set oFso = WScript.CreateObject("Scripting.FileSystemObject")

oFso.CopyFolder "C:\Windows\System32\inetsrv\backup\" & sBackupString, "F:\inetpub\backup\", True
If Err.Number <> 0 Then
	oShell.Run sNagiosFail 
  Err.Clear
Else
	oShell.Run sNagiosOK
End If

Set oShell = nothing
Set ofso = nothing

WScript.Quit

'********************************
'Datestring

Function DateString()
	Dim sTemp
	'year
	DateString = Year(Date)
	'month
	sTemp = Month(Date)
	If Int(sTemp) < 10 Then sTemp = "0" & sTemp
	DateString = DateString & sTemp
	'day
	sTemp = Day(Date)
	If Int(sTemp) < 10 Then sTemp = "0" & sTemp
	DateString= DateString & sTemp
End Function

' ****************************************
' sendMail(sSubject,sBody) procedure
' ****************************************
Sub sendMail(sToAddress,sSubject,sBody)
	Dim objEmail

	Set objEmail = CreateObject("CDO.Message")
	objEmail.From = sFromAddress
	objEmail.To = sToAddress
	objEmail.Subject = sSubject
	objEmail.Textbody = sBody

	objEmail.Configuration.Fields.Item _
		("http://schemas.microsoft.com/cdo/configuration/sendusing") = 2 
	objEmail.Configuration.Fields.Item _
		("http://schemas.microsoft.com/cdo/configuration/smtpserver") = "%CHANGE_ME%"
	objEmail.Configuration.Fields.Item _
		("http://schemas.microsoft.com/cdo/configuration/smtpauthenticate") = cdoBasic
	objEmail.Configuration.Fields.Item _
		("http://schemas.microsoft.com/cdo/configuration/sendusername") = "%CHANGE_ME%"
	objEmail.Configuration.Fields.Item _
		("http://schemas.microsoft.com/cdo/configuration/sendpassword") = "%CHANGE_ME%"
	objEmail.Configuration.Fields.Item _
		("http://schemas.microsoft.com/cdo/configuration/smtpserverport") = 25
	objEmail.Configuration.Fields.Item _
		("http://schemas.microsoft.com/cdo/configuration/smtpusessl") = TRUE
	objEmail.Configuration.Fields.Item _
		("http://schemas.microsoft.com/cdo/configuration/smtpconnectiontimeout") = 60

	objEmail.Configuration.Fields.Update

	objEmail.Send

	Set objEmail = Nothing
End Sub
