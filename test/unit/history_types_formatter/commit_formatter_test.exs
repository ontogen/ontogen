defmodule Ontogen.HistoryType.Formatter.CommitFormatterTest do
  use OntogenCase

  doctest Ontogen.HistoryType.Formatter.CommitFormatter

  alias Ontogen.HistoryType.Formatter.CommitFormatter

  import Ontogen.IdUtils

  describe "default format" do
    test "commit" do
      commit = commit(message: "First commit\nwith description")

      assert CommitFormatter.format(commit, :default, color: false) =~
               ~r"fc376678c4 - First commit \(\d+ .+\) <John Doe john\.doe@example\.com>$"

      assert CommitFormatter.format(commit, :default, color: true) =~
               "\e[33mfc376678c4\e[0m - First commit \e[32m("

      assert CommitFormatter.format(commit, :default) ==
               CommitFormatter.format(commit, :default, color: true)
    end

    test "flat committer" do
      assert commit(committer: id(:agent))
             |> CommitFormatter.format(:default, color: false) =~
               ") <http://example.com/Agent>"
    end

    test "revert commit" do
      assert CommitFormatter.format(revert(), :default) =~
               "\e[33m0f6be19cfb\e[0m - \e[3mRevert of commits:"
    end
  end

  describe "oneline format" do
    test "commit" do
      commit = commit(message: "First commit\nwith description")

      assert CommitFormatter.format(commit, :oneline) ==
               "\e[33mfc376678c4decae97dda5fd4ecf174d5f51c4a07fb26220b6e73719f04f63f0b\e[0m First commit"
    end

    test "revert" do
      assert CommitFormatter.format(revert(), :oneline) =~
               "\e[33m0f6be19cfb2b86fe37e6113c7210fccfd26e31467f2b6a21a733bd47d9d721d2\e[0m \e[3mRevert of commits:\e[0m"
    end
  end

  describe "short format" do
    test "commit" do
      commit = commit(message: "First commit\nwith description")

      assert CommitFormatter.format(commit, :short) ==
               """
               \e[33mcommit fc376678c4decae97dda5fd4ecf174d5f51c4a07fb26220b6e73719f04f63f0b\e[0m
               Author: John Doe <john.doe@example.com>

               First commit
               """
    end

    test "commit with speech act without speaker" do
      assert commit(
               message: "First commit\nwith description",
               speech_act: speech_act(speaker: nil)
             )
             |> CommitFormatter.format(:short) ==
               """
               \e[33mcommit fc376678c4decae97dda5fd4ecf174d5f51c4a07fb26220b6e73719f04f63f0b\e[0m
               Source: <http://example.com/test/dataset>

               First commit
               """
    end

    test "revert" do
      assert CommitFormatter.format(revert(), :short) ==
               """
               \e[33mcommit 0f6be19cfb2b86fe37e6113c7210fccfd26e31467f2b6a21a733bd47d9d721d2\e[0m
               RevertBase:   commit-root

               Revert of commits:
               """

      commits = commit_history()

      assert revert(commits: Enum.slice(commits, 1..1))
             |> CommitFormatter.format(:short) ==
               """
               \e[33mcommit 943416c00ba537b0de9e7189cfa58627178e31ae7b8ee185b167a2f441611459\e[0m
               RevertTarget: 23d9efcfebbde0367d707dcaf3d6f7ef7691db6ff6c0f11b3738e65badff270f

               Revert of commits:
               """

      assert revert(commits: Enum.slice(commits, 1..2))
             |> CommitFormatter.format(:short) ==
               """
               \e[33mcommit 75506fe4bfd5ec56cdba81d484aea8bf62640a2932f0bbaa686e3b4441ffc00a\e[0m
               RevertBase:   commit-root
               RevertTarget: 23d9efcfebbde0367d707dcaf3d6f7ef7691db6ff6c0f11b3738e65badff270f

               Revert of commits:
               """
    end
  end

  describe "medium format" do
    test "commit" do
      commit = commit(message: "First commit\nwith description")

      assert CommitFormatter.format(commit, :medium) ==
               """
               \e[33mcommit fc376678c4decae97dda5fd4ecf174d5f51c4a07fb26220b6e73719f04f63f0b\e[0m
               Source: <http://example.com/test/dataset>
               Author: John Doe <john.doe@example.com>
               Date:   Fri May 26 13:02:02 2023 +0000

               First commit
               with description
               """
    end

    test "commit with speech act without speaker or source" do
      assert commit(
               message: "First commit\nwith description",
               speech_act: speech_act(speaker: nil)
             )
             |> CommitFormatter.format(:medium) ==
               """
               \e[33mcommit fc376678c4decae97dda5fd4ecf174d5f51c4a07fb26220b6e73719f04f63f0b\e[0m
               Source: <http://example.com/test/dataset>
               Date:   Fri May 26 13:02:02 2023 +0000

               First commit
               with description
               """

      assert commit(
               message: "First commit\nwith description",
               speech_act: speech_act(data_source: nil)
             )
             |> CommitFormatter.format(:medium) ==
               """
               \e[33mcommit fc376678c4decae97dda5fd4ecf174d5f51c4a07fb26220b6e73719f04f63f0b\e[0m
               Author: John Doe <john.doe@example.com>
               Date:   Fri May 26 13:02:02 2023 +0000

               First commit
               with description
               """
    end

    test "revert" do
      [third, second, first] = commits = commit_history()

      assert revert(commits: Enum.slice(commits, 0..1))
             |> CommitFormatter.format(:medium) ==
               """
               \e[33mcommit 4e97d6e2faef8698f736e1d4264894b9eacf05c4e3f4653d795649c8d1869c3a\e[0m
               RevertBase:   #{hash_from_iri(first.__id__)}
               RevertTarget: #{hash_from_iri(third.__id__)}
               Date:         Fri May 26 13:02:02 2023 +0000

               Revert of commits:

               - #{hash_from_iri(third.__id__)}
               - #{hash_from_iri(second.__id__)}

               """
    end
  end

  describe "full format" do
    test "commit" do
      commit = commit(message: "First commit\nwith description")

      assert CommitFormatter.format(commit, :full) ==
               """
               \e[33mcommit fc376678c4decae97dda5fd4ecf174d5f51c4a07fb26220b6e73719f04f63f0b\e[0m
               Source:     <http://example.com/test/dataset>
               Author:     John Doe <john.doe@example.com>
               AuthorDate: Fri May 26 13:02:02 2023 +0000
               Commit:     John Doe <john.doe@example.com>
               CommitDate: Fri May 26 13:02:02 2023 +0000

               First commit
               with description
               """
    end

    test "flat agents" do
      assert commit(
               committer: id(:agent),
               speech_act: speech_act(speaker: id(:agent))
             )
             |> CommitFormatter.format(:full) =~
               """
               \e[33mcommit a4f334cc9ba50825b099ed045a9f86b9dd8b845e90cfafdec2940889ae35136d\e[0m
               Source:     <http://example.com/test/dataset>
               Author:     <http://example.com/Agent>
               AuthorDate: Fri May 26 13:02:02 2023 +0000
               Commit:     <http://example.com/Agent>
               CommitDate: Fri May 26 13:02:02 2023 +0000

               Test commit
               """
    end

    test "commit with speech act without speaker or source" do
      assert commit(
               message: "First commit\nwith description",
               speech_act: speech_act(speaker: nil)
             )
             |> CommitFormatter.format(:full) ==
               """
               \e[33mcommit fc376678c4decae97dda5fd4ecf174d5f51c4a07fb26220b6e73719f04f63f0b\e[0m
               Source:     <http://example.com/test/dataset>
               Author:     -
               AuthorDate: Fri May 26 13:02:02 2023 +0000
               Commit:     John Doe <john.doe@example.com>
               CommitDate: Fri May 26 13:02:02 2023 +0000

               First commit
               with description
               """

      assert commit(
               message: "First commit\nwith description",
               speech_act: speech_act(data_source: nil)
             )
             |> CommitFormatter.format(:full) ==
               """
               \e[33mcommit fc376678c4decae97dda5fd4ecf174d5f51c4a07fb26220b6e73719f04f63f0b\e[0m
               Source:     -
               Author:     John Doe <john.doe@example.com>
               AuthorDate: Fri May 26 13:02:02 2023 +0000
               Commit:     John Doe <john.doe@example.com>
               CommitDate: Fri May 26 13:02:02 2023 +0000

               First commit
               with description
               """
    end

    test "revert" do
      [_third, second, first] = commits = commit_history()

      assert revert(commits: Enum.slice(commits, 1..2))
             |> CommitFormatter.format(:full) ==
               """
               \e[33mcommit 75506fe4bfd5ec56cdba81d484aea8bf62640a2932f0bbaa686e3b4441ffc00a\e[0m
               RevertBase:   commit-root
               RevertTarget: #{hash_from_iri(second.__id__)}
               Commit:       John Doe <john.doe@example.com>
               CommitDate:   Fri May 26 13:02:02 2023 +0000

               Revert of commits:

               - #{hash_from_iri(second.__id__)}
               - #{hash_from_iri(first.__id__)}

               """
    end
  end

  describe "raw format" do
    test "commit" do
      commit = commit(message: "First commit\nwith description")

      assert CommitFormatter.format(commit, :raw) ==
               """
               \e[33mcommit fc376678c4decae97dda5fd4ecf174d5f51c4a07fb26220b6e73719f04f63f0b\e[0m
               add ae04b9c2c1bfa7cf292a17851ecb1451e0d649dd9e8f76cb32b4b32ddae82d1d
               remove 6bfcd892d7b6be60628af5fbd85159a8ef2787ae726675fe502230c9338a4604
               committer <http://example.com/Agent/john_doe> 1685106122 +0000

               First commit
               with description
               """
    end

    test "revert" do
      assert CommitFormatter.format(revert(), :raw) ==
               """
               \e[33mcommit 0f6be19cfb2b86fe37e6113c7210fccfd26e31467f2b6a21a733bd47d9d721d2\e[0m
               add ae04b9c2c1bfa7cf292a17851ecb1451e0d649dd9e8f76cb32b4b32ddae82d1d
               remove 6bfcd892d7b6be60628af5fbd85159a8ef2787ae726675fe502230c9338a4604
               committer <http://example.com/Agent/john_doe> 1685106122 +0000

               Revert of commits:

               - af0f05affbb433c0d2e881712909aafc2664c8d42b2d74951f026db32e653417

               """
    end
  end

  defp commit_history() do
    commits([
      [
        add: graph(1),
        message: "Initial commit"
      ],
      [
        add: graph(2),
        remove: graph(1),
        committer: agent(:agent_jane),
        message: "Second commit"
      ],
      [
        update: graph(3)
      ]
    ])
  end
end
