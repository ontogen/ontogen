defmodule Ontogen.Commit.Id do
  @moduledoc false

  import Ontogen.IdUtils

  alias Ontogen.Commit

  def generate(%Commit{} = commit) do
    content_hash_iri(:commit, &content/1, [commit])
  end

  def content(commit) do
    [
      unless(Commit.root?(commit), do: "parent #{to_hash(commit.parent)}\n"),
      if(commit.add, do: "add #{to_hash(commit.add)}\n"),
      if(commit.update, do: "update #{to_hash(commit.update)}\n"),
      if(commit.replace, do: "replace #{to_hash(commit.replace)}\n"),
      if(commit.remove, do: "remove #{to_hash(commit.remove)}\n"),
      if(commit.overwrite, do: "overwrite #{to_hash(commit.overwrite)}\n"),
      "committer <#{to_id(commit.committer)}> #{to_timestamp(commit.time)}\n",
      "\n",
      commit.message
    ]
    |> Enum.reject(&is_nil/1)
    |> IO.iodata_to_binary()
  end
end
