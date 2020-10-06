class NW extends Chrome
{
	FindInstances()
	{
		static Needle := "--remote-debugging-port=(\d+)"
		Out := {}
		for Item in ComObjGet("winmgmts:")
			.ExecQuery("SELECT CommandLine FROM Win32_Process"
			. " WHERE Name = 'nw.exe'")
			if RegExMatch(Item.CommandLine, Needle, Match)
				Out[Match1] := Item.CommandLine
		return Out.MaxIndex() ? Out : False
	}
	
	__New(nwPath, bfcPath, debugPort:="")
	{
		; Verify Betaflight-Configurator path
		if !InStr(FileExist(BFCPath), "D")
			throw Exception("The given Betaflight-Configurator path is invalid")
		
		; Verify NWjsPath
		if !FileExist(nwPath)
			throw Exception("The given nw.exe path is invalid")
		
		; Verify DebugPort
		if (debugPort!= "")
		{
			if debugPort is not integer
				throw Exception("DebugPort must be a positive integer")
			else if (debugPort <= 0)
				throw Exception("DebugPort must be a positive integer")
			this.debugPort := debugPort
		}
		
		Run, % this.CliEscape(nwPath) " " this.CliEscape(bfcPath)
		. " --remote-debugging-port=" this.debugPort
		,,, OutputVarPID
		this.PID := OutputVarPID
	}
}