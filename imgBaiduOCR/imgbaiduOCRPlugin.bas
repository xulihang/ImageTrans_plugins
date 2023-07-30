B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=4.2
@EndOfDesignText@
Sub Class_Globals

End Sub

'Initializes the object. You can NOT add parameters to this method!
Public Sub Initialize() As String
	Log("Initializing plugin " & GetNiceName)
	' Here return a key to prevent running unauthorized plugins
	Return "MyKey"
End Sub

' must be available
public Sub GetNiceName() As String
	Return "imgbaiduOCR"
End Sub

' must be available
public Sub Run(Tag As String, Params As Map) As ResumableSub
	Log("run"&Params)
	Select Tag
		Case "getParams"
			Dim paramsList As List
			paramsList.Initialize
			paramsList.Add("appid")
			paramsList.Add("key")
			Return paramsList
		Case "getText"
			wait for (GetText(Params.Get("img"),Params.Get("lang"),Params.Get("targetLang"))) complete (result As Map)
			Return result
		Case "getTextWithLocation"
			wait for (GetTextWithLocation(Params.Get("img"),Params.Get("lang"),Params.Get("targetLang"))) complete (regions As List)
			Return regions
		Case "getLangs"
			Return getLangs(Params.Get("loc"))
	End Select
	Return ""
End Sub

private Sub getLangs(loc As Localizator) As Map
	Dim result As Map
	result.Initialize
	Dim names,codes As List
	names.Initialize
	codes.Initialize
	codes.Add("auto")
	codes.Add("zh")
	codes.Add("en")
	codes.Add("jp")
	codes.Add("kor")
	codes.Add("fra")
	codes.Add("spa")
	codes.Add("ru")
	codes.Add("pt")
	codes.Add("de")
	codes.Add("it")
	codes.Add("dan")
	codes.Add("nl")
	codes.Add("may")
	codes.Add("swe")
	codes.Add("id")
	codes.Add("pl")
	codes.Add("rom")
	codes.Add("tr")
	codes.Add("el")
	codes.Add("hu")
	names.Add(loc.localize("自动检测"))
	names.Add(loc.localize("中文"))
	names.Add(loc.localize("英语"))
	names.Add(loc.localize("日语"))
	names.Add(loc.localize("韩语"))
	names.Add(loc.localize("法语"))
	names.Add(loc.localize("西班牙语"))
	names.Add(loc.localize("俄语"))
	names.Add(loc.localize("葡萄牙语"))
	names.Add(loc.localize("德语"))
	names.Add(loc.localize("意大利语"))
	names.Add(loc.localize("丹麦语"))
	names.Add(loc.localize("荷兰语"))
	names.Add(loc.localize("马来语"))
	names.Add(loc.localize("瑞典语"))
	names.Add(loc.localize("印尼语"))
	names.Add(loc.localize("波兰语"))
	names.Add(loc.localize("罗马尼亚语"))
	names.Add(loc.localize("土耳其语"))
	names.Add(loc.localize("希腊语"))
	names.Add(loc.localize("匈牙利语"))
	result.Put("names",names)
	result.Put("codes",codes)
	Return result
End Sub

private Sub GetText(img As B4XBitmap,lang As String,targetLang As String) As ResumableSub
	wait for (GetTextWithLocation(img,lang,targetLang)) complete (boxes As List)
	Dim sb As StringBuilder
	sb.Initialize
	Dim targetSB As StringBuilder
	targetSB.Initialize
	For i = 0 To boxes.Size - 1
		Dim box As Map = boxes.Get(i)
		sb.Append(box.Get("text"))
		targetSB.Append(box.Get("target"))
		If i <> boxes.Size -1 Then
			sb.Append(CRLF)
			targetSB.Append(CRLF)
		End If
	Next
	Return CreateMap("text":sb.ToString,"extra":CreateMap("target":targetSB.ToString))
End Sub

private Sub GetTextWithLocation(img As B4XBitmap,lang As String,targetLang As String) As ResumableSub
	Dim regions As List
	regions.Initialize
	wait for (ocr(img,lang,targetLang)) complete (boxes As List)
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

private Sub ocr(img As B4XBitmap,lang As String,targetLang As String) As ResumableSub
	Dim key As String
	Dim appid As String
	Try
		If File.Exists(File.DirApp,"preferences.conf") Then
			Dim preferencesMap As Map = readJsonAsMap(File.ReadString(File.DirApp,"preferences.conf"))
			key=getMap("imgbaidu",getMap("api",preferencesMap)).Get("key")
			appid=getMap("imgbaidu",getMap("api",preferencesMap)).Get("appid")
		End If
	Catch
		Log(LastException)
		Return ""
	End Try

	Dim boxes As List
	boxes.Initialize
	saveImgToDiskWithSizeCheck(img,100,5000000)
	Dim fd As MultipartFileData
	fd.Initialize
	fd.KeyName = "image"
	fd.Dir = File.DirApp
	fd.FileName = "image.jpg"
	fd.ContentType = "image/jpg"
	Dim endPoint As String = "https://fanyi-api.baidu.com/api/trans/sdk/picture"
	Dim salt As Int = Rnd(100,10000)
	Dim values As Map
	values.Initialize
	values.Put("from",lang)
	values.Put("to",targetLang)
	values.Put("appid",appid)
	values.Put("salt",salt)
	values.Put("sign",getSign(appid,key,salt))
	values.Put("mac","mac")
	values.Put("version","3")
	values.Put("cuid","APICUID")
	Dim job As HttpJob
	job.Initialize("",Me)
	job.PostMultipart(endPoint,values,Array(fd))
	wait for (job) JobDone(job As HttpJob)
	If job.Success Then
		Try
			Log(job.GetString)
			Dim json As JSONParser
			json.Initialize(job.GetString)
			Dim response As Map = json.NextObject
			Dim data As Map = response.Get("data")
			Dim content As List = data.Get("content")
			Log(content)
			For Each one As Map In content
				Dim box As Map
				box.Initialize
				box.Put("text",one.Get("src"))
				box.Put("target",one.Get("dst"))
				Dim boxGeometry As Map = getGeometryFromRect(one.Get("rect")) '"92 35 248 152"
				box.Put("geometry",boxGeometry)
				boxes.Add(box)
			Next
		Catch
			Log(LastException)
		End Try
	Else
		Log(job.ErrorMessage)
	End If
	job.Release
	Return boxes
End Sub

Private Sub getGeometryFromRect(rect As String) As Map
	Dim values() As String = Regex.Split(" ",rect)
	Dim geometry As Map
	geometry.Initialize
	geometry.Put("X",values(0))
	geometry.Put("Y",values(1))
	geometry.Put("width",values(2))
	geometry.Put("height",values(3))
	Return geometry
End Sub

Private Sub getSign(appid As String,key As String,salt As Int) As String
	Dim Bconv As ByteConverter
	Dim md As MessageDigest
	Dim md5OfImage As String = Bconv.HexFromBytes(md.GetMessageDigest(File.ReadBytes(File.DirApp,"image.jpg"),"MD5")).ToLowerCase
	Dim rawSign As String
	rawSign = appid&md5OfImage&salt&"APICUID"&"mac"&key
	Dim md5 As String
	md5 = Bconv.HexFromBytes(md.GetMessageDigest(Bconv.StringToBytes(rawSign,"UTF-8"),"MD5")).ToLowerCase
	Return md5
End Sub

private Sub getMap(key As String,parentmap As Map) As Map
	Return parentmap.Get(key)
End Sub

private Sub readJsonAsMap(s As String) As Map
	Dim json As JSONParser
	json.Initialize(s)
	Return json.NextObject
End Sub

private Sub saveImgToDiskWithSizeCheck(img As B4XBitmap,quality As Int, sizeLimit As Int)
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

