defmodule Ontogen.Local.RepoTest do
  use Ontogen.Store.Test.Case

  doctest Ontogen.Local.Repo
  alias Ontogen.Local.Repo
  alias Ontogen.Commands.CreateRepo

  import ExUnit.CaptureIO

  describe "init" do
    test "when no repo specified" do
      assert capture_io(fn -> start_supervised(Repo) end) =~
               "Repo not specified"

      assert Repo.status() == :no_repo
      assert Repo.repository() == nil
      assert Repo.dataset() == nil
      assert Repo.prov_graph() == nil
    end

    test "when the repo does not exist" do
      assert capture_io(fn -> start_supervised({Repo, [repo: id(:repo)]}) end) =~
               "Repo not found"

      assert Repo.status() == :no_repo
      assert Repo.repository() == nil
      assert Repo.dataset() == nil
      assert Repo.prov_graph() == nil
    end

    test "when the repo does exist" do
      {:ok, repository} = CreateRepo.call(Local.store(), repository())

      assert capture_io(fn -> start_supervised({Repo, [repo: repository.__id__]}) end) =~
               "Connected to repo #{id(:repository)}"

      assert Repo.status() == :ready
      assert Repo.repository() == repository
      assert Repo.dataset() == repository.dataset
      assert Repo.prov_graph() == repository.prov_graph
    end
  end

  describe "create_repo/3" do
    test "when the repo does not exist" do
      capture_io(fn -> {:ok, _} = start_supervised(Repo) end)

      repository = repository()

      assert Repo.create(repository) == {:ok, repository}

      assert Repo.status() == :ready
      assert Repo.repository() == repository
      assert Repo.dataset() == repository.dataset
      assert Repo.prov_graph() == repository.prov_graph
    end

    test "when the repo already exists" do
      capture_io(fn -> {:ok, _} = start_supervised({Repo, [repo: id(:repository)]}) end)

      {:ok, _} = CreateRepo.call(Local.store(), repository())

      assert Repo.create(repository()) == {:error, :repo_already_exists}
    end

    test "when the repo is already connected" do
      {:ok, _} = CreateRepo.call(Local.store(), repository())

      capture_io(fn -> {:ok, _} = start_supervised({Repo, [repo: id(:repository)]}) end)

      assert Repo.create(repository()) == {:error, :repo_already_connected}
    end
  end
end
