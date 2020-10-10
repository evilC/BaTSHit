/*
Interfaces with Betaflight configurator using NWJS
*/
#include %A_LineFile%\..\nwjs.ahk

class Betaflight {
	DefaultTimeout := 5000
	;~ Selectors := {CurrentTab: "#content > div > div > div.tab_title.i18n-replaced"
	Tabs:= {setup: {Name: "Setup", MenuSelector: "#tabs > ul:nth-child(2) > li.tab_setup > a"}
		, ports: {Name: "Ports", MenuSelector: "#tabs > ul:nth-child(2) > li.tab_ports > a"}
		, configuration: {Name: "Configuration", MenuSelector: "#tabs > ul:nth-child(2) > li.tab_configuration > a"}
		, power: {Name: "Power & Battery", MenuSelector: "#tabs > ul:nth-child(2) > li.tab_power > a"}
		, failsafe: {Name: "Failsafe", MenuSelector: "#tabs > ul:nth-child(2) > li.tab_failsafe > a"}
		, pid_Tuning: {Name: "PID Tuning", MenuSelector: "#tabs > ul:nth-child(2) > li.tab_pid_tuning > a"}
		, receiver: {Name: "Receiver", MenuSelector: "#tabs > ul:nth-child(2) > li.tab_receiver > a"}
		, auxiliary: {Name: "Modes", MenuSelector: "#tabs > ul:nth-child(2) > li.tab_auxiliary > a"}
		, adjustments: {Name: "Adjustments", MenuSelector: "#tabs > ul:nth-child(2) > li.tab_adjustments > a"}
		, servos: {Name: "Servos", MenuSelector: "#tabs > ul:nth-child(2) > li.tab_servos > a"}
		, motors: {Name: "Motors", MenuSelector: "#tabs > ul:nth-child(2) > li.tab_motors > a"}
		, osd: {Name: "OSD", MenuSelector: "#tabs > ul:nth-child(2) > li.tab_osd > a"}
		, vtx: {Name: "Video Transmitter", MenuSelector: "#tabs > ul:nth-child(2) > li.tab_vtx > a"}
		, "led-strip": {Name: "LED Strip", MenuSelector: "#tabs > ul:nth-child(2) > li.tab_led_strip > a"}
		, sensors: {Name: "Sensors", MenuSelector: "#tabs > ul:nth-child(2) > li.tab_sensors > a"}
		, logging: {Name: "Tethered Logging", MenuSelector: "#tabs > ul:nth-child(2) > li.tab_logging > a"}
		, onboard_logging: {Name: "Blackbox", MenuSelector: "#tabs > ul:nth-child(2) > li.tab_onboard_logging > a"}
		, cli: {Name: "CLI", MenuSelector: "#tabs > ul.mode-connected.mode-connected-cli > li > a"}}
	Power := {BatteryConnected: "#battery-connection-state > td.value"
		, CurrentVolts: "#battery-voltage > td.value"
		, CurrentAmps: "#battery-amperage > td.value"
		, mAhUsed: "#battery-mah-drawn > td.value"}
	Motors := {SetEnableMotors: "#content > div > div > div.gui_box.motorblock > div > div.motor_testing > div.notice > span.switchery.switchery-small"
		, GetEnableMotors: "#motorsEnableTestMode"
		, Sliders: ["#content > div > div > div.gui_box.motorblock > div > div.motor_testing > div.left > div.sliders > input[type=range]:nth-child(1)"
		, "#content > div > div > div.gui_box.motorblock > div > div.motor_testing > div.left > div.sliders > input[type=range]:nth-child(2)"
		, "#content > div > div > div.gui_box.motorblock > div > div.motor_testing > div.left > div.sliders > input[type=range]:nth-child(3)"
		, "#content > div > div > div.gui_box.motorblock > div > div.motor_testing > div.left > div.sliders > input[type=range]:nth-child(4)"
		, "#content > div > div > div.gui_box.motorblock > div > div.motor_testing > div.left > div.sliders > input[type=range]:nth-child(5)"
		, "#content > div > div > div.gui_box.motorblock > div > div.motor_testing > div.left > div.sliders > input[type=range]:nth-child(6)"
		, "#content > div > div > div.gui_box.motorblock > div > div.motor_testing > div.left > div.sliders > input[type=range]:nth-child(7)"
		, "#content > div > div > div.gui_box.motorblock > div > div.motor_testing > div.left > div.sliders > input[type=range]:nth-child(8)"]}
			
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
	
	; ============== DOM management
	
	ExecJS(js){
		this.Debug("Executing JS: " js)
		return this.BfPage.evaluate(js)
	}
	
	GetTimeout(timeout := -1){
		if (timeout == -1)
			return this.DefaultTimeout
		else
			return timeout
	}
	
	WaitForSelector(selector, timeout := -1){
		this.Debug("Waiting for selector " selector)
		timeout := this.GetTimeout(timeout)
		gotSelector := 0
		Loop {
			try {
				node := this.ExecJS("document.querySelector('" selector "')")
				gotSelector := 1
				if (node.subtype == "null")
					throw
				this.Debug("Wait for selector ended - FOUND, subtype = " node.subtype)
				break
			} catch {
				;~ msg := "Wait for selector ended - Exception! Selector = " selector
				;~ this.Debug(msg)
				;~ throw msg
			}
			Sleep 10
		} until (gotSelector || A_TickCount > timeout)
		if (!gotSelector){
			msg =  "Wait for selector ended - NOT FOUND, Timeout reached ! Selector = " selector
			this.Debug(msg)
			throw msg
		}
		return this
	}
	
	BuildJQuery(selector, action){
		js := "$('" selector "')"
		if (action != "")
			js .= "." action
		return js
	}
	
	/*
	BuildJS(selector, action := ""){
		js := "document.querySelector('" selector "')"
		if (action != "")
			js .= "." action
		return js
	}
	*/
	
	GetSelector(selector, timeout := -1){
		this.WaitForSelector(selector, timeout)
		;~ return this.ExecJS(this.BuildJS(selector))
		return this.ExecJS(this.BuildJQuery(selector))
	}
	
	Click(selector, timeout := -1){
		this.Debug("Clicking selector " selector " ...")
		this.WaitForSelector(selector, timeout)
		this.ExecJs(this.BuildJQuery(selector, "click()"))
	}
	
	; Get InnerText of an element
	GetInnerText(selector, timeout := -1){
		this.Debug("Getting InnerText for selector " selector " ...")
		this.WaitForSelector(selector, timeout)
		;~ node := this.ExecJS(this.BuildJS(selector, "innerText"))
		node := this.ExecJS(this.BuildJQuery(selector, "text()"))
		this.Debug("Value is " node.value)
		return node.value
	}
	
	; Gets value of a TextBox etc
	GetValue(selector, timeout := -1){
		this.Debug("Getting Value for selector " selector " ...")
		this.WaitForSelector(selector, timeout)
		js := this.BuildJQuery(selector, "val()")
		node := this.ExecJS(js)
		value := node.value
		this.Debug("Value is " value)
		return value
	}
	
	; Gets value of a Checkbox
	GetCheckboxState(selector){
		this.Debug("Getting Checkbox state for selector " selector "...")
		node := this.ExecJs(this.BuildJQuery(selector, "is(':checked')"))
		value := node.value
		this.Debug("Value is " value)
		return value
	}
	
	; ============= Tabs
	GetCurrentTab(){
		timeout := A_TickCount + 5000
		selector := "#content > div"
		found := 0
		Loop {
			gotSelector := 0
			; ToDo: Can I use GetSelector() here?
			this.WaitForSelector(selector)
			node := this.ExecJS(this.BuildJQuery(selector, "attr('class')"))
			desc := node.value
			if (desc == ""){
				this.Debug("Node has no description")
			} else {
				this.Debug("Description is " desc)
			}
			;~ pos := RegExMatch(desc, "O)div\.tab-([\w-]*)", m)
			pos := RegExMatch(desc, "O)tab-([\w-]*)", m)
			tabName := m.Value(1)
			if (tabName != ""){
				found := 1
			} else {
				this.Debug("Waiting for tab name...")
			}
		} until (found || A_TickCount > timeout)
		if (!found){
			msg := "Could not get current tab"
			this.Debug(msg)
			throw msg
		}
		this.debug(tabName)
		return tabName
	}
	
	; Returns true if tab changed
	ChangeTab(tabName){
		this.Debug("Change Tab start - " tabName)
		currentTab := this.GetCurrentTab()
		if (currentTab == tabName){
			this.Debug("Change Tab end - already on tab " tabName)
		} else {
			if (!ObjHasKey(this.Tabs, tabName)){
				throw "Unknown tab " tabName
			}
			selector := this.Tabs[tabName].MenuSelector
			this.Click(selector)
			this.Debug("Change Tab end")
		}
	}
	
	Debug(text){
		OutputDebug % "AHK| " text
	}
	; ======================== Power Tab ====================
	
	GetCurrentVolts(){
		val := this.GetInnerText(this.Power.CurrentVolts)
		val := SubStr(val, 1 , StrLen(val) - 2)
		return val
	}
	
	GetCurrentAmps(){
		val := this.GetInnerText(this.Power.CurrentAmps)
		val := SubStr(val, 1 , StrLen(val) - 2)
		return val
	}
	
	MonitorCurrentAmps(state){
		fn := this._MonitorCurrentAmpsFn
		if (state){
			this.MaxAmps := 0
			this.ChangeTab("motors")
			this.MotorChange(50)
			this.ChangeTab("power")
			SetTimer, % fn, 1000
		} else {
			SetTimer, % fn, Off
			this.ChangeTab("motors")
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

	GetMotorsEnabled(){
		return this.GetCheckboxState(this.Motors.GetEnableMotors)
	}
	
	SetMotorsEnabled(state){
		if (state != this.GetMotorsEnabled()){
			this.Click(this.Motors.SetEnableMotors)
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
		
		this.SetMotorsEnabled(1)
		pos := 1000 + (percent * 10)
		this.ExecJS(this.BuildJQuery(this.Motors.Sliders[motor], "val(" pos ").trigger('input');"))
	}

	GetMotorValue(motor := 1){
		; ToDo: Why is this sometimes off by 1?
		this.SetMotorsEnabled(1)
		pos := this.GetValue(this.Motors.Sliders[motor])
		value := round((pos - 1000) / 10)
		return value
	}
}