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
	Return "pandaOCR"
End Sub

' must be available
public Sub Run(Tag As String, Params As Map) As ResumableSub
	Log("run"&Params)
	Select Tag
		Case "getParams"
			Dim paramsList As List
			paramsList.Initialize
			paramsList.Add("port")
			Return paramsList
		Case "getText"
			wait for (GetText(Params.Get("img"),Params.Get("lang"))) complete (result As String)
			Return result
		Case "getTextWithLocation"
			Return Array()
	End Select
	Return ""
End Sub


Sub GetText(img As B4XBitmap,lang As String) As ResumableSub
	Dim text As String
	Dim port As String = "5678"
	Try
		If File.Exists(File.DirApp,"preferences.conf") Then
			Dim preferencesMap As Map = readJsonAsMap(File.ReadString(File.DirApp,"preferences.conf"))
			port=getMap("panda",getMap("api",preferencesMap)).GetDefault("port",port)
		End If
	Catch
		Log(LastException)
	End Try


	saveImgToDisk(img)
	
	Dim job As HttpJob
	job.Initialize("",Me)
	Dim su As StringUtils
	Dim base64 As String=su.EncodeBase64(File.ReadBytes(File.DirApp,"image.jpg"))
	
	Dim params As Map
	params.Initialize
	params.Put("lang","auto")
	params.Put("type","1")
	params.Put("pic",base64)
	Dim jsonG As JSONGenerator
	jsonG.Initialize(params)
	job.PostString("http://127.0.0.1:"&port,jsonG.ToString)
	wait for (job) JobDone(job As HttpJob)
	If job.Success Then
		Try
			Log(job.GetString)
			Dim json As JSONParser
			json.Initialize(job.GetString)
			Dim Response As Map=json.NextObject
			text = Response.Get("text")
		Catch
			Log(LastException)
		End Try
	End If
	job.Release
	Return text
End Sub




Sub getMap(key As String,parentmap As Map) As Map
	Return parentmap.Get(key)
End Sub

Sub readJsonAsMap(s As String) As Map
	Dim json As JSONParser
	json.Initialize(s)
	Return json.NextObject
End Sub

Sub saveImgToDisk(img As B4XBitmap)
	Dim imgPath As String=File.Combine(File.DirApp,"image.jpg")
	Dim out As OutputStream=File.OpenOutput(imgPath,"",False)
	img.WriteToStream(out,100,"JPEG")
	out.Close
End Sub

