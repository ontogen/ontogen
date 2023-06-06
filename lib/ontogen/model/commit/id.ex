defmodule Ontogen.Commit.Id do
  import Ontogen.IdUtils

  alias Ontogen.Commit

  def generate(%Commit{} = commit) do
    {:ok, content_hash_iri(:commit, &content/1, [commit])}
  end

  def content(commit) do
    [
      if(commit.parent, do: "parent #{to_hash(commit.parent)}"),
      if(commit.insertion, do: "insertion #{to_hash(commit.insertion)}"),
      if(commit.deletion, do: "deletion #{to_hash(commit.deletion)}"),
      "committer <#{to_id(commit.committer)}> #{to_timestamp(commit.ended_at)}",
      "\n",
      commit.message
    ]
    |> Enum.reject(&is_nil/1)
    |> Enum.join("\n")
  end
end
