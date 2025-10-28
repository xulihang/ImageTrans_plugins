B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=4.2
@EndOfDesignText@
Sub Class_Globals
	Private fx As JFX
	Private engine As jMIGAN
End Sub

'Initializes the object. You can NOT add parameters to this method!
Public Sub Initialize() As String
	Log("Initializing plugin " & GetNiceName)
	' Here return a key to prevent running unauthorized plugins
	Return "MyKey"
End Sub

' must be available
public Sub GetNiceName() As String
	Return "MIGANInpaint"
End Sub

' must be available
public Sub Run(Tag As String, Params As Map) As ResumableSub
	Log("run"&Params)
	Select Tag
		Case "getParams"
			Dim paramsList As List
			paramsList.Initialize
			Return paramsList
		Case "inpaint"
			wait for (inpaint(Params.Get("origin"),Params.Get("mask"))) complete (result As B4XBitmap)
			Return result
		Case "getSetupParams"
			Dim o As Object = CreateMap("readme":"https://github.com/xulihang/ImageTrans_plugins/tree/master/MIGANInpaint")
			Return o
		Case "getIsInstalledOrRunning"
			Wait For (CheckIsRunning) complete (running As Boolean)
			Return running
	End Select
	Return ""
End Sub

Private Sub LoadMIGANIfNeeded As ResumableSub
	If engine.IsInitialized = False Then
		engine.Initialize(File.Combine(File.DirApp,"migan_pipeline_v2.onnx"))
	End If
	Return True
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

Public Sub ImageToPNGBytes(Image As B4XBitmap) As Byte()
	Dim out As OutputStream
	out.InitializeToBytesArray(0)
	Image.WriteToStream(out, 100, "PNG")
	out.Close
	Return out.ToBytesArray
End Sub

Sub inpaint(origin As B4XBitmap,mask As B4XBitmap) As ResumableSub
	If ONNXExists Then
		Dim resizedSrc As B4XBitmap = origin.Resize(512,512,False)
		mask = mask.Resize(512,512,False)
		Wait For (LoadMIGANIfNeeded) complete (done As Object)
		Dim originMat As cvMat = Image2cvMat2(resizedSrc)
		Dim maskMat As cvMat = cv2.bytesToMat2(ImageToPNGBytes(mask),"IMREAD_UNCHANGED")
		Dim gray As cvMat
		gray.Initialize(Null)
		cv2.cvtColor(maskMat,gray,"COLOR_BGR2GRAY")
		Dim thresh As cvMat
		thresh.Initialize(Null)
		cv2.threshold(gray,thresh,200,255,cv2.procEnum("THRESH_BINARY_INV")+cv2.procEnum("THRESH_OTSU"))
		cv2.erode(thresh,thresh,cv2.getStructuringElement("MORPH_RECT",3,3))
		File.WriteBytes(File.DirApp,"m.jpg",thresh.mat2bytes)
		wait for (engine.inpaintAsync(originMat,thresh)) complete (resultMat As cvMat)
		gray.release
		thresh.release
		originMat.release
		maskMat.release
		Dim result As B4XBitmap
		result = BytesToImage(resultMat.mat2bytes)
		result = result.Resize(origin.Width,origin.Height,False)
		Return result
	End If
	Return origin
End Sub

Private Sub ONNXExists As Boolean
	If File.Exists(File.DirApp,"migan_pipeline_v2.onnx") Then
		Return True
	End If
	Return False
End Sub

private Sub CheckIsRunning As ResumableSub
	If ONNXExists Then
		Return True
	End If
	Return False
End Sub