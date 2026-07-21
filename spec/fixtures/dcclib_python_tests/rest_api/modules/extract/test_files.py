import pytest

from ...conftest import upload_dcc


# region === FIXTURES ===
@pytest.fixture()
def empty_dcc_id(client):
    return upload_dcc(client, "<xml></xml>")


# endregion


def test_list_files_empty_success(client, empty_dcc_id):
    response = client.get(f"/dccs/{empty_dcc_id}/extract/files")
    assert response.status_code == 200
    assert len(response.json["files"]) == 0


def test_list_files_correct_content(client, valid_dcc_id):
    response = client.get(
        f"/dccs/{valid_dcc_id}/extract/files",
    )
    assert response.status_code == 200
    assert len(response.json["files"]) == 1
    assert response.json["files"][0] == {
        "name": [
            {"lang": "de", "value": "Testdatei"},
            {"lang": "en", "value": "Test file"},
        ],
        "file_name": "test.txt",
        "data_base64": "VGVzdAo=",
        "mime_type": "text/plain",
        "ring": "administrative_data",
    }


def test_extract_file_empty_index_out_of_bounds(client, empty_dcc_id):
    response = client.get(f"/dccs/{empty_dcc_id}/extract/files/0")
    assert response.status_code == 400
    assert response.json == {"message": "Index out of bounds"}


def test_extract_file_correct_content(client, valid_dcc_id):
    response = client.get(f"/dccs/{valid_dcc_id}/extract/files/0")
    assert response.status_code == 200
    assert response.headers["Content-Disposition"] == "attachment; filename=test.txt"
    assert response.headers["Content-Type"] == "text/plain"
    assert response.data == b"Test\n"
