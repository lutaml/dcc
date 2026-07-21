from click.testing import CliRunner
from dcclib_cli.cli import cli
from dcclib_test_resources.constants import VALID_XML_PATH

FIRST_FILE_CONTENT = "Test"


def test_returns_all_files():
    runner = CliRunner()
    result = runner.invoke(cli, ["extract", "files", str(VALID_XML_PATH)])
    assert result.exit_code == 0
    assert result.output.startswith("SUCCESS: Files were extracted and are listed in the table below.")


def test_valid_index_returns_selected_file():
    runner = CliRunner()
    result = runner.invoke(cli, ["extract", "files", str(VALID_XML_PATH), "0"])
    assert result.exit_code == 0
    assert result.output.startswith(FIRST_FILE_CONTENT)


def test_too_small_index_returns_error():
    runner = CliRunner()
    # -- is needed to disable parsing of further arguments
    # otherwise the -1 would be interpreted as an option
    result = runner.invoke(cli, ["extract", "files", "--", str(VALID_XML_PATH), "-1"])
    assert result.output.startswith("ERROR: Index -1 out of bounds.")
    assert result.exit_code == 1


def test_too_large_index_returns_error():
    runner = CliRunner()
    result = runner.invoke(cli, ["extract", "files", str(VALID_XML_PATH), "999"])
    assert result.output.startswith("ERROR: Index 999 out of bounds.")
    assert result.exit_code == 1


def test_output_option_writes_file():
    runner = CliRunner()
    with runner.isolated_filesystem():
        result = runner.invoke(cli, ["extract", "files", str(VALID_XML_PATH), "0", "-o", "output.txt"])
        assert result.exit_code == 0
        with open("output.txt", encoding="utf-8") as f:
            assert f.read().startswith(FIRST_FILE_CONTENT)
        assert result.output == "SUCCESS: File written to output.txt\n"
