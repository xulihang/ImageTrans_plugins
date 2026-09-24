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
			wait for (GetTextFromWholeImage(Params.Get("img"),Params.Get("boxes"))) complete (success As Boolean)
			Return success
		Case "isLLMOCR"
			Return True
		Case "getDefaultParamValues"
			Return CreateMap("prompt": defaultPrompt, _
			                 "prompt_location": defaultLocalizationPrompt, _
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
'Returns True only when every box got a text; boxes that the model skipped keep their old text.
Sub GetTextFromWholeImage(annotatedImg As B4XBitmap, boxes As List) As ResumableSub
	Dim count As Int = boxes.Size
	Dim filled As Int = 0
	If count > 0 Then
		wait for (requestBoxTexts(annotatedImg,count)) complete (texts As Map)
		Dim missing As List
		missing.Initialize
		For i = 0 To count - 1
			Dim key As String = "" & (i + 1)
			Dim box As Map = boxes.Get(i)
			If texts.ContainsKey(key) Then
				box.Put("text",texts.Get(key))
				filled = filled + 1
			Else
				missing.Add(key)
			End If
		Next
		If missing.Size > 0 Then
			Log("Missing texts for " & missing.Size & " of " & count & " boxes: " & missing)
		End If
	End If
	If count > 0 And filled = count Then
		Return True
	End If
	Return False
End Sub

'Sends the annotated image and returns a map of id to text, or an empty map on any failure.
Sub requestBoxTexts(annotatedImg As B4XBitmap, count As Int) As ResumableSub
	Dim texts As Map
	texts.Initialize
	Dim config As Map = readChatGPTOCRConfig("prompt_whole_image",defaultWholeImagePrompt)
	Dim prompt As String = config.Get("prompt")
	If prompt.Trim = "" Then
		prompt = defaultWholeImagePrompt
	End If
	prompt = prompt.Replace("{N}","" & count)
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
		Catch
			Log(LastException)
		End Try
	End If
	job.Release
	Return texts
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
		map1.Put("key","")
		map1.Put("host","https://api.deepseek.com/v1")
		map1.Put("model","deepseek-v4-flash")
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
