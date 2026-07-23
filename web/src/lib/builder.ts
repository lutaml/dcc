export interface BuilderQuantity {
  name: string;
  value: string;
  quantityType: string;
  unitSiunitx: string;
  unitLabel: string;
  hasUncertainty: boolean;
  uncertainty: string;
  coverageFactor: string;
  coverageProbability: string;
}

export interface BuilderForm {
  schemaVersion: string;
  uniqueId: string;
  country: string;
  languages: string;
  beginDate: string;
  endDate: string;
  itemName: string;
  itemModel: string;
  manufacturer: string;
  labName: string;
  labEmail: string;
  labCode: string;
  signerName: string;
  signerEmail: string;
  customerName: string;
  measurements: { name: string; quantities: BuilderQuantity[] }[];
}

export function emptyForm(): BuilderForm {
  return {
    schemaVersion: "3.3.0",
    uniqueId: "",
    country: "DE",
    languages: "en",
    beginDate: new Date().toISOString().split("T")[0],
    endDate: new Date().toISOString().split("T")[0],
    itemName: "",
    itemModel: "",
    manufacturer: "",
    labName: "",
    labEmail: "",
    labCode: "",
    signerName: "",
    signerEmail: "",
    customerName: "",
    measurements: [
      {
        name: "",
        quantities: [emptyQuantity()],
      },
    ],
  };
}

export function emptyQuantity(): BuilderQuantity {
  return {
    name: "", value: "", quantityType: "", unitSiunitx: "", unitLabel: "",
    hasUncertainty: true, uncertainty: "", coverageFactor: "2", coverageProbability: "0.95",
  };
}

function esc(s: string): string {
  return s.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;").replace(/"/g, "&quot;");
}

export function generateDccXml(form: BuilderForm): string {
  const langs = form.languages.split(",").map((l) => l.trim()).filter(Boolean);
  const langTags = langs.map((l) => `<dcc:usedLangCodeISO639_1>${esc(l)}</dcc:usedLangCodeISO639_1>`).join("\n      ");
  const mandatoryLang = langs[0] || "en";

  const quantityXml = form.measurements
    .filter((m) => m.name || m.quantities.some((q) => q.value))
    .map((m) => {
      const quants = m.quantities
        .filter((q) => q.value)
        .map((q) => {
          const unc = (q.hasUncertainty && q.uncertainty)
            ? `\n                  <si:expandedMU>
                    <si:valueExpandedMU>${esc(q.uncertainty)}</si:valueExpandedMU>
                    <si:coverageFactor>${esc(q.coverageFactor || "2")}</si:coverageFactor>
                    <si:coverageProbability>${esc(q.coverageProbability || "0.95")}</si:coverageProbability>
                  </si:expandedMU>`
            : "";
          return `          <dcc:quantity>
            <dcc:name><dcc:content lang="en">${esc(q.name || q.quantityType || "Value")}</dcc:content></dcc:name>
            <si:real>
              <si:value>${esc(q.value)}</si:value>${q.unitSiunitx ? `\n              <si:unit>${esc(q.unitSiunitx)}</si:unit>` : ""}${unc}
            </si:real>
          </dcc:quantity>`;
        })
        .join("\n");

      return `        <dcc:result>
          <dcc:name><dcc:content lang="en">${esc(m.name)}</dcc:content></dcc:name>
          <dcc:data>
${quants}
          </dcc:data>
        </dcc:result>`;
    })
    .join("\n");

  return `<?xml version="1.0" encoding="UTF-8"?>
<dcc:digitalCalibrationCertificate
    xmlns:dcc="https://ptb.de/dcc"
    xmlns:si="https://ptb.de/si"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xsi:schemaLocation="https://ptb.de/dcc https://ptb.de/dcc/v${esc(form.schemaVersion)}/dcc.xsd"
    schemaVersion="${esc(form.schemaVersion)}">

  <dcc:administrativeData>
    <dcc:dccSoftware>
      <dcc:software>
        <dcc:name><dcc:content lang="en">DCC Validator Builder</dcc:content></dcc:name>
        <dcc:release>0.1.0</dcc:release>
      </dcc:software>
    </dcc:dccSoftware>

    <dcc:coreData>
      <dcc:countryCodeISO3166_1>${esc(form.country)}</dcc:countryCodeISO3166_1>
      ${langTags}
      <dcc:mandatoryLangCodeISO639_1>${esc(mandatoryLang)}</dcc:mandatoryLangCodeISO639_1>
      <dcc:uniqueIdentifier>${esc(form.uniqueId)}</dcc:uniqueIdentifier>
      <dcc:beginPerformanceDate>${esc(form.beginDate)}</dcc:beginPerformanceDate>
      <dcc:endPerformanceDate>${esc(form.endDate)}</dcc:endPerformanceDate>
    </dcc:coreData>

    <dcc:items>
      <dcc:item>
        <dcc:name><dcc:content lang="en">${esc(form.itemName)}</dcc:content></dcc:name>
        <dcc:manufacturer><dcc:name><dcc:content lang="en">${esc(form.manufacturer)}</dcc:content></dcc:name></dcc:manufacturer>
        <dcc:model>${esc(form.itemModel)}</dcc:model>
      </dcc:item>
    </dcc:items>

    <dcc:calibrationLaboratory>
      <dcc:calibrationLaboratoryCode>${esc(form.labCode)}</dcc:calibrationLaboratoryCode>
      <dcc:contact>
        <dcc:name><dcc:content lang="en">${esc(form.labName)}</dcc:content></dcc:name>
        <dcc:eMail>${esc(form.labEmail)}</dcc:eMail>
      </dcc:contact>
    </dcc:calibrationLaboratory>

    <dcc:respPersons>
      <dcc:respPerson>
        <dcc:person>
          <dcc:name><dcc:content lang="en">${esc(form.signerName)}</dcc:content></dcc:name>
          <dcc:eMail>${esc(form.signerEmail)}</dcc:eMail>
        </dcc:person>
        <dcc:mainSigner>true</dcc:mainSigner>
      </dcc:respPerson>
    </dcc:respPersons>

    <dcc:customer>
      <dcc:name><dcc:content lang="en">${esc(form.customerName)}</dcc:content></dcc:name>
    </dcc:customer>
  </dcc:administrativeData>

  <dcc:measurementResults>
    <dcc:measurementResult>
      <dcc:name><dcc:content lang="en">Calibration Results</dcc:content></dcc:name>
      <dcc:results>
${quantityXml}
      </dcc:results>
    </dcc:measurementResult>
  </dcc:measurementResults>
</dcc:digitalCalibrationCertificate>
`;
}
