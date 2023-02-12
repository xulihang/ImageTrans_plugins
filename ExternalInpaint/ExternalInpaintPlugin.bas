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
	Return "ExternalInpaint"
End Sub

' must be available
public Sub Run(Tag As String, Params As Map) As ResumableSub
	Log("run"&Params)
	Select Tag
		Case "inpaint"
			wait for (inpaint(Params.Get("origin"),Params.Get("mask"))) complete (result As B4XBitmap)
			Return result
	End Select
	Return ""
End Sub

Sub inpaint(origin As B4XBitmap,mask As B4XBitmap) As ResumableSub
	Dim out As OutputStream
	out=File.OpenOutput(File.DirApp,"origin.jpg",False)
	origin.WriteToStream(out,"100","JPEG")
	out.Close
	Dim out As OutputStream
	out=File.OpenOutput(File.DirApp,"mask.png",False)
	mask.WriteToStream(out,"100","PNG")
	out.Close
	
	Dim job As HttpJob
	job.Initialize("",Me)
	
	Dim originFd As MultipartFileData
	originFd.Initialize
	originFd.KeyName = "origin"
	originFd.Dir = File.DirApp
	originFd.FileName = "origin.jpg"
	originFd.ContentType = "image/jpg"
	
	Dim maskFd As MultipartFileData
	maskFd.Initialize
	maskFd.KeyName = "mask"
	maskFd.Dir = File.DirApp
	maskFd.FileName = "mask.png"
	maskFd.ContentType = "image/png"
	
	job.PostMultipart("http://127.0.0.1:8080/gettxtremoved",Null, Array(originFd,maskFd))
	job.GetRequest.Timeout=240*1000
	Wait For (job) JobDone(job As HttpJob)
	If job.Success Then
		Try
			Dim result As B4XBitmap=job.GetBitmap
			Return result
		Catch
			Log(LastException)
		End Try
	End If
	job.Release
	Return origin
End Sub 
