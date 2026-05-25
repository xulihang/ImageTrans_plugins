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
	Return "mineruOCR"
End Sub

' must be available
public Sub Run(Tag As String, Params As Map) As ResumableSub
	Select Tag
		Case "getParams"
			Dim paramsList As List
			paramsList.Initialize
			paramsList.Add("key")
			paramsList.Add("host")
			paramsList.Add("is_ocr")
			paramsList.Add("enable_formula")
			paramsList.Add("enable_table")
			paramsList.Add("language")
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
			Return CreateMap("host":"https://mineru.net/api/v4", _
			                 "is_ocr":"true", _
			                 "enable_formula":"true", _
			                 "enable_table":"true", _
			                 "language":"ch")
	End Select
	Return ""
End Sub

Sub DetectLayout(img As B4XBitmap) As ResumableSub
	wait for (parse(img, True)) complete (result As Map)
	Dim layout As List =  result.Get("layout")
	Return layout
End Sub

Sub GetText(img As B4XBitmap) As ResumableSub
	wait for (parse(img, False)) complete (result As Map)
	Return result.Get("text")
End Sub

Sub GetTextWithLocation(img As B4XBitmap) As ResumableSub
	wait for (parse(img, True)) complete (result As Map)
	Dim textWithLocationList As List =  result.Get("textWithLocation")
	Return textWithLocationList
End Sub

Sub parse(img As B4XBitmap, includeLocation As Boolean) As ResumableSub
	saveImgToDiskWithSizeCheck(img, 100, 5000000)

	Dim preferencesMap As Map
	If File.Exists(File.DirApp, "preferences.conf") Then
		preferencesMap = readJsonAsMap(File.ReadString(File.DirApp, "preferences.conf"))
	Else
		Dim map1 As Map
		map1.Initialize
		map1.Put("key", "")
		map1.Put("host", "https://mineru.net/api/v4")
		map1.Put("is_ocr", "true")
		map1.Put("enable_formula", "true")
		map1.Put("enable_table", "true")
		map1.Put("language", "ch")
		preferencesMap = CreateMap("api":CreateMap("mineru":map1))
	End If
	Log(preferencesMap)
	Dim apiMap As Map = getMap("mineru", getMap("api", preferencesMap))
	Dim apikey As String = apiMap.GetDefault("key", "")
	Dim host As String = apiMap.GetDefault("host", "https://mineru.net/api/v4")
	Dim isOcrStr As String = apiMap.GetDefault("is_ocr", "true")
	Dim enableFormulaStr As String = apiMap.GetDefault("enable_formula", "true")
	Dim enableTableStr As String = apiMap.GetDefault("enable_table", "true")
	Dim language As String = apiMap.GetDefault("language", "ch")

	Dim isOcr As Boolean = (isOcrStr = "true")
	Dim enableFormula As Boolean = (enableFormulaStr = "true")
	Dim enableTable As Boolean = (enableTableStr = "true")
	Dim isCloudApi As Boolean = host.Contains("mineru.net")

	Dim resultText As String
	Dim textWithLocation As List
	textWithLocation.Initialize
	Dim layout As List
	layout.Initialize

	Dim finalResult As Map
	finalResult.Initialize

	Dim imgW As Int = img.Width
	Dim imgH As Int = img.Height

	If isCloudApi Then
		wait for (parseViaCloudApi(host, apikey, isOcr, enableFormula, enableTable, language, imgW, imgH)) complete (cloudResult As Map)
		resultText = cloudResult.Get("text")
		textWithLocation = cloudResult.Get("textWithLocation")
		layout = textWithLocation
	Else
		wait for (parseViaFileParse(host, isOcr, enableFormula, enableTable, language, imgW, imgH)) complete (localResult As Map)
		resultText = localResult.Get("text")
		textWithLocation = localResult.Get("textWithLocation")
		layout = localResult.Get("textWithLocation")
	End If

	finalResult.Put("text", resultText)
	finalResult.Put("textWithLocation", textWithLocation)
	finalResult.Put("layout", layout)
	Return finalResult
End Sub

Sub parseViaFileParse(host As String, isOcr As Boolean, enableFormula As Boolean, enableTable As Boolean, language As String, imgWidth As Int, imgHeight As Int) As ResumableSub
	Dim resultText As String = ""
	Dim textWithLocation As List
	textWithLocation.Initialize

	Dim resultMap As Map
	resultMap.Initialize

	Dim url As String = host
	If url.EndsWith("/") Then url = url.SubString2(0, url.Length - 1)
	url = url & "/file_parse"

	Dim job As HttpJob
	job.Initialize("job", Me)

	Dim fd As MultipartFileData
	fd.Initialize
	fd.Dir = File.DirApp
	fd.FileName = "image.jpg"
	fd.KeyName = "files"
	fd.ContentType = "image/jpeg"

	Dim nameValues As Map
	nameValues.Initialize
	If isOcr Then nameValues.Put("is_ocr", "true")
	If enableFormula Then nameValues.Put("formula_enable", "true")
	If enableTable Then nameValues.Put("table_enable", "true")
	nameValues.Put("lang_list", language)
	nameValues.Put("return_content_list", "true")
	nameValues.Put("return_md", "true")

	job.PostMultipart(url, nameValues, Array(fd))
	job.GetRequest.Timeout = 1200000 * 1000
	wait For (job) JobDone(job As HttpJob)

	If job.Success Then
		Try
			Log(job.GetString)
			Dim json As JSONParser
			json.Initialize(job.GetString)
			Dim response As Map = json.NextObject

			resultText = response.GetDefault("md", "")
			If response.ContainsKey("content_list") Then
				Dim contentList As List = response.Get("content_list")
				textWithLocation = ProcessContentList(contentList, imgWidth, imgHeight)
			End If
		Catch
			Log(LastException)
		End Try
	Else
		Log(job.ErrorMessage)
	End If
	job.Release

	resultMap.Put("text", resultText)
	resultMap.Put("textWithLocation", textWithLocation)
	Return resultMap
End Sub

Sub parseViaCloudApi(host As String, apikey As String, isOcr As Boolean, enableFormula As Boolean, enableTable As Boolean, language As String, imgWidth As Int, imgHeight As Int) As ResumableSub
	Dim resultText As String = ""
	Dim textWithLocation As List
	textWithLocation.Initialize

	Dim resultMap As Map
	resultMap.Initialize

	Dim baseUrl As String = host
	If baseUrl.EndsWith("/") Then baseUrl = baseUrl.SubString2(0, baseUrl.Length - 1)

	' Step 1: Get upload URL
	Dim batchUrl As String = baseUrl & "/file-urls/batch"
	Dim job As HttpJob
	job.Initialize("job", Me)

	Dim fileMeta As Map
	fileMeta.Initialize
	fileMeta.Put("name", "image.jpg")
	fileMeta.Put("data_id", "img_" & DateTime.Now)

	Dim files As List
	files.Initialize
	files.Add(fileMeta)

	Dim batchData As Map
	batchData.Initialize
	batchData.Put("files", files)
	batchData.Put("model_version", "vlm")

	Dim jsonG As JSONGenerator
	jsonG.Initialize(batchData)
	job.PostString(batchUrl, jsonG.ToString)
	job.GetRequest.SetContentType("application/json")
	job.GetRequest.SetHeader("Authorization", "Bearer " & apikey)
	job.GetRequest.Timeout = 1200000 * 1000
	wait For (job) JobDone(job As HttpJob)

	If job.Success = False Then
		Log("Batch upload request failed: " & job.ErrorMessage)
		job.Release
		resultMap.Put("text", resultText)
		resultMap.Put("textWithLocation", textWithLocation)
		Return resultMap
	End If

	Dim batchResponse As Map = readJsonAsMap(job.GetString)
	Log("create upload done")
	Log(batchResponse)
	
	job.Release

	Dim batchData2 As Map = batchResponse.Get("data")
	Dim fileUrls As List = batchData2.Get("file_urls")
	Dim uploadUrl As String = fileUrls.Get(0)
	Dim batchId As String = batchData2.Get("batch_id")

	' Step 2: Upload file
	Dim uploadJob As HttpJob
	uploadJob.Initialize("job", Me)
	Dim fileBytes() As Byte = File.ReadBytes(File.DirApp, "image.jpg")
	uploadJob.PutBytes(uploadUrl, fileBytes)
	uploadJob.GetRequest.SetContentType("")
	uploadJob.GetRequest.Timeout = 1200000 * 1000
	wait For (uploadJob) JobDone(uploadJob As HttpJob)
	Log("upload done")
	Log(uploadJob.Success)
	If uploadJob.Success = False Then
		Log("File upload failed: " & uploadJob.ErrorMessage)
		uploadJob.Release
		resultMap.Put("text", resultText)
		resultMap.Put("textWithLocation", textWithLocation)
		Return resultMap
	End If
	
	uploadJob.Release
	
	' Step 3: Poll for results
	'https://mineru.net/api/v4/extract-results/batch/{batch_id}
	Dim taskUrl As String = baseUrl & "/extract-results/batch/" & batchId
	Dim maxRetries As Int = 60
	Dim retryCount As Int = 0
	Dim completed As Boolean = False
	Dim taskState As String = ""

	Do While retryCount < maxRetries And completed = False
		Sleep(2000)
		Dim pollJob As HttpJob
		pollJob.Initialize("job", Me)
		pollJob.Download(taskUrl)
		pollJob.GetRequest.SetHeader("Authorization", "Bearer " & apikey)
		pollJob.GetRequest.Timeout = 1200000 * 1000
		wait For (pollJob) JobDone(pollJob As HttpJob)

		If pollJob.Success Then
			Dim pollJson As JSONParser
			pollJson.Initialize(pollJob.GetString)
			Dim pollResponse As Map = pollJson.NextObject
			Log(pollResponse)
			If pollResponse.ContainsKey("data") Then
				Dim data As Map = pollResponse.Get("data")
				Dim extractResult As List = data.Get("extract_result")
				If extractResult.Size > 0 Then
					Dim firstResult As Map = extractResult.Get(0)
					taskState = firstResult.GetDefault("state", "")

					If taskState = "done" Then
						completed = True
						Dim fullZipUrl As String = firstResult.GetDefault("full_zip_url", "")
						If fullZipUrl <> "" Then
							wait for (DownloadAndExtractZip(fullZipUrl, apikey, imgWidth, imgHeight)) complete (extracted As Map)
							resultText = extracted.Get("text")
							textWithLocation = extracted.Get("textWithLocation")
						End If
					Else If taskState = "failed" Then
						Log("Task failed: " & firstResult.GetDefault("err_msg", ""))
						completed = True
					Else
						Log("Task state: " & taskState)
					End If
				End If
			End If
		Else
			Log("Poll failed: " & pollJob.ErrorMessage)
		End If
		pollJob.Release
		retryCount = retryCount + 1
	Loop

	resultMap.Put("text", resultText)
	resultMap.Put("textWithLocation", textWithLocation)
	Return resultMap
End Sub

Sub DownloadAndExtractZip(zipUrl As String, apikey As String, imgWidth As Int, imgHeight As Int) As ResumableSub
	Dim resultText As String = ""
	Dim textWithLocation As List
	textWithLocation.Initialize

	Dim resultMap As Map
	resultMap.Initialize

	Dim zipJob As HttpJob
	zipJob.Initialize("job", Me)
	zipJob.Download(zipUrl)
	zipJob.GetRequest.SetHeader("Authorization", "Bearer " & apikey)
	zipJob.GetRequest.Timeout = 1200000 * 1000
	wait For (zipJob) JobDone(zipJob As HttpJob)

	If zipJob.Success Then
		Try
			Dim in As InputStream = zipJob.GetInputStream
			Dim zis As JavaObject
			zis.InitializeNewInstance("java.util.zip.ZipInputStream", Array(in))

			Dim entry As JavaObject = zis.RunMethod("getNextEntry", Null)
			Do While entry <> Null
				Dim entryName As String = entry.RunMethod("getName", Null)

				If entryName.EndsWith(".md") Then
					resultText = ReadZipEntryText(zis)
				End If

				If entryName.EndsWith("_content_list.json") Then
					Dim contentJson As String = ReadZipEntryText(zis)
					If contentJson <> "" Then
						Dim json As JSONParser
						json.Initialize(contentJson)
						Dim contentList As List = json.NextArray
						textWithLocation = ProcessContentList(contentList, imgWidth, imgHeight)
					End If
				End If

				entry = zis.RunMethod("getNextEntry", Null)
			Loop
			zis.RunMethod("close", Null)
		Catch
			Log(LastException)
		End Try
	Else
		Log("Zip download failed: " & zipJob.ErrorMessage)
	End If
	zipJob.Release

	resultMap.Put("text", resultText)
	resultMap.Put("textWithLocation", textWithLocation)
	Return resultMap
End Sub

Sub ReadZipEntryText(zis As JavaObject) As String
	Dim baos As JavaObject
	baos.InitializeNewInstance("java.io.ByteArrayOutputStream", Null)
	Dim buffer(4096) As Byte
	Dim len As Int = 1
	Do While len > 0
		len = zis.RunMethod("read", Array(buffer, 0, buffer.Length))
		If len > 0 Then
			baos.RunMethod("write", Array(buffer, 0, len))
		End If
	Loop
	Dim result As String = baos.RunMethod("toString", Array("UTF-8"))
	Return result
End Sub

Private Sub ProcessContentList(contentList As List, imgWidth As Int, imgHeight As Int) As List
	Dim boxes As List
	boxes.Initialize

	For Each block As Map In contentList
		Dim blockType As String = block.GetDefault("type", "")
		Dim text As String = block.GetDefault("text", "")
		If block.ContainsKey("table_body") Then
			text = block.Get("table_body")
		End If
		Dim bbox As List = block.Get("bbox")

		If bbox.Size >= 4 Then
			Dim x1 As Float = bbox.Get(0)
			Dim y1 As Float = bbox.Get(1)
			Dim x2 As Float = bbox.Get(2)
			Dim y2 As Float = bbox.Get(3)

			' MinerU normalizes coordinates to 0-1000, convert to actual pixels
			If imgWidth > 0 And imgHeight > 0 Then
				x1 = x1 / 1000 * imgWidth
				y1 = y1 / 1000 * imgHeight
				x2 = x2 / 1000 * imgWidth
				y2 = y2 / 1000 * imgHeight
			End If

			Dim box As Map
			box.Initialize
			box.Put("X", x1)
			box.Put("Y", y1)
			box.Put("width", x2 - x1)
			box.Put("height", y2 - y1)
			box.Put("text", text)
			box.Put("class", blockType)
			boxes.Add(box)
		End If
	Next

	Return boxes
End Sub

Sub readJsonAsMap(s As String) As Map
	Dim json As JSONParser
	json.Initialize(s)
	Return json.NextObject
End Sub

Sub getMap(key As String, parentmap As Map) As Map
	Return parentmap.Get(key)
End Sub

Sub saveImgToDiskWithSizeCheck(img As B4XBitmap, quality As Int, sizeLimit As Int)
	Dim imgPath As String = File.Combine(File.DirApp, "image.jpg")
	Dim out As OutputStream = File.OpenOutput(imgPath, "", False)
	img.WriteToStream(out, quality, "JPEG")
	out.Close
	Dim su As StringUtils
	Dim base64 As String = su.EncodeBase64(File.ReadBytes(File.DirApp, "image.jpg"))
	If base64.Length > sizeLimit Then
		Log("bigger than limit")
		If quality >= 10 Then
			saveImgToDiskWithSizeCheck(img, quality - 10, sizeLimit)
		End If
	End If
End Sub
