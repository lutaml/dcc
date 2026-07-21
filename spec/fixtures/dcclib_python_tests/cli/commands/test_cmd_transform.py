from click.testing import CliRunner
from dcclib_cli.cli import cli
from dcclib_test_resources.constants import CUSTOM_XSLT_PATH, VALID_XML_PATH


def test_xslt_transform_successful():
    runner = CliRunner()
    result = runner.invoke(cli, ["transform", "xslt", str(VALID_XML_PATH), str(CUSTOM_XSLT_PATH)])
    assert result.exit_code == 0
    assert "Test XSLT" in result.output


def test_xslt_transform_with_output_option():
    runner = CliRunner()
    with runner.isolated_filesystem():
        result = runner.invoke(
            cli,
            [
                "transform",
                "xslt",
                str(VALID_XML_PATH),
                str(CUSTOM_XSLT_PATH),
                "-o",
                "output.xml",
            ],
        )
        assert result.exit_code == 0
        with open("output.xml", encoding="utf-8") as f:
            assert "Test XSLT" in f.read()
        assert result.output.startswith("SUCCESS: Transformation exited without errors, wrote output to output.xml")
