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
			paramsList.Add("url")
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
	Dim job As HttpJob
	job.Initialize("",Me)
	job.PostBytes(getUrl,ImageToBytes(img))
	wait For (job) JobDone(job As HttpJob)
	If job.Success Then
		result=job.GetString
	Else
		result=job.ErrorMessage
	End If
	job.Release
	Return result
End Sub

private Sub ImageToBytes(Image As B4XBitmap) As Byte()
	Dim out As OutputStream
	out.InitializeToBytesArray(0)
	Image.WriteToStream(out, 100, "JPEG")
	out.Close
	Return out.ToBytesArray
End Sub

Sub getUrl As String
	Dim url As String = "http://127.0.0.1:8090/ocr"
	If File.Exists(File.DirApp,"preferences.conf") Then
		Try
			Dim preferencesMap As Map = readJsonAsMap(File.ReadString(File.DirApp,"preferences.conf"))
			url=getMap("google_drive",getMap("api",preferencesMap)).GetDefault("url",url)
		Catch
			Log(LastException)
		End Try
	End If
	Return url
End Sub

Sub getMap(key As String,parentmap As Map) As Map
	Return parentmap.Get(key)
End Sub

Sub readJsonAsMap(s As String) As Map
	Dim json As JSONParser
	json.Initialize(s)
	Return json.NextObject
End Sub
