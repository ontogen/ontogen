defmodule Ontogen.Bog.ReferencableTest do
  use Ontogen.BogCase

  doctest Ontogen.Bog.Referencable

  alias Ontogen.Bog.{Referencable, NotMinted}

  describe "load_from_rdf/2" do
    test "valid referencable" do
      graph =
        """
        #{RDF.turtle_prefixes(ex: EX, bog: Bog)}

        _:example
          a ex:TestReferencable
          ; bog:ref "foo"
          ; ex:foo 42
        .
        """
        |> Turtle.read_string!()

      assert Referencable.load_from_rdf(graph, ~B<example>) ==
               {:ok,
                %Ontogen.Bog.Referencable{
                  __additional_statements__: %{
                    ~I<http://example.com/foo> => %{RDF.XSD.Integer.new(42) => nil},
                    ~I<http://www.w3.org/1999/02/22-rdf-syntax-ns#type> => %{
                      ~I<https://w3id.org/bog#Referencable> => nil
                    }
                  },
                  __id__: ~B<example>,
                  __class__: ~I<http://example.com/TestReferencable>,
                  __ref__: "foo",
                  __hash__: nil
                }}
    end

    test "with multiple classes for the same subject are defined" do
      graph =
        """
        #{RDF.turtle_prefixes(ex: EX, bog: Bog, foaf: FOAF)}

        _:example
          a ex:TestReferencable, foaf:Agent, ex:Class
          ; bog:ref "foo"
          ; ex:foo 42
        .
        """
        |> Turtle.read_string!()

      assert Referencable.load_from_rdf(graph, ~B<example>) ==
               {:ok,
                %Ontogen.Bog.Referencable{
                  __additional_statements__: %{
                    ~I<http://example.com/foo> => %{RDF.XSD.Integer.new(42) => nil},
                    ~I<http://www.w3.org/1999/02/22-rdf-syntax-ns#type> => %{
                      ~I<https://w3id.org/bog#Referencable> => nil
                    }
                  },
                  __id__: ~B<example>,
                  __class__: ~I<http://example.com/TestReferencable>,
                  __ref__: "foo",
                  __hash__: nil
                }}
    end

    test "when multiple refs for the same subject are defined" do
      graph =
        """
        #{RDF.turtle_prefixes(ex: EX, bog: Bog)}

        _:example
          a ex:TestReferencable
          ; bog:ref "foo", "bar"
          ; ex:foo 42
        .
        """
        |> Turtle.read_string!()

      assert {:error, %Grax.ValidationError{errors: [__ref__: _]}} =
               Referencable.load_from_rdf(graph, ~B<example>)
    end
  end

  describe "deref_id/1" do
    test "when the id is not minted" do
      assert {:error, %NotMinted{referencable: %{__ref__: "testReferencable"}}} =
               TestReferencable.deref_id("testReferencable")

      refute TestReferencable.deref_id!("testReferencable")
    end

    test "when the id is minted" do
      assert {:ok, %Referencable{__id__: %IRI{value: "urn:uuid:" <> _} = id}} =
               TestReferencable.mint("testReferencable")

      assert ^id = TestReferencable.deref_id!("testReferencable")
    end
  end

  describe "deref/1" do
    test "when the id is not minted" do
      assert {:error, %NotMinted{referencable: %{__ref__: "testReferencable"}}} =
               TestReferencable.deref("testReferencable", empty_graph())

      refute TestReferencable.deref!("testReferencable", empty_graph())
    end

    test "when the id is minted, but not described in the graph" do
      assert {:ok, %Referencable{}} = TestReferencable.mint("testReferencable")

      assert (test = TestReferencable.deref!("testReferencable", empty_graph())) ==
               TestReferencable.build!(TestReferencable.deref_id!("testReferencable"))

      assert ^test = TestReferencable.deref!("testReferencable", empty_graph())
    end

    test "when the id is minted and described in the graph" do
      assert {:ok, %Referencable{}} = TestReferencable.mint("testReferencable")

      assert (test = TestReferencable.deref!("testReferencable", test_graph())) ==
               TestReferencable.build!(TestReferencable.deref_id!("testReferencable"),
                 foo: "test"
               )

      assert ^test = TestReferencable.deref!("testReferencable", test_graph())
    end
  end

  describe "this/0" do
    test "when the id is not minted" do
      assert {:error, %NotMinted{referencable: %{__ref__: "testReferencable"}}} =
               TestReferencable.this(empty_graph())

      refute TestReferencable.this!("testReferencable", empty_graph())
    end

    test "when the id is minted and described in the graph" do
      assert {:ok, %Referencable{}} = TestReferencable.mint("testReferencable")

      assert %TestReferencable{} = test = TestReferencable.this!(test_graph())

      assert TestReferencable.this!(test_graph()) ==
               TestReferencable.deref!("testReferencable", test_graph())

      assert ^test = TestReferencable.this!(test_graph())
    end
  end

  describe "this_id/0" do
    test "when the id is not minted" do
      assert {:error, %NotMinted{referencable: %{__ref__: "testReferencable"}}} =
               TestReferencable.this_id()

      refute TestReferencable.this_id!()
    end

    test "when the id is minted" do
      assert {:ok, %Referencable{}} = TestReferencable.mint(:this)

      assert {:ok, %IRI{value: "urn:uuid:" <> _} = id} = TestReferencable.this_id()
      assert ^id = TestReferencable.this_id!()
      assert TestReferencable.this_id!() == TestReferencable.deref_id!("testReferencable")
    end
  end

  test "this_ref/0" do
    assert TestReferencable.this_ref() == "testReferencable"
    assert Ontogen.Service.this_ref() == "service"
    assert Ontogen.Store.this_ref() == "store"
    assert Ontogen.Repository.this_ref() == "repository"
    assert Ontogen.Dataset.this_ref() == "dataset"
    assert Ontogen.ProvGraph.this_ref() == "provGraph"
    assert Ontogen.Agent.this_ref() == "agent"
  end

  test "this_ref/1" do
    assert Referencable.this_ref(~I<https://w3id.org/ontogen#Service>) == "service"
    assert Referencable.this_ref(Ontogen.Agent) == "agent"
    assert Referencable.this_ref(FOAF.Agent) == "agent"

    assert_raise RuntimeError, fn ->
      Referencable.this_ref(~I<https://w3id.org/ontogen#>)
    end

    assert_raise RuntimeError, fn ->
      Referencable.this_ref(~I<https://w3id.org/>)
    end

    assert_raise RuntimeError, fn ->
      Referencable.this_ref(FOAF.mbox())
    end
  end

  describe "type?/1" do
    test "with a module" do
      assert Ontogen.Bog.Referencable.type?(Ontogen.Service)
      assert Ontogen.Bog.Referencable.type?(Ontogen.Store)
      assert Ontogen.Bog.Referencable.type?(Ontogen.Repository)
      assert Ontogen.Bog.Referencable.type?(Ontogen.Dataset)
      assert Ontogen.Bog.Referencable.type?(Ontogen.ProvGraph)
      refute Ontogen.Bog.Referencable.type?(Ontogen.SpeechAct)
      refute Ontogen.Bog.Referencable.type?(FOAF.Agent)
      refute Ontogen.Bog.Referencable.type?(NotExisting)
    end

    test "with an IRI" do
      assert Ontogen.NS.Og.Service |> RDF.iri() |> Ontogen.Bog.Referencable.type?()
      assert Ontogen.NS.Og.Dataset |> RDF.iri() |> Ontogen.Bog.Referencable.type?()
      refute Ontogen.NS.Og.SpeechAct |> RDF.iri() |> Ontogen.Bog.Referencable.type?()
      refute FOAF.Agent |> RDF.iri() |> Ontogen.Bog.Referencable.type?()
      refute EX.Foo |> RDF.iri() |> Ontogen.Bog.Referencable.type?()
    end
  end

  def test_graph do
    (TestReferencable.this_id!() || raise("TestReferencable not minted yet"))
    |> EX.foo("test")
    |> RDF.graph()
  end
end
