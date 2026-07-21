def test_extract_successful(client, valid_formulae_dcc_id):
    response = client.get(f"/dccs/{valid_formulae_dcc_id}/extract/formulae")

    assert response.status_code == 200
    assert response.json == {
        "formulae": [
            {
                "name": "R",
                "expression": "R0*(A*T + B*T**2 + 1)",
                "bound_variables": ["T"],
                "variables": {
                    "A": "0.0039155",
                    "B": "-0.0000006469",
                    "R0": "100.0225",
                    "T": ["0.0", "25.0", "50.0", "75.0", "100.0"],
                },
                "result": [
                    "100.0225",
                    "109.77301212171875",
                    "119.442643549375",
                    "129.03139428296875",
                    "138.5392643225",
                ],
            }
        ]
    }


def test_extract_no_formulae_empty_response(client, valid_dcc_id):
    response = client.get(f"/dccs/{valid_dcc_id}/extract/formulae")

    assert response.status_code == 200
    assert response.json == {"formulae": []}


def test_extract_invalid_syntax_fails(client, invalid_syntax_dcc_id):
    response = client.get(f"/dccs/{invalid_syntax_dcc_id}/extract/formulae")

    assert response.status_code == 400
    assert response.json["message"] == "Could not extract formulae."


def test_evaluate_successful(client, valid_formulae_dcc_id):
    variables = {
        "T": [42],
    }
    response = client.post(
        f"/dccs/{valid_formulae_dcc_id}/extract/formulae",
        json={"variables": variables},
    )

    assert response.status_code == 200
    assert response.json == {
        "formulae": [
            {
                "name": "R",
                "expression": "R0*(A*T + B*T**2 + 1)",
                "bound_variables": ["T"],
                "variables": {
                    "A": "0.0039155",
                    "B": "-0.0000006469",
                    "R0": "100.0225",
                    "T": ["0.0", "25.0", "50.0", "75.0", "100.0"],
                },
                "result": ["116.357161312039"],
            }
        ]
    }


def test_evaluate_missing_variable_fails(client, valid_formulae_dcc_id):
    # this makes the formula evaluation fail, because a variable is missing
    variables = {
        "T": [],
    }
    response = client.post(
        f"/dccs/{valid_formulae_dcc_id}/extract/formulae",
        json={"variables": variables},
    )

    assert response.status_code == 400
    assert response.json["message"] == "Could not evaluate formula."


def test_evaluate_invalid_syntax_fails(client, invalid_syntax_dcc_id):
    response = client.post(f"/dccs/{invalid_syntax_dcc_id}/extract/formulae")

    assert response.status_code == 400
    assert response.json["message"] == "Could not extract formulae."


def test_evaluate_no_formulae_empty_response(client, valid_dcc_id):
    response = client.post(f"/dccs/{valid_dcc_id}/extract/formulae")

    assert response.status_code == 200
    assert response.json == {"formulae": []}


def test_extract_formula_successful(client, valid_formulae_dcc_id):
    response = client.get(f"/dccs/{valid_formulae_dcc_id}/extract/formulae/0")

    assert response.status_code == 200
    assert response.json == {
        "name": "R",
        "expression": "R0*(A*T + B*T**2 + 1)",
        "bound_variables": ["T"],
        "variables": {
            "A": "0.0039155",
            "B": "-0.0000006469",
            "R0": "100.0225",
            "T": ["0.0", "25.0", "50.0", "75.0", "100.0"],
        },
        "result": [
            "100.0225",
            "109.77301212171875",
            "119.442643549375",
            "129.03139428296875",
            "138.5392643225",
        ],
    }


def test_extract_formula_index_out_of_bounds_fails(client, valid_formulae_dcc_id):
    response = client.get(f"/dccs/{valid_formulae_dcc_id}/extract/formulae/1")

    assert response.status_code == 400
    assert response.json["message"] == "Index out of bounds."
