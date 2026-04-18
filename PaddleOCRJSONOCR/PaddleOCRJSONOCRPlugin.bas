B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=4.2
@EndOfDesignText@
Sub Class_Globals
	Private fx As JFX
	Private engine As JavaObject
	Private mRec As Boolean = True
End Sub

'Initializes the object. You can NOT add parameters to this method!
Public Sub Initialize() As String
	Log("Initializing plugin " & GetNiceName)
	' Here return a key to prevent running unauthorized plugins
	Return "MyKey"
End Sub

' must be available
public Sub GetNiceName() As String
	Return "PaddleOCRJSONOCR"
End Sub

Public Sub InitOCR(rec As Boolean)
	If engine.IsInitialized Then
		If rec == mRec Then
			Return
		End If
	End If
	mRec = rec
	
	Dim arguments As Map
	arguments.Initialize
	If mRec = False Then
		arguments.Put("rec",False)
	End If
	
	Dim fileJO As JavaObject
	fileJO.InitializeNewInstance("java.io.File",Array As String("PaddleOCR-json/PaddleOCR-json"))
	engine.InitializeNewInstance("org.example.Ocr",Array(fileJO,arguments))
End Sub

' must be available
public Sub Run(Tag As String, Params As Map) As ResumableSub
	Select Tag
		Case "getParams"
			Dim paramsList As List
			paramsList.Initialize
			Return paramsList
		Case "getText"
			InitOCR(mRec)
			wait for (GetText(Params.Get("img"),Params.Get("lang"),Params.Get("path"))) complete (result As String)
			mRec = True
			Return result
		Case "getTextWithLocation"
			InitOCR(mRec)
			wait for (GetTextWithLocation(Params.Get("img"),Params.Get("lang"),Params.Get("path"))) complete (regions As List)
			mRec = True
			Return regions
		Case "getSetupParams"
			Dim paramsMap As Map
			paramsMap.Initialize
			paramsMap.Put("readme","https://github.com/xulihang/ImageTrans_plugins/tree/master/PaddleOCRJSONOCR")
			Dim o As Object = paramsMap
			Return o
		Case "getIsInstalledOrRunning"
			Dim root As String = Params.Get("root")
			If File.Exists(root,"PaddleOCR-json") Then
				Return True
			End If
			Return False
		Case "SetCombination"
			Dim comb As String=Params.Get("combination")
			mRec = Not(comb.Contains("detect only"))
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
	combs.Add("PaddleOCRJSON")
	combs.Add("detect only (PaddleOCRJSON)")
	Return combs
End Sub


Sub GetText(img As B4XBitmap, lang As String, path As String) As ResumableSub
	wait for (ocr(img,lang,path)) complete (boxes As List)
	Dim sb As StringBuilder
	sb.Initialize
	For Each box As Map In boxes
		sb.Append(box.Get("text"))
		sb.Append(CRLF)
	Next
	Return sb.ToString
End Sub

Sub GetTextWithLocation(img As B4XBitmap, lang As String, path As String) As ResumableSub
	wait for (ocr(img,lang,path)) complete (boxes As List)
	Dim regions As List
	regions.Initialize
	For Each box As Map In boxes
		Dim region As Map=box.Get("geometry")
		region.Put("text",box.Get("text"))
		addExtra(region,box)
		regions.Add(region)
	Next
	Return regions
End Sub

Private Sub addExtra(region As Map,box As Map)
	Dim extra As Map
	extra.Initialize
	For Each key As String In box.Keys
		If key <> "geometry" And key <> "text" Then
			extra.Put(key,box.Get(key))
		End If
	Next
	region.Put("extra",extra)
End Sub

private Sub GenerateUniqueName As String
	Dim randomNumber As Int = Rnd(0,1000)
	Dim timestamp As String = DateTime.Now
	Return timestamp&"-"&randomNumber&".jpg"
End Sub

Sub ocr(img As B4XBitmap,lang As String, imgPath As String) As ResumableSub
	Dim boxes As List
	boxes.Initialize
	Dim path As String
	
	If File.Exists(imgPath,"") Then
		path = imgPath
	Else
		path = File.Combine(File.DirApp,GenerateUniqueName)
		Dim out As OutputStream
		out=File.OpenOutput(path,"",False)
		img.WriteToStream(out,"100","JPEG")
		out.Close
	End If
	
	Dim imageFileJO As JavaObject
	imageFileJO.InitializeNewInstance("java.io.File",Array As String(path))
	Dim response As JavaObject = engine.RunMethod("runOcr",Array(imageFileJO))

	If 100 = response.RunMethod("getCode",Null) Then
		Dim entries() As Object = response.RunMethod("getData",Null)
		For Each entry As JavaObject In entries
			Dim X1 As Int = entry.RunMethod("getX1",Null)
			Dim X2 As Int = entry.RunMethod("getX2",Null)
			Dim X3 As Int = entry.RunMethod("getX3",Null)
			Dim X4 As Int = entry.RunMethod("getX4",Null)
			Dim Y1 As Int = entry.RunMethod("getY1",Null)
			Dim Y2 As Int = entry.RunMethod("getY2",Null)
			Dim Y3 As Int = entry.RunMethod("getY3",Null)
			Dim Y4 As Int = entry.RunMethod("getY4",Null)
			Dim text As String = entry.RunMethod("getText",Null)
			Dim box As Map
			box.Initialize
			Dim boxGeometry As Map
			boxGeometry.Initialize
			boxGeometry.Put("X",X1)
			boxGeometry.Put("Y",Y1)
			boxGeometry.Put("width",X2 - X1)
			boxGeometry.Put("height",Y3 - Y1)
			box.Put("text",text)
			box.Put("geometry",boxGeometry)
			boxes.Add(box)
		Next
	End If
	Return boxes
End Sub

