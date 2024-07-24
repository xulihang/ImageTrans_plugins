B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=4.2
@EndOfDesignText@
Sub Class_Globals
	Private fx As JFX
	Private translationMap As Map
	Private path As String
End Sub

'Initializes the object. You can NOT add parameters to this method!
Public Sub Initialize() As String
	Log("Initializing plugin " & GetNiceName)
	translationMap.Initialize
	' Here return a key to prevent running unauthorized plugins
	Return "MyKey"
End Sub

' must be available
public Sub GetNiceName() As String
	Return "tsvMT"
End Sub

' must be available
public Sub Run(Tag As String, Params As Map) As ResumableSub
	Log("run"&Params)
	Select Tag
		Case "getParams"
			Dim paramsList As List
			paramsList.Initialize
			paramsList.Add("path")
			Return paramsList
		Case "translate"
			wait for (translate(Params.Get("source"),Params.Get("sourceLang"),Params.Get("targetLang"),Params.Get("preferencesMap"))) complete (result As String)
			Return result
		Case "getMultipleCandidates"
			wait for (getMultipleCandidates(Params.Get("source"),Params.Get("sourceLang"),Params.Get("targetLang"),Params.Get("preferencesMap"))) complete (resultList As List)
			Return resultList
		Case "supportMultipleCandidates"
			Return True
		Case "getDefaultParamValues"
			Return CreateMap("path":"C:\test.tsv")
	End Select
	Return ""
End Sub

Sub getMultipleCandidates(source As String, sourceLang As String, targetLang As String,preferencesMap As Map) As ResumableSub
	Dim filepath As String
	Try
		filepath = getMap("tsv",getMap("api",preferencesMap)).Get("path")
		If path <> filepath Then
			If File.Exists(filepath,"") Then
				Log("exist")
				loadTranslations(filepath)
			End If
			path = filepath
		End If
	Catch
		Log(LastException)
	End Try
	Dim targetList As List
	targetList.Initialize
    If translationMap.ContainsKey(source) Then
		Dim resultMap As Map = translationMap.Get(source)
		For Each key As String In resultMap.Keys
		    Dim result As Map
			result.Initialize
			result.Put("target",resultMap.Get(key))
			result.Put("note",key)
			targetList.Add(result)
	    Next
    End If
	Return targetList
End Sub

Private Sub loadTranslations(filepath As String)
	Dim lines As List = File.ReadList(filepath,"")
	Dim firstLineItems As List = Regex.Split("	",lines.Get(0))
	Dim index As Int = 0
	For Each line As String In lines
		If index > 0 Then
			Dim items As List = Regex.Split("	",line)
			Dim storedSource As String = items.Get(0)
			Dim map1 As Map
			map1.Initialize
			For i = items.Size - 1 To 1 Step -1
				Dim target As String = items.Get(i)
				Dim note As String = firstLineItems.Get(i)
				map1.Put(note,target)
			Next
			translationMap.Put(storedSource,map1)
		End If
		index = index + 1
	Next
End Sub

Sub translate(source As String, sourceLang As String, targetLang As String,preferencesMap As Map) As ResumableSub
	wait for (getMultipleCandidates(source,sourceLang,targetLang,preferencesMap)) Complete (targetList As List)
	If targetList.Size > 0 Then
		Dim result As Map = targetList.Get(0)
		Return result.GetDefault("target","")
	End If
	Return ""
End Sub

Sub getMap(key As String,parentmap As Map) As Map
	Return parentmap.Get(key)
End Sub
