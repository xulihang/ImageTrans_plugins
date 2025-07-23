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
	Return "deeplMT"
End Sub

' must be available
public Sub Run(Tag As String, Params As Map) As ResumableSub
	Select Tag
		Case "getParams"
			Dim paramsList As List
			paramsList.Initialize
			paramsList.Add("key")
			paramsList.Add("freemode (yes or no)")
			Return paramsList
		Case "translate"
			Dim sourceList As List
			sourceList.Initialize
			sourceList.Add(Params.Get("source"))
			wait for (translate(sourceList,Params.Get("sourceLang"),Params.Get("targetLang"),Params.Get("preferencesMap"))) complete (targetList As List)
			If targetList.Size>0 Then
				Return targetList.Get(0)
			Else
				Return ""
			End If
		Case "batchtranslate"
			wait for (translate(Params.Get("source"),Params.Get("sourceLang"),Params.Get("targetLang"),Params.Get("preferencesMap"))) complete (targetList As List)
			Return targetList
		Case "supportBatchTranslation"
			Return True
		Case "getMaximumSegments"
			Return 50
		Case "getDefaultParamValues"
			Return CreateMap("freemode (yes or no)":"yes")
	End Select
	Return ""
End Sub


Sub ConvertLang(lang As String) As String
	Return lang.ToUpperCase
End Sub

Sub translate(sourceList As List,sourceLang As String,targetLang As String,preferencesMap As Map) As ResumableSub
	sourceLang=ConvertLang(sourceLang)
	targetLang=ConvertLang(targetLang)
	
	Dim targetList As List
	targetList.Initialize

	Dim job As HttpJob
	job.Initialize("job",Me)

	Dim freemode As String
	Dim key As String
	Try
		freemode=getMap("deepl",getMap("mt",preferencesMap)).GetDefault("freemode (yes or no)","yes")
		key=getMap("deepl",getMap("mt",preferencesMap)).GetDefault("key","")
	Catch
		Log(LastException)
	End Try

	If key="" Then
		Return ""
	End If

	Dim url As String
	If freemode="yes" Then
		url="https://api-free.deepl.com/v2/translate"
	Else
		url="https://api.deepl.com/v2/translate "
	End If
	
	
    Dim requestBody As Map
	requestBody.Initialize
	requestBody.Put("text",sourceList)
	requestBody.Put("source_lang",sourceLang)
	requestBody.Put("target_lang",targetLang)
	Dim jsonG As JSONGenerator
	jsonG.Initialize(requestBody)
	Dim data As String = jsonG.ToString
	Log(data)
	
	job.PostString(url,data)
	job.GetRequest.SetContentType("application/json")
	job.GetRequest.SetHeader("Authorization"," DeepL-Auth-Key "&key)
	wait For (job) JobDone(job As HttpJob)
	If job.Success Then
		Try
			Log(job.GetString)
			Dim json As JSONParser
			json.Initialize(job.GetString)
			Dim translations As List = json.NextObject.Get("translations")
			For Each trans As Map In translations
				targetList.Add(trans.Get("text"))
			Next
		Catch
			Log(LastException)
		End Try
	Else
		Log(job.ErrorMessage)
	End If
	job.Release
	Return targetList
End Sub


Sub getMap(key As String,parentmap As Map) As Map
	Return parentmap.Get(key)
End Sub
