B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=4.2
@EndOfDesignText@
Sub Class_Globals
	Private fx As JFX
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
	Return "macOCR"
End Sub

' must be available
public Sub Run(Tag As String, Params As Map) As ResumableSub
	Select Tag
		Case "getParams"
			Dim paramsList As List
			paramsList.Initialize
			paramsList.Add("placeholder")
			Return paramsList
		Case "getText"
			wait for (GetText(Params.Get("img"),Params.Get("lang"),Params.GetDefault("imgName",""))) complete (result As String)
			rotationDetection = False
			Return result
		Case "getTextWithLocation"
			wait for (GetTextWithLocation(Params.Get("img"),Params.Get("lang"),Params.GetDefault("imgName",""))) complete (regions As List)
			rotationDetection = False
			Return regions
		Case "isUsingShell"
			Return True
		Case "getResult"
			Dim boxes As List
			boxes.Initialize
			Dim parsed As Boolean = parseResult(boxes,Params.Get("imgName"))
			If parsed Then
				Return boxes
			Else
				Return False
			End If
		Case "getLangs"
			wait for (getLangs) complete (langs As Map)
			Return langs
		Case "SetCombination"
			Dim comb As String=Params.Get("combination")
			rotationDetection = comb.Contains("rotationDetection")
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
	wait for (ocr(img,lang,"")) complete (result As Map)
	Dim Lines As List=result.Get("lines")
	If result.ContainsKey("lines") Then
		Dim Lines As List=result.Get("lines")
		Dim hasVertices As Boolean
		If Lines.Size>0 Then
			Dim line As Map = Lines.Get(0)
			If line.ContainsKey("x0") Then
				hasVertices = True
			End If
		End If
		If hasVertices And rotationDetection Then
		    Dim boxes As List
		    boxes.Initialize
		    addBoxes(Lines,boxes)
		End If
		For i = 0 To boxes.Size - 1
			Dim box As Map = boxes.Get(i)
			If box.ContainsKey("degree") Then
				degree = box.Get("degree")
				Return degree
			End If
		Next
	End If
	Return degree
End Sub

Sub getLangs As ResumableSub
	Dim result As Map
	result.Initialize
	Dim names,codes As List
	names.Initialize
	codes.Initialize
	Dim executable As String
	executable="./OCR"
	Dim sh As Shell
	sh.Initialize("sh",executable,Array("--langs"))
	sh.Encoding=GetSystemProperty("file.encoding","UTF8")
	sh.WorkingDirectory=File.DirApp
	sh.Run(10000)
	wait for sh_ProcessCompleted (Success As Boolean, ExitCode As Int, StdOut As String, StdErr As String)
	If Success And ExitCode = 0 Then
	    Log(StdOut)
		Dim data As List
		data.Initialize
		data.AddAll(Regex.Split(CRLF,StdOut))
		Try
			For i=0 To data.Size-1
				Dim name As String=data.Get(i)
				Dim code As String=data.Get(i)
				names.Add(name.Trim)
				codes.Add(code.Trim)
			Next
		Catch
			Log(LastException)
		End Try
	End If
	result.Put("names",names)
	result.Put("codes",codes)
	Return result
End Sub

Sub GetText(img As B4XBitmap, lang As String, imgName As String) As ResumableSub
	wait for (ocr(img,lang,imgName)) complete (result As Map)
	Return result.GetDefault("text","")
End Sub

Sub GetTextWithLocation(img As B4XBitmap, lang As String, imgName As String) As ResumableSub
	wait for (ocr(img,lang,imgName)) complete (result As Map)
	If result.ContainsKey("lines") Then
		Dim Lines As List=result.Get("lines")
		Dim hasVertices As Boolean
		If Lines.Size>0 Then
			Dim line As Map = Lines.Get(0)
			If line.ContainsKey("x0") Then
				hasVertices = True
			End If
		End If
		If hasVertices And rotationDetection Then
			Dim boxes As List
			boxes.Initialize
			addBoxes(Lines,boxes)
			Dim regions As List
			regions.Initialize
			For Each box As Map In boxes
				Dim region As Map=box.Get("geometry")
				region.Put("text",box.Get("text"))
				addExtra(region,box)
				regions.Add(region)
			Next
			Return regions
		Else
			Return LinesToRegions(Lines)
		End If
	Else
		Dim boxes As List
		boxes.Initialize
		Return boxes
	End If
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

private Sub LinesToBoxes(lines As List) As List
	Dim boxes As List
	boxes.Initialize
	For Each line As Map In lines
		Dim box As Map
		box.Initialize
		Dim sb As StringBuilder
		sb.Initialize
		sb.Append(line.Get("text"))
		Dim x,y,width,height As Int
		x = line.Get("x")
		y = line.Get("y")
		width = line.Get("width")
		height = line.Get("height")
		Dim geometry As Map
		geometry.Initialize
		geometry.Put("X",x)
		geometry.Put("Y",y)
		geometry.Put("width",width)
		geometry.Put("height",height)
		box.Put("text",sb.ToString)
		box.Put("geometry",geometry)
		boxes.Add(box)
	Next
	Return boxes
End Sub

private Sub LinesToRegions(lines As List) As List
	Dim boxes As List
	boxes.Initialize
	For Each line As Map In lines
		Dim box As Map
		box.Initialize
		Dim sb As StringBuilder
		sb.Initialize
		sb.Append(line.Get("text"))
		Dim x,y,width,height As Int
		x = line.Get("x")
		y = line.Get("y")
		width = line.Get("width")
		height = line.Get("height")
		box.Put("X",x)
		box.Put("Y",y)
		box.Put("width",width)
		box.Put("height",height)
		box.Put("text",sb.ToString)
		boxes.Add(box)
	Next
	Return boxes
End Sub

private Sub GenerateUniqueName As String
	Dim randomNumber As Int = Rnd(0,1000)
	Dim timestamp As String = DateTime.Now
	Return timestamp&"-"&randomNumber&".jpg"
End Sub

Sub ocr(img As B4XBitmap, Lang As String,imgName As String) As ResumableSub
	Dim result As Map
	result.Initialize
	'Dim json As JSONParser 'test code for windows
	'json.Initialize(File.ReadString(File.DirApp,"test.json"))
	'result = json.NextObject
	'Return result
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
	If File.Exists(File.DirApp,imgName&"-out.json") Then
		File.Delete(File.DirApp,imgName&"out.json")
	End If
	Dim executable As String
	executable="./OCR"
	Dim sh As Shell
	sh.Initialize("sh",executable,Array(Lang,"false","true",imgName,imgName&"-out.json"))
	sh.WorkingDirectory=File.DirApp
	sh.Run(10000)
	wait for sh_ProcessCompleted (Success As Boolean, ExitCode As Int, StdOut As String, StdErr As String)
	If Success And ExitCode = 0 Then
		Dim jsonPath As String = File.Combine(File.DirApp,imgName&"-out.json")
		If File.Exists(jsonPath,"") Then
			Dim jsonString As String=File.ReadString(jsonPath,"")
			Dim json As JSONParser
			json.Initialize(jsonString)
			result = json.NextObject
		End If
	End If
	If imgNamePassed = False Then
		File.Delete(jsonPath,"")
	End If
	File.Delete(File.DirApp,imgName)
	Return result
End Sub

private Sub parseResult(boxes As List,imgName As String) As Boolean
	Dim jsonPath As String = File.Combine(File.DirApp,imgName&"-out.json")
	If File.Exists(jsonPath,"") Then
		Dim jsonString As String=File.ReadString(jsonPath,"")
		Dim json As JSONParser
		json.Initialize(jsonString)
		Dim result As Map =json.NextObject
		If result.ContainsKey("lines") Then
		    Dim Lines As List=result.Get("lines")
			boxes.AddAll(LinesToBoxes(Lines))
		End If
		File.Delete(jsonPath,"")
		Return True
	Else
		Return False
	End If
End Sub
