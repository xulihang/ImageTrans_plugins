B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=StaticCode
Version=7.8
@EndOfDesignText@
'Static code module
Sub Process_Globals
	Private fx As JFX
End Sub


Sub OverlappingPercent(boxGeometry1 As Map,boxGeometry2 As Map) As Double
	'Log("boxGeometry1"&boxGeometry1)
	'Log("boxGeometry2"&boxGeometry2)
	Dim X1,Y1,W1,H1 As Int
	X1=boxGeometry1.Get("X")
	Y1=boxGeometry1.Get("Y")
	W1=boxGeometry1.Get("width")
	H1=boxGeometry1.Get("height")
	Dim X2,Y2,W2,H2 As Int
	X2=boxGeometry2.Get("X")
	Y2=boxGeometry2.Get("Y")
	W2=boxGeometry2.Get("width")
	H2=boxGeometry2.Get("height")
	Dim theSmallerX,theBiggerX,theSmallerXWidth,theBiggerXWidth As Int
	If theSmallerOneIndex(X1,X2)=0 Then
		theSmallerX=X1
		theBiggerX=X2
		theSmallerXWidth=W1
		theBiggerXWidth=W2
	Else
		theSmallerX=X2
		theBiggerX=X1
		theSmallerXWidth=W2
		theBiggerXWidth=W1
	End If
	Dim theSmallerY,theBiggerY,theSmallerYHeight,theBiggerYHeight As Int
	If theSmallerOneIndex(Y1,Y2)=0 Then
		theSmallerY=Y1
		theBiggerY=Y2
		theSmallerYHeight=H1
		theBiggerYHeight=H2
	Else
		theSmallerY=Y2
		theBiggerY=Y1
		theSmallerYHeight=H2
		theBiggerYHeight=H1
	End If

	If theSmallerX+theSmallerXWidth>=theBiggerX And theSmallerY+theSmallerYHeight>=theBiggerY Then
		'overlapping
		Dim overlappingArea As Double = (theSmallerOne(X1+W1,X2+W2)-theBiggerX)*(theSmallerOne(Y1+H1,Y2+H2)-theBiggerY)
		Dim area1,area2 As Double
		area1=W1*H1
		area2=W2*H2
		Dim theSmallArea As Int=theSmallerOne(area1,area2)
		'Log("overlappingArea:"&overlappingArea)
		'Log("theSmallArea:"&theSmallArea)
		'Log("overlapping percent:")
		'Log(overlappingArea/theSmallArea)
		Return overlappingArea/theSmallArea
	Else
		Return 0
	End If
End Sub

Sub theSmallerOneIndex(X1 As Int,X2 As Int) As Int
	If X1<X2 Then
		Return 0
	Else
		Return 1
	End If
End Sub

Sub theSmallerOne(X1 As Int,X2 As Int) As Int
	If X1<X2 Then
		Return X1
	Else
		Return X2
	End If
End Sub