; ID: 1585
; Author: Perturbatio
; Date: 2005-12-29 06:25:48
; Title: IntList
; Description: a hack of my StringList that allows you to maintain a list of Ints

SuperStrict

Framework BRL.Retro
Import BRL.System

Rem
Intlist created by Kris Kelly (Perturbatio) Dec 2005
purpose: faster access to a list of Ints with less mem usage
it's performance is comparable to a TList when using a small number of Ints
but when you are using a large amount, it is much better (and uses less memory).

When invoking the create method, you can specify the StepSize, this is the amount that
the Items Array will be increased by each time it is in danger of running out of space.
It is faster to do it in large blocks than in hundreds of little ones.
End Rem

Type TIntList
	Field Items:Int[]
	Field _Size:Int = 0 'DO NOT MANUALLY MODIFY THIS!!!
	Field StepSize:Int
	
	Method AddFirst(val:Int)
		Local i:Int

		'grow Items array by 1
		'Items = Items[..Items.Length + 1]
		_Size:+1
		'resize in bulk
		If Items.Length < _Size Then Items = Items[.._Size+StepSize]
		
		
		'shift Items to the rightt, overwriting val
		For i = 1 To _Size-1 'Items.Length - 1
			Items[i] = Items[i - 1]
		Next
		
		Items[0] = val
		'no need to return anything here since we know it was added at 0
	End Method
	
	
	Method AddLast:Int(val:Int)
		'grow Items array by 1
		'Items = Items[..Items.Length + 1]
		_Size:+1
		'resize in bulk
		If Items.Length < _Size Then Items = Items[.._Size+StepSize]
		
		'set the last index to val
		'Items[Items.Length - 1] = val

		Items[_Size-1] = val
		
		Return _Size 'Items.Length - 1 'return the index it was added at
	End Method
	
	
	'return the entire list as a concatenated Int with optional delimiter
	'because base objects have ToInt, cannot override with different parameters
	Method ToDelimString:String(Delim:String = "")
		Local result:String
		Local i:Int
		
		For i = 0 To _Size-2
			result:+Items[i] + Delim
		Next
		result:+ Items[_Size-1]
		
		Return result
	End Method
	
	
	Method ToString:String()
		Return ToDelimString() 'just call ToDelimString with no parameters
	End Method
	
	'You could just reference the field _Size (which is what is done throughout the code), 
	'but that could result in an unsafe type if you 
	Method Count:Int()
		Return _Size
	End Method
	
	
	'return the first index where the list contains val, else return -1
	Method Contains:Int(val:Int)
		Local i:Int
		
		For i = 0 To _Size-1
			If val = Items[i] Then Return i	
		Next
		
		Return -1
	End Method
	
	
	Function FromIntArray:TIntList(val:Int[])
		Local tempList:TIntList = TIntList.Create()
		
		Try
			tempList.Items = val
		Catch err:String
			RuntimeError("Error when converting from Int Array to TIntList, error: ~n"+err$)
			Return Null
		End Try
		
		Return tempList
	End Function
	
	
	Function FromString:TIntList(val:String, Delim:String)
		Local tempList:TIntList = TIntList.Create()
		Local currentChar : String = ""
		Local count : Int = 0
		Local TokenStart : Int = 0
			If Delim.Length <0 Or Delim.Length > 1 Then Return Null
	
			If Len(Delim)<>1 Then Return Null
	
			val = Trim(val)
	
			For count = 0 Until Len(val)
				If val[count..count+1] = delim Then
					tempList.AddLast(Int(val[TokenStart..Count]))
					TokenStart = count + 1
				End If
			Next
			tempList.AddLast(Int(val[TokenStart..Count]))
			
		Return tempList
	End Function


	'if AutoAddToEnd is true then if the index specified is greater than size, use AddLast
	Method Insert:Int(val:Int, index:Int, AutoAddToEnd:Int = False)
		Local i:Int
		
		'If index is out of range, Return False
		If index < 0 Then Return False
		If index > _Size Then
			If Not AutoAddToEnd Then 
				Return False
			Else
				AddLast(val)
				Return True
			EndIf
		EndIf
		
		'if the index is equal to Size then addlast
		If index = _Size Then 
			AddLast(val)
			Return True
		EndIf

		'resize Items
		'Items = Items[..Items.Length]
		_Size:+1
		'resize in bulk
		If Items.Length < _Size Then Items = Items[.._Size + StepSize]

		
		'shift Items to the right from index
		For i = _Size-1 To index+1 Step -1
			Items[i] = Items[i - 1]
			'Print "index "+ i + " " + items[i]
		Next
		
		'then insert val
		Items[index] = val
		Return True
	End Method
	
	
	Method RemoveByIndex:Int(index:Int)
		Local i:Int

		'shift Items to the left, overwriting index
		For i = index To _Size - 2
			Items[i] = Items[i + 1]
		Next
		
		'shrink Items by 1
		'Items = Items[..Items.Length]
		_Size:-1
		'if the length of items is at least (2 *StepSize) larger than Size, resize the array
		'this should help prevent the size from getting out of control but keep it reasonably fast
		If _Size < Items.Length - (StepSize * 2) Then Items = Items[.._Size]
		If _Size < 0 Then _Size = 0
		'null the end one
		Items[_Size] = Null
	End Method
	
	
	Method RemoveByVal:Int(val:Int, RemoveAll:Int = False)
		Local i:Int

		i = Contains(val)
		While i > -1
			
			RemoveByIndex(i)
			If Not RemoveAll Then Return True
			i = Contains(val)

		Wend
		
		Return True
	End Method
	
	
	Method Clear()
		Items = Items[..0]
		_Size = 0
	End Method

	
	Method ToArray:Int[]()
		Return Items
	End Method
	
	
	Method ToList(List:TList Var)
		For Local s:Int = EachIn items
			List.AddLast(String(s))
		Next
	End Method
	
	
	Method GetStepSize:Int()
		Return StepSize
	End Method
	
	Method SetStepSize(val:Int)
		If val < 1 Then val = 1 'don't allow negative values
		StepSize = val
	End Method
	
	
	Method Sort()
		Items.Sort()
	End Method
	
	
	Method Free()
		TIntList.Destroy(Self)
	End Method
	
	
	Method SaveToFile(filename:String)
		Local fs:TStream = WriteFile(filename)
		Local i:Int
		
		For i=0 To _Size-1
			WriteLine(fs, Items[i])
		Next
		CloseFile(fs)
	End Method
	
	
	Method LoadFromFile(filename:String)
		Local fs:TStream = OpenFile(filename)
		If Not fs Then Return
		Clear()
		
		While Not Eof(fs)
			AddLast(Int(ReadLine(fs)))
		Wend
		
		CloseFile(fs)
	End Method
	
	
	Function Destroy(sl:TIntList)
		sl.Clear()
		sl = Null
		GCCollect
	End Function
	
	
	Function Create:TIntList(StepSize:Int = 10)
		Local tempList:TIntList = New TIntList
		tempList.StepSize = StepSize
		Return tempList
	End Function
End Type

Rem test Insert
Global sl:TIntList = TIntList.Create(10)

sl.AddLast("A")
sl.AddLast("B")
sl.AddLast("D")
sl.AddLast("f")
Print sl.ToInt()
sl.Insert("C", 2)
Print sl.ToInt()
sl.Insert("E", 4)
Print sl.ToInt()

'sl.RemoveByIndex(2)

For Local s:Int = EachIn sl.Items
	If s<>Null Then Print s
Next

sl.AddLast("f")
sl.AddLast("f")
sl.AddLast("f")
sl.AddLast("F")
sl.RemoveByInt("f", True, True)
Print sl.ToDelimInt("-")

End Rem


'Rem test speed
SeedRnd MilliSecs()

Global numberOfIterations:Int = 9999 'increase this to see the performance difference


'Test a TIntList
Print "~nTIntList:~n"
Global sl:TIntList = TIntList.Create(1000) 'change this to a 1 and see the performance change


Local starttime:Int = MilliSecs()

For Local i:Int = 0 To numberOfIterations
	sl.AddLast(Rand(65,90))
Next

sl.Sort()

Print MilliSecs()-Starttime + "ms"
GCCollect()
Print (GCMemAlloced()/1024)+"kb used"


sl.Free()
Print (GCMemAlloced()/1024)+"kb after free"


'test a TList
Print "~nTList:~n"
Global sl2:TList = New TList


starttime:Int = MilliSecs()

For Local i:Int = 0 To numberOfIterations
	sl2.AddLast(String(Rand(65,90)))
Next

sl2.Sort()


Print MilliSecs()-Starttime + "ms"
GCCollect()
Print (GCMemAlloced()/1024)+"kb used"
sl2 = Null
GCCollect()
Print (GCMemAlloced()/1024)+"kb after free"
