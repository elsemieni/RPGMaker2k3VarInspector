#NoTrayIcon
#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Icon=icon.ico
#AutoIt3Wrapper_Outfile=build\rpgmaker2k3varinspector.Exe
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****
#cs ----------------------------------------------------------------------------

 AutoIt Version: 3.3.14.2
 Author:         Enzo Barbaguelatta - EN.I <marbleen.cl>

 Script Function:
	RPG Maker 2000/2003 Var Inspector

#ce ----------------------------------------------------------------------------

; Script Start - Add your code below here

#include <ButtonConstants.au3>
#include <GUIConstantsEx.au3>
#include <ListViewConstants.au3>
#include <StaticConstants.au3>
#include <WindowsConstants.au3>
#include <MsgBoxConstants.au3>
#include <FileConstants.au3>
#include <GuiListView.au3>
#include <GuiComboBox.au3>
#include <Array.au3>
#include "nomadmemory.au3"

;==========================================
Global $enabled
Global $pid
Global $mem
Global $base_pointer
Global $variable_array_pointer
Global $switch_array_pointer
Global $variable_first_pointer
Global $switch_first_pointer
Global $selected_maker

Local $hProcess
Local $out_data
Local $bytes_leidos

Global $itemListID[9999]
Global $itemListCat[9999]
Global $itemListVID[9999]
Global $itemListLabel[9999]
Global $itemListValue[9999]
Global $itemListI = 0

Global $halted = False

#Region ### START Koda GUI section ### Form=c:\users\elsem\rpg\2k3\testproject\var_inspector.kxf

Global  $Form1_1 = GUICreate("EN.I RPG Maker 2000/2003 Variable Inspector", 202, 666, 737, 15)
Global $Label1 = GUICtrlCreateLabel("Base Pointer: 0x00000000", 8, 528, 129, 17)
Global $Label2 = GUICtrlCreateLabel("Variables Pointer: 0x00000000", 8, 560, 148, 17)
Global $Label3 = GUICtrlCreateLabel("First Variable Pointer: 0x00000000", 8, 576, 165, 17)
Global $AttachButton = GUICtrlCreateButton("(Re)Attach RPG_RT", 8, 32, 185, 25)
Global $ListView1 = GUICtrlCreateListView("#|ID|Label|Value  ", 8, 88, 185, 377)
Global $Label4 = GUICtrlCreateLabel("Switches Pointer: 0x00000000", 8, 544, 148, 17)
Global $Label5 = GUICtrlCreateLabel("First Switch Pointer: 0x00000000", 8, 592, 159, 17)
Global $LoadButton = GUICtrlCreateButton("Load preset", 8, 56, 91, 25)
Global $SaveButton = GUICtrlCreateButton("Save preset", 104, 56, 89, 25)
Global $AddButton = GUICtrlCreateButton("Add", 8, 472, 89, 25)
Global $RemoveButton = GUICtrlCreateButton("Remove", 104, 472, 89, 25)
Global $HaltButton = GUICtrlCreateButton("Halt", 8, 496, 185, 25)
Global $Combo1 = GUICtrlCreateCombo("2003 >= 1.09a (or 2k3e/Maniacs)", 8, 8, 185, 25, BitOR($CBS_DROPDOWN, $CBS_DROPDOWNLIST, $CBS_AUTOHSCROLL))
GUICtrlSetData($Combo1, "2003 1.08 (or DynRPG)|2003 1.03|2000 1.61 (2ke)|2000 1.51 Value!|2000 1.07 (PRO)", "2003 >= 1.09a (or 2k3e/Maniacs)")
Global $Label7 = GUICtrlCreateLabel("EN.I's RPG Maker 2k/3 VarInspector", 8, 616, 180, 17)
Global $Label8 = GUICtrlCreateLabel("v1.0 Entidad2 - 2020 EN.I", 8, 632, 127, 17)
Global $Label9 = GUICtrlCreateLabel("https://marbleen.cl", 8, 648, 94, 17)

$selected_maker = GUICtrlRead($Combo1)
GUISetState(@SW_SHOW, $Form1_1)

#Region --- CodeWizard generated code Start ---
;MsgBox features: Title=Yes, Text=Yes, Buttons=OK, Icon=Info
MsgBox(64,"Information","How to use:" & @CRLF & @CRLF & "- Select your RPG_RT version in the upper selector." & @CRLF & "- Start your game, and set a variable and a switch." & @CRLF & "- Click Attach RPG_RT to bind the executable to the inspector." & @CRLF & "- Start adding variables to watch. " & @CRLF & @CRLF & "Have fun! :)")
#EndRegion --- CodeWizard generated code End ---


#EndRegion ### END Koda GUI section ###

While 1
	Sleep(50)
	rminspector_checkalive()
	rminspector_update_all()
	$nMsg = GUIGetMsg()
	Switch $nMsg
		Case $GUI_EVENT_CLOSE
			Exit
		Case $AttachButton
			rminspector_attach()
		Case $LoadButton
			rminspector_load()
		Case $SaveButton
			rminspector_save()
		Case $AddButton
			rminspector_addwindow()
		Case $RemoveButton
			rminspector_removebutton()
		Case $HaltButton
			rminspector_tooglehalt()
		Case $ListView1
			MsgBox($MB_SYSTEMMODAL, "listview", "clicked=" & GUICtrlGetState($ListView1), 2)
	EndSwitch
WEnd



Func rminspector_GetRPG_RT()
	$enabled = 0
	$pid = ProcessExists("RPG_RT.exe")
	if $pid = 0 Then
		MsgBox(16,"Error","RPG_RT process not found. Execute RPG_RT and then click (Re)attach.")
		Return -1
	EndIf

	$mem = _MemoryOpen($pid)
	if ($mem = 0) Then
		MsgBox(16,"Error","Error while accessing RPG_RT process.")
		Return -1
	EndIf

	Local $init_mem
	Switch $selected_maker
		Case "2003 >= 1.09a (or 2k3e/Maniacs)"
			$init_mem = 0x004D2008
		Case "2003 1.08 (or DynRPG)"
			$init_mem = 0x004D1FF8
		Case "2003 1.03"
			$init_mem = 0x004C9040
		Case "2000 1.61 (2ke)"
			$init_mem = 0x004A3B80
		Case "2000 1.51 Value!"
			$init_mem = 0x004A2B70
		Case "2000 1.07 (PRO)"
			$init_mem = 0x0049DBB8
		Case Else
			MsgBox(16,"Error","Invalid option selected")
			Return -1
	EndSwitch

	$out = _MemoryRead($init_mem, $mem)

	if ($out = 0 ) Then
		MsgBox(16,"Error","Error while reading RPG_RT data (" & @error& "). " & @CRLF & "Did you select your RPG_RT version correctly?")
		Return -1
	EndIf

	$base_pointer = $out
	$variable_array_pointer = $base_pointer + 0x28
	$switch_array_pointer = $base_pointer + 0x20

	$out = _MemoryRead($variable_array_pointer, $mem)
	if ($out = 0 ) Then
		MsgBox(16,"Error","Error while reading RPG_RT variable pointer data. (" & @error& "). " & @CRLF & "Remember start a game and set a switch&variable first!")
		Return -1
	EndIf
	$variable_first_pointer = $out

	$out = _MemoryRead($switch_array_pointer, $mem)
	if ($out = 0 ) Then
		MsgBox(16,"Error","Error while reading RPG_RT switch pointer data. (" & @error& "). " & @CRLF & "Remember start a game and set a switch&variable first!")
		Return -1
	EndIf
	$switch_first_pointer = $out


	$enabled = 1
	Return 0
EndFunc

Func rminspector_closeprocess()
	if $enabled > 0 Then
		_MemoryClose($mem)
	EndIf
	$enabled = 0
EndFunc

Func rminspector_attach()
	$enabled = 0
	$selected_maker = GUICtrlRead($Combo1)
	$out = rminspector_GetRPG_RT()
	if ($enabled = 1) Then
		GUICtrlSetData( $Label1, "Base Pointer: 0x" & Hex($base_pointer, 8))
		GUICtrlSetData( $Label2, "Variables Pointer: 0x" & Hex($variable_array_pointer, 8))
		GUICtrlSetData( $Label3, "First Variable Pointer: 0x" & Hex($variable_first_pointer, 8))
		GUICtrlSetData( $Label4, "Switches Pointer: 0x" & Hex($switch_array_pointer, 8))
		GUICtrlSetData( $Label5, "First Switch Pointer: 0x" & Hex($switch_first_pointer, 8))
	else
		GUICtrlSetData( $Label1, "Base Pointer: ???")
		GUICtrlSetData( $Label2, "Variables Pointer: ???")
		GUICtrlSetData( $Label3, "First Variable Pointer: ???")
		GUICtrlSetData( $Label4, "Switches Pointer: ???")
		GUICtrlSetData( $Label5, "First Switch Pointer: ???")
	EndIf

EndFunc

Func rminspector_load()
	$filepath = FileOpenDialog ( "Open preset", @ScriptDir, "Preset data (*.dat)|All files (*.*)", $FD_PATHMUSTEXIST , "presets.dat", $Form1_1)
		if @error = 0 Then
		$fp = FileOpen ( $filepath, $FO_READ)
		if $fp = -1 Then
			MsgBox(16,"Error","Error while reading file.")
			Return
		EndIf

		rminspector_clear()
		$out = FileRead($fp)
		FileClose($fp)
		$out_struct = StringSplit($out, "|")
		if $out_struct[0] > 0 Then
			$selected_maker = $out_struct[1]
			GUICtrlSetData($Combo1, "", $selected_maker)
			GUICtrlSetData($Combo1, "2003 >= 1.09a (or 2k3e/Maniacs)|2003 1.08 (or DynRPG)|2003 1.03|2000 1.61 (2ke)|2000 1.51 Value!|2000 1.07 (PRO)", $selected_maker)

			$file_n = $out_struct[2]

			For $i=0 to $file_n -1
				rminspector_add($out_struct[($i * 3) + 3], Number($out_struct[($i * 3) + 4]), $out_struct[($i * 3) + 5])
			Next
		EndIf
	EndIf
EndFunc

Func rminspector_save()
	$filepath = FileSaveDialog ( "Save preset", @ScriptDir, "Preset data (*.dat)|All files (*.*)", $FD_PATHMUSTEXIST , "presets.dat", $Form1_1)
	if @error = 0 Then
		$fp = FileOpen ( $filepath, $FO_OVERWRITE)
		if $fp = -1 Then
			MsgBox(16,"Error","Error while writing file.")
			Return
		EndIf

		$selected_maker = GUICtrlRead($Combo1)
		$out = $selected_maker & "|" & $itemListI & "|"

		For $i = 0 to $itemListI - 1
			$out &= $itemListCat[$i] & "|" & $itemListVID[$i] & "|" & $itemListLabel[$i] & "|"
		Next

		$out &= "END"
		FileWrite($fp, $out)
		FileClose($fp)
	EndIf
EndFunc

Func rminspector_removeitem($id)
	if $id >= $itemListI Then
		MsgBox(16,"Error","Not valid item")
		Return
	EndIf

	;la idea es eliminarlo
	_ArrayDelete($itemListCat, $id)
	_ArrayDelete($itemListVID, $id)
	_ArrayDelete($itemListLabel, $id)
	_ArrayDelete($itemListValue, $id)

	;eliminar registro del listview
	GUICtrlDelete($itemListID[$id])
	_ArrayDelete($itemListID, $id)

	$itemListI -=1
	rminspector_update_all()
	Return

EndFunc

Func rminspector_update_all($force = false)
	For $i = 0 To $itemListI
		rminspector_update_single($i, $force)
	Next
EndFunc

Func rminspector_update_single($id, $force = false)
	if $halted = False Then
		$tmp_value = rminspector_getRPGRTVar($id)
		if $tmp_value <> $itemListValue[$id] Then $force = true
		 $itemListValue[$id] = $tmp_value
	EndIf
	if $force = true then GUICtrlSetData($itemListID[$id], ($id + 1) & "|" & $itemListCat[$id] & "[" & $itemListVID[$id] & "]|" & $itemListLabel[$id] & "|" & $itemListValue[$id] )

EndFunc

Func rminspector_add($cat, $vid, $label)
	$itemListID[$itemListI] = GUICtrlCreateListViewItem("", $ListView1)
	rminspector_edit($itemListI, $cat, $vid, $label)
	$itemListI += 1
EndFunc

Func rminspector_edit($id, $cat, $vid, $label)
	$itemListCat[$itemListI] = $cat
	$itemListVID[$itemListI] = $vid
	$itemListLabel[$itemListI] = $label
	$itemListValue[$itemListI] = 0
	rminspector_update_single($itemListI, true)
EndFunc

Func rminspector_getRPGRTVar($id)
	if $enabled then
		if $itemListCat[$id] = "v" Then
			;variable
			$address_to_read = $variable_first_pointer + ($itemListVID[$id] - 1) * 4
			$out = _MemoryRead($address_to_read, $mem, "int")
		Else
			;switch
			$address_to_read = $switch_first_pointer + ($itemListVID[$id] - 1)
			$out = _MemoryRead($address_to_read, $mem, "boolean")

		EndIf
		return $out
	else
		return "--"
	EndIf

EndFunc

Func rminspector_getPickedItem()
	$item = GUICtrlRead(GUICtrlRead($ListView1))
	if $item = 0 Then return -1
	$pick_splitted = StringSplit ($item, "|")
	if $pick_splitted[0] > 0 Then
		return Number($pick_splitted[1]) - 1
	EndIf
	return -1
EndFunc

Func rminspector_removebutton()
	$id = rminspector_getPickedItem()
	if $id <> -1 Then
		rminspector_removeitem($id)
		rminspector_update_all(true)
	EndIf
EndFunc

Func rminspector_tooglehalt()

	if $halted = False Then
		$halted = True
		GUICtrlSetData( $HaltButton, "Continue")
	Else
		$halted = False
		GUICtrlSetData( $HaltButton, "Halt")
	EndIf
EndFunc

Func rminspector_clear()
	_GUICtrlListView_BeginUpdate($ListView1)
	For $i = $itemListI -1 To 0 Step -1
		rminspector_removeitem($i)
	Next
	_GUICtrlListView_EndUpdate($ListView1)
EndFunc

Func rminspector_addwindow($id = -1)
	GUISetState(@SW_DISABLE , $Form1_1)

	$Form2 = GUICreate("Add/edit", 261, 71, 207, 183)
	$Label12 = GUICtrlCreateLabel("Type", 8, 0, 28, 17)
	$Combo12 = GUICtrlCreateCombo("Switch", 8, 16, 89, 25, BitOR($CBS_DROPDOWN, $CBS_DROPDOWNLIST, $CBS_AUTOHSCROLL))
	GUICtrlSetData($Combo12, "Variable", "Switch")
	$Label22 = GUICtrlCreateLabel("ID", 104, 0, 15, 17)
	$Input12 = GUICtrlCreateInput("", 104, 16, 57, 21)
	$Label32 = GUICtrlCreateLabel("Label", 168, 0, 30, 17)
	$Input22 = GUICtrlCreateInput("", 168, 16, 81, 21)
	$OkButton2 = GUICtrlCreateButton("Ok", 8, 40, 81, 25)
	$CancelButton2 = GUICtrlCreateButton("Cancel", 96, 40, 81, 25)
	GUISetState(@SW_SHOW, $Form2)
	#EndRegion ### END Koda GUI section ###

	While 1
		$nMsg = GUIGetMsg()
		Switch $nMsg
			Case $GUI_EVENT_CLOSE
				GUISetState(@SW_HIDE, $Form2)
				GUIDelete ($Form2)
				GUISetState(@SW_ENABLE , $Form1_1)
				WinActivate ($Form1_1)
				return
			Case $CancelButton2
				GUISetState(@SW_HIDE, $Form2)
				GUIDelete ($Form2)
				GUISetState(@SW_ENABLE , $Form1_1)
				WinActivate ($Form1_1)
				return
			Case $OkButton2
				$n_clear = true
				$n_type = GUICtrlRead($Combo12)
				if $n_type = "Switch" then
					$n_type = "s"
				else
					$n_type = "v"
				endif
				$n_id = Number(GUICtrlRead($Input12))
				if ($n_id < 1) Then
					$n_clear = false
					MsgBox(16,"Error","ID must be a positive number")
				EndIf
				$n_label = GUICtrlRead($Input22)
				if $n_label = "" Then
					$n_clear = false
					MsgBox(16,"Error","Label cannot be empty")
				EndIf
				if $n_clear Then
					GUISetState(@SW_HIDE, $Form2)
					GUIDelete ($Form2)
					rminspector_add($n_type, $n_id, $n_label)
					GUISetState(@SW_ENABLE , $Form1_1)
					WinActivate ($Form1_1)
					return
				EndIf
		EndSwitch

	WEnd
EndFunc

Func rminspector_checkalive()
	if $enabled Then
		if ProcessExists($pid) = 0 Then
			$enabled = false
			GUICtrlSetData( $Label1, "Base Pointer: ???")
			GUICtrlSetData( $Label2, "Variables Pointer: ???")
			GUICtrlSetData( $Label3, "First Variable Pointer: ???")
			GUICtrlSetData( $Label4, "Switches Pointer: ???")
			GUICtrlSetData( $Label5, "First Switch Pointer: ???")
			rminspector_update_all(true)
			MsgBox(48,"Warning","RPG_RT process has ended. For attaching again, click (Re)attach.")
		EndIf
	EndIf
EndFunc

