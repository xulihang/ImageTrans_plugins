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



Sub BubbleSort(boxesList As List,Xweight As Double,Yweight As Double) As List
	For j=0 To boxesList.Size-1
		For i = 1 To boxesList.Size - 1
			If  NextIsLower(boxesList.Get(i),boxesList.Get(i-1),Xweight,Yweight) Then
				boxesList=Swap(boxesList,i, i-1)
			End If
		Next
	Next
	Return boxesList
End Sub

Sub Swap(boxesList As List,index1 As Int, index2 As Int) As List
	Dim temp As Map
	temp = boxesList.Get(index1)
	boxesList.Set(index1,boxesList.Get(index2))
	boxesList.Set(index2,temp)
	Return boxesList
End Sub

Sub NextIsLower(box1 As Map, box2 As Map, Xweight As Double, Yweight As Double) As Boolean
	'XY1 is the next
	Dim boxGeometry1 As Map
	boxGeometry1=box1.Get("geometry")
	Dim X1,Y1 As Int
	X1=boxGeometry1.Get("X")
	Y1=boxGeometry1.Get("Y")

	Dim boxGeometry2 As Map
	boxGeometry2=box2.Get("geometry")
	Dim X2,Y2 As Int
	X2=boxGeometry2.Get("X")
	Y2=boxGeometry2.Get("Y")

	Dim diagonal1,diagonal2 As Int
	diagonal1=Xweight*Xweight*X1*X1+Yweight*Yweight*Y1*Y1
	diagonal2=Xweight*Xweight*X2*X2+Yweight*Yweight*Y2*Y2
	If diagonal1<=diagonal2 Then
		Return True
	Else
		Return False
	End If
End Sub
 
Sub BubbleSortBasedOnX(boxesList As List,right2left As Boolean) As List
	For j=0 To boxesList.Size-1
		For i = 1 To boxesList.Size - 1
			If right2left Then
				If NextHasBiggerX(boxesList.Get(i),boxesList.Get(i-1)) Then
					boxesList=Swap(boxesList,i, i-1)
				End If
			Else
				If NextHasSmallerX(boxesList.Get(i),boxesList.Get(i-1)) Then
					boxesList=Swap(boxesList,i, i-1)
				End If
			End If
		Next
	Next
	Return boxesList
End Sub
 
Sub NextHasSmallerX(box1 As Map, box2 As Map) As Boolean
	'XY1 is the next
	Dim boxGeometry1 As Map
	boxGeometry1=box1.Get("geometry")
	Dim X1 As Int
	X1=boxGeometry1.Get("X")
	Dim boxGeometry2 As Map
	boxGeometry2=box2.Get("geometry")
	Dim X2 As Int
	X2=boxGeometry2.Get("X")
	If X1<X2 Then
		Return True
	Else
		Return False
	End If
End Sub

Sub NextHasBiggerX(box1 As Map, box2 As Map) As Boolean
	'XY1 is the next
	Dim boxGeometry1 As Map
	boxGeometry1=box1.Get("geometry")
	Dim X1 As Int
	X1=boxGeometry1.Get("X")
	Dim boxGeometry2 As Map
	boxGeometry2=box2.Get("geometry")
	Dim X2 As Int
	X2=boxGeometry2.Get("X")
	If X1>X2 Then
		Return True
	Else
		Return False
	End If
End Sub