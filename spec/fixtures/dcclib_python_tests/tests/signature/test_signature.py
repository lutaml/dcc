import pytest
from dcclib_test_resources.constants import (
    CA_CERT_PATH,
    VALID_XML_PATH,
)
from lxml import etree
from signxml import InvalidDigest

from dcclib.signature.signature import DCCSigner, DCCVerifier


# region === FIXTURES ===
@pytest.fixture()
def signed_xml(cert_key, cert_pem, valid_xml):
    signer = DCCSigner(cert_key, cert_pem)
    signed_xml = signer.sign_str(valid_xml)
    return signed_xml


# endregion


# region === Signing ===
def test_sign_successful(signed_xml):
    assert "<ds:Signature" in signed_xml


def test_sign_path_successful(cert_key, cert_pem):
    signer = DCCSigner(cert_key, cert_pem)
    result = signer.sign_path(VALID_XML_PATH)

    assert "<ds:Signature" in etree.tostring(result).decode("utf-8")


def test_sign_tree_successful(cert_key, cert_pem):
    signer = DCCSigner(cert_key, cert_pem)
    tree = etree.parse(VALID_XML_PATH)
    result = signer.sign_tree(tree.getroot())

    assert "<ds:Signature" in etree.tostring(result).decode("utf-8")


def test_sign_invalid_key_fails(cert_key, cert_pem, valid_xml):
    invalid_key = cert_key.replace("-----BEGIN PRIVATE KEY-----", "-----BEGIN INVALID KEY-----")

    signer = DCCSigner(invalid_key, cert_pem)

    with pytest.raises(ValueError) as e:
        signer.sign_str(valid_xml)

    assert "MismatchedTags" in str(e.value)


def test_sign_invalid_cert_fails(cert_key, invalid_cert_pem, valid_xml):
    signer = DCCSigner(cert_key, invalid_cert_pem)

    with pytest.raises(ValueError) as e:
        signer.sign_str(valid_xml)

    assert "No PEM-encoded certificates found" in str(e.value)


# endregion


# region === Verification ===
def test_verify_successful(signed_xml):
    verifier = DCCVerifier(ca_pem_file=CA_CERT_PATH)
    result = verifier.verify_str(signed_xml)

    assert (
        "example@ptb.de,CN=ca,OU=1.24,O=PTB,L=Braunschweig,ST=Lower Saxony,C=DE" in result.cert.issuer.rfc4514_string()
    )
    assert (
        "example@ptb.de,CN=cert,OU=1.24,O=PTB,L=Braunschweig,ST=Lower Saxony,C=DE"
        in result.cert.subject.rfc4514_string()
    )
    assert "<dcc:digitalCalibrationCertificate" in etree.tostring(result.signed_tree).decode("utf-8")
    assert "<ds:Signature" in etree.tostring(result.signature_tree).decode("utf-8")


def test_verify_path_successful(tmp_path, signed_xml):
    signed_xml_path = tmp_path / "signed.xml"
    signed_xml_path.write_text(signed_xml)
    verifier = DCCVerifier(ca_pem_file=CA_CERT_PATH)

    result = verifier.verify_path(str(signed_xml_path))

    assert (
        "example@ptb.de,CN=ca,OU=1.24,O=PTB,L=Braunschweig,ST=Lower Saxony,C=DE" in result.cert.issuer.rfc4514_string()
    )
    assert (
        "example@ptb.de,CN=cert,OU=1.24,O=PTB,L=Braunschweig,ST=Lower Saxony,C=DE"
        in result.cert.subject.rfc4514_string()
    )
    assert "<dcc:digitalCalibrationCertificate" in etree.tostring(result.signed_tree).decode("utf-8")
    assert "<ds:Signature" in etree.tostring(result.signature_tree).decode("utf-8")


def test_verify_invalid_digest_fails(signed_xml):
    verifier = DCCVerifier(ca_pem_file=CA_CERT_PATH)
    invalid_signed_xml = signed_xml.replace(
        "<dcc:uniqueIdentifier>1234</dcc:uniqueIdentifier>",
        "<dcc:uniqueIdentifier>12345</dcc:uniqueIdentifier>",
    )
    with pytest.raises(InvalidDigest):
        verifier.verify_str(invalid_signed_xml)


# endregion
