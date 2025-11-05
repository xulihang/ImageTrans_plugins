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
	Return "SegmentAnythingMaskGen"
End Sub

' must be available
public Sub Run(Tag As String, Params As Map) As ResumableSub
	Log("run"&Params)
	Select Tag
		Case "getParams"
			Dim paramsList As List
			paramsList.Initialize
			Return paramsList
		Case "genMask"
			wait for (genMask(Params.Get("img"),Params.Get("boxes"))) complete (result As B4XBitmap)
			Return result
	End Select
	Return ""
End Sub

Sub genMask(img As B4XBitmap,boxes As List) As ResumableSub
	Dim inputBoxes As List
	inputBoxes.Initialize
	For Each box As Map In boxes
		Dim boxGeometry As Map = box.Get("geometry")
		Dim X,Y,width,height As Int
		X=boxGeometry.Get("X")
		Y=boxGeometry.Get("Y")
		width=boxGeometry.Get("width")

		height=boxGeometry.Get("height")
		Dim inputBox As List
		inputBox.Initialize
		inputBox.Add(X)
		inputBox.Add(Y)
		inputBox.Add(X+width)
		inputBox.Add(Y+height)
		inputBoxes.Add(inputBox)
	Next
	Dim jsonG As JSONGenerator
	jsonG.Initialize2(inputBoxes)
	Dim out As OutputStream
	out=File.OpenOutput(File.DirApp,"image.jpg",False)
	img.WriteToStream(out,"100","JPEG")
	out.Close
	Dim job As HttpJob
	job.Initialize("",Me)
	Dim fd As MultipartFileData
	fd.Initialize
	fd.KeyName = "upload"
	fd.Dir = File.DirApp
	fd.FileName = "image.jpg"
	fd.ContentType = "image/jpg"
	job.PostMultipart("http://127.0.0.1:8289/getmask",CreateMap("boxes":jsonG.ToString), Array(fd))
	job.GetRequest.Timeout=240*1000
	Wait For (job) JobDone(job As HttpJob)
	If job.Success Then
		Try
			Dim result As B4XBitmap=job.GetBitmap
			job.Release
			Return result
		Catch
			Log(LastException)
		End Try
	Else
		Log(job.ErrorMessage)
	End If
	job.Release
	Return emptyMask(img)
End Sub

Private Sub emptyMask(img As B4XBitmap) As B4XBitmap
	Dim bc As BitmapCreator
	bc.Initialize(img.Width,img.Height)
	Return bc.Bitmap
End Sub
