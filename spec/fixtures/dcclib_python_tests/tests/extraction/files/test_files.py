import pytest

from dcclib.extraction.files import FileExtractor


@pytest.mark.parametrize(
    "ctor,arg",
    [
        (FileExtractor.from_str, "valid_xml"),
        (FileExtractor.from_tree, "valid_xml_tree"),
        (FileExtractor.from_file, "valid_xml_path"),
    ],
)
def test_files_returns_files(ctor, arg, request):
    file_extractor = ctor(request.getfixturevalue(arg))
    files = file_extractor.extract()

    assert len(files) == 1

    assert files[0].ring.value == "administrativeData"
    assert files[0].file_name == "test.txt"
    assert files[0].mime_type == "text/plain"
    assert files[0].data_base64 == "VGVzdAo="
    assert files[0].decode_data_base64() == b"Test\n"

    assert len(files[0].name) == 2

    assert files[0].name[0].value == "Testdatei"
    assert files[0].name[0].lang == "de"

    assert files[0].name[1].value == "Test file"
    assert files[0].name[1].lang == "en"


def test_files_returns_no_files():
    file_extractor = FileExtractor.from_str("<dcc:digitalCalibrationCertificate xmlns:dcc='https://www.ptb.de/dcc'/>")
    files = file_extractor.extract()

    assert len(files) == 0
