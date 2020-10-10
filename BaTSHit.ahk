#NoEnv
#include Lib\Chrome\Chrome.ahk
#include Lib\AppFactory\AppFactory.ahk
#include Lib\Betaflight\Betaflight.ahk

OutputDebug DBGVIEWCLEAR

nwjsPath := "Lib\nwjs-sdk\nw.exe"

GuiWidth := 555

bf := new Betaflight(nwjsPath)

factory := new AppFactory()
Gui, Add, Text, xm, Betaflight Path
factory.AddControl("BfPath", "Edit", "x100 yp-2 w400 R1 Disabled", bf.BfDefaultPath, Func("GuiEvent").Bind("BfPath"))
Gui, Add, Button, x+5 yp w60 gSetBfFolder, Choose...

Gui, Add, Button, xm w%GuiWidth% gLaunchBf vbtnLaunchBf, Launch Betaflight
Gui, Add, Text, xm w150 y+10, % "Hotkey to Set Motor +10%"
factory.AddInputButton("MotorPlus", "x150 yp-3 w200", Func("MotorChange").Bind("+"))
Gui, Add, Text, xm w150 y+10, % "Hotkey to Set Motor -10%"
factory.AddInputButton("MotorMinus", "x150 yp-3 w200", Func("MotorChange").Bind("-"))
Gui, Add, Text, xm w150 y+10, % "Hotkey to Set Motor to 100%"
factory.AddInputButton("MotorFull", "x150 yp-3 w200", Func("MotorChange").Bind(100))
Gui, Add, Text, xm w150 y+10, % "Hotkey to Set Motor to 0%"
factory.AddInputButton("MotorCut", "x150 yp-3 w200", Func("MotorChange").Bind(0))
Gui, Show, , BaTSHit (Betaflight Thrust Stand Helper)

; Set BF path to setting from INI file
bf.SetBfPath(factory.GuiControls.BfPath.Get())

gosub, SetBfLaunchState

mt := 0
return

F1::
	; Change tabs test
	for tabName, tabObj in bf.Tabs {
		keywait, Esc
		if (tabName == "cli")
			continue
		Tooltip % tabName
		bf.ChangeTab(tabName)
		KeyWait, Esc, D
	}
	return

F2::
	; Monitor power test
	mt := !mt
	max := bf.MonitorCurrentAmps(mt)
	if (!mt)
		msgbox % max
	return

F3::
	; InnerText test - try to get voltage on Power tab
	Tooltip % bf.GetInnerText("#battery-voltage > td.value")
	return

F7::
	; Enable Motors test
	Tooltip % bf.SetMotorsEnabled(1)
	return

F8::
	; Get Motor value test
	Tooltip % bf.GetMotorValue()
	return

F9::
	; Set Motor value test
	bf.SetMotorValue(50)
	return
	
MotorChange(value, state){
	global bf
	if (!state)
		return
	bf.ChangeTab("motors")
	bf.SetMotorsEnabled(1)
	bf.MotorChange(value)
}

SetBfLaunchState:
	GuiControl, % (bf.IsBfFound() ? "Enable" : "Disable"), btnLaunchBf
	return

LaunchBf:
	bf.MotorValue := 0
	bf.LaunchBf()
	return

SetBfFolder:
	if (bf.ChooseBfPath()){
		factory.GuiControls.BfPath.SetControlState(bf.GetBfPath())
		factory.GuiControls.BfPath.ControlChanged()
	} else {
		msgbox % path "\betaflight-configurator.exe" not found
		return		
	}
	gosub, SetBfLaunchState
	return

GuiClose:
	ExitApp