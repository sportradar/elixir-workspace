defmodule Workspace.ANSITest do
  use ExUnit.Case

  describe "unescape/1" do
    test "removes simple ANSI color codes" do
      assert Workspace.ANSI.unescape("\e[31mHello\e[0m") == "Hello"
    end

    test "removes multiple ANSI codes in a string" do
      assert Workspace.ANSI.unescape("\e[31mRed\e[0m and \e[32mGreen\e[0m") == "Red and Green"
    end

    test "removes cursor movement ANSI codes" do
      assert Workspace.ANSI.unescape("\e[1A\e[2KHello") == "Hello"
    end

    test "removes complex ANSI sequences" do
      assert Workspace.ANSI.unescape("\e[1;31;40mWarning\e[0m") == "Warning"
    end

    test "removes ANSI codes with semicolon-separated attributes" do
      assert Workspace.ANSI.unescape("\e[1;4;34mUnderlined Blue Text\e[0m") ==
               "Underlined Blue Text"
    end

    test "removes CSI sequence with question mark parameters" do
      assert Workspace.ANSI.unescape("\e[?25lHidden Cursor\e[?25h") == "Hidden Cursor"
    end

    test "removes ANSI codes with spaces and separators" do
      assert Workspace.ANSI.unescape("\e[38;5;196mBright Red\e[0m") == "Bright Red"
    end

    test "removes non-color ANSI sequences" do
      assert Workspace.ANSI.unescape("\e[K\e[JClear Screen") == "Clear Screen"
    end

    test "removes mixed ANSI escape sequences" do
      assert Workspace.ANSI.unescape("\e[1mBold \e[4mUnderlined\e[0m Normal") ==
               "Bold Underlined Normal"
    end

    test "returns original string if no ANSI codes are present" do
      assert Workspace.ANSI.unescape("No ANSI codes here") == "No ANSI codes here"
    end

    test "handles empty string" do
      assert Workspace.ANSI.unescape("") == ""
    end

    test "handles string with only ANSI codes" do
      assert Workspace.ANSI.unescape("\e[31m\e[1m\e[0m") == ""
    end

    test "removes CSI sequence with no parameters" do
      # CSI sequence that only has the command byte
      assert Workspace.ANSI.unescape("\e[mNormal\e[m") == "Normal"
    end

    # Complex and borderline cases
    test "removes CSI sequences with unusual but valid parameters" do
      # Using various characters in parameter sections: digits, semicolons, question marks, and spaces
      input = "\e[?12; 34;56mComplex\e[0m"
      expected = "Complex"
      assert Workspace.ANSI.unescape(input) == expected
    end

    test "removes ANSI codes when they are adjacent to each other" do
      input = "\e[1m\e[4mUnderlined Bold\e[0m"
      expected = "Underlined Bold"
      assert Workspace.ANSI.unescape(input) == expected
    end

    test "removes ANSI codes embedded in multi-line text" do
      input = "Line1\e[31m\nLine2\e[0m\nLine3"
      expected = "Line1\nLine2\nLine3"
      assert Workspace.ANSI.unescape(input) == expected
    end

    test "handles CSI sequence with extra separator bytes" do
      # The sequence includes extra spaces or characters in the separator range.
      input = "\e[12 34mTest\e[0m"
      expected = "Test"
      assert Workspace.ANSI.unescape(input) == expected
    end

    test "removes CSI sequence with intermediate bytes" do
      # Here, "12" are parameter bytes (0x30–0x3F), "$" is an intermediate byte (0x20–0x2F),
      # and "Q" is the final byte (0x40–0x7E).
      input = "\e[12$QText\e[0m"
      expected = "Text"
      assert Workspace.ANSI.unescape(input) == expected
    end

    test "with invalid CSI sequences" do
      # here \x8B is not a valid final byte so we dont expect any escape
      input = "Start\x1B[31\x8BInvalid"
      assert Workspace.ANSI.unescape(input) == "Start\e[31\x8BInvalid"
    end

    # this will fail since we don't handle OSC, leaving it here for future improvement
    # if needed
    test "does not remove OSC sequences" do
      input = "\x1B]0;My Title\x07Normal Text\x1B]2;Other\x1B\\More Text"
      correct = "Normal TextMore Text"
      incorrect = "0;My Title\aNormal Text2;OtherMore Text"

      refute Workspace.ANSI.unescape(input) == correct
      assert Workspace.ANSI.unescape(input) == incorrect
    end
  end
end
