def test_upload_valid_dcc_successful(client, valid_xml):
    response = client.post("/dccs", json={"xml": valid_xml})
    assert response.status_code == 201
    assert response.json["id"] is not None


def test_get_dcc_successful(client, valid_dcc_id, valid_xml):
    response = client.get(f"/dccs/{valid_dcc_id}")
    assert response.status_code == 200
    assert response.json["id"] == valid_dcc_id
    assert response.json["xml"] == valid_xml


def test_get_dcc_not_found(client):
    response = client.get("/dccs/123")
    assert response.status_code == 404
    assert response.json["message"] == "DCC 123 not found."


def test_delete_dcc_successful(client, valid_dcc_id):
    response = client.delete(f"/dccs/{valid_dcc_id}")
    assert response.status_code == 204

    response = client.get(f"/dccs/{valid_dcc_id}")
    assert response.status_code == 404


def test_delete_dcc_not_found(client):
    response = client.delete("/dccs/123")
    assert response.status_code == 404
    assert response.json["message"] == "DCC 123 not found."
