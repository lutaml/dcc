import pytest
from dcclib_test_resources.constants import (
    CUSTOM_XSD_PATH,
    NON_EXISTING_XSD_PATH,
)
from lxml import etree
from saxonche import PySaxonApiError

from dcclib.validation import SchematronValidator, SchemaVersion, XsdValidator
from dcclib.validation.xsd import detect_schema_version


# region === SCHEMA VERSION DETECTION TESTS ===
def test_detect_schema_version_successful(valid_xml):
    tree = etree.fromstring(valid_xml.encode("utf-8"))
    version = detect_schema_version(tree)

    assert version == SchemaVersion.latest


def test_detect_schema_version_from_fragment_successful():
    xml_content = """
    <dcc:digitalCalibrationCertificate
        xmlns:dcc='https://ptb.de/dcc'
        schemaVersion='3.2.1'>
    </dcc:digitalCalibrationCertificate>
    """

    tree = etree.fromstring(xml_content.encode("utf-8"))
    version = detect_schema_version(tree)

    assert version == SchemaVersion.v3_2_1


def test_detect_schema_version_with_invalid_version_fails():
    xml_content = """
    <dcc:digitalCalibrationCertificate
        xmlns:dcc='https://ptb.de/dcc'
        schemaVersion='1.3.3.7'>
    </dcc:digitalCalibrationCertificate>
    """

    tree = etree.fromstring(xml_content.encode("utf-8"))
    with pytest.raises(ValueError):
        detect_schema_version(tree)


def test_detect_schema_version_without_version_fails():
    xml_content = """
    <dcc:digitalCalibrationCertificate
        xmlns:dcc='https://ptb.de/dcc'>
    </dcc:digitalCalibrationCertificate>
    """

    tree = etree.fromstring(xml_content.encode("utf-8"))
    with pytest.raises(ValueError):
        detect_schema_version(tree)


def test_detect_schema_version_with_custom_tag_fails():
    xml_content = """
    <dkbs:digitalCalibrationCertificate
        xmlns:dkbs='https://ptb.de/dcc'
        schemaVersion='3.2.1'>
    </dkbs:digitalCalibrationCertificate>
    """

    tree = etree.fromstring(xml_content.encode("utf-8"))
    version = detect_schema_version(tree)

    assert version == SchemaVersion.v3_2_1


def test_detect_schema_version_without_tag_fails():
    xml_content = "<xml></xml>"

    tree = etree.fromstring(xml_content.encode("utf-8"))
    with pytest.raises(ValueError):
        detect_schema_version(tree)


# endregion


# region === XSD VALIDATION TESTS ===
def test_xsd_success(valid_xml):
    validator = XsdValidator.from_version(SchemaVersion.latest)

    res = validator.validate_str(valid_xml)

    assert res.is_valid
    assert len(res.errors) == 0


def test_xsd_with_custom_schema_file_invalid(valid_xml):
    xsd = XsdValidator.from_file(CUSTOM_XSD_PATH)

    res = xsd.validate_str(valid_xml)

    assert not res.is_valid
    assert all("customElement" in e.message for e in res.errors)


def test_xsd_with_custom_schema_string_invalid(custom_xsd, valid_xml):
    xsd = XsdValidator.from_str(custom_xsd)

    res = xsd.validate_str(valid_xml)

    assert not res.is_valid
    assert all("customElement" in e.message for e in res.errors)


def test_xsd_with_non_existing_custom_schema_raises_file_not_found_error():
    with pytest.raises(FileNotFoundError):
        XsdValidator.from_file(NON_EXISTING_XSD_PATH)


def test_xsd_with_invalid_syntax_fails(invalid_syntax_xml):
    xsd = XsdValidator.from_version(SchemaVersion.latest)

    res = xsd.validate_str(invalid_syntax_xml)

    assert not res.is_valid
    assert all(e.domain_name == "PARSER" for e in res.errors)


def test_xsd_with_invalid_schema_fails(invalid_schema_xml):
    xsd = XsdValidator.from_version(SchemaVersion.latest)

    res = xsd.validate_str(invalid_schema_xml)

    assert not res.is_valid
    assert all(e.domain_name == "SCHEMASV" for e in res.errors)


def test_xsd_with_auto_detect_schema_version_successful(valid_xml):
    xsd = XsdValidator.from_auto_detection()

    res = xsd.validate_str(valid_xml)

    assert res.is_valid
    assert len(res.errors) == 0


# endregion


# region === SCHEMATRON VALIDATION TESTS ===
@pytest.mark.parametrize(
    "ctor,ctor_arg",
    [
        (SchematronValidator.from_str, "custom_schematron"),
        (SchematronValidator.from_tree, "custom_schematron_tree"),
        (SchematronValidator.from_file, "custom_schematron_path"),
    ],
)
@pytest.mark.parametrize(
    "meth,arg",
    [
        ("validate_str", "valid_xml"),
        ("validate_tree", "valid_xml_tree"),
        ("validate_file", "valid_xml_path"),
    ],
)
def test_schematron_success(ctor, ctor_arg, meth, arg, request):
    argument = request.getfixturevalue(arg)
    sch = ctor(request.getfixturevalue(ctor_arg))

    res = getattr(sch, meth)(argument)

    assert res.is_valid
    assert all("information" in se.role for se in res.successful_reports)
    assert len(res.failed_assertions) == 0


def test_schematron_for_dcc_successful(valid_xml):
    sch = SchematronValidator.for_dcc()

    res = sch.validate_str(valid_xml)

    assert res.is_valid
    assert len(res.failed_assertions) == 0
    assert len(res.successful_reports) > 0


def test_schematron_with_invalid_syntax_raises_saxon_api_error(invalid_syntax_xml):
    sch = SchematronValidator.for_dcc()

    # Saxonche fails because the syntax is invalid
    with pytest.raises(PySaxonApiError):
        sch.validate_str(invalid_syntax_xml)


def test_schematron_with_invalid_schema_successful(invalid_schema_xml):
    sch = SchematronValidator.for_dcc()

    res = sch.validate_str(invalid_schema_xml)

    # No schematron errors, even though the schema is invalid
    assert res


def test_schematron_with_invalid_schematron(invalid_schematron_xml):
    sch = SchematronValidator.for_dcc()

    res = sch.validate_str(invalid_schematron_xml)

    assert not res.is_valid
    assert all("error" in se.role for se in res.failed_assertions)


# endregion
