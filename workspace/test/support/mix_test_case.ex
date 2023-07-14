# Checks related helper functions
defmodule MixTest.Case do
  use ExUnit.CaseTemplate

  using do
    quote do
      import TestUtils
      require TestUtils
    end
  end
end
