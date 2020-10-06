/*
Interfaces with Betaflight configurator using NWJS
*/
#include %A_LineFile%\..\nwjs.ahk

class Betaflight {
	Selectors := {Slider: "$('#content > div > div > div.gui_box.motorblock > div > div.motor_testing > div.left > div.sliders > input[type=range]:nth-child(1)').eq(0)"
				, CurrentTab: "#content > div > div > div.tab_title.i18n-replaced"
				, Tabs: {Setup: "#tabs > ul:nth-child(2) > li.tab_setup > a"
						, "Setup OSD": "#tabs > ul:nth-child(2) > li.tab_setup_osd > a"
						, Ports: "#tabs > ul:nth-child(2) > li.tab_ports.active > a"
						, Configuration: "#tabs > ul:nth-child(2) > li.tab_configuration > a"
						, "Power & Battery": "#tabs > ul:nth-child(2) > li.tab_power > a"
						, Failsafe: "#tabs > ul:nth-child(2) > li.tab_failsafe > a"
						, "PID Tuning": "#tabs > ul:nth-child(2) > li.tab_pid_tuning > a"
						, Receiver: "#tabs > ul:nth-child(2) > li.tab_receiver > a"
						, Modes: "#tabs > ul:nth-child(2) > li.tab_auxiliary > a"
						, Adjustments: "#tabs > ul:nth-child(2) > li.tab_adjustments > a"
						, Servos: "#tabs > ul:nth-child(2) > li.tab_servos > a"
						, Motors: "#tabs > ul:nth-child(2) > li.tab_motors > a"
						, OSD: "#tabs > ul:nth-child(2) > li.tab_osd > a"
						, VTX: "#tabs > ul:nth-child(2) > li.tab_vtx > a"
						, Transponder: "#tabs > ul:nth-child(2) > li.tab_transponder > a"
						, "LED Strip": "#tabs > ul:nth-child(2) > li.tab_led_strip > a"
						, Sensors: "#tabs > ul:nth-child(2) > li.tab_sensors.active > a"
						, "Tethered Logging": "#tabs > ul:nth-child(2) > li.tab_logging > a"
						, BlackBox: "#tabs > ul:nth-child(2) > li.tab_onboard_logging > a"
						, CLI: "#tabs > ul.mode-connected.mode-connected-cli > li > a"}}
	BfDefaultPath := "C:\Program Files (x86)\Betaflight\Betaflight-Configurator"
	;~ SliderSelector := "$('#content > div > div > div.gui_box.motorblock > div > div.motor_testing > div.left > div.sliders > input[type=range]:nth-child(1)').eq(0)"
	;~ CurrentTabSelector := "#content > div > div > div.tab_title.i18n-replaced"
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
	
	ExecJS(js){
		return this.BfPage.evaluate(js)
	}
	
	GetCurrentTab(){
		return this.GetInnerText(this.Selectors.CurrentTab)
	}

	ChangeTab(tabName){
		if (selector := this.Selectors.Tabs[tabName]){
			this.Click(selector)
			return true
		} else {
			msgbox % "No selector found for tab " tabName
			return false
		}
	}
	
	Click(selector){
		this.ExecJs("document.querySelector('" selector "').click()")
	}
	
	GetInnerText(selector){
		return this.ExecJS("document.querySelector('" selector "').innerText").value
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
		this.BfPage.evaluate(this.Selectors.Slider ".val(" pos ").trigger('input');")
	}

	GetMotorValue(){
		val := this.BfPage.evaluate(this.SliderSelector ".val()").value
		return val
	}
}