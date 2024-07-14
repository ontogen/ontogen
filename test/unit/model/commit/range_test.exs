defmodule Ontogen.Commit.RangeTest do
  use OntogenCase

  doctest Ontogen.Commit.Range

  alias Ontogen.{Commit, InvalidCommitRangeError}

  @valid_hash "0db70c636f5b2e0a8271fc94ad9319ae5e2645fc68008a3d1cd6436a0126efd5"
  @hash_iri RDF.iri("urn:hash::sha256:#{@valid_hash}")

  describe "parse/2" do
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

    test "just a commit ref without opts" do
      assert Commit.Range.parse!("head~2") ==
               Commit.Range.parse!("head~2", single_ref_as: :ref)
    end

    test "just a commit ref with single_ref_as: :ref" do
      assert Commit.Range.parse!("head", single_ref_as: :ref) ==
               %Commit.Ref{ref: :head, offset: 0}

      assert Commit.Range.parse!("head~2", single_ref_as: :ref) ==
               %Commit.Ref{ref: :head, offset: 2}

      assert Commit.Range.parse!(@valid_hash, single_ref_as: :ref) ==
               @hash_iri

      assert Commit.Range.parse!(@valid_hash <> "~1", single_ref_as: :ref) ==
               %Commit.Ref{ref: @hash_iri, offset: 1}
    end

    test "just a commit ref with single_ref_as: :single_commit_range" do
      assert Commit.Range.parse!("head", single_ref_as: :single_commit_range) ==
               %Commit.Range{
                 base: %Commit.Ref{ref: :head, offset: 1},
                 target: :head
               }

      assert Commit.Range.parse!("head~2", single_ref_as: :single_commit_range) ==
               %Commit.Range{
                 base: %Commit.Ref{ref: :head, offset: 3},
                 target: %Commit.Ref{ref: :head, offset: 2}
               }

      assert Commit.Range.parse!(@valid_hash, single_ref_as: :single_commit_range) ==
               %Commit.Range{
                 base: %Commit.Ref{ref: @hash_iri, offset: 1},
                 target: @hash_iri
               }

      assert Commit.Range.parse!(@valid_hash <> "~1", single_ref_as: :single_commit_range) ==
               %Commit.Range{
                 base: %Commit.Ref{ref: @hash_iri, offset: 2},
                 target: %Commit.Ref{ref: @hash_iri, offset: 1}
               }
    end

    test "just a commit ref with single_ref_as: :base" do
      assert Commit.Range.parse!("head~2", single_ref_as: :base) ==
               %Commit.Range{
                 base: %Commit.Ref{ref: :head, offset: 2},
                 target: :head
               }

      assert Commit.Range.parse!(@valid_hash, single_ref_as: :base) ==
               %Commit.Range{
                 base: @hash_iri,
                 target: :head
               }

      assert Commit.Range.parse!(@valid_hash <> "~1", single_ref_as: :base) ==
               %Commit.Range{
                 base: %Commit.Ref{ref: @hash_iri, offset: 1},
                 target: :head
               }
    end

    test "just a commit ref with single_ref_as: :target" do
      assert Commit.Range.parse!("head~2", single_ref_as: :target) ==
               %Commit.Range{
                 base: Commit.root(),
                 target: %Commit.Ref{ref: :head, offset: 2}
               }

      assert Commit.Range.parse!(@valid_hash, single_ref_as: :target) ==
               %Commit.Range{
                 base: Commit.root(),
                 target: @hash_iri
               }

      assert Commit.Range.parse!(@valid_hash <> "~1", single_ref_as: :target) ==
               %Commit.Range{
                 base: Commit.root(),
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
