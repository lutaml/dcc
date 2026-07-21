<?xml version="1.0" encoding="UTF-8"?>
<sch:schema xmlns:sch="http://purl.oclc.org/dsdl/schematron"
            queryBinding="xslt2"
            xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
            xmlns:sqf="http://www.schematron-quickfix.com/validator/process">

    <sch:ns uri="https://ptb.de/dcc" prefix="dcc"/>
    <sch:ns uri="https://ptb.de/si" prefix="si"/>

    <sch:pattern>
        <sch:rule context="/dcc:digitalCalibrationCertificate">
            <sch:report role="information" test="true()">Test information</sch:report>
        </sch:rule>
    </sch:pattern>
</sch:schema>
