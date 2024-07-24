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
	Return "InsetRectMaskGen"
End Sub

' must be available
public Sub Run(Tag As String, Params As Map) As ResumableSub
	Log("run"&Params)
	Select Tag
		Case "getParams"
			Dim paramsList As List
			paramsList.Initialize
			paramsList.Add("pixels")
			Return paramsList
		Case "getDefaultParamValues"
			Return CreateMap("pixels":"5")
		Case "genMask"
			Dim pixels As Int = 5
			Try
				Dim settings As Map = Params.Get("settings")
				pixels = settings.Get("pixels")
			Catch
				Log(LastException)
			End Try
			wait for (genMask(Params.Get("img"),pixels)) complete (result As B4XBitmap)
			Return result
		Case "byTextArea"
			Return True
	End Select
	Return ""
End Sub

Sub genMask(img As B4XBitmap,pixels As Int) As ResumableSub
	Dim bc As BitmapCreator
	bc.Initialize(img.Width,img.Height)
	Try
		Dim r As B4XRect
		r.Initialize(pixels, pixels, img.Width - pixels, img.Height - pixels)
		Dim xui As XUI
		bc.DrawRect(r,xui.Color_Red,True,0)
	Catch
		Log(LastException)
		Dim r As B4XRect
		r.Initialize(0, 0, img.Width, img.Height)
		Dim xui As XUI
		bc.DrawRect(r,xui.Color_Red,True,0)
	End Try
	Return bc.Bitmap
End Sub
