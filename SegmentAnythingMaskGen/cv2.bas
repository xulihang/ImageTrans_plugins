B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=StaticCode
Version=7.8
@EndOfDesignText@
'Static code module
Sub Process_Globals
	Private fx As JFX
	Private Imgproc As JavaObject
	Private Imgcodecs As JavaObject
	Private Core As JavaObject
	Private matStatic As JavaObject
	Private Photo As JavaObject
	Private th As Thread
End Sub

Public Sub Initialize
	Imgproc.InitializeStatic("org.opencv.imgproc.Imgproc")
	Imgcodecs.InitializeStatic("org.opencv.imgcodecs.Imgcodecs")
	Core.InitializeStatic("org.opencv.core.Core")
	matStatic.InitializeStatic("org.opencv.core.Mat")
	Photo.InitializeStatic("org.opencv.photo.Photo")
	th.Initialise("th")
End Sub

Sub NATIVE_LIBRARY_NAME As String
	Return Core.GetField("NATIVE_LIBRARY_NAME")
End Sub

Sub MatOfRect As JavaObject
	Dim jo As JavaObject
	jo.InitializeNewInstance("org.opencv.core.MatOfRect",Null)
	Return jo
End Sub

Sub mserDetectRegions(image As cvMat, msers As List, bboxes As JavaObject)
	Dim mserStatic As JavaObject
	mserStatic.InitializeStatic("org.opencv.features2d.MSER")
	Dim mser As JavaObject
	mser=mserStatic.RunMethodJO("create",Null)
	mser.RunMethod("detectRegions",Array(image.JO,msers,bboxes))
End Sub

Public Sub absdiff(src1 As cvMat, src2 As cvMat, dst As cvMat)
	Core.RunMethod("absdiff",Array(src1.JO,src2.JO,dst.JO))
End Sub

Sub add(src1 As cvMat,src2 As cvMat,dst As cvMat)
	Core.RunMethod("add",Array(src1.JO,src2.JO,dst.JO))
End Sub

public Sub addWeighted(src1 As cvMat,alpha As Double,src2 As cvMat,beta As Double,gamma As Double,dst As cvMat)
	Core.RunMethod("addWeighted",Array(src1.JO,alpha,src2.JO,beta,gamma,dst.JO))
End Sub

Sub inpaint(src As cvMat, inpaintMask As cvMat, dst As cvMat, inpaintRadius As Double, flags As Int)
	Photo.RunMethod("inpaint",Array(src.JO,inpaintMask.JO,dst.JO,inpaintRadius,flags))
End Sub

Sub inpaint2(map1 As Map)
	Dim src As cvMat=map1.get("src")
	Dim inpaintMask As cvMat=map1.get("inpaintMask")
	Dim dst As cvMat=map1.get("dst")
	Dim inpaintRadius As Double=map1.get("inpaintRadius")
	Dim flags As Int=map1.get("flags")
	Photo.RunMethod("inpaint",Array(src.JO,inpaintMask.JO,dst.JO,inpaintRadius,flags))
End Sub

Public Sub inpaintAsync(src As cvMat, inpaintMask As cvMat, dst As cvMat, inpaintRadius As Double, flags As Int) As ResumableSub
	Dim map1 As Map
	map1.Initialize
	map1.Put("src",src)
	map1.Put("inpaintMask",inpaintMask)
	map1.Put("dst",dst)
	map1.Put("inpaintRadius",inpaintRadius)
	map1.Put("flags",flags)
	th.Start(Me,"inpaint2",Array As Map(map1))
	wait for th_Ended(endedOK As Boolean, error As String)
	Log(endedOK)
	Log(error)
	Return endedOK
End Sub

Sub split(src As cvMat,mats As List)
	Core.RunMethod("split",Array(src.JO,mats))
End Sub

Sub merge(mats As List,dst As cvMat)
	Core.RunMethod("merge",Array(mats,dst.JO))
End Sub

Sub bytesToMat(bytes() As Byte) As cvMat
	Dim matOfByte As JavaObject
	matOfByte.InitializeNewInstance("org.opencv.core.MatOfByte",Array(bytes))
	Return matJO2mat(Imgcodecs.RunMethodJO("imdecode",Array(matOfByte, codecsEnum("IMREAD_COLOR"))))
End Sub

Sub bytesToMat2(bytes() As Byte,mode As String) As cvMat
	Dim matOfByte As JavaObject
	matOfByte.InitializeNewInstance("org.opencv.core.MatOfByte",Array(bytes))
	Return matJO2mat(Imgcodecs.RunMethodJO("imdecode",Array(matOfByte, codecsEnum(mode))))
End Sub

Public Sub matZeros(params() As Object) As cvMat
	Return matJO2mat(matStatic.RunMethodJO("zeros",params))
End Sub

Public Sub Canny(img As cvMat,edges As cvMat,threshold1 As Double,threshold2 As Double)
	Imgproc.RunMethod("Canny",Array(img.JO,edges.JO,threshold1,threshold2))
End Sub

Public Sub drawContours(img As cvMat,contours As List,index As Int,color As Object,thickness As Int)
	Imgproc.RunMethod("drawContours",Array(img.Jo, contours, index, color, thickness))
End Sub

Public Sub findContours(img As cvMat,contours As List,hierarchy As cvMat,mode As Int,method As Int)
	Imgproc.RunMethod("findContours",Array(img.JO,contours,hierarchy.JO,mode,method))
End Sub

Public Sub arcLength(curve As JavaObject, closed As Boolean) As Double
	Return Imgproc.RunMethod("arcLength",Array(curve,closed))
End Sub

Public Sub approxPolyDP(curve As JavaObject, approxCurve As JavaObject, epsilon As Double, closed As Boolean)
	Imgproc.RunMethod("approxPolyDP",Array(curve,approxCurve,epsilon,closed))
End Sub

public Sub boundingRect(mat As cvMat) As JavaObject
	Return Imgproc.RunMethod("boundingRect",Array(mat.JO))
End Sub

Public Sub bitwise_not(src As cvMat, dst As cvMat)
	Core.RunMethod("bitwise_not",Array(src.JO,dst.JO))
End Sub

Public Sub reduce(src As cvMat,dst As cvMat,dimension As Int,rtype As Int,dtype As Int)
	Core.RunMethod("reduce",Array(src.JO,dst.JO,dimension,rtype,dtype))
End Sub

Public Sub imread(path As String) As cvMat
	Return matJO2mat(Imgcodecs.RunMethodJO("imread",Array(path)))
End Sub

Public Sub imwrite(path As String,img As cvMat)
	Imgcodecs.RunMethod("imwrite",Array(path,img.JO))
End Sub

Public Sub medianBlur(src As cvMat,dst As cvMat, ksize As Int)
	Imgproc.RunMethodJO("medianBlur",Array(src.JO,dst.JO,ksize))
End Sub

Public Sub gaussianBlur(src As cvMat,dst As cvMat, ksize As JavaObject, sigmaX As Double, sigmaY As Double)
	Imgproc.RunMethodJO("GaussianBlur",Array(src.JO,dst.JO,ksize,sigmaX,sigmaY))
End Sub

Public Sub threshold(src As cvMat,dst As cvMat,thresh As Double,maxVal As Double,threshType As Int) As Double
	Return Imgproc.RunMethod("threshold",Array(src.JO,dst.JO,thresh,maxVal,threshType))
End Sub

Public Sub copyMakeBorder(src As cvMat, dst As cvMat, top As Int, bottom As Int, left As Int, right As Int, borderType As Int, color As Object)
	Core.RunMethod("copyMakeBorder",Array(src.JO, dst.JO, top, bottom, left, right, borderType, color))
End Sub

Public Sub connectedComponentsWithStats(image As cvMat,labels As cvMat,stats As cvMat,centroids As cvMat) As Int
	Return Imgproc.RunMethod("connectedComponentsWithStats",Array(image.JO,labels.JO,stats.JO,centroids.JO))
End Sub

Public Sub cvtColor(src As cvMat,dst As cvMat,mode As Object)
	Dim modeInt As Int=0
	If GetType(mode)="java.lang.String" Then
		modeInt=procEnum(mode)
	Else if GetType(mode)="java.lang.Integer" Then
		modeInt=mode
	End If
	Imgproc.RunMethodJO("cvtColor",Array(src.JO,dst.JO,modeInt))
End Sub

'mode example: COLOR_BGR2GRAY 
Public Sub procEnum(mode As String) As Int
	Return Imgproc.GetField(mode)
End Sub

Public Sub coreEnum(str As String) As Int
	Return Core.GetField(str)
End Sub

Public Sub PhotoEnum(str As String) As Int
	Return Photo.GetField(str)
End Sub

Public Sub codecsEnum(mode As String) As Int
	Return Imgcodecs.GetField(mode)
End Sub

Public Sub cvType(typeStr As String) As Int
	Dim cvt As JavaObject
	cvt.InitializeStatic("org.opencv.core.CvType")
	Return cvt.GetField(typeStr)
End Sub

Public Sub rectangle(img As cvMat, rec As Object, color As Object, thickness As Int, lineType As Int)
	Imgproc.RunMethod("rectangle",Array(img.JO, rec,color,thickness, lineType))
End Sub

Public Sub rect(x As Int,y As Int,width As Int,height As Int) As JavaObject
	Dim rec As JavaObject
	rec.InitializeNewInstance("org.opencv.core.Rect",Array(x,y,width,height))
	Return rec
End Sub

Public Sub point(x As Double,y As Double) As JavaObject
	Dim p As JavaObject
	p.InitializeNewInstance("org.opencv.core.Point",Array(x,y))
	Return p
End Sub

Public Sub mat2fFromPointsList(points As List) As JavaObject
	Dim mat2f As JavaObject
	mat2f.InitializeNewInstance("org.opencv.core.MatOfPoint2f",Null)
	mat2f.RunMethod("fromList",Array(points))
	Return mat2f
End Sub

Public Sub getPerspectiveTransform(m1 As JavaObject,m2 As JavaObject) As JavaObject
	Return Imgproc.RunMethod("getPerspectiveTransform",Array(m1,m2))
End Sub

Public Sub warpPerspective(src As cvMat,dst As cvMat,matrix As JavaObject,dsize As JavaObject)
	Imgproc.RunMethod("warpPerspective",Array(src.JO, dst.JO, matrix, dsize))
End Sub

Public Sub Scalar(b As Double,g As Double,r As Double) As JavaObject
	Dim sca As JavaObject
	sca.InitializeNewInstance("org.opencv.core.Scalar",Array(b,g,r))
	Return sca
End Sub

Public Sub Scalar2(r As Double,g As Double,b As Double,a As Double) As JavaObject
	Dim sca As JavaObject
	sca.InitializeNewInstance("org.opencv.core.Scalar",Array(r,g,b,a))
	Return sca
End Sub

Public Sub copyTo(src As cvMat,dst As cvMat,mask As cvMat)
	Core.RunMethod("copyTo",Array(src.JO,dst.JO,mask.JO))
End Sub

Public Sub imencode(fileExtension As String,MatJO As JavaObject,MatOfByte As JavaObject)
	'Log(fileExtension)
	Imgcodecs.RunMethod("imencode",Array(fileExtension, MatJO, MatOfByte))
End Sub

Public Sub erode(src As cvMat,dst As cvMat,kernel As cvMat)
	Imgproc.RunMethod("erode",Array(src.Jo,dst.Jo,kernel.Jo))
End Sub

Public Sub dilate(src As cvMat,dst As cvMat,kernel As cvMat)
	Imgproc.RunMethod("dilate",Array(src.Jo,dst.Jo,kernel.Jo))
End Sub

'MORPH_RECT
Public Sub getStructuringElement(shape As String,width As Double,height As Double) As cvMat
	Return matJO2mat(Imgproc.RunMethodJO("getStructuringElement",Array(procEnum(shape),size(width,height))))
End Sub

Sub resize(src As cvMat,dst As cvMat,dsize As JavaObject)
	Imgproc.RunMethod("resize",Array(src.JO,dst.JO,dsize))
End Sub

Public Sub size(width As Double,height As Double) As JavaObject
	Dim s As JavaObject
	s.InitializeNewInstance("org.opencv.core.Size",Array(width,height))
	Return s
End Sub

Sub matJO2mat(jo As JavaObject) As cvMat
	Dim mat As cvMat
	mat.Initialize(Null)
	mat.JO=jo
	Return mat
End Sub

Public Sub hconcat(matList As List,dst As cvMat)
	Dim newList As List
	newList.Initialize
	For Each mat As cvMat In matList
		newList.Add(mat.JO)
	Next
	Core.RunMethod("hconcat",Array(newList,dst.JO))
End Sub

Public Sub vconcat(matList As List,dst As cvMat)
	Dim newList As List
	newList.Initialize
	For Each mat As cvMat In matList
		newList.Add(mat.JO)
	Next
	Core.RunMethod("vconcat",Array(newList,dst.JO))
End Sub

Public Sub contourArea(mat As cvMat) As Double
	Return Imgproc.RunMethod("contourArea",Array(mat.JO))
End Sub

Public Sub createBackgroundSubtractorMOG2() As JavaObject
	Dim video As JavaObject
	video.InitializeStatic("org.opencv.video.Video")
	Return video.RunMethod("createBackgroundSubtractorMOG2",Null)
End Sub

public Sub MatOfPointAsMatOfPoint2F(matOfPoint As JavaObject) As JavaObject
	Dim points As List = matOfPoint.RunMethod("toList",Null)
	Return mat2fFromPointsList(points)
End Sub

Public Sub minAreaRect(points As Object) As JavaObject
	Return Imgproc.RunMethod("minAreaRect",Array(points))
End Sub
