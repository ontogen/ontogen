defmodule Ontogen.CommitTest do
  use Ontogen.Test.Case

  doctest Ontogen.Commit

  alias Ontogen.Commit

  describe "new/1" do
    test "with all required attributes" do
      message = "Initial commit"

      assert {:ok, %Commit{} = commit} =
               Commit.new(
                 insertion: expression(),
                 committer: agent(),
                 message: message,
                 ended_at: datetime()
               )

      assert %IRI{value: "urn:hash::sha256:" <> _} = commit.__id__

      assert commit.insertion == expression()
      assert commit.committer == agent()
      assert commit.message == message
      assert commit.ended_at == datetime()
      refute commit.parent
      assert Commit.root?(commit)
    end
  end
end
