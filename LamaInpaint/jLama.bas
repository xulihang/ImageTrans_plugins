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
End Sub

'Initializes the object. You can add parameters to this method if needed.
Public Sub Initialize(modelPath As String)
	th.Initialise("th")
	mModelPath = modelPath
	engine.InitializeStatic("com.xulihang.LamaInpaintDynamicSingleton")
End Sub

Public Sub loadModelAsync As ResumableSub
	Log("model loading")
	th.Start(Me,"loadModel",Null)
	wait for th_Ended(endedOK As Boolean, error As String)
	Log(endedOK)
	Log(error)
	Log("model loaded")
End Sub

Public Sub loadModel
	Dim jo As JavaObject
	jo.InitializeStatic("com.xulihang.LamaInpaintDynamicSingleton.ModelCache")
	jo.RunMethod("init",Array(mModelPath))
End Sub

Public Sub inpaintAsync(image As cvMat,mask As cvMat,size As Int) As ResumableSub
	Dim map1 As Map
	map1.Initialize
	map1.Put("image",image)
	map1.Put("mask",mask)
	map1.Put("size",size)
	Log(map1)
	th.Start(Me,"inpaintUsingMap",Array As Map(map1))
	wait for th_Ended(endedOK As Boolean, error As String)
	Log(endedOK)
	Log(error)
	Dim out As cvMat = map1.Get("out")
	Return out
End Sub

Public Sub inpaint(image As cvMat,mask As cvMat,size As Int) As cvMat
	Dim jo As JavaObject = engine.RunMethod("inpaintONNX",Array(image.JO,mask.JO,size))
	Return cv2.matJO2mat(jo)
End Sub

Private Sub inpaintUsingMap(map1 As Map)
	Dim image As cvMat = map1.Get("image")
	Dim mask As cvMat = map1.Get("mask")
	Dim size As Int = map1.Get("size")
	Dim jo As JavaObject = engine.RunMethod("inpaintONNX",Array(image.JO,mask.JO,size))
	map1.Put("out",cv2.matJO2mat(jo))
End Sub
