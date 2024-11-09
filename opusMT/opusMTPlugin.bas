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
	Return "opusMT"
End Sub

' must be available
public Sub Run(Tag As String, Params As Map) As ResumableSub
	Log("run"&Params)
	Select Tag
		Case "getParams"
			Dim paramsList As List
			paramsList.Initialize
			paramsList.Add("url")
			paramsList.Add("model")
			Return paramsList
		Case "translate"
			wait for (translate(Params.Get("source"),Params.Get("sourceLang"),Params.Get("targetLang"),Params.Get("preferencesMap"))) complete (result As String)
			Return result
		Case "getDefaultParamValues"
			Return CreateMap("url":"http://localhost:8500/MTRestService/Translate")
	End Select
	Return ""
End Sub

Private Sub convertLang(lang As String) As String 
	If lang.StartsWith("zh") Then
		Return "cmn"
	End If
	Return lang
End Sub


Sub translate(source As String, sourceLang As String, targetLang As String,preferencesMap As Map) As ResumableSub
	sourceLang = convertLang(sourceLang)
	targetLang = convertLang(targetLang)
	Dim target As String
	Dim su As StringUtils
	Dim job As HttpJob
	job.Initialize("job",Me)
	Dim model As String
	Dim url As String = "http://localhost:8500/MTRestService/Translate"
	Try
		url=getMap("opus",getMap("mt",preferencesMap)).GetDefault("url","http://localhost:8500/MTRestService/Translate")
		model=getMap("opus",getMap("mt",preferencesMap)).GetDefault("model","")
	Catch
		Log(LastException)
	End Try
	Dim params As String
	params="?input="&su.EncodeUrl(source,"UTF8")&"&srcLangCode="&sourceLang&"&trgLangCode="&targetLang&"&modelTag="&model
	job.Download(url&params)
	wait For (job) JobDone(job As HttpJob)
	If job.Success Then
		target = job.GetString
		Log(target)
	Else
		target=""
	End If
	job.Release
	Return target
End Sub


Sub getMap(key As String,parentmap As Map) As Map
	Return parentmap.Get(key)
End Sub
