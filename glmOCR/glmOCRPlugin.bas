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
	Return "glmOCROCR"
End Sub

' must be available
public Sub Run(Tag As String, Params As Map) As ResumableSub
	Select Tag
		Case "getParams"
			Dim paramsList As List
			paramsList.Initialize
			paramsList.Add("key")
			paramsList.Add("model")
			paramsList.Add("url")
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
			Return CreateMap("url":"https://open.bigmodel.cn/api/paas/v4/layout_parsing", _
			                 "model":"glm-ocr")
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
		preferencesMap = CreateMap("api":CreateMap("glmOCR":map1))
	End If
	Dim apikey As String = getMap("glmOCR",getMap("api",preferencesMap)).Get("key")
	Dim url As String = getMap("glmOCR",getMap("api",preferencesMap)).GetDefault("url","https://open.bigmodel.cn/api/paas/v4/layout_parsing")
	Dim model As String = getMap("glmOCR",getMap("api",preferencesMap)).GetDefault("model","glm-ocr")

	Dim su As StringUtils
	Dim base64 As String=su.EncodeBase64(File.ReadBytes(File.DirApp,"image.jpg"))
	Dim urlMap As Map
	urlMap.Initialize
	urlMap.Put("url","data:image/jpeg;base64,"&base64)
	Dim data As Map
	data.Initialize
	data.Put("file","data:image/jpeg;base64,"&base64)

	data.Put("model",model)
	
	Dim jsonG As JSONGenerator
	jsonG.Initialize(data)
	job.PostString(url,jsonG.ToString)
	Log(jsonG.ToString)
	job.GetRequest.SetContentType("application/json")
	job.GetRequest.SetHeader("Authorization","Bearer "&apikey)
	job.GetRequest.Timeout = 1200000*1000
	wait For (job) JobDone(job As HttpJob)

	If job.Success Then
		Try
			Log(job.GetString)
			'File.WriteString(File.DirApp,"out.json",job.GetString)
			regions.AddAll(PostProcess(job.GetString))
		Catch
			Log(LastException)
		End Try
	Else
		Log(job.ErrorMessage)
	End If
	job.Release
	If actionType = "ocr" Then
		Dim sb As StringBuilder
		sb.Initialize
		For Each box As Map In regions
			sb.Append(box.Get("text"))
			sb.Append(CRLF)
		Next
		Return sb.ToString.Trim
	Else
		Return regions
	End If
End Sub

Private Sub PostProcess(json As String) As List
	Dim jsonP As JSONParser
	jsonP.Initialize(json)
	Dim data As Map = jsonP.NextObject
	Dim layoutDetails As List = data.Get("layout_details")
	Dim boxes As List = layoutDetails.Get(0)
    Dim converted As List
	converted.Initialize
	For Each box As Map In boxes
		Dim content As String = box.GetDefault("content","")
		Dim bbox As List = box.Get("bbox_2d") ' 631,0,744,790
		Dim topLeftX As Int = bbox.Get(0)
		Dim topLeftY As Int = bbox.Get(1)
		Dim rightBottomX As Int = bbox.Get(2)
		Dim rightBottomY As Int = bbox.Get(3)
		Dim width As Int = rightBottomX - topLeftX
		Dim height As Int = rightBottomY - topLeftY
		Dim class As String = box.Get("native_label")
		Dim convertedBox As Map
		convertedBox.Initialize
		convertedBox.Put("X", topLeftX)
		convertedBox.Put("Y", topLeftY)
		convertedBox.Put("width", width)
		convertedBox.Put("height", height)
		convertedBox.Put("text",content)
		convertedBox.Put("class",class)
		converted.Add(convertedBox)
	Next
	Return converted
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
