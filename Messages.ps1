[String[]]$MsgEULA = @(
"Before we begin",
"--------------------------------",
"You may only use this Speedtest software and information generated",
"from it for personal, non-commercial use, through a command line",
"interface on a personal computer. Your use of this software is subject",
"to the End User License Agreement, Terms of Use and Privacy Policy and",
"General Data Protection Regulation (Europe)",
"these URLs:",
"https://www.speedtest.net/about/eula$",
"https://www.speedtest.net/about/terms$",
"https://www.speedtest.net/about/privacy"
);

[String[]]$PromptEULA = @(
"Do you wish to continue in accordnace with the",
"End User License Agreement and the Terms of Use and Privacy? y/n"
);

[String[]]$FileVersionError = @(
"Missing Speedtest.exe in $WorkingDirectory",
"Or existing version could not be verified."
);

[String[]]$OnTheMarkQuestion = @(
"Do you want interval times to be 'OnTheMark'? y/n"
);

[String[]]$ServerSelectMsg = @(
"Please specify the ID of the server you would like to use (0 to use random)"
);

[String[]]$BeingTestMsg = @(
"\|/ DO NOT open the log file while the speed test is running.",
" |  Either stop the script first, or wait for the delay between runtimes.",
"/|\ It is time! Running Speed Test...Please wait...",
" ",
"Speedtest.exe is currently polling for best server.",
"Errors may occur during polling process and display in the terminal.",
"See log for details once prompted"
);