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
	Dim filePath As String
	Try
		filePath = getMap("tsv",getMap("api",preferencesMap)).Get("path")
	Catch
		Log(LastException)
	End Try
	Dim targetList As List
	targetList.Initialize
	Log(filePath)
	If File.Exists(filePath,"") Then
		Log("exist")
		Dim lines As List = File.ReadList(filePath,"")
		Dim firstLineItems As List = Regex.Split("	",lines.Get(0))
		Dim index As Int = 0
		For Each line As String In lines
			If index > 0 Then
				Dim items As List = Regex.Split("	",line)
				Dim storedSource As String = items.Get(0)
				If storedSource == source Then
					For i = items.Size - 1 To 1 Step -1
						Dim target As String = items.Get(i)
						Dim note As String = firstLineItems.Get(i)
						Dim result As Map
						result.Initialize
						result.Put("source","")
						result.Put("target",target)
						result.Put("note",note)
						targetList.Add(result)
					Next
				End If
			End If
			index = index + 1
		Next
	End If
	Return targetList
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
