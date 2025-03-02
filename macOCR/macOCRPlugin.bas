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
	Return "macOCR"
End Sub

' must be available
public Sub Run(Tag As String, Params As Map) As ResumableSub
	Select Tag
		Case "getParams"
			Dim paramsList As List
			paramsList.Initialize
			paramsList.Add("placeholder")
			Return paramsList
		Case "getText"
			wait for (GetText(Params.Get("img"),Params.Get("lang"),Params.GetDefault("imgName",""))) complete (result As String)
			Return result
		Case "getTextWithLocation"
			wait for (GetTextWithLocation(Params.Get("img"),Params.Get("lang"),Params.GetDefault("imgName",""))) complete (regions As List)
			Return regions
		Case "isUsingShell"
			Return True
		Case "getResult"
			Dim boxes As List
			boxes.Initialize
			Dim parsed As Boolean = parseResult(boxes,Params.Get("imgName"))
			If parsed Then
				Return boxes
			Else
				Return False
			End If
		Case "getLangs"
			wait for (getLangs) complete (langs As Map)
			Return langs
	End Select
	Return ""
End Sub

Sub getLangs As ResumableSub
	Dim result As Map
	result.Initialize
	Dim names,codes As List
	names.Initialize
	codes.Initialize
	Dim executable As String
	executable="./OCR"
	Dim sh As Shell
	sh.Initialize("sh",executable,Array("--langs"))
	sh.Encoding=GetSystemProperty("file.encoding","UTF8")
	sh.WorkingDirectory=File.DirApp
	sh.Run(10000)
	wait for sh_ProcessCompleted (Success As Boolean, ExitCode As Int, StdOut As String, StdErr As String)
	If Success And ExitCode = 0 Then
	    Log(StdOut)
		Dim data As List
		data.Initialize
		data.AddAll(Regex.Split(CRLF,StdOut))
		Try
			For i=0 To data.Size-1
				Dim name As String=data.Get(i)
				Dim code As String=data.Get(i)
				names.Add(name.Trim)
				codes.Add(code.Trim)
			Next
		Catch
			Log(LastException)
		End Try
	End If
	result.Put("names",names)
	result.Put("codes",codes)
	Return result
End Sub

Sub GetText(img As B4XBitmap, lang As String, imgName As String) As ResumableSub
	wait for (ocr(img,lang,imgName)) complete (result As Map)
	Return result.GetDefault("text","")
End Sub

Sub GetTextWithLocation(img As B4XBitmap, lang As String, imgName As String) As ResumableSub
	wait for (ocr(img,lang,imgName)) complete (result As Map)
	If result.ContainsKey("lines") Then
		Dim Lines As List=result.Get("lines")
		Return LinesToRegions(Lines)
	Else
		Dim boxes As List
		boxes.Initialize
		Return boxes
	End If
End Sub

private Sub LinesToBoxes(lines As List) As List
	Dim boxes As List
	boxes.Initialize
	For Each line As Map In lines
		Dim box As Map
		box.Initialize
		Dim sb As StringBuilder
		sb.Initialize
		sb.Append(line.Get("text"))
		Dim x,y,width,height As Int
		x = line.Get("x")
		y = line.Get("y")
		width = line.Get("width")
		height = line.Get("height")
		Dim geometry As Map
		geometry.Initialize
		geometry.Put("X",x)
		geometry.Put("Y",y)
		geometry.Put("width",width)
		geometry.Put("height",height)
		box.Put("text",sb.ToString)
		box.Put("geometry",geometry)
		boxes.Add(box)
	Next
	Return boxes
End Sub

private Sub LinesToRegions(lines As List) As List
	Dim boxes As List
	boxes.Initialize
	For Each line As Map In lines
		Dim box As Map
		box.Initialize
		Dim sb As StringBuilder
		sb.Initialize
		sb.Append(line.Get("text"))
		Dim x,y,width,height As Int
		x = line.Get("x")
		y = line.Get("y")
		width = line.Get("width")
		height = line.Get("height")
		box.Put("X",x)
		box.Put("Y",y)
		box.Put("width",width)
		box.Put("height",height)
		box.Put("text",sb.ToString)
		boxes.Add(box)
	Next
	Return boxes
End Sub

private Sub GenerateUniqueName As String
	Dim randomNumber As Int = Rnd(0,1000)
	Dim timestamp As String = DateTime.Now
	Return timestamp&"-"&randomNumber&".jpg"
End Sub

Sub ocr(img As B4XBitmap, Lang As String,imgName As String) As ResumableSub
	Dim imgNamePassed As Boolean = False
	If imgName = "" Then
		imgName = GenerateUniqueName
	Else
		imgNamePassed = True
	End If
	Dim result As Map
	result.Initialize
	Dim out As OutputStream
	out=File.OpenOutput(File.DirApp,imgName,False)
	img.WriteToStream(out,"100","JPEG")
	out.Close
	If File.Exists(File.DirApp,imgName&"-out.json") Then
		File.Delete(File.DirApp,imgName&"out.json")
	End If
	Dim executable As String
	executable="./OCR"
	Dim sh As Shell
	sh.Initialize("sh",executable,Array(Lang,"false","true",imgName,imgName&"-out.json"))
	sh.WorkingDirectory=File.DirApp
	sh.Run(10000)
	wait for sh_ProcessCompleted (Success As Boolean, ExitCode As Int, StdOut As String, StdErr As String)
	If Success And ExitCode = 0 Then
		Dim jsonPath As String = File.Combine(File.DirApp,imgName&"-out.json")
		If File.Exists(jsonPath,"") Then
			Dim jsonString As String=File.ReadString(jsonPath,"")
			Dim json As JSONParser
			json.Initialize(jsonString)
			result = json.NextObject
		End If
	End If
	If imgNamePassed = False Then
		File.Delete(jsonPath,"")
	End If
	File.Delete(File.DirApp,imgName)
	Return result
End Sub

private Sub parseResult(boxes As List,imgName As String) As Boolean
	Dim jsonPath As String = File.Combine(File.DirApp,imgName&"-out.json")
	If File.Exists(jsonPath,"") Then
		Dim jsonString As String=File.ReadString(jsonPath,"")
		Dim json As JSONParser
		json.Initialize(jsonString)
		Dim result As Map =json.NextObject
		If result.ContainsKey("lines") Then
		    Dim Lines As List=result.Get("lines")
			boxes.AddAll(LinesToBoxes(Lines))
		End If
		File.Delete(jsonPath,"")
		Return True
	Else
		Return False
	End If
End Sub
