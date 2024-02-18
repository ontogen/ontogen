defmodule Ontogen.Changeset.Action do
  # during a Changeset.merge these actions will be applied in the reverse order defined here
  @fields [:insert, :update, :replace, :delete, :overwrite]

  @doc """
  Returns a list of the action fields.

  ## Example

      iex> Ontogen.Changeset.Action.fields()
      #{inspect(@fields)}

  """
  @spec fields :: list(atom)
  def fields, do: @fields

  @doc """
  Returns `true` if `map` contains at least on action field; otherwise returns `false`.

  Note, that a single `:overwrite` doesn't count.

  ## Example

      iex> is_action_map(:insert)
      false

      iex> is_action_map(%{foo: []})
      false

      iex> is_action_map(%{insert: []})
      true

      iex> is_action_map(%{delete: [], replace: []})
      true

      iex> is_action_map(%{overwrite: []})
      false

      iex> is_action_map(%Ontogen.Commit{})
      true

      iex> is_action_map(%Ontogen.SpeechAct{})
      true

      iex> is_action_map(%Ontogen.Commit.Changeset{})
      true

      iex> is_action_map(%Ontogen.SpeechAct.Changeset{})
      true
  """
  defguard is_action_map(map)
           when is_map(map) and
                  (is_map_key(map, :insert) or
                     is_map_key(map, :delete) or
                     is_map_key(map, :update) or
                     is_map_key(map, :replace))

  @doc """
  Extracts a map of actions from the given keywords and returns it with the remaining unprocessed keywords.
  """
  def extract(args) do
    {insert, args} = Keyword.pop(args, :insert)
    {delete, args} = Keyword.pop(args, :delete)
    {update, args} = Keyword.pop(args, :update)
    {replace, args} = Keyword.pop(args, :replace)
    {overwrite, args} = Keyword.pop(args, :overwrite)

    {
      %{
        insert: insert,
        delete: delete,
        update: update,
        replace: replace,
        overwrite: overwrite
      },
      args
    }
  end

  @doc """
  Checks if a changeset structure contains any changes.
  """
  def empty?(%{insert: nil, delete: nil, update: nil, replace: nil, overwrite: nil}),
    do: true

  def empty?(%{insert: _, delete: _, update: _, replace: _, overwrite: _}), do: false
  def empty?(%{insert: nil, delete: nil, update: nil, replace: nil}), do: true
  def empty?(%{insert: _, delete: _, update: _, replace: _}), do: false

  def empty?(args) when is_list(args) do
    args |> Keyword.take(fields()) |> Enum.empty?()
  end

  def sort_changes(changes) when is_list(changes) do
    @fields
    |> Enum.reduce_while({[], changes}, fn
      _, {_, []} = result ->
        {:halt, result}

      action, {sorted, remaining} ->
        {values, remaining} = Keyword.pop_values(remaining, action)
        {:cont, {Enum.map(values, &{action, &1}) ++ sorted, remaining}}
    end)
    |> case do
      {sorted, []} -> sorted
      {_, invalid} -> raise ArgumentError, "invalid change actions: #{Keyword.keys(invalid)}"
    end
  end
end
