<?xml version="1.0" encoding="UTF-8"?>
<sch:schema xmlns:sch="http://purl.oclc.org/dsdl/schematron" queryBinding="xslt2"
            xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
            xmlns:sqf="http://www.schematron-quickfix.com/validator/process">

    <sch:ns uri="https://ptb.de/dcc" prefix="dcc"/>
    <sch:ns uri="https://ptb.de/si" prefix="si"/>

    <sch:pattern>
        <xsl:comment>
            This pattern validates the placement of dcc:usedMethods elements within a DCC document.
            Methods can be declared globally under dcc:measurementResult, locally under dcc:list, or individually under
            each dcc:quantity element.
        </xsl:comment>

        <sch:rule context="//dcc:measurementResult">
            <sch:report role="information" test="count(dcc:usedMethods)">
                Global measurement methods declared for all results in this measurement result section.
            </sch:report>
        </sch:rule>

        <sch:rule context="//dcc:measurementResults//dcc:list[not(ancestor::dcc:metaData)]">
            <sch:report role="information" test="count(dcc:usedMethods)">
                Local measurement methods declared for all quantities in this list.
            </sch:report>
            <sch:report role="error"
                        test="count(dcc:usedMethods)=0 and count(ancestor::dcc:measurementResult/dcc:usedMethods)=0 and count(dcc:quantity)>count(dcc:quantity/dcc:usedMethods)">
                Missing measurement methods: No methods declared globally, locally, or for individual quantities. Each
                quantity must have associated used methods declared.
            </sch:report>
        </sch:rule>

        <sch:rule context="//dcc:result/dcc:data/dcc:quantity">
            <sch:report role="information" test="count(dcc:usedMethods)">
                Local measurement methods declared for this specific quantity.
            </sch:report>
            <sch:report role="error"
                        test="count(dcc:usedMethods)=0 and count(ancestor::dcc:measurementResult/dcc:usedMethods)=0">
                Missing measurement methods: No methods declared globally or locally for this quantity. Measurement
                methods are required.
            </sch:report>
        </sch:rule>

        <sch:rule context="//dcc:measurementResults//dcc:list[not(ancestor::dcc:metaData)]/dcc:quantity">
            <sch:report role="information" test="count(dcc:usedMethods)">
                Local measurement methods declared for this specific quantity within a list.
            </sch:report>
        </sch:rule>
    </sch:pattern>

    <sch:pattern>
        <xsl:comment>
            This pattern validates the placement of dcc:usedSoftware elements within a DCC document.
            Software can be declared globally under dcc:measurementResult, locally under dcc:list, or individually under
            each dcc:quantity element.
        </xsl:comment>

        <sch:rule context="//dcc:measurementResult">
            <sch:report role="information" test="count(dcc:usedSoftware)">
                Global software declaration for all results in this measurement result section.
            </sch:report>
        </sch:rule>

        <sch:rule context="//dcc:measurementResults//dcc:list[not(ancestor::dcc:metaData)]">
            <sch:report role="information" test="count(dcc:usedSoftware)">
                Local software declaration for all quantities in this list.
            </sch:report>
            <sch:report role="warning"
                        test="count(dcc:usedSoftware)=0 and count(ancestor::dcc:measurementResult/dcc:usedSoftware)=0 and count(dcc:quantity)>count(dcc:quantity/dcc:usedSoftware)">
                Software information missing: Consider declaring software used during measurement process (globally,
                locally, or per quantity).
            </sch:report>
        </sch:rule>

        <sch:rule context="//dcc:result/dcc:data/dcc:quantity">
            <sch:report role="information" test="count(dcc:usedSoftware)">
                Local software declaration for this specific quantity.
            </sch:report>
            <sch:report role="warning"
                        test="count(dcc:usedSoftware)=0 and count(ancestor::dcc:measurementResult/dcc:usedSoftware)=0">
                Software information missing: Consider declaring software used for this quantity measurement.
            </sch:report>
        </sch:rule>

        <sch:rule context="//dcc:measurementResults//dcc:list[not(ancestor::dcc:metaData)]/dcc:quantity">
            <sch:report role="information" test="count(dcc:usedSoftware)">
                Local software declaration for this specific quantity within a list.
            </sch:report>
        </sch:rule>
    </sch:pattern>

    <sch:pattern>
        <xsl:comment>
            This pattern validates the placement of dcc:influenceConditions elements within a DCC document.
            Influence conditions can be declared globally under dcc:measurementResult, locally under dcc:list, or
            individually under each dcc:quantity element.
        </xsl:comment>

        <sch:rule context="//dcc:measurementResult">
            <sch:report role="information" test="count(dcc:influenceConditions)">
                Global influence conditions declared for all results in this measurement result section.
            </sch:report>
        </sch:rule>

        <sch:rule context="//dcc:measurementResults//dcc:list[not(ancestor::dcc:metaData)]">
            <sch:report role="information" test="count(dcc:influenceConditions)">
                Local influence conditions declared for all quantities in this list.
            </sch:report>
            <sch:report role="error"
                        test="count(dcc:influenceConditions)=0 and count(ancestor::dcc:measurementResult/dcc:influenceConditions)=0 and count(dcc:quantity)>count(dcc:quantity/dcc:influenceConditions)">
                Missing influence conditions: No conditions declared globally, locally, or for individual quantities.
                Each quantity must have associated influence conditions.
            </sch:report>
        </sch:rule>

        <sch:rule context="//dcc:result/dcc:data/dcc:quantity">
            <sch:report role="information" test="count(dcc:influenceConditions)">
                Local influence conditions declared for this specific quantity.
            </sch:report>
            <sch:report role="error"
                        test="count(dcc:influenceConditions)=0 and count(ancestor::dcc:measurementResult/dcc:influenceConditions)=0">
                Missing influence conditions: No conditions declared globally or locally for this quantity. Influence
                conditions are required.
            </sch:report>
        </sch:rule>

        <sch:rule context="//dcc:measurementResults//dcc:list[not(ancestor::dcc:metaData)]/dcc:quantity">
            <sch:report role="information" test="count(dcc:influenceConditions)">
                Local influence conditions declared for this specific quantity within a list.
            </sch:report>
        </sch:rule>
    </sch:pattern>

    <sch:pattern>
        <xsl:comment>
            This pattern validates the DCC schema version to ensure the latest version is being used.
        </xsl:comment>

        <sch:rule context="dcc:digitalCalibrationCertificate">
            <sch:assert role="warning" test="@schemaVersion='3.3.0'">
                Schema version outdated: You are using schema version '<sch:value-of select="@schemaVersion"/>'. The
                latest available version is 3.3.0. Consider upgrading to ensure compatibility.
            </sch:assert>
        </sch:rule>
    </sch:pattern>

    <sch:pattern>
        <xsl:comment>
            This pattern validates that all @id and @refId attributes are properly linked within the document.
        </xsl:comment>

        <sch:let name="refIds" value="//@refId"/>
        <sch:let name="ids" value="//@id"/>

        <sch:rule context="//@id">
            <sch:assert role="warning" test="some $refId in $refIds satisfies tokenize($refId, ' ') = .">
                Unlinked ID: The ID '<sch:value-of select="."/>' is not referenced by any refId attribute. Every ID
                should be referenced.
            </sch:assert>
        </sch:rule>

        <sch:rule context="//@refId">
            <sch:assert role="error" test="some $refId in tokenize(., ' ') satisfies $ids = $refId">
                Invalid reference ID: The refId '<sch:value-of select="."/>' does not correspond to any existing ID in
                the document.
            </sch:assert>
        </sch:rule>
    </sch:pattern>

    <sch:pattern>
        <xsl:comment>
            This pattern validates language attributes in dcc:content elements against declared language codes.
        </xsl:comment>

        <sch:let name="langs" value="//dcc:usedLangCodeISO639_1"/>
        <sch:let name="langCount" value="count($langs)"/>

        <sch:rule context="dcc:content[@lang]">
            <sch:assert role="error" test="@lang = $langs">
                Invalid language code: The language code '<sch:value-of select="@lang"/>' is not declared in
                dcc:usedLangCodeISO639_1. Available codes are:<sch:value-of select="string-join($langs,', ')"/>.
            </sch:assert>
        </sch:rule>

        <sch:rule context="//*[dcc:content[@lang]]">
            <sch:let name="localLangs" value="dcc:content/@lang"/>

            <sch:assert role="error" test="count($localLangs) = $langCount">
                The dcc:content elements use only [<sch:value-of select="string-join($localLangs, ', ')"/>] of the
                declared languages [<sch:value-of select="string-join($langs, ', ')"/>]. Add missing languages or use
                one without a @lang attribute.
            </sch:assert>

            <sch:assert role="error" test="count($localLangs) = count(distinct-values($localLangs))">
                Duplicate language codes detected in dcc:content elements: [<sch:value-of
                    select="string-join($localLangs, ', ')"/>]. Each dcc:content element must use a unique @lang value.
            </sch:assert>
        </sch:rule>

        <sch:rule context="dcc:content">
            <sch:report role="warning"
                        test="not(@lang) and (count(../../dcc:name)=0 and count(../../dcc:further)=0 and count(../../dcc:referral)=0)">
                Language attribute missing: Consider adding a language attribute to this content element for better
                internationalization.
            </sch:report>
        </sch:rule>
    </sch:pattern>

    <sch:pattern>
        <xsl:comment>
            This pattern validates that calibration end date is not before the beginning date.
        </xsl:comment>

        <sch:rule context="dcc:coreData/dcc:endPerformanceDate">
            <sch:let name="eDate" value="xs:date(.)"/>
            <sch:let name="bDate" value="xs:date(../dcc:beginPerformanceDate)"/>
            <sch:assert role="error" test="$bDate le $eDate">
                Invalid date range: The calibration end date (<sch:value-of select="."/>) cannot be before the beginning
                date (<sch:value-of select="../dcc:beginPerformanceDate"/>).
            </sch:assert>
        </sch:rule>
    </sch:pattern>

    <sch:pattern>
        <xsl:comment>
            This pattern validates the format of software release version numbers.
        </xsl:comment>

        <sch:rule context="//dcc:release">
            <sch:assert role="error" test="(matches(text(), '^[a-zA-Z]{1}( )?([0-9]{1,3}\.){0,3}([0-9]{1,3})$'))">
                Invalid release version format: The release version '<sch:value-of select="text()"/>' for software '
                <sch:value-of select="preceding-sibling::dcc:name[1]/dcc:content[1]/text()"/>' does not follow the
                required format (e.g., 'v1.2.3' or 'A 1.0').
            </sch:assert>
        </sch:rule>
    </sch:pattern>

    <sch:pattern>
        <xsl:comment>
            This pattern validates ISO language and country codes against standard lists.
        </xsl:comment>

        <sch:let name="lc"
                 value="string-join(('aa', 'ab', 'ae', 'af', 'ak', 'am', 'an', 'ar', 'as', 'av', 'ay', 'az', 'ba', 'be', 'bg', 'bi', 'bm', 'bn', 'bo', 'br', 'bs', 'ca', 'ce', 'ch', 'co', 'cr', 'cs', 'cu', 'cv', 'cy', 'da', 'de', 'dv', 'dz', 'ee', 'el', 'en', 'eo', 'es', 'et', 'eu', 'fa', 'ff', 'fi', 'fj', 'fo', 'fr', 'fy', 'ga', 'gd', 'gl', 'gn', 'gu', 'gv', 'ha', 'he', 'hi', 'ho', 'hr', 'ht', 'hu', 'hy', 'hz', 'ia', 'id', 'ie', 'ig', 'ii', 'ik', 'io', 'is', 'it', 'iu', 'ja', 'jv', 'ka', 'kg', 'ki', 'kj', 'kk', 'kl', 'km', 'kn', 'ko', 'kr', 'ks', 'ku', 'kv', 'kw', 'ky', 'la', 'lb', 'lg', 'li', 'ln', 'lo', 'lt', 'lu', 'lv', 'mg', 'mh', 'mi', 'mk', 'ml', 'mn', 'mr', 'ms', 'mt', 'my', 'na', 'nb', 'nd', 'ne', 'ng', 'nl', 'nn', 'no', 'nr', 'nv', 'ny', 'oc', 'oj', 'om', 'or', 'os', 'pa', 'pi', 'pl', 'ps', 'pt', 'qu', 'rm', 'rn', 'ro', 'ru', 'rw', 'sa', 'sc', 'sd', 'se', 'sg', 'si', 'sk', 'sl', 'sm', 'sn', 'so', 'sq', 'sr', 'ss', 'st', 'su', 'sv', 'sw', 'ta', 'te', 'tg', 'th', 'ti', 'tk', 'tl', 'tn', 'to', 'tr', 'ts', 'tt', 'tw', 'ty', 'ug', 'uk', 'ur', 'uz', 've', 'vi', 'vo', 'wa', 'wo', 'xh', 'yi', 'yo', 'za', 'zh', 'zu'), ' ')"/>

        <sch:rule context="//dcc:usedLangCodeISO639_1">
            <sch:assert role="error" test="contains($lc, text())">
                Invalid ISO 639-1 language code: '<sch:value-of select="text()"/>' is not a valid language code
                according to the ISO 639-1 standard.
            </sch:assert>
        </sch:rule>

        <sch:rule context="//dcc:mandatoryLangCodeISO639_1">
            <sch:assert role="error" test="contains($lc, text())">
                Invalid ISO 639-1 language code: '<sch:value-of select="text()"/>' is not a valid language code
                according to the ISO 639-1 standard.
            </sch:assert>
        </sch:rule>

        <sch:rule context="//dcc:countryCodeISO3166_1">
            <sch:let name="cc"
                     value="string-join(('AD', 'AO', 'AI', 'AQ', 'AG', 'AR', 'AM', 'AW', 'AU', 'AT', 'AZ', 'BS', 'BH', 'BD', 'BB', 'BY', 'BE', 'BZ', 'BJ', 'BM', 'BT', 'BO', 'BQ', 'BA', 'BW', 'BV', 'BR', 'IO', 'BN', 'BG', 'BF', 'BI', 'CV', 'KH', 'CM', 'CA', 'KY', 'CF', 'TD', 'CL', 'CN', 'CX', 'CC', 'CO', 'KM', 'CD', 'CG', 'CK', 'CR', 'CI', 'HR', 'CU', 'CW', 'CY', 'CZ', 'DE', 'DK', 'DJ', 'DM', 'DO', 'EC', 'EG', 'SV', 'GQ', 'ER', 'EE', 'SZ', 'ET', 'FK', 'FO', 'FJ', 'FI', 'FR', 'GF', 'PF', 'TF', 'GA', 'GM', 'GE', 'DE', 'GH', 'GI', 'GR', 'GL', 'GD', 'GP', 'GU', 'GT', 'GG', 'GN', 'GW', 'GY', 'HT', 'HM', 'VA', 'HN', 'HK', 'HU', 'IS', 'IN', 'ID', 'IR', 'IQ', 'IE', 'IM', 'IL', 'IT', 'JM', 'JP', 'JE', 'JO', 'KZ', 'KE', 'KI', 'KP', 'KR', 'KW', 'KG', 'LA', 'LV', 'LB', 'LS', 'LR', 'LY', 'LI', 'LT', 'LU', 'MO', 'MK', 'MG', 'MW', 'MY', 'MV', 'ML', 'MT', 'MH', 'MQ', 'MR', 'MU', 'YT', 'MX', 'FM', 'MD', 'MC', 'MN', 'ME', 'MS', 'MA', 'MZ', 'MM', 'NA', 'NR', 'NP', 'NL', 'NC', 'NZ', 'NI', 'NE', 'NG', 'NU', 'NF', 'MP', 'NO', 'OM', 'PK', 'PW', 'PS', 'PA', 'PG', 'PY', 'PE', 'PH', 'PN', 'PL', 'PT', 'PR', 'QA', 'RE', 'RO', 'RU', 'RW', 'BL', 'SH', 'KN', 'LC', 'MF', 'PM', 'VC', 'WS', 'SM', 'ST', 'SA', 'SN', 'RS', 'SC', 'SL', 'SG', 'SX', 'SK', 'SI', 'SB', 'SO', 'ZA', 'GS', 'SS', 'ES', 'LK', 'SD', 'SR', 'SJ', 'SE', 'CH', 'SY', 'TW', 'TJ', 'TZ', 'TH', 'TL', 'TG', 'TK', 'TO', 'TT', 'TN', 'TR', 'TM', 'TC', 'TV', 'UG', 'UA', 'AE', 'GB', 'UM', 'US', 'UY', 'UZ', 'VU', 'VE', 'VN', 'VG', 'VI', 'WF', 'EH', 'YE', 'ZM', 'ZW'), ' ')"/>

            <sch:assert role="error" test="contains($cc, text())">
                Invalid ISO 3166-1 country code: '<sch:value-of select="text()"/>' is not a valid country code according
                to the ISO 3166-1 standard.
            </sch:assert>
        </sch:rule>
    </sch:pattern>

    <sch:pattern>
        <xsl:comment>
            This pattern validates relative uncertainty values and their relationships with expanded uncertainty.
        </xsl:comment>

        <sch:rule context="//dcc:quantity">
            <sch:let name="valueXMLList" value="si:realListXMLList/si:valueXMLList"/>
            <sch:let name="relativeUncertaintyXmlList"
                     value="dcc:relativeUncertainty/dcc:relativeUncertaintyXmlList/si:valueXMLList"/>
            <sch:let name="uncertaintyXMLList" value="si:realListXMLList/si:expandedUncXMLList/si:uncertaintyXMLList"/>

            <sch:let name="value" value="si:real/si:value"/>
            <sch:let name="relativeUncertainty" value="dcc:relativeUncertainty/dcc:relativeUncertainty/si:value"/>
            <sch:let name="uncertainty" value="si:real/si:expandedUnc/si:uncertainty"/>

            <sch:report role="error"
                        test="count(dcc:relativeUncertainty/dcc:relativeUncertaintyXmlList)=1 and count(si:realListXMLList/si:expandedUncXMLList)=0">
                Missing expanded uncertainty: Relative uncertainty is provided but corresponding expanded uncertainty is
                missing.
            </sch:report>
            <sch:report role="error"
                        test="count(dcc:relativeUncertainty/dcc:relativeUncertainty)=1 and count(si:real/si:expandedUnc)=0">
                Missing expanded uncertainty: Relative uncertainty is provided but corresponding expanded uncertainty is
                missing.
            </sch:report>

            <sch:report role="error"
                        test="count(dcc:relativeUncertainty/dcc:relativeUncertaintyXmlList)=0 and count(dcc:relativeUncertainty/dcc:relativeUncertainty)=1 and count(si:realListXMLList/si:valueXMLList)=1 and count(si:real/si:value)=0">
                Inconsistent data format: Value list requires relative uncertainty list, not single relative uncertainty
                value.
            </sch:report>
            <sch:report role="error"
                        test="count(dcc:relativeUncertainty/dcc:relativeUncertaintyXmlList)=1 and count(dcc:relativeUncertainty/dcc:relativeUncertainty)=0 and count(si:realListXMLList/si:valueXMLList)=0 and count(si:real/si:value)=1">
                Inconsistent data format: Single value requires single relative uncertainty, not relative uncertainty
                list.
            </sch:report>

            <sch:report role="error"
                        test="($relativeUncertainty) != ($uncertainty) div ($value) and count(dcc:relativeUncertainty/dcc:relativeUncertainty/si:value) = 1">
                Incorrect relative uncertainty calculation: The relative uncertainty value (<sch:value-of
                    select="$relativeUncertainty"/>) does not match the calculation (uncertainty/value =<sch:value-of
                    select="$uncertainty div $value"/>).
            </sch:report>
        </sch:rule>

        <sch:rule context="//dcc:relativeUncertainty">
            <sch:let name="relativeUncertaintyXmlList" value="dcc:relativeUncertaintyXmlList/si:valueXMLList"/>
            <sch:let name="valueXMLList" value="preceding-sibling::si:realListXMLList/si:valueXMLList"/>

            <sch:report role="error"
                        test="(count(tokenize($valueXMLList, ' ')) != count(tokenize($relativeUncertaintyXmlList, ' '))) and (count(tokenize($relativeUncertaintyXmlList, ' ')) > 1)">
                Count mismatch: The number of relative uncertainty values (<sch:value-of
                    select="count(tokenize($relativeUncertaintyXmlList, ' '))"/>) must match the number of measurement
                values (<sch:value-of select="count(tokenize($valueXMLList, ' '))"/>) when not using a constant
                uncertainty.
            </sch:report>
        </sch:rule>

        <sch:rule context="//si:realListXMLList">
            <sch:let name="uncertaintyXMLList" value="si:expandedUncXMLList/si:uncertaintyXMLList"/>
            <sch:let name="valueXMLList" value="si:valueXMLList"/>

            <sch:report role="error"
                        test="(count(tokenize($valueXMLList, ' ')) != count(tokenize($uncertaintyXMLList, ' '))) and (count(tokenize($uncertaintyXMLList, ' ')) > 1) and count(si:expandedUncXMLList/si:uncertaintyXMLList)=1">
                Count mismatch: The number of expanded uncertainty values (<sch:value-of
                    select="count(tokenize($uncertaintyXMLList, ' '))"/>) must match the number of measurement values (
                <sch:value-of select="count(tokenize($valueXMLList, ' '))"/>) when not using constant uncertainty.
            </sch:report>
        </sch:rule>
    </sch:pattern>

    <sch:pattern>
        <xsl:comment>
            This pattern validates units and unit lists to ensure proper formatting and consistency.
        </xsl:comment>

        <sch:rule context="//si:real/si:unit">
            <sch:report role="error" test="count(tokenize(., ' ')) > 1">
                Invalid unit format: Units cannot contain spaces. Found '<sch:value-of select="."/>'.
            </sch:report>
        </sch:rule>
        <sch:rule context="//si:unitXMLList">
            <sch:report role="error"
                        test="count(tokenize(., ' ')) > 1 and not(count(tokenize(., ' ')) = count(tokenize(preceding-sibling::si:valueXMLList)))">
                Unit count mismatch: If units vary across values, you must provide a unit for each value. Found
                <sch:value-of select="count(tokenize(., ' '))"/>
                units for
                <sch:value-of select="count(tokenize(preceding-sibling::si:valueXMLList, ' '))"/>
                values.
            </sch:report>
            <sch:report role="warning"
                        test="count(tokenize(., ' ')) > 1 and (every $value in tokenize(., ' ') satisfies ($value = tokenize(., ' ')))">
                Redundant unit specification: All units in the list are identical ('<sch:value-of
                    select="tokenize(., ' ')[1]"/>'). Consider using a single unit declaration for better clarity.
            </sch:report>
        </sch:rule>
    </sch:pattern>

    <sch:pattern>
        <xsl:comment>
            This pattern validates that non-SI units are properly declared before use.
        </xsl:comment>

        <sch:let name="nonSI" value="//dcc:statement/dcc:nonSIUnit"/>
        <sch:rule context="//si:hybrid/si:real/si:unit">
            <sch:report role="error" test="not(text()=$nonSI) and matches(text(), '^\|.+')">
                Undeclared non-SI unit: The unit '<sch:value-of select="text()"/>' appears to be a non-SI unit but is
                not declared in the dcc:nonSIUnit statements.
            </sch:report>
        </sch:rule>

        <sch:rule context="//dcc:nonSIUnit">
            <sch:assert role="error" test="count(preceding-sibling::dcc:nonSIDefinition)=1">
                Missing non-SI unit definition: The non-SI unit '<sch:value-of select="text()"/>' must have a
                corresponding definition in dcc:nonSIDefinition.
            </sch:assert>
        </sch:rule>

        <sch:rule context="//dcc:nonSIDefinition">
            <sch:assert role="error" test="count(following-sibling::dcc:nonSIUnit)=1">
                Missing non-SI unit declaration: The non-SI unit definition must have a corresponding unit declaration
                in dcc:nonSIUnit.
            </sch:assert>
        </sch:rule>
    </sch:pattern>

    <sch:pattern>
        <xsl:comment>
            This pattern validates that language codes are not declared multiple times.
        </xsl:comment>

        <sch:rule context="dcc:usedLangCodeISO639_1">
            <sch:report role="error"
                        test="text()=preceding-sibling::dcc:usedLangCodeISO639_1/text() or text()=following-sibling::dcc:usedLangCodeISO639_1/text()">
                Duplicate language code: The language code '<sch:value-of select="text()"/>' is declared multiple times.
                Each language code may only be declared once.
            </sch:report>
        </sch:rule>
    </sch:pattern>

    <sch:pattern>
        <xsl:comment>
            This pattern validates XML list formatting to ensure proper spacing between entries.
            XML lists must contain exactly one space between entries, no leading/trailing spaces, and no multiple
            consecutive spaces.
        </xsl:comment>

        <sch:rule context="//si:valueXMLList">
            <sch:assert role="error" test="(matches(., '^([^\s]+\s)*([^\s]+)$'))">
                Invalid list formatting: XML list contains improper spacing. Ensure exactly one space separates entries
                with no leading/trailing spaces.
            </sch:assert>
        </sch:rule>

        <sch:rule context="//si:unitXMLList">
            <sch:assert role="error" test="(matches(., '^([^\s]+\s)*([^\s]+)$'))">
                Invalid list formatting: Unit XML list contains improper spacing. Ensure exactly one space separates
                entries with no leading/trailing spaces.
            </sch:assert>
        </sch:rule>

        <sch:rule context="//si:labelXMLList">
            <sch:assert role="error" test="(matches(., '^([^\s]+\s)*([^\s]+)$'))">
                Invalid list formatting: Label XML list contains improper spacing. Ensure exactly one space separates
                entries with no leading/trailing spaces.
            </sch:assert>
        </sch:rule>

        <sch:rule context="//si:dateTimeXMLList">
            <sch:assert role="error" test="(matches(., '^([^\s]+\s)*([^\s]+)$'))">
                Invalid list formatting: DateTime XML list contains improper spacing. Ensure exactly one space separates
                entries with no leading/trailing spaces.
            </sch:assert>
        </sch:rule>

        <sch:rule context="//si:uncertaintyXMLList">
            <sch:assert role="error" test="(matches(., '^([^\s]+\s)*([^\s]+)$'))">
                Invalid list formatting: Uncertainty XML list contains improper spacing. Ensure exactly one space
                separates entries with no leading/trailing spaces.
            </sch:assert>
        </sch:rule>

        <sch:rule context="//si:coverageFactorXMLList">
            <sch:assert role="error" test="(matches(., '^([^\s]+\s)*([^\s]+)$'))">
                Invalid list formatting: Coverage factor XML list contains improper spacing. Ensure exactly one space
                separates entries with no leading/trailing spaces.
            </sch:assert>
        </sch:rule>

        <sch:rule context="//si:coverageProbabilityXMLList">
            <sch:assert role="error" test="(matches(., '^([^\s]+\s)*([^\s]+)$'))">
                Invalid list formatting: Coverage probability XML list contains improper spacing. Ensure exactly one
                space separates entries with no leading/trailing spaces.
            </sch:assert>
        </sch:rule>

        <sch:rule context="//si:distributionXMLList">
            <sch:assert role="error" test="(matches(., '^([^\s]+\s)*([^\s]+)$'))">
                Invalid list formatting: Distribution XML list contains improper spacing. Ensure exactly one space
                separates entries with no leading/trailing spaces.
            </sch:assert>
        </sch:rule>

        <sch:rule context="//si:standardUncXMLList">
            <sch:assert role="error" test="(matches(., '^([^\s]+\s)*([^\s]+)$'))">
                Invalid list formatting: Standard uncertainty XML list contains improper spacing. Ensure exactly one
                space separates entries with no leading/trailing spaces.
            </sch:assert>
        </sch:rule>

        <sch:rule context="//si:intervalMinXMLList">
            <sch:assert role="error" test="(matches(., '^([^\s]+\s)*([^\s]+)$'))">
                Invalid list formatting: Interval minimum XML list contains improper spacing. Ensure exactly one space
                separates entries with no leading/trailing spaces.
            </sch:assert>
        </sch:rule>

        <sch:rule context="//si:intervalMaxXMLList">
            <sch:assert role="error" test="(matches(., '^([^\s]+\s)*([^\s]+)$'))">
                Invalid list formatting: Interval maximum XML list contains improper spacing. Ensure exactly one space
                separates entries with no leading/trailing spaces.
            </sch:assert>
        </sch:rule>

        <sch:rule context="//dcc:dateTimeXMLListType">
            <sch:assert role="error" test="(matches(., '^([^\s]+\s)*([^\s]+)$'))">
                Invalid list formatting: DateTime list contains improper spacing. Ensure exactly one space separates
                entries with no leading/trailing spaces.
            </sch:assert>
        </sch:rule>

        <sch:rule context="//dcc:stringConformityStatementStatusXMLListType">
            <sch:assert role="error" test="(matches(., '^([^\s]+\s)*([^\s]+)$'))">
                Invalid list formatting: Conformity statement status list contains improper spacing. Ensure exactly one
                space separates entries with no leading/trailing spaces.
            </sch:assert>
        </sch:rule>

        <sch:rule context="//@refType">
            <sch:assert role="error" test="(matches(., '^([^\s]+\s)*([^\s]+)$'))">
                Invalid attribute formatting: The refType attribute '<sch:value-of select="."/>' contains improper
                spacing. Ensure exactly one space separates entries with no leading/trailing spaces.
            </sch:assert>
        </sch:rule>

        <sch:rule context="//@refId">
            <sch:assert role="error" test="(matches(., '^([^\s]+\s)*([^\s]+)$'))">
                Invalid attribute formatting: The refId attribute '<sch:value-of select="."/>' contains improper
                spacing. Ensure exactly one space separates entries with no leading/trailing spaces.
            </sch:assert>
        </sch:rule>
    </sch:pattern>
</sch:schema>
