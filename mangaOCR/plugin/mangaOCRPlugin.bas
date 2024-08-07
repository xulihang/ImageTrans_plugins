﻿B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=4.2
@EndOfDesignText@
Sub Class_Globals
	Private fx As JFX
	Private longTextMode As Boolean = False
End Sub

'Initializes the object. You can NOT add parameters to this method!
Public Sub Initialize() As String
	Log("Initializing plugin " & GetNiceName)
	' Here return a key to prevent running unauthorized plugins
	Return "MyKey"
End Sub

' must be available
public Sub GetNiceName() As String
	Return "manga-ocrOCR"
End Sub

' must be available
public Sub Run(Tag As String, Params As Map) As ResumableSub
	Log("run"&Params)
	Select Tag
		Case "getParams"
			Dim paramsList As List
			paramsList.Initialize
			paramsList.Add("url")
			Return paramsList
		Case "getText"
			If longTextMode Then
				wait for (GetTextLongTextMode(Params.Get("img"))) complete (result As String)
				Return result
			Else
				wait for (GetText(Params.Get("img"))) complete (result As String)
				Return result
			End If

		Case "getTextWithLocation"
			Dim list1 As List
			list1.Initialize
			Return list1
		Case "getDefaultParamValues"
			Return CreateMap("url":"http://127.0.0.1:8080/ocr")
		Case "getLangs"
			Return getLangs(Params.Get("loc"))
		Case "getSetupParams"
			Dim o As Object = CreateMap("readme":"https://github.com/xulihang/ImageTrans_plugins/tree/master/mangaOCR")
			Return o
		Case "getIsInstalledOrRunning"
			Wait For (CheckIsRunning) complete (running As Boolean)
			Return running
		Case "SetCombination"
			Dim comb As String=Params.Get("combination")
			longTextMode = comb.Contains("long text")
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
	combs.Add("manga-ocr")
	combs.Add("normal text (manga-ocr)")
	combs.Add("long text (manga-ocr)")
	Return combs
End Sub

Sub getLangs(loc As Localizator) As Map
	Dim result As Map
	result.Initialize
	Dim names,codes As List
	names.Initialize
	codes.Initialize
	codes.Add("ja")
	names.Add(loc.Localize("日语"))
	result.Put("names",names)
	result.Put("codes",codes)
	Return result
End Sub

Sub GetText(img As B4XBitmap) As ResumableSub
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
	job.PostMultipart(getUrl,Null, Array(fd))
	job.GetRequest.Timeout=240*1000
	Wait For (job) JobDone(job As HttpJob)
	If job.Success Then
		Try
			Log(job.GetString)
			Return job.GetString
		Catch
			Log(LastException)
		End Try
	End If
	job.Release
	Return ""
End Sub

Sub GetTextLongTextMode(img As B4XBitmap) As ResumableSub
	Dim imgs As List
	imgs.Initialize
	If img.Height / img.Width > 8 Then
		Dim segHeight As Int = img.Width * 8
		Dim top As Int = 0
		Dim heightLeft As Int = img.Height
		Dim segsNumber As Int = Ceil(img.Height / segHeight)
		For i = 1 To segsNumber
			imgs.Add(img.Crop(0,top,img.Width,Min(segHeight,heightLeft)))
			heightLeft = heightLeft - segHeight
			top = top + segHeight
		Next
	Else
		imgs.Add(img)
	End If
	Dim sb As StringBuilder
	sb.Initialize
	For Each cropped As Image In imgs
		wait for (GetText(cropped)) complete (result As String)
		sb.Append(result)
	Next
	Return sb.ToString
End Sub

Sub getMap(key As String,parentmap As Map) As Map
	Return parentmap.Get(key)
End Sub

Sub getUrl As String
	Dim url As String = "http://127.0.0.1:8080/ocr"
	If File.Exists(File.DirApp,"preferences.conf") Then
		Try
			Dim preferencesMap As Map = readJsonAsMap(File.ReadString(File.DirApp,"preferences.conf"))
			url=getMap("manga-ocr",getMap("api",preferencesMap)).GetDefault("url",url)
		Catch
			Log(LastException)
		End Try
	End If
	Return url
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

Sub readJsonAsMap(s As String) As Map
	Dim json As JSONParser
	json.Initialize(s)
	Return json.NextObject
End Sub
