<xsl:stylesheet version="3.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
    <xsl:output method="html" encoding="UTF-8" indent="yes"/>
    <xsl:template match="/">
        <html>
            <body>
                <h1>Test XSLT</h1>
                <p>
                    XSLT Version = <xsl:copy-of select="system-property('xsl:version')"/>
                </p>
                <p>
                    XSLT Vendor = <xsl:copy-of select="system-property('xsl:vendor')"/>
                </p>
                <p>
                    XSLT Vendor URL = <xsl:copy-of select="system-property('xsl:vendor-url')"/>
                </p>
            </body>
        </html>
    </xsl:template>
</xsl:stylesheet>
