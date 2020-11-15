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
	Return "WinRTOCR"
End Sub

' must be available
public Sub Run(Tag As String, Params As Map) As ResumableSub
	Log("run"&Params)
	Log("winRT")
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
	End Select
	Return ""
End Sub

Sub convertLang(lang As String) As String
	If lang.StartsWith("en") Then
		Return "en"
	else if lang.StartsWith("chi_sim") Then
		Return "zh-Hans"
	else if lang.StartsWith("chi_tra") Then
		Return "zh-Hant"
	else if lang.StartsWith("jpn") Then
		Return "ja"
	else if lang.StartsWith("kor") Then
		Return "ko"
	Else
		Return lang
	End If
End Sub

Sub GetText(img As B4XBitmap, lang As String) As ResumableSub
	wait for (ocr(img,lang)) complete (result As Map)
	Return result.GetDefault("Text","")
End Sub

Sub GetTextWithLocation(img As B4XBitmap, lang As String) As ResumableSub
	wait for (ocr(img,lang)) complete (result As Map)
	If result.ContainsKey("Lines") Then
		Dim Lines As List=result.Get("Lines")
		Return LinesToBoxes(Lines,lang)
	Else
		Dim boxes As List
		boxes.Initialize
		Return boxes
	End If
End Sub

Sub LinesToBoxes(lines As List, lang As String) As List
	Dim boxes As List
	boxes.Initialize
	For Each line As Map In lines
		Dim box As Map
		box.Initialize
		Dim sb As StringBuilder
		sb.Initialize
		sb.Append(line.Get("Text"))
		Dim minX,minY,maxX,maxY As Int
		Dim words As List=line.Get("Words")
		Dim index As Int
		For Each word As Map In words
			'sb.Append(word.Get("Text"))
			'If LangHasSpace(lang) Then
			'	sb.Append(" ")
			'End If
			
			Dim boundingRect As Map=word.Get("BoundingRect")
			If index=0 Then
				minX=boundingRect.Get("Left")
				minY=boundingRect.Get("Top")
			Else
				minX=Min(boundingRect.Get("Left"),minX)
				minY=Min(boundingRect.Get("Top"),minY)
			End If

			maxX=Max(boundingRect.Get("Right"),maxX)
			maxY=Max(boundingRect.Get("Bottom"),maxY)
			index=index+1
		Next
		box.Put("X",minX)
		box.Put("Y",minY)
		box.Put("width",maxX-minX)
		box.Put("height",maxY-minY)
		box.Put("text",sb.ToString)
		boxes.Add(box)
	Next
	Return boxes
End Sub

Sub LangHasSpace(lang As String) As Boolean
	If lang.StartsWith("ch") Or lang.StartsWith("jp") Then
		Return False
	Else
		Return True
	End If
End Sub

Sub ocr(img As B4XBitmap, Lang As String) As ResumableSub
	Lang=convertLang(Lang)
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
	executable="./WinRTOCR/WinRTOCR.exe"
	Dim sh As Shell
	sh.Initialize("sh",executable,Array("image.jpg",Lang,"out.json"))
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
