B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=8.8
@EndOfDesignText@
Sub Class_Globals
	Private fx As JFX
	Private engine As JavaObject
	Private th As Thread
End Sub

'Initializes the object. You can add parameters to this method if needed.
Public Sub Initialize
	th.Initialise("th")
End Sub

Public Sub loadModelAsync(encoder As String,decoder As String) As ResumableSub
	th.Start(Me,"loadModel",Array As String(encoder,decoder))
	wait for th_Ended(endedOK As Boolean, error As String)
	Log(endedOK)
	Log(error)
	Return engine
End Sub

Public Sub loadModel(encoder As String,decoder As String) As JavaObject
	engine.InitializeNewInstance("com.xulihang.SAMOnnxInference",Array(encoder,decoder))
	Return engine
End Sub



Public Sub BytesToImage(bytes() As Byte) As Image
	Dim In As InputStream
	In.InitializeFromBytesArray(bytes, 0, bytes.Length)
	Dim bmp As Image
	bmp.Initialize2(In)
	In.Close
	Return bmp
End Sub

Sub Image2cvMat2(img As B4XBitmap) As cvMat
	Return cv2.bytesToMat(ImageToBytes(img))
End Sub

Public Sub ImageToBytes(Image As B4XBitmap) As Byte()
	Dim out As OutputStream
	out.InitializeToBytesArray(0)
	Image.WriteToStream(out, 100, "JPEG")
	out.Close
	Return out.ToBytesArray
End Sub

Public Sub genmaskAsync(boxes As List,img As B4XBitmap) As ResumableSub
	Dim map1 As Map
	map1.Initialize
	map1.Put("boxes",boxes)
	map1.Put("img",img)
	th.Start(Me,"genmask",Array As Map(map1))
	wait for th_Ended(endedOK As Boolean, error As String)
	Log(endedOK)
	Log(error)
	Log(map1)
	Dim mask As B4XBitmap = map1.Get("mask")
	Return mask
End Sub

Public Sub genmask(map1 As Map) As B4XBitmap
	Dim boxes As List = map1.Get("boxes")
	Dim img As B4XBitmap = map1.Get("img")
	Dim mat As cvMat = Image2cvMat2(img)
	cv2.cvtColor(mat,mat,"COLOR_BGR2RGB")
	'Dim meJO As JavaObject = Me
	Dim convertedBoxes As List
	convertedBoxes.Initialize
	For Each box As List In boxes
		Dim convertedBox(4) As Float
		convertedBox(0)=box.Get(0)
		convertedBox(1)=box.Get(1)
		convertedBox(2)=box.Get(2)
		convertedBox(3)=box.Get(3)
		convertedBoxes.Add(convertedBox)
	Next
	'Dim boxPoints As JavaObject = meJO.RunMethod("getBox",Null)
	'Dim points1 As JavaObject = meJO.RunMethod("getPoints1",Null)
	'Dim labels1 As JavaObject = meJO.RunMethod("getLabels1",Null)
	Dim points1(0, 0) As Float ' 空的二维浮点数数组
	Dim labels1(0) As Float    ' 空的一维浮点数数组
	Dim jo As JavaObject = engine.RunMethod("infer",Array(convertedBoxes,points1,labels1,mat.JO))
	Dim m As cvMat = cv2.matJO2mat(jo)
	Dim mask As B4XBitmap = BytesToImage(m.mat2bytesPNG)
	map1.Put("mask",mask)
	Return mask
End Sub

#If Java
public static float[] getBox(){
    float[] box1 = {210, 200, 350, 500};
	return box1;
}
public static float[][] getPoints1(){
    float[][] points1 = {};
    return points1;
}
public static float[] getLabels1(){
    float[] labels1 = {};
	return labels1;
}
#End If