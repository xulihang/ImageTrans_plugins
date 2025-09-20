B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=10
@EndOfDesignText@
Sub Class_Globals
	Private engine As JavaObject
	Private th As Thread
End Sub

'Initializes the object. You can add parameters to this method if needed.
Public Sub Initialize
	th.Initialise("th")
End Sub

Public Sub loadModelWithPathAsync(encoder As String,decoder As String,vocabs As List) As ResumableSub
	Dim map1 As Map
	map1.Initialize
	map1.Put("encoder",encoder)
	map1.Put("decoder",decoder)
	map1.Put("vocabs",vocabs)
	th.Start(Me,"loadModelWithPathUsingMap",Array As Map(map1))
	wait for th_Ended(endedOK As Boolean, error As String)
	Log(endedOK)
	Log(error)
	engine = map1.Get("engine")
	Return engine
End Sub

Public Sub loadModelAsync(encoder() As Byte,decoder() As Byte,vocabs As List) As ResumableSub
	Dim map1 As Map
	map1.Initialize
	map1.Put("encoder",encoder)
	map1.Put("decoder",decoder)
	map1.Put("vocabs",vocabs)
	th.Start(Me,"loadModelUsingMap",Array As Map(map1))
	wait for th_Ended(endedOK As Boolean, error As String)
	Log(endedOK)
	Log(error)
	engine = map1.Get("engine")
	Return engine
End Sub

Private Sub loadModelUsingMap(map1 As Map)
	Dim encoder() As Byte = map1.Get("encoder")
	Dim decoder() As Byte = map1.Get("decoder")
	Dim vocabs As List = map1.Get("vocabs")
	Dim jo As JavaObject
	jo.InitializeNewInstance("com.xulihang.MangaOCR",Array(encoder,decoder,vocabs))
	map1.Put("engine",jo)
End Sub

Private Sub loadModelWithPathUsingMap(map1 As Map)
	Dim encoder As String = map1.Get("encoder")
	Dim decoder As String = map1.Get("decoder")
	Dim vocabs As List = map1.Get("vocabs")
	Dim jo As JavaObject
	jo.InitializeNewInstance("com.xulihang.MangaOCR",Array(encoder,decoder,vocabs))
	map1.Put("engine",jo)
End Sub


Public Sub loadModel(encoder() As Byte,decoder() As Byte,vocabs As List)
	engine.InitializeNewInstance("com.xulihang.MangaOCR",Array(encoder,decoder,vocabs))
End Sub

Public Sub loadModelWithPath(encoder As String,decoder As String,vocabs As List)
	engine.InitializeNewInstance("com.xulihang.MangaOCR",Array(encoder,decoder,vocabs))
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

Public Sub recognizeAsync(image As cvMat) As ResumableSub
	Dim text As String
	Dim map1 As Map
	map1.Initialize
	map1.Put("image",image)
	DoProcessingAsync(map1)
	wait for Recognized(Success As Boolean)
	If Success=True Then
		text = map1.Get("text")
	End If
	Return text
End Sub

Public Sub recognize(image As cvMat) As String
	Return engine.RunMethod("run",Array(image.JO))
End Sub

Private Sub recognizeUsingMap(map1 As Map)
	Dim image As cvMat = map1.Get("image")
	Dim text As String = engine.RunMethod("run",Array(image.JO))
	map1.Put("text",text)
End Sub

