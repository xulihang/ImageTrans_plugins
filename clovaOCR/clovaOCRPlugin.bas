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
	Return "clovaOCR"
End Sub

' must be available
public Sub Run(Tag As String, Params As Map) As ResumableSub
	Log("run"&Params)
	Select Tag
		Case "getParams"
			Dim paramsList As List
			paramsList.Initialize
			paramsList.Add("url")
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
	codes.Add("ko")
	codes.Add("ja")
	names.Add(loc.Localize("韩语"))
	names.Add(loc.Localize("日语"))
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
	Dim url,key As String
	Try
		If File.Exists(File.DirApp,"preferences.conf") Then
			Dim preferencesMap As Map = readJsonAsMap(File.ReadString(File.DirApp,"preferences.conf"))
			url=getMap("clova",getMap("api",preferencesMap)).Get("url")
			key=getMap("clova",getMap("api",preferencesMap)).Get("key")
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
	
	Dim images As List
	images.Initialize
	Dim image As Map
	image.Initialize
	image.Put("format","jpg")
	image.Put("data",base64)
	'image.Put("url","http://www.xulihang.me/18_094.jpg")
	image.Put("name","image")
	images.Add(image)
	Dim body As Map
	body.Initialize
	body.Put("images",images)
	body.Put("timestamp",DateTime.Now)
	body.Put("requestId",UUID)
	body.Put("lang",lang)
	body.Put("version","V2")
	Dim json As JSONGenerator
	json.Initialize(body)
	job.PostString(url,json.ToString)
	job.GetRequest.SetContentType("application/json")
	job.GetRequest.SetHeader("X-OCR-SECRET",key)
	wait for (job) JobDone(job As HttpJob)
	If job.Success Then
		Try
			Log(job.GetString)
			Dim jsonP As JSONParser
			jsonP.Initialize(job.GetString)
			Dim result As Map=jsonP.NextObject
			Dim images As List=result.Get("images")
			Dim image As Map=images.Get(0)
			Dim fields As List=image.Get("fields")
			For Each field As Map In fields
				Dim box As Map
				box.Initialize
				Dim text As String=field.Get("inferText")
				box.Put("text",text)
				Dim boxGeometry As Map
				boxGeometry.Initialize
				Dim X,Y,width,height As Int
				Dim boundingPoly As Map=field.Get("boundingPoly")
				Dim vertices As List=boundingPoly.Get("vertices")
				Dim points As Map
				points.Initialize
				Dim i As Int
				For Each vertice As Map In vertices
					points.Put("x"&i,vertice.Get("x"))
					points.Put("y"&i,vertice.Get("y"))
					i=i+1
				Next
				X=Min(points.get("x0"),points.Get("x2"))
				Y=Min(points.get("y0"),points.Get("y1"))
				width=Max(points.Get("x1"),points.get("x3"))-X
				height=Max(points.get("y1"),points.Get("y3"))-Y
				boxGeometry.Put("X",X)
				boxGeometry.Put("Y",Y)
				boxGeometry.Put("width",width)
				boxGeometry.Put("height",height)
				box.Put("geometry",boxGeometry)
				boxes.Add(box)				
			Next
		Catch
			Log(LastException)
		End Try
	End If
	job.Release
	Return boxes
End Sub

Sub UUID As String
	Dim jo As JavaObject
	Return jo.InitializeStatic("java.util.UUID").RunMethod("randomUUID", Null)
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

