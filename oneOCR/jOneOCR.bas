B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=10
@EndOfDesignText@
Sub Class_Globals
	Private engine As JavaObject
	Private th As Thread
	Public folder As String
End Sub

'Initializes the object. You can add parameters to this method if needed.
Public Sub Initialize
	th.Initialise("th")
	Dim finder As JavaObject
	finder.InitializeStatic("com.xulihang.oneocr.OneOCREngine")
	Dim dllFolder As JavaObject = finder.RunMethod("findSnippingToolDir",Null)
	Try
		folder = dllFolder.RunMethodJO("toAbsolutePath",Null).RunMethod("toString",Null)
	Catch
		Log(LastException)
	End Try
	If File.Exists(folder,"") Then
		engine.InitializeNewInstance("com.xulihang.oneocr.OneOCREngine",Array(dllFolder))
		engine.RunMethod("load", Null)
	End If
End Sub

Sub DoProcessingAsync(map1 As Map) As ResumableSub
	Dim b() As Boolean = Array As Boolean(False)
	TimeOutImpl(10000, b)
	th.Start(Me,"recognizeUsingMap",Array As Map(map1))
	wait for th_Ended(endedOK As Boolean, error As String)
	If b(0) = False Then
		b(0) = True
		CallSubDelayed2(Me, "Recognized", True)
	End If
	Return endedOK
End Sub

Sub TimeOutImpl(Duration As Int, b() As Boolean)
	Sleep(Duration)
	If b(0) = False Then
		b(0) = True
		Log("time out")
		CallSubDelayed2(Me, "Recognized", False)
	End If
End Sub

Public Sub recognizeAsync(img As Image) As ResumableSub
	Dim lines As List
	lines.Initialize
	Dim map1 As Map
	map1.Initialize
	map1.Put("image",img)
	DoProcessingAsync(map1)
	wait for Recognized(Success As Boolean)
	If Success=True Then
		lines = map1.Get("lines")
	End If
	Return lines
End Sub

Public Sub recognize(img As Image) As List
	Dim b As JavaObject = convertImageToBufferedBitmap(img)
	Log(b)
	Return engine.RunMethod("recognize",Array(b))
End Sub


Public Sub recognizeUsingMap(map1 As Map)
	Dim img As Image = map1.Get("image")
	Dim lines As List = engine.RunMethod("recognize",Array(convertImageToBufferedBitmap(img)))
	map1.Put("lines",lines)
End Sub

Private Sub convertImageToBufferedBitmap(img As Image) As JavaObject
	Dim jo As JavaObject
	jo.InitializeStatic("javafx.embed.swing.SwingFXUtils")
	Return jo.RunMethod("fromFXImage",Array(img,Null))
End Sub

