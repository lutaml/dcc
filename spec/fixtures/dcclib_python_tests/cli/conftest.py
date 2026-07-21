import pytest
from click.testing import CliRunner

# ruff: noqa
from dcclib_test_resources.fixtures import *


@pytest.fixture(scope="module")
def runner():
    return CliRunner()
