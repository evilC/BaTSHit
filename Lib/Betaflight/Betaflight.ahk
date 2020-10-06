/*
Interfaces with Betaflight configurator using NWJS
*/
#include %A_LineFile%\..\nwjs.ahk

class Betaflight {
	CurrentTab := "Setup"
	;~ Selectors := {CurrentTab: "#content > div > div > div.tab_title.i18n-replaced"   
	Selectors := {CurrentTab: "#content > div > div > div.cf_column.full > div.tab_title.i18n-replaced"
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
			, CLI: "#tabs > ul.mode-connected.mode-connected-cli > li > a"}
		, Power: {BatteryConnected: "#battery-connection-state > td.value"
			, CurrentVolts: "#battery-voltage > td.value"
			, CurrentAmps: "#battery-amperage > td.value"
			, mAhUsed: "#battery-mah-drawn > td.value"}
		, Motors: {EnableMotors: "#content > div > div > div.gui_box.motorblock > div > div.motor_testing > div.notice > span.switchery.switchery-small"
			, Sliders: ["$('#content > div > div > div.gui_box.motorblock > div > div.motor_testing > div.left > div.sliders > input[type=range]:nth-child(1)').eq(0)"
			, "$('#content > div > div > div.gui_box.motorblock > div > div.motor_testing > div.left > div.sliders > input[type=range]:nth-child(1)').eq(1)"
			, "$('#content > div > div > div.gui_box.motorblock > div > div.motor_testing > div.left > div.sliders > input[type=range]:nth-child(1)').eq(2)"
			, "$('#content > div > div > div.gui_box.motorblock > div > div.motor_testing > div.left > div.sliders > input[type=range]:nth-child(1)').eq(3)"
			, "$('#content > div > div > div.gui_box.motorblock > div > div.motor_testing > div.left > div.sliders > input[type=range]:nth-child(1)').eq(4)"
			, "$('#content > div > div > div.gui_box.motorblock > div > div.motor_testing > div.left > div.sliders > input[type=range]:nth-child(1)').eq(5)"
			, "$('#content > div > div > div.gui_box.motorblock > div > div.motor_testing > div.left > div.sliders > input[type=range]:nth-child(1)').eq(6)"
			, "$('#content > div > div > div.gui_box.motorblock > div > div.motor_testing > div.left > div.sliders > input[type=range]:nth-child(1)').eq(7)"
			, "$('#content > div > div > div.gui_box.motorblock > div > div.motor_testing > div.left > div.sliders > input[type=range]:nth-child(1)').eq(8)"]}}
			
	BfDefaultPath := "C:\Program Files (x86)\Betaflight\Betaflight-Configurator"
	MotorValue := 0
	_MonitorCurrentAmpsFn := this._MonitorCurrentAmps.Bind(this)

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
		this.WaitForPageLoad()
	}
	
	WaitForPageLoad(){
		this.BfPage.WaitForLoad()
	}
	
	GetBfPath(){
		return this.BfPath
	}
	
	GetCurrentTab(){
		; Unreliable - path not always the same
		; return this.GetInnerText(this.Selectors.CurrentTab)
		return this.CurrentTab
	}
	
	; Returns true if tab changed
	ChangeTab(tabName){
		if (this.CurrentTab == tabName)
			return false
		if (selector := this.Selectors.Tabs[tabName]){
			this.Debug("Clicking selector for tab " tabName)
			this.Click(selector)
			this.CurrentTab := tabName
			;~ this.WaitForPageLoad()
			Sleep, 200 ; ToDo: Need deterministic way to ensure page is ready
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
		this.Debug("Getting InnerText for selector " selector " ...")
		value := this.ExecJS("document.querySelector('" selector "').innerText").value
		this.Debug("Value is " value)
		return value
	}
	
	GetValue(selector){
		this.Debug("Getting Value for selector " selector "...")
		value := this.ExecJS(selector ".val()").value
		this.Debug("Value is " value)
		return value
	}
	
	ExecJS(js){
		return this.BfPage.evaluate(js)
	}
	
	GetCheckboxState(selector){
		this.Debug("Getting Checkbox state for selector " selector "...")
		value := this.ExecJs("document.querySelector('" selector "').checked").value
		this.Debug("Value is " value)
		return value
	}
	
	Debug(text){
		OutputDebug % "AHK| " text
	}
	; ======================== Power Tab ====================
	
	GetCurrentVolts(){
		this.ChangeTab("Power & Battery")
		val := this.GetInnerText(this.Selectors.Power.CurrentVolts)
		val := SubStr(val, 1 , StrLen(val) - 2)
		return val
	}
	
	GetCurrentAmps(){
		this.ChangeTab("Power & Battery")
		val := this.GetInnerText(this.Selectors.Power.CurrentAmps)
		val := SubStr(val, 1 , StrLen(val) - 2)
		return val
	}
	
	MonitorCurrentAmps(state){
		;~ this.ChangeTab("Power & Battery")
		fn := this._MonitorCurrentAmpsFn
		if (state){
			this.MaxAmps := 0
			this.MotorChange(50)
			SetTimer, % fn, 1000
		} else {
			SetTimer, % fn, Off
			this.MotorChange(0)
			return this.MaxAmps
		}
	}
	
	_MonitorCurrentAmps(){
		amps := this.GetCurrentAmps()
		if (amps > this.MaxAmps){
			this.MaxAmps := amps
		}
	}
	
	; ======================== Motors Tab ====================

	GetMotorState(){
		return this.GetCheckboxState("#motorsEnableTestMode")
	}
	
	SetMotorState(state){
		if (state != this.GetMotorState()){
			this.Click(this.Selectors.Motors.EnableMotors)
		}
	}
	
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
	
	SetMotorValue(percent, motor := 1){
		this.ChangeTab("Motors")
		this.SetMotorState(1)
		pos := 1000 + (percent * 10)
		this.ExecJS(this.Selectors.Motors.Sliders[motor]  ".val(" pos ").trigger('input');")
	}

	GetMotorValue(motor := 1){
		this.ChangeTab("Motors")
		this.EnableMotorsIfChangingTab()
		return this.ExecJS(this.Selectors.Motors.Sliders[motor] ".val()").value.value
	}
}