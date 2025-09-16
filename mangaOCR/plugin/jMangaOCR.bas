B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=10
@EndOfDesignText@
Sub Class_Globals
	Private engine As JavaObject
	Private th As Thread
	Private mModelPath As String
	Private mVocabPath As String
End Sub

'Initializes the object. You can add parameters to this method if needed.
Public Sub Initialize(modelPath As String,vocabPath As String)
	th.Initialise("th")
	mModelPath = modelPath
	mVocabPath = vocabPath
End Sub

Public Sub loadModelAsync As ResumableSub
	Dim map1 As Map
	map1.Initialize
	th.Start(Me,"loadModelUsingMap",Array As Map(map1))
	wait for th_Ended(endedOK As Boolean, error As String)
	Log(endedOK)
	Log(error)
	engine = map1.Get("engine")
	Return engine
End Sub

Public Sub loadModel
	engine.InitializeNewInstance("com.xulihang.MangaOCR",Array(mModelPath,mVocabPath))
End Sub

Public Sub recognizeAsync(image As cvMat) As ResumableSub
	Dim map1 As Map
	map1.Initialize
	map1.Put("image",image)
	th.Start(Me,"recognizeUsingMap",Array As Map(map1))
	wait for th_Ended(endedOK As Boolean, error As String)
	Log(endedOK)
	Log(error)
	Dim text As String = map1.Get("text")
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

Private Sub loadModelUsingMap(map1 As Map)
	Dim jo As JavaObject
	jo.InitializeNewInstance("com.xulihang.MangaOCR",Array(mModelPath,mVocabPath))
	map1.Put("engine",jo)
End Sub
