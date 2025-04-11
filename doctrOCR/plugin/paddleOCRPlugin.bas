B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=4.2
@EndOfDesignText@
Sub Class_Globals
	Private fx As JFX
	Private detectOnly As Boolean = False
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
		Case "getParams"
			Dim paramsList As List
			paramsList.Initialize
			paramsList.Add("url")
			Return paramsList
		Case "getText"
			wait for (GetText(Params.Get("img"),Params.Get("lang"))) complete (result As String)
			detectOnly = False
			Return result
		Case "getTextWithLocation"
			wait for (GetTextWithLocation(Params.Get("img"),Params.Get("lang"))) complete (regions As List)
			detectOnly = False
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
		Case "GetCombinations"
			Return BuildCombinations
		Case "Multiple"
			Return True
	End Select
	Return ""
End Sub

Sub BuildCombinations As List
	Dim combs As List
	combs.Initialize
	combs.Add("paddleocr")
	combs.Add("detect only (paddleocr)")
	Return combs
End Sub

Sub convertLang(lang As String) As String
	If lang.StartsWith("en") Then
		Return "en"
	else if lang.StartsWith("ch") Then
		Return "ch"
	else if lang.StartsWith("jpn") Then
		Return "japan"
	else if lang.StartsWith("kor") Then
		Return "korean"
	Else
		Return lang
	End If
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
		regions.Add(region)
	Next
	Return regions
End Sub

Sub ocr(img As B4XBitmap, lang As String) As ResumableSub
	lang=convertLang(lang)
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
				textLinesToBoxes(textLines,boxes)
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
