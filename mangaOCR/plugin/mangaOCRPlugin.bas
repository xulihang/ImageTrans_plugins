B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=4.2
@EndOfDesignText@
Sub Class_Globals
	Private fx As JFX
	Private longTextMode As Boolean = False
	Private engine As jMangaOCR
End Sub

'Initializes the object. You can NOT add parameters to this method!
Public Sub Initialize() As String
	Log("Initializing plugin " & GetNiceName)
	' Here return a key to prevent running unauthorized plugins
	Return "MyKey"
End Sub

' must be available
public Sub GetNiceName() As String
	Return "manga-ocrOCR"
End Sub

' must be available
public Sub Run(Tag As String, Params As Map) As ResumableSub
	'Log("run"&Params)
	Select Tag
		Case "getParams"
			Dim paramsList As List
			paramsList.Initialize
			paramsList.Add("url")
			paramsList.Add("long text ratio")
			Return paramsList
		Case "getText"
			If longTextMode Then
				wait for (GetTextLongTextMode(Params.Get("img"))) complete (result As String)
				longTextMode = False
				Return result
			Else
				wait for (GetText(Params.Get("img"))) complete (result As String)
				Return result
			End If
		Case "getTextWithLocation"
			Dim list1 As List
			list1.Initialize
			Return list1
		Case "getDefaultParamValues"
			Return CreateMap("url":"http://127.0.0.1:8080/ocr","long text ratio":"8")
		Case "getLangs"
			Return getLangs(Params.Get("loc"))
		Case "getSetupParams"
			Dim o As Object = CreateMap("readme":"https://github.com/xulihang/ImageTrans_plugins/tree/master/mangaOCR")
			Return o
		Case "getIsInstalledOrRunning"
			Wait For (CheckIsRunning) complete (running As Boolean)
			Return running
		Case "SetCombination"
			Dim comb As String=Params.Get("combination")
			longTextMode = comb.Contains("long text")
		Case "GetCombinations"
			Return BuildCombinations
		Case "Multiple"
			Return True
	End Select
	Return ""
End Sub

Sub BuildCombinations As List
	Dim combs As List
	combs.Initialize
	combs.Add("manga-ocr")
	combs.Add("normal text (manga-ocr)")
	combs.Add("long text (manga-ocr)")
	Return combs
End Sub

Sub getLangs(loc As Localizator) As Map
	Dim result As Map
	result.Initialize
	Dim names,codes As List
	names.Initialize
	codes.Initialize
	codes.Add("ja")
	names.Add(loc.Localize("日语"))
	result.Put("names",names)
	result.Put("codes",codes)
	Return result
End Sub

Private Sub LoadMangaOCRIfNeeded As ResumableSub
	If engine.IsInitialized = False Then
		Dim mangaOCRDir As String = File.Combine(File.DirApp,"mangaocr")
		Dim encoderModel As String = File.Combine(mangaOCRDir,"encoder.onnx")
		Dim decoderModel As String = File.Combine(mangaOCRDir,"decoder.onnx")
		Dim vocabs As List = File.ReadList(mangaOCRDir,"vocab.txt")
		engine.Initialize
		wait for (engine.loadModelWithPathAsync(encoderModel,decoderModel,vocabs)) complete (done As Object)
	End If
	Return True
End Sub

Sub Image2cvMat2(img As B4XBitmap) As cvMat
	Return cv2.bytesToMat(ImageToBytes(img))
End Sub

Public Sub ImageToBytes(Image As B4XBitmap) As Byte()
	Dim out As OutputStream
	out.InitializeToBytesArray(0)
	Image.WriteToStream(out, 100, "JPEG")
	out.Close
	Return out.ToBytesArray
End Sub

Sub GetText(img As B4XBitmap) As ResumableSub
	If ONNXExists Then
		Wait For (LoadMangaOCRIfNeeded) complete (done As Object)
		Dim srcMat As cvMat = Image2cvMat2(img)
		wait for (engine.recognizeAsync(srcMat)) complete (result As String)
		srcMat.release
		Return result
	Else
		Dim out As OutputStream
		out=File.OpenOutput(File.DirApp,"image.jpg",False)
		img.WriteToStream(out,"100","JPEG")
		out.Close
		Dim job As HttpJob
		job.Initialize("",Me)
		Dim fd As MultipartFileData
		fd.Initialize
		fd.KeyName = "upload"
		fd.Dir = File.DirApp
		fd.FileName = "image.jpg"
		fd.ContentType = "image/jpg"
		job.PostMultipart(getUrl,Null, Array(fd))
		job.GetRequest.Timeout=240*1000
		Wait For (job) JobDone(job As HttpJob)
		If job.Success Then
			Try
				Log(job.GetString)
				Return job.GetString
			Catch
				Log(LastException)
			End Try
		End If
		job.Release
		Return ""
	End If
End Sub



Sub GetTextLongTextMode(img As B4XBitmap) As ResumableSub
	Dim longTextRatio As Int = getLongTextRatio
	Dim imgs As List
	imgs.Initialize
	If img.Height / img.Width > longTextRatio Then
		Dim segHeight As Int = img.Width * longTextRatio
		Dim top As Int = 0
		Dim heightLeft As Int = img.Height
		Dim segsNumber As Int = Ceil(img.Height / segHeight)
		For i = 1 To segsNumber
			imgs.Add(img.Crop(0,top,img.Width,Min(segHeight,heightLeft)))
			heightLeft = heightLeft - segHeight
			top = top + segHeight
		Next
	Else If img.Width / img.Height > longTextRatio Then
		Dim segWidth As Int = img.Height * longTextRatio
		Dim left As Int = 0
		Dim widthLeft As Int = img.Width
		Dim segsNumber As Int = Ceil(img.Width / segWidth)
		For i = 1 To segsNumber
			imgs.Add(img.Crop(left,0,Min(segWidth,widthLeft),img.Height))
			widthLeft = widthLeft - segWidth
			left = left + segWidth
		Next
	Else
		imgs.Add(img)
	End If
	Dim sb As StringBuilder
	sb.Initialize
	For Each cropped As Image In imgs
		wait for (GetText(cropped)) complete (result As String)
		sb.Append(result)
	Next
	Return sb.ToString
End Sub

Sub getMap(key As String,parentmap As Map) As Map
	Return parentmap.Get(key)
End Sub

Private Sub getLongTextRatio As Int
	Dim ratio As Int = 8
	If File.Exists(File.DirApp,"preferences.conf") Then
		Try
			Dim preferencesMap As Map = readJsonAsMap(File.ReadString(File.DirApp,"preferences.conf"))
			ratio=getMap("manga-ocr",getMap("api",preferencesMap)).GetDefault("long text ratio",ratio)
		Catch
			Log(LastException)
		End Try
	End If
	Return ratio
End Sub

Sub getUrl As String
	Dim url As String = "http://127.0.0.1:8080/ocr"
	If File.Exists(File.DirApp,"preferences.conf") Then
		Try
			Dim preferencesMap As Map = readJsonAsMap(File.ReadString(File.DirApp,"preferences.conf"))
			url=getMap("manga-ocr",getMap("api",preferencesMap)).GetDefault("url",url)
		Catch
			Log(LastException)
		End Try
	End If
	Return url
End Sub

Private Sub ONNXExists As Boolean
	Dim mangaOCRDir As String = File.Combine(File.DirApp,"mangaocr")
	If File.Exists(mangaOCRDir,"decoder.onnx") And File.Exists(mangaOCRDir,"encoder.onnx") And File.Exists(mangaOCRDir,"vocab.txt") Then
		Return True
	End If
	Return False
End Sub

Private Sub CheckIsRunning As ResumableSub
	If ONNXExists Then
		Return True
	End If
	Dim result As Boolean = True
	Dim job As HttpJob
	job.Initialize("job",Me)
	job.Head(getUrl)
	job.GetRequest.Timeout = 500
	Wait For (job) JobDone(job As HttpJob)
	If job.Success = False Then
		If job.Response.StatusCode <> 404 Then
		    result = False
		End If
	End If
	job.Release
	Return result
End Sub

Sub readJsonAsMap(s As String) As Map
	Dim json As JSONParser
	json.Initialize(s)
	Return json.NextObject
End Sub
