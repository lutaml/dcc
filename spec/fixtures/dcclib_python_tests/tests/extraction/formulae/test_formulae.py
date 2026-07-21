import mpmath as mp
import pytest
from dcclib_test_resources.constants import VALID_FORMULA_XML_PATH

from dcclib.extraction.formulae import DCCFunction, FormulaExtractor
from dcclib.extraction.formulae.formula import sub_len


def mpf_equals(a, b, tol=None):
    if tol is None:
        tol = mp.mpf("1e-10")
    return abs(a - b) < tol


def test_formulae_extract_calc_smoke():
    extractor = FormulaExtractor.from_path(VALID_FORMULA_XML_PATH)
    formulae = extractor.extract()

    assert len(formulae) == 1

    formula = formulae[0]
    assert formula.name == "R"

    results = formula.evaluate()
    assert len(results) == 5
    assert mpf_equals(results[0], mp.mpf("100.02250000000000"))
    assert mpf_equals(results[1], mp.mpf("109.77301212171875"))
    assert mpf_equals(results[2], mp.mpf("119.44264354937500"))
    assert mpf_equals(results[3], mp.mpf("129.03139428296875"))
    assert mpf_equals(results[4], mp.mpf("138.53926432250000"))

    results = formula.evaluate({"T": 25})
    assert len(results) == 1
    assert mpf_equals(results[0], mp.mpf("109.77301212171875"))


def test_sub_len_empty_returns_0():
    assert sub_len([]) == 0


def test_sub_len_empty_sublist_fails():
    with pytest.raises(ValueError):
        sub_len([[]])


def test_sub_len_flat_returns_1():
    assert sub_len([[1], 2, [3]]) == 1
    assert sub_len([[1]]) == 1
    assert sub_len([1]) == 1
    assert sub_len([0, 1, 2, 3]) == 1


def test_sub_len_different_lengths_fails():
    with pytest.raises(ValueError):
        sub_len([[1], [2, 3], [4, 5, 6]])

    with pytest.raises(ValueError):
        sub_len([[1], [2, 3], [4, 5, 6], [7, 8, 9, 10]])


def test_evaluate_no_bvars_and_vars_successful():
    function = DCCFunction("R", "100", {}, set())
    results = function.evaluate()

    assert len(function.combinations) == 1
    assert len(results) == 1
    assert results[0] == 100


def test_evaluate_one_bvar_successful():
    function = DCCFunction("R", "100 + 0.5 * T", {"T": 25}, {"T"})
    results = function.evaluate()

    assert len(results) == 1
    assert results[0] == 112.5


def test_evaluate_one_var_successful():
    function = DCCFunction("R", "100 + 0.5 * T", {"T": 25}, set())
    results = function.evaluate()

    assert len(results) == 1
    assert results[0] == 112.5


def test_evaluate_bvar_list_successful():
    function = DCCFunction("R", "100 + T", {"T": [0, 25, 50, 75, 100]}, {"T"})
    results = function.evaluate()

    assert len(results) == 5
    assert results[0] == 100


def test_evaluate_var_list_successful():
    function = DCCFunction("R", "100 + T + X", {"T": 25}, {"T"})
    results = function.evaluate({"X": [0, 1, 2, 3, 4]})

    assert len(results) == 5
    assert results[1] == 126


def test_evaluate_bvar_and_var_list_successful():
    function = DCCFunction("R", "100 + T + X", {"T": [0, 25, 50, 75, 100]}, {"T"})
    results = function.evaluate({"X": [0, 1, 2, 3, 4]})

    assert len(results) == 5
    assert results[1] == 126


def test_evaluate_one_var_one_bvar_successful():
    function = DCCFunction("R", "100 + 0.5 * T * X", {"T": 25, "X": 2}, {"T"})
    results = function.evaluate()

    assert len(results) == 1
    assert results[0] == 125


def test_evaluate_unequal_var_list_fails():
    function = DCCFunction("R", "100 + 0.5 * T * X", {"T": [25, 50]}, {"T"})
    with pytest.raises(ValueError):
        function.evaluate({"X": [0, 1, 2, 3]})


def test_evaluate_missing_vars_fails():
    function = DCCFunction("R", "100 + 0.5 * T * X", {}, set())
    with pytest.raises(ValueError):
        function.evaluate()


def test_evaluate_missing_bvars_fails():
    function = DCCFunction("R", "100 + 0.5 * T * X", {}, {"T"})
    with pytest.raises(ValueError):
        function.evaluate()


def test_evaluate_pass_non_bvar_successful():
    function = DCCFunction("R", "100 + 0.5 * T * X", {"T": 25, "X": 2}, {"T"})
    results = function.evaluate({"X": 4})

    assert len(results) == 1
    assert results[0] == 150
