B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=4.2
@EndOfDesignText@
Sub Class_Globals
	Private fx As JFX
	Private engine As jLama
End Sub

'Initializes the object. You can NOT add parameters to this method!
Public Sub Initialize() As String
	Log("Initializing plugin " & GetNiceName)
	' Here return a key to prevent running unauthorized plugins
	Return "MyKey"
End Sub

' must be available
public Sub GetNiceName() As String
	Return "LamaInpaint"
End Sub

' must be available
public Sub Run(Tag As String, Params As Map) As ResumableSub
	Log("run"&Params)
	Select Tag
		Case "getParams"
			Dim paramsList As List
			paramsList.Initialize
			paramsList.Add("url")
			paramsList.Add("max_size")
			Return paramsList
		Case "inpaint"
			wait for (inpaint(Params.Get("origin"),Params.Get("mask"),Params.GetDefault("settings",getDefaultSettings))) complete (result As B4XBitmap)
			Return result
		Case "getSetupParams"
			Dim o As Object = CreateMap("readme":"https://github.com/xulihang/ImageTrans_plugins/tree/master/LamaInpaint")
			Return o
		Case "getIsInstalledOrRunning"
			Wait For (CheckIsRunning) complete (running As Boolean)
			Return running
		Case "getDefaultParamValues"
			Return getDefaultSettings
		Case "betterEntireImage"
			Return True
	End Select
	Return ""
End Sub

Private Sub getDefaultSettings As Map
	Return CreateMap("url":"http://localhost:8087/inpaint","max_size":"960")
End Sub

Private Sub LoadLamaIfNeeded As ResumableSub
	If engine.IsInitialized = False Then
		engine.Initialize(File.Combine(File.DirApp,"big-lama.onnx"))
		wait for (engine.loadModelAsync) complete (done As Object)
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

Public Sub updateMask(mask As B4XBitmap) As B4XBitmap
	Dim xui As XUI
	Dim r As B4XRect
	r.Initialize(0,0,mask.Width,mask.Height)
	Dim bc As BitmapCreator
	bc.Initialize(mask.Width,mask.Height)
	bc.DrawBitmap(mask,r,False)
	For x = 0 To mask.Width - 1
		For y = 0 To mask.Height - 1
			Dim color As ARGBColor
			bc.GetARGB(x,y,color)
			If color.a = 0 Or (color.b = 0 And color.r = 0 And color.g = 0) Then 'black or transparent
				bc.SetColor(x,y,xui.Color_Black)
			Else
				bc.SetColor(x,y,xui.Color_White)
			End If
		Next
	Next
	Return bc.Bitmap
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
		Dim maxSize As Int = settings.GetDefault("max_size",960)
		
		If maxSize Mod 64 <> 0 Then
			maxSize = Ceil(maxSize/64) * 64
		End If
		
		mask = updateMask(mask)
		
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
		
		Dim paddedSrc As B4XBitmap = paddedImage(resized,maxSize)
		
		mask = paddedImage(mask,maxSize)
		
		Wait For (LoadLamaIfNeeded) complete (done As Object)
		
		Dim originMat As cvMat = Image2cvMat2(paddedSrc)
		Dim maskMat As cvMat = cv2.bytesToMat2(ImageToPNGBytes(mask),"IMREAD_UNCHANGED")
		wait for (engine.inpaintAsync(originMat,maskMat)) complete (resultMat As cvMat)
		'Dim resultMat As cvMat = engine.inpaint(originMat,maskMat)
		originMat.release
		maskMat.release
		Dim result As B4XBitmap
		result = BytesToImage(resultMat.mat2bytes)
		result = result.Crop(0,0,resized.Width,resized.Height)
		result = result.Resize(origin.Width,origin.Height,False)
		resultMat.release
		Return result
	End If
	
	mask = updateMask(mask)
	Dim out As OutputStream
	out=File.OpenOutput(File.DirApp,"origin.jpg",False)
	origin.WriteToStream(out,"100","JPEG")
	out.Close
	
	Dim out As OutputStream
	out=File.OpenOutput(File.DirApp,"mask.png",False)
	mask.WriteToStream(out,"100","PNG")
	out.Close
	
	Dim job As HttpJob
	job.Initialize("",Me)
	
	Dim originFd As MultipartFileData
	originFd.Initialize
	originFd.KeyName = "image"
	originFd.Dir = File.DirApp
	originFd.FileName = "origin.jpg"
	originFd.ContentType = "image/jpg"
	
	Dim maskFd As MultipartFileData
	maskFd.Initialize
	maskFd.KeyName = "mask"
	maskFd.Dir = File.DirApp
	maskFd.FileName = "mask.png"
	maskFd.ContentType = "image/png"
	
	
	
	job.PostMultipart(settings.GetDefault("url","http://localhost:8087/inpaint"), _
                           CreateMap("ldmSteps":"50", _ 
						   "ldmSampler":"plms", _ 
						   "zitsWireframe":"true", _ 
                           "hdStrategy":"Resize", _ 
						   "hdStrategyCropMargin":"196", _ 
						   "hdStrategyCropTrigerSize":"2048", _ 
						   "hdStrategyResizeLimit":"2048", _ 
	                       "prompt":"", _
						   "negativePrompt":"", _
						   "useCroper":"false", _
						   "croperX":"228", _
						   "croperY":"450", _
						   "croperWidth":"512", _
						   "croperHeight":"512", _
						   "sdScale":"1", _
						   "sdMaskBlur":"5", _
						   "sdSteps":"50", _
						   "sdGuidanceScale":"7.5", _
						   "sdStrength":"0.75", _
						   "sdSampler":"uni_pc", _
						   "sdSeed":"-1", _
						   "sdMatchHistograms":"false", _
						   "cv2Flag":"INPAINT_NS", _
						   "cv2Radius":"5", _
						   "paintByExampleSteps":"50", _
						   "paintByExampleGuidanceScale":"7.5", _
						   "paintByExampleMaskBlur":"5", _
						   "paintByExampleSeed":"-1", _
						   "paintByExampleMatchHistograms":"false", _
						   "p2pSteps":"50", _
						   "p2pImageGuidanceScale":"1.5", _
						   "p2pGuidanceScale":"7.5", _
						   "controlnet_conditioning_scale":"0.4", _
						   "controlnet_method":"control_v11p_sd15_canny" _
						   ), _ 
						   Array(originFd,maskFd))
	job.GetRequest.Timeout=240*1000
	Wait For (job) JobDone(job As HttpJob)
	If job.Success Then
		Try
			Dim result As B4XBitmap=job.GetBitmap
			If result.Width <> origin.Width Then
				Log("Inconsistent size")
				result = result.Resize(origin.Width,origin.Height,False)
			End If
			Return result
		Catch
			Log(LastException)
		End Try
	End If
	job.Release
	Return origin
End Sub

Sub readJsonAsMap(s As String) As Map
	Dim json As JSONParser
	json.Initialize(s)
	Return json.NextObject
End Sub

Sub getMap(key As String,parentmap As Map) As Map
	Return parentmap.Get(key)
End Sub

Sub getUrl As String
	Dim url As String = "http://localhost:8087/inpaint"
	If File.Exists(File.DirApp,"preferences.conf") Then
		Try
			Dim preferencesMap As Map = readJsonAsMap(File.ReadString(File.DirApp,"preferences.conf"))
			url=getMap("LamaInpaint",getMap("api",preferencesMap)).GetDefault("url",url)
		Catch
			Log(LastException)
		End Try
	End If
	Return url
End Sub

Private Sub ONNXExists As Boolean
	If File.Exists(File.DirApp,"big-lama.onnx") Then
		Return True
	End If
	Return False
End Sub

private Sub CheckIsRunning As ResumableSub
	If ONNXExists Then
		Return True
	End If
	Dim result As Boolean = True
	Dim job As HttpJob
	job.Initialize("job",Me)
	job.Head(getUrl)
	job.GetRequest.Timeout = 500
	Wait For (job) JobDone(job As HttpJob)
	If job.Success = False Then
	    If job.Response.StatusCode <> 404 And job.Response.StatusCode <> 405 Then
		    result = False
		End If
	End If
	job.Release
	Return result
End Sub