#include Lib\Chrome\Chrome.ahk
#include Lib\Chrome\nwjs.ahk
#include Lib\AppFactory\AppFactory.ahk

nwjsPath := "nwjs-sdk\nw.exe"
bfDefaultPath := "C:\Program Files (x86)\Betaflight\Betaflight-Configurator"
;~ bfDefaultPath := "C:\"
SliderSelector := "$('#content > div > div > div.gui_box.motorblock > div > div.motor_testing > div.left > div.sliders > input[type=range]:nth-child(1)').eq(0)"
;~ SliderSelector := "$('div.sliders input:not(.master)').eq(0)"

if (!FileExist(nwjsPath)){
	msgbox NWJS SDK not found, please download it and extract it to Lib\NWJS`n(Download page will launch)
	Run, https://nwjs.io/downloads/
	ExitApp
}
GuiWidth := 555

factory := new AppFactory()
Gui, Add, Text, xm, Betaflight Path
factory.AddControl("BfPath", "Edit", "x100 yp-2 w400 R1 Disabled", bfDefaultPath, Func("GuiEvent").Bind("BfPath"))
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

gosub, SetBfLaunchState
if (WinExist("ahk_exe nw.exe")){
	gosub, LaunchBf
}
return

MotorChange(value, state){
	if (!state)
		return
	global MotorValue
	if (value == "+"){
		MotorValue += 10
	} else if (value == "-"){
		MotorValue -= 10
	} else if (value is number || value == 0){
		MotorValue := value
	} else {
		throw "Unsupported value " value
	}
	if (MotorValue > 100)
		MotorValue := 100
	else if (MotorValue < 0)
		MotorValue := 0
	
	SetMotorValue(MotorValue)
}

SetMotorValue(percent){
	global BfPage, SliderSelector
	pos := 1000 + (percent * 10)
	BfPage.evaluate(SliderSelector ".val(" pos ").trigger('input');")
}

GetMotorValue(){
	global BfPage, SliderSelector
	val := BfPage.evaluate(SliderSelector ".val()").value
	return val
}

SetBfLaunchState:
	state := (IsBfFound(factory.GuiControls.BfPath.Get()))
	GuiControl, % (state ? "Enable" : "Disable"), btnLaunchBf
	return

LaunchBf:
	; Find an instance of NW, or create a new one
	if (nws := NW.FindInstances())
		nwInst := {"base": NW, "DebugPort": nws.MinIndex()}
	else
		nwInst := new NW(NwjsPath, factory.GuiControls.BfPath.Get())

	; Get the main Betaflight Configurator page
	BfPage := nwInst.getPageByURL("main.html", "contains")
	BfPage.WaitForLoad()
	MotorValue := 0
	return

SetBfFolder:
	FileSelectFolder, path, , , Select Betaflight install folder, *.exe
	if (!ErrorLevel){	; If user selected a folder
		if (!IsBfFound(path)){
				msgbox % path "\betaflight-configurator.exe" not found
				return
		}
		factory.GuiControls.BfPath.SetControlState(path)
		factory.GuiControls.BfPath.ControlChanged()
	}
	gosub, SetBfLaunchState
	return

IsBfFound(path){
	return FileExist(path "\betaflight-configurator.exe")
}

GuiClose:
	ExitApp