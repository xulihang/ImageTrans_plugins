B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=4.2
@EndOfDesignText@
Sub Class_Globals
	Private fx As JFX
	Private defaultBatchPrompt As String = $"You are a professional AI translator. Translate the following text into {langcode}.

**Source Text:**
{source}

**Requirements:**
Output ONLY the final translation. Do not include any explanations, notes, or the original text. Do not mix sentences and keep the original number of sentences.
"$
	Private defaultBatchPromptWithTerm As String = $"You are a professional AI translator. Translate the following text into {langcode}.

**Source Text:**
{source}

**Requirements:**
1. Strictly adhere to the provided glossary for term translation.
2. Output ONLY the final translation. Do not include any explanations, notes, or the original text. Do not mix sentences and keep the original number of sentences.

**Glossary (JSON):**
{term}"$
	Private defaultSpellCheckingPrompt As String = $"You are a spell checker. Please fix the following OCR results.

	**Text:**
	{source}

	**Requirements:**
	Output ONLY the corrected text. Do Not include any explanations and notes. Do Not mix sentences And keep the original number of sentences.
"$
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
			paramsList.Add("batch_prompt")
			paramsList.Add("prompt_with_term")
			paramsList.Add("batch_prompt_with_term")
			paramsList.Add("spell_checking_prompt")
			paramsList.Add("host")
			paramsList.Add("model")
			paramsList.Add("force_no_think (yes or no)")
			Return paramsList
		Case "batchtranslate"
			Dim terms As Map
			If Params.ContainsKey("terms") Then
			    terms = Params.Get("terms")
			Else
				terms.Initialize
			End If
			wait for (batchTranslate(Params.Get("source"),Params.Get("sourceLang"),Params.Get("targetLang"),Params.Get("preferencesMap"),terms)) complete (targetList As List)
			Return targetList
		Case "spellcheck"
			wait for (spellCheck(Params.Get("source"),Params.Get("preferencesMap"))) complete (targetList As List)
			Return targetList
		Case "translate"
			Dim terms As Map
			If Params.ContainsKey("terms") Then
				terms = Params.Get("terms")
			Else
				terms.Initialize
			End If
			wait for (translate(Params.Get("source"),Params.Get("sourceLang"),Params.Get("targetLang"),Params.Get("preferencesMap"),terms)) complete (result As String)
			Return result
		Case "supportBatchTranslation"
			Return True
		Case "getDefaultParamValues"
			Return CreateMap("prompt":defaultBatchPrompt, _
							 "spell_checking_prompt": defaultSpellCheckingPrompt, _
			                 "batch_prompt":defaultBatchPrompt, _ 
							 "prompt_with_term":defaultBatchPromptWithTerm, _ 
			                 "batch_prompt_with_term":defaultBatchPromptWithTerm, _ 
							 "force_no_think (yes or no)":"no", _ 
			                 "host":"https://api.openai.com/v1", _
							 "model":"gpt-4o")
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

Sub spellCheck(sourceList As List,preferencesMap As Map) As ResumableSub
	Dim targetList As List
	targetList.Initialize
	
	Dim job As HttpJob
	job.Initialize("job",Me)
	
	Dim apikey As String = getMap("chatGPT",getMap("mt",preferencesMap)).Get("key")
	Dim host As String = getMap("chatGPT",getMap("mt",preferencesMap)).GetDefault("host","https://api.openai.com/v1")
	
	Dim prompt As String

	prompt = getMap("chatGPT",getMap("mt",preferencesMap)).GetDefault("spell_checking_prompt",defaultSpellCheckingPrompt)

	
	Dim noThink As String = getMap("chatGPT",getMap("mt",preferencesMap)).GetDefault("force_no_think (yes or no)","no")
	Dim model As String = getMap("chatGPT",getMap("mt",preferencesMap)).GetDefault("model","gpt-4o")

	Dim url As String = host&"/chat/completions"
	Dim messages As List
	messages.Initialize
	Dim message As Map
	message.Initialize
	message.Put("role","user")

    
	Dim sb As StringBuilder
	sb.Initialize
	Dim index As Int = 0
	For Each source As String In sourceList
		index = index + 1
		source = source.Replace(CRLF,"\n")
		sb.Append(index)
		sb.Append(". ")
		sb.Append(source)
		sb.Append(CRLF)
	Next
	
	Dim target As String = sb.ToString
	message.Put("content",prompt.Replace("{source}",target))
	
	If noThink = "yes" Then
		Dim msg As String = message.Get("content")
		msg = msg & "/no_think"
		message.Put("content",msg)
	End If
	
	messages.Add(message)
	Dim params As Map
	params.Initialize
	params.Put("model",model)
	params.Put("messages",messages)
	If url.Contains("siliconflow") Then
		params.Put("enable_thinking",False)
	End If
	If noThink = "yes" Then
		params.Put("enable_thinking",False)
	End If
	Log(params)
	Dim jsonG As JSONGenerator
	jsonG.Initialize(params)
	job.PostString(url,jsonG.ToString)
	Log(jsonG.ToString)
	job.GetRequest.SetContentType("application/json")
	job.GetRequest.SetHeader("Authorization","Bearer "&apikey)
	job.GetRequest.Timeout = 1200000
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
			Dim content As String = message.Get("content")
			content = RemoveThinkTags(content)
			content = Regex.Replace("\n+",content,CRLF)
			content = content.Trim
			For Each line As String In Regex.Split(CRLF,content)
				line = ReplaceStartingNumberedStrings(line)
				line = line.Replace("\n",CRLF)
				targetList.Add(line)
			Next
			Do While targetList.Size < sourceList.Size
				targetList.Add("")
			Loop
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
	
	Dim apikey As String = getMap("chatGPT",getMap("mt",preferencesMap)).Get("key")
	Dim host As String = getMap("chatGPT",getMap("mt",preferencesMap)).GetDefault("host","https://api.openai.com/v1")
	
	Dim prompt As String
	If terms.Size>0 Then
		prompt = getMap("chatGPT",getMap("mt",preferencesMap)).GetDefault("batch_prompt_with_term",defaultBatchPromptWithTerm)
	Else
		prompt = getMap("chatGPT",getMap("mt",preferencesMap)).GetDefault("batch_prompt",defaultBatchPrompt)
	End If
	
	Dim noThink As String = getMap("chatGPT",getMap("mt",preferencesMap)).GetDefault("force_no_think (yes or no)","no")
	Dim model As String = getMap("chatGPT",getMap("mt",preferencesMap)).GetDefault("model","gpt-4o")

	Dim url As String = host&"/chat/completions"
	Dim messages As List
	messages.Initialize
	Dim message As Map
	message.Initialize
	message.Put("role","user")

    
	Dim sb As StringBuilder
	sb.Initialize
	Dim index As Int = 0
	For Each source As String In sourceList
		index = index + 1
		source = source.Replace(CRLF,"\n")
		sb.Append(index)
		sb.Append(". ")
		sb.Append(source)
		sb.Append(CRLF)
	Next
	
	Dim target As String = sb.ToString
	
	If prompt.Contains("{langcode}") Then
		If converted Then
			message.Put("content",prompt.Replace("{langcode}",targetLang).Replace("{source}",target))
			'$"Translate the following into ${targetLang}: ${source}"$
		Else
			If terms.Size>0 Then
				message.Put("content",defaultBatchPromptWithTerm.Replace("{langcode}",$"the language whose ISO639-1 code is ${targetLang}"$).Replace("{source}",target))
			Else
				message.Put("content",defaultBatchPrompt.Replace("{langcode}",$"the language whose ISO639-1 code is ${targetLang}"$).Replace("{source}",target))
			End If
		End If
	Else
		message.Put("content",prompt.Replace("{source}",target))
	End If
	
	If terms.Size>0 Then
		Dim termsJsonG As JSONGenerator
		termsJsonG.Initialize(terms)
		Dim msg As String = message.Get("content")
		message.Put("content",msg.Replace("{term}",termsJsonG.ToString))
	End If
	
	If noThink = "yes" Then
		Dim msg As String = message.Get("content")
		msg = msg & "/no_think"
		message.Put("content",msg)
	End If
	
	messages.Add(message)
	Dim params As Map
	params.Initialize
	params.Put("model",model)
	params.Put("messages",messages)
	If url.Contains("siliconflow") Then
		params.Put("enable_thinking",False)
	End If
	If noThink = "yes" Then
		params.Put("enable_thinking",False)
	End If
	Log(params)
	Dim jsonG As JSONGenerator
	jsonG.Initialize(params)
	job.PostString(url,jsonG.ToString)
	Log(jsonG.ToString)
	job.GetRequest.SetContentType("application/json")
	job.GetRequest.SetHeader("Authorization","Bearer "&apikey)
	job.GetRequest.Timeout = 1200000
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
			Dim content As String = message.Get("content")
			content = RemoveThinkTags(content)
			content = Regex.Replace("\n+",content,CRLF)
			content = content.Trim
			For Each line As String In Regex.Split(CRLF,content)
				line = ReplaceStartingNumberedStrings(line)
				line = line.Replace("\n",CRLF)
				targetList.Add(line)
			Next
			Do While targetList.Size < sourceList.Size
				targetList.Add("")
			Loop
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

Sub ReplaceStartingNumberedStrings(Text As String) As String
	Dim Pattern As String = "^\d+[\.、]\s*"  '\s*匹配0个或多个空白字符（包括空格）
	Return Regex.Replace(Pattern, Text, "")
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
	
	Dim key As String = getMap("chatGPT",getMap("mt",preferencesMap)).Get("key")
	Dim prompt As String
	If terms.Size>0 Then
		prompt = getMap("chatGPT",getMap("mt",preferencesMap)).GetDefault("prompt_with_term",defaultBatchPromptWithTerm)
	Else
		prompt = getMap("chatGPT",getMap("mt",preferencesMap)).GetDefault("prompt",defaultBatchPrompt)
	End If
	
	Dim noThink As String = getMap("chatGPT",getMap("mt",preferencesMap)).GetDefault("force_no_think (yes or no)","no")
	Dim host As String = getMap("chatGPT",getMap("mt",preferencesMap)).GetDefault("host","https://api.openai.com/v1")
	Dim url As String = host&"/chat/completions"
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
			If terms.Size>0 Then
				message.Put("content",defaultBatchPromptWithTerm.Replace("{langcode}",$"the language whose ISO639-1 code is ${targetLang}"$).Replace("{source}",source))
			Else
				message.Put("content",$"Translate the following into the language whose ISO639-1 code is ${targetLang}: ${source}"$)
			End If
			
		End If
	Else
		message.Put("content",prompt.Replace("{source}",source))
	End If
	
	If terms.Size>0 Then
		Dim termsJsonG As JSONGenerator
		termsJsonG.Initialize(terms)
		Dim msg As String = message.Get("content")
		message.Put("content",msg.Replace("{term}",termsJsonG.ToString))
	End If
	
	If noThink = "yes" Then
		Dim msg As String = message.Get("content")
		msg = msg & "/no_think"
		message.Put("content",msg)
	End If
	
	messages.Add(message)
	Dim model As String = getMap("chatGPT",getMap("mt",preferencesMap)).GetDefault("model","gpt-4o")
	Dim params As Map
	params.Initialize
	params.Put("model",model)
	params.Put("messages",messages)
	If url.Contains("siliconflow") Then
		params.Put("enable_thinking",False)
	End If
	If noThink = "yes" Then
		params.Put("enable_thinking",False)
	End If
	Log(params)
	Dim jsonG As JSONGenerator
	jsonG.Initialize(params)
	job.PostString(url,jsonG.ToString)
	job.GetRequest.SetContentType("application/json")
	job.GetRequest.SetHeader("Authorization","Bearer "&key)
	job.GetRequest.Timeout = 1200000
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
			target = RemoveThinkTags(target)
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

Sub RemoveThinkTags(Text As String) As String
	Return Regex.Replace2("<think>.*?</think>",32,Text, "")
End Sub


Sub getMap(key As String,parentmap As Map) As Map
	Return parentmap.Get(key)
End Sub
