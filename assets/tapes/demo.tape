# VHS documentation
#
# Output:
#   Output <path>.gif               Create a GIF output at the given <path>
#   Output <path>.mp4               Create an MP4 output at the given <path>
#   Output <path>.webm              Create a WebM output at the given <path>
#
# Require:
#   Require <string>                Ensure a program is on the $PATH to proceed
#
# Settings:
#   Set FontSize <number>           Set the font size of the terminal
#   Set FontFamily <string>         Set the font family of the terminal
#   Set Height <number>             Set the height of the terminal
#   Set Width <number>              Set the width of the terminal
#   Set LetterSpacing <float>       Set the font letter spacing (tracking)
#   Set LineHeight <float>          Set the font line height
#   Set LoopOffset <float>%         Set the starting frame offset for the GIF loop
#   Set Theme <json|string>         Set the theme of the terminal
#   Set Padding <number>            Set the padding of the terminal
#   Set Framerate <number>          Set the framerate of the recording
#   Set PlaybackSpeed <float>       Set the playback speed of the recording
#   Set MarginFill <file|#000000>   Set the file or color the margin will be filled with.
#   Set Margin <number>             Set the size of the margin. Has no effect if MarginFill isn't set.
#   Set BorderRadius <number>       Set terminal border radius, in pixels.
#   Set WindowBar <string>          Set window bar type. (one of: Rings, RingsRight, Colorful, ColorfulRight)
#   Set WindowBarSize <number>      Set window bar size, in pixels. Default is 40.
#   Set TypingSpeed <time>          Set the typing speed of the terminal. Default is 50ms.
#
# Sleep:
#   Sleep <time>                    Sleep for a set amount of <time> in seconds
#
# Type:
#   Type[@<time>] "<characters>"    Type <characters> into the terminal with a
#                                   <time> delay between each character
#
# Keys:
#   Escape[@<time>] [number]        Press the Escape key
#   Backspace[@<time>] [number]     Press the Backspace key
#   Delete[@<time>] [number]        Press the Delete key
#   Insert[@<time>] [number]        Press the Insert key
#   Down[@<time>] [number]          Press the Down key
#   Enter[@<time>] [number]         Press the Enter key
#   Space[@<time>] [number]         Press the Space key
#   Tab[@<time>] [number]           Press the Tab key
#   Left[@<time>] [number]          Press the Left Arrow key
#   Right[@<time>] [number]         Press the Right Arrow key
#   Up[@<time>] [number]            Press the Up Arrow key
#   Down[@<time>] [number]          Press the Down Arrow key
#   PageUp[@<time>] [number]        Press the Page Up key
#   PageDown[@<time>] [number]      Press the Page Down key
#   Ctrl+<key>                      Press the Control key + <key> (e.g. Ctrl+C)
#
# Display:
#   Hide                            Hide the subsequent commands from the output
#   Show                            Show the subsequent commands in the output

Require echo

Set Shell "bash"
Set FontSize 22
Set Width 1300
Set Height 700
# Set WindowBar Colorful

Type "# This is an elixir mono-repo with mix projects under packages and apps"
Sleep 500ms 
Enter

Type "tree -L 2 --gitignore"
Sleep 500ms
Enter
Sleep 1s

Type "# you can list all workspace projects"
Sleep 500ms
Enter

Type "mix workspace.list"
Sleep 500ms
Enter
Sleep 3s

Type "# displaying the dependencies graph between the projects"
Sleep 500ms
Enter

Type "mix workspace.graph --show-status"
Sleep 500ms
Enter
Sleep 3s

Enter

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

Enter

Type "# running a command in all projects"
Sleep 500ms
Enter
Type "mix workspace.run -t format --show-status"
Sleep 500ms
Enter
Sleep 5s

Enter

Type "# running a command only on modified projects"
Sleep 500ms
Enter
Type "mix workspace.run -t format --modified --show-status"
Sleep 500ms
Enter
Sleep 3s

Enter

Type "# or affected, e.g. modified + all projects depending on them"
Sleep 500ms
Enter
Type "mix workspace.run -t format --affected --show-status"
Sleep 500ms
Enter
Sleep 3s

Enter

Type "# viewing the status"
Sleep 500ms
Enter
Type "mix workspace.status"
Sleep 500ms
Enter
Sleep 6s
