B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=10.5
@EndOfDesignText@
Sub Class_Globals
	Private engine As JavaObject
	Private th As Thread
	Public mInitialized As Boolean
End Sub

'Initializes the object. You can NOT add parameters to this method!
Public Sub Initialize
	Log("initialize cpp")
	th.Initialise("th")
	Dim libPath As String = FindNativeLibrary
	If libPath <> "" Then
		Dim sysCls As JavaObject
		sysCls.InitializeStatic("java.lang.System")
		sysCls.RunMethod("load", Array(libPath))
		Log("Loaded native library: " & libPath)
	Else
		Log("Native library not found in Files dir, will try JAR embedded library")
	End If

	Dim jo As JavaObject
	jo.InitializeNewInstance("com.xulihang.ZXingCpp", Null)
	Dim version As String = jo.RunMethod("getVersion", Null)
	Log("zxing-cpp version: " & version)
	engine = jo
End Sub

' Find the native library in Files directory
Private Sub FindNativeLibrary As String
	Dim libName As String = getNativeLibName
	If File.Exists(File.DirApp, libName) Then
		Return File.Combine(File.DirApp, libName)
	End If
	Return ""
End Sub

Private Sub getNativeLibName As String
	Dim osName As String = getOsName.ToLowerCase
	If osName.Contains("win") Then
		Return "ZXing.dll"
	Else If osName.Contains("mac") Then
		Return "libZXing.dylib"
	Else If osName.Contains("linux") Then
		Return "libZXing.so"
	End If
	Return "ZXing.dll"
End Sub

Private Sub getOsName As String
	Dim sysCls As JavaObject
	sysCls.InitializeStatic("java.lang.System")
	Return sysCls.RunMethod("getProperty", Array("os.name"))
End Sub

' DoProcessingAsync with timeout
Private Sub DoProcessingAsync(map1 As Map) As ResumableSub
	Dim b() As Boolean = Array As Boolean(False)
	TimeOutImpl(30000, b)
	th.Start(Me, "decodeUsingMap", Array As Map(map1))
	wait for th_Ended(endedOK As Boolean, error As String)
	If b(0) = False Then
		b(0) = True
		CallSubDelayed2(Me, "Decoded", True)
	End If
	Return endedOK
End Sub

Private Sub TimeOutImpl(Duration As Int, b() As Boolean)
	Sleep(Duration)
	If b(0) = False Then
		b(0) = True
		Log("time out")
		CallSubDelayed2(Me, "Decoded", False)
	End If
End Sub

' Async decode - takes a BufferedImage (JavaObject) and returns List of Map
Public Sub decodeAsync(bufferedImage As JavaObject, enableTryHarder As Boolean, _
		enableTryRotate As Boolean, enableTryInvert As Boolean, _
		enableTryDownscale As Boolean, IncludeLocation As Boolean) As ResumableSub

	Dim boxes As List
	boxes.Initialize
	Dim map1 As Map
	map1.Initialize
	map1.Put("image", bufferedImage)
	map1.Put("tryHarder", enableTryHarder)
	map1.Put("tryRotate", enableTryRotate)
	map1.Put("tryInvert", enableTryInvert)
	map1.Put("tryDownscale", enableTryDownscale)
	map1.Put("includeLocation", IncludeLocation)
	DoProcessingAsync(map1)
	wait for Decoded(Success As Boolean)
	If Success Then
		boxes = map1.Get("boxes")
	End If
	Return boxes
End Sub

Public Sub decode(bufferedImage As JavaObject, enableTryHarder As Boolean, _
		enableTryRotate As Boolean, enableTryInvert As Boolean, _
		enableTryDownscale As Boolean, IncludeLocation As Boolean) As List

	Dim boxes As List
	boxes.Initialize
	Dim map1 As Map
	map1.Initialize
	map1.Put("image", bufferedImage)
	map1.Put("tryHarder", enableTryHarder)
	map1.Put("tryRotate", enableTryRotate)
	map1.Put("tryInvert", enableTryInvert)
	map1.Put("tryDownscale", enableTryDownscale)
	map1.Put("includeLocation", IncludeLocation)
	decodeUsingMap(map1)
	Return boxes
End Sub


' Runs on background thread
Private Sub decodeUsingMap(map1 As Map)

	Dim bufferedImage As JavaObject = map1.Get("image")
	Dim tryHarder As Boolean = map1.Get("tryHarder")
	Dim tryRotate As Boolean = map1.Get("tryRotate")
	Dim tryInvert As Boolean = map1.Get("tryInvert")
	Dim tryDownscale As Boolean = map1.Get("tryDownscale")
	Dim includeLocation As Boolean = map1.Get("includeLocation")
	' Create reader options
	Dim readerOpts As JavaObject = engine.RunMethod("createReaderOptions", Null)

	engine.RunMethod("setTryHarder", Array(readerOpts, tryHarder))
	engine.RunMethod("setTryRotate", Array(readerOpts, tryRotate))
	engine.RunMethod("setTryInvert", Array(readerOpts, tryInvert))
	engine.RunMethod("setTryDownscale", Array(readerOpts, tryDownscale))

	Dim barcodeList As JavaObject = engine.RunMethod("readBarcodesAsList", Array(bufferedImage, readerOpts))
	Dim listSize As Int = barcodeList.RunMethod("size", Null)
	Dim boxes As List
	boxes.Initialize

	For i = 0 To listSize - 1
		Dim barcodeResult As JavaObject = barcodeList.RunMethod("get", Array(i))
		Dim box As Map
		box.Initialize

		Dim text As String = barcodeResult.RunMethod("getText", Null)
		Dim formatName As String = barcodeResult.RunMethod("getFormatName", Null)
		Dim valid As Boolean = barcodeResult.RunMethod("isValid", Null)
		Dim symbology As String = barcodeResult.RunMethod("getSymbologyIdentifier", Null)
		Dim orientation As Int = barcodeResult.RunMethod("getOrientation", Null)
		Dim seqIdx As Int = barcodeResult.RunMethod("getSequenceIndex", Null)
		Dim seqSize As Int = barcodeResult.RunMethod("getSequenceSize", Null)

		box.Put("text", text)
		box.Put("format", formatName)
		box.Put("valid", valid)
		If symbology <> Null Then box.Put("symbology", symbology)
		box.Put("orientation", orientation)
		box.Put("sequenceIndex", seqIdx)
		box.Put("sequenceSize", seqSize)

		If includeLocation Then
			Dim pos As JavaObject = barcodeResult.RunMethod("getPosition", Null)
			If pos <> Null Then
				Dim tlX As Int = pos.RunMethod("getTopLeftX", Null)
				Dim tlY As Int = pos.RunMethod("getTopLeftY", Null)
				Dim trX As Int = pos.RunMethod("getTopRightX", Null)
				Dim topRightY As Int = pos.RunMethod("getTopRightY", Null)
				Dim brX As Int = pos.RunMethod("getBottomRightX", Null)
				Dim brY As Int = pos.RunMethod("getBottomRightY", Null)
				Dim blX As Int = pos.RunMethod("getBottomLeftX", Null)
				Dim blY As Int = pos.RunMethod("getBottomLeftY", Null)

				Dim minX As Float = Min(Min(tlX, trX), Min(brX, blX))
				Dim minY As Float = Min(Min(tlY, topRightY), Min(brY, blY))
				Dim maxX As Float = Max(Max(tlX, trX), Max(brX, blX))
				Dim maxY As Float = Max(Max(tlY, topRightY), Max(brY, blY))

				Dim boxGeometry As Map
				boxGeometry.Initialize
				boxGeometry.Put("X", minX)
				boxGeometry.Put("Y", minY)
				boxGeometry.Put("width", maxX - minX)
				boxGeometry.Put("height", maxY - minY)
				box.Put("geometry", boxGeometry)

				' Store 4 corners
				Dim corners As List
				corners.Initialize
				corners.Add(CreateMap("x":tlX, "y":tlY))
				corners.Add(CreateMap("x":trX, "y":topRightY))
				corners.Add(CreateMap("x":brX, "y":brY))
				corners.Add(CreateMap("x":blX, "y":blY))
				box.Put("corners", corners)
			Else
				Dim boxGeometry As Map
				boxGeometry.Initialize
				boxGeometry.Put("X", 0)
				boxGeometry.Put("Y", 0)
				boxGeometry.Put("width", 0)
				boxGeometry.Put("height", 0)
				box.Put("geometry", boxGeometry)
			End If
		End If
		boxes.Add(box)
	Next
	map1.Put("boxes", boxes)
End Sub

