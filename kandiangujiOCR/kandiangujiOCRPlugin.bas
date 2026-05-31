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
	Return "kandiangujiOCR"
End Sub

' must be available
public Sub Run(Tag As String, Params As Map) As ResumableSub
	Select Tag
		Case "getParams"
			Dim paramsList As List
			paramsList.Initialize
			paramsList.Add("email")
			paramsList.Add("token")
			paramsList.Add("det_mode")
			paramsList.Add("version")
			paramsList.Add("return_position")
			Return paramsList
		Case "getText"
			wait for (GetText(Params.Get("img"))) complete (result As String)
			Return result
		Case "getTextWithLocation"
			wait for (GetTextWithLocation(Params.Get("img"))) complete (regions As List)
			Return regions
		Case "getLayout"
			wait for (DetectLayout(Params.Get("img"))) complete (regions As List)
			Return regions
		Case "supportLayoutDetection"
			Return True
		Case "getDefaultParamValues"
			Return CreateMap("email":"", _
			                 "token":"", _
			                 "det_mode":"auto", _
			                 "version":"v2", _
			                 "return_position":"true")
	End Select
	Return ""
End Sub

Sub DetectLayout(img As B4XBitmap) As ResumableSub
	wait for (ocr(img, True)) complete (result As Map)
	Dim list1 As List = result.Get("layout")
	Return list1
End Sub

Sub GetText(img As B4XBitmap) As ResumableSub
	wait for (ocr(img, True)) complete (result As Map)
	Return result.Get("text")
End Sub

Sub GetTextWithLocation(img As B4XBitmap) As ResumableSub
	wait for (ocr(img, True)) complete (result As Map)
	Dim list1 As List = result.Get("textWithLocation")
	Return list1
End Sub

Sub ocr(img As B4XBitmap, includePosition As Boolean) As ResumableSub
	saveImgToDiskWithSizeCheck(img, 100, 5000000)

	Dim preferencesMap As Map
	If File.Exists(File.DirApp, "preferences.conf") Then
		preferencesMap = readJsonAsMap(File.ReadString(File.DirApp, "preferences.conf"))
	Else
		Dim map1 As Map
		map1.Initialize
		map1.Put("email", "")
		map1.Put("token", "")
		map1.Put("det_mode", "auto")
		map1.Put("version", "v2")
		map1.Put("return_position", "true")
		preferencesMap = CreateMap("api":CreateMap("kandianguji":map1))
	End If
	Dim apiMap As Map = getMap("kandianguji", getMap("api", preferencesMap))
	Dim email As String = apiMap.GetDefault("email", "")
	Dim token As String = apiMap.GetDefault("token", "")
	Dim detMode As String = apiMap.GetDefault("det_mode", "auto")
	Dim version As String = apiMap.GetDefault("version", "v2")
	Dim returnPositionStr As String = apiMap.GetDefault("return_position", "true")
	Dim returnPosition As Boolean = (returnPositionStr = "true")

	Dim resultText As String
	Dim textWithLocation As List
	textWithLocation.Initialize
	Dim layout As List
	layout.Initialize

	Dim imgW As Int = img.Width
	Dim imgH As Int = img.Height

	Dim url As String = "https://ocr.kandianguji.com/ocr_api"

	Dim su As StringUtils
	Dim base64 As String = su.EncodeBase64(File.ReadBytes(File.DirApp, "image.jpg"))

	Dim requestMap As Map
	requestMap.Initialize
	requestMap.Put("token", token)
	requestMap.Put("email", email)
	requestMap.Put("image", base64)
	requestMap.Put("det_mode", detMode)
	requestMap.Put("version", version)

	If returnPosition Then
		requestMap.Put("return_position", True)
	End If

	Dim job As HttpJob
	job.Initialize("job", Me)
	Dim jsonG As JSONGenerator
	jsonG.Initialize(requestMap)
	job.PostString(url, jsonG.ToString)
	job.GetRequest.SetContentType("application/json")
	job.GetRequest.Timeout = 1200000 * 1000
	wait For (job) JobDone(job As HttpJob)

	If job.Success Then
		Try
			Log(job.GetString)
			Dim json As JSONParser
			json.Initialize(job.GetString)
			Dim response As Map = json.NextObject

			If response.Get("message") = "success" Then
				Dim data As Map = response.Get("data")
				Dim textLines As List = data.Get("text_lines")

				For Each line As Map In textLines
					Dim text As String = line.Get("text")
					resultText = resultText & text & CRLF

					If line.ContainsKey("position") Then
						Dim pos As List = line.Get("position")
						If pos.Size = 4 Then
							Dim xs As List
							xs.Initialize
							Dim ys As List
							ys.Initialize
							For Each pt As List In pos
								xs.Add(pt.Get(0))
								ys.Add(pt.Get(1))
							Next

							Dim x1 As Float = MinInList(xs)
							Dim y1 As Float = MinInList(ys)
							Dim x2 As Float = MaxInList(xs)
							Dim y2 As Float = MaxInList(ys)

							Dim box As Map
							box.Initialize
							box.Put("X", x1)
							box.Put("Y", y1)
							box.Put("width", x2 - x1)
							box.Put("height", y2 - y1)
							box.Put("text", text)
							textWithLocation.Add(box)

							Dim layoutBox As Map
							layoutBox.Initialize
							layoutBox.Put("X", x1)
							layoutBox.Put("Y", y1)
							layoutBox.Put("width", x2 - x1)
							layoutBox.Put("height", y2 - y1)
							layoutBox.Put("text", "")
							layoutBox.Put("class", "text")
							layout.Add(layoutBox)
						End If
					End If
				Next
			Else
				Log("API error: " & response.GetDefault("info", "unknown error"))
			End If
		Catch
			Log(LastException)
		End Try
	Else
		Log(job.ErrorMessage)
	End If
	job.Release

	Dim finalResult As Map
	finalResult.Initialize
	finalResult.Put("text", resultText)
	finalResult.Put("textWithLocation", textWithLocation)
	finalResult.Put("layout", layout)
	Return finalResult
End Sub

Sub MinInList(lst As List) As Float
	Dim MinValue As Float = lst.Get(0)
	For Each v As Float In lst
		If v < MinValue Then 
			MinValue = v
		End If
	Next
	Return MinValue
End Sub

Sub MaxInList(lst As List) As Float
	Dim MaxValue As Float = lst.Get(0)
	For Each v As Float In lst
		If v > MaxValue Then 
			MaxValue = v
		End If
	Next
	Return MaxValue
End Sub

Sub readJsonAsMap(s As String) As Map
	Dim json As JSONParser
	json.Initialize(s)
	Return json.NextObject
End Sub

Sub getMap(key As String, parentmap As Map) As Map
	Return parentmap.Get(key)
End Sub

Sub saveImgToDiskWithSizeCheck(img As B4XBitmap, quality As Int, sizeLimit As Int)
	Dim imgPath As String = File.Combine(File.DirApp, "image.jpg")
	Dim out As OutputStream = File.OpenOutput(imgPath, "", False)
	img.WriteToStream(out, quality, "JPEG")
	out.Close
	Dim su As StringUtils
	Dim base64 As String = su.EncodeBase64(File.ReadBytes(File.DirApp, "image.jpg"))
	If base64.Length > sizeLimit Then
		Log("bigger than limit")
		If quality >= 10 Then
			saveImgToDiskWithSizeCheck(img, quality - 10, sizeLimit)
		End If
	End If
End Sub
