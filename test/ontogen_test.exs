defmodule OntogenTest do
  use Ontogen.ServiceCase

  doctest Ontogen

  alias Ontogen.Repository.{SetupError, NotSetupError}

  describe "booted, i.e. initialized" do
    @tag config: [setup: false]
    test "when the service is not setup, i.e. the repo does not exist" do
      assert Ontogen.status() == :not_setup

      assert {:error, %NotSetupError{operation: %Ontogen.Operations.RepositoryQuery{}}} =
               Ontogen.repository(stored: true)
    end

    test "when the service is setup" do
      assert Ontogen.status() == :ready
      assert Ontogen.repository(stored: true) == {:ok, ready_service().repository}
      assert Ontogen.dataset_info() == Ontogen.Config.dataset!()
      assert Ontogen.history_info() == Ontogen.Config.history!()
    end
  end

  describe "setup/0" do
    @tag config: [setup: false]
    test "when the service is not setup, i.e. the repo does not exist" do
      assert Ontogen.status() == :not_setup

      ready_service = ready_service()

      assert Ontogen.setup() == {:ok, ready_service}

      assert Ontogen.status() == :ready
      assert Ontogen.repository(stored: true) == {:ok, ready_service.repository}
      assert Ontogen.dataset_info() == Ontogen.Config.dataset!()
      assert Ontogen.history_info() == Ontogen.Config.history!()
    end

    test "when the service is already setup" do
      assert Ontogen.setup() ==
               {:error,
                SetupError.exception(
                  service: ready_service(),
                  reason: :already_setup
                )}
    end
  end
end
