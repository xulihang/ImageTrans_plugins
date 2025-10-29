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
	engine.InitializeNewInstance("com.xulihang.AOTInpainter",Array(modelPath,False))
End Sub

Public Sub inpaintAsync(image As cvMat,mask As cvMat) As ResumableSub
	Dim map1 As Map
	map1.Initialize
	map1.Put("image",image)
	map1.Put("mask",mask)
	Log(map1)
	th.Start(Me,"inpaintUsingMap",Array As Map(map1))
	wait for th_Ended(endedOK As Boolean, error As String)
	Log(endedOK)
	Log(error)
	Dim out As cvMat = map1.Get("out")
	Return out
End Sub

Public Sub inpaint(image As cvMat,mask As cvMat) As cvMat
	Dim jo As JavaObject = engine.RunMethod("inpaint",Array(image.JO,mask.JO))
	Return cv2.matJO2mat(jo)
End Sub

Private Sub inpaintUsingMap(map1 As Map)
	Dim image As cvMat = map1.Get("image")
	Dim mask As cvMat = map1.Get("mask")
	Dim jo As JavaObject = engine.RunMethod("inpaint",Array(image.JO,mask.JO))
	map1.Put("out",cv2.matJO2mat(jo))
End Sub

