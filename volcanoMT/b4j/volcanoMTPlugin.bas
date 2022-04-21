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
	Return "volcanoMT"
End Sub

' must be available
public Sub Run(Tag As String, Params As Map) As ResumableSub
	Select Tag
		Case "getParams"
			Dim paramsList As List
			paramsList.Initialize
			paramsList.Add("accesskey")
			paramsList.Add("secret")
			Return paramsList
		Case "translate"
			wait for (translate(Array(Params.Get("source")),Params.Get("sourceLang"),Params.Get("targetLang"),Params.Get("preferencesMap"))) complete (targetList As List)
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
	End Select
	Return ""
End Sub


Sub translate(sourceList As List,sourceLang As String,targetLang As String,preferencesMap As Map) As ResumableSub
    Dim targetList As List
	targetList.Initialize
	Dim accesskey As String
	Dim secret As String

	Try
		accesskey=getMap("volcano",getMap("mt",preferencesMap)).Get("accesskey")
		secret=getMap("volcano",getMap("mt",preferencesMap)).Get("secret")
	Catch
		Log(LastException)
	End Try
	

	Dim map1 As Map
	map1.Initialize
	map1.Put("sourceLang",sourceLang)
	map1.Put("targetLang",targetLang)
	map1.Put("sourceList",sourceList)
	Dim json As JSONGenerator
	json.Initialize(map1)
    Dim su As StringUtils
	Dim body As String = su.EncodeUrl(json.ToString,"UTF8")
    Dim sh As Shell
	sh.Initialize("sh","java",Array("-jar","volcmt.jar",body,accesskey,secret))
	sh.Encoding=GetSystemProperty("sun.jnu.encoding","UTF8")
	sh.Run(10000)
	wait for sh_ProcessCompleted (Success As Boolean, ExitCode As Int, StdOut As String, StdErr As String)
	If Success And ExitCode = 0 Then
		Try
			Dim jsonP As JSONParser
			jsonP.Initialize(StdOut)
			Dim translationList As List = jsonP.NextObject.Get("TranslationList")
			For Each translation As Map In translationList
				targetList.Add(translation.Get("Translation"))
			Next
		Catch
			Log(LastException)
		End Try
	End If
	Return targetList
End Sub


Sub getMap(key As String,parentmap As Map) As Map
	Return parentmap.Get(key)
End Sub
