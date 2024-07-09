Require echo

Set Shell "bash"
Set FontSize 22
Set Width 1300
Set Height 700

Type "mix workspace.graph --show-status"
Sleep 500ms
Enter
Sleep 3s

Ctrl+L

Type "# workspace keeps track of your project changes"
Sleep 500ms
Enter

Type "touch packages/cli_tools/lib/foo.ex"
Sleep 500ms
Enter

Type "mix workspace.graph --show-status"
Sleep 500ms
Enter
Sleep 3s
