def test_app_returns_metadata(client):
    response = client.get("/")

    assert response.status_code == 200
    assert response.json["title"] == "DCCLib REST-API"
    assert response.json["description"] == "REST-API for the DCCLib library."
    assert response.json["docs"] == "/docs"
