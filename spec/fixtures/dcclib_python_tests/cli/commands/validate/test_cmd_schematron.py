from click.testing import CliRunner
from dcclib_cli.cli import cli
from dcclib_test_resources.constants import (
    CUSTOM_SCHEMATRON_PATH,
    INVALID_SCHEMATRON_XML_PATH,
    VALID_XML_PATH,
)


def test_validate_with_custom_schematron_success():
    runner = CliRunner()
    result = runner.invoke(cli, ["validate", "schematron", str(VALID_XML_PATH), "-s", str(CUSTOM_SCHEMATRON_PATH)])
    assert result.exit_code == 0
    assert "SUCCESS: Schematron validation exited with no errors." in result.output


def test_validate_with_dcc_schematron_success():
    runner = CliRunner()
    result = runner.invoke(cli, ["validate", "schematron", str(VALID_XML_PATH)])
    assert result.exit_code == 0
    assert "SUCCESS: Schematron validation exited with no errors." in result.output


def test_validate_with_invalid_schematron_xml_fails():
    runner = CliRunner()
    result = runner.invoke(cli, ["validate", "schematron", str(INVALID_SCHEMATRON_XML_PATH)])
    assert result.exit_code == 1
    assert "ERROR:" in result.output
