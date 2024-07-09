Require echo

Set Shell "bash"
Set FontSize 22
Set Width 1300
Set Height 700

Type "# running a command on all projects"
Enter
Type "mix workspace.run -t format --show-status"
Sleep 1000ms
Enter
Sleep 7s
Ctrl+L

Type "# running a command only on modified projects" 
Enter
Type "mix workspace.run -t format --show-status --modified"
Sleep 500ms
Enter
Sleep 5s
Ctrl+L

Type "# running a command on affected projects" 
Enter
Type "mix workspace.run -t format --show-status --affected"
Sleep 500ms
Enter
Sleep 5s
