defmodule Ontogen.Bog.PrecompilerTest do
  use Ontogen.BogCase

  doctest Ontogen.Bog.Precompiler

  alias Ontogen.Bog.{Precompiler, Referencable}

  alias RDF.Description

  alias Uniq.UUID

  test "resolving blank node descriptions" do
    prefixes = RDF.turtle_prefixes(ex: EX, bog: Bog, void: "http://rdfs.org/ns/void#")
    ref = "foo"
    salt_file_path = Referencable.Id.salt_path(ref)

    refute File.exists?(salt_file_path)

    bog_config_graph =
      """
      #{prefixes}

      [
        a ex:TestReferencable
        ; bog:ref "#{ref}"
        ; void:triples 42
      ].
      """
      |> Turtle.read_string!()

    # assert Precompiler.precompile(bog_config_graph, debug: true) |> dbg
    assert {:ok, %Graph{} = precompiled_graph} = Precompiler.precompile(bog_config_graph)

    assert File.exists?(salt_file_path)
    salt = File.read!(salt_file_path)

    assert [precompiled_description] = Graph.descriptions(precompiled_graph)

    assert [%Literal{literal: %XSD.String{value: hash}}] =
             precompiled_description[Bog.refHash()]

    assert hash == hkdf_hash(class: EX.TestReferencable, salt: salt)

    assert %IRI{value: "urn:uuid:" <> uuid} = precompiled_description.subject
    assert uuid == UUID.uuid5(Ontogen.IdSpec.bog_uuid_namespace(), hash)

    assert precompiled_graph ==
             """
             #{prefixes}

             <urn:uuid:#{uuid}> a ex:TestReferencable
               ; bog:ref "#{ref}"
               ; bog:refHash "#{hash}"
               ; void:triples 42
             .
             """
             |> Turtle.read_string!()

    assert {:ok, ^precompiled_graph} = Precompiler.precompile(bog_config_graph)
    assert {:ok, ^precompiled_graph} = Precompiler.precompile(bog_config_graph)
  end

  test "resolving referencable object blank node description" do
    prefixes =
      RDF.turtle_prefixes(
        bog: Bog,
        og: Og,
        ex: EX,
        foaf: FOAF
      )

    bog_config_graph =
      """
      #{prefixes}

      [
        a ex:TestReferencable
        ; bog:ref "foo"
        ; foaf:maker [ a og:Agent
            ; bog:ref "user"
            ; foaf:name "John Doe"
          ]
      ].

      [
        a og:Agent
        ; bog:ref "user"
        ; foaf:firstName "John"
        ; foaf:lastName "Doe"
      ].
      """
      |> Turtle.read_string!()

    assert {:ok, %Graph{} = graph} = Precompiler.precompile(bog_config_graph)

    ref_indexed_graph = ref_indexed(graph)
    foo_id = ref_indexed_graph[:foo].subject
    user_id = ref_indexed_graph[:user].subject
    foo_hash = Bog.refHash(ref_indexed_graph[:foo])
    user_hash = Bog.refHash(ref_indexed_graph[:user])

    assert ref_indexed_graph == %{
             foo:
               foo_id
               |> RDF.type(EX.TestReferencable)
               |> Bog.ref("foo")
               |> Bog.refHash(foo_hash)
               |> FOAF.maker(user_id),
             user:
               user_id
               |> RDF.type(Og.Agent)
               |> Bog.ref("user")
               |> Bog.refHash(user_hash)
               |> FOAF.name("John Doe")
               |> FOAF.firstName("John")
               |> FOAF.lastName("Doe")
           }
  end

  test "resolving bog:this" do
    prefixes =
      RDF.turtle_prefixes(
        og: Og,
        bog: Bog,
        ex: EX,
        foaf: FOAF
      )

    assert """
           #{prefixes}

           [
             bog:this ex:TestReferencable
             ; foaf:maker [ bog:this og:Agent
                 ; foaf:name "John Doe"
               ]
           ].

           [
             bog:this og:Agent
             ; foaf:firstName "John"
             ; foaf:lastName "Doe"
           ].
           """
           |> Turtle.read_string!()
           |> Precompiler.precompile() ==
             """
             #{prefixes}

             [
               a ex:TestReferencable
               ; bog:ref "testReferencable"
               ; foaf:maker [ a og:Agent
                   ; bog:ref "agent"
                   ; foaf:name "John Doe"
                 ]
             ].

             [
               a og:Agent
               ; bog:ref "agent"
               ; foaf:firstName "John"
               ; foaf:lastName "Doe"
             ].
             """
             |> Turtle.read_string!()
             |> Precompiler.precompile()
  end

  test "using bog:I" do
    prefixes =
      RDF.turtle_prefixes(
        og: Og,
        bog: Bog,
        ex: EX,
        foaf: FOAF
      )

    assert """
           #{prefixes}

           bog:I
               foaf:firstName "John"
             ; foaf:lastName "Doe"
           .
           """
           |> Turtle.read_string!()
           |> Precompiler.precompile() ==
             """
             #{prefixes}

             [
               a og:Agent
               ; bog:ref "agent"
               ; foaf:firstName "John"
               ; foaf:lastName "Doe"
             ].
             """
             |> Turtle.read_string!()
             |> Precompiler.precompile()

    assert """
           #{prefixes}

           [
             a ex:TestReferencable
             ; bog:ref "testReferencable"
             ; foaf:maker bog:I
           ] .

           bog:I
               foaf:firstName "John"
             ; foaf:lastName "Doe"
           .
           """
           |> Turtle.read_string!()
           |> Precompiler.precompile() ==
             """
             #{prefixes}

             [
               a ex:TestReferencable
               ; bog:ref "testReferencable"
               ; foaf:maker [ a og:Agent
                   ; bog:ref "agent"
                 ]
             ].

             [
               a og:Agent
               ; bog:ref "agent"
               ; foaf:firstName "John"
               ; foaf:lastName "Doe"
             ].
             """
             |> Turtle.read_string!()
             |> Precompiler.precompile()
  end

  test "with non-referencable blank nodes" do
    prefixes = RDF.turtle_prefixes(ex: EX)

    turtle_config_graph =
      """
      #{prefixes}

      [
        a ex:TestReferencable
        ; ex:foo 42
      ].
      """
      |> Turtle.read_string!()

    assert {:ok, ^turtle_config_graph} = Precompiler.precompile(turtle_config_graph)
  end

  test "when multiple refs for the same subject are defined" do
    bog_config_graph =
      """
      #{RDF.turtle_prefixes(ex: EX, bog: Bog)}

      [
        a ex:TestReferencable
        ; bog:ref "foo", "bar"
      ].
      """
      |> Turtle.read_string!()

    assert {:error, %Grax.ValidationError{errors: [__ref__: _]}} =
             Precompiler.precompile(bog_config_graph)
  end

  defp ref_indexed(%Graph{} = graph), do: graph |> Graph.descriptions() |> ref_indexed()

  defp ref_indexed(descriptions) do
    Enum.reduce(descriptions, %{}, fn description, ref_index ->
      if ref = Description.first(description, Bog.ref()) do
        Map.put(ref_index, ref |> to_string() |> String.to_atom(), description)
      else
        Map.put(ref_index, nil, description)
      end
    end)
  end

  defp hkdf_hash(class: class, salt: salt) do
    :sha256
    |> HKDF.derive(
      """
      salt: #{salt}
      class: #{IRI.to_string(class)}
      """
      |> String.trim_trailing(),
      16
    )
    |> Base.encode16(case: :lower)
  end
end
