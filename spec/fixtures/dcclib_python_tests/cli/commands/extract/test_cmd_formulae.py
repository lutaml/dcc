from click.testing import CliRunner
from dcclib_cli.cli import cli
from dcclib_test_resources.constants import (
    VALID_FORMULA_XML_PATH,
)
from dcclib_test_resources.constants import (
    VALID_XML_PATH as NO_FORMULA_XML_PATH,
)


def test_no_variables_success():
    runner = CliRunner()
    result = runner.invoke(cli, ["extract", "formulae", str(VALID_FORMULA_XML_PATH)])
    assert result.exit_code == 0
    # Variables should be taken from the DCC XML file
    assert "100.0225" in result.output
    assert "109.77301212171875" in result.output
    assert "119.442643549375" in result.output
    assert "129.03139428296875" in result.output
    assert "138.5392643225" in result.output


def test_one_variable_success():
    runner = CliRunner()
    result = runner.invoke(cli, ["extract", "formulae", str(VALID_FORMULA_XML_PATH), "-v", "T=42"])
    assert result.exit_code == 0
    assert "116.357161312039" in result.output


def test_multiple_variable_success():
    runner = CliRunner()
    result = runner.invoke(
        cli,
        [
            "extract",
            "formulae",
            str(VALID_FORMULA_XML_PATH),
            "-v",
            "T=42",
            "-v",
            "R0=1",
        ],
    )
    assert result.exit_code == 0
    assert "1.1633098684" in result.output


def test_multiple_same_variable_success():
    runner = CliRunner()
    result = runner.invoke(cli, ["extract", "formulae", str(VALID_FORMULA_XML_PATH), "-v", "T=42,43"])
    assert result.exit_code == 0
    assert "116.357161312039" in result.output
    assert "116.74329952359275" in result.output


def test_no_formulae_xml():
    runner = CliRunner()
    result = runner.invoke(
        cli,
        ["extract", "formulae", str(NO_FORMULA_XML_PATH), "-v", "x=1", "-v", "y=2"],
    )
    assert result.exit_code == 0
    assert "No formulae found." in result.output


def test_invalid_variable():
    runner = CliRunner()
    result = runner.invoke(cli, ["extract", "formulae", str(VALID_FORMULA_XML_PATH), "-v", "x=invalid"])
    assert result.exit_code == 2
    assert "invalid is not a valid key=decimal_value" in result.output
