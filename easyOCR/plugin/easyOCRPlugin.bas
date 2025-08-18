B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=4.2
@EndOfDesignText@
Sub Class_Globals
	Private fx As JFX
	private rotationDetection as Boolean = False
End Sub

'Initializes the object. You can NOT add parameters to this method!
Public Sub Initialize() As String
	Log("Initializing plugin " & GetNiceName)
	' Here return a key to prevent running unauthorized plugins
	Return "MyKey"
End Sub

' must be available
public Sub GetNiceName() As String
	Return "easyocrOCR"
End Sub

' must be available
public Sub Run(Tag As String, Params As Map) As ResumableSub
	Log("run"&Params)
	Select Tag
		Case "getParams"
			Dim paramsList As List
			paramsList.Initialize
			paramsList.Add("url")
			Return paramsList
		Case "getText"
			wait for (GetText(Params.Get("img"),Params.Get("lang"))) complete (result As String)
			rotationDetection = False
			Return result
		Case "getTextWithLocation"
			wait for (GetTextWithLocation(Params.Get("img"),Params.Get("lang"))) complete (regions As List)
			rotationDetection = False
			Return regions
		Case "getLangs"
			Return getLangs
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

Sub getLangs As Map
	Dim result As Map
	result.Initialize
	Dim names,codes As List
	names.Initialize
	codes.Initialize
	names.add("Abaza")
	names.add("Adyghe")
	names.add("Afrikaans")
	names.add("Angika")
	names.add("Arabic")
	names.add("Assamese")
	names.add("Avar")
	names.add("Azerbaijani")
	names.add("Belarusian")
	names.add("Bulgarian")
	names.add("Bihari")
	names.add("Bhojpuri")
	names.add("Bengali")
	names.add("Bosnian")
	names.add("Simplified Chinese")
	names.add("Traditional Chinese")
	names.add("Chechen")
	names.add("Czech")
	names.add("Welsh")
	names.add("Danish")
	names.add("Dargwa")
	names.add("German")
	names.add("English")
	names.add("Spanish")
	names.add("Estonian")
	names.add("Persian (Farsi)")
	names.add("French")
	names.add("Irish")
	names.add("Goan Konkani")
	names.add("Hindi")
	names.add("Croatian")
	names.add("Hungarian")
	names.add("Indonesian")
	names.add("Ingush")
	names.add("Icelandic")
	names.add("Italian")
	names.add("Japanese")
	names.add("Kabardian")
	names.add("Korean")
	names.add("Kurdish")
	names.add("Latin")
	names.add("Lak")
	names.add("Lezghian")
	names.add("Lithuanian")
	names.add("Latvian")
	names.add("Magahi")
	names.add("Maithili")
	names.add("Maori")
	names.add("Mongolian")
	names.add("Marathi")
	names.add("Malay")
	names.add("Maltese")
	names.add("Nepali")
	names.add("Newari")
	names.add("Dutch")
	names.add("Norwegian")
	names.add("Occitan")
	names.add("Polish")
	names.add("Portuguese")
	names.add("Romanian")
	names.add("Russian")
	names.add("Serbian (cyrillic)")
	names.add("Serbian (latin)")
	names.add("Nagpuri")
	names.add("Slovak")
	names.add("Slovenian")
	names.add("Albanian")
	names.add("Swedish")
	names.add("Swahili")
	names.add("Tamil")
	names.add("Tabassaran")
	names.add("Thai")
	names.add("Tagalog")
	names.add("Turkish")
	names.add("Uyghur")
	names.add("Ukranian")
	names.add("Urdu")
	names.add("Uzbek")
	names.add("Vietnamese")
	codes.add("abq")
	codes.add("ady")
	codes.add("af")
	codes.add("ang")
	codes.add("ar")
	codes.add("as")
	codes.add("ava")
	codes.add("az")
	codes.add("be")
	codes.add("bg")
	codes.add("bh")
	codes.add("bho")
	codes.add("bn")
	codes.add("bs")
	codes.add("ch_sim")
	codes.add("ch_tra")
	codes.add("che")
	codes.add("cs")
	codes.add("cy")
	codes.add("da")
	codes.add("dar")
	codes.add("de")
	codes.add("en")
	codes.add("es")
	codes.add("et")
	codes.add("fa")
	codes.add("fr")
	codes.add("ga")
	codes.add("gom")
	codes.add("hi")
	codes.add("hr")
	codes.add("hu")
	codes.add("id")
	codes.add("inh")
	codes.add("is")
	codes.add("it")
	codes.add("ja")
	codes.add("kbd")
	codes.add("ko")
	codes.add("ku")
	codes.add("la")
	codes.add("lbe")
	codes.add("lez")
	codes.add("lt")
	codes.add("lv")
	codes.add("mah")
	codes.add("mai")
	codes.add("mi")
	codes.add("mn")
	codes.add("mr")
	codes.add("ms")
	codes.add("mt")
	codes.add("ne")
	codes.add("new")
	codes.add("nl")
	codes.add("no")
	codes.add("oc")
	codes.add("pl")
	codes.add("pt")
	codes.add("ro")
	codes.add("ru")
	codes.add("rs_cyrillic")
	codes.add("rs_latin")
	codes.add("sck")
	codes.add("sk")
	codes.add("sl")
	codes.add("sq")
	codes.add("sv")
	codes.add("sw")
	codes.add("ta")
	codes.add("tab")
	codes.add("th")
	codes.add("tl")
	codes.add("tr")
	codes.add("ug")
	codes.add("uk")
	codes.add("ur")
	codes.add("uz")
	codes.add("vi")
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
	Dim regions As List
	regions.Initialize
	wait for (ocr(img,lang)) complete (boxes As List)
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

Sub ocr(img As B4XBitmap, lang As String) As ResumableSub
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
	job.PostMultipart(getUrl,CreateMap("lang":lang), Array(fd))
	job.GetRequest.Timeout=240*1000
	Wait For (job) JobDone(job As HttpJob)
	If job.Success Then
		Try
			Log(job.GetString)
			Dim json As JSONParser
			json.Initialize(job.GetString)
			Dim result As Map=json.NextObject
			Dim textLines As List
			textLines=result.Get("text_lines")
			addBoxes(textLines,boxes)
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
			url=getMap("easyocr",getMap("api",preferencesMap)).GetDefault("url",url)
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
