defmodule Ontogen.Commit.RefTest do
  use OntogenCase

  doctest Ontogen.Commit.Ref

  alias Ontogen.Commit.Ref
  alias Ontogen.InvalidCommitRefError

  @valid_hash "0db70c636f5b2e0a8271fc94ad9319ae5e2645fc68008a3d1cd6436a0126efd5"
  @hash_iri RDF.iri("urn:hash::sha256:#{@valid_hash}")

  describe "parse/1" do
    test "full commit hash" do
      assert Ref.parse(@valid_hash) == {:ok, @hash_iri}

      assert Ref.parse("0DB70c636f5b2e0a8271fc94ad9319ae5e2645fc68008a3d1cd6436a0126efd5") ==
               {:ok, @hash_iri}
    end

    test "valid hash IRI" do
      assert Ref.parse(@hash_iri.value) == {:ok, @hash_iri}

      assert Ref.parse(
               "Urn:Hash::Sha256:0DB70c636f5b2e0a8271fc94ad9319ae5e2645fc68008a3d1cd6436a0126efd5"
             ) ==
               {:ok, @hash_iri}
    end

    test "hash-relative" do
      assert Ref.parse("#{@valid_hash}~1") == {:ok, %Ref{ref: @hash_iri, offset: 1}}
      assert Ref.parse("#{@valid_hash}~2") == {:ok, %Ref{ref: @hash_iri, offset: 2}}
    end

    test "resolvable hash-relative" do
      assert Ref.parse("#{@valid_hash}~0") == {:ok, @hash_iri}
    end

    test "head" do
      assert Ref.parse("head") == {:ok, %Ref{ref: :head, offset: 0}}
      assert Ref.parse("HEAD") == {:ok, %Ref{ref: :head, offset: 0}}
    end

    test "head-relative" do
      assert Ref.parse("head~0") == {:ok, %Ref{ref: :head, offset: 0}}
      assert Ref.parse("HEAD~1") == {:ok, %Ref{ref: :head, offset: 1}}
      assert Ref.parse("Head~2") == {:ok, %Ref{ref: :head, offset: 2}}
    end

    test "invalid head-relative" do
      assert Ref.parse("head~1.5") ==
               {:error, InvalidCommitRefError.exception(value: "invalid commit ref: head~1.5")}

      assert Ref.parse("head~foo") ==
               {:error, InvalidCommitRefError.exception(value: "invalid commit ref: head~foo")}

      assert Ref.parse("head~f1") ==
               {:error, InvalidCommitRefError.exception(value: "invalid commit ref: head~f1")}

      assert Ref.parse("head~1f") ==
               {:error, InvalidCommitRefError.exception(value: "invalid commit ref: head~1f")}
    end

    test "invalid hash IRI" do
      assert Ref.parse("urn:hash::sha256:foo") ==
               {:error, InvalidCommitRefError.exception(value: "foo")}
    end
  end

  test "to_string/1" do
    assert to_string(%Ref{ref: :head, offset: 0}) == "HEAD"
    assert to_string(%Ref{ref: :head, offset: 1}) == "HEAD~1"
  end
end
