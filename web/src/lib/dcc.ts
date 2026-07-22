export interface DccContent {
  lang?: string;
  text: string;
}

export interface DccQuantity {
  name: string;
  value?: string;
  unit?: string;
  uncertainty?: string;
}

export interface DccResult {
  name: string;
  quantities: DccQuantity[];
}

export interface DccMeasurementResult {
  name: string;
  results: DccResult[];
}

export interface DccSigner {
  name: string;
  email?: string;
  mainSigner: boolean;
}

export interface DccCert {
  schemaVersion: string;
  uniqueId: string;
  country: string;
  itemName: string;
  labName: string;
  labEmail?: string;
  labAddress?: string;
  model?: string;
  manufacturer?: string;
  coreData: { label: string; value: string }[];
  signers: DccSigner[];
  measurements: DccMeasurementResult[];
}

export interface ValidationIssue {
  severity: "error" | "warning" | "info";
  message: string;
  line?: number;
}

export interface ValidationResult {
  ok: boolean;
  issues: ValidationIssue[];
}

const DCC_NS = "https://ptb.de/dcc";
const SI_NS = "https://ptb.de/si";

function localName(tag: string): string {
  return tag.includes(":") ? tag.split(":").pop()! : tag;
}

function getText(el: Element | null | undefined): string {
  if (!el) return "";
  const contents = el.getElementsByTagNameNS(DCC_NS, "content");
  if (contents.length === 0) return el.textContent?.trim() || "";
  for (let i = 0; i < contents.length; i++) {
    const c = contents[i];
    const lang = c.getAttribute("lang") || c.getAttributeNS("http://www.w3.org/XML/1998/namespace", "lang");
    if (lang === "en") return c.textContent?.trim() || "";
  }
  return contents[0]?.textContent?.trim() || "";
}

function getFirst(el: Element | null, localName: string, ns = DCC_NS): Element | null {
  if (!el) return null;
  return el.getElementsByTagNameNS(ns, localName)[0] || null;
}

function getAll(el: Element | null, localName: string, ns = DCC_NS): Element[] {
  if (!el) return [];
  return Array.from(el.getElementsByTagNameNS(ns, localName));
}

export function parseDcc(xml: string): DccCert {
  const doc = new DOMParser().parseFromString(xml, "text/xml");
  const root = doc.documentElement;
  const admin = getFirst(root, "administrativeData");
  const core = getFirst(admin, "coreData");
  const items = getFirst(admin, "items");
  const item = getFirst(items, "item");
  const lab = getFirst(admin, "calibrationLaboratory");
  const labContact = getFirst(lab, "contact");
  const respPersons = getFirst(admin, "respPersons");
  const customer = getFirst(admin, "customer");
  const measurementResults = getFirst(root, "measurementResults");

  const coreData: { label: string; value: string }[] = [];
  if (core) {
    const uid = getText(getFirst(core, "uniqueIdentifier"));
    if (uid) coreData.push({ label: "Unique ID", value: uid });

    const begin = getFirst(core, "beginPerformanceDate")?.textContent?.trim();
    if (begin) coreData.push({ label: "Begin Date", value: begin });

    const end = getFirst(core, "endPerformanceDate")?.textContent?.trim();
    if (end) coreData.push({ label: "End Date", value: end });

    const langs = getAll(core, "usedLangCodeISO639_1").map((e) => e.textContent?.trim() || "");
    if (langs.length) coreData.push({ label: "Languages", value: langs.join(", ") });

    const mandatory = getFirst(core, "mandatoryLangCodeISO639_1")?.textContent?.trim();
    if (mandatory) coreData.push({ label: "Mandatory Lang", value: mandatory });
  }

  const signers: DccSigner[] = getAll(respPersons, "respPerson").map((rp) => {
    const person = getFirst(rp, "person");
    return {
      name: getText(getFirst(person, "name")),
      email: getFirst(person, "eMail")?.textContent?.trim() || undefined,
      mainSigner: getFirst(rp, "mainSigner")?.textContent?.trim() === "true",
    };
  });

  const measurements: DccMeasurementResult[] = getAll(measurementResults, "measurementResult").map((mr) => {
    const results: DccResult[] = getAll(getFirst(mr, "results"), "result").map((r) => {
      const quantities: DccQuantity[] = [];

      const dataEls = getAll(r, "data");
      for (const data of dataEls) {
        for (const q of getAll(data, "quantity")) {
          const name = getText(getFirst(q, "name"));

          for (const siEl of Array.from(q.children)) {
            if (siEl.namespaceURI === SI_NS) {
              const value = getFirst(siEl, "value", SI_NS)?.textContent?.trim();
              const unit = getFirst(siEl, "unit", SI_NS)?.textContent?.trim();
              const expMu = getFirst(siEl, "expandedMU", SI_NS);
              const expUnc = getFirst(siEl, "expandedUnc", SI_NS);
              const muEl = expMu || expUnc;
              const uncertainty = getFirst(muEl, "valueExpandedMU", SI_NS)?.textContent?.trim()
                || getFirst(muEl, "uncertainty", SI_NS)?.textContent?.trim();

              if (value) {
                quantities.push({ name: name || "—", value, unit: unit || "", uncertainty: uncertainty || undefined });
              }
            }
          }

          if (quantities.length === 0 && name) {
            quantities.push({ name });
          }
        }
      }

      return { name: getText(getFirst(r, "name")), quantities };
    });

    return { name: getText(getFirst(mr, "name")), results };
  });

  const loc = getFirst(labContact, "location");
  const addrParts: string[] = [];
  if (loc) {
    const street = getFirst(loc, "street")?.textContent?.trim();
    const no = getFirst(loc, "streetNo")?.textContent?.trim();
    if (street) addrParts.push(`${street} ${no || ""}`.trim());
    const pc = getFirst(loc, "postCode")?.textContent?.trim();
    const city = getFirst(loc, "city")?.textContent?.trim();
    if (pc) addrParts.push(`${pc} ${city || ""}`.trim());
    const cc = getFirst(loc, "countryCode")?.textContent?.trim();
    if (cc) addrParts.push(cc);
  }

  return {
    schemaVersion: root.getAttribute("schemaVersion") || "unknown",
    uniqueId: getText(getFirst(core, "uniqueIdentifier")),
    country: getFirst(core, "countryCodeISO3166_1")?.textContent?.trim() || "",
    itemName: getText(getFirst(item, "name")),
    labName: getText(getFirst(labContact, "name")),
    labEmail: getFirst(labContact, "eMail")?.textContent?.trim() || undefined,
    labAddress: addrParts.join(", ") || undefined,
    model: getFirst(item, "model")?.textContent?.trim() || undefined,
    manufacturer: getText(getFirst(getFirst(item, "manufacturer"), "name")) || undefined,
    coreData,
    signers,
    measurements,
  };
}

export function validateDcc(xml: string): ValidationResult {
  const issues: ValidationIssue[] = [];

  let doc: Document;
  try {
    doc = new DOMParser().parseFromString(xml, "text/xml");
  } catch (e) {
    return { ok: false, issues: [{ severity: "error", message: `XML parse error: ${(e as Error).message}` }] };
  }

  const parseError = doc.querySelector("parsererror");
  if (parseError) {
    return { ok: false, issues: [{ severity: "error", message: parseError.textContent || "Malformed XML" }] };
  }

  const root = doc.documentElement;
  if (!root || localName(root.tagName) !== "digitalCalibrationCertificate") {
    issues.push({ severity: "error", message: "Root element must be <digitalCalibrationCertificate>" });
    return { ok: false, issues };
  }

  const sv = root.getAttribute("schemaVersion");
  if (!sv) {
    issues.push({ severity: "warning", message: "Missing schemaVersion attribute" });
  } else if (!sv.match(/^\d+\.\d+\.\d+/)) {
    issues.push({ severity: "error", message: `Invalid schemaVersion format: "${sv}" (expected X.Y.Z)` });
  }

  const admin = getFirst(root, "administrativeData");
  if (!admin) {
    issues.push({ severity: "error", message: "Missing required element: <administrativeData>" });
  } else {
    const required = ["dccSoftware", "coreData", "items", "calibrationLaboratory", "respPersons", "customer"];
    for (const name of required) {
      if (!getFirst(admin, name)) {
        issues.push({ severity: "error", message: `Missing required element: <${name}> in <administrativeData>` });
      }
    }

    const core = getFirst(admin, "coreData");
    if (core) {
      const uid = getFirst(core, "uniqueIdentifier");
      if (!uid || !uid.textContent?.trim()) {
        issues.push({ severity: "error", message: "<uniqueIdentifier> is empty or missing" });
      }

      const country = getFirst(core, "countryCodeISO3166_1")?.textContent?.trim();
      if (country && !country.match(/^[A-Z]{2}$/)) {
        issues.push({ severity: "error", message: `Invalid ISO 3166-1 country code: "${country}" (expected 2 uppercase letters)` });
      }

      const begin = getFirst(core, "beginPerformanceDate")?.textContent?.trim();
      const end = getFirst(core, "endPerformanceDate")?.textContent?.trim();
      if (begin && end && begin > end) {
        issues.push({ severity: "error", message: `endPerformanceDate (${end}) precedes beginPerformanceDate (${begin})` });
      }
    }
  }

  const mr = getFirst(root, "measurementResults");
  if (!mr) {
    issues.push({ severity: "error", message: "Missing required element: <measurementResults>" });
  }

  const persons = getAll(getFirst(root, "administrativeData"), "respPerson");
  const mainSigners = persons.filter((p) => getFirst(p, "mainSigner")?.textContent?.trim() === "true");
  if (persons.length > 0 && mainSigners.length === 0) {
    issues.push({ severity: "warning", message: "No mainSigner designated among responsible persons" });
  }
  if (mainSigners.length > 1) {
    issues.push({ severity: "warning", message: "Multiple mainSigner=true found; expected exactly one" });
  }

  return {
    ok: issues.filter((i) => i.severity === "error").length === 0,
    issues,
  };
}
