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
	Return "STTNInpaint"
End Sub

' must be available
public Sub Run(Tag As String, Params As Map) As ResumableSub
	Log("run"&Params)
	Select Tag
		Case "getParams"
			Dim paramsList As List
			paramsList.Initialize
			paramsList.Add("url")
			Return paramsList
		Case "inpaint"
			wait for (inpaint(Params.Get("origin"),Params.Get("mask"),Params.GetDefault("settings",getDefaultSettings))) complete (result As B4XBitmap)
			Return result
		Case "inpaintFolder"
			wait for (inpaintFolder(Params.Get("folder"),Params.Get("mask"),Params.GetDefault("settings",getDefaultSettings))) complete (done As Boolean)
			Return result
		Case "supportFolder"
			Return True
		Case "getDefaultParamValues"
			Return getDefaultSettings
		Case "getSetupParams"
			Dim o As Object = CreateMap("readme":"https://github.com/xulihang/ImageTrans_plugins/tree/master/STTNInpaint")
			Return o
		Case "getIsInstalledOrRunning"
			Wait For (CheckIsRunning) complete (running As Boolean)
			Return running
	End Select
	Return ""
End Sub

private Sub getMap(key As String,parentmap As Map) As Map
	Return parentmap.Get(key)
End Sub

private Sub readJsonAsMap(s As String) As Map
	Dim json As JSONParser
	json.Initialize(s)
	Return json.NextObject
End Sub

private Sub getUrl As String
	Dim url As String = "http://127.0.0.1:8189/"
	If File.Exists(File.DirApp,"preferences.conf") Then
		Try
			Dim preferencesMap As Map = readJsonAsMap(File.ReadString(File.DirApp,"preferences.conf"))
			url=getMap("STTNInpaint",getMap("api",preferencesMap)).GetDefault("url",url)
		Catch
			Log(LastException)
		End Try
	End If
	Return url
End Sub

Private Sub CheckIsRunning As ResumableSub
	Dim result As Boolean = True
	Dim job As HttpJob
	job.Initialize("job",Me)
	job.Head(getUrl)
	job.GetRequest.Timeout = 500
	Wait For (job) JobDone(job As HttpJob)
	If job.Success = False Then
		If job.Response.StatusCode <> 404 Then
			result = False
		End If
	End If
	job.Release
	Return result
End Sub

Private Sub getDefaultSettings As Map
	Return CreateMap("url":"http://127.0.0.1:8189/")
End Sub


Sub inpaint(origin As B4XBitmap,mask As B4XBitmap,settings As Map) As ResumableSub
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
	Dim url As String = settings.GetDefault("url","http://127.0.0.1:8189/")&"gettxtremoved"
	job.PostMultipart(url,Null, Array(originFd,maskFd))
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

Sub inpaintFolder(folder As String,mask As B4XBitmap,settings As Map) As ResumableSub
	Dim out As OutputStream
	out=File.OpenOutput(File.DirApp,"mask.png",False)
	mask.WriteToStream(out,"100","PNG")
	out.Close
	
	Dim job As HttpJob
	job.Initialize("",Me)
	
	Dim maskFd As MultipartFileData
	maskFd.Initialize
	maskFd.KeyName = "mask"
	maskFd.Dir = File.DirApp
	maskFd.FileName = "mask.png"
	maskFd.ContentType = "image/png"
	Dim url As String = settings.GetDefault("url","http://127.0.0.1:8189/")&"gettxtremoved_folder"
	job.PostMultipart(url,CreateMap("folder":folder), Array(maskFd))
	job.GetRequest.Timeout=300*1000
	Wait For (job) JobDone(job As HttpJob)
	If job.Success Then
		Return True
	End If
	job.Release
	Return False
End Sub 

