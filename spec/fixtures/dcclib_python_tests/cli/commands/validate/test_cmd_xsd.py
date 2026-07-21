from click.testing import CliRunner
from dcclib_cli.cli import cli
from dcclib_test_resources.constants import (
    CUSTOM_XSD_PATH,
    INVALID_SCHEMA_XML_PATH,
    INVALID_SYNTAX_XML_PATH,
    VALID_XML_PATH,
)


def test_validate_success():
    runner = CliRunner()
    result = runner.invoke(cli, ["validate", "xsd", str(VALID_XML_PATH)])
    assert result.exit_code == 0
    assert "SUCCESS: XSD validation exited with no errors." in result.output


def test_validate_invalid_syntax_fails():
    runner = CliRunner()
    result = runner.invoke(cli, ["validate", "xsd", str(INVALID_SYNTAX_XML_PATH)])
    assert result.exit_code == 1
    assert "XSD validation failed." in result.output
    assert "Opening and ending tag mismatch" in result.output


def test_validate_invalid_schema():
    runner = CliRunner()
    result = runner.invoke(cli, ["validate", "xsd", str(INVALID_SCHEMA_XML_PATH)])
    assert result.exit_code == 1
    assert "XSD validation failed." in result.output
    assert "This element is not expected" in result.output


def test_validate_with_custom_schema_fails_always():
    runner = CliRunner()
    result = runner.invoke(cli, ["validate", "xsd", str(VALID_XML_PATH), "-s", str(CUSTOM_XSD_PATH)])
    assert result.exit_code == 1
    assert "XSD validation failed." in result.output
    assert "Expected is ( {https://ptb.de/dcc}customElement )" in result.output
