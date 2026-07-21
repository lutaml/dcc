from dcclib.validation import SchemaVersion, XsdValidator


# This bug appeared when a validation fails and a second validation fails afterward.
# The error messages from the first validation would still be present in the result of the second validation.
# The issue was that the global error log of lxml was not cleared after performing a validation.
def test_validation_error_log_is_cleared(valid_xml, invalid_syntax_xml, custom_xsd):
    first_validator = XsdValidator.from_str(custom_xsd)
    second_validator = XsdValidator.from_version(SchemaVersion.latest)

    # Perform the first validation with a custom XSD that emits an error message
    first_res = first_validator.validate_str(valid_xml)
    # Perform a second validation with a different XSD that emits a different error message
    second_res = second_validator.validate_str(invalid_syntax_xml)

    # "This element is not expected" is an error message from the first validation
    assert not first_res.is_valid
    assert len(first_res.errors) == 1
    assert "This element is not expected" in first_res.errors[0].message
    # This should not contain any error messages from the first validation
    assert not second_res.is_valid
    assert not any("This element is not expected" in e.message for e in second_res.errors)
