from click.testing import CliRunner
from dcclib_cli.cli import cli
from dcclib_test_resources.constants import (
    CA_CERT_PATH,
    INVALID_SIGNATURE_XML_PATH,
    VALID_SIGNATURE_XML_PATH,
)


def test_sign_successful(runner, cert_pem_path, cert_key_path, valid_xml_path):
    result = runner.invoke(cli, ["signature", "sign", cert_pem_path, cert_key_path, valid_xml_path])
    assert result.exit_code == 0
    assert "<ds:Signature" in result.output


def test_sign_invalid_cert_fails(runner, invalid_cert_pem_path, cert_key_path, valid_xml_path):
    result = runner.invoke(
        cli,
        [
            "signature",
            "sign",
            invalid_cert_pem_path,
            cert_key_path,
            valid_xml_path,
        ],
    )
    assert result.exit_code == 1
    assert "Could not sign XML: No PEM-encoded certificates found" in result.output


def test_verify_successful():
    runner = CliRunner()
    result = runner.invoke(cli, ["signature", "verify", str(CA_CERT_PATH), str(VALID_SIGNATURE_XML_PATH)])
    assert result.exit_code == 0
    assert "Verification successful." in result.output


def test_verify_invalid_xml_fails():
    runner = CliRunner()
    result = runner.invoke(cli, ["signature", "verify", str(CA_CERT_PATH), str(INVALID_SIGNATURE_XML_PATH)])
    assert result.exit_code == 1
    assert "Could not verify XML: Digest mismatch for reference" in result.output


def test_verify_output_file_successful():
    runner = CliRunner()
    with runner.isolated_filesystem():
        result = runner.invoke(
            cli,
            [
                "signature",
                "verify",
                str(CA_CERT_PATH),
                str(VALID_SIGNATURE_XML_PATH),
                "-o",
                "verified.xml",
            ],
        )
        assert result.exit_code == 0
        with open("verified.xml", encoding="utf-8") as f:
            assert "dcc:digitalCalibrationCertificate" in f.read()
        assert "Signed XML content written to verified.xml" in result.output
