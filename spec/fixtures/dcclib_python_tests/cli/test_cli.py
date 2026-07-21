from click.testing import CliRunner
from dcclib_cli.cli import cli


def test_cli_smoke():
    runner = CliRunner()
    result = runner.invoke(cli, [])
    assert result.exit_code == 2
    assert "Usage:" in result.output


def test_cli_invalid_command_fails():
    runner = CliRunner()
    result = runner.invoke(cli, ["invalid"])
    assert result.exit_code == 2
    assert "No such command 'invalid'" in result.output
