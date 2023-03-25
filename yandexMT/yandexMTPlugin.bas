B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=4.2
@EndOfDesignText@
Sub Class_Globals
	Private fx As JFX
	Private IAMTokenRetrivedTimestamp As Long
	Private IAMToken As String
End Sub

'Initializes the object. You can NOT add parameters to this method!
Public Sub Initialize() As String
	Log("Initializing plugin " & GetNiceName)
	' Here return a key to prevent running unauthorized plugins
	Return "MyKey"
End Sub

' must be available
public Sub GetNiceName() As String
	Return "yandexMT"
End Sub

' must be available
public Sub Run(Tag As String, Params As Map) As ResumableSub
	'Log("run"&Params)
	Select Tag
		Case "getParams"
			Dim paramsList As List
			paramsList.Initialize
			paramsList.Add("OAuth Token")
			paramsList.Add("Folder ID")
			Return paramsList
		Case "batchtranslate"
			wait for (batchTranslate(Params.Get("source"),Params.Get("sourceLang"),Params.Get("targetLang"),Params.Get("preferencesMap"))) complete (targetList As List)
			Return targetList
		Case "translate"
			wait for (translate(Params.Get("source"),Params.Get("sourceLang"),Params.Get("targetLang"),Params.Get("preferencesMap"))) complete (result As String)
			Return result
		Case "supportBatchTranslation"
			Return True
	End Select
	Return ""
End Sub


private Sub batchTranslate(sourceList As List, sourceLang As String, targetLang As String,preferencesMap As Map) As ResumableSub
	Dim targetList As List
	targetList.Initialize
	Dim job As HttpJob
	job.Initialize("job",Me)
	If IAMTokenValid = False Then
		Dim OAuthToken As String = getMap("yandex",getMap("mt",preferencesMap)).Get("OAuth Token")
		wait for (getIAMToken(OAuthToken)) Complete (success As Object)
	End If
	Dim FolderID As String = getMap("yandex",getMap("mt",preferencesMap)).Get("Folder ID")
	Dim jsonObject As Map
	jsonObject.Initialize
	jsonObject.Put("folderId",FolderID)
	jsonObject.Put("targetLanguageCode",targetLang)
	jsonObject.Put("texts",sourceList)
	Dim json As JSONGenerator
	json.Initialize(jsonObject)
	Dim URL As String
	URL="https://translate.api.cloud.yandex.net/translate/v2/translate"
	job.PostString(URL,json.ToString)
	job.GetRequest.SetContentType("application/json")
	job.GetRequest.SetHeader("Authorization","Bearer "&IAMToken)
	wait For (job) JobDone(job As HttpJob)
	If job.Success Then
		Log(job.GetString)
		Dim parser As JSONParser
		parser.Initialize(job.GetString)
		Dim translations As List = parser.NextObject.Get("translations")
		For Each translation As Map In translations 
			targetList.Add(translation.Get("text"))
		Next
	Else
		Log(job.ErrorMessage)
	End If
	job.Release
	Return targetList
End Sub

private Sub translate(source As String, sourceLang As String, targetLang As String,preferencesMap As Map) As ResumableSub
	wait for (batchTranslate(Array As String(source),sourceLang,targetLang,preferencesMap)) Complete (targetList As List)
	If targetList.Size>0 Then
		Return targetList.Get(0)
	Else
		Return ""
	End If
End Sub

Private Sub IAMTokenValid As Boolean
	If IAMToken <> "" Then
		If DateTime.Now - IAMTokenRetrivedTimestamp < 12*60*60*1000 Then
			Return True
		End If
	End If
	Return False
End Sub

private Sub getIAMToken(OAuthToken As String) As ResumableSub
	'curl -d "{\"yandexPassportOauthToken\":\"<OAuth-token>\"}" "https://iam.api.cloud.yandex.net/iam/v1/tokens"
	Dim job As HttpJob
	job.Initialize("job",Me)
	Dim json As JSONGenerator
	json.Initialize(CreateMap("yandexPassportOauthToken":OAuthToken))
	job.PostString("https://iam.api.cloud.yandex.net/iam/v1/tokens",json.ToString)
	job.GetRequest.SetContentType("application/json")
	wait For (job) JobDone(job As HttpJob)
	If job.Success Then
		Dim parser As JSONParser
		parser.Initialize(job.GetString)
		IAMToken = parser.NextObject.Get("iamToken")
		IAMTokenRetrivedTimestamp = DateTime.Now
	Else
		Log(job.ErrorMessage)
	End If
	job.Release
	Return ""
End Sub


private Sub getMap(key As String,parentmap As Map) As Map
	Return parentmap.Get(key)
End Sub
