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
	Log("run"&Params)
	Select Tag
		Case "getParams"
			Dim paramsList As List
			paramsList.Initialize
			paramsList.Add("placeholder")
			Return paramsList
		Case "getText"
			wait for (GetText(Params.Get("img"),Params.Get("lang"))) complete (result As String)
			Return result
		Case "getTextWithLocation"
			wait for (GetTextWithLocation(Params.Get("img"),Params.Get("lang"))) complete (regions As List)
			Return regions
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

Sub GetText(img As B4XBitmap, lang As String) As ResumableSub
	wait for (ocr(img,lang)) complete (result As Map)
	Return result.GetDefault("text","")
End Sub

Sub GetTextWithLocation(img As B4XBitmap, lang As String) As ResumableSub
	wait for (ocr(img,lang)) complete (result As Map)
	If result.ContainsKey("lines") Then
		Dim Lines As List=result.Get("lines")
		Return LinesToBoxes(Lines)
	Else
		Dim boxes As List
		boxes.Initialize
		Return boxes
	End If
End Sub

Sub LinesToBoxes(lines As List) As List
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

Sub ocr(img As B4XBitmap, Lang As String) As ResumableSub
	Dim result As Map
	result.Initialize
	Dim out As OutputStream
	out=File.OpenOutput(File.DirApp,"image.jpg",False)
	img.WriteToStream(out,"100","JPEG")
	out.Close
	If File.Exists(File.DirApp,"out.json") Then
		File.Delete(File.DirApp,"out.json")	
	End If
	Dim executable As String
	executable="./OCR"
	Dim sh As Shell
	sh.Initialize("sh",executable,Array(Lang,"false","true","image.jpg","out.json"))
	sh.WorkingDirectory=File.DirApp
	sh.Run(10000)
	wait for sh_ProcessCompleted (Success As Boolean, ExitCode As Int, StdOut As String, StdErr As String)
	If Success And ExitCode = 0 Then
		If File.Exists(File.DirApp,"out.json") Then
			Dim jsonString As String=File.ReadString(File.DirApp,"out.json")
			Dim json As JSONParser
			json.Initialize(jsonString)
			result=json.NextObject
		End If
	End If
	Return result
End Sub
