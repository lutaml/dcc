from dcclib.validation import SchemaVersion


# region === XSD VALIDATION TESTS ===
def test_list_schema_versions_contains_all_versions(client):
    response = client.get("/xsd/versions")
    assert response.status_code == 200
    assert response.json["versions"] == list([version.name.replace("_", ".") for version in SchemaVersion])


def test_validate_xsd_invalid_syntax_fails(client, invalid_syntax_dcc_id):
    response = client.post(f"/dccs/{invalid_syntax_dcc_id}/validate/xsd")
    assert response.status_code == 400
    assert response.json["is_valid"] is False
    assert len(response.json["errors"]) > 0
    assert response.json["errors"][0] == {
        "column": 20,
        "domain": "1",
        "domain_name": "PARSER",
        "level": 3,
        "level_name": "FATAL",
        "line": 7,
        "message": "Opening and ending tag mismatch: software line 5 and name",
        "type": "76",
        "type_name": "ERR_TAG_NAME_MISMATCH",
    }


def test_validate_xsd_invalid_schema_fails(client, invalid_schema_dcc_id):
    response = client.post(f"/dccs/{invalid_schema_dcc_id}/validate/xsd")
    assert response.status_code == 400
    assert response.json["is_valid"] is False
    assert len(response.json["errors"]) > 0
    assert response.json["errors"][0] == {
        "column": 0,
        "domain": "17",
        "domain_name": "SCHEMASV",
        "level": 2,
        "level_name": "ERROR",
        "line": 17,
        "message": "Element '{https://ptb.de/dcc}uniqueIdentifier': [facet 'pattern'] "
        "The value '' is not accepted by the pattern "
        "'[^\\s]+(\\s+[^\\s]+)*'.",
        "type": "1839",
        "type_name": "SCHEMAV_CVC_PATTERN_VALID",
    }


def test_validate_xsd_valid_dcc_successful(client, valid_dcc_id):
    response = client.post(f"/dccs/{valid_dcc_id}/validate/xsd")
    assert response.status_code == 200
    assert response.json["is_valid"] is True
    assert len(response.json["errors"]) == 0


def test_validate_invalid_version_fails(client, valid_dcc_id):
    response = client.post(f"/dccs/{valid_dcc_id}/validate/xsd", json={"version": "v1.2.3"})
    assert response.status_code == 400
    assert response.json["message"] == "Schema version v1.2.3 not found."


def test_validate_valid_version_successful(client, valid_dcc_id):
    response = client.post(f"/dccs/{valid_dcc_id}/validate/xsd", json={"version": "v3.3.0"})
    assert response.status_code == 200
    assert response.json["is_valid"] is True
    assert len(response.json["errors"]) == 0


# endregion


# region === SCHEMATRON VALIDATION TESTS ===
def test_validate_schematron_invalid_syntax_fails(client, invalid_syntax_dcc_id):
    response = client.post(f"/dccs/{invalid_syntax_dcc_id}/validate/schematron")
    # TODO: implement schema validation before schematron validation
    assert response.status_code == 500


def test_validate_schematron_invalid_schema_fails(client, invalid_schema_dcc_id):
    response = client.post(f"/dccs/{invalid_schema_dcc_id}/validate/schematron")
    # TODO: implement schema validation before schematron validation
    assert response.status_code == 200


def test_validate_schematron_invalid_schematron_fails(client, invalid_schematron_dcc_id):
    response = client.post(f"/dccs/{invalid_schematron_dcc_id}/validate/schematron")
    assert response.status_code == 400
    assert response.json["is_valid"] is False
    assert len(response.json["failed_assertions"]) > 0


def test_validate_schematron_valid_successful(client, valid_dcc_id):
    response = client.post(f"/dccs/{valid_dcc_id}/validate/schematron")
    assert response.status_code == 200
    assert response.json["is_valid"] is True
    assert len(response.json["failed_assertions"]) == 0


# endregion
