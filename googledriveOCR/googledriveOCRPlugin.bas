B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=4.2
@EndOfDesignText@
Sub Class_Globals
	Private fx As JFX
End Sub

'Initializes the object. You can NOT add parameters to this method!
Public Sub Initialize() As String
	Log("Initializing plugin " & GetNiceName)
	' Here return a key to prevent running unauthorized plugins
	Return "MyKey"
End Sub

' must be available
public Sub GetNiceName() As String
	Return "google_driveOCR"
End Sub

' must be available
public Sub Run(Tag As String, Params As Map) As ResumableSub
	Log("run"&Params)
	Select Tag
		Case "getParams"
			Dim paramsList As List
			paramsList.Initialize
			paramsList.Add("placeholder")
			Return paramsList
		Case "getText"
			wait for (GetText(Params.Get("img"))) complete (result As String)
			Return result
		Case "getTextWithLocation"
			Dim list1 As List
			list1.Initialize
			Return list1
		Case "getLangs"
			Return getLangs
	End Select
	Return ""
End Sub

Sub getLangs As Map
	Dim result As Map
	result.Initialize
	Dim names,codes As List
	names.Initialize
	codes.Initialize
    names.Add("Auto detect")
	codes.Add("auto")
	result.Put("names",names)
	result.Put("codes",codes)
	Return result
End Sub

Sub GetText(img As B4XBitmap) As ResumableSub
	Dim result As String
	Dim out As OutputStream
	out=File.OpenOutput(File.DirApp,"image.jpg",False)
	img.WriteToStream(out,"100","JPEG")
	out.Close
	If File.Exists(File.DirApp,"out.txt") Then
		File.Delete(File.DirApp,"out.txt")	
	End If
	Dim sh As Shell
	sh.Initialize("sh","java",Array("-jar","google_drive_ocr.jar"))
	sh.WorkingDirectory=File.DirApp
	sh.Run(-1)
	wait for sh_ProcessCompleted (Success As Boolean, ExitCode As Int, StdOut As String, StdErr As String)
	If Success And ExitCode=0 Then
		If File.Exists(File.DirApp,"out.txt") Then
			result = File.ReadString(File.DirApp,"out.txt")
		End If
	End If
	Return result.Trim
End Sub
