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
	Return "macMTMT"
End Sub

' must be available
public Sub Run(Tag As String, Params As Map) As ResumableSub
	Select Tag
		Case "getParams"
			Dim paramsList As List
			paramsList.Initialize
			paramsList.Add("url")
			Return paramsList
		Case "translate"
			wait for (translate(Params.Get("source"),Params.Get("sourceLang"),Params.Get("targetLang"),Params.Get("preferencesMap"))) complete (result As String)
			Return result
		Case "batchtranslate"
			wait for (batchTranslate(Params.Get("source"),Params.Get("sourceLang"),Params.Get("targetLang"),Params.Get("preferencesMap"))) complete (targetList As List)
			Return targetList
		Case "getSetupParams"
			Dim o As Object = CreateMap("readme":"https://github.com/xulihang/ImageTrans_plugins/tree/master/macMT")
			Return o
		Case "getIsInstalledOrRunning"
			Wait For (CheckIsRunning) complete (running As Boolean)
			Return running
		Case "supportBatchTranslation"
			Return True
		Case "getDefaultParamValues"
			Return CreateMap("url":"http://localhost:5308/translate")
	End Select
	Return ""
End Sub

private Sub CheckIsRunning As ResumableSub
	Dim result As Boolean = True
	Dim url As String = getUrl
	Dim job As HttpJob
	job.Initialize("job",Me)
	job.Download(url)
	job.GetRequest.Timeout = 500
	Wait For (job) JobDone(job As HttpJob)
	If job.Success = False Then
		If job.Response.StatusCode <> 404 And job.Response.StatusCode <> 405 Then
			result = False
		End If
	End If
	job.Release
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

Sub getUrl As String
	Dim url As String = "http://localhost:5308/translate"
	If File.Exists(File.DirApp,"preferences.conf") Then
		Try
			Dim preferencesMap As Map = readJsonAsMap(File.ReadString(File.DirApp,"preferences.conf"))
			url=getMap("macMT",getMap("api",preferencesMap)).GetDefault("url",url)
		Catch
			Log(LastException)
		End Try
	End If
	Return url
End Sub


Sub batchTranslate(sourceList As List,sourceLang As String,targetLang As String,preferencesMap As Map) As ResumableSub
	Dim targetList As List
	targetList.Initialize
	Dim sb As StringBuilder
	sb.Initialize
	For Each source As String In sourceList
		sb.Append(source.Replace(CRLF,"<br/>"))
		sb.Append(CRLF)
	Next
	wait for (translate(sb.ToString,sourceLang,targetLang,preferencesMap)) Complete (target As String)
	Dim targetList As List
	targetList.Initialize
	For Each result As String In Regex.Split(CRLF,target)
		result = result.Replace("<br/>",CRLF)
		targetList.Add(result)
	Next
	Return targetList
End Sub

Sub translate(source As String,sourceLang As String,targetLang As String,preferencesMap As Map) As ResumableSub
	Dim target As String
	Dim job As HttpJob
	job.Initialize("job",Me)
	Dim url As String = "http://localhost:5308/translate"

	Try
		url=getMap("macMT",getMap("api",preferencesMap)).GetDefault("url",url)
	Catch
		Log(LastException)
	End Try
	
	Dim map1 As Map
	map1.Initialize
	map1.Put("text",source)
	map1.Put("source_language",sourceLang)
	map1.Put("target_language",targetLang)
	Dim jsonG As JSONGenerator
	jsonG.Initialize(map1)
	job.PostString(url,jsonG.ToString)
	job.GetRequest.SetContentType("application/json")
	wait For (job) JobDone(job As HttpJob)
	If job.Success Then
		Try
			Dim result As Map
			Dim json As JSONParser
			json.Initialize(job.GetString)
			result=json.NextObject
			target=result.Get("translated_text")
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

