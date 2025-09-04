B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=4.2
@EndOfDesignText@
Sub Class_Globals
	Private fx As JFX
	Private detectOnly As Boolean = False
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
	Return "paddleocrOCR"
End Sub

' must be available
public Sub Run(Tag As String, Params As Map) As ResumableSub
	'Log("run"&Params)
	Select Tag
		Case "getLangs"
			wait for (getLangs(Params.Get("loc"))) complete (langs As Map)
			Return langs
		Case "getParams"
			Dim paramsList As List
			paramsList.Initialize
			paramsList.Add("url")
			Return paramsList
		Case "getText"
			wait for (GetText(Params.Get("img"),Params.Get("lang"))) complete (result As String)
			detectOnly = False
			rotationDetection = False
			Return result
		Case "getTextWithLocation"
			wait for (GetTextWithLocation(Params.Get("img"),Params.Get("lang"))) complete (regions As List)
			detectOnly = False
			rotationDetection = False
			Return regions
		Case "getSetupParams"
			Dim o As Object = CreateMap("readme":"https://github.com/xulihang/ImageTrans_plugins/tree/master/paddleOCR")
			Return o
		Case "getIsInstalledOrRunning"
			Wait For (CheckIsRunning) complete (running As Boolean)
			Return running
		Case "SetCombination"
			Dim comb As String=Params.Get("combination")
			detectOnly = comb.Contains("detect only")
			rotationDetection = comb.Contains("rotationDetection")
		Case "GetCombinations"
			Return BuildCombinations
		Case "Multiple"
			Return True
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
	detectOnly = True
	Dim degree As Double
	wait for (ocr(img,lang)) complete (boxes As List)
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
	combs.Add("paddleocr")
	combs.Add("detect only (paddleocr)")
	Return combs
End Sub

Sub getLangs(loc As Localizator) As ResumableSub
	Dim result As Map
	result.Initialize
	Dim names,codes As List
	names.Initialize
	codes.Initialize
	names.Add(loc.Localize("中文"))
	codes.Add("ch")
	names.Add(loc.Localize("英语"))
	codes.Add("en")
	names.Add(loc.Localize("繁体中文"))
	codes.Add("chinese_cht")
	names.Add(loc.Localize("日语"))
	codes.Add("japan")
	names.Add(loc.Localize("韩语"))
	codes.Add("korean")
	names.Add(loc.Localize("德语"))
	codes.Add("de")
	names.Add(loc.Localize("南非荷兰语"))
	codes.Add("af")
	names.Add(loc.Localize("意大利语"))
	codes.Add("it")
	names.Add(loc.Localize("西班牙语"))
	codes.Add("es")
	names.Add(loc.Localize("波斯尼亚语"))
	codes.Add("bs")
	names.Add(loc.Localize("葡萄牙语"))
	codes.Add("pt")
	names.Add(loc.Localize("捷克语"))
	codes.Add("cs")
	names.Add(loc.Localize("威尔士语"))
	codes.Add("cy")
	names.Add(loc.Localize("丹麦语"))
	codes.Add("da")
	names.Add(loc.Localize("爱沙尼亚语"))
	codes.Add("et")
	names.Add(loc.Localize("爱尔兰语"))
	codes.Add("ga")
	names.Add(loc.Localize("克罗地亚语"))
	codes.Add("hr")
	names.Add(loc.Localize("乌兹别克语"))
	codes.Add("uz")
	names.Add(loc.Localize("俄罗斯语"))
	codes.Add("ru")
	names.Add(loc.Localize("乌克兰语"))
	codes.Add("uk")
	names.Add(loc.Localize("匈牙利语"))
	codes.Add("hu")
	names.Add(loc.Localize("塞尔维亚语"))
	codes.Add("rs_latin")
	names.Add(loc.Localize("印度尼西亚语"))
	codes.Add("id")
	names.Add(loc.Localize("欧西坦语"))
	codes.Add("oc")
	names.Add(loc.Localize("冰岛语"))
	codes.Add("is")
	names.Add(loc.Localize("立陶宛语"))
	codes.Add("lt")
	names.Add(loc.Localize("毛利语"))
	codes.Add("mi")
	names.Add(loc.Localize("马来语"))
	codes.Add("ms")
	names.Add(loc.Localize("荷兰语"))
	codes.Add("nl")
	names.Add(loc.Localize("挪威语"))
	codes.Add("no")
	names.Add(loc.Localize("波兰语"))
	codes.Add("pl")
	names.Add(loc.Localize("斯洛伐克语"))
	codes.Add("sk")
	names.Add(loc.Localize("斯洛语尼亚语"))
	codes.Add("sl")
	names.Add(loc.Localize("阿尔巴尼亚语"))
	codes.Add("sq")
	names.Add(loc.Localize("瑞典语"))
	codes.Add("sv")
	names.Add(loc.Localize("西瓦希里语"))
	codes.Add("sw")
	names.Add(loc.Localize("塔加洛语"))
	codes.Add("tl")
	names.Add(loc.Localize("土耳其语"))
	codes.Add("tr")
	names.Add(loc.Localize("拉丁语"))
	codes.Add("la")
	names.Add(loc.Localize("白俄罗斯语"))
	codes.Add("be")
	result.Put("names",names)
	result.Put("codes",codes)
	Return result
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
	Dim regions As List
	regions.Initialize
	wait for (ocr(img,lang)) complete (boxes As List)
	For Each box As Map In boxes
		Dim region As Map=box.Get("geometry")
		region.Put("text",box.Get("text"))
		addExtra(region,box)
		regions.Add(region)
	Next
	Log(regions)
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

Sub ocr(img As B4XBitmap, lang As String) As ResumableSub
	Dim boxes As List
	boxes.Initialize
	Dim localMode As Boolean = False
	Dim url As String = getUrl
	If detectOnly Then
		url = getUrl.Replace("ocr","detect")
	End If
	If url.StartsWith("http://127.0.0.1") And detectOnly Then
		localMode = True
	End If
	Dim uniqueName As String = GenerateUniqueName
	Dim path As String = File.Combine(File.DirApp,uniqueName)
	Dim out As OutputStream
	out=File.OpenOutput(path,"",False)
	img.WriteToStream(out,"100","JPEG")
	out.Close
	Dim job As HttpJob
	job.Initialize("",Me)
	job.Tag = uniqueName
	If localMode Then
		job.PostMultipart(url,CreateMap("lang":lang,"engine":"paddleocr","path":path), Null)
	Else
		Dim fd As MultipartFileData
		fd.Initialize
		fd.KeyName = "upload"
		fd.Dir = File.DirApp
		fd.FileName = uniqueName
		fd.ContentType = "image/jpg"
		job.PostMultipart(url,CreateMap("lang":lang,"engine":"paddleocr"), Array(fd))
    End If
	job.GetRequest.Timeout=240*1000
	Wait For (job) JobDone(job As HttpJob)
	File.Delete(path,"")
	If job.Success Then
		Try
			If job.Tag <> uniqueName Then
				Log("inconsistent name")
			Else
				'Log(job.GetString)
				Dim json As JSONParser
				json.Initialize(job.GetString)
				Dim result As Map=json.NextObject
				Dim textLines As List
				textLines=result.Get("text_lines")
				addBoxes(textLines,boxes)
			End If
		Catch
			Log(LastException)
		End Try
	End If
	job.Release
	Return boxes
End Sub

private Sub GenerateUniqueName As String
	Dim randomNumber As Int = Rnd(0,1000)
	Dim timestamp As String = DateTime.Now
	Return timestamp&"-"&randomNumber&".jpg"
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

Sub getMap(key As String,parentmap As Map) As Map
	Return parentmap.Get(key)
End Sub

Sub getUrl As String
	Dim url As String = "http://127.0.0.1:8080/ocr"
	If File.Exists(File.DirApp,"preferences.conf") Then
		Try
			Dim preferencesMap As Map = readJsonAsMap(File.ReadString(File.DirApp,"preferences.conf"))
			url=getMap("paddleocr",getMap("api",preferencesMap)).GetDefault("url",url)
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
