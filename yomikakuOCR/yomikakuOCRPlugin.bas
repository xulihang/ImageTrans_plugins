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
	Return "YomikakuOCR"
End Sub

' must be available
public Sub Run(Tag As String, Params As Map) As ResumableSub
	Log("run"&Params)
	Select Tag
		Case "getParams"
			Dim paramsList As List
			paramsList.Initialize
			paramsList.Add("watch folder")
			paramsList.Add("timeout (seconds)")
			Return paramsList
		Case "getText"
			wait for (GetText(Params.Get("img"))) complete (result As String)
			Return result
		Case "getTextWithLocation"
			wait for (GetTextWithLocation(Params.Get("img"))) complete (regions As List)
			Return regions
		Case "getLangs"
			wait for (getLangs) complete (langs As Map)
			Return langs
	End Select
	Return ""
End Sub

Sub getLangs As ResumableSub
	Dim result As Map
	result.Initialize
	Dim names,codes As List
	names.Initialize
	codes.Initialize
    names.Add("Japanese")
	codes.Add("ja")
	result.Put("names",names)
	result.Put("codes",codes)
	Return result
End Sub

Sub GetText(img As B4XBitmap) As ResumableSub
	wait for (ocr(img)) complete (result As String)
	Return result
End Sub

Sub GetTextWithLocation(img As B4XBitmap) As ResumableSub
	Dim boxes As List
	boxes.Initialize
	Return boxes
End Sub


Sub ocr(img As B4XBitmap) As ResumableSub
	Dim result As String
	Dim folder As String="E:\\B4J\\test\\manga_partial"
	Dim timeout As Int=10
	Try
		If File.Exists(File.DirApp,"preferences.conf") Then
			Dim preferencesMap As Map = readJsonAsMap(File.ReadString(File.DirApp,"preferences.conf"))
			Dim settings As Map = getMap("Yomikaku",getMap("api",preferencesMap))
			If settings.ContainsKey("watch folder") Then
				folder = settings.Get("watch folder")
			End If
			If settings.ContainsKey("timeout (seconds)") Then
				timeout = settings.Get("timeout (seconds)")
			End If
		End If
	Catch
		Log(LastException)
	End Try
	Log("Watch folder: "&folder)
	If File.Exists(folder,"")=False And folder<>Null Then
		Log("folder doesn't exist")
		Return ""
	End If
    Dim timestamp As Long=DateTime.Now
	Dim tempPath As String = File.Combine(File.DirApp,timestamp&".jpg")
	Dim out As OutputStream
	out = File.OpenOutput(tempPath,"",False)
	img.WriteToStream(out,100,"JPEG")
	out.Flush
	out.Close
	File.Copy(tempPath,"",folder,timestamp&".jpg")
	File.Delete(tempPath,"")
	Dim waitedTimes As Int
	Do While File.Exists(folder,timestamp&".txt")=False
		Sleep(1000)
		waitedTimes=waitedTimes+1
		If waitedTimes>timeout Then
			Log("time out")
			Return ""
		End If
	Loop
	
	If File.Exists(folder,timestamp&".txt") Then
		Dim encoding As String
		encoding="shift-jis"
		Dim textReader As TextReader
		textReader.Initialize2(File.OpenInput(folder,timestamp&".txt"),encoding)
		result=textReader.ReadAll
		textReader.Close
	End If
	
	Return result
End Sub

Sub readJsonAsMap(s As String) As Map
	Dim json As JSONParser
	json.Initialize(s)
	Return json.NextObject
End Sub

Sub getMap(key As String,parentmap As Map) As Map
	Return parentmap.Get(key)
End Sub
