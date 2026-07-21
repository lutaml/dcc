def test_verify_successful(client, valid_signature_dcc_id, ca_cert):
    response = client.post(
        f"/dccs/{valid_signature_dcc_id}/signature",
        json={"ca_cert": ca_cert},
    )

    assert response.status_code == 200
    assert (
        response.json["signature"]["issuer"]
        == "1.2.840.113549.1.9.1=example@ptb.de,CN=ca,OU=1.24,O=PTB,L=Braunschweig,ST=Lower Saxony,C=DE"
    )
    assert response.json["signature"]["signature_algorithm"] == "sha256WithRSAEncryption"
    assert (
        response.json["signature"]["subject"]
        == "1.2.840.113549.1.9.1=example@ptb.de,CN=cert,OU=1.24,O=PTB,L=Braunschweig,ST=Lower Saxony,C=DE"
    )

    assert response.json["signed_xml"].startswith("<dcc:digitalCalibrationCertificate")


def test_verify_invalid_ca_cert_fails(client, valid_signature_dcc_id):
    response = client.post(f"/dccs/{valid_signature_dcc_id}/signature", json={"ca_cert": "invalid"})

    assert response.status_code == 400
    assert response.json["message"] == "Could not extract signature information."


def test_verify_invalid_syntax_fails(client, invalid_syntax_dcc_id, ca_cert):
    response = client.post(
        f"/dccs/{invalid_syntax_dcc_id}/signature",
        json={"ca_cert": ca_cert},
    )

    assert response.status_code == 400
    assert response.json["message"] == "Could not extract signature information."


def test_verify_no_signature_fails(client, valid_dcc_id, ca_cert):
    response = client.post(
        f"/dccs/{valid_dcc_id}/signature",
        json={"ca_cert": ca_cert},
    )

    assert response.status_code == 400
    assert response.json["message"] == "Could not extract signature information."


def test_verify_invalid_signature_fails(client, invalid_signature_dcc_id, ca_cert):
    response = client.post(
        f"/dccs/{invalid_signature_dcc_id}/signature",
        json={"ca_cert": ca_cert},
    )

    assert response.status_code == 400
    assert response.json["message"] == "Could not extract signature information."
    assert "Digest mismatch for reference" in response.json["details"]
