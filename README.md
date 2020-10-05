# BaTSHit
Betaflight Thrust Stand Helper

BaTSHit is a tool to help you easily operate a "Thrust Stand" (Test RC aircraft motors and propellers) using Betaflight
It maps hotkeys which can operate the sliders on the "Motors" tab of Betaflight, regardless of which window is currently active
This allows you, for example, to have an Excel spreadsheet open and active (So that you can enter thrust values into the spreadsheet), whilst still being able to throttle up or down with hotkeys

![](https://github.com/evilC/BaTSHit/blob/master/BaTSHit.png?raw=true)

#### Warning! Spinning propellers are dangerous! Please take appropriate caution when using this app!

## Usage
### Installation
1. Install [AutoHotkey](https://www.autohotkey.com/) if not already installed
1. Download a release of BaTSHit from the [Releases Page](https://github.com/evilC/BaTSHit/releases)
1. Run Batshit.ahk
1. You will be prompted to download the NWJS SDK - a browser will automatically be opened for you to the download page for this
1. Extract the SDK to `Lib\nwjs-sdk`

### Setup
1. Run Batshit.ahk
1. For each of the hotkeys, click the "Click to Bind..." button top open the menu, press `Bind`, and press the key you wish to use for this action
1. It is highly recommended that you also click the binding again to open the menu, and select `Block` from the list.
This will stop windows from seeing the hotkey (ie Block the default action of the key)
1. Your key choices will be remembered when you next run BaTSHit

### To Use:
1. If a copy of Betaflight is running that was not launched by BaTSHit, close it
**Note** BaTSHit only works with copies of Betaflight that it launched!
1. Run Batshit.ahk
1. Click `Launch Betaflight`
1. Plug in Flight Controller and connect
1. Navigate to the `Modes` tab of Betaflight
1. Uncheck the warning dialog to allow control of the motors
1. It is advised that you test out the hotkeys to make sure they work **BEFORE** you power up the ESC, allowing motors to spin. (**Especially the Throttle to 0% hotkey!**)
