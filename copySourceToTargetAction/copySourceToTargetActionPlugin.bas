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
	Return "copySourceToTargetAction"
End Sub

' must be available
public Sub Run(Tag As String, Params As Map) As ResumableSub
	Select Tag
		Case "process"
          Process(Params.Get("sourceTextArea"),Params.Get("targetTextArea"))			
	End Select
	Return ""
End Sub

private Sub Process(sourceTextArea As TextArea,targetTextArea As TextArea)
	targetTextArea.Text = targetTextArea.Text & CRLF & CRLF & sourceTextArea.Text
End Sub