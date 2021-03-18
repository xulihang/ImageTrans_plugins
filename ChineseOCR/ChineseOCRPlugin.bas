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
	Return "ChineseOCROCR"
End Sub

' must be available
public Sub Run(Tag As String, Params As Map) As ResumableSub
	Log("run"&Params)
	Log("winRT")
	Select Tag
		Case "getParams"
			Dim paramsList As List
			paramsList.Initialize
			paramsList.Add("use GPU (yes or no)")
			Return paramsList
		Case "getText"
			wait for (GetText(Params.Get("img"),Params.Get("lang"))) complete (result As String)
			Return result
		Case "getTextWithLocation"
			wait for (GetTextWithLocation(Params.Get("img"),Params.Get("lang"))) complete (regions As List)
			Return regions
		Case "getLangs"
			wait for (getLangs) complete (langs As Map)
			Return langs
	End Select
	Return ""
End Sub

Sub getLangs As ResumableSub
	Dim result As Map
	result.Initialize
	Dim names,codes As List
	names.Initialize
	codes.Initialize
	names.Add("Chinese")
	codes.Add("zh")
	result.Put("names",names)
	result.Put("codes",codes)
	Return result
End Sub

Sub GetText(img As B4XBitmap, lang As String) As ResumableSub
	wait for (ocr(img)) complete (boxes As List)
	Dim sb As StringBuilder
	sb.Initialize
	For Each box As Map In boxes
		sb.Append(box.Get("text"))
		sb.Append(CRLF)
	Next
	Return sb.ToString
End Sub

Sub GetTextWithLocation(img As B4XBitmap, lang As String) As ResumableSub
	wait for (ocr(img)) complete (boxes As List)
	Dim regions As List
	regions.Initialize
	For Each box As Map In boxes
		Dim region As Map=box.Get("geometry")
		region.Put("text",box.Get("text"))
		regions.Add(region)
	Next
	Return regions
End Sub

Sub ocr(img As B4XBitmap) As ResumableSub
	Dim gpuindex As String="-1"
	Try
		If File.Exists(File.DirApp,"preferences.conf") Then
			Dim preferencesMap As Map = readJsonAsMap(File.ReadString(File.DirApp,"preferences.conf"))
			Select getMap("ChineseOCR",getMap("api",preferencesMap)).Get("use GPU (yes or no)")
				Case "yes"
					gpuindex="0"
				Case "no"
					gpuindex="-1"
			End Select
		End If
	Catch
		Log(LastException)
	End Try
	Dim boxes As List
	boxes.Initialize
	Dim out As OutputStream
	out=File.OpenOutput(File.DirApp,"image.jpg",False)
	img.WriteToStream(out,"100","JPEG")
	out.Close
	Dim env As Map
	env.Initialize
	env.Put("GPU_INDEX",gpuindex)
	Dim libPath As String="win-lib-cpu-x64"
	Select DetectOS
		Case "windows"
			If gpuindex=0 Then
				libPath="win-lib-gpu-x64"
			Else
				libPath="win-lib-cpu-x64"
			End If
		Case "linux"
			If gpuindex=0 Then
				libPath="Linux-Lib-GPU"
			Else
				libPath="Linux-Lib-CPU"
			End If
		Case "mac"
			If gpuindex=0 Then
				libPath="Darwin-Lib-GPU"
			Else
				libPath="Darwin-Lib-CPU"
			End If
	End Select
	env.Put("LIB_PATH",libPath)
	
	Dim sh As Shell
    Dim runtime As JavaObject
	runtime.InitializeStatic("java.lang.Runtime")
	Dim cores As Int=runtime.RunMethodJO("getRuntime",Null).RunMethod("availableProcessors",Null)
	Dim imgPath As String=File.Combine(File.DirApp,"image.jpg")
	sh.Initialize("sh","java",Array As String("-Djava.library.path="&env.Get("LIB_PATH"),"-Dfile.encoding=UTF-8","-jar","OcrLiteNcnnJvm.jar","models","dbnet_op","angle_op","crnn_lite_op","keys.txt",imgPath,cores,"50","0","0.3","0.3","2","1","1",env.Get("GPU_INDEX")))
	sh.SetEnvironmentVariables(env)
	sh.Encoding="UTF-8"
	sh.WorkingDirectory=File.Combine(File.DirApp,"ChineseOCR")
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

Sub getMap(key As String,parentmap As Map) As Map
	Return parentmap.Get(key)
End Sub

Sub readJsonAsMap(s As String) As Map
	Dim json As JSONParser
	json.Initialize(s)
	Return json.NextObject
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
