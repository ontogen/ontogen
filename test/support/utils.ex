defmodule Ontogen.TestUtils do
  import RDF.Guards

  def flatten_property(struct, [property]), do: flatten_property(struct, property)

  def flatten_property(struct, [property | rest]) do
    Map.put(struct, property, struct |> Map.get(property) |> flatten_property(rest))
  end

  def flatten_property(struct, property) do
    Map.put(struct, property, struct |> Map.get(property) |> flatten_value())
  end

  defp flatten_value(nil), do: nil
  defp flatten_value(list) when is_list(list), do: Enum.map(list, &flatten_value/1)
  defp flatten_value(%_{__id__: id}), do: id
  defp flatten_value(id) when is_rdf_resource(id), do: id
end
