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
	Return "tencentOCR"
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
	codes.Add("auto")
	codes.Add("zh")
	codes.Add("jap")
	codes.Add("kor")
	codes.Add("spa")
	codes.Add("fre")
	codes.Add("ger")
	codes.Add("por")
	codes.Add("vie")
	codes.Add("may")
	codes.Add("rus")
	codes.Add("ita")
	codes.Add("hol")
	codes.Add("swe")
	codes.Add("fin")
	codes.Add("dan")
	codes.Add("nor")
	codes.Add("hun")
	codes.Add("tha")
	codes.Add("lat")
	codes.Add("ara")
	names.Add(loc.Localize("自动检测"))
	names.Add(loc.Localize("中文"))
	names.Add(loc.Localize("日语"))
	names.Add(loc.Localize("韩语"))
	names.Add(loc.Localize("西班牙语"))
	names.Add(loc.Localize("法语"))
	names.Add(loc.Localize("德语"))
	names.Add(loc.Localize("葡萄牙语"))
	names.Add(loc.Localize("越南语"))
	names.Add(loc.Localize("马来语"))
	names.Add(loc.Localize("俄语"))
	names.Add(loc.Localize("意大利语"))
	names.Add(loc.Localize("荷兰语"))
	names.Add(loc.Localize("瑞典语"))
	names.Add(loc.Localize("芬兰语"))
	names.Add(loc.Localize("丹麦语"))
	names.Add(loc.Localize("挪威语"))
	names.Add(loc.Localize("匈牙利语"))
	names.Add(loc.Localize("泰语"))
	names.Add(loc.Localize("拉丁语系"))
	names.Add(loc.Localize("阿拉伯语"))
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
			id=getMap("tencent",getMap("api",preferencesMap)).Get("id")
			key=getMap("tencent",getMap("api",preferencesMap)).Get("key")
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
	
	Dim params As String
	Dim nounce As Int
	Dim timestamp As Int=DateTime.Now/1000
	nounce=Rnd(1000,2000)
	params="Action=GeneralBasicOCR&ImageBase64="&base64&"&LanguageType="&lang&"&Nonce="&nounce&"&Region=ap-shanghai&SecretId="&id&"&SignatureMethod=HmacSHA256&Timestamp="&timestamp&"&Version=2018-11-19"
	'add signature
	base64=su.EncodeUrl(base64,"UTF-8")
	params="Action=GeneralBasicOCR&ImageBase64="&base64&"&LanguageType="&lang&"&Nonce="&nounce&"&Region=ap-shanghai&SecretId="&id&"&Signature="&getSignature(key,params)&"&SignatureMethod=HmacSHA256&Timestamp="&timestamp&"&Version=2018-11-19"
	job.PostString("https://ocr.tencentcloudapi.com/",params)
	wait for (job) JobDone(job As HttpJob)
	If job.Success Then
		Try
			Log(job.GetString)
			Dim json As JSONParser
			json.Initialize(job.GetString)
			Dim Response As Map=json.NextObject.Get("Response")
			Dim TextDetections As List=Response.Get("TextDetections")
			For Each line As Map In TextDetections
				Dim box As Map
				box.Initialize
				box.Put("text",line.Get("DetectedText"))
				Dim boxGeometry As Map
				boxGeometry=line.Get("ItemPolygon")
				boxGeometry.Put("width",boxGeometry.Get("Width"))
				boxGeometry.Put("height",boxGeometry.Get("Height"))
				boxGeometry.remove("Height")
				boxGeometry.remove("Width")
				box.Put("geometry",boxGeometry)
				boxes.Add(box)
			Next
		Catch
			Log(LastException)
		End Try
	End If
	Return boxes
End Sub

Sub getSignature(key As String,params As String) As String
	Dim mactool As Mac
	Dim k As KeyGenerator
	k.Initialize("HMACSHA256")
	Dim su As StringUtils
	Dim combined As String="POSTocr.tencentcloudapi.com/?"&params
	k.KeyFromBytes(Bconv.StringToBytes(key,"UTF-8"))
	mactool.Initialise("HMACSHA256",k.Key)
	mactool.Update(combined.GetBytes("UTF-8"))
	Dim bb() As Byte
	bb=mactool.Sign
	Dim base As Base64
	Dim sign As String=base.EncodeBtoS(bb,0,bb.Length)
	sign=su.EncodeUrl(sign,"UTF-8")
	Return sign
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

