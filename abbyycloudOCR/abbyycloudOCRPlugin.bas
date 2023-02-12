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
	Return "abbyycloudOCR"
End Sub

' must be available
public Sub Run(Tag As String, Params As Map) As ResumableSub
	Select Tag
		Case "getParams"
			Dim paramsList As List
			paramsList.Initialize
			paramsList.Add("password")
			paramsList.Add("id")
			Return paramsList
		Case "getText"
			wait for (GetText(Params.Get("img"),Params.Get("lang"))) complete (result As String)
			Return result
		Case "getTextWithLocation"
			wait for (GetTextWithLocation(Params.Get("img"),Params.Get("lang"))) complete (regions As List)
			Return regions
		Case "getLangs"
			Return getLangs(Params.Get("loc"))
	End Select
	Return ""
End Sub

Sub getLangs(loc As Localizator) As Map
	Dim result As Map
	result.Initialize
	Dim names,codes As List
	names.Initialize
	codes.Initialize
	codes.Add("Abkhaz")
	codes.Add("Adyghe")
	codes.Add("Afrikaans")
	codes.Add("Agul")
	codes.Add("Albanian")
	codes.Add("Altaic")
	codes.Add("Arabic")
	codes.Add("ArmenianEastern")
	codes.Add("ArmenianGrabar")
	codes.Add("ArmenianWestern")
	codes.Add("Avar")
	codes.Add("Aymara")
	codes.Add("AzeriCyrillic")
	codes.Add("AzeriLatin")
	codes.Add("Bashkir")
	codes.Add("Basque")
	codes.Add("Belarusian")
	codes.Add("Bemba")
	codes.Add("Blackfoot")
	codes.Add("Breton")
	codes.Add("Bugotu")
	codes.Add("Bulgarian")
	codes.Add("Buryat")
	codes.Add("Catalan")
	codes.Add("Chamorro")
	codes.Add("Chechen")
	codes.Add("ChinesePRC")
	codes.Add("ChineseTaiwan")
	codes.Add("Chukcha")
	codes.Add("Chuvash")
	codes.Add("CMC7")
	codes.Add("Corsican")
	codes.Add("CrimeanTatar")
	codes.Add("Croatian")
	codes.Add("Crow")
	codes.Add("Czech")
	codes.Add("Danish")
	codes.Add("Dargwa")
	codes.Add("Digits")
	codes.Add("Dungan")
	codes.Add("Dutch")
	codes.Add("DutchBelgian")
	codes.Add("E13B")
	codes.Add("English")
	codes.Add("EskimoCyrillic")
	codes.Add("EskimoLatin")
	codes.Add("Esperanto")
	codes.Add("Estonian")
	codes.Add("Even")
	codes.Add("Evenki")
	codes.Add("Farsi")
	codes.Add("Faeroese")
	codes.Add("Fijian")
	codes.Add("Finnish")
	codes.Add("French")
	codes.Add("Frisian")
	codes.Add("Friulian")
	codes.Add("GaelicScottish")
	codes.Add("Gagauz")
	codes.Add("Galician")
	codes.Add("Ganda")
	codes.Add("German")
	codes.Add("GermanLuxembourg")
	codes.Add("GermanNewSpelling")
	codes.Add("Greek")
	codes.Add("Guarani")
	codes.Add("Hani")
	codes.Add("Hausa")
	codes.Add("Hawaiian")
	codes.Add("Hebrew")
	codes.Add("Hungarian")
	codes.Add("Icelandic")
	codes.Add("Ido")
	codes.Add("Indonesian")
	codes.Add("Ingush")
	codes.Add("Interlingua")
	codes.Add("Irish")
	codes.Add("Italian")
	codes.Add("Japanese")
	codes.Add("Kabardian")
	codes.Add("Kalmyk")
	codes.Add("KarachayBalkar")
	codes.Add("Karakalpak")
	codes.Add("Kasub")
	codes.Add("Kawa")
	codes.Add("Kazakh")
	codes.Add("Khakas")
	codes.Add("Khanty")
	codes.Add("Kikuyu")
	codes.Add("Kirghiz")
	codes.Add("Kongo")
	codes.Add("Korean")
	codes.Add("KoreanHangul")
	codes.Add("Koryak")
	codes.Add("Kpelle")
	codes.Add("Kumyk")
	codes.Add("Kurdish")
	codes.Add("Lak")
	codes.Add("Lappish")
	codes.Add("Latin")
	codes.Add("Latvian")
	codes.Add("LatvianGothic")
	codes.Add("Lezgin")
	codes.Add("Lithuanian")
	codes.Add("Luba")
	codes.Add("Macedonian")
	codes.Add("Malagasy")
	codes.Add("Malay")
	codes.Add("Malinke")
	codes.Add("Maltese")
	codes.Add("Mansi")
	codes.Add("Maori")
	codes.Add("Mari")
	codes.Add("Maya")
	codes.Add("Miao")
	codes.Add("Minangkabau")
	codes.Add("Mohawk")
	codes.Add("Mongol")
	codes.Add("Mordvin")
	codes.Add("Nahuatl")
	codes.Add("Nenets")
	codes.Add("Nivkh")
	codes.Add("Nogay")
	codes.Add("Norwegian")
	codes.Add("NorwegianBokmal")
	codes.Add("NorwegianNynorsk")
	codes.Add("Nyanja")
	codes.Add("Occidental")
	codes.Add("Ojibway")
	codes.Add("OldEnglish")
	codes.Add("OldFrench")
	codes.Add("OldGerman")
	codes.Add("OldItalian")
	codes.Add("OldSlavonic")
	codes.Add("OldSpanish")
	codes.Add("Ossetian")
	codes.Add("Papiamento")
	codes.Add("PidginEnglish")
	codes.Add("Polish")
	codes.Add("PortugueseBrazilian")
	codes.Add("PortugueseStandard")
	codes.Add("Provencal")
	codes.Add("Quechua")
	codes.Add("RhaetoRomanic")
	codes.Add("Romanian")
	codes.Add("RomanianMoldavia")
	codes.Add("Romany")
	codes.Add("Ruanda")
	codes.Add("Rundi")
	codes.Add("RussianOldSpelling")
	codes.Add("Russian")
	codes.Add("Samoan")
	codes.Add("Selkup")
	codes.Add("SerbianCyrillic")
	codes.Add("SerbianLatin")
	codes.Add("Shona")
	codes.Add("Sioux (Dakota)")
	codes.Add("Slovak")
	codes.Add("Slovenian")
	codes.Add("Somali")
	codes.Add("Sorbian")
	codes.Add("Sotho")
	codes.Add("Spanish")
	codes.Add("Sunda")
	codes.Add("Swahili")
	codes.Add("Swazi")
	codes.Add("Swedish")
	codes.Add("Tabassaran")
	codes.Add("Tagalog")
	codes.Add("Tahitian")
	codes.Add("Tajik")
	codes.Add("Tatar")
	codes.Add("Thai")
	codes.Add("Jingpo")
	codes.Add("Tongan")
	codes.Add("Tswana")
	codes.Add("Tun")
	codes.Add("Turkish")
	codes.Add("Turkmen")
	codes.Add("Tuvan")
	codes.Add("Udmurt")
	codes.Add("UighurCyrillic")
	codes.Add("UighurLatin")
	codes.Add("Ukrainian")
	codes.Add("UzbekCyrillic")
	codes.Add("UzbekLatin")
	codes.Add("Vietnamese")
	codes.Add("Visayan")
	codes.Add("Welsh")
	codes.Add("Wolof")
	codes.Add("Xhosa")
	codes.Add("Yakut")
	codes.Add("Yiddish")
	codes.Add("Zapotec")
	codes.Add("Zulu")

	names.Add("Abkhaz")
	names.Add("Adyghe")
	names.Add("Afrikaans")
	names.Add("Agul")
	names.Add("Albanian")
	names.Add("Altaic")
	names.Add("Arabic (Saudi Arabia) ")
	names.Add("Armenian (Eastern) ")
	names.Add("Armenian (Grabar) ")
	names.Add("Armenian (Western) ")
	names.Add("Avar")
	names.Add("Aymara")
	names.Add("Azerbaijani (Cyrillic) ")
	names.Add("Azerbaijani (Latin) ")
	names.Add("Bashkir")
	names.Add("Basque")
	names.Add("Belarussian ")
	names.Add("Bemba")
	names.Add("Blackfoot")
	names.Add("Breton")
	names.Add("Bugotu")
	names.Add("Bulgarian")
	names.Add("Buryat")
	names.Add("Catalan")
	names.Add("Chamorro")
	names.Add("Chechen")
	names.Add("Chinese Simplified ")
	names.Add("Chinese Traditional ")
	names.Add("Chukcha")
	names.Add("Chuvash")
	names.Add("For MICR CMC-7 text type ")
	names.Add("Corsican")
	names.Add("Crimean Tatar ")
	names.Add("Croatian")
	names.Add("Crow")
	names.Add("Czech")
	names.Add("Danish")
	names.Add("Dargwa")
	names.Add("Numbers* ")
	names.Add("Dungan")
	names.Add("Dutch (Netherlands) ")
	names.Add("Dutch (Belgium) ")
	names.Add("For MICR (E-13B) text type ")
	names.Add("English")
	names.Add("Eskimo (Cyrillic) ")
	names.Add("Eskimo (Latin) ")
	names.Add("Esperanto")
	names.Add("Estonian")
	names.Add("Even")
	names.Add("Evenki")
	names.Add("Farsi")
	names.Add("Faeroese")
	names.Add("Fijian")
	names.Add("Finnish")
	names.Add("French")
	names.Add("Frisian")
	names.Add("Friulian")
	names.Add("Scottish Gaelic ")
	names.Add("Gagauz")
	names.Add("Galician")
	names.Add("Ganda")
	names.Add("German")
	names.Add("German (Luxembourg) ")
	names.Add("German (new spelling) ")
	names.Add("Greek")
	names.Add("Guarani")
	names.Add("Hani")
	names.Add("Hausa")
	names.Add("Hawaiian")
	names.Add("Hebrew")
	names.Add("Hungarian")
	names.Add("Icelandic")
	names.Add("Ido")
	names.Add("Indonesian")
	names.Add("Ingush")
	names.Add("Interlingua")
	names.Add("Irish")
	names.Add("Italian")
	names.Add("Japanese")
	names.Add("Kabardian")
	names.Add("Kalmyk")
	names.Add("Karachay-Balkar ")
	names.Add("Karakalpak")
	names.Add("Kasub")
	names.Add("Kawa")
	names.Add("Kazakh")
	names.Add("Khakas")
	names.Add("Khanty")
	names.Add("Kikuyu")
	names.Add("Kirghiz")
	names.Add("Kongo")
	names.Add("Korean")
	names.Add("Korean (Hangul) ")
	names.Add("Koryak")
	names.Add("Kpelle")
	names.Add("Kumyk")
	names.Add("Kurdish")
	names.Add("Lak")
	names.Add("Sami (Lappish) ")
	names.Add("Latin")
	names.Add("Latvian")
	names.Add("Latvian language written in Gothic script ")
	names.Add("Lezgin")
	names.Add("Lithuanian")
	names.Add("Luba")
	names.Add("Macedonian")
	names.Add("Malagasy")
	names.Add("Malay")
	names.Add("Malinke")
	names.Add("Maltese")
	names.Add("Mansi")
	names.Add("Maori")
	names.Add("Mari")
	names.Add("Maya")
	names.Add("Miao")
	names.Add("Minangkabau")
	names.Add("Mohawk")
	names.Add("Mongol")
	names.Add("Mordvin")
	names.Add("Nahuatl")
	names.Add("Nenets")
	names.Add("Nivkh")
	names.Add("Nogay")
	names.Add("NorwegianNynorsk + NorwegianBokmal ")
	names.Add("Norwegian (Bokmal) ")
	names.Add("Norwegian (Nynorsk) ")
	names.Add("Nyanja")
	names.Add("Occidental")
	names.Add("Ojibway")
	names.Add("Old English ")
	names.Add("Old French ")
	names.Add("Old German ")
	names.Add("Old Italian ")
	names.Add("Old Slavonic ")
	names.Add("Old Spanish ")
	names.Add("Ossetian")
	names.Add("Papiamento")
	names.Add("Tok Pisin ")
	names.Add("Polish")
	names.Add("Portuguese (Brazil) ")
	names.Add("Portuguese (Portugal) ")
	names.Add("Provencal")
	names.Add("Quechua")
	names.Add("Rhaeto-Romanic ")
	names.Add("Romanian")
	names.Add("Romanian (Moldavia) ")
	names.Add("Romany")
	names.Add("Ruanda")
	names.Add("Rundi")
	names.Add("Russian (old spelling) ")
	names.Add("Russian")
	names.Add("Samoan")
	names.Add("Selkup")
	names.Add("Serbian (Cyrillic) ")
	names.Add("Serbian (Latin) ")
	names.Add("Shona")
	names.Add("Sioux (Dakota)")
	names.Add("Slovak")
	names.Add("Slovenian")
	names.Add("Somali")
	names.Add("Sorbian")
	names.Add("Sotho")
	names.Add("Spanish")
	names.Add("Sunda")
	names.Add("Swahili")
	names.Add("Swazi")
	names.Add("Swedish")
	names.Add("Tabassaran")
	names.Add("Tagalog")
	names.Add("Tahitian")
	names.Add("Tajik")
	names.Add("Tatar")
	names.Add("Thai")
	names.Add("Jingpo")
	names.Add("Tongan")
	names.Add("Tswana")
	names.Add("Tun")
	names.Add("Turkish")
	names.Add("Turkmen")
	names.Add("Tuvan")
	names.Add("Udmurt")
	names.Add("Uighur (Cyrillic) ")
	names.Add("Uighur (Latin) ")
	names.Add("Ukrainian")
	names.Add("Uzbek (Cyrillic) ")
	names.Add("Uzbek (Latin) ")
	names.Add("Vietnamese")
	names.Add("Cebuano ")
	names.Add("Welsh")
	names.Add("Wolof")
	names.Add("Xhosa")
	names.Add("Yakut")
	names.Add("Yiddish")
	names.Add("Zapotec")
	names.Add("Zulu")

	result.Put("names",names)
	result.Put("codes",codes)
	Return result
End Sub

Sub GetText(img As B4XBitmap,lang As String) As ResumableSub
	wait for (DoOCR(img,lang)) complete (boxes As List)
	Dim sb As StringBuilder
	sb.Initialize
	For Each box As Map In boxes
		sb.Append(box.Get("text"))
		sb.Append(CRLF)
	Next
	Return sb.ToString
End Sub

Sub GetTextWithLocation(img As B4XBitmap,lang As String) As ResumableSub
	Dim regions As List
	regions.Initialize
	wait for (DoOCR(img,lang)) complete (boxes As List)
	For Each box As Map In boxes
		Dim region As Map=box.Get("geometry")
		region.Put("text",box.Get("text"))
		regions.Add(region)
	Next
	Return regions
End Sub

Sub DoOCR(img As B4XBitmap,lang As String) As ResumableSub
	Dim id,password As String
	Try
		If File.Exists(File.DirApp,"preferences.conf") Then
			Dim preferencesMap As Map = readJsonAsMap(File.ReadString(File.DirApp,"preferences.conf"))
			id=getMap("abbyycloud",getMap("api",preferencesMap)).Get("id")
			password=getMap("abbyycloud",getMap("api",preferencesMap)).Get("password")
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
	Dim toEncode As String=id&":"&password
	Dim authHeader As String
	authHeader="Basic "&su.EncodeBase64(toEncode.GetBytes("iso-8859-1"))
	Dim fd As MultipartFileData
	fd.Initialize
	fd.Dir=File.DirApp
	fd.FileName="image.jpg"
	fd.KeyName="upload"
	Dim url As String="https://cloud-westus.ocrsdk.com/"
	job.PostMultipart(url&"processImage?exportFormat=xml&language="&lang,Null,Array(fd))
	job.GetRequest.SetHeader("Authorization",authHeader)
	wait for (job) JobDone(job As HttpJob)
	If job.Success Then
		Try
			wait for (waitForResult(job.GetString,url,authHeader)) Complete (boxes As List)
			Return boxes
		Catch
			Log(LastException)
		End Try
	Else
		Log(job.ErrorMessage)
	End If
	job.Release
	Return boxes
End Sub

Sub waitForResult(xml As String,url As String,authHeader As String) As ResumableSub
	Dim boxes As List
	boxes.Initialize
	Dim id As String=getID(xml)
	If id<>"" Then
		Dim timeout As Int=45 'seconds
		Dim elapsed As Int=0
		Dim Completed As Boolean=getCompleted(xml)
		Do While Completed=False
			Dim job As HttpJob
			job.Initialize("job",Me)
			job.Download(url&"getTaskStatus?taskId="&id)
			job.GetRequest.SetHeader("Authorization",authHeader)
			wait for (job) JobDone(job As HttpJob)
			If job.Success Then
				xml=job.GetString
			End If
			Completed=getCompleted(xml)
			elapsed=elapsed+2
			If elapsed>timeout Then
				Exit
			End If
			Sleep(2000)
		Loop
		If Completed Then
			Log("completed")
			wait for (getResult(getUrl(xml))) Complete (result As String)
			Log(result)
			AddBoxesFromXML(boxes,result)
		End If
		
	End If
	Return boxes
End Sub

Sub AddBoxesFromXML(boxes As List,xml As String)
	Dim x2m As Xml2Map
	x2m.Initialize
	Dim root As Map=x2m.Parse(xml)
	Dim document As Map=root.Get("document")
	Dim page As Map=document.Get("page")
	Dim blocks As List=GetElements(page,"block")
	For Each block As Map In blocks
		If block.ContainsKey("text") Then
			Dim text As Map=block.Get("text")
			Dim paras As List=GetElements(text,"par")
			For Each para As Map In paras
				Dim lines As List=GetElements(para,"line")
				For Each line As Map In lines
					Dim attributes As Map=line.Get("Attributes")
					Dim l,t,r,b As Int
					l=attributes.Get("l")
					t=attributes.Get("t")
					r=attributes.Get("r")
					b=attributes.Get("b")
					Dim box As Map
					box.Initialize
					Dim boxGeometry As Map
					boxGeometry.Initialize
					boxGeometry.Put("X",l)
					boxGeometry.Put("Y",t)
					boxGeometry.Put("width",r-l)
					boxGeometry.Put("height",b-t)
					box.Put("geometry",boxGeometry)
					box.Put("text",MergedCharacters(line))
					boxes.Add(box)
				Next
			Next
		End If
	Next
End Sub

Sub MergedCharacters(line As Map) As String
	Dim sb As StringBuilder
	sb.Initialize
	Dim formatting As Map=line.Get("formatting")
	'Dim attributes As Map=formatting.Get("Attributes")
	'Dim lang As String=attributes.Get("lang")
	Dim chars As List=GetElements(formatting,"charParams")
	For Each c As Map In chars
		Dim text As String=c.Get("Text")
		sb.Append(text)
	Next
	Return sb.ToString.Trim
End Sub

Sub GetElements (m As Map, key As String) As List
	Dim res As List
	If m.ContainsKey(key) = False Then
		res.Initialize
		Return res
	Else
		Dim value As Object = m.Get(key)
		If value Is List Then Return value
		res.Initialize
		res.Add(value)
		Return res
	End If
End Sub

Sub getCompleted(xml As String) As Boolean
	Try
		Dim attributes As Map=getAttributes(xml)
		Dim status As String=attributes.Get("status")
		If status<>"Completed" Then
			Return False
		End If
	Catch
		Log(LastException)
	End Try
	Return True
End Sub

Sub getResult(url As String) As ResumableSub
	Dim job As HttpJob
	job.Initialize("job",Me)
	job.Download(url)
	wait for (job) JobDone(job As HttpJob)
	If job.Success Then
		Return job.GetString
	End If
	Return ""
End Sub

Sub getAttributes(xml As String) As Map
	Dim x2m As Xml2Map
	x2m.Initialize
	Dim root As Map=x2m.Parse(xml)
	Dim response As Map=root.Get("response")
	Dim task As Map=response.Get("task")
	Dim attributes As Map=task.Get("Attributes")
	Return attributes
End Sub

Sub getID(xml As String) As String
	Try
		Dim attributes As Map=getAttributes(xml)
		Dim id As String=attributes.Get("id")
		Return id
	Catch
		Log(LastException)
	End Try
    Return ""
End Sub

Sub getUrl(xml As String) As String
	Try
		Dim attributes As Map=getAttributes(xml)
		Dim resultUrl As String=attributes.Get("resultUrl")
		Return resultUrl
	Catch
		Log(LastException)
	End Try
    Return ""
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

