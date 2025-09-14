B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=4.2
@EndOfDesignText@
Sub Class_Globals
	Private fx As JFX
	Private rotationDetection as Boolean = False
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
	Select Tag
		Case "getParams"
			Dim paramsList As List
			paramsList.Initialize
			Return paramsList
		Case "getText"
			wait for (GetText(Params.Get("img"),Params.Get("lang"),Params.GetDefault("imgName",""))) complete (result As String)
			rotationDetection = False
			Return result
		Case "getTextWithLocation"
			wait for (GetTextWithLocation(Params.Get("img"),Params.Get("lang"),Params.GetDefault("imgName",""))) complete (regions As List)
			rotationDetection = False
			Return regions
		Case "getLangs"
			wait for (getLangs(Params.Get("loc"))) complete (langs As Map)
			Return langs
		Case "SetCombination"
			Dim comb As String=Params.Get("combination")
			rotationDetection = comb.Contains("rotationDetection")
		Case "isUsingShell"
			Return True
		Case "getResult"
			Dim boxes As List
			boxes.Initialize
			Dim detectedBoxes As List = ParseResult(Params.Get("imgName"),True)
			addBoxes(detectedBoxes,boxes)
			If boxes.Size>0 Then
				Return boxes
			Else
				Return False
			End If
		Case "getSetupParams"
			Dim paramsMap As Map
			paramsMap.Initialize
			paramsMap.Put("zip","https://github.com/xulihang/RapidOcrOnnxJvm/releases/download/builds/rapidocr.zip")
			'paramsMap.Put("zip","http://127.0.0.1:8000/rapidocr.zip")
			paramsMap.Put("folder","rapidocr")
			Dim o As Object = paramsMap
			Return o
		Case "getIsInstalledOrRunning"
			Dim root As String = Params.Get("root")
			If File.Exists(root,"rapidocr") Then
				If File.Exists(File.Combine(root,"rapidocr"),"RapidOcrOnnxJvm.jar") Then
					Return True
				End If
			End If
			Return False
		Case "rotationDetectionSupported"
			Return True
		Case "detectRotation"
			wait for (DetectRotation(Params.Get("img"),Params.Get("lang"))) complete (angle As Double)
			rotationDetection = False
			Return angle
	End Select
	Return ""
End Sub

Sub DetectRotation(img As B4XBitmap, lang As String) As ResumableSub
	rotationDetection = True
	Dim degree As Double
	wait for (ocr(img,lang,"")) complete (boxes As List)
	For i = 0 To boxes.Size - 1
		Dim box As Map = boxes.Get(i)
		If box.ContainsKey("degree") Then
			degree = box.Get("degree")
			Return degree
		End If
	Next
	Return degree
End Sub

Sub getLangs(loc As Localizator) As ResumableSub
	Dim result As Map
	result.Initialize
	Dim names,codes As List
	names.Initialize
	codes.Initialize
	names.Add(loc.Localize("中文"))
	codes.Add("zh")
	names.Add(loc.Localize("英语"))
	codes.Add("en")
	names.Add(loc.Localize("繁体中文"))
	codes.Add("zh-cht")
	names.Add(loc.Localize("日语"))
	codes.Add("ja")
	names.Add(loc.Localize("韩语"))
	codes.Add("ko")
	result.Put("names",names)
	result.Put("codes",codes)
	Return result
End Sub

Sub GetText(img As B4XBitmap, lang As String,imgName As String) As ResumableSub
	wait for (ocr(img,lang,imgName)) complete (boxes As List)
	Dim sb As StringBuilder
	sb.Initialize
	For Each box As Map In boxes
		sb.Append(box.Get("text"))
		sb.Append(CRLF)
	Next
	Return sb.ToString
End Sub

Sub GetTextWithLocation(img As B4XBitmap, lang As String,imgName As String) As ResumableSub
	wait for (ocr(img,lang,imgName)) complete (boxes As List)
	Dim regions As List
	regions.Initialize
	For Each box As Map In boxes
		Dim region As Map=box.Get("geometry")
		region.Put("text",box.Get("text"))
		addExtra(region,box)
		regions.Add(region)
	Next
	Return regions
End Sub

Private Sub addExtra(region As Map,box As Map)
	Dim extra As Map
	extra.Initialize
	For Each key As String In box.Keys
		If key <> "geometry" And key <> "text" Then
			extra.Put(key,box.Get(key))
		End If
	Next
	region.Put("extra",extra)
End Sub

private Sub GenerateUniqueName As String
	Dim randomNumber As Int = Rnd(0,1000)
	Dim timestamp As String = DateTime.Now
	Return timestamp&"-"&randomNumber&".jpg"
End Sub

Sub ocr(img As B4XBitmap,lang As String,imgName As String) As ResumableSub
	Dim boxes As List
	boxes.Initialize
	Dim imgNamePassed As Boolean = False
	If imgName = "" Then
		imgName = GenerateUniqueName
	Else
		imgNamePassed = True
	End If
	Dim out As OutputStream
	out=File.OpenOutput(File.DirApp,imgName,False)
	img.WriteToStream(out,"100","JPEG")
	out.Close
	Dim env As Map
	env.Initialize
	Dim libPath As String=File.Combine("win-JNI-CPU-x64","bin")
	Select DetectOS
	    Case "linux"
			libPath=File.Combine("Linux-JNI-CPU","lib")
		Case "mac"
			wait for (IsAppleCPU) Complete (appleCPU As Boolean)
			If appleCPU Then
				libPath=File.Combine("Darwin-JNI-CPU-arm","lib")
			Else
				libPath=File.Combine("Darwin-JNI-CPU-x64","lib")
			End If
	End Select
	env.Put("LIB_PATH",libPath)
	Dim rec As String
	Dim keys As String
	If lang = "ko" Then
		rec = "rec_korean_PP-OCRv3_infer.onnx"
		keys = "dict_korean.txt"
	else if lang = "ja" Then
		rec = "rec_japan_PP-OCRv3_infer.onnx"
		keys = "dict_japan.txt"
	else if lang = "zh-cht" Then
		rec = "rec_chinese_cht_PP-OCRv3_infer.onnx"
		keys = "dict_chinese_cht.txt"
	else if lang = "en" Then
		rec = "rec_en_PP-OCRv3_infer.onnx"
		keys = "dict_en.txt"
	Else
		rec = "ch_PP-OCRv3_rec_infer.onnx"
		keys = "ppocr_keys_v1.txt"
	End If
	Dim sh As Shell
	Dim imgPath As String=File.Combine(File.DirApp,imgName)
	Dim args As List = Array As String("-Djava.library.path="&env.Get("LIB_PATH"),"-Dfile.encoding=UTF-8","-jar","RapidOcrOnnxJvm.jar","models","ch_PP-OCRv3_det_infer.onnx","ch_ppocr_mobile_v2.0_cls_infer.onnx",rec,keys,imgPath)
	Dim javaPath As String = "java"
	Dim localJavaPath As String = File.Combine(File.DirApp,"jdk-23/Contents/Home/bin/java")
	If DetectOS == "mac" And File.Exists(localJavaPath,"") Then
		javaPath = localJavaPath
	End If
	sh.Initialize("sh",javaPath,args)
	sh.SetEnvironmentVariables(env)
	sh.Encoding="UTF-8"
	sh.WorkingDirectory=File.Combine(File.DirApp,"rapidocr")
	sh.Run(60000)
	wait for sh_ProcessCompleted (Success As Boolean, ExitCode As Int, StdOut As String, StdErr As String)
	If Success Then
		Dim detectedBoxes As List = ParseResult(imgName,Not(imgNamePassed))
		addBoxes(detectedBoxes,boxes)
	End If
	Return boxes
End Sub

Sub addBoxes(detectedBoxes As List,boxes As List)
	For Each box As Map In detectedBoxes
		Dim newBox As Map
		newBox.Initialize
		newBox.put("text",box.GetDefault("text",""))
		Dim boxGeometry As Map
		boxGeometry.Initialize
		Dim left,top,width,height As Int
		Dim X1,X2,X3,X4,Y1,Y2,Y3,Y4 As Int
		X1 = box.get("x0")
		X2 = box.get("x1")
		X3 = box.get("x2")
		X4 = box.get("x3")
		Y1 = box.get("y0")
		Y2 = box.get("y1")
		Y3 = box.get("y2")
		Y4 = box.get("y3")
		Dim minX,maxX,minY,maxY As Int
		minX = -1
		minY = -1
		For Each X As Int In Array(X1,X2,X3,X4)
			If minX = -1 Then
				minX = X
			Else
				minX = Min(minX,X)
			End If
			maxX = Max(maxX,X)
		Next
		For Each Y As Int In Array(Y1,Y2,Y3,Y4)
			If minY = -1 Then
				minY = Y
			Else
				minY = Min(minY,Y)
			End If
			maxY = Max(maxY,Y)
		Next
		If rotationDetection Then
			Dim centerX As Int = minX + (maxX - minX) / 2
			Dim centerY As Int = minY + (maxY - minY) / 2
			Dim K As Double = (Y2-Y1)/(X2-X1)
			Dim degree As Int= ATan(K) * 180 / cPI
			If degree < 0 Then
				degree = degree + 360
			End If
			Dim point1(2) As Int = CalculateRotatedPosition(-degree,centerX,centerY,X1,Y1)
			Dim point2(2) As Int = CalculateRotatedPosition(-degree,centerX,centerY,X2,Y2)
			Dim point3(2) As Int = CalculateRotatedPosition(-degree,centerX,centerY,X3,Y3)
			Dim point4(2) As Int = CalculateRotatedPosition(-degree,centerX,centerY,X4,Y4)
			minX = -1
			minY = -1
			For Each X As Int In Array(point1(0),point2(0),point3(0),point4(0))
				If minX = -1 Then
					minX = X
				Else
					minX = Min(minX,X)
				End If
				maxX = Max(maxX,X)
			Next
			For Each Y As Int In Array(point1(1),point2(1),point3(1),point4(1))
				If minY = -1 Then
					minY = Y
				Else
					minY = Min(minY,Y)
				End If
				maxY = Max(maxY,Y)
			Next
			If degree <> 0 Then
				newBox.Put("degree",degree)
			End If
		End If
		width = maxX - minX
		height = maxY - minY
		left = minX
		top = minY
		boxGeometry.Put("X",left)
		boxGeometry.Put("Y",top)
		boxGeometry.Put("width",width)
		boxGeometry.Put("height",height)
		newBox.Put("geometry",boxGeometry)
		'box.Put("std",True)
		boxes.Add(newBox)
	Next
End Sub

Sub CalculateRotatedPosition(degree As Double,pivotx As Double,pivoty As Double,x As Double,y As Double) As Int()
	Dim rotate As JavaObject
	rotate.InitializeNewInstance("javafx.scene.transform.Rotate",Array(degree,pivotx,pivoty))
	Dim point2dJO As JavaObject = rotate.RunMethod("transform",Array(x,y))
	Dim point(2) As Int
	point(0)=point2dJO.RunMethod("getX",Null)
	point(1)=point2dJO.RunMethod("getY",Null)
	Return point
End Sub

Private Sub ParseResult(imgName As String,deleteResult As Boolean) As List
	Dim jsonPath As String = File.Combine(File.DirApp,imgName&"-out.json")
	Dim boxes As List
	boxes.Initialize
	If File.Exists(jsonPath,"") Then
		Dim jsonString As String=File.ReadString(jsonPath,"")
		Dim json As JSONParser
		json.Initialize(jsonString)
		Dim textBlocks As List=json.NextObject.Get("textBlocks")
		For Each textBlock As Map In textBlocks
			Dim boxPoints As List=textBlock.Get("boxPoint")
			Dim index As Int=0
			Dim box As Map
			box.Initialize
			For Each point As Map In boxPoints
				Dim X As Int=point.Get("x")
				Dim Y As Int=point.Get("y")
				box.Put("x"&index,x)
				box.Put("y"&index,y)
				index=index+1
			Next
			box.Put("text",textBlock.GetDefault("text",""))
			boxes.Add(box)
		Next
		For i=0 To textBlocks.Size-1
			File.Delete(File.DirApp,$"${imgName}-part-${i}.jpg"$)
		Next
		File.Delete(File.DirApp,imgName)
		If deleteResult Then
			File.Delete(jsonPath,"")
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


Sub IsAppleCPU As ResumableSub
	Dim sh As Shell
	sh.Initialize("sh","uname",Array As String("-m"))
	sh.Run(-1)
	wait for sh_ProcessCompleted (Success As Boolean, ExitCode As Int, StdOut As String, StdErr As String)
	If StdOut.Contains("arm64") Then
		Return True
	Else
		Return False
	End If
End Sub
