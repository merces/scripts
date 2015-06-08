'
'	getinfo.vbs - Get useful info from Windows machines in a domain
'
'	Copyright (C) 2010 - 2011 Fernando Mercês (fernando@mentebinaria.com.br)
'
'	This program is free software: you can redistribute it and/or modify
'	it under the terms of the GNU General Public License as published by
'	the Free Software Foundation, either version 3 of the License, or
'	(at your option) any later version.
'
'	This program is distributed in the hope that it will be useful,
'	but WITHOUT ANY WARRANTY; without even the implied warranty of
'	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
'	GNU General Public License for more details.
'
'	You should have received a copy of the GNU General Public License
'	along with this program.  If not, see <http://www.gnu.org/licenses/>.
'
'	Created at 20/7/2010
'	Updated at 1/6/2011
'	Version 0.5
'
' //TODO handle more than one hard disk and microprocessor

Const eu = "getinfo v0.5"

' Set to TRUE for domain mode or to FALSE for stand-alone mode
Const domainMode = true

' Set the output filename
outputFileName = "getinfo_v0.5_maquinas.txt"

' If in domain mode, you need to set the following constants
Const domain = "contoso.msft"
Const ldapDomain = "dc=contoso,dc=msft"

' If in stand-alone mode, set the following parameter
machineName = "meupc"

Function removeDupSpaces(s)
	s = Trim(s)
	s = Replace(s, "   ", "")
	s = Replace(s, "  ", " ")

	removeDupSpaces = s
End Function

' Functon to ping a machine (by name) to check availability
Function isOnline(name)
	Set objWMIService = GetObject("winmgmts:" _
	    & "{impersonationLevel=impersonate}!\\.\root\cimv2")
	Set colPingedComputers = objWMIService.ExecQuery _
	    ("Select * from Win32_PingStatus Where Address = '" & name & "'")
	
	For Each objComputer in colPingedComputers
	    If objComputer.StatusCode = 0 Then
	        isOnline = True
	    Else
	        isOnline = False
	   End If
	Next
End Function

' Domain mode needs query AD directly to get domain members computers
If domainMode Then
	Const ADS_SCOPE_SUBTREE = 2
	
	Set objConnection = CreateObject("ADODB.Connection")
	Set objCommand =   CreateObject("ADODB.Command")
	objConnection.Provider = "ADsDSOObject"
	objConnection.Open "Active Directory Provider"
	
	Set objCOmmand.ActiveConnection = objConnection
	objCommand.CommandText = _
	    "Select Name, Location from 'LDAP://" & ldapDomain _
	        & "' Where objectClass='computer'"  
	objCommand.Properties("Page Size") = 1000
	objCommand.Properties("Searchscope") = ADS_SCOPE_SUBTREE 
	Set objRecordSet = objCommand.Execute
	objRecordSet.MoveFirst
	max = objRecordSet.RecordCount
Else
	' Stand-alone mode, run only once
	max = 1
End If

' Collection to store computer entries
Set entries = CreateObject("System.Collections.ArrayList")

For i=1 To max
	
	If domainMode Then
		machineName = objRecordSet.Fields("Name").Value & "." & domain
	End If
	
	Dim proc, mem, mobo, so, fqdn
	
	If isOnline(machineName) Then
		Set objWMIService = GetObject("winmgmts:\\" & LCase(machineName) & "\root\CIMV2")
		
		' Query Operational System
		Set colOSes = objWMIService.ExecQuery("Select * from Win32_OperatingSystem")
		Set dtmConvertedDate = CreateObject("WbemScripting.SWbemDateTime")
		For Each objOS in colOSes
			dtmConvertedDate.Value = objOS.InstallDate
		    dtmInstallDate = dtmConvertedDate.Day & "/" & dtmConvertedDate.Month & "/" & dtmConvertedDate.Year
			nome = objOS.CSName
			so = objOS.Caption & " SP" & objOS.ServicePackMajorVersion _
			& " (instalado em " & dtmInstallDate & ")"
		Next
		
		' Query microprocessor
		Set colProcessors = objWMIService.ExecQuery("SELECT * FROM Win32_Processor")
		For Each objProcessor in colProcessors
			proc = objProcessor.Name
		Next
		
		' Query system memory (RAM)
		Set colCSItems = objWMIService.ExecQuery("SELECT * FROM Win32_ComputerSystem")
		For Each objCSItem In colCSItems
			If objCSItem.TotalPhysicalMemory > 1000000000 Then
				mem = Round(objCSItem.TotalPhysicalMemory / 2^30, 1) & " GB"
			Else
				mem = Round(objCSItem.TotalPhysicalMemory / 2^20, 0) & " MB"
			End If
			' FQDN and logged username are here too =P
			fqdn = nome & "." & objCSItem.Domain
			username = Mid(objCSItem.UserName, InStr(objCSItem.UserName, "\") + 1)
		Next
		
		' Query motherboard
		Set colItems = objWMIService.ExecQuery("Select * from Win32_BaseBoard")
		For Each objItem in colItems
			mobo = Left(objItem.Manufacturer, InStr(objItem.Manufacturer, " ")) & objItem.Product
		Next
		
		' Query monitor (not so useful)
		Set colMon = objWMIService.ExecQuery("Select * from Win32_DesktopMonitor")
		For Each objItem in colMon
			monitor = objItem.MonitorType
		Next


		' Query monitor (not so useful)
		Set col = objWMIService.ExecQuery("SELECT * FROM Win32_DiskDrive")
		For Each obj in col
			hd = Round(obj.Size / 2^30, 1) & " GB"
		Next
		
		' Add strings to entries collection
		entries.Add _
		  "Nome: " & fqdn & " (" & username & ")" & vbCrLf _
		& "SO: " & so & vbCrLf _
		& "Processador: " & proc & vbCrLf _
		& "Placa-mãe: " & mobo & vbCrLf _
		& "Memória: " & mem & vbCrLf _
		& "HD: " & hd & vbCrLf _
		& "Monitor: " & monitor

	End If
	
	If domainMode Then
		objRecordSet.MoveNext
	End If
	
Next

' Sort entries
entries.Sort()

' Write text file
Set objFSO = CreateObject("Scripting.FileSystemObject")

If Not objFSO.FileExists(outputFileName) Then
	Set objFile = objFSO.CreateTextFile(outputFileName, True)
Else
	Set objFile = objFSO.OpenTextFile(outputFileName, 2)
End If

For Each entry In entries
	objFile.WriteLine removeDupSpaces(entry) & vbCrLf
Next

objFile.Close

MsgBox "Arquivo " & outputFileName & " escrito com sucesso. Você o visualizará agora.", _
 vbOKOnly + vbInformation, eu

Set WshShell = WScript.CreateObject("WScript.Shell")
WshShell.Run (outputFileName)

WScript.Quit 0