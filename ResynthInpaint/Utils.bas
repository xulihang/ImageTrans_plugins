B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=StaticCode
Version=10
@EndOfDesignText@
'Static code module
Sub Process_Globals
	Private fx As JFX
End Sub

'返回用于 shell 调用 java 的可执行文件路径，各平台优先使用自带运行时
Public Sub GetJavaPath As String
	Dim javaPath As String = "java"
	Dim localJavaPath As String = File.Combine(File.DirApp,"jdk-23/Contents/Home/bin/java")
	Dim localJavaPathWindows As String = File.Combine(File.DirApp,"jre/bin/java.exe")
	Dim localJavaPathLinux As String = File.Combine(File.DirApp,"jre/bin/java")
	If DetectOS == "mac" And File.Exists(localJavaPath,"") Then
		javaPath = localJavaPath
	End If
	If DetectOS == "windows" And File.Exists(localJavaPathWindows,"") Then
		javaPath = localJavaPathWindows
	End If
	If DetectOS == "linux" And File.Exists(localJavaPathLinux,"") Then
		javaPath = localJavaPathLinux
	End If
	Return javaPath
End Sub

'windows, mac or linux
Sub DetectOS As String
	Dim os As String = GetSystemProperty("os.name", "").ToLowerCase
	If os.Contains("win") Then
		Return "windows"
	Else If os.Contains("mac") Then
		Return "mac"
	Else
		Return "linux"
	End If
End Sub