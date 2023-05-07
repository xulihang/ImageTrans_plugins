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
	Return "chatGPTMT"
End Sub

' must be available
public Sub Run(Tag As String, Params As Map) As ResumableSub
	Select Tag
		Case "getParams"
			Dim paramsList As List
			paramsList.Initialize
			paramsList.Add("key")
			paramsList.Add("prompt")
			paramsList.Add("host")
			Return paramsList
		Case "translate"
			wait for (translate(Params.Get("source"),Params.Get("sourceLang"),Params.Get("targetLang"),Params.Get("preferencesMap"))) complete (result As String)
			Return result
		Case "supportBatchTranslation"
			Return False
		Case "getDefaultParamValues"
			Return CreateMap("prompt":"Translate the following into {langcode}: {source}", _ 
			                 "host":"https://api.openai.com")
	End Select
	Return ""
End Sub

private Sub ConvertLang(lang As String) As String
	Dim map1 As Map
	map1.Initialize
	map1.Put("zh","Chinese")
	map1.Put("zh-CN","Simplified Chinese")
	map1.Put("zh-TW","Traditional Chinese")
	map1.Put("en","English")
	map1.Put("ja","Japanese")
	map1.Put("ko","Korean")
	map1.Put("ar","Arabic")
	map1.Put("de","German")
	map1.Put("fi","Finish")
	map1.Put("el","Greek")
	map1.Put("da","Danish")
	map1.Put("cs","Czech")
	map1.Put("ca","Catalan")
	map1.Put("fr","French")
	map1.Put("it","Italian")
	map1.Put("sv","Swedish")
	map1.Put("pt","Portuguese")
	map1.Put("nl","Dutch")
	map1.Put("pl","Polish")
	map1.Put("es","Spanish")
	map1.Put("id","Indonesian")
	map1.Put("hi","Hindi")
	map1.Put("vi","Vietnamese")
	map1.Put("ru","Russian")
	If map1.ContainsKey(lang) Then
		Return map1.Get(lang)
	End If
	Return lang
End Sub


Sub translate(source As String,sourceLang As String,targetLang As String,preferencesMap As Map) As ResumableSub
	Dim converted As Boolean
	Dim langCode As String = targetLang
	targetLang = ConvertLang(targetLang)
	If langCode <> targetLang Then
		converted = True
	End If
	Dim target As String
	Dim job As HttpJob
	job.Initialize("job",Me)
	
	Dim key As String = getMap("chatGPT",getMap("mt",preferencesMap)).Get("key")
	Dim prompt As String = getMap("chatGPT",getMap("mt",preferencesMap)).GetDefault("prompt","Translate the following into {langcode}: {source}")
	Dim host As String = getMap("chatGPT",getMap("mt",preferencesMap)).GetDefault("host","https://api.openai.com")
	Dim url As String = host&"/v1/chat/completions"
	Dim messages As List
	messages.Initialize
	Dim message As Map
	message.Initialize
	message.Put("role","user")
	If prompt.Contains("{langcode}") Then
		If converted Then
			message.Put("content",prompt.Replace("{langcode}",targetLang).Replace("{source}",source))
			'$"Translate the following into ${targetLang}: ${source}"$
		Else
			message.Put("content",$"Translate the following into the language whose ISO639-1 code is ${targetLang}: ${source}"$)
		End If
	Else
		message.Put("content",prompt.Replace("{source}",source))
	End If
	messages.Add(message)
	Dim params As Map
	params.Initialize
	params.Put("model","gpt-3.5-turbo")
	params.Put("messages",messages)
	Dim jsonG As JSONGenerator
	jsonG.Initialize(params)
	job.PostString(url,jsonG.ToString)
	job.GetRequest.SetContentType("application/json")
	job.GetRequest.SetHeader("Authorization","Bearer "&key)
	wait For (job) JobDone(job As HttpJob)
	If job.Success Then
		Try
			Log(job.GetString)
			Dim json As JSONParser
			json.Initialize(job.GetString)
			Dim response As Map = json.NextObject
			Dim choices As List
			choices = response.Get("choices")
			Dim choice As Map = choices.Get(0)
			Dim message As Map = choice.Get("message")
			target = message.Get("content")
			target = target.Trim
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
