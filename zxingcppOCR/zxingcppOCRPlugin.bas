B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=10.5
@EndOfDesignText@
Sub Class_Globals
	Private fx As JFX
	Private decoder As jZXingCPP
	Private enableTryHarder As Boolean = False
	Private enableTryRotate As Boolean = False
	Private enableTryInvert As Boolean = False
	Private enableTryDownscale As Boolean = False
	Private formatFilter As String
End Sub

'Initializes the object. You can NOT add parameters to this method!
Public Sub Initialize() As String
	Log("Initializing plugin " & GetNiceName)
	Return "MyKey"
End Sub

' must be available
public Sub GetNiceName() As String
	Return "zxingcppOCR"
End Sub

Private Sub InitIfNeeded 
	If decoder.IsInitialized = False Then
		decoder.Initialize
	End If
End Sub

' must be available
public Sub Run(Tag As String, Params As Map) As ResumableSub
	Select Tag
		Case "getParams"
			Dim paramsList As List
			paramsList.Initialize
			paramsList.Add("tryHarder")
			paramsList.Add("tryRotate")
			paramsList.Add("tryInvert")
			paramsList.Add("tryDownscale")
			paramsList.Add("formats")
			Return paramsList
		Case "getLangs"
			Return getLangs(Params.Get("loc"))
		Case "getText"
			wait for (GetText(Params.Get("img"))) complete (result As String)
			Return result
		Case "getTextWithLocation"
			wait for (GetTextWithLocation(Params.Get("img"))) complete (regions As List)
			Return regions
		Case "getDefaultParamValues"
			Return CreateMap("tryHarder":"false", _
			                 "tryRotate":"false", _
			                 "tryInvert":"false", _
			                 "tryDownscale":"false", _
			                 "formats":"")
	End Select
	Return ""
End Sub


Sub getLangs(loc As Localizator) As Map
	Dim result As Map
	result.Initialize
	Dim names,codes As List
	names.Initialize
	codes.Initialize
	codes.Add("barcode")
	names.Add(loc.Localize("条码"))
	result.Put("names",names)
	result.Put("codes",codes)
	Return result
End Sub


Sub GetText(img As B4XBitmap) As ResumableSub
	wait for (scan(img, False)) complete (boxes As List)
	Dim sb As StringBuilder
	sb.Initialize
	For i = 0 To boxes.Size - 1
		Dim box As Map = boxes.Get(i)
		If i > 0 Then sb.Append(CRLF)
		sb.Append(box.Get("text"))
	Next
	Return sb.ToString
End Sub

Sub GetTextWithLocation(img As B4XBitmap) As ResumableSub
	Dim regions As List
	regions.Initialize
	wait for (scan(img, True)) complete (boxes As List)
	For Each box As Map In boxes
		Dim region As Map = box.Get("geometry")
		region.Put("text", box.Get("text"))
		Dim extra As Map
		extra.Initialize
		If box.ContainsKey("format") Then extra.Put("format", box.Get("format"))
		If box.ContainsKey("symbology") Then extra.Put("symbology", box.Get("symbology"))
		If box.ContainsKey("corners") Then extra.Put("corners", box.Get("corners"))
		If box.ContainsKey("orientation") Then extra.Put("orientation", box.Get("orientation"))
		If box.ContainsKey("sequenceIndex") And box.ContainsKey("sequenceSize") Then
			extra.Put("sequenceIndex", box.Get("sequenceIndex"))
			extra.Put("sequenceSize", box.Get("sequenceSize"))
		End If
		region.Put("extra", extra)
		regions.Add(region)
	Next
	Return regions
End Sub

Sub scan(img As B4XBitmap, IncludeLocation As Boolean) As ResumableSub
	Dim boxes As List
	boxes.Initialize

	InitIfNeeded

	' Load preferences
	LoadPreferences

	' Convert B4XBitmap (JavaFX Image) to BufferedImage
	Dim swingUtils As JavaObject
	swingUtils.InitializeStatic("javafx.embed.swing.SwingFXUtils")
	Dim bufferedImage As JavaObject = swingUtils.RunMethod("fromFXImage", Array(img, Null))

	' Decode asynchronously (runs on background thread via Threading library)
	'wait for (decoder.decodeAsync(bufferedImage, enableTryHarder, enableTryRotate, _
	'	enableTryInvert, enableTryDownscale, IncludeLocation)) complete (result As List)
	Dim result As List = decoder.decode(bufferedImage, enableTryHarder, enableTryRotate, _
		enableTryInvert, enableTryDownscale, IncludeLocation)
	Return result
End Sub

Private Sub LoadPreferences
	Try
		If File.Exists(File.DirApp, "preferences.conf") Then
			Dim preferencesMap As Map = readJsonAsMap(File.ReadString(File.DirApp, "preferences.conf"))
			Dim apiMap As Map = getMap("zxingcpp", getMap("api", preferencesMap))
			enableTryHarder = apiMap.GetDefault("tryHarder", "false") = "true"
			enableTryRotate = apiMap.GetDefault("tryRotate", "false") = "true"
			enableTryInvert = apiMap.GetDefault("tryInvert", "false") = "true"
			enableTryDownscale = apiMap.GetDefault("tryDownscale", "false") = "true"
			formatFilter = apiMap.GetDefault("formats", "")
		End If
	Catch
		Log(LastException)
	End Try
End Sub

Sub readJsonAsMap(s As String) As Map
	Dim json As JSONParser
	json.Initialize(s)
	Return json.NextObject
End Sub

Sub getMap(key As String, parentmap As Map) As Map
	Return parentmap.Get(key)
End Sub