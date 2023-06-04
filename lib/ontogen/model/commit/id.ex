defmodule Ontogen.Commit.Id do
  import Ontogen.IdUtils

  alias Ontogen.Commit

  def generate(%Commit{} = commit) do
    content_hash_iri(:commit, &content/1, [commit])
  end

  def content(commit) do
    [
      if(commit.parent, do: "parent #{to_id(commit.parent)}"),
      if(commit.insertion, do: "insertion #{to_id(commit.insertion)}"),
      if(commit.deletion, do: "deletion #{to_id(commit.deletion)}"),
      "committer <#{to_id(commit.committer)}> #{to_timestamp(commit.ended_at)}",
      "\n",
      commit.message
    ]
    |> Enum.reject(&is_nil/1)
    |> Enum.join("\n")
  end
end
