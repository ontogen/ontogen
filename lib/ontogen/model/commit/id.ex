defmodule Ontogen.Commit.Id do
  import Ontogen.IdUtils

  alias Ontogen.Commit

  def generate(%Commit{} = commit) do
    content_hash_iri(:commit, &content/1, [commit])
  end

  def content(commit) do
    [
      unless(Commit.root?(commit), do: "parent #{to_hash(commit.parent)}"),
      if(commit.add, do: "add #{to_hash(commit.add)}"),
      if(commit.update, do: "update #{to_hash(commit.update)}"),
      if(commit.replace, do: "replace #{to_hash(commit.replace)}"),
      if(commit.remove, do: "remove #{to_hash(commit.remove)}"),
      if(commit.overwrite, do: "overwrite #{to_hash(commit.overwrite)}"),
      "committer <#{to_id(commit.committer)}> #{to_timestamp(commit.time)}",
      "\n",
      commit.message
    ]
    |> Enum.reject(&is_nil/1)
    |> Enum.join("\n")
  end
end
