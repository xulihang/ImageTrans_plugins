B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=4.2
@EndOfDesignText@
Sub Class_Globals
	Private fx As JFX
End Sub

'Initializes the object. You can NOT add parameters to this method!
Public Sub Initialize() As String
	Log("Initializing plugin " & GetNiceName)
	' Here return a key to prevent running unauthorized plugins
	Return "MyKey"
End Sub

' must be available
public Sub GetNiceName() As String
	Return "OpenAIInpaint"
End Sub

' must be available
public Sub Run(Tag As String, Params As Map) As ResumableSub
	Log("run"&Params)
	Select Tag
		Case "getParams"
			Dim paramsList As List
			paramsList.Initialize
			paramsList.Add("key")
			paramsList.Add("url")
			paramsList.Add("model")
			paramsList.Add("output_size")
			Return paramsList
		Case "inpaint"
			wait for (inpaint(Params.Get("origin"),Params.Get("mask"),Params.GetDefault("settings",getDefaultSettings))) complete (result As B4XBitmap)
			Return result
		Case "getDefaultParamValues"
			Return getDefaultSettings
	End Select
	Return ""
End Sub


Private Sub getDefaultSettings As Map
	Return CreateMap("url":"https://api.openai.com/v1/images/edits","model":"gpt-image-1","output_size":"1024x1024")
End Sub

Public Sub ImageToBytes(Image As B4XBitmap) As Byte()
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
	Dim result As B4XBitmap = origin
	Dim targetSize As Int = 1024
	Dim model As String = settings.GetDefault("model","gpt-image-1")
	Dim key As String
	Dim url As String = "https://api.openai.com/v1/images/edits"
	If settings.ContainsKey("url") Then
		url = settings.Get("url")
	End If
	If settings.ContainsKey("key") Then
		key = settings.Get("key")
	Else
		Return result
	End If
	
	Try
		targetSize = Regex.Split("x",settings.GetDefault("output_size","1024x1024"))(0)
	Catch
		Log(LastException)
	End Try
	
	
	mask = updateMask(mask)
	
	Dim resized As B4XBitmap
	resized = origin.Resize(targetSize,targetSize,True)
	mask = mask.Resize(targetSize,targetSize,True)
	Dim paddedSrc As B4XBitmap = paddedImage(resized,targetSize)
	mask = paddedImage(mask,targetSize)
	
	Dim su As StringUtils

	Dim srcBase64 As String = su.EncodeBase64(ImageToBytes(paddedSrc))
	Dim maskBase64 As String = su.EncodeBase64(ImageToBytes(mask))

	Dim job As HttpJob
	job.Initialize("",Me)
	
	' 构造请求 JSON
	Dim json As String = $"
{
    "model": "${model}",
    "image": "data:image/png;base64,${srcBase64}",
    "mask": "data:image/png;base64,${maskBase64}",
    "prompt": "Remove the text from the image with the mask."
}
"$
    'Log(json)
	job.PostString(url, json)
	job.GetRequest.SetHeader("Authorization",$"Bearer ${key}"$)
	job.GetRequest.SetContentType("application/json")
	job.GetRequest.Timeout=240*1000
	Wait For (job) JobDone(job As HttpJob)
	If job.Success Then
		Try
			Dim parser As JSONParser
			parser.Initialize(job.GetString)
			Log(job.GetString)
			Dim response As Map = parser.NextObject
			Dim dataList As List = response.Get("data")
			Dim imgData As Map = dataList.Get(0)
		    Dim b64 As String = imgData.Get("b64_json")
			Dim su As StringUtils
			Dim out() As Byte = su.DecodeBase64(b64)
			'File.WriteBytes(File.DirApp, "result.png", out)
			'Log("输出图片已保存为 result.png")
			result = BytesToImage(out)
			result = result.Crop(0,0,resized.Width,resized.Height)
			result = result.Resize(origin.Width,origin.Height,False)
		Catch
			Log(LastException)
		End Try
	End If
	job.Release
	Return result
End Sub

Public Sub BytesToImage(bytes() As Byte) As Image
	Dim In As InputStream
	In.InitializeFromBytesArray(bytes, 0, bytes.Length)
	Dim bmp As Image
	bmp.Initialize2(In)
	In.Close
	Return bmp
End Sub