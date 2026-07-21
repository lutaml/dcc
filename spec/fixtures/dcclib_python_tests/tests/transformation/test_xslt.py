import pytest
from dcclib_test_resources.constants import (
    NON_EXISTING_XML_PATH,
    NON_EXISTING_XSLT_PATH,
    VALID_XML_PATH,
)

from dcclib.transformation import XsltProcessor


def test_with_xml_file_successful(custom_xslt):
    xslt_processor = XsltProcessor.from_str(custom_xslt)

    result = xslt_processor.transform_file(str(VALID_XML_PATH))

    assert "Test XSLT" in result


def test_with_xslt_file_xml_file_successful(custom_xslt_path, valid_xml_path):
    xslt_processor = XsltProcessor.from_file(custom_xslt_path)

    result = xslt_processor.transform_file(valid_xml_path)

    assert "Test XSLT" in result


def test_with_xslt_tree_successful(custom_xslt_tree, valid_xml_tree):
    xslt_processor = XsltProcessor.from_tree(custom_xslt_tree)

    result = xslt_processor.transform_tree(valid_xml_tree)

    assert "Test XSLT" in result


def test_with_xml_file_not_found(custom_xslt):
    xslt_processor = XsltProcessor.from_str(custom_xslt)

    with pytest.raises(FileNotFoundError):
        xslt_processor.transform_file(NON_EXISTING_XML_PATH)


def test_with_xslt_file_not_found():
    with pytest.raises(FileNotFoundError):
        XsltProcessor.from_file(NON_EXISTING_XSLT_PATH)


def test_with_string_successful(custom_xslt, valid_xml):
    xslt_processor = XsltProcessor.from_str(custom_xslt)

    result = xslt_processor.transform_str(valid_xml)

    assert "Test XSLT" in result
