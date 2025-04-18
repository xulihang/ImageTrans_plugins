﻿B4J=true
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
	Select Tag
		Case "getParams"
			Dim paramsList As List
			paramsList.Initialize
			Return paramsList
		Case "getText"
			wait for (GetText(Params.Get("img"),Params.Get("lang"),Params.GetDefault("imgName",""))) complete (result As String)
			Return result
		Case "getTextWithLocation"
			wait for (GetTextWithLocation(Params.Get("img"),Params.Get("lang"),Params.GetDefault("imgName",""))) complete (regions As List)
			Return regions
		Case "getLangs"
			wait for (getLangs(Params.Get("loc"))) complete (langs As Map)
			Return langs
		Case "isUsingShell"
			Return True
		Case "getResult"
			Dim boxes As List
			boxes.Initialize
			Dim parsed As Boolean = ParseResult(boxes,Params.Get("imgName"),True)
			If parsed Then
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
				Return True
			End If
			Return False
	End Select
	Return ""
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
		regions.Add(region)
	Next
	Return regions
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
		ParseResult(boxes,imgName,Not(imgNamePassed))
	End If
	Return boxes
End Sub

Private Sub ParseResult(boxes As List,imgName As String,deleteResult As Boolean) As Boolean
	Dim jsonPath As String = File.Combine(File.DirApp,imgName&"-out.json")
	If File.Exists(jsonPath,"") Then
		Dim jsonString As String=File.ReadString(jsonPath,"")
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
			File.Delete(File.DirApp,$"${imgName}-part-${i}.jpg"$)
		Next
		File.Delete(File.DirApp,imgName)
		If deleteResult Then
			File.Delete(jsonPath,"")
		End If
	Else
		Return False
	End If
	Return True
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
