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
	Return "transliterationMT"
End Sub

' must be available
public Sub Run(Tag As String, Params As Map) As ResumableSub
	Log("run"&Params)
	Select Tag
		Case "getParams"
			Dim paramsList As List
			paramsList.Initialize
			paramsList.Add("key")
			paramsList.Add("sourceScript")
			paramsList.Add("use jakaroma (yes or no)")
			Return paramsList
		Case "translate"
			wait for (translate(Params.Get("source"),Params.Get("sourceLang"),Params.Get("preferencesMap"))) complete (result As String)
			Return result
		Case "getDefaultParamValues"
			Return CreateMap("sourceScript":"Jpan","use jakaroma (yes or no)":"yes")
	End Select
	Return ""
End Sub


Sub translate(source As String, sourceLang As String, preferencesMap As Map) As ResumableSub
	Dim useJakaroma As String =getMap("transliteration",getMap("api",preferencesMap)).GetDefault("use jakaroma (yes or no)","yes")
	If useJakaroma = "yes" Then
		wait for (Jakaroma(source)) Complete (result As String)
	Else
		wait for (azure(source,sourceLang,preferencesMap)) Complete (result As String)
	End If
	Return result
End Sub

Sub Jakaroma(source As String) As ResumableSub
	Dim target As String
	Dim sh As Shell
	sh.Initialize("sh","java",Array("-jar","jakaroma.jar",source))
	sh.Encoding=GetSystemProperty("file.encoding","UTF8")
	sh.WorkingDirectory=File.Combine(File.DirApp,"plugins")
	sh.Run(10000)
	wait for sh_ProcessCompleted (Success As Boolean, ExitCode As Int, StdOut As String, StdErr As String)
	If Success And ExitCode = 0 Then
		Log(StdOut)
		target = StdOut
	End If
	Return target
End Sub

Sub azure(source As String,sourceLang As String,preferencesMap As Map) As ResumableSub
	Dim target,key As String
	key=getMap("transliteration",getMap("api",preferencesMap)).Get("key")
	If key="" Then
		Return ""
	End If
	Dim sourceScript As String = getMap("transliteration",getMap("api",preferencesMap)).GetDefault("sourceScript","Jpan")
	Dim sourceList As List
	sourceList.Initialize
	sourceList.Add(CreateMap("Text":source))
	Dim jsong As JSONGenerator
	jsong.Initialize2(sourceList)
	source=jsong.ToString
	Dim job As HttpJob
	job.Initialize("job",Me)
	Dim params As String
	params="&language="&sourceLang&"&fromScript="&sourceScript&"&toScript=Latn"
	Log(params)
	job.PostString("https://api.cognitive.microsofttranslator.com/transliterate?api-version=3.0"&params,source)
	job.GetRequest.SetContentType("application/json")
	job.GetRequest.SetHeader("Ocp-Apim-Subscription-Key",key)
	job.GetRequest.SetHeader("X-ClientTraceId",UUID)
	job.GetRequest.SetHeader("Content-Type","application/json")
	job.GetRequest.SetHeader("Accept","application/json")
	wait For (job) JobDone(job As HttpJob)
	If job.Success Then
		Try
			Dim json As JSONParser
			json.Initialize(job.GetString)
			Dim result As List
			result=json.NextArray
			Dim innerMap As Map
			innerMap=result.Get(0)
			target=innerMap.Get("text")
		Catch
			target=""
			Log(LastException)
		End Try
	Else
		target=""
	End If
	job.Release
	Return target
End Sub

Sub getMap(key As String,parentmap As Map) As Map
	Return parentmap.Get(key)
End Sub

Sub UUID As String
	Dim jo As JavaObject
	Return jo.InitializeStatic("java.util.UUID").RunMethod("randomUUID", Null)
End Sub
