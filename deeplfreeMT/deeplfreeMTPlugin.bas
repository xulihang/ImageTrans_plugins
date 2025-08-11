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
	Return "deeplfreeMT"
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
		Case "supportBatchTranslation"
			Return False
		Case "getDefaultParamValues"
			Return CreateMap("url":"http://service.basiccat.org:8080/")
	End Select
	Return ""
End Sub


Sub ConvertLang(lang As String) As String
	Return lang.ToUpperCase
End Sub

Sub translate(source As String,sourceLang As String,targetLang As String,preferencesMap As Map) As ResumableSub
	sourceLang=ConvertLang(sourceLang)
	targetLang=ConvertLang(targetLang)
	
	Dim target As String
	Dim job As HttpJob
	job.Initialize("job",Me)
	Dim url As String = "http://service.basiccat.org:8080/"
	Try
		url=getMap("deeplfree",getMap("mt",preferencesMap)).GetDefault("url","http://service.basiccat.org:8080/")
	Catch
		Log(LastException)
	End Try
	
	'{"text": "have a try", "source_lang": "auto", "target_lang": "ZH"}
	Dim params As Map
	params.Initialize
	params.Put("text",source)
	params.Put("source_lang",sourceLang)
	params.Put("target_lang",targetLang)
	
	Dim jsonG As JSONGenerator
	jsonG.Initialize(params)
	
	job.PostString(url&"translate",jsonG.ToString)
	job.GetRequest.SetContentType("application/json")
	wait For (job) JobDone(job As HttpJob)
	If job.Success Then
		Try
			Log(job.GetString)
			Dim json As JSONParser
			json.Initialize(job.GetString)
			target = json.NextObject.Get("data")
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
