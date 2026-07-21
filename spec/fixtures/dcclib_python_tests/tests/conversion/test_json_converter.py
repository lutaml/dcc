from dcclib_test_resources.constants import VALID_XML_PATH
from lxml import etree

from dcclib.conversion import JSONConverter

# this string checks if the conversion is schema-aware
# if it is not schema-aware, mandatoryLangCodeISO639_1 would not be an array
EXPECTED_STRING = """\"dcc:mandatoryLangCodeISO639_1\": [\n          \"en\"\n        ]"""


def test_valid_xml_from_path_successful():
    converter = JSONConverter.from_file(str(VALID_XML_PATH))

    json_str = converter.convert()

    # this string checks if the conversion is schema-aware
    # if it is not schema-aware, mandatoryLangCodeISO639_1 would not be an array
    assert EXPECTED_STRING in json_str


def test_valid_xml_from_tree_successful():
    with open(VALID_XML_PATH, encoding="utf-8") as f:
        tree = etree.parse(f)

    converter = JSONConverter.from_tree(tree)

    json_str = converter.convert()

    assert EXPECTED_STRING in json_str


def test_valid_xml_from_str_successful(valid_xml):
    converter = JSONConverter.from_str(valid_xml)

    json_str = converter.convert()

    assert EXPECTED_STRING in json_str
