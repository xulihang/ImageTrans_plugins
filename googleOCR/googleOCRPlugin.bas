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
	Return "googleOCR"
End Sub

' must be available
public Sub Run(Tag As String, Params As Map) As ResumableSub
	Log("run"&Params)
	Select Tag
		Case "getParams"
			Dim paramsList As List
			paramsList.Initialize
			paramsList.Add("key")
			paramsList.Add("type (document or text)")
			Return paramsList
		Case "getText"
			wait for (GetText(Params.Get("img"),Params.Get("lang"))) complete (result As String)
			Return result
		Case "getTextWithLocation"
			wait for (GetTextWithLocation(Params.Get("img"),Params.Get("lang"))) complete (regions As List)
			Return regions
		Case "getLangs"
			Return getLangs
		Case "getDefaultParamValues"
			Return CreateMap("type (document or text)":"document")
	End Select
	Return ""
End Sub

Sub getLangs As Map
	Dim result As Map
	result.Initialize
	Dim names,codes As List
	names.Initialize
	codes.Initialize
	codes.Add("auto")
	codes.Add("af")
	codes.Add("sq")
	codes.Add("ar")
	codes.Add("hy")
	codes.Add("be")
	codes.Add("bn")
	codes.Add("bg")
	codes.Add("ca")
	codes.Add("zh")
	codes.Add("hr")
	codes.Add("cs")
	codes.Add("da")
	codes.Add("nl")
	codes.Add("en")
	codes.Add("et")
	codes.Add("fil (or tl)")
	codes.Add("fi")
	codes.Add("fr")
	codes.Add("de")
	codes.Add("el")
	codes.Add("gu")
	codes.Add("iw")
	codes.Add("hi")
	codes.Add("hu")
	codes.Add("is")
	codes.Add("id")
	codes.Add("it")
	codes.Add("ja")
	codes.Add("kn")
	codes.Add("km")
	codes.Add("ko")
	codes.Add("lo")
	codes.Add("lv")
	codes.Add("lt")
	codes.Add("mk")
	codes.Add("ms")
	codes.Add("ml")
	codes.Add("mr")
	codes.Add("ne")
	codes.Add("no")
	codes.Add("fa")
	codes.Add("pl")
	codes.Add("pt")
	codes.Add("pa")
	codes.Add("ro")
	codes.Add("ru")
	codes.Add("ru-PETR1708")
	codes.Add("sr")
	codes.Add("sr-Latn")
	codes.Add("sk")
	codes.Add("sl")
	codes.Add("es")
	codes.Add("sv")
	codes.Add("ta")
	codes.Add("te")
	codes.Add("th")
	codes.Add("tr")
	codes.Add("uk")
	codes.Add("vi")
	codes.Add("yi")
	names.Add("Auto detect")
	names.Add("Afrikaans")
	names.Add("Albanian")
	names.Add("Arabic")
	names.Add("Armenian")
	names.Add("Belorussian")
	names.Add("Bengali")
	names.Add("Bulgarian")
	names.Add("Catalan")
	names.Add("Chinese")
	names.Add("Croatian")
	names.Add("Czech")
	names.Add("Danish")
	names.Add("Dutch")
	names.Add("English")
	names.Add("Estonian")
	names.Add("Filipino")
	names.Add("Finnish")
	names.Add("French")
	names.Add("German")
	names.Add("Greek")
	names.Add("Gujarati")
	names.Add("Hebrew")
	names.Add("Hindi")
	names.Add("Hungarian")
	names.Add("Icelandic")
	names.Add("Indonesian")
	names.Add("Italian")
	names.Add("Japanese")
	names.Add("Kannada")
	names.Add("Khmer")
	names.Add("Korean")
	names.Add("Lao")
	names.Add("Latvian")
	names.Add("Lithuanian")
	names.Add("Macedonian")
	names.Add("Malay")
	names.Add("Malayalam")
	names.Add("Marathi")
	names.Add("Nepali")
	names.Add("Norwegian")
	names.Add("Persian")
	names.Add("Polish")
	names.Add("Portuguese")
	names.Add("Punjabi")
	names.Add("Romanian")
	names.Add("Russian")
	names.Add("Russian")
	names.Add("Serbian")
	names.Add("Serbian")
	names.Add("Slovak")
	names.Add("Slovenian")
	names.Add("Spanish")
	names.Add("Swedish")
	names.Add("Tamil")
	names.Add("Telugu")
	names.Add("Thai")
	names.Add("Turkish")
	names.Add("Ukrainian")
	names.Add("Vietnamese")
	names.Add("Yiddish")
	result.Put("names",names)
	result.Put("codes",codes)
	Return result
End Sub

Sub GetText(img As B4XBitmap,lang As String) As ResumableSub
	wait for (ocr(img,lang,True)) complete (text As String)
	Return text
End Sub

Sub GetTextWithLocation(img As B4XBitmap,lang As String) As ResumableSub
	Dim regions As List
	regions.Initialize
	wait for (ocr(img,lang,False)) complete (boxes As List)
	For Each box As Map In boxes
		Dim region As Map=box.Get("geometry")
		region.Put("text",box.Get("text"))
		regions.Add(region)
	Next
	Return regions
End Sub

Sub ocr(img As B4XBitmap,lang As String,textOnly As Boolean) As ResumableSub
	Dim key As String
	Dim detectionType As String="DOCUMENT_TEXT_DETECTION"
	Try
		If File.Exists(File.DirApp,"preferences.conf") Then
			Dim preferencesMap As Map = readJsonAsMap(File.ReadString(File.DirApp,"preferences.conf"))
			key=getMap("google",getMap("api",preferencesMap)).Get("key")
			Select getMap("google",getMap("api",preferencesMap)).GetDefault("type (document or text)","document")
				Case "document"
					detectionType="DOCUMENT_TEXT_DETECTION"
				Case "text"
					detectionType="TEXT_DETECTION"
			End Select
		End If
	Catch
		Log(LastException)
		Return ""
	End Try
	Dim boxes As List
	boxes.Initialize
	saveImgToDiskWithSizeCheck(img,100,5000000)
	Dim resultMap As Map
	resultMap.Initialize
	Dim job As HttpJob
	job.Initialize("",Me)
	Dim su As StringUtils
	Dim base64 As String=su.EncodeBase64(File.ReadBytes(File.DirApp,"image.jpg"))
	
	Dim requests As List
	requests.Initialize
	Dim body As Map
	body.Initialize
	body.Put("requests",requests)
	Dim request As Map
	request.Initialize
	Dim imageMap As Map
	imageMap.Initialize
	imageMap.Put("content",base64)
	Dim features As List
	features.Initialize
	Dim feature As Map
	feature.Initialize
	feature.Put("type",detectionType)
	features.Add(feature)
	request.Put("image",imageMap)
	request.Put("features",features)
	If lang.StartsWith("auto")=False Then
		Dim hints As List
		hints.Initialize
		hints.Add(lang)
		Dim context As Map
		context.Initialize
		context.Put("languageHints",hints)
		request.Put("imageContext",context)
	End If
	requests.Add(request)
	Dim jsonG As JSONGenerator
	jsonG.Initialize(body)
	job.PostString("https://vision.googleapis.com/v1/images:annotate?key="&key,jsonG.ToString)
	'job.GetRequest.SetHeader("Authorization","Bearer "&key)
	job.GetRequest.SetContentType("application/json; charset=utf-8")
	wait for (job) JobDone(job As HttpJob)
	If job.Success Then
		Try
			Log(job.GetString)
			'File.WriteString(File.DirApp,"out.json",job.GetString)
			Dim responses As List
			Dim json As JSONParser
			json.Initialize(job.GetString)
			responses=json.NextObject.Get("responses")
			Dim response As Map=responses.Get(0)
			Dim fullTextAnnotation As Map=response.Get("fullTextAnnotation")
			If textOnly Then
				Return fullTextAnnotation.GetDefault("text","")
			End If
			Dim pages As List=fullTextAnnotation.Get("pages")
			For Each page As Map In pages
				Dim blocks As List = page.Get("blocks")
				Log(blocks.Size&" blocks")
				
				For Each block As Map In blocks
					Dim paragraphs As List=block.Get("paragraphs")
					Log(paragraphs.Size&" paras")
					For Each paragraph As Map In paragraphs
						boxes.Add(Paragraph2Box(paragraph))
					Next
				Next
			Next
		Catch
			Log(LastException)
		End Try
	End If
	job.Release
	RemoveOverlapped(boxes)
	If textOnly Then
		Return ""
	Else
		Return boxes
	End If
End Sub

Sub Paragraph2Box(paragraph As Map) As Map
	Dim box As Map
	box.Initialize
	Dim boundingBox As Map=paragraph.Get("boundingBox")
	Dim vertices As List=boundingBox.Get("vertices")
	Dim minX,maxX,minY,maxY As Int
	Dim index As Int=0
	For Each point As Map In vertices
		Dim x As Int=point.GetDefault("x",0)
		Dim y As Int=point.GetDefault("y",0)
		If index=0 Then
			minX=x
			minY=y
		Else
			minX=Min(minX,x)
			minY=Min(minY,y)
		End If
		maxX=Max(x,maxX)
		maxY=Max(y,maxY)
		index=index+1
	Next
	Dim boxGeometry As Map
	boxGeometry.Initialize
	boxGeometry.Put("X",minX)
	boxGeometry.Put("Y",minY)
	boxGeometry.Put("width",maxX-minX)
	boxGeometry.Put("height",maxY-minY)
	box.Put("geometry",boxGeometry)
	
	Dim sb As StringBuilder
	sb.Initialize
	Dim words As List=paragraph.Get("words")
	For Each word As Map In words
		Dim HasSpace As Boolean=True
		If word.ContainsKey("property") Then
			Dim property As Map=word.Get("property")
			Dim detectedLanguages As List=property.Get("detectedLanguages")
			For Each language As Map In detectedLanguages
				Dim langcode As String=language.Get("languageCode")
				If langcode.StartsWith("zh") Or langcode.StartsWith("ja") Then
					HasSpace=False
				End If
			Next
		End If
		Dim symbols As List=word.Get("symbols")
		For Each symbol As Map In symbols
			sb.Append(symbol.Get("text"))
		Next
		If HasSpace Then
			sb.Append(" ")
		End If
	Next
	box.Put("text",sb.ToString.Trim)
	Return box
End Sub

Sub RemoveOverlapped(boxes As List)
	Dim new As List
	new.Initialize
	For i=0 To boxes.Size-1
		Dim shouldRemove As Boolean=False
		Dim box1 As Map=boxes.Get(i)
		Dim geometry1 As Map
		geometry1=box1.Get("geometry")
		For j=0 To boxes.Size-1
			Dim box2 As Map=boxes.Get(j)
			Dim geometry2 As Map
			geometry2=box2.Get("geometry")
			If Utils.OverlappingPercent(geometry1,geometry2)>0.5 Then
				If GetArea(geometry1)<GetArea(geometry2) Then
					shouldRemove=True
				End If
			End If
		Next
		If shouldRemove=False Then
			new.Add(box1)
		End If
	Next
	boxes.Clear
	boxes.Addall(new)
End Sub

Sub GetArea(boxGeometry As Map) As Int
	Dim width,height As Int
	width=boxGeometry.Get("width")
	height=boxGeometry.Get("height")
	Return width*height
End Sub

Sub getMap(key As String,parentmap As Map) As Map
	Return parentmap.Get(key)
End Sub

Sub readJsonAsMap(s As String) As Map
	Dim json As JSONParser
	json.Initialize(s)
	Return json.NextObject
End Sub

Sub saveImgToDiskWithSizeCheck(img As B4XBitmap,quality As Int, sizeLimit As Int)
	Dim imgPath As String=File.Combine(File.DirApp,"image.jpg")
	Dim out As OutputStream=File.OpenOutput(imgPath,"",False)
	img.WriteToStream(out,quality,"JPEG")
	out.Close
	Dim su As StringUtils
	Dim base64 As String=su.EncodeBase64(File.ReadBytes(File.DirApp,"image.jpg"))
	If base64.Length>sizeLimit Then
		Log("bigger than limit")
		If quality>=10 Then
			saveImgToDiskWithSizeCheck(img,quality-10,sizeLimit)
		End If
	End If
End Sub

