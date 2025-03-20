defmodule Workspace.ANSI do
  @moduledoc false
  # helper function for working with cli output and ANSI codes

  # A regex for capturing ansi escape codes.
  #
  #
  # According to the standard the CSI is defined as:
  #
  # - An `ESC [`
  # - followed by any number (including none) of "parameter bytes" in the range 0x30–0x3F (ASCII 0–9:;<=>?)
  # - followed  by any number of "intermediate bytes" in the range 0x20–0x2F
  # (ASCII space and !"#$%&'()*+,-./)
  # - then finally by a single "final byte" in the range 0x40–0x7E (ASCII @A–Z[\]^_a–z{|}~)
  #
  # Notice that whitespace in the parameter bytes is not allowed according to the standard
  # but many terminals, including echo -e tolerate them, so we also include them in the
  # parameter bytes match
  #
  # NOTE
  #
  # This will not capture all possible escape codes, e.g. OSC sequences but it is more than enough
  # for our use case
  @ansi_escape_regex ~r"""
    \x1B              # Match the ESC character (ASCII 27), start of all ANSI sequences
    (?:               # Non-capturing group for two types of sequences
      [@-Z\\-_]       # Simple sequence: one character from @ to Z, \, _, or -
      |               # OR
      \[              # CSI sequence starts with literal [
      [\x30-\x3F\s]*  # Zero or more parameter bytes (ASCII 0–9, :;<=>?)
      [\x20-\x2F]*    # Zero or more intermediate bytes (ASCII space and !"#$%&'()*+,-./)
      [\x40-\x7E]     # Final byte: ASCII 64 ('@') to 126 ('~')
    )                 # End of non-capturing group
  """x

  # We add the x modifier to enable extended mode and allow inline comments

  @doc """
  Returns the input string with (most) ANSI escape sequences removed.
  """
  @spec unescape(data :: binary()) :: binary()
  def unescape(data) do
    Regex.replace(@ansi_escape_regex, data, "")
  end
end
