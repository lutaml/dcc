import pytest
from dcclib_rest_api.app import create_app

# ruff: noqa
from dcclib_test_resources.fixtures import *


def upload_dcc(client, xml: str) -> str:
    response = client.post("/dccs", json={"xml": xml})
    assert response.status_code == 201
    return response.json["id"]


@pytest.fixture(scope="session", autouse=True)
def app():
    app = create_app(debug=True)
    yield app


@pytest.fixture()
def client(app):
    return app.test_client()


# region === RESOURCE FIXTURES ===
@pytest.fixture()
def valid_dcc_id(client, valid_xml):
    return upload_dcc(client, valid_xml)


@pytest.fixture()
def invalid_syntax_dcc_id(client, invalid_syntax_xml):
    return upload_dcc(client, invalid_syntax_xml)


@pytest.fixture()
def invalid_schema_dcc_id(client, invalid_schema_xml):
    return upload_dcc(client, invalid_schema_xml)


@pytest.fixture()
def invalid_schematron_dcc_id(client, invalid_schematron_xml):
    return upload_dcc(client, invalid_schematron_xml)


@pytest.fixture()
def valid_formulae_dcc_id(client, valid_formula_xml):
    return upload_dcc(client, valid_formula_xml)


@pytest.fixture()
def valid_signature_dcc_id(client, valid_signature_xml):
    return upload_dcc(client, valid_signature_xml)


@pytest.fixture()
def invalid_signature_dcc_id(client, valid_signature_xml):
    xml = valid_signature_xml.replace(
        "<dcc:uniqueIdentifier>1234</dcc:uniqueIdentifier>",
        "<dcc:uniqueIdentifier>12355</dcc:uniqueIdentifier>",
    )
    return upload_dcc(client, xml)


# endregion
