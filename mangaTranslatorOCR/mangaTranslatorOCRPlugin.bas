B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=4.2
@EndOfDesignText@
Sub Class_Globals
	Private fx As JFX
	Private wordlevel As Boolean = False
	Private detectors As List
	Private recognizers As List
	Private skip_recognization As String
	Private detectColor As Boolean = False
	Private useCTC As Boolean = False
	Private use48px As Boolean = False
	Private recognizerAffix As String="_recognizer"
	Private detectorAffix As String="_detector"
	Private nameAffix As String = " (mangaTranslator)"
	Private rotationDetection As Boolean = False
End Sub

'Initializes the object. You can NOT add parameters to this method!
Public Sub Initialize() As String
	Log("Initializing plugin " & GetNiceName)
	' Here return a key to prevent running unauthorized plugins
	detectors.Initialize
	detectors.AddAll(Array As String("db"))
	recognizers.Initialize
	recognizers.AddAll(Array As String("OCR","OCR-CTC","OCR-48px"))
	Return "MyKey"
End Sub

' must be available
public Sub GetNiceName() As String
	Return "mangaTranslatorOCR"
End Sub

' must be available
public Sub Run(Tag As String, Params As Map) As ResumableSub
	Select Tag
		Case "getParams"
			Dim paramsList As List
			paramsList.Initialize
			paramsList.Add("url")
			Return paramsList
		Case "getSetupParams"
			Dim o As Object = CreateMap("readme":"https://github.com/xulihang/ImageTrans_plugins/tree/master/mangaTranslatorOCR")
			Return o
		Case "getIsInstalledOrRunning"
			Wait For (CheckIsRunning) complete (running As Boolean)
			Return running
		Case "getDefaultParamValues"
			Return CreateMap("url":"http://127.0.0.1:8080/ocr")
		Case "getText"
			wait for (GetText(Params.Get("img"),Params.Get("lang"))) complete (result As String)
			Return result
		Case "getTextWithLocation"
			wait for (GetTextWithLocation(Params.Get("img"),Params.Get("lang"),Params.GetDefault("path",""),Params.GetDefault("generateMaskDuringSceneTextDetection",False))) complete (regions As List)
			Return regions
		Case "WordLevel"
			Return wordlevel
		Case "SetCombination"
			Dim comb As String=Params.Get("combination")
			skip_recognization=""
			detectColor = False
			rotationDetection = False
			useCTC = False
			use48px = False
			If comb.Contains("CTC") Then
				useCTC = True
			End If
			If comb.Contains("48px") Then
				use48px = True
			End If
			If comb.Contains("+")=False Then
				If comb.Contains(detectorAffix) Then
					skip_recognization="true"
					Return ""
				End If
			Else
				If comb.Contains("colordetection") Then
					detectColor = True
				End If
				If comb.Contains("rotationdetection") Then
					rotationDetection = True
				End If
			End If
		Case "GetCombinations"
			Return BuildCombinations
		Case "Multiple"
			Return True
	End Select
	Return ""
End Sub

Private Sub CheckIsRunning As ResumableSub
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

Sub BuildCombinations As List
	Dim combs As List
	combs.Initialize
	For Each d_name As String In detectors
		combs.Add(d_name&detectorAffix&nameAffix)
		For Each r_name As String In recognizers			
			combs.Add(d_name&"+"&r_name&nameAffix)
			combs.Add(d_name&"+"&r_name&"+colordetection"&nameAffix)
			combs.Add(d_name&"+"&r_name&"+colordetection+rotationdetection"&nameAffix)
		Next
	Next
	Return combs
End Sub

Sub GetText(img As B4XBitmap, lang As String) As ResumableSub
	wait for (ocr(img,lang,"",False)) complete (boxes As List)
	Dim m As Map
	m.Initialize
	Dim sb As StringBuilder
	sb.Initialize
	For i = 0 To boxes.Size - 1
		Dim box As Map = boxes.Get(i)
		sb.Append(box.Get("text"))
		If (box.ContainsKey("textColor") Or box.ContainsKey("degree")) And m.ContainsKey("extra") = False Then
			Dim extra As Map
			extra.Initialize
			If box.ContainsKey("textColor") Then
				extra.Put("textColor",box.Get("textColor"))
			End If
			If box.ContainsKey("degree") Then
				extra.Put("degree",box.Get("degree"))
			End If
			m.Put("extra",extra)
		End If
		If i <> boxes.Size -1 Then
			sb.Append(CRLF)
		End If
	Next
	m.Put("text",sb.ToString)
	Dim j As JSONGenerator
	j.Initialize(m)
	Return j.ToString
End Sub

Sub GetTextWithLocation(img As B4XBitmap, lang As String, path As String,generateMask As Boolean) As ResumableSub
	Dim regions As List
	regions.Initialize
	wait for (ocr(img,lang,path,generateMask)) complete (boxes As List)
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


Sub ocr(img As B4XBitmap,lang As String,path As String,generateMask As Boolean) As ResumableSub
	Dim boxes As List
	boxes.Initialize
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
	Dim params As Map
	params.Initialize
	params.Put("skip_recognization",skip_recognization)
	If generateMask Then
		params.Put("generate_mask","true")
	Else
		params.Put("generate_mask","false")
	End If
	If useCTC Then
		params.Put("use_ctc","true")
	Else
		params.Put("use_ctc","false")
	End If
	If use48px Then
		params.Put("use_48px","true")
	Else
		params.Put("use_48px","false")
	End If
	job.PostMultipart(getUrl,params,Array(fd))
	job.GetRequest.Timeout=240*1000
	Wait For (job) JobDone(job As HttpJob)
	If job.Success Then
		Try
			Log(job.GetString)
			Dim json As JSONParser
			json.Initialize(job.GetString)
			Dim result As Map=json.NextObject
			Dim detectedBoxes As List
			detectedBoxes=result.Get("boxes")
			addBoxes(detectedBoxes,boxes)
			If generateMask Then
				If result.ContainsKey("mask") Then
					If detectedBoxes.Size > 0 Then
						Dim box As Map = boxes.Get(0)
						box.Put("mask",result.get("mask"))
					End If
				End If
			End If
		Catch
			Log(LastException)
		End Try
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
			newBox.Put("degree",degree)
		End If
		width = maxX - minX
		height = maxY - minY
		left = minX
		top = minY
		If detectColor Then
			If box.ContainsKey("fg_r") Then
				Dim fgR,fgG,fgB As Int
				fgR = box.Get("fg_b") 'bgr -> rgb
				fgG = box.Get("fg_g")
				fgB = box.Get("fg_r")
				newBox.Put("textColor",fgR&","&fgG&","&fgB)
			End If
		End If
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

Sub getMap(key As String,parentmap As Map) As Map
	Return parentmap.Get(key)
End Sub

Sub getUrl As String
	Dim url As String = "http://127.0.0.1:8080/ocr"
	If File.Exists(File.DirApp,"preferences.conf") Then
		Try
			Dim preferencesMap As Map = readJsonAsMap(File.ReadString(File.DirApp,"preferences.conf"))
			url=getMap("mangaTranslator",getMap("api",preferencesMap)).GetDefault("url",url)
		Catch
			Log(LastException)
		End Try
	End If
	Return url
End Sub

Sub readJsonAsMap(s As String) As Map
	Dim json As JSONParser
	json.Initialize(s)
	Return json.NextObject
End Sub
