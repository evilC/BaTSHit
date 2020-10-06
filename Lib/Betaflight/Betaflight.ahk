/*
Interfaces with Betaflight configurator using NWJS
*/
#include %A_LineFile%\..\nwjs.ahk

class Betaflight {
	BfDefaultPath := "C:\Program Files (x86)\Betaflight\Betaflight-Configurator"
	SliderSelector := "$('#content > div > div > div.gui_box.motorblock > div > div.motor_testing > div.left > div.sliders > input[type=range]:nth-child(1)').eq(0)"
	;~ SliderSelector := "$('div.sliders input:not(.master)').eq(0)"
	MotorValue := 0

	__New(NwjsPath, bfPath := -1){
		if (bfPath == -1){
			bfPath := this.bfDefaultPath
		}
		if (!FileExist(nwjsPath)){
			msgbox NWJS SDK not found, please download it and extract it to Lib\nwjs-sdk`n(Download page will launch)
			Run, https://nwjs.io/downloads/
			ExitApp
		}
		this.NwjsPath := NwjsPath
		this.BfPath := BfPath
		if (WinExist("ahk_exe nw.exe")){
			this.LaunchBf()
		}
	}
	
	ChooseBfPath(){
		FileSelectFolder, path, , , Select Betaflight install folder
		if (!ErrorLevel){	; If user selected a folder
			if (this.IsBfFound(path)){
				this.BfPath := path
				return 1
			}
		}
		return 0
	}
	
	IsBfFound(path := -1){
		if (path == -1)
			path := this.BfPath
		return FileExist(path "\betaflight-configurator.exe")
	}
	
	LaunchBf(){
		; Find an instance of NW, or create a new one
		if (nws := NW.FindInstances())
			this.nwInst := {"base": NW, "DebugPort": nws.MinIndex()}
		else
			this.nwInst := new NW(this.NwjsPath, this.bfPath)
		
		; Get the main Betaflight Configurator page
		this.BfPage := this.nwInst.getPageByURL("main.html", "contains")
		this.BfPage.WaitForLoad()
	}
	
	GetBfPath(){
		return this.BfPath
	}
	
	; ======================== Motors Tab ====================
	
	MotorChange(value){
		if (value == "+"){
			this.MotorValue += 10
		} else if (value == "-"){
			this.MotorValue -= 10
		} else if (value is number || value == 0){
			this.MotorValue := value
		} else {
			throw "Unsupported value " value
		}
		if (this.MotorValue > 100)
			this.MotorValue := 100
		else if (this.MotorValue < 0)
			this.MotorValue := 0
		
		this.SetMotorValue(this.MotorValue)
	}
	
	SetMotorValue(percent){
		pos := 1000 + (percent * 10)
		this.BfPage.evaluate(this.SliderSelector ".val(" pos ").trigger('input');")
	}

	GetMotorValue(){
		val := this.BfPage.evaluate(this.SliderSelector ".val()").value
		return val
	}
}