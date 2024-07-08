defmodule Ontogen.Operations.SetupCommandTest do
  use Ontogen.StoreCase

  doctest Ontogen.Operations.SetupCommand

  alias Ontogen.Operations.{SetupCommand, RepositoryQuery}
  alias Ontogen.{Repository, Config}
  alias Ontogen.Repository.{NotSetupError, SetupError}

  test "creates graphs for the configured repo" do
    service = Config.service!()
    assert {:error, %NotSetupError{}} = RepositoryQuery.call(service)

    assert {:ok, %SetupCommand{} = setup_command} = SetupCommand.new()

    assert {:error, %NotSetupError{}} = RepositoryQuery.call(service)

    assert SetupCommand.call(setup_command, service) == {:ok, ready_service()}

    assert RepositoryQuery.call(service) == Repository.set_head(service.repository, :root)
  end

  test "when the repo already exists" do
    service = Config.service!()
    assert {:error, %NotSetupError{}} = RepositoryQuery.call(service)

    assert {:ok, %SetupCommand{} = setup_command} = SetupCommand.new()

    assert {:error, %NotSetupError{}} = RepositoryQuery.call(service)

    assert SetupCommand.call(setup_command, service) == {:ok, ready_service()}

    assert SetupCommand.call(setup_command, service) ==
             {:error, SetupError.exception(service: service, reason: :already_setup)}
  end
end
