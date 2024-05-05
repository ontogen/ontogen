defmodule Ontogen.SpeechAct.FormatterTest do
  use OntogenCase

  doctest Ontogen.SpeechAct.Formatter

  alias Ontogen.SpeechAct.Formatter

  describe "full format" do
    test "with all metadata" do
      assert Formatter.format(speech_act(), :full) ==
               """
               \e[33mspeech_act a280800d4d2ea117a8b01669bccbe1a76302fe55e544f909ecb339de29520346\e[0m
               Source: <http://example.com/test/dataset>
               Author: John Doe <john.doe@example.com>
               Date:   Fri May 26 13:02:02 2023 +0000
               """
               |> String.trim_trailing()
    end

    test "without speaker or source" do
      assert speech_act(speaker: nil)
             |> Formatter.format(:full) ==
               """
               \e[33mspeech_act d1a8d22b5e219eb22a21070a7cc5132cf045606695801f949b75636b3533b441\e[0m
               Source: <http://example.com/test/dataset>
               Author: -
               Date:   Fri May 26 13:02:02 2023 +0000
               """
               |> String.trim_trailing()

      assert speech_act(data_source: nil)
             |> Formatter.format(:full) ==
               """
               \e[33mspeech_act a280800d4d2ea117a8b01669bccbe1a76302fe55e544f909ecb339de29520346\e[0m
               Source: -
               Author: John Doe <john.doe@example.com>
               Date:   Fri May 26 13:02:02 2023 +0000
               """
               |> String.trim_trailing()
    end

    test "flat agent" do
      assert speech_act(speaker: id(:agent))
             |> Formatter.format(:full) ==
               """
               \e[33mspeech_act b7438f47349882ae11662dfc4bf61d1be6b035e9cfb8acfbf452fcc6bbf9364d\e[0m
               Source: <http://example.com/test/dataset>
               Author: <http://example.com/Agent>
               Date:   Fri May 26 13:02:02 2023 +0000
               """
               |> String.trim_trailing()
    end

    test "with changes" do
      assert Formatter.format(speech_act(), :full, changes: [:resource_only, :short_stat]) ==
               """
               \e[33mspeech_act a280800d4d2ea117a8b01669bccbe1a76302fe55e544f909ecb339de29520346\e[0m
               Source: <http://example.com/test/dataset>
               Author: John Doe <john.doe@example.com>
               Date:   Fri May 26 13:02:02 2023 +0000

               http://example.com/S1
               http://example.com/S2

                2 resources changed, 3 insertions(+)
               """
               |> String.trim_trailing()
    end
  end

  describe "raw format" do
    test "with agent" do
      assert speech_act(
               add: statement(1),
               update: statements([2, 3]),
               replace: statement(4),
               remove: statement(5)
             )
             |> Formatter.format(:raw) ==
               """
               \e[33mspeech_act 3f8cbbdae2101305de64d29b3c4fcae049438f08dd42483d74854493d31bc810\e[0m
               add 979ebda022992a4e5d65edddb1087b9eac54b71e688c34e69c3a99ac25bfa52e
               update 44b1e79cfc4959dce0582948346308f764398dca3745bca117f09393b08d51c3
               replace 12c584dd0edd8515f0d5b367f68f41f48ba720802ec350dfb8a87e9d35e8d946
               remove 8a059d704bc207ef2af3d68c09c98d38125c558d8365e1c20e8bbd750ca62568
               context <http://example.com/Agent/john_doe> 1685106122 +0000
               """
    end

    test "without agent" do
      assert speech_act(speaker: nil) |> Formatter.format(:raw, color: false) ==
               """
               speech_act d1a8d22b5e219eb22a21070a7cc5132cf045606695801f949b75636b3533b441
               add ae04b9c2c1bfa7cf292a17851ecb1451e0d649dd9e8f76cb32b4b32ddae82d1d
               context <http://example.com/test/dataset> 1685106122 +0000
               """
    end
  end
end
