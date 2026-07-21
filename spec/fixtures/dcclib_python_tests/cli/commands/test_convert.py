# tests/commands/test_cmd_convert.py

from click.testing import CliRunner
from dcclib_cli.cli import cli
from dcclib_test_resources.constants import INVALID_SYNTAX_XML_PATH, VALID_XML_PATH

# this string checks if the conversion is schema-aware
# if it is not schema-aware, mandatoryLangCodeISO639_1 would not be an array
EXPECTED_STRING = """\"dcc:mandatoryLangCodeISO639_1\": [\n          \"en\"\n        ]"""


def test_to_json_success():
    runner = CliRunner()
    result = runner.invoke(cli, ["convert", "to-json", str(VALID_XML_PATH)])
    assert result.exit_code == 0
    assert EXPECTED_STRING in result.output


def test_to_json_invalid_xml_fails():
    runner = CliRunner()
    result = runner.invoke(cli, ["convert", "to-json", str(INVALID_SYNTAX_XML_PATH)])
    assert result.exit_code == 1
    assert "Could not convert to JSON" in result.output


def test_verify_output_file_successful():
    runner = CliRunner()
    with runner.isolated_filesystem():
        result = runner.invoke(cli, ["convert", "to-json", str(VALID_XML_PATH), "-o", "output.json"])
        assert result.exit_code == 0
        with open("output.json", encoding="utf-8") as f:
            assert EXPECTED_STRING in f.read()
        assert "JSON content written to output.json" in result.output
