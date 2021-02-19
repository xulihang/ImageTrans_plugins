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
	Return "DynamsoftOCR"
End Sub

' must be available
public Sub Run(Tag As String, Params As Map) As ResumableSub
	Log("run"&Params)
	Select Tag
		Case "getParams"
			Dim paramsList As List
			paramsList.Initialize
			paramsList.Add("license")
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

Sub GetText(img As B4XBitmap, lang As String) As ResumableSub
	wait for (ocr(img,lang)) complete (result As Map)
	Return result.GetDefault("Text","")
End Sub

Sub GetTextWithLocation(img As B4XBitmap, lang As String) As ResumableSub
	wait for (ocr(img,lang)) complete (result As Map)
	If result.ContainsKey("boxes") Then
		Dim Boxes As List=result.Get("boxes")
		Return Boxes
	Else
		Dim Boxes As List
		Boxes.Initialize
		Return Boxes
	End If
End Sub

Sub LangHasSpace(lang As String) As Boolean
	If lang.StartsWith("ch") Or lang.StartsWith("jp") Then
		Return False
	Else
		Return True
	End If
End Sub

Sub ocr(img As B4XBitmap, Lang As String) As ResumableSub
	Dim license As String
	Try
		If File.Exists(File.DirApp,"preferences.conf") Then
			Dim preferencesMap As Map = readJsonAsMap(File.ReadString(File.DirApp,"preferences.conf"))
			license=getMap("Dynamsoft",getMap("api",preferencesMap)).Get("license")
		End If
	Catch
		Log(LastException)
		Return ""
	End Try

	Dim result As Map
	result.Initialize
	Dim out As OutputStream
	out=File.OpenOutput(File.DirApp,"image.jpg",False)
	img.WriteToStream(out,"100","JPEG")
	out.Close
	If File.Exists(File.DirApp,"out.txt") Then
		File.Delete(File.DirApp,"out.txt")	
	End If
	Dim executable As String
	executable="./Dynamsoft/LabelRecognitionDemo.exe"
	Dim sh As Shell
	sh.Initialize("sh",executable,Array(license,"image.jpg","out.txt"))
	sh.WorkingDirectory=File.DirApp
	sh.Run(10000)
	wait for sh_ProcessCompleted (Success As Boolean, ExitCode As Int, StdOut As String, StdErr As String)
	Log(StdOut)
	Log(StdErr)
	If Success And ExitCode = 0 Then
		If File.Exists(File.DirApp,"out.txt") Then
			result=Data2Map(File.ReadString(File.DirApp,"out.txt"))
		End If
	End If
	Return result
End Sub

Sub Data2Map(data As String) As Map
	Dim result As Map
	result.Initialize
	Dim boxes As List
	boxes.Initialize
	
	Dim sb As StringBuilder
	sb.Initialize
	For Each Line As String In Regex.Split("\r\n",data)
		Try
			Dim point0,point1,point2,point3 As String
			point0=Regex.Split("	",Line)(0)
			point1=Regex.Split("	",Line)(1)
			point2=Regex.Split("	",Line)(2)
			point3=Regex.Split("	",Line)(3)
			Dim text As String
			text=Regex.Split("	",Line)(4)
		
			Dim box As Map
			box.Initialize

			Dim minX,minY,maxX,maxY As Int
			Dim index As Int=0
			For Each point As String In Array As String(point0,point1,point2,point3)
				Dim X As Int=Regex.Split(",",point)(0)
				Dim Y As Int=Regex.Split(",",point)(1)
				If index=0 Then
					minX=X
					minY=Y
				Else
					minX=Min(X,minX)
					minY=Min(Y,minY)
				End If
				maxX=Max(X,maxX)
				maxY=Max(Y,maxY)
				index=index+1
			Next
			
			box.Put("X",minX)
			box.Put("Y",minY)
			box.Put("width",maxX-minX)
			box.Put("height",maxY-minY)
			box.Put("text",text)
			sb.Append(text).Append(CRLF)
			boxes.Add(box)
		Catch
			Log(LastException)
		End Try
	Next
	result.Put("boxes",boxes)
	result.Put("Text",sb.ToString.Trim)
	Return result
End Sub

Sub getMap(key As String,parentmap As Map) As Map
	Return parentmap.Get(key)
End Sub

Sub readJsonAsMap(s As String) As Map
	Dim json As JSONParser
	json.Initialize(s)
	Return json.NextObject
End Sub

