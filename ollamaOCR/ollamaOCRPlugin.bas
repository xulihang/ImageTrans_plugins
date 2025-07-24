B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=4.2
@EndOfDesignText@
Sub Class_Globals
	Private fx As JFX
	Private defaultPrompt As String = $"Extract the text in the image (please only return the text)"$
	Private defaultLocalizationPrompt As String = $"Extract the text in the image (please return the text and the coordinates in the following JSON format example: [{text:'text',bbox:{x:0,y:0,width:0,height:0}])"$
End Sub

'Initializes the object. You can NOT add parameters to this method!
Public Sub Initialize() As String
	Log("Initializing plugin " & GetNiceName)
	' Here return a key to prevent running unauthorized plugins
	Return "MyKey"
End Sub

' must be available
public Sub GetNiceName() As String
	Return "ollamaOCROCR"
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
			paramsList.Add("host")
			paramsList.Add("model")
			Return paramsList
		Case "getText"
			wait for (GetText(Params.Get("img"))) complete (result As String)
			Return result
		Case "getTextWithLocation"
			wait for (GetTextWithLocation(Params.Get("img"))) complete (regions As List)
			Return regions
		Case "getDefaultParamValues"
			Return CreateMap("prompt": defaultPrompt, _
			                 "prompt_location": defaultLocalizationPrompt, _
							 "host":"http://localhost:11434/v1", _
							 "model":"qwen2.5vl:3b")
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
		preferencesMap = CreateMap("api":CreateMap("ollamaOCR":map1))
	End If
	Dim apikey As String = getMap("ollamaOCR",getMap("api",preferencesMap)).Get("key")
	Dim host As String = getMap("ollamaOCR",getMap("api",preferencesMap)).GetDefault("host","http://localhost:11434/v1")
	Dim model As String = getMap("ollamaOCR",getMap("api",preferencesMap)).GetDefault("model","qwen2.5vl:3b")
	Dim prompt As String
	If textOnly Then
		prompt = getMap("ollamaOCR",getMap("api",preferencesMap)).GetDefault("prompt",defaultPrompt)
	Else
		prompt = getMap("ollamaOCR",getMap("api",preferencesMap)).GetDefault("prompt_location",defaultLocalizationPrompt)
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
					Dim bbox As Map = box.Get("bbox")
					Dim region As Map
					region.Initialize
					region.Put("text",box.Get("text"))
					region.Put("X",bbox.Get("x"))
					region.Put("Y",bbox.Get("y"))
					region.Put("width",bbox.Get("width"))
					region.Put("height",bbox.Get("height"))
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
