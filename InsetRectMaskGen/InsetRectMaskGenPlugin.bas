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
			wait for (genMask(Params.Get("img"),Params.Get("box"),pixels)) complete (result As B4XBitmap)
			Return result
		Case "byTextArea"
			Return True
	End Select
	Return ""
End Sub

Sub genMask(img As B4XBitmap,box As Map,pixels As Int) As ResumableSub
	Dim bc As BitmapCreator
	bc.Initialize(img.Width,img.Height)
	Dim degree As Int = box.GetDefault("degree",0)
	Try
		If degree <> 0 Then
			Dim boxGeometry As Map = box.Get("geometry")
			Dim newGeometry As Map
			newGeometry.Initialize
			newGeometry.Put("X",boxGeometry.Get("X") + pixels)
			newGeometry.Put("Y",boxGeometry.Get("Y") + pixels)
			newGeometry.Put("width",boxGeometry.Get("width") - pixels)
			newGeometry.Put("height",boxGeometry.Get("height") - pixels)
			Dim imageWidth As Int = box.Get("imageWidth")
			Dim imageHeight As Int = box.Get("imageHeight")
			Dim roiX As Int = box.Get("roiX")
			Dim roiY As Int = box.Get("roiY")
            Dim roi As BitmapCreator
			roi.Initialize(imageWidth,imageHeight)
			Dim Point1(2),Point2(2),Point3(2),Point4(2) As Int
			Dim Points As List = getRotatedPoints(degree,newGeometry)
			Point1 = Points.Get(0)
			Point2 = Points.Get(1)
			Point3 = Points.Get(2)
			Point4 = Points.Get(3)
			Dim path As BCPath
			path.Initialize(Point1(0),Point1(1))
			path.LineTo(Point2(0),Point2(1))
			path.LineTo(Point3(0),Point3(1))
			path.LineTo(Point4(0),Point4(1))
			path.LineTo(Point1(0),Point1(1))
			Dim xui As XUI
			roi.DrawPath(path,xui.Color_Red,True,0)
			Dim cropped As B4XBitmap = roi.Bitmap.Crop(roiX,roiY,img.Width,img.Height)
			Dim r As B4XRect
			r.Initialize(0, 0, img.Width, img.Height)
			bc.DrawBitmap(cropped,r,True)
		Else
			Dim r As B4XRect
			r.Initialize(pixels, pixels, img.Width - pixels, img.Height - pixels)
			Dim xui As XUI
			bc.DrawRect(r,xui.Color_Red,True,0)
		End If
	Catch
		Log(LastException)
		Dim r As B4XRect
		r.Initialize(0, 0, img.Width, img.Height)
		Dim xui As XUI
		bc.DrawRect(r,xui.Color_Red,True,0)
	End Try
	Return bc.Bitmap
End Sub

public Sub getRotatedPoints(degree As Double,boxGeometry As Map) As List
	Dim X,Y,width,height As Int
	X=boxGeometry.Get("X")
	Y=boxGeometry.Get("Y")
	width=boxGeometry.Get("width")
	height=boxGeometry.Get("height")
	Dim centerX,centerY As Int
	centerX=X+width/2
	centerY=Y+height/2
	Dim Point1(2),Point2(2),Point3(2),Point4(2) As Int
	Point1=CalculateRotatedPosition(degree,centerX,centerY,X,Y)
	Point2=CalculateRotatedPosition(degree,centerX,centerY,X+width,Y)
	Point3=CalculateRotatedPosition(degree,centerX,centerY,X+width,Y+height)
	Point4=CalculateRotatedPosition(degree,centerX,centerY,X,Y+height)
	Return Array(Point1,Point2,Point3,Point4)
End Sub

Sub CalculateRotatedPosition(degree As Double,pivotx As Double,pivoty As Double,x As Double,y As Double) As Int()
	Dim rotate As JavaObject
	rotate.InitializeNewInstance("javafx.scene.transform.Rotate",Array(degree,pivotx,pivoty))
	Dim point2dJO As JavaObject = rotate.RunMethod("transform",Array(x,y))
	Dim point(2) As Int
	point(0)=point2dJO.RunMethod("getX",Null)
	point(1)=point2dJO.RunMethod("getY",Null)
	Return point
End Sub
