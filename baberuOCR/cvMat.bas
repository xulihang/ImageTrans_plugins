B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=7.8
@EndOfDesignText@
Sub Class_Globals
	Private fx As JFX
	Private matJO As JavaObject
End Sub

'Initializes the object. You can add parameters to this method if needed.
Public Sub Initialize(params() As Object)
	matJO.InitializeNewInstance("org.opencv.core.Mat",params)
End Sub

Public Sub copyTo(roi As cvMat,mask As cvMat)
	matJO.RunMethod("copyTo",Array(roi.JO,mask.JO))
End Sub

Public Sub release
	matJO.RunMethod("release",Null)
End Sub

Public Sub getJO As JavaObject
	Return matJO
End Sub

Public Sub setJO(mat As JavaObject)
	matJO=mat
End Sub

Public Sub get(indexes() As Int) As Double()
	Return matJO.RunMethod("get",Array(indexes))
End Sub

Public Sub put(indexes() As Int, data() As Double) As Int
	Return matJO.RunMethod("put",Array(indexes,data))
End Sub

Public Sub clone As cvMat
	Return matJO2mat(matJO.RunMethodJO("clone",Null))
End Sub

Sub matJO2mat(jo As JavaObject) As cvMat
	Dim mat As cvMat
	mat.Initialize(Null)
	mat.JO=jo
	Return mat
End Sub

Sub mat2bytes As Byte()
	Dim matOfByte As JavaObject
	matOfByte.InitializeNewInstance("org.opencv.core.MatOfByte",Null)
	'Dim bytes(Cols*Rows*Channels) As Byte
	'matJO.RunMethod("get",Array(0,0,bytes))
	cv2.imencode(".jpg", matJO, matOfByte)
	Dim bytes() As Byte
	bytes=matOfByte.RunMethod("toArray",Null)
	Return bytes
End Sub

Sub mat2bytesPNG As Byte()
	Dim matOfByte As JavaObject
	matOfByte.InitializeNewInstance("org.opencv.core.MatOfByte",Null)
	'Dim bytes(Cols*Rows*Channels) As Byte
	'matJO.RunMethod("get",Array(0,0,bytes))
	cv2.imencode(".png", matJO, matOfByte)
	Dim bytes() As Byte
	bytes=matOfByte.RunMethod("toArray",Null)
	Return bytes
End Sub

Sub mat2bytesWebP(quality As Int) As Byte()
	Dim matOfByte As JavaObject
	matOfByte.InitializeNewInstance("org.opencv.core.MatOfByte",Null)
	
	Dim params As JavaObject
	params.InitializeNewInstance("org.opencv.core.MatOfInt",Null)
	
	Dim imgcodecs As JavaObject
	imgcodecs.InitializeStatic("org.opencv.imgcodecs.Imgcodecs")
	
	Dim list1 As List
	list1.Initialize
	list1.Add(imgcodecs.GetField("IMWRITE_WEBP_QUALITY"))
	list1.Add(quality)
	
	params.RunMethod("fromList",Array(list1))
	imgcodecs.RunMethod("imencode",Array(".webp", matJO, matOfByte, params))

	Dim bytes() As Byte
	bytes=matOfByte.RunMethod("toArray",Null)
	Return bytes
End Sub

Public Sub mat2mat2f As JavaObject
	Dim mat2f As JavaObject
	mat2f.InitializeNewInstance("org.opencv.core.MatOfPoint2f",Array(matJO.RunMethod("toArray",Null)))
	Return mat2f
End Sub

Sub Channels As Int
	Return matJO.RunMethod("channels",Null)
End Sub

Sub Size As JavaObject
	Return matJO.RunMethodJO("size",Null)
End Sub

Public Sub dtype As Int
	Return matJO.RunMethod("type",Null)
End Sub

Sub Cols As Int
	Return matJO.RunMethod("cols",Null)
End Sub

Sub Rows As Int
	Return matJO.RunMethod("rows",Null)
End Sub

'cv rect
Public Sub submat(roi As JavaObject) As cvMat
	Dim jo As JavaObject = matJO.RunMethod("submat",Array(roi))
	Dim mat As cvMat
	mat.Initialize(Null)
	mat.JO = jo
	Return mat
End Sub