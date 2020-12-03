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
			Return result
		Case "getTextWithLocation"
			wait for (GetTextWithLocation(Params.Get("img"),Params.Get("lang"))) complete (regions As List)
			Return regions
		Case "getLangs"
			Return getLangs
	End Select
	Return ""
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
		regions.Add(region)
	Next
	Return regions
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
			textLinesToBoxes(textLines,boxes)
		Catch
			Log(LastException)
		End Try
	End If
	Return boxes
End Sub

Sub textLinesToBoxes(textLines As List,boxes As List)
	For Each line As Map In textLines
		Dim box As Map
		box.Initialize
		box.put("text",line.GetDefault("text",""))
		Dim boxGeometry As Map
		boxGeometry.Initialize
		Dim X,Y,width,height As Int
		X=Min(line.get("x0"),line.Get("x2"))
		Y=Min(line.get("y0"),line.Get("y1"))
		width=Max(line.Get("x1"),line.get("x3"))-X
		height=Max(line.get("y1"),line.Get("y3"))-Y
		boxGeometry.Put("X",X)
		boxGeometry.Put("Y",Y)
		boxGeometry.Put("width",width)
		boxGeometry.Put("height",height)
		box.Put("geometry",boxGeometry)
		'box.Put("std",True)
		boxes.Add(box)
	Next
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
