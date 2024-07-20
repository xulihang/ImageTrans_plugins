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
	Return "RapidOCROCR"
End Sub

' must be available
public Sub Run(Tag As String, Params As Map) As ResumableSub
	Log("run"&Params)
	Log("winRT")
	Select Tag
		Case "getParams"
			Dim paramsList As List
			paramsList.Initialize
			Return paramsList
		Case "getText"
			wait for (GetText(Params.Get("img"),Params.Get("lang"))) complete (result As String)
			Return result
		Case "getTextWithLocation"
			wait for (GetTextWithLocation(Params.Get("img"),Params.Get("lang"))) complete (regions As List)
			Return regions
		Case "getLangs"
			wait for (getLangs(Params.Get("loc"))) complete (langs As Map)
			Return langs
		Case "getSetupParams"
			Dim paramsMap As Map
			paramsMap.Initialize
			paramsMap.Put("zip","https://github.com/xulihang/RapidOcrOnnxJvm/releases/download/builds/rapid.zip")
			paramsMap.Put("folder","rapidocr")
			Return paramsMap
	End Select
	Return ""
End Sub

Sub getLangs(loc As Localizator) As ResumableSub
	Dim result As Map
	result.Initialize
	Dim names,codes As List
	names.Initialize
	codes.Initialize
	names.Add(loc.Localize("中英文"))
	codes.Add("zh")
	names.Add(loc.Localize("日语"))
	codes.Add("ja")
	names.Add(loc.Localize("韩语"))
	codes.Add("ko")
	result.Put("names",names)
	result.Put("codes",codes)
	Return result
End Sub

Sub GetText(img As B4XBitmap, lang As String) As ResumableSub
	wait for (ocr(img,lang)) complete (boxes As List)
	Dim sb As StringBuilder
	sb.Initialize
	For Each box As Map In boxes
		sb.Append(box.Get("text"))
		sb.Append(CRLF)
	Next
	Return sb.ToString
End Sub

Sub GetTextWithLocation(img As B4XBitmap, lang As String) As ResumableSub
	wait for (ocr(img,lang)) complete (boxes As List)
	Dim regions As List
	regions.Initialize
	For Each box As Map In boxes
		Dim region As Map=box.Get("geometry")
		region.Put("text",box.Get("text"))
		regions.Add(region)
	Next
	Return regions
End Sub

Sub ocr(img As B4XBitmap,lang As String) As ResumableSub
	Dim boxes As List
	boxes.Initialize
	Dim out As OutputStream
	out=File.OpenOutput(File.DirApp,"image.jpg",False)
	img.WriteToStream(out,"100","JPEG")
	out.Close
	Dim env As Map
	env.Initialize
	Dim libPath As String="win-JNI-CPU-x64"
	Select DetectOS
	    Case "linux"
			libPath="Linux-JNI-CPU"
		Case "mac"
			libPath="Darwin-JNI-CPU"
	End Select
	libPath = File.Combine(libPath,"bin")
	env.Put("LIB_PATH",libPath)
	Dim rec As String
	Dim keys As String
	If lang = "ko" Then
		rec = "rec_korean_PP-OCRv3_infer.onnx"
		keys = "dict_korean.txt"
	else if lang = "ja" Then
		rec = "rec_japan_PP-OCRv3_infer.onnx"
		keys = "dict_japan.txt"
	Else
		rec = "ch_PP-OCRv3_rec_infer.onnx"
		keys = "ppocr_keys_v1.txt"
	End If
	Dim sh As Shell
	Dim imgPath As String=File.Combine(File.DirApp,"image.jpg")
	Dim args As List = Array As String("-Djava.library.path="&env.Get("LIB_PATH"),"-Dfile.encoding=UTF-8","-jar","RapidOcrOnnxJvm.jar","models","ch_PP-OCRv3_det_infer.onnx","ch_ppocr_mobile_v2.0_cls_infer.onnx",rec,keys,imgPath)
	Log(args)
	sh.Initialize("sh","java",args)
	sh.SetEnvironmentVariables(env)
	sh.Encoding="UTF-8"
	sh.WorkingDirectory=File.Combine(File.DirApp,"rapidocr")
	sh.Run(10000)
	wait for sh_ProcessCompleted (Success As Boolean, ExitCode As Int, StdOut As String, StdErr As String)
	Log("done")
	Log(StdOut)
	Log(StdErr)
	If Success Then
		If File.Exists(File.DirApp,"image.jpg-out.json") Then
			Dim jsonString As String=File.ReadString(File.DirApp,"image.jpg-out.json")
			Log(jsonString)
			Dim json As JSONParser
			json.Initialize(jsonString)
			Dim textBlocks As List=json.NextObject.Get("textBlocks")
			For Each textBlock As Map In textBlocks
				Dim minX,minY,maxX,maxY As Int
				Dim boxPoints As List=textBlock.Get("boxPoint")
				Dim index As Int=0
				For Each point As Map In boxPoints
					If index=0 Then
						minX=point.Get("x")
						minY=point.Get("y")
					End If
					minX=Min(point.Get("x"),minX)
					minY=Min(point.Get("y"),minY)
					maxX=Max(point.Get("x"),maxX)
					maxY=Max(point.Get("y"),maxY)
					index=index+1
				Next
				Dim box As Map
				box.Initialize
			    box.Put("text",textBlock.GetDefault("text",""))
				Dim boxGeometry As Map
				boxGeometry.Initialize
				boxGeometry.Put("X",minX)
				boxGeometry.Put("Y",minY)
				boxGeometry.Put("width",maxX-minX)
				boxGeometry.Put("height",maxY-minY)
				box.Put("geometry",boxGeometry)
				boxes.Add(box)
			Next
			For i=0 To textBlocks.Size-1
				File.Delete(File.DirApp,$"image.jpg-part-${i}.jpg"$)
			Next
		End If
	End If
	Return boxes
End Sub

'windows, mac or linux
Sub DetectOS As String
	Dim os As String = GetSystemProperty("os.name", "").ToLowerCase
	If os.Contains("win") Then
		Return "windows"
	Else If os.Contains("mac") Then
		Return "mac"
	Else
		Return "linux"
	End If
End Sub
