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
	Return "sugoiMT"
End Sub

' must be available
public Sub Run(Tag As String, Params As Map) As ResumableSub
	Log("run"&Params)
	Select Tag
		Case "getParams"
			Dim paramsList As List
			paramsList.Initialize
			paramsList.Add("url")
			Return paramsList
		Case "translate"
			wait for (translate(Params.Get("source"),Params.Get("sourceLang"),Params.Get("targetLang"),Params.Get("preferencesMap"))) complete (result As String)
			Return result
		Case "getDefaultParamValues"
			Return CreateMap("url":"http://localhost:14366")
	End Select
	Return ""
End Sub

Sub translate(source As String, sourceLang As String, targetLang As String,preferencesMap As Map) As ResumableSub
	Dim target As String
	Dim url As String = preferencesMap.GetDefault("url","http://localhost:14366")
	Dim params As Map
	params.Initialize
	params.Put("content",source)
	params.Put("message","translate sentences")
	Dim json As JSONGenerator
	json.Initialize(params)
	Dim job As HttpJob
	job.Initialize("",Me)
	job.PostString(url,json.ToString)
	job.GetRequest.SetContentType("application/json")
	Wait For (job) JobDone (job As HttpJob)
	If job.Success Then
		target=job.GetString
		If target.StartsWith($"""$) And source.StartsWith($"""$) = False Then
			target=target.SubString2(1,target.Length-1)
		End If
	Else
		target=""
	End If
	job.Release
	Return target
End Sub
