B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=4.2
@EndOfDesignText@
Sub Class_Globals
	Private fx As JFX
	Private defaultPrompt As String = $"Translate the following into {langcode}: {source}"$
	Private defaultPromptWithTerm As String = $"With the help of the terms defined in JSON: {term}, translate the following into {langcode}: {source}"$
	Private defaultBatchPrompt As String = $"Your task is to translate a text in JSON format into {langcode} and return the text in valid JSON format. You should not mix the values of different keys into one. Here is the JSON string to translate: {source}"$
	Private defaultBatchPromptWithTerm As String = $"Your task is to translate a text in JSON format into {langcode} and return the text in valid JSON format. You should use the terms defined in JSON: {term}. You should not mix the values of different keys into one. Here is the JSON string to translate: {source}"$
End Sub

'Initializes the object. You can NOT add parameters to this method!
Public Sub Initialize() As String
	Log("Initializing plugin " & GetNiceName)
	' Here return a key to prevent running unauthorized plugins
	Return "MyKey"
End Sub

' must be available
public Sub GetNiceName() As String
	Return "geminiMT"
End Sub

' must be available
public Sub Run(Tag As String, Params As Map) As ResumableSub
	Select Tag
		Case "getParams"
			Dim paramsList As List
			paramsList.Initialize
			paramsList.Add("key")
			paramsList.Add("prompt")
			paramsList.Add("batch_prompt")
			paramsList.Add("prompt_with_term")
			paramsList.Add("batch_prompt_with_term")
			paramsList.Add("endpoint")
			Return paramsList
		Case "translate"
			Dim terms As Map
			If Params.ContainsKey("terms") Then
				terms = Params.Get("terms")
			Else
				terms.Initialize
			End If
			wait for (translate(Params.Get("source"),Params.Get("sourceLang"),Params.Get("targetLang"),Params.Get("preferencesMap"),terms)) complete (result As String)
			Return result
		Case "batchtranslate"
			Dim terms As Map
			If Params.ContainsKey("terms") Then
				terms = Params.Get("terms")
			Else
				terms.Initialize
			End If
			wait for (batchTranslate(Params.Get("source"),Params.Get("sourceLang"),Params.Get("targetLang"),Params.Get("preferencesMap"),terms)) complete (targetList As List)
			Return targetList
		Case "supportBatchTranslation"
			Return True
		Case "getDefaultParamValues"
			Return CreateMap("prompt": defaultPrompt, _
			                 "batch_prompt": defaultBatchPrompt, _ 
							 "prompt_with_term":defaultPromptWithTerm, _ 
			                 "batch_prompt_with_term":defaultBatchPromptWithTerm, _ 
			                 "endpoint": "https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent")
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

Sub batchTranslate(sourceList As List, sourceLang As String, targetLang As String,preferencesMap As Map,terms As Map) As ResumableSub
	Dim targetList As List
	targetList.Initialize
	Dim converted As Boolean
	Dim langCode As String = targetLang
	targetLang = ConvertLang(targetLang)
	If langCode <> targetLang Then
		converted = True
	End If

	Dim job As HttpJob
	job.Initialize("job",Me)
	
	Dim apikey As String = getMap("gemini",getMap("mt",preferencesMap)).Get("key")
	Dim endpoint As String = getMap("gemini",getMap("mt",preferencesMap)).GetDefault("endpoint","https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent")
	Dim prompt As String
	If terms.Size>0 Then
		prompt = getMap("gemini",getMap("mt",preferencesMap)).GetDefault("batch_prompt_with_term",defaultBatchPromptWithTerm)
	Else
		prompt = getMap("gemini",getMap("mt",preferencesMap)).GetDefault("batch_prompt",defaultBatchPrompt)
	End If
	Dim url As String = endpoint&"?key="&apikey
	
	Dim body As Map
	body.Initialize
	Dim contents As List
	contents.Initialize
	body.Put("contents",contents)
	Dim content As Map
	content.Initialize
	Dim parts As List
	parts.Initialize
	content.Put("parts",parts)
	contents.Add(content)
	Dim part As Map
	part.Initialize
	
	Dim keyvalues As Map
	keyvalues.Initialize
	Dim index As Int = 0
	For Each source As String In sourceList
		Dim key As String = index
		keyvalues.Put(key,source)
		index = index + 1
	Next
	Dim jsonG As JSONGenerator
	jsonG.Initialize(keyvalues)
	Dim jsonString As String = jsonG.ToString
	
	If prompt.Contains("{langcode}") Then
		If converted Then
			part.Put("text",prompt.Replace("{langcode}",targetLang).Replace("{source}",jsonString))
			'$"Translate the following into ${targetLang}: ${source}"$
		Else
			part.Put("text",defaultBatchPrompt.Replace("{langcode}",$"the language whose ISO639-1 code is ${targetLang}"$).Replace("{source}",jsonString))
		End If
	Else
		If terms.Size>0 Then
			part.Put("text",defaultBatchPromptWithTerm.Replace("{langcode}",$"the language whose ISO639-1 code is ${targetLang}"$).Replace("{source}",jsonString))
		Else
			part.Put("text",defaultBatchPrompt.Replace("{langcode}",$"the language whose ISO639-1 code is ${targetLang}"$).Replace("{source}",jsonString))
		End If
	End If
	
	If terms.Size>0 Then
		Dim termsJsonG As JSONGenerator
		termsJsonG.Initialize(terms)
		Dim msg As String = part.Get("text")
		part.Put("text",msg.Replace("{term}",termsJsonG.ToString))
	End If
	
	parts.Add(part)
	Dim jsonG As JSONGenerator
	jsonG.Initialize(body)
	job.PostString(url,jsonG.ToString)
	job.GetRequest.SetContentType("application/json")
	wait For (job) JobDone(job As HttpJob)
	If job.Success Then
		Try
			Log(job.GetString)
			Dim str As String = job.GetString
			parseResults(str,sourceList,targetList)
		Catch
			Log(LastException)
		End Try
	End If
	job.Release
	If targetList.Size = 0 Then
		For Each source As String In sourceList
			targetList.Add("")
		Next
	End If
	Return targetList
End Sub

Private Sub parseResults(jsonString As String,sourceList As List,targetList As List)
	Dim json As JSONParser
	json.Initialize(jsonString)
	Dim response As Map = json.NextObject
	Dim candidates As List = response.Get("candidates")
	Dim candidate As Map = candidates.Get(0)
	Dim content As Map = candidate.Get("content")
	Dim parts As List = content.Get("parts")
	Dim part As Map = parts.Get(0)
	Dim text As String = part.Get("text")
	If text.StartsWith("```json") Then
		text = text.Replace("```json","")
		text = text.SubString2(0,text.Length - 3)
	End If
	Dim jsonP As JSONParser
	jsonP.Initialize(text)
	Dim keyvalues As Map = jsonP.NextObject
	For i = 0 To sourceList.Size - 1
		Dim key As String = i
		targetList.Add(keyvalues.GetDefault(key,""))
	Next
End Sub

Sub translate(source As String,sourceLang As String,targetLang As String,preferencesMap As Map,terms As Map) As ResumableSub
	Dim converted As Boolean
	Dim langCode As String = targetLang
	targetLang = ConvertLang(targetLang)
	If langCode <> targetLang Then
		converted = True
	End If
	Dim target As String
	Dim job As HttpJob
	job.Initialize("job",Me)
	Dim key As String = getMap("gemini",getMap("mt",preferencesMap)).Get("key")
	Dim prompt As String
	If terms.Size>0 Then
		prompt = getMap("gemini",getMap("mt",preferencesMap)).GetDefault("prompt_with_term",defaultPromptWithTerm)
	Else
		prompt = getMap("gemini",getMap("mt",preferencesMap)).GetDefault("prompt",defaultPrompt)
	End If
	Dim endpoint As String = getMap("gemini",getMap("mt",preferencesMap)).GetDefault("endpoint","https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent")
	Dim url As String = endpoint&"?key="&key
	Dim body As Map
	body.Initialize
	Dim contents As List
	contents.Initialize
	body.Put("contents",contents)
	Dim content As Map
	content.Initialize
	Dim parts As List
	parts.Initialize
	content.Put("parts",parts)
	contents.Add(content)
	Dim part As Map
	part.Initialize
	If prompt.Contains("{langcode}") Then
		If converted Then
			part.Put("text",prompt.Replace("{langcode}",targetLang).Replace("{source}",source))
			'$"Translate the following into ${targetLang}: ${source}"$
		Else
			If terms.Size>0 Then
				part.Put("text",defaultPromptWithTerm.Replace("{langcode}",$"the language whose ISO639-1 code is ${targetLang}"$).Replace("{source}",source))
			Else
				part.Put("text",defaultPrompt.Replace("{langcode}",$"the language whose ISO639-1 code is ${targetLang}"$).Replace("{source}",source))
			End If
			part.Put("text",$"Translate the following into the language whose ISO639-1 code is ${targetLang}: ${source}"$)
		End If
	Else
		part.Put("text",prompt.Replace("{source}",source))
	End If
	
	If terms.Size>0 Then
		Dim termsJsonG As JSONGenerator
		termsJsonG.Initialize(terms)
		Dim msg As String = part.Get("text")
		part.Put("text",msg.Replace("{term}",termsJsonG.ToString))
	End If
	
	Log(part)
	
	parts.Add(part)
	Dim jsonG As JSONGenerator
	jsonG.Initialize(body)
	job.PostString(url,jsonG.ToString)
	job.GetRequest.SetContentType("application/json")
	wait For (job) JobDone(job As HttpJob)
	If job.Success Then
		Try
			Log(job.GetString)
			Dim json As JSONParser
			json.Initialize(job.GetString)
			Dim response As Map = json.NextObject
			Dim candidates As List = response.Get("candidates")
			Dim candidate As Map = candidates.Get(0)
			Dim content As Map = candidate.Get("content")
			Dim parts As List = content.Get("parts")
			Dim part As Map = parts.Get(0)
			target = part.Get("text")
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
