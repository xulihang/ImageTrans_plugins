B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=4.2
@EndOfDesignText@
Sub Class_Globals
	Private fx As JFX
	Private engine As jOneOCR
	Private wordLevel As Boolean
	Private rotationDetection As Boolean = False
End Sub

'Initializes the object. You can NOT add parameters to this method!
Public Sub Initialize() As String
	Log("Initializing plugin " & GetNiceName)
	' Here return a key to prevent running unauthorized plugins
	Return "MyKey"
End Sub

' must be available
public Sub GetNiceName() As String
	Return "oneocrOCR"
End Sub

Private Sub InitIfNeeded
	If engine.IsInitialized = False Then
		engine.Initialize
		Log(engine.folder)
	End If
End Sub

' must be available
public Sub Run(Tag As String, Params As Map) As ResumableSub
	Select Tag
		Case "getParams"
			Dim paramsList As List
			paramsList.Initialize
			Return paramsList
		Case "getText"
			InitIfNeeded
			wait for (GetText(Params.Get("img"))) complete (result As String)
			wordLevel = False
			rotationDetection = False
			Return result
		Case "getTextWithLocation"
			InitIfNeeded
			wait for (GetTextWithLocation(Params.Get("img"))) complete (regions As List)
			wordLevel = False
			rotationDetection = False
			Return regions
		Case "getLangs"
			Return getLangs(Params.Get("loc"))
		Case "getSetupParams"
			Dim o As Object = CreateMap("readme":"https://github.com/xulihang/ImageTrans_plugins/tree/master/oneOCR")
			Return o
		Case "getIsInstalledOrRunning"
			InitIfNeeded
			Wait For (CheckIsRunning) complete (running As Boolean)
			Return running
		Case "SetCombination"
			Dim comb As String=Params.Get("combination")
			wordLevel = comb.Contains("word-level")
			rotationDetection = False
			If comb.Contains("rotationDetection") Then
				rotationDetection = True
			End If
		Case "GetCombinations"
			Return BuildCombinations
		Case "Multiple"
			Return True
		Case "rotationDetectionSupported"
			Return True
		Case "detectRotation"
			InitIfNeeded
			wait for (DetectRotation(Params.Get("img"))) complete (angle As Double)
			rotationDetection = False
			Return angle
	End Select
	Return ""
End Sub

Sub DetectRotation(img As B4XBitmap) As ResumableSub
	rotationDetection = True
	Dim degree As Double
	wait for (ocr(img)) complete (boxes As List)
	For i = 0 To boxes.Size - 1
		Dim box As Map = boxes.Get(i)
		If box.ContainsKey("degree") Then
			degree = box.Get("degree")
			Return degree
		End If
	Next
	Return degree
End Sub

Sub BuildCombinations As List
	Dim combs As List
	combs.Initialize
	combs.Add("oneocr")
	combs.Add("word-level (oneocr)")
	combs.Add("rotationdetection (oneocr)")
	Return combs
End Sub

Sub getLangs(loc As Localizator) As Map
	Dim result As Map
	result.Initialize
	Dim names,codes As List
	names.Initialize
	codes.Initialize
	codes.Add("auto")
	names.Add(loc.Localize("自动"))
	result.Put("names",names)
	result.Put("codes",codes)
	Return result
End Sub


Public Sub ImageToBytes(Image As B4XBitmap) As Byte()
	Dim out As OutputStream
	out.InitializeToBytesArray(0)
	Image.WriteToStream(out, 100, "JPEG")
	out.Close
	Return out.ToBytesArray
End Sub

Sub GetText(img As B4XBitmap) As ResumableSub
	wait for (engine.recognizeAsync(img)) complete (lines As List)
	Dim m As Map
	m.Initialize
	Dim sb As StringBuilder
	sb.Initialize
	For i = 0 To lines.Size - 1
		Dim line As JavaObject = lines.Get(i)
		sb.Append(line.GetField("text"))
		If i <> lines.Size - 1 Then
			sb.Append(CRLF)
		End If
	Next
	m.Put("text",sb.ToString)
	Dim j As JSONGenerator
	j.Initialize(m)
	Return j.ToString
End Sub

Sub GetTextWithLocation(img As B4XBitmap) As ResumableSub
	Dim regions As List
	regions.Initialize
	wait for (ocr(img)) complete (boxes As List)
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

Sub ocr(img As B4XBitmap) As ResumableSub
	Dim boxes As List
	boxes.Initialize
	wait for (engine.recognizeAsync(img)) complete (lines As List)
	addBoxesFromEngine(lines, boxes)
	Return boxes
End Sub

Sub addBoxesFromEngine(lines As List, boxes As List)
	Dim objects As List
	objects.Initialize
	For Each line As JavaObject In lines
		If wordLevel Then
			objects.AddAll(line.GetField("words"))
		Else
			objects.Add(line)
		End If
	Next
	For Each item As JavaObject In objects
		Dim quad() As Int = item.GetField("quad")
		Dim newBox As Map
		newBox.Initialize
		newBox.Put("text",item.GetField("text"))
		Dim minX,maxX,minY,maxY As Int
		minX = -1
		minY = -1
		For Each X As Int In Array(quad(0),quad(2),quad(4),quad(6))
			If minX = -1 Then
				minX = X
			Else
				minX = Min(minX,X)
			End If
			maxX = Max(maxX,X)
		Next
		For Each Y As Int In Array(quad(1),quad(3),quad(5),quad(7))
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
			Dim K As Double = (quad(3)-quad(1))/(quad(2)-quad(0))
			Dim degree As Int= ATan(K) * 180 / cPI
			If degree < 0 Then
				degree = degree + 360
			End If
			Dim point1(2) As Int = CalculateRotatedPosition(-degree,centerX,centerY,quad(0),quad(1))
			Dim point2(2) As Int = CalculateRotatedPosition(-degree,centerX,centerY,quad(2),quad(3))
			Dim point3(2) As Int = CalculateRotatedPosition(-degree,centerX,centerY,quad(4),quad(5))
			Dim point4(2) As Int = CalculateRotatedPosition(-degree,centerX,centerY,quad(6),quad(7))
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
		Dim width As Int = maxX - minX
		Dim height As Int = maxY - minY
		Dim left As Int = minX
		Dim top As Int = minY
		Dim boxGeometry As Map
		boxGeometry.Initialize
		boxGeometry.Put("X",left)
		boxGeometry.Put("Y",top)
		boxGeometry.Put("width",width)
		boxGeometry.Put("height",height)
		newBox.Put("geometry",boxGeometry)
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


Sub getMap(key As String,parentmap As Map) As Map
	Return parentmap.Get(key)
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

Private Sub ModelFolderExists As Boolean
	If File.Exists(engine.folder,"") Then
		Return True
	End If
	Return False
End Sub

Private Sub CheckIsRunning As ResumableSub
	If ModelFolderExists Then
		Return True
	Else
		Return False
	End If
End Sub

Sub readJsonAsMap(s As String) As Map
	Dim json As JSONParser
	json.Initialize(s)
	Return json.NextObject
End Sub
