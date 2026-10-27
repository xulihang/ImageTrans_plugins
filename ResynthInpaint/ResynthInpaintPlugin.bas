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
	Return "ResynthInpaint"
End Sub

' must be available
public Sub Run(Tag As String, Params As Map) As ResumableSub
	Log("run"&Params)
	Select Tag
		Case "getParams"
			Dim paramsList As List
			paramsList.Initialize
			Return paramsList
		Case "inpaint"
			wait for (inpaint(Params.Get("origin"),Params.Get("mask"))) complete (result As B4XBitmap)
			Return result
	End Select
	Return ""
End Sub

Sub inpaint(origin As B4XBitmap,mask As B4XBitmap) As ResumableSub
	
	File.Delete(File.DirApp,"origin.png")
	File.Delete(File.DirApp,"mask.png")
	File.Delete(File.DirApp,"out.png")
	
	Dim out As OutputStream
	out=File.OpenOutput(File.DirApp,"origin.png",False)
	origin.WriteToStream(out,"100","PNG")
	out.Close
	Dim out As OutputStream
	out=File.OpenOutput(File.DirApp,"mask.png",False)
	mask.WriteToStream(out,"100","PNG")
	out.Close
	
	Dim javaPath As String = Utils.GetJavaPath
	Dim sh As Shell
	sh.Initialize("sh",javaPath,Array("-jar","jars/resynth.jar","origin.png","mask.png","out.png"))
	sh.WorkingDirectory=File.DirApp
	sh.Run(-1)
	wait for sh_ProcessCompleted (Success As Boolean, ExitCode As Int, StdOut As String, StdErr As String)
	If File.Exists(File.DirApp,"out.png") Then
		Dim img As B4XBitmap = fx.LoadImage(File.DirApp,"out.png")
		Return img
	End If
	Return origin
End Sub 
