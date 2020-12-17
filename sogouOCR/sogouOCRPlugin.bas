B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=4.2
@EndOfDesignText@
Sub Class_Globals
	Private fx As JFX
	Private Bconv As ByteConverter
End Sub

'Initializes the object. You can NOT add parameters to this method!
Public Sub Initialize() As String
	Log("Initializing plugin " & GetNiceName)
	' Here return a key to prevent running unauthorized plugins
	Return "MyKey"
End Sub

' must be available
public Sub GetNiceName() As String
	Return "sogouOCR"
End Sub

' must be available
public Sub Run(Tag As String, Params As Map) As ResumableSub
	Log("run"&Params)
	Select Tag
		Case "getParams"
			Dim paramsList As List
			paramsList.Initialize
			paramsList.Add("id")
			paramsList.Add("key")
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
	codes.Add("zh-CHS")
	codes.Add("en")
	codes.Add("ru")
	codes.Add("ja")
	codes.Add("ko")
	codes.Add("fr")
	codes.Add("de")
	codes.Add("es")
	codes.Add("pt")
	names.Add(loc.Localize("简体中文"))
	names.Add(loc.Localize("英语"))
	names.Add(loc.Localize("俄语"))
	names.Add(loc.Localize("日语"))
	names.Add(loc.Localize("韩语"))
	names.Add(loc.Localize("法语"))
	names.Add(loc.Localize("德语"))
	names.Add(loc.Localize("西班牙语"))
	names.Add(loc.Localize("葡萄牙语"))
	result.Put("names",names)
	result.Put("codes",codes)
	Return result
End Sub

Sub GetText(img As B4XBitmap,lang As String) As ResumableSub
	wait for (ocr(img,lang)) complete (boxes As List)
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
	wait for (ocr(img,lang)) complete (boxes As List)
	For Each box As Map In boxes
		Dim region As Map=box.Get("geometry")
		region.Put("text",box.Get("text"))
		regions.Add(region)
	Next
	Return regions
End Sub

Sub ocr(img As B4XBitmap,lang As String) As ResumableSub
	Dim id,key As String
	Try
		If File.Exists(File.DirApp,"preferences.conf") Then
			Dim preferencesMap As Map = readJsonAsMap(File.ReadString(File.DirApp,"preferences.conf"))
			id=getMap("sogou",getMap("api",preferencesMap)).Get("id")
			key=getMap("sogou",getMap("api",preferencesMap)).Get("key")
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
	Dim urlencoded As String=su.EncodeUrl(base64,"UTF8")
	Dim params As String
	Dim timestamp As String=DateTime.Now
	Dim service As String="basicOpenOcr"
	params="&service="&service&"&pid="&id&"&salt="&timestamp&"&lang="&lang&"&image="&urlencoded&"&sign="&MD5(id,service,timestamp,base64,key)
	Log(params)
	job.PostString("http://deepi.sogou.com/api/sogouService",params)
	job.GetRequest.SetContentType("application/x-www-form-urlencoded")
	wait for (job) JobDone(job As HttpJob)
	If job.Success Then
		Try
			Log(job.GetString)
			Dim json As JSONParser
			json.Initialize(job.GetString)
			Dim resultList As List=json.NextObject.Get("result")
			For Each result As Map In resultList
				Dim content As String=result.Get("content")
				Dim frame As List=result.Get("frame")
				Dim box As Map
				box.Initialize
				box.Put("text",content.Trim)
				Dim boxGeometry As Map=FrameToGeometry(frame)
				box.Put("geometry",boxGeometry)
				boxes.Add(box)
			Next
		Catch
			Log(LastException)
		End Try
	End If
	Return boxes
End Sub

Sub FrameToGeometry(Frame As List) As Map
	Dim points As Map=FrameToMap(Frame)
	Dim X,Y,width,height As Int
	X=Min(points.get("x0"),points.Get("x2"))
	Y=Min(points.get("y0"),points.Get("y1"))
	width=Max(points.Get("x1"),points.get("x3"))-X
	height=Max(points.get("y1"),points.Get("y3"))-Y
	Dim boxGeometry As Map
	boxGeometry.Initialize
	boxGeometry.Put("X",X)
	boxGeometry.Put("Y",Y)
	boxGeometry.Put("width",width)
	boxGeometry.Put("height",height)
	Return boxGeometry
End Sub

Sub FrameToMap(frame As List) As Map
	Dim map1 As Map
	map1.Initialize
	Dim index As Int=0
	For Each coord As String In frame
		map1.Put("x"&index,Regex.Split(",",coord)(0))
		map1.Put("y"&index,Regex.Split(",",coord)(1))
		index=index+1
	Next
	Return map1
End Sub

Sub MD5(pid As String,service As String, timestamp As String, image As String, key As String) As String
	Dim sb As StringBuilder
	sb.Initialize
	sb.Append(pid)
	sb.Append(service)
	sb.Append(timestamp)
	If image.Length>1024 Then
		sb.Append(image.SubString2(0,1024))
	Else
		sb.Append(image)
	End If
	sb.Append(key)
	Dim Bconv As ByteConverter
	Dim data() As Byte
	Dim md As MessageDigest
	data = md.GetMessageDigest(sb.ToString.GetBytes("UTF8"), "MD5")
	Dim hex As String=Bconv.HexFromBytes(data)
	Return hex.ToLowerCase
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

