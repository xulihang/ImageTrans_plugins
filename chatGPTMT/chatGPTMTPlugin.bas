B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=4.2
@EndOfDesignText@
Sub Class_Globals
	Private fx As JFX
	'The batch prompts ask for one numbered line per item. Numbering keeps the translations aligned when a
	'comic page has many short bubbles and lets the parser ignore an echoed instruction, and unlike JSON
	'it is a format the small local models follow too.
	Private defaultVisionBatchPrompt As String = $"You are a professional AI translator. Translate the numbered text areas of an image below into {langcode}.

**Source Text:**
{source}

**Requirements:**
- Output one line per numbered item, in the same order, each starting with its number and a period, like this: 1. translated text
- Keep the original number of items. Do not merge, split or reorder items, and do not mix their translations.
- Output only the translated lines. Do not include explanations, notes or the source text.
"$
	Private defaultVisionBatchPromptWithTerm As String = $"You are a professional AI translator. Translate the numbered text areas of an image below into {langcode}.

**Source Text:**
{source}

**Requirements:**
1. Strictly adhere to the provided glossary for term translation.
2. Output one line per numbered item, in the same order, each starting with its number and a period, like this: 1. translated text
3. Keep the original number of items. Do not merge, split or reorder items, and do not mix their translations.
4. Output only the translated lines. Do not include explanations, notes or the source text.

**Glossary (JSON):**
{term}"$
	Private defaultBatchPrompt As String = $"You are a professional AI translator. Translate the numbered lines below into {langcode}.

**Source Text:**
{source}

**Requirements:**
- Output one line per numbered item, in the same order, each starting with its number and a period, like this: 1. translated text
- Keep the original number of items. Do not merge, split or reorder items, and do not mix their translations.
- Output only the translated lines. Do not include explanations, notes or the source text.
"$
	Private defaultBatchPromptWithTerm As String = $"You are a professional AI translator. Translate the numbered lines below into {langcode}.

**Source Text:**
{source}

**Requirements:**
1. Strictly adhere to the provided glossary for term translation.
2. Output one line per numbered item, in the same order, each starting with its number and a period, like this: 1. translated text
3. Keep the original number of items. Do not merge, split or reorder items, and do not mix their translations.
4. Output only the translated lines. Do not include explanations, notes or the source text.

**Glossary (JSON):**
{term}"$
	'The single sentence prompt stays plain: the translate method sends one source string, not JSON.
	Private defaultPrompt As String = $"You are a professional AI translator. Translate the following text into {langcode}.

**Source Text:**
{source}

**Requirements:**
Output ONLY the final translation. Do not include any explanations, notes, or the original text.
"$
	Private defaultPromptWithTerm As String = $"You are a professional AI translator. Translate the following text into {langcode}.

**Source Text:**
{source}

**Requirements:**
1. Strictly adhere to the provided glossary for term translation.
2. Output ONLY the final translation. Do not include any explanations, notes, or the original text.

**Glossary (JSON):**
{term}"$
	Private defaultSpellCheckingPrompt As String = $"You are a spell checker. Please fix the following OCR results.

	**Text:**
	{source}

	**Requirements:**
	Output ONLY the corrected text. Do Not include any explanations and notes. Do Not mix sentences And keep the original number of sentences.
"$
	Private defaultTransliterationPrompt As String = $"Mark the following text with HTML ruby:

**Text:**
{source}

**Requirements:**
Output ONLY the final transliteration. Use hiragana for Japanese and use pinyin for Chinese. Remember to use both ruby and rt. Do not translate the text. Do not include any explanations, notes, or the original text. Do not mix sentences and keep the original number of sentences.
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
			paramsList.Add("vision_batch_prompt")
			paramsList.Add("batch_prompt_with_term")
			paramsList.Add("vision_batch_prompt_with_term")
			paramsList.Add("spell_checking_prompt")
			paramsList.Add("transliteration_prompt")
			paramsList.Add("host")
			paramsList.Add("model")
			paramsList.Add("force_no_think (yes or no)")
			paramsList.Add("extra_fields")
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
		Case "transliterate"
			wait for (transliterate(Params.Get("source"),Params.Get("sourceLang"),Params.Get("targetLang"),Params.Get("preferencesMap"))) complete (targetList As List)
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
		Case "visionTranslate"
			Dim terms As Map
			If Params.ContainsKey("terms") Then
				terms = Params.Get("terms")
			Else
				terms.Initialize
			End If
			wait for (visionTranslate(Params.Get("source"),Params.Get("img"),Params.Get("sourceLang"),Params.Get("targetLang"),Params.Get("preferencesMap"),terms)) complete (targetList As List)
			Return targetList
		Case "supportVisionTranslation"
			Return True
		Case "supportBatchTranslation"
			Return True
		Case "getDefaultParamValues"
			Return CreateMap("prompt":defaultPrompt, _
							 "spell_checking_prompt": defaultSpellCheckingPrompt, _
			                 "batch_prompt":defaultBatchPrompt, _
							 "vision_batch_prompt":defaultVisionBatchPrompt, _
							 "prompt_with_term":defaultPromptWithTerm, _
			                 "batch_prompt_with_term":defaultBatchPromptWithTerm, _
							 "vision_batch_prompt_with_term":defaultVisionBatchPromptWithTerm, _
							 "transliteration_prompt":defaultTransliterationPrompt, _ 
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

Sub visionTranslate(boxes As List, img As B4XBitmap,sourceLang As String, targetLang As String,preferencesMap As Map,terms As Map) As ResumableSub
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
		prompt = getMap("chatGPT",getMap("mt",preferencesMap)).GetDefault("vision_batch_prompt_with_term",defaultVisionBatchPromptWithTerm)
	Else
		prompt = getMap("chatGPT",getMap("mt",preferencesMap)).GetDefault("vision_batch_prompt",defaultVisionBatchPrompt)
	End If
	
	Dim noThink As String = getMap("chatGPT",getMap("mt",preferencesMap)).GetDefault("force_no_think (yes or no)","no")
	Dim model As String = getMap("chatGPT",getMap("mt",preferencesMap)).GetDefault("model","gpt-4o")

	Dim url As String = host&"/chat/completions"

	Dim contentList As List
	contentList.Initialize
	Dim messages As List
	messages.Initialize
	Dim message As Map
	message.Initialize
	message.Put("role","user")
	
	'The source is sent as one numbered line per box, so the answer can be matched back by number and
	'each box's text stays on a single line. The text of a box is what the OCR step stored under "text".
	Dim sb As StringBuilder
	sb.Initialize
	For i = 0 To boxes.Size - 1
		Dim box As Map = boxes.Get(i)
		sb.Append(i + 1)
		sb.Append(". ")
		sb.Append(OneLine(box.GetDefault("text","")))
		sb.Append(CRLF)
	Next
	Dim target As String = sb.ToString
	Dim userMessage As String
	If prompt.Contains("{langcode}") Then
		If converted Then
			userMessage = prompt.Replace("{langcode}",targetLang).Replace("{source}",target)
			'$"Translate the following into ${targetLang}: ${source}"$
		Else
			If terms.Size>0 Then
				userMessage = defaultVisionBatchPromptWithTerm.Replace("{langcode}",$"the language whose ISO639-1 code is ${targetLang}"$).Replace("{source}",target)
			Else
				userMessage = defaultVisionBatchPrompt.Replace("{langcode}",$"the language whose ISO639-1 code is ${targetLang}"$).Replace("{source}",target)
			End If
		End If
	Else
		userMessage = prompt.Replace("{source}",target)
	End If
	
	If terms.Size>0 Then
		Dim termsJsonG As JSONGenerator
		termsJsonG.Initialize(terms)
		userMessage = userMessage.Replace("{term}",termsJsonG.ToString)
	End If
	
	If noThink = "yes" Then
		userMessage = userMessage & "/no_think"
	End If
	
	Dim text As Map
	text.Initialize
	text.Put("type","text")
	text.Put("text",userMessage)
	
	Dim su As StringUtils
	Dim base64 As String=su.EncodeBase64(ImageToBytes(img))
	Dim urlMap As Map
	urlMap.Initialize
	urlMap.Put("url","data:image/jpeg;base64,"&base64)
	Dim image As Map
	image.Initialize
	image.Put("type","image_url")
	image.Put("image_url",urlMap)
	contentList.Add(text)
	contentList.Add(image)
	message.Put("content",contentList)
	
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
	Dim extraFieldsStr As String = getMap("chatGPT",getMap("mt",preferencesMap)).GetDefault("extra_fields","")
	If extraFieldsStr.Trim <> "" Then
		Dim extraParser As JSONParser
		extraParser.Initialize(extraFieldsStr)
		Dim extraMap As Map = extraParser.NextObject
		For Each extraKey As String In extraMap.Keys
			params.Put(extraKey, extraMap.Get(extraKey))
		Next
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
			parseBatchResult(content,boxes.Size,targetList)
		Catch
			Log(LastException)
		End Try
	End If
	job.Release
	If targetList.Size = 0 Then
		For Each source As String In boxes
			targetList.Add("")
		Next
	End If
	Return targetList
End Sub

private Sub ImageToBytes(Image As B4XBitmap) As Byte()
	Dim out As OutputStream
	out.InitializeToBytesArray(0)
	Image.WriteToStream(out, 100, "JPEG")
	out.Close
	Return out.ToBytesArray
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

    
	'The source is sent as one numbered line per item, so the answer can be matched back by number and
	'each item's text stays on a single line.
	Dim sb As StringBuilder
	sb.Initialize
	Dim index As Int = 0
	For Each source As String In sourceList
		index = index + 1
		sb.Append(index)
		sb.Append(". ")
		sb.Append(OneLine(source))
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
	Dim extraFieldsStr As String = getMap("chatGPT",getMap("mt",preferencesMap)).GetDefault("extra_fields","")
	If extraFieldsStr.Trim <> "" Then
		Dim extraParser As JSONParser
		extraParser.Initialize(extraFieldsStr)
		Dim extraMap As Map = extraParser.NextObject
		For Each extraKey As String In extraMap.Keys
			params.Put(extraKey, extraMap.Get(extraKey))
		Next
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
			parseBatchResult(content,sourceList.Size,targetList)
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

'Fills targetList with one translation per source item, in source order.
'The answer is read in three ways, best first:
'1. a JSON object keyed by the ids of the source (what a user's own JSON prompt may ask for);
'2. one numbered line per item, like "1. translation", which is what the default prompts ask for;
'3. plain lines matched by position, the original behaviour, kept so that an answer in a shape the
'   parser cannot recognize still behaves as it did before.
'Numbering rather than position is what keeps a comic page aligned when the model wraps a translation
'onto a second line or echoes part of the instruction; a numbered answer that does not cover every id
'exactly is discarded rather than repaired, and falls through to the positional parser.
Private Sub parseBatchResult(content As String,count As Int,targetList As List)
	content = RemoveThinkTags(content)
	Dim values As Map = parseKeyedValues(content,count)
	If hasIdKeys(values,count) Then
		fillFromMap(values,count,targetList)
		Return
	End If
	Dim numbered As Map = parseNumberedLines(content,count)
	If isComplete(numbered,count) Then
		fillFromMap(numbered,count,targetList)
		Return
	End If
	content = Regex.Replace("\n+",content,CRLF)
	content = content.Trim
	For Each line As String In Regex.Split(CRLF,content)
		line = ReplaceStartingNumberedStrings(line)
		line = line.Replace("\n",CRLF)
		targetList.Add(line)
	Next
	Do While targetList.Size < count
		targetList.Add("")
	Loop
End Sub

'Reads the values of an id keyed map into targetList. A value that came back as an object, such as
'{"target": "..."}, is reduced to its text; a missing id becomes an empty string.
Private Sub fillFromMap(values As Map,count As Int,targetList As List)
	For i = 0 To count - 1
		Dim value As Object = values.GetDefault("" & (i + 1),"")
		If value Is Map Then
			Dim valueMap As Map = value
			value = valueMap.GetDefault("target",valueMap.GetDefault("text",""))
		End If
		targetList.Add(toText(value))
	Next
End Sub

'Reads an answer whose items are numbered, one per line, into a map keyed by id.
'A line without a number is a continuation of the item above, so a translation that wrapped onto a
'second line stays with its id, and anything before the first number is ignored. A number that was
'already used, or a number appearing as part of the translation itself, is treated as text of the
'current item instead of starting a new one.
Private Sub parseNumberedLines(content As String,count As Int) As Map
	Dim out As Map
	out.Initialize
	Dim currentKey As String = ""
	Dim buffer As StringBuilder
	buffer.Initialize
	For Each rawLine As String In Regex.Split(CRLF,Regex.Replace("\n+",content,CRLF))
		Dim line As String = rawLine.Trim
		If line = "" Then
			Continue
		End If
		Dim m As Matcher = Regex.Matcher("^(\d+)\s*[.。．、)）:：]\s*(.*)$",line)
		Dim matched As Boolean = m.Find
		Dim idKey As String = ""
		Dim rest As String = line
		If matched Then
			idKey = m.Group(1)
			rest = m.Group(2)
		End If
		'A number starts a new item only the first time it is seen; a repeat is read as text, which
		'is what happens when the translation itself begins with something like "3.6x".
		Dim startNew As Boolean = matched And idKey <> currentKey And out.ContainsKey(idKey) = False
		If startNew Then
			If currentKey <> "" Then
				out.Put(currentKey,buffer.ToString)
			End If
			currentKey = idKey
			buffer.Initialize
			buffer.Append(rest)
		Else
			'Not a new item: keep the whole line, including anything that looked like a number, so
			'text such as "3.6x" is not cut open by the parser.
			If currentKey <> "" And line <> "" Then
				If buffer.Length > 0 Then
					buffer.Append(" ")
				End If
				buffer.Append(line)
			End If
		End If
	Next
	If currentKey <> "" Then
		out.Put(currentKey,buffer.ToString)
	End If
	Return out
End Sub

'True when the map carries every id from 1 to count, so an answer that only numbered some of the
'items is rejected rather than used.
Private Sub isComplete(m As Map,count As Int) As Boolean
	If m.IsInitialized = False Or count <= 0 Then
		Return False
	End If
	For i = 1 To count
		If m.ContainsKey("" & i) = False Then
			Return False
		End If
	Next
	Return True
End Sub

'Collapses the line breaks inside a source string, so that one item is always one line on the way out
'and cannot be split into two by a break the model copies from the source.
Private Sub OneLine(s As String) As String
	Dim t As String = s.Replace(CRLF," ").Replace("\n"," ")
	Return t.Trim
End Sub

'Reads the translations out of an answer, accepting either a JSON object keyed by id or a JSON array
'ordered like the source. Always returns an initialized map, possibly empty, so the caller can simply
'test it with hasIdKeys.
Private Sub parseKeyedValues(content As String,count As Int) As Map
	Dim result As Map = parseValuesObject(content,count)
	If hasIdKeys(result,count) Then
		Return result
	End If
	Return parseValuesArray(content,count)
End Sub

Private Sub parseValuesObject(content As String,count As Int) As Map
	Dim out As Map
	out.Initialize
	Dim start As Int = content.IndexOf("{")
	Dim e As Int = content.LastIndexOf("}")
	If start = -1 Or e <= start Then
		Return out
	End If
	Try
		Dim parser As JSONParser
		parser.Initialize(content.SubString2(start,e + 1))
		Dim result As Map = parser.NextObject
		If result.IsInitialized = False Then
			Return out
		End If
		'Unwrap a single wrapper field, as in {"translations": {"1": "..."}}.
		If hasIdKeys(result,count) = False And result.Size = 1 Then
			Dim only As Object = result.GetValueAt(0)
			If only Is Map Then
				result = only
			End If
		End If
		Return result
	Catch
		Log(LastException)
		Return out
	End Try
End Sub

Private Sub parseValuesArray(content As String,count As Int) As Map
	Dim out As Map
	out.Initialize
	Dim start As Int = content.IndexOf("[")
	Dim e As Int = content.LastIndexOf("]")
	If start = -1 Or e <= start Then
		Return out
	End If
	Try
		Dim parser As JSONParser
		parser.Initialize(content.SubString2(start,e + 1))
		Dim arr As List = parser.NextArray
		For i = 0 To arr.Size - 1
			out.Put("" & (i + 1),arr.Get(i))
		Next
	Catch
		Log(LastException)
	End Try
	Return out
End Sub

'True when the map carries at least one of the ids "1"..count, which is what marks an answer as the
'keyed JSON the default prompts ask for. A partial answer is still accepted: the ids it left out are
'filled with an empty string by the caller.
Private Sub hasIdKeys(m As Map,count As Int) As Boolean
	If m.IsInitialized = False Then
		Return False
	End If
	For i = 1 To count
		If m.ContainsKey("" & i) Then
			Return True
		End If
	Next
	Return False
End Sub

Private Sub toText(v As Object) As String
	If v = Null Then
		Return ""
	End If
	Return "" & v
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
		prompt = getMap("chatGPT",getMap("mt",preferencesMap)).GetDefault("prompt_with_term",defaultPromptWithTerm)
	Else
		prompt = getMap("chatGPT",getMap("mt",preferencesMap)).GetDefault("prompt",defaultPrompt)
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
				message.Put("content",defaultPromptWithTerm.Replace("{langcode}",$"the language whose ISO639-1 code is ${targetLang}"$).Replace("{source}",source))
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
	Dim extraFieldsStr As String = getMap("chatGPT",getMap("mt",preferencesMap)).GetDefault("extra_fields","")
	If extraFieldsStr.Trim <> "" Then
		Dim extraParser As JSONParser
		extraParser.Initialize(extraFieldsStr)
		Dim extraMap As Map = extraParser.NextObject
		For Each extraKey As String In extraMap.Keys
			params.Put(extraKey, extraMap.Get(extraKey))
		Next
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


Sub transliterate(sourceList As List, sourceLang As String, targetLang As String,preferencesMap As Map) As ResumableSub
	Dim targetList As List
	targetList.Initialize

	Dim job As HttpJob
	job.Initialize("job",Me)
	
	Dim apikey As String = getMap("chatGPT",getMap("mt",preferencesMap)).Get("key")
	Dim host As String = getMap("chatGPT",getMap("mt",preferencesMap)).GetDefault("host","https://api.openai.com/v1")
	
	Dim prompt As String
	prompt = getMap("chatGPT",getMap("mt",preferencesMap)).GetDefault("transliteration_prompt",defaultTransliterationPrompt)

	
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
				line = Regex.Replace("<p>\n+",line,"")
				line = line.Replace("<p>","")
				line = line.Replace("</p>","")
				line = ReplaceStartingNumberedStrings(line)
				line = line.Replace("\n",CRLF)
				If line.Trim = "" Then
					Continue
				End If
				line = line.Trim
				line = ReplaceStartingNumberedStrings(line)
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
