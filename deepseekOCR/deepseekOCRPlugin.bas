B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=4.2
@EndOfDesignText@
Sub Class_Globals
	Private fx As JFX
	Private defaultOCRPrompt As String = "<image>\nFree OCR."
	Private defaultOCRWithLocationPrompt As String = "<image>\n<|grounding|>OCR this image."
	Private defaultLayoutDetectionPrompt As String = "<image>\n<|grounding|>Given the layout of the image."
End Sub

'Initializes the object. You can NOT add parameters to this method!
Public Sub Initialize() As String
	Log("Initializing plugin " & GetNiceName)
	' Here return a key to prevent running unauthorized plugins
	Return "MyKey"
End Sub

' must be available
public Sub GetNiceName() As String
	Return "deepseekOCROCR"
End Sub

' must be available
public Sub Run(Tag As String, Params As Map) As ResumableSub
	Select Tag
		Case "getParams"
			Dim paramsList As List
			paramsList.Initialize
			paramsList.Add("key")
			paramsList.Add("model")
			paramsList.Add("host")
			paramsList.Add("prompt_ocr")
			paramsList.Add("prompt_ocr_with_location")
			paramsList.Add("prompt_layout_detection")
			Return paramsList
		Case "getText"
			wait for (GetText(Params.Get("img"))) complete (result As String)
			Return result
		Case "getTextWithLocation"
			wait for (GetTextWithLocation(Params.Get("img"))) complete (regions As List)
			Return regions
		Case "getLayout"
			wait for (DetectLayout(Params.Get("img"))) complete (regions As List)
			Return regions
		Case "supportLayoutDetection"
			Return True
		Case "getDefaultParamValues"
			Return CreateMap("host":"https://api.siliconflow.cn/v1", _ 
			                 "prompt_ocr":defaultOCRPrompt, _ 
			                 "prompt_ocr_with_location":defaultOCRWithLocationPrompt, _ 
                  			 "prompt_layout_detection":defaultLayoutDetectionPrompt, _ 
			                 "model":"deepseek-ai/DeepSeek-OCR")
	End Select
	Return ""
End Sub

Sub DetectLayout(img As B4XBitmap) As ResumableSub
	wait for (ocr(img,"layout_detection")) complete (regions As List)
	Return regions
End Sub

Sub GetText(img As B4XBitmap) As ResumableSub
	wait for (ocr(img,"ocr")) complete (text As String)
	Return text
End Sub

Sub GetTextWithLocation(img As B4XBitmap) As ResumableSub
	wait for (ocr(img,"ocr_with_location")) complete (regions As List)
	Return regions
End Sub

Sub ocr(img As B4XBitmap,actionType As String) As ResumableSub
	saveImgToDiskWithSizeCheck(img,100,5000000)
	Dim regions As List
	regions.Initialize
	Dim job As HttpJob
	job.Initialize("job",Me)
	Dim preferencesMap As Map
	If File.Exists(File.DirApp,"preferences.conf") Then
		preferencesMap = readJsonAsMap(File.ReadString(File.DirApp,"preferences.conf"))
	Else
		'for test
		Dim map1 As Map
		map1.Initialize
		map1.Put("key","")
		map1.Put("host","http://127.0.0.1:8000/v1")
		map1.Put("model","deepseek-ocr")
		map1.Put("prompt_ocr","OCR")
		map1.Put("prompt_layout_detection","<|grounding|>Given the layout of the image.")
		preferencesMap = CreateMap("api":CreateMap("deepseekOCR":map1))
	End If
	Dim apikey As String = getMap("deepseekOCR",getMap("api",preferencesMap)).Get("key")
	Dim host As String = getMap("deepseekOCR",getMap("api",preferencesMap)).GetDefault("host","https://api.openai.com/v1")
	Dim model As String = getMap("deepseekOCR",getMap("api",preferencesMap)).GetDefault("model","deepseek-ai/DeepSeek-OCR")
	Dim url As String = host&"/chat/completions"
	
	Dim prompt As String
	
	If actionType = "ocr" Then
		prompt = getMap("deepseekOCR",getMap("api",preferencesMap)).GetDefault("prompt_ocr",defaultOCRPrompt)
	else if actionType = "ocr_with_location" Then
		prompt = getMap("deepseekOCR",getMap("api",preferencesMap)).GetDefault("prompt_ocr_with_location",defaultOCRWithLocationPrompt)
	Else
		prompt = getMap("deepseekOCR",getMap("api",preferencesMap)).GetDefault("prompt_layout_detection",defaultLayoutDetectionPrompt)
	End If
	
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
	contentList.Add(image)
	contentList.Add(text)
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
	job.GetRequest.SetContentType("application/json")
	job.GetRequest.SetHeader("Authorization","Bearer "&apikey)
	job.GetRequest.Timeout = 1200000*1000
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
			If actionType="layout_detection" Then
				regions = ProcessLayout(result,img.Width,img.Height)
			else if actionType="ocr_with_location" Then
				regions = ProcessTextWithLocation(result,img.Width,img.Height)
			End If
		Catch
			Log(LastException)
		End Try
	Else
		Log(job.ErrorMessage)
	End If
	job.Release
	If actionType = "ocr" Then
		Return result
	Else
		Return regions
	End If
End Sub

private Sub ProcessTextWithLocation(rawData As String,imgWidth As Int,imgHeight As Int) As List
    
	Dim boxes As List
	boxes.Initialize
    
	' 分割每一行
	Dim lines As List
	lines.Initialize
	lines = Regex.Split(CRLF, rawData)
    
	For Each line As String In lines
		line = line.Trim
		If line.Length = 0 Then Continue
        
		' 检查是否包含 <|ref|> 和 <|det|> 标记
		If line.Contains("<|ref|>") And line.Contains("<|det|>") Then
			' 提取文本内容（在 <|ref|> 和 <|/ref|> 之间）
			Dim textStart As Int = line.IndexOf("<|ref|>") + 7
			Dim textEnd As Int = line.IndexOf("<|/ref|>")
            
			If textStart > 6 And textEnd > textStart Then
				Dim textContent As String = line.SubString2(textStart, textEnd).Trim
                
				' 只处理包含文字的项（跳过 Initializing plugin 等）
				If textContent.Length > 0 Then
					' 提取坐标数据
					Dim detStart As Int = line.IndexOf("[[") + 2
					Dim detEnd As Int = line.IndexOf("]]")
                    
					If detStart > 1 And detEnd > detStart Then
						Dim coordStr As String = line.SubString2(detStart, detEnd)
						Dim coords() As String = Regex.Split(", ", coordStr)
                        
						If coords.Length = 4 Then
							' 解析原始坐标
							Dim x1 As Float = coords(0)
							Dim y1 As Float = coords(1)
							Dim x2 As Float = coords(2)
							Dim y2 As Float = coords(3)
                            
							' 归一化处理（除以999再乘以图像尺寸）
							x1 = x1 / 999 * imgWidth
							y1 = y1 / 999 * imgHeight
							x2 = x2 / 999 * imgWidth
							y2 = y2 / 999 * imgHeight
                            
							' 计算宽度和高度
							Dim width As Float = x2 - x1
							Dim height As Float = y2 - y1
                            
							' 创建 box 映射，包含文本内容和坐标信息
							Dim box As Map
							box.Initialize
							box.Put("text", textContent)
							box.Put("X", x1)
							box.Put("Y", y1)
							box.Put("width", width)
							box.Put("height", height)
                            
							' 添加原始坐标（可选）
							box.Put("original", CreateMap("x1": coords(0), "y1": coords(1), "x2": coords(2), "y2": coords(3)))
                            
							' 添加到列表
							boxes.Add(box)
						End If
					End If
				End If
			End If
		End If
	Next
    
	' 返回结果
	Return boxes
End Sub

private Sub ProcessLayout(rawData As String,imgWidth As Int,imgHeight As Int) As List
        
	Dim boxes As List
	boxes.Initialize
    
	' 分割每一行
	Dim lines As List
	lines.Initialize
	lines = Regex.Split(CRLF, rawData)
    
	For Each line As String In lines
		line = line.Trim
		If line.Length = 0 Then Continue
        
		' 检查是否不是图片
		If line.Contains("<|ref|>image<|/ref|>") = False Then
			' 提取坐标数据
			Dim startIndex As Int = line.IndexOf("[[") + 2
			Dim endIndex As Int = line.IndexOf("]]")
            
			If startIndex > 1 And endIndex > startIndex Then
				Dim coordStr As String = line.SubString2(startIndex, endIndex)
				Dim coords() As String = Regex.Split(", ", coordStr)
                
				If coords.Length = 4 Then
					' 解析原始坐标
					Dim x1 As Float = coords(0)
					Dim y1 As Float = coords(1)
					Dim x2 As Float = coords(2)
					Dim y2 As Float = coords(3)
                    
					' 归一化处理
					x1 = x1 / 999 * imgWidth
					y1 = y1 / 999 * imgHeight
					x2 = x2 / 999 * imgWidth
					y2 = y2 / 999 * imgHeight
                    
					' 计算宽度和高度
					Dim width As Float = x2 - x1
					Dim height As Float = y2 - y1
                    
					' 创建 box 映射
					Dim box As Map
					box.Initialize
					box.Put("X", x1)
					box.Put("Y", y1)
					box.Put("width", width)
					box.Put("height", height)
                    box.Put("text","")
					' 添加到列表
					boxes.Add(box)
				End If
			End If
		End If
	Next
    
	' 返回结果
	Return boxes
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
