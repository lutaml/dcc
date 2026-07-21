from dcclib_test_resources.constants import CUSTOM_XSLT_PATH


def test_xslt_invalid_fails(client, valid_dcc_id):
    response = client.post(
        f"/dccs/{valid_dcc_id}/transform/xslt",
        json={"xslt": "invalid"},
    )

    assert response.status_code == 400
    assert response.json["message"] == "Could not perform XSLT transformation."


def test_xslt_valid_successful(client, valid_dcc_id):
    with open(CUSTOM_XSLT_PATH, encoding="utf-8") as f:
        xslt = f.read()

    response = client.post(
        f"/dccs/{valid_dcc_id}/transform/xslt",
        json={"xslt": xslt},
    )

    assert response.status_code == 200
    assert response.headers["Content-Disposition"] == f"attachment; filename={valid_dcc_id}.html"
    assert response.headers["Content-Type"] == "text/html"
    assert b"XSLT Version = 3.0" in response.data
