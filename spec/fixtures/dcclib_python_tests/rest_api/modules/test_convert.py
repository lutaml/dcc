def test_json_valid_successful(client, valid_dcc_id):
    response = client.post(f"/dccs/{valid_dcc_id}/convert/json")
    assert response.status_code == 200
    assert response.headers["Content-Type"] == "application/json"
    assert '"dcc:digitalCalibrationCertificate": {' in response.data.decode("utf-8")


def test_json_invalid_syntax_fails(client, invalid_syntax_dcc_id):
    response = client.post(f"/dccs/{invalid_syntax_dcc_id}/convert/json")
    assert response.status_code == 400
    assert "Failed to convert DCC to JSON." in response.json["message"]
