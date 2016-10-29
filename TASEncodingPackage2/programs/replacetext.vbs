'ReplaceText.vbs

Option Explicit

Const ForAppending = 8
Const TristateFalse = 0 ' the value for ASCII
Const TempFilename = ".\Temp.txt"
Const Overwrite = True

Dim FileSystem
Dim Filename, OldText, NewText
Dim OriginalFile, TempFile, Line

If WScript.Arguments.Count = 3 Then
    Filename = WScript.Arguments.Item(0)
    OldText = WScript.Arguments.Item(1)
    NewText = WScript.Arguments.Item(2)
Else
    Wscript.Echo "Usage: ReplaceText.vbs <Filename> <OldText> <NewText>"
    Wscript.Quit
End If

Set FileSystem = CreateObject("Scripting.FileSystemObject")

If FileSystem.FileExists(TempFilename) Then
    FileSystem.DeleteFile TempFilename
End If

Set TempFile = FileSystem.CreateTextFile(TempFilename, Overwrite, TristateFalse)
Set OriginalFile = FileSystem.OpenTextFile(Filename)

Do Until OriginalFile.AtEndOfStream
    Line = OriginalFile.ReadLine

    If InStr(Line, OldText) > 0 Then
        Line = Replace(Line, OldText, NewText)
    End If 

    TempFile.WriteLine(Line)
Loop

OriginalFile.Close
TempFile.Close

FileSystem.DeleteFile Filename
FileSystem.MoveFile TempFilename, Filename

Wscript.Quit
