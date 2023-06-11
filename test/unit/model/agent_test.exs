defmodule Ontogen.AgentTest do
  use Ontogen.Test.Case

  doctest Ontogen.Agent
  alias Ontogen.Agent

  test "can be loaded from RDF with just an foaf:mbox" do
    assert """
           @prefix foaf: <http://xmlns.com/foaf/0.1/> .

           <http://example.com/Agent/john_doe>
             foaf:name "John Doe" ;
             foaf:mbox <mailto:john.doe@example.com> .
           """
           |> RDF.Turtle.read_string!()
           |> Agent.load(~I<http://example.com/Agent/john_doe>) ==
             {:ok,
              %Agent{
                __additional_statements__: %{
                  ~I<http://www.w3.org/1999/02/22-rdf-syntax-ns#type> => %{
                    ~I<https://w3id.org/ontogen#Agent> => nil
                  },
                  ~I<http://xmlns.com/foaf/0.1/mbox> => %{~I<mailto:john.doe@example.com> => nil}
                },
                __id__: ~I<http://example.com/Agent/john_doe>,
                email: ~I<mailto:john.doe@example.com>,
                name: "John Doe"
              }}
  end
end
