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
			paramsList.Add("max_size")
			Return paramsList
		Case "inpaint"
			wait for (inpaint(Params.Get("origin"),Params.Get("mask"),Params.GetDefault("settings",getDefaultSettings))) complete (result As B4XBitmap)
			Return result
		Case "getSetupParams"
			Dim o As Object = CreateMap("readme":"https://github.com/xulihang/ImageTrans_plugins/tree/master/MIGANInpaint")
			Return o
		Case "getIsInstalledOrRunning"
			Wait For (CheckIsRunning) complete (running As Boolean)
			Return running
		Case "getDefaultParamValues"
			Return getDefaultSettings
	End Select
	Return ""
End Sub

Private Sub getDefaultSettings As Map
	Return CreateMap("max_size":"1536")
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

Sub paddedImage(origin As B4XBitmap,targetSize As Int) As B4XBitmap
	Dim bc As BitmapCreator
	bc.Initialize(targetSize,targetSize)
	Dim r As B4XRect
	r.Initialize(0,0,origin.Width,origin.Height)
	bc.DrawBitmap(origin,r,True)
	Return bc.Bitmap
End Sub

Sub inpaint(origin As B4XBitmap,mask As B4XBitmap,settings As Map) As ResumableSub
	If ONNXExists Then
		'Dim resizedSrc As B4XBitmap = origin.Resize(512,512,False)
		'mask = mask.Resize(512,512,False)
		
		Dim maxSize As Int = settings.GetDefault("max_size",1536)
		
		If maxSize Mod 64 <> 0 Then
			maxSize = Ceil(maxSize/64) * 64
		End If
		
		Dim resized As B4XBitmap = origin
		If origin.Width < maxSize And origin.Height < maxSize Then
			If origin.Width < origin.Height Then
				maxSize = Ceil(origin.Height / 64) * 64
			Else
				maxSize = Ceil(origin.Width / 64) * 64
			End If
		Else
			resized = origin.Resize(maxSize,maxSize,True)
			mask = mask.Resize(maxSize,maxSize,True)
		End If
		
		Wait For (LoadMIGANIfNeeded) complete (done As Object)
		
		Dim paddedSrc As B4XBitmap = paddedImage(resized,maxSize)
		mask = paddedImage(mask,maxSize)
		
		Dim originMat As cvMat = Image2cvMat2(paddedSrc)
		
		'File.WriteBytes(File.DirApp,"padded.jpg",originMat.mat2bytes)
		
		Dim maskMat As cvMat = cv2.bytesToMat2(ImageToPNGBytes(mask),"IMREAD_UNCHANGED")
		
		Dim gray As cvMat
		gray.Initialize(Null)
		cv2.cvtColor(maskMat,gray,"COLOR_BGR2GRAY")
		Dim thresh As cvMat
		thresh.Initialize(Null)
		cv2.threshold(gray,thresh,200,255,cv2.procEnum("THRESH_BINARY_INV")+cv2.procEnum("THRESH_OTSU"))
		cv2.erode(thresh,thresh,cv2.getStructuringElement("MORPH_RECT",3,3))
		
		wait for (engine.inpaintAsync(originMat,thresh)) complete (resultMat As cvMat)
		gray.release
		thresh.release
		originMat.release
		maskMat.release
		'File.WriteBytes(File.DirApp,"resultMat.jpg",resultMat.mat2bytes)
		Dim result As B4XBitmap
		result = BytesToImage(resultMat.mat2bytes)
		result = result.Crop(0,0,resized.Width,resized.Height)
		result = result.Resize(origin.Width,origin.Height,False)
		resultMat.release
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