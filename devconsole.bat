echo Launching Betaflight console and opening browser window to debug...
cd Lib\nwjs-sdk
start /B nw.exe "C:\Program Files (x86)\Betaflight\Betaflight-Configurator" --remote-debugging-port=9222
start /B chrome http://localhost:9222