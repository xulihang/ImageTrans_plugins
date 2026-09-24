B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=4.2
@EndOfDesignText@
Sub Class_Globals
	Private fx As JFX
	Private defaultPrompt As String = $"Extract the text in the image (please only return the text)"$
	Private defaultLocalizationPrompt As String = $"Please return the text and coordinate information from the image as a JSON array. Each element must contain two fields: bbox_2d (an integer array in the format [x1, y1, x2, y2]) and text_content (a string)."$
	Private defaultWholeImagePrompt As String = $"This image has numbered text areas marked on it.

Annotation convention:
- Each text area is outlined by a red rectangle.
- The ID of an area is the red number in a white square placed next to its rectangle: to the left of the rectangle when the rectangle is wider than it is tall, above the rectangle when it is taller than it is wide.
- The rectangles and their ID numbers are annotations, not page content. Never include the ID digits in the recognized text.

Task: recognize the text inside every marked area, with IDs 1 through {N}.
- Read each area in the natural reading order of its language: vertical text top-to-bottom and right-to-left, horizontal text left-to-right then top-to-bottom.
- Return the text exactly as it appears, in its original language. Do not translate, transliterate, or normalize it.
- If an area contains several lines of one sentence, join them into one continuous string, using a space where the language separates words. Do not output line breaks.
- If an area contains no readable text, use an empty string.
- When a character is ambiguous, choose the most plausible reading.

Response contract: return one JSON object with exactly one field, and nothing else.
- "texts": an object containing every ID from 1 to {N} exactly once, mapped to a string.

Return only the JSON object. Do not wrap it in markdown, do not add explanations, and do not add, omit, rename, renumber, or coerce any ID or value."$
	Private defaultWholeImageTranslatePrompt As String = $"This image has numbered text areas marked on it.

Annotation convention:
- Each text area is outlined by a red rectangle.
- The ID of an area is the red number in a white square placed next to its rectangle: to the left of the rectangle when the rectangle is wider than it is tall, above the rectangle when it is taller than it is wide.
- The rectangles and their ID numbers are annotations, not page content. Never include the ID digits in the recognized text.

Task: for every marked area, with IDs 1 through {N}, recognize the text and translate it into {targetLang}.
- Read each area in the natural reading order of its language: vertical text top-to-bottom and right-to-left, horizontal text left-to-right then top-to-bottom.
- Recognize each area exactly as it appears, in its original language, for the "texts" field. Do not normalize it.
- If an area contains several lines of one sentence, join them into one continuous string, using a space where the language separates words. Do not output line breaks.
- Translate each recognized text into {targetLang} for the "targets" field. Translate the meaning, not word by word. Keep the original number of sentences. Do not add explanations, notes, or the source text.
- If an area contains no readable text, use an empty string for both fields.
- When a character is ambiguous, choose the most plausible reading.

Response contract: return one JSON object with exactly two fields, and nothing else.
- "texts": an object containing every ID from 1 to {N} exactly once, mapped to the recognized source text.
- "targets": an object containing every ID from 1 to {N} exactly once, mapped to the {targetLang} translation of that ID's text.

Return only the JSON object. Do not wrap it in markdown, do not add explanations, and do not add, omit, rename, renumber, or coerce any ID or value."$
	'Appended to the prompt when sort_reading_order is on. It restates the final rule at its own
	'end, so that a guard clause is still the last thing the model reads.
	Private readingOrderRequirement As String = $"Additional requirement, which extends the response contract above: also return the natural reading order of the marked areas.
- "order": an array containing every id from 1 to {N} exactly once, in reading order. Reading order is right to left then top to bottom for right-to-left text, and left to right then top to bottom otherwise. Follow the intended order of the page rather than the position on the screen.

The response object therefore contains one more field than described above. Everything else in the contract is unchanged, including this final rule: return only the JSON object, do not wrap it in markdown, do not add explanations, and do not add, omit, rename, renumber, or coerce any ID or value."$
End Sub

'Initializes the object. You can NOT add parameters to this method!
Public Sub Initialize() As String
	Log("Initializing plugin " & GetNiceName)
	' Here return a key to prevent running unauthorized plugins
	Return "MyKey"
End Sub

' must be available
public Sub GetNiceName() As String
	Return "chatGPTOCROCR"
End Sub

' must be available
public Sub Run(Tag As String, Params As Map) As ResumableSub
	Select Tag
		Case "getParams"
			Dim paramsList As List
			paramsList.Initialize
			paramsList.Add("key")
			paramsList.Add("prompt")
			paramsList.Add("prompt_location")
			paramsList.Add("prompt_whole_image")
			paramsList.Add("prompt_whole_image_translate")
			paramsList.Add("sort_reading_order")
			paramsList.Add("host")
			paramsList.Add("model")
			paramsList.Add("extra_fields")
			Return paramsList
		Case "getText"
			wait for (GetText(Params.Get("img"))) complete (result As String)
			Return result
		Case "getTextWithLocation"
			wait for (GetTextWithLocation(Params.Get("img"))) complete (regions As List)
			Return regions
		Case "getTextFromWholeImage"
			Dim translate As Boolean = toBoolean(Params.Get("translate"),False)
			Dim targetLang As String = toText(Params.Get("targetLang"))
			wait for (GetTextFromWholeImage(Params.Get("img"),Params.Get("boxes"),translate,targetLang)) complete (success As Boolean)
			Return success
		Case "isLLMOCR"
			Return True
		Case "getDefaultParamValues"
			Return CreateMap("prompt": defaultPrompt, _
			                 "prompt_location": defaultLocalizationPrompt, _
			                 "prompt_whole_image": defaultWholeImagePrompt, _
			                 "prompt_whole_image_translate": defaultWholeImageTranslatePrompt, _
			                 "sort_reading_order":"false", _
			                 "host":"https://api.openai.com/v1", _
							 "model":"gpt-4o")
	End Select
	Return ""
End Sub


Sub GetText(img As B4XBitmap) As ResumableSub
	wait for (ocr(img,True)) complete (text As String)
	Return text
End Sub

Sub GetTextWithLocation(img As B4XBitmap) As ResumableSub
	wait for (ocr(img,False)) complete (regions As List)
	Return regions
End Sub

'The caller passes the page with its boxes already annotated with ids. The model returns the
'text of each id and the texts are written back to the boxes. How the ids are drawn is the
'caller's concern and must match the annotation convention described in the prompt.
'When translate is True and targetLang is not empty, the boxes also get a "target" filled with
'the translation of their text, in the same single request.
'When the sort_reading_order setting is on, the model also returns the reading order and the
'boxes list is reordered in place to follow it. An unusable order is ignored, never guessed at:
'the texts are still written, only the order is left alone.
'Returns True only when every box got a text, and, when translating, also a target.
Sub GetTextFromWholeImage(annotatedImg As B4XBitmap, boxes As List, translate As Boolean, targetLang As String) As ResumableSub
	Dim count As Int = boxes.Size
	Dim lang As String = targetLang.Trim
	Dim doTranslate As Boolean = translate And lang <> ""
	If translate And doTranslate = False Then
		Log("Translation was requested but targetLang is empty, only recognizing text.")
	End If
	Dim filled As Int = 0
	Dim translated As Int = 0
	If count > 0 Then
		wait for (requestBoxTexts(annotatedImg,count,doTranslate,lang)) complete (response As Map)
		Dim texts As Map = response.Get("texts")
		Dim targets As Map = response.Get("targets")
		Dim order As List = response.Get("order")
		Dim missing As List
		missing.Initialize
		Dim missingTargets As List
		missingTargets.Initialize
		For i = 0 To count - 1
			Dim key As String = "" & (i + 1)
			Dim box As Map = boxes.Get(i)
			If texts.ContainsKey(key) Then
				If box.GetDefault("text","") == "" Then
					box.Put("text",texts.Get(key))
				End If
				filled = filled + 1
			Else
				missing.Add(key)
			End If
			If doTranslate Then
				If targets.ContainsKey(key) Then
					If box.GetDefault("target","") == "" Then
						box.Put("target",targets.Get(key))
					End If
					translated = translated + 1
				Else
					missingTargets.Add(key)
				End If
			End If
		Next
		If missing.Size > 0 Then
			Log("Missing texts for " & missing.Size & " of " & count & " boxes: " & missing)
		End If
		If doTranslate And missingTargets.Size > 0 Then
			Log("Missing translations for " & missingTargets.Size & " of " & count & " boxes: " & missingTargets)
		End If
		'Filling above is done by index, so reordering has to come after it.
		If order.IsInitialized And order.Size > 0 Then
			If validOrder(order,count) Then
				Dim byId As Map
				byId.Initialize
				For i = 0 To count - 1
					byId.Put("" & (i + 1),boxes.Get(i))
				Next
				boxes.Clear
				For i = 0 To order.Size - 1
					boxes.Add(byId.Get(order.Get(i)))
				Next
				Log("Reordered " & count & " boxes by the reading order returned by the model.")
			Else
				Log("The model returned an unusable reading order, the box order is unchanged.")
			End If
		End If
	End If
	If count > 0 And filled = count And (doTranslate = False Or translated = count) Then
		Return True
	End If
	Return False
End Sub

'Sends the annotated image and returns a map with the "texts" and "targets" id to string maps
'and the "order" list of ids. All three are always present, and all are empty when the request
'or the parsing failed. "order" is only ever filled when sort_reading_order is on.
Sub requestBoxTexts(annotatedImg As B4XBitmap, count As Int, translate As Boolean, targetLang As String) As ResumableSub
	Dim texts As Map
	texts.Initialize
	Dim targets As Map
	targets.Initialize
	Dim order As List
	order.Initialize
	Dim promptKey As String
	Dim fallbackPrompt As String
	If translate Then
		promptKey = "prompt_whole_image_translate"
		fallbackPrompt = defaultWholeImageTranslatePrompt
	Else
		promptKey = "prompt_whole_image"
		fallbackPrompt = defaultWholeImagePrompt
	End If
	Dim config As Map = readChatGPTOCRConfig(promptKey,fallbackPrompt)
	Dim sortReadingOrder As Boolean = toBoolean(config.Get("sort_reading_order"),False)
	Dim prompt As String = config.Get("prompt")
	If prompt.Trim = "" Then
		prompt = fallbackPrompt
	End If
	If sortReadingOrder Then
		prompt = prompt & CRLF & CRLF & readingOrderRequirement
	End If
	prompt = prompt.Replace("{N}","" & count)
	prompt = prompt.Replace("{targetLang}",targetLang)
	saveImgToDiskWithSizeCheck(annotatedImg,100,5000000)
	Dim su As StringUtils
	Dim base64 As String=su.EncodeBase64(File.ReadBytes(File.DirApp,"image.jpg"))
	Dim promptPart As Map
	promptPart.Initialize
	promptPart.Put("type","text")
	promptPart.Put("text",prompt)
	Dim urlMap As Map
	urlMap.Initialize
	urlMap.Put("url","data:image/jpeg;base64,"&base64)
	urlMap.Put("detail","high")
	Dim imagePart As Map
	imagePart.Initialize
	imagePart.Put("type","image_url")
	imagePart.Put("image_url",urlMap)
	Dim contentList As List
	contentList.Initialize
	contentList.Add(promptPart)
	contentList.Add(imagePart)
	Dim userMessage As Map
	userMessage.Initialize
	userMessage.Put("role","user")
	userMessage.Put("content",contentList)
	Dim messages As List
	messages.Initialize
	messages.Add(userMessage)
	Dim params As Map
	params.Initialize
	params.Put("model",config.Get("model"))
	params.Put("messages",messages)
	params.Put("temperature",0)
	Dim extraFieldsStr As String = config.Get("extra_fields")
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
	Dim host As String = config.Get("host")
	Dim apikey As String = config.Get("key")
	Dim url As String = host&"/chat/completions"
	Dim job As HttpJob
	job.Initialize("boxocr",Me)
	job.PostString(url,jsonG.ToString)
	Log(jsonG.ToString)
	job.GetRequest.Timeout = 1200000
	job.GetRequest.SetContentType("application/json")
	job.GetRequest.SetHeader("Authorization","Bearer "&apikey)
	wait For (job) JobDone(job As HttpJob)
	If job.Success Then
		Try
			Log(job.GetString)
			Dim json As JSONParser
			json.Initialize(job.GetString)
			Dim response As Map = json.NextObject
			Dim choices As List = response.Get("choices")
			Dim choice As Map = choices.Get(0)
			Dim responseMessage As Map = choice.Get("message")
			Dim content As String = responseMessage.Get("content")
			Dim parser As JSONParser
			parser.Initialize(ExtractJSONObject(content))
			Dim result As Map = parser.NextObject
			If result.ContainsKey("texts") Then
				Dim parsedTexts As Map = result.Get("texts")
				For Each key As String In parsedTexts.Keys
					texts.Put(key,parsedTexts.Get(key))
				Next
			End If
			If result.ContainsKey("targets") Then
				Dim parsedTargets As Map = result.Get("targets")
				For Each key As String In parsedTargets.Keys
					targets.Put(key,parsedTargets.Get(key))
				Next
			End If
			If result.ContainsKey("order") Then
				Dim parsedOrder As List = result.Get("order")
				For i = 0 To parsedOrder.Size - 1
					'Ids may come back as numbers rather than strings, so normalize them here and
					'leave every other judgement to validOrder.
					order.Add(toText(parsedOrder.Get(i)))
				Next
			End If
		Catch
			Log(LastException)
		End Try
	End If
	job.Release
	Return CreateMap("texts":texts,"targets":targets,"order":order)
End Sub

'True when the ids form exactly the set 1..N, each of them once. A partly valid order is worse
'than no order at all, so anything unexpected is rejected rather than repaired.
Private Sub validOrder(order As List,count As Int) As Boolean
	If order.IsInitialized = False Then
		Return False
	End If
	If order.Size <> count Then
		Return False
	End If
	Dim seen As Map
	seen.Initialize
	For i = 0 To order.Size - 1
		Dim key As String = toText(order.Get(i))
		If seen.ContainsKey(key) Then
			Return False
		End If
		seen.Put(key,True)
	Next
	For i = 0 To count - 1
		If seen.ContainsKey("" & (i + 1)) = False Then
			Return False
		End If
	Next
	Return True
End Sub

'Params may carry a Boolean or a string, and may be missing; anything unclear means default.
Private Sub toBoolean(v As Object, defaultValue As Boolean) As Boolean
	If v Is Boolean Then
		Return v
	End If
	If v = Null Then
		Return defaultValue
	End If
	Dim s As String = "" & v
	If s.ToLowerCase = "true" Then
		Return True
	End If
	If s.ToLowerCase = "false" Then
		Return False
	End If
	Return defaultValue
End Sub

Private Sub toText(v As Object) As String
	If v = Null Then
		Return ""
	End If
	Return "" & v
End Sub

'Keeps only the outermost JSON object, so that code fences or a sentence before the JSON
'do not break parsing.
Private Sub ExtractJSONObject(s As String) As String
	Dim start As Int = s.IndexOf("{")
	Dim e As Int = s.LastIndexOf("}")
	If start > -1 And e > start Then
		Return s.SubString2(start,e + 1)
	End If
	Return s.Trim
End Sub

'Reads the chatGPTOCR section of preferences.conf, falling back to the same defaults as ocr.
Private Sub readChatGPTOCRConfig(promptKey As String,fallbackPrompt As String) As Map
	Dim preferencesMap As Map
	If File.Exists(File.DirApp,"preferences.conf") Then
		preferencesMap = readJsonAsMap(File.ReadString(File.DirApp,"preferences.conf"))
	Else
		Dim map1 As Map
		map1.Initialize
		map1.Put("key","sk-")
		map1.Put("host","https://api.deepseek.com/v1")
		map1.Put("model","deepseek-v4-flash")
		'map1.Put("sort_reading_order","true")
		'map1.Put("extra_fields",$"{"thinking":{"type": "disabled"}}"$)
		map1.Put("extra_fields",$"{}"$)
		preferencesMap = CreateMap("api":CreateMap("chatGPTOCR":map1))
	End If
	Dim apiRoot As Map = getMap("api",preferencesMap)
	If apiRoot.IsInitialized = False Then
		apiRoot.Initialize
	End If
	Dim api As Map = getMap("chatGPTOCR",apiRoot)
	If api.IsInitialized = False Then
		api.Initialize
	End If
	Return CreateMap( _
		"key":api.GetDefault("key",""), _
		"host":api.GetDefault("host","https://api.openai.com/v1"), _
		"model":api.GetDefault("model","gpt-4o"), _
		"extra_fields":api.GetDefault("extra_fields",""), _
		"sort_reading_order":api.GetDefault("sort_reading_order","false"), _
		"prompt":api.GetDefault(promptKey,fallbackPrompt))
End Sub

Sub ocr(img As B4XBitmap,textOnly As Boolean) As ResumableSub
	saveImgToDiskWithSizeCheck(img,100,5000000)
	Dim textResult As String
	Dim regions As List
	regions.Initialize
	Dim job As HttpJob
	job.Initialize("job",Me)
	Dim preferencesMap As Map
	If File.Exists(File.DirApp,"preferences.conf") Then
		preferencesMap = readJsonAsMap(File.ReadString(File.DirApp,"preferences.conf"))
	Else
		Dim map1 As Map
		map1.Initialize
		map1.Put("key","")
		map1.Put("host","https://dashscope.aliyuncs.com/compatible-mode/v1")
		map1.Put("model","qwen3.6-plus")
		'map1.Put("prompt","/set nothink Extract the text in the image (please only return the text)")
		map1.Put("extra_fields",$"{"enable_thinking":false}"$)
		preferencesMap = CreateMap("api":CreateMap("chatGPTOCR":map1))
	End If
	Dim apikey As String = getMap("chatGPTOCR",getMap("api",preferencesMap)).Get("key")
	Dim host As String = getMap("chatGPTOCR",getMap("api",preferencesMap)).GetDefault("host","https://api.openai.com/v1")
	Dim model As String = getMap("chatGPTOCR",getMap("api",preferencesMap)).GetDefault("model","gpt-4o")
	Dim prompt As String
	If textOnly Then
		prompt = getMap("chatGPTOCR",getMap("api",preferencesMap)).GetDefault("prompt",defaultPrompt)
	Else
		prompt = getMap("chatGPTOCR",getMap("api",preferencesMap)).GetDefault("prompt_location",defaultLocalizationPrompt)
	End If
	Dim url As String = host&"/chat/completions"
	
	Dim contentList As List
	contentList.Initialize
	Dim messages As List
	messages.Initialize
	Dim message As Map
	message.Initialize
	message.Put("role","user")
	Dim text As Map
	text.Initialize
	text.Put("type","text")
	text.Put("text",prompt)
	Dim su As StringUtils
	Dim base64 As String=su.EncodeBase64(File.ReadBytes(File.DirApp,"image.jpg"))
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
	Dim extraFieldsStr As String = getMap("chatGPTOCR",getMap("api",preferencesMap)).GetDefault("extra_fields","")
	If extraFieldsStr.Trim <> "" Then
		Dim extraParser As JSONParser
		extraParser.Initialize(extraFieldsStr)
		Dim extraMap As Map = extraParser.NextObject
		For Each extraKey As String In extraMap.Keys
			params.Put(extraKey, extraMap.Get(extraKey))
		Next
	End If
	Dim jsonG As JSONGenerator
	jsonG.Initialize(params)
	job.PostString(url,jsonG.ToString)
	Log(jsonG.ToString)
	job.GetRequest.Timeout = 1200000
	job.GetRequest.SetContentType("application/json")
	job.GetRequest.SetHeader("Authorization","Bearer "&apikey)
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
			Dim result As String = message.Get("content")
			If textOnly Then
				textResult = result
			Else
				If result.StartsWith("```json") Then
					result = result.Replace("```json","")
					result = result.Replace("```","")
				End If
				Dim parser As JSONParser
				parser.Initialize(result)
				Dim boxes As List = parser.NextArray
				For Each box As Map In boxes
					Dim bbox As List = box.Get("bbox_2d")
					Dim region As Map
					region.Initialize
					region.Put("text",box.Get("text_content"))
					region.Put("X",bbox.Get(0)/1000*img.Width)
					region.Put("Y",bbox.Get(1)/1000*img.Height)
					region.Put("width",(bbox.Get(2)-bbox.Get(0))/1000*img.Width)
					region.Put("height",(bbox.Get(3)-bbox.Get(1))/1000*img.Height)
					regions.Add(region)
				Next
			End If
		Catch
			Log(LastException)
		End Try
	End If
	job.Release
	If textOnly Then
		Return textResult
	Else
		Return regions
	End If
End Sub

Sub readJsonAsMap(s As String) As Map
	Dim json As JSONParser
	json.Initialize(s)
	Return json.NextObject
End Sub

Sub getMap(key As String,parentmap As Map) As Map
	Return parentmap.Get(key)
End Sub

Sub saveImgToDiskWithSizeCheck(img As B4XBitmap,quality As Int, sizeLimit As Int)
	Dim imgPath As String=File.Combine(File.DirApp,"image.jpg")
	Dim out As OutputStream=File.OpenOutput(imgPath,"",False)
	img.WriteToStream(out,quality,"JPEG")
	out.Close
	Dim su As StringUtils
	Dim base64 As String=su.EncodeBase64(File.ReadBytes(File.DirApp,"image.jpg"))
	If base64.Length>sizeLimit Then
		Log("bigger than limit")
		If quality>=10 Then
			saveImgToDiskWithSizeCheck(img,quality-10,sizeLimit)
		End If
	End If
End Sub
