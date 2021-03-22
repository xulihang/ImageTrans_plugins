B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=4.2
@EndOfDesignText@
Sub Class_Globals
	Private fx As JFX
	Private detector As String="craft"
	Private recognizer As String="opencv"
	Private wordlevel As Boolean=True
	Private detectors As List
	Private recognizers As List
	Private skip_recogniztion As String
	Private recognize_entire_image As String
	Private recognizerAffix As String="_recognizer"
	Private detectorAffix As String="_detector"
End Sub

'Initializes the object. You can NOT add parameters to this method!
Public Sub Initialize() As String
	Log("Initializing plugin " & GetNiceName)
	' Here return a key to prevent running unauthorized plugins
	detectors.Initialize
	detectors.AddAll(Array As String("craft","chineseocr"))
	recognizers.Initialize
	recognizers.AddAll(Array As String("opencv","chineseocr"))
	Return "MyKey"
End Sub

' must be available
public Sub GetNiceName() As String
	Return "ImageTransOCR"
End Sub

' must be available
public Sub Run(Tag As String, Params As Map) As ResumableSub
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
		Case "WordLevel"
			Return wordlevel
		Case "SetCombination"
			Dim comb As String=Params.Get("combination")
			comb=comb.Replace(" (ImageTrans)","")			
			skip_recogniztion=""
			recognize_entire_image=""
			If comb.Contains("+") Then
				detector=Regex.Split("\+",comb)(0)
				recognizer=Regex.Split("\+",comb)(1)
			Else if comb.Contains(recognizerAffix) Then
				comb=comb.Replace(recognizerAffix,"")
				recognizer=comb
				recognize_entire_image="true"
			else if comb.Contains(detectorAffix) Then
				comb=comb.Replace(detectorAffix,"")
				detector=comb
				skip_recogniztion="true"
			End If

			If detector="craft" Then
				wordlevel=True
			Else
				wordlevel=False
			End If
			
			If recognize_entire_image="true" Then
				wordlevel=False
			End If			
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
	For Each d_name As String In detectors
		combs.Add(d_name&detectorAffix&" (ImageTrans)")
		For Each r_name As String In recognizers			
			combs.Add(d_name&"+"&r_name&" (ImageTrans)")
		Next
	Next
	For Each r_name As String In recognizers
		combs.Add(r_name&recognizerAffix&" (ImageTrans)")
	Next
	Return combs
End Sub

Sub GetText(img As B4XBitmap, lang As String) As ResumableSub
	If recognize_entire_image="true" Then
		wait for (ocr(img,lang)) complete (result As String)
		Return result
	Else
		wait for (ocr(img,lang)) complete (boxes As List)
		Dim sb As StringBuilder
		sb.Initialize
		For Each box As Map In boxes
			sb.Append(box.Get("text"))
			sb.Append(CRLF)
		Next
		Return sb.ToString
	End If
End Sub

Sub GetTextWithLocation(img As B4XBitmap, lang As String) As ResumableSub
	Dim regions As List
	regions.Initialize
	If recognize_entire_image="true" Then
		Return regions
	End If
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
	job.PostMultipart(getUrl,CreateMap("detector":detector,"recognizer":recognizer,"lang":lang,"skip_recogniztion":skip_recogniztion,"recognize_entire_image":recognize_entire_image), Array(fd))
	job.GetRequest.Timeout=240*1000
	Wait For (job) JobDone(job As HttpJob)
	If job.Success Then
		Try
			Log(job.GetString)
			If recognize_entire_image="true" Then
				Return job.GetString
			End If			
			Dim json As JSONParser
			json.Initialize(job.GetString)
			Dim result As Map=json.NextObject
			Dim detectedBoxes As List
			detectedBoxes=result.Get("boxes")
			addBoxes(detectedBoxes,boxes)
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
		Dim X,Y,width,height As Int
		X=Min(box.get("x0"),box.Get("x2"))
		Y=Min(box.get("y0"),box.Get("y1"))
		width=Max(box.Get("x1"),box.get("x3"))-X
		height=Max(box.get("y1"),box.Get("y3"))-Y
		boxGeometry.Put("X",X)
		boxGeometry.Put("Y",Y)
		boxGeometry.Put("width",width)
		boxGeometry.Put("height",height)
		newBox.Put("geometry",boxGeometry)
		'box.Put("std",True)
		boxes.Add(newBox)
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
			url=getMap("ImageTrans",getMap("api",preferencesMap)).GetDefault("url",url)
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
