defmodule Ontogen.Commit.RangeTest do
  use OntogenCase

  doctest Ontogen.Commit.Range

  alias Ontogen.{Commit, InvalidCommitRangeError}

  @valid_hash "0db70c636f5b2e0a8271fc94ad9319ae5e2645fc68008a3d1cd6436a0126efd5"
  @hash_iri RDF.iri("urn:hash::sha256:#{@valid_hash}")

  describe "parse/1" do
    test "valid range" do
      assert Commit.Range.parse!("head~2..head") ==
               %Commit.Range{
                 base: %Commit.Ref{ref: :head, offset: 2},
                 target: :head
               }

      assert Commit.Range.parse!("#{@valid_hash}..head~1") ==
               %Commit.Range{
                 base: @hash_iri,
                 target: %Commit.Ref{ref: :head, offset: 1}
               }

      assert Commit.Range.parse!("#{@valid_hash}~3..#{@valid_hash}~1") ==
               %Commit.Range{
                 base: %Commit.Ref{ref: @hash_iri, offset: 3},
                 target: %Commit.Ref{ref: @hash_iri, offset: 1}
               }
    end

    test "just a commit ref" do
      assert Commit.Range.parse!("head") ==
               %Commit.Ref{ref: :head, offset: 0}

      assert Commit.Range.parse!("head~2") ==
               %Commit.Ref{ref: :head, offset: 2}

      assert Commit.Range.parse!(@valid_hash) ==
               @hash_iri

      assert Commit.Range.parse!(@valid_hash <> "~1") ==
               %Commit.Ref{ref: @hash_iri, offset: 1}
    end

    test "just a commit ref with force: true" do
      assert Commit.Range.parse!("head", force: true) ==
               %Commit.Range{
                 base: %Commit.Ref{ref: :head, offset: 1},
                 target: :head
               }

      assert Commit.Range.parse!("head~2", force: true) ==
               %Commit.Range{
                 base: %Commit.Ref{ref: :head, offset: 3},
                 target: %Commit.Ref{ref: :head, offset: 2}
               }

      assert Commit.Range.parse!(@valid_hash, force: true) ==
               %Commit.Range{
                 base: %Commit.Ref{ref: @hash_iri, offset: 1},
                 target: @hash_iri
               }

      assert Commit.Range.parse!(@valid_hash <> "~1", force: true) ==
               %Commit.Range{
                 base: %Commit.Ref{ref: @hash_iri, offset: 2},
                 target: %Commit.Ref{ref: @hash_iri, offset: 1}
               }
    end

    test "invalid" do
      assert Commit.Range.parse("head..head~2") ==
               {:error, InvalidCommitRangeError.exception(reason: :head_base)}

      assert Commit.Range.parse("head~1..head~2") ==
               {:error, InvalidCommitRangeError.exception(reason: :target_before_base)}

      assert Commit.Range.parse("#{@valid_hash}~1..#{@valid_hash}~2") ==
               {:error, InvalidCommitRangeError.exception(reason: :target_before_base)}
    end
  end
end
