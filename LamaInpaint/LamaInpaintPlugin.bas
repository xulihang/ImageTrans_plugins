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
	Return "LamaInpaint"
End Sub

' must be available
public Sub Run(Tag As String, Params As Map) As ResumableSub
	Log("run"&Params)
	Select Tag
		Case "inpaint"
			wait for (inpaint(Params.Get("origin"),Params.Get("mask"))) complete (result As B4XBitmap)
			Return result
		Case "getDefaultParamValues"
			Return CreateMap("url":"http://localhost:8087/inpaint")
	End Select
	Return ""
End Sub

Sub inpaint(origin As B4XBitmap,mask As B4XBitmap) As ResumableSub
	Dim out As OutputStream
	out=File.OpenOutput(File.DirApp,"origin.jpg",False)
	origin.WriteToStream(out,"100","JPEG")
	out.Close
	
	Dim r As B4XRect
	r.Initialize(0,0,mask.Width,mask.Height)

    Dim xui As XUI	
	Dim bc As BitmapCreator
	bc.Initialize(mask.Width,mask.Height)
	bc.DrawBitmap(mask,r,False)
	For x = 0 To mask.Width - 1
	    For y = 0 To mask.Height - 1
			Dim color As ARGBColor
			bc.GetARGB(x,y,color)
		    If color.a = 0 Or (color.b = 255 And color.r = 255 And color.g = 255) Then 'transparent or white
				bc.SetColor(x,y,xui.Color_Black)
			Else
				bc.SetColor(x,y,xui.Color_White)
		    End If
		Next
	Next
	
	
	Dim out As OutputStream
	out=File.OpenOutput(File.DirApp,"mask.png",False)
	bc.Bitmap.WriteToStream(out,"100","PNG")
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
	
	
	
	job.PostMultipart(getUrl, _
                           CreateMap("ldmSteps":"50", _ 
                           "hdStrategy":"resize", _ 
						   "hdStrategyCropMargin":"128", _ 
						   "hdStrategyCropTrigerSize":"2048", _ 
						   "hdStrategyResizeLimit":"2048"), _ 
						   Array(originFd,maskFd))
	job.GetRequest.Timeout=240*1000
	Wait For (job) JobDone(job As HttpJob)
	If job.Success Then
		Try
			Dim result As B4XBitmap=job.GetBitmap
			Return result
		Catch
			Log(LastException)
		End Try
	End If
	Return origin
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

Sub getMap(key As String,parentmap As Map) As Map
	Return parentmap.Get(key)
End Sub

Sub readJsonAsMap(s As String) As Map
	Dim json As JSONParser
	json.Initialize(s)
	Return json.NextObject
End Sub
