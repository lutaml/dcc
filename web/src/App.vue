<script setup lang="ts">
import { ref, computed } from "vue";
import { parseDcc, validateDcc, verifySignature, type DccCert, type ValidationResult } from "./lib/dcc";

const cert = ref<DccCert | null>(null);
const validation = ref<ValidationResult>({ ok: true, issues: [] });
const loading = ref(false);
const dragActive = ref(false);
const showXml = ref(false);
const rawXml = ref("");
const sigVerifying = ref(false);
const sigResult = ref<{ verified: boolean; result?: boolean; error?: string } | null>(null);

const errors = computed(() => validation.value.issues.filter((i) => i.severity === "error"));
const warnings = computed(() => validation.value.issues.filter((i) => i.severity === "warning"));

async function processXml(xml: string) {
  loading.value = true;
  rawXml.value = xml;
  sigResult.value = null;
  try {
    validation.value = validateDcc(xml);
    cert.value = parseDcc(xml);

    if (cert.value?.signature?.present) {
      sigVerifying.value = true;
      try {
        const sig = await verifySignature(xml);
        sigResult.value = { verified: true, result: sig.verificationResult, error: sig.verificationError };
      } catch (e) {
        sigResult.value = { verified: false, error: (e as Error).message };
      }
      sigVerifying.value = false;
    }
  } catch (e) {
    validation.value = { ok: false, issues: [{ severity: "error", message: (e as Error).message }] };
    cert.value = null;
  }
  loading.value = false;
}

function onUpload(e: Event) {
  const input = e.target as HTMLInputElement;
  if (!input.files?.[0]) return;
  input.files[0].text().then(processXml);
}

function onDrop(e: DragEvent) {
  dragActive.value = false;
  const file = e.dataTransfer?.files?.[0];
  if (!file) return;
  file.text().then(processXml);
}

const demoXml = `<?xml version="1.0" encoding="UTF-8"?>
<dcc:digitalCalibrationCertificate xmlns:dcc="https://ptb.de/dcc" xmlns:si="https://ptb.de/si" schemaVersion="3.3.0">
  <dcc:administrativeData>
    <dcc:dccSoftware><dcc:software><dcc:name><dcc:content lang="en">DCC Validator</dcc:content></dcc:name><dcc:release>0.1.0</dcc:release></dcc:software></dcc:dccSoftware>
    <dcc:coreData>
      <dcc:countryCodeISO3166_1>NL</dcc:countryCodeISO3166_1>
      <dcc:usedLangCodeISO639_1>en</dcc:usedLangCodeISO639_1>
      <dcc:mandatoryLangCodeISO639_1>en</dcc:mandatoryLangCodeISO639_1>
      <dcc:uniqueIdentifier>R117-PROMASS-F300</dcc:uniqueIdentifier>
      <dcc:beginPerformanceDate>2024-03-15</dcc:beginPerformanceDate>
      <dcc:endPerformanceDate>2024-03-15</dcc:endPerformanceDate>
    </dcc:coreData>
    <dcc:items>
      <dcc:item>
        <dcc:name><dcc:content lang="en">Promass F 300 Coriolis Flow Meter</dcc:content></dcc:name>
        <dcc:manufacturer><dcc:name><dcc:content lang="en">Endress+Hauser Flowtec AG</dcc:content></dcc:name></dcc:manufacturer>
        <dcc:model>Promass F 300 DNx</dcc:model>
      </dcc:item>
    </dcc:items>
    <dcc:calibrationLaboratory>
      <dcc:calibrationLaboratoryCode>NL1</dcc:calibrationLaboratoryCode>
      <dcc:contact>
        <dcc:name><dcc:content lang="en">NMi Certin B.V.</dcc:content></dcc:name>
        <dcc:eMail>info@nmi.nl</dcc:eMail>
      </dcc:contact>
    </dcc:calibrationLaboratory>
    <dcc:respPersons>
      <dcc:respPerson>
        <dcc:person><dcc:name><dcc:content lang="en">M. Schmidt, Ph.D.</dcc:content></dcc:name><dcc:eMail>m.schmidt@nmi.nl</dcc:eMail></dcc:person>
        <dcc:mainSigner>true</dcc:mainSigner>
      </dcc:respPerson>
    </dcc:respPersons>
    <dcc:customer><dcc:name><dcc:content lang="en">Endress+Hauser Flowtec AG</dcc:content></dcc:name></dcc:customer>
  </dcc:administrativeData>
  <dcc:measurementResults>
    <dcc:measurementResult>
      <dcc:name><dcc:content lang="en">Mass flow calibration — DN25</dcc:content></dcc:name>
      <dcc:results>
        <dcc:result>
          <dcc:name><dcc:content lang="en">Maximum flow rate</dcc:content></dcc:name>
          <dcc:data><dcc:quantity>
            <dcc:name><dcc:content lang="en">Max mass flow</dcc:content></dcc:name>
            <si:real><si:value>300</si:value><si:unit>\\kilogram\\per\\minute</si:unit>
              <si:expandedMU><si:valueExpandedMU>0.15</si:valueExpandedMU><si:coverageFactor>2</si:coverageFactor><si:coverageProbability>0.95</si:coverageProbability></si:expandedMU>
            </si:real>
          </dcc:quantity></dcc:data>
        </dcc:result>
        <dcc:result>
          <dcc:name><dcc:content lang="en">Density range</dcc:content></dcc:name>
          <dcc:data>
            <dcc:quantity><dcc:name><dcc:content lang="en">Density min</dcc:content></dcc:name><si:real><si:value>300</si:value><si:unit>\\kilogram\\per\\metre\\tothe{3}</si:unit></si:real></dcc:quantity>
            <dcc:quantity><dcc:name><dcc:content lang="en">Density max</dcc:content></dcc:name><si:real><si:value>1400</si:value><si:unit>\\kilogram\\per\\metre\\tothe{3}</si:unit></si:real></dcc:quantity>
          </dcc:data>
        </dcc:result>
        <dcc:result>
          <dcc:name><dcc:content lang="en">Temperature range</dcc:content></dcc:name>
          <dcc:data>
            <dcc:quantity><dcc:name><dcc:content lang="en">Temp min</dcc:content></dcc:name><si:real><si:value>-40</si:value><si:unit>\\degreeCelsius</si:unit></si:real></dcc:quantity>
            <dcc:quantity><dcc:name><dcc:content lang="en">Temp max</dcc:content></dcc:name><si:real><si:value>55</si:value><si:unit>\\degreeCelsius</si:unit></si:real></dcc:quantity>
          </dcc:data>
        </dcc:result>
      </dcc:results>
    </dcc:measurementResult>
  </dcc:measurementResults>
</dcc:digitalCalibrationCertificate>`;

function loadDemo() {
  processXml(demoXml);
}

function initials(name: string): string {
  if (!name) return "?";
  const parts = name.trim().split(/\s+/);
  if (parts.length === 1) return parts[0][0].toUpperCase();
  return (parts[0][0] + parts[parts.length - 1][0]).toUpperCase();
}
</script>

<template>
  <div class="min-h-screen bg-slate-950 text-slate-200 font-sans antialiased">
    <!-- Top bar -->
    <div class="border-b border-slate-800 bg-slate-900/50 backdrop-blur sticky top-0 z-50">
      <div class="max-w-5xl mx-auto px-6 py-3 flex items-center gap-4">
        <div class="flex items-center gap-2">
          <div class="w-8 h-8 rounded-lg bg-cyan-500/10 border border-cyan-500/30 flex items-center justify-center">
            <span class="text-cyan-400 text-lg font-bold">D</span>
          </div>
          <span class="font-semibold text-slate-100">DCC Validator</span>
        </div>
        <div class="flex-1"></div>
        <button @click="loadDemo" class="px-3 py-1.5 text-xs font-medium rounded-lg border border-slate-700 hover:border-cyan-500/50 hover:text-cyan-400 transition-colors">
          Demo
        </button>
        <label class="cursor-pointer px-3 py-1.5 text-xs font-medium rounded-lg bg-cyan-500/10 border border-cyan-500/30 text-cyan-400 hover:bg-cyan-500/20 transition-colors">
          Upload XML
          <input type="file" accept=".xml,.dcc" class="hidden" @change="onUpload" />
        </label>
      </div>
    </div>

    <!-- Drop zone -->
    <div v-if="!cert && !loading" class="max-w-2xl mx-auto px-6 pt-24">
      <div
        @dragover.prevent="dragActive = true"
        @dragleave.prevent="dragActive = false"
        @drop.prevent="onDrop"
        :class="['border-2 border-dashed rounded-2xl p-16 text-center transition-all', dragActive ? 'border-cyan-500 bg-cyan-500/5' : 'border-slate-800']"
      >
        <div class="text-5xl mb-4 opacity-30">📋</div>
        <p class="text-slate-400 mb-1">Drag a DCC XML file here</p>
        <p class="text-slate-600 text-sm">or click upload above</p>
        <button @click="loadDemo" class="mt-6 px-4 py-2 text-sm font-medium rounded-lg bg-cyan-500/10 border border-cyan-500/30 text-cyan-400 hover:bg-cyan-500/20 transition-colors">
          Try a demo certificate →
        </button>
      </div>
    </div>

    <!-- Loading -->
    <div v-if="loading" class="max-w-2xl mx-auto px-6 pt-32 text-center">
      <div class="inline-block w-8 h-8 border-2 border-cyan-500/30 border-t-cyan-500 rounded-full animate-spin mb-4"></div>
      <p class="text-slate-400 text-sm">Validating...</p>
    </div>

    <!-- Certificate view -->
    <div v-if="cert && !loading" class="max-w-5xl mx-auto px-6 py-8 space-y-4">
      <!-- Validity banner -->
      <div :class="['rounded-2xl p-5 border slide-up flex items-center gap-4', validation.ok ? 'bg-green-500/5 border-green-500/20' : 'bg-red-500/5 border-red-500/20']">
        <div :class="['w-12 h-12 rounded-xl flex items-center justify-center text-2xl', validation.ok ? 'bg-green-500/10' : 'bg-red-500/10']">
          {{ validation.ok ? "✓" : "✕" }}
        </div>
        <div class="flex-1">
          <div :class="['font-semibold text-lg', validation.ok ? 'text-green-400' : 'text-red-400']">
            {{ validation.ok ? "Certificate Valid" : "Validation Failed" }}
          </div>
          <div class="text-sm text-slate-500">
            {{ errors.length }} error{{ errors.length === 1 ? "" : "s" }},
            {{ warnings.length }} warning{{ warnings.length === 1 ? "" : "s" }}
            <span v-if="cert.schemaVersion"> · Schema v{{ cert.schemaVersion }}</span>
          </div>
        </div>
        <div :class="['flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-medium', validation.ok ? 'bg-green-500/10 text-green-400 border border-green-500/20' : 'bg-red-500/10 text-red-400 border border-red-500/20']">
          <span class="w-1.5 h-1.5 rounded-full pulse-dot" :class="validation.ok ? 'bg-green-400' : 'bg-red-400'"></span>
          {{ validation.ok ? "VALID" : "INVALID" }}
        </div>
      </div>

      <!-- Errors -->
      <div v-if="errors.length" class="slide-up rounded-xl border border-red-500/15 bg-red-500/[0.03] overflow-hidden">
        <div class="px-5 py-3 border-b border-red-500/10 text-xs font-semibold uppercase tracking-wide text-red-400/80">Validation Errors</div>
        <div class="divide-y divide-red-500/5">
          <div v-for="(e, i) in errors" :key="i" class="px-5 py-3 flex gap-3">
            <span class="text-red-500/50 text-xs font-mono pt-0.5">{{ e.line ? "L" + e.line : "—" }}</span>
            <span class="text-sm text-slate-300">{{ e.message }}</span>
          </div>
        </div>
      </div>

      <!-- Identity -->
      <div class="slide-up rounded-2xl border border-slate-800 bg-slate-900 overflow-hidden">
        <div class="bg-gradient-to-br from-slate-900 to-slate-800/50 p-6 relative overflow-hidden">
          <div class="absolute top-0 right-0 w-64 h-64 bg-cyan-500/5 rounded-full blur-3xl"></div>
          <div class="relative flex justify-between items-start gap-4">
            <div>
              <div class="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-[10px] font-semibold uppercase tracking-wider border border-cyan-500/30 text-cyan-400 bg-cyan-500/5 mb-3">
                <span class="w-1 h-1 rounded-full bg-cyan-400 pulse-dot"></span>
                Digital Calibration Certificate
              </div>
              <h1 class="text-2xl font-bold text-slate-100 mb-1">{{ cert.itemName || "Calibration Certificate" }}</h1>
              <p class="text-slate-400">{{ cert.labName }}</p>
              <p class="font-mono text-xs text-slate-600 mt-1.5">ID: {{ cert.uniqueId || "—" }}</p>
            </div>
            <div class="text-right border-l border-slate-700 pl-6">
              <div class="text-[10px] uppercase tracking-wider text-slate-500">Schema</div>
              <div class="font-mono text-green-400 font-medium">v{{ cert.schemaVersion }}</div>
              <div v-if="cert.country" class="mt-2">
                <div class="text-[10px] uppercase tracking-wider text-slate-500">Country</div>
                <div class="font-mono text-lg">{{ cert.country }}</div>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- Core data -->
      <div v-if="cert.coreData.length" class="slide-up rounded-xl border border-slate-800 bg-slate-900 overflow-hidden">
        <div class="px-5 py-3 border-b border-slate-800 text-xs font-semibold uppercase tracking-wide text-slate-500">Core Data</div>
        <div class="grid grid-cols-2 sm:grid-cols-3 gap-px bg-slate-800/50">
          <div v-for="f in cert.coreData" :key="f.label" class="bg-slate-900 p-3">
            <div class="text-[10px] uppercase tracking-wider text-slate-600 mb-0.5">{{ f.label }}</div>
            <div class="font-mono text-sm text-slate-200">{{ f.value }}</div>
          </div>
        </div>
      </div>

      <!-- Measurements -->
      <div v-if="cert.measurements.length" class="slide-up rounded-xl border border-slate-800 bg-slate-900 overflow-hidden">
        <div class="px-5 py-3 border-b border-slate-800 text-xs font-semibold uppercase tracking-wide text-slate-500">Measurement Results</div>
        <div class="p-5 space-y-3">
          <div v-for="mr in cert.measurements" :key="mr.name" class="rounded-lg border border-slate-800 bg-slate-800/40 p-4">
            <div class="font-medium text-slate-200 mb-3">{{ mr.name }}</div>
            <div class="space-y-2">
              <div v-for="r in mr.results" :key="r.name" class="py-2 border-l-2 border-cyan-500/30 pl-3 bg-cyan-500/[0.03] rounded-r-lg">
                <div class="text-sm text-slate-400 mb-1">{{ r.name }}</div>
                <div v-for="q in r.quantities" :key="q.name" class="flex items-baseline gap-2 font-mono text-sm pl-2">
                  <span v-if="q.name !== r.name" class="text-slate-500 text-xs">{{ q.name }}:</span>
                  <span class="text-green-400">{{ q.value }}</span>
                  <span class="text-slate-600">{{ q.unit }}</span>
                  <span v-if="q.uncertainty" class="text-amber-400/60 text-xs">±{{ q.uncertainty }}</span>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- Lab + Signers -->
      <div class="slide-up grid sm:grid-cols-2 gap-4">
        <div v-if="cert.labName" class="rounded-xl border border-slate-800 bg-slate-900 overflow-hidden">
          <div class="px-5 py-3 border-b border-slate-800 text-xs font-semibold uppercase tracking-wide text-slate-500">Calibration Laboratory</div>
          <div class="p-5">
            <div class="font-medium text-slate-200 mb-1">{{ cert.labName }}</div>
            <div v-if="cert.labEmail" class="font-mono text-xs text-slate-500">{{ cert.labEmail }}</div>
            <div v-if="cert.labAddress" class="text-sm text-slate-400 mt-2">{{ cert.labAddress }}</div>
          </div>
        </div>
        <div v-if="cert.signers.length" class="rounded-xl border border-slate-800 bg-slate-900 overflow-hidden">
          <div class="px-5 py-3 border-b border-slate-800 text-xs font-semibold uppercase tracking-wide text-slate-500">Responsible Persons</div>
          <div class="p-5 space-y-2">
            <div v-for="s in cert.signers" :key="s.name" class="flex items-center gap-3 rounded-lg border border-slate-800 bg-slate-800/40 px-3 py-2">
              <div class="w-8 h-8 rounded-full bg-cyan-500 text-slate-900 flex items-center justify-center text-xs font-bold">{{ initials(s.name) }}</div>
              <div class="flex-1">
                <div class="text-sm font-medium text-slate-200">{{ s.name }}</div>
                <div v-if="s.email" class="font-mono text-xs text-slate-500">{{ s.email }}</div>
              </div>
              <span v-if="s.mainSigner" class="px-2 py-0.5 rounded-full text-[10px] font-semibold uppercase tracking-wider text-green-400 border border-green-500/20 bg-green-500/10">Main</span>
            </div>
          </div>
        </div>
      </div>

      <!-- Signature -->
      <div v-if="cert.signature?.present" class="slide-up rounded-xl border border-slate-800 bg-slate-900 overflow-hidden">
        <div class="px-5 py-3 border-b border-slate-800 flex items-center gap-2">
          <span class="text-slate-500">🔏</span>
          <span class="text-xs font-semibold uppercase tracking-wide text-slate-500">Digital Signature</span>
        </div>
        <div class="p-5">
          <!-- Verifying -->
          <div v-if="sigVerifying" class="flex items-center gap-3">
            <div class="inline-block w-5 h-5 border-2 border-cyan-500/30 border-t-cyan-500 rounded-full animate-spin"></div>
            <span class="text-sm text-slate-400">Verifying signature with Web Crypto...</span>
          </div>
          <!-- Verified result -->
          <div v-else-if="sigResult?.verified" class="flex items-center gap-4">
            <div :class="['w-10 h-10 rounded-lg flex items-center justify-center text-xl',
                 sigResult.result ? 'bg-green-500/10 text-green-400' : 'bg-red-500/10 text-red-400']">
              {{ sigResult.result ? '✓' : '✕' }}
            </div>
            <div class="flex-1">
              <div :class="['font-medium', sigResult.result ? 'text-green-400' : 'text-red-400']">
                {{ sigResult.result ? 'Signature Valid' : 'Signature Invalid' }}
              </div>
              <div v-if="sigResult.error" class="text-xs text-red-400/60 mt-0.5">{{ sigResult.error }}</div>
              <div class="text-xs text-slate-600 mt-0.5">Verified via xmldsigjs + Web Crypto API</div>
            </div>
          </div>
          <!-- Not verified -->
          <div v-else class="flex items-center gap-4">
            <div class="w-10 h-10 rounded-lg bg-amber-500/10 flex items-center justify-center text-xl text-amber-400">⚠</div>
            <div class="flex-1">
              <div class="font-medium text-amber-400">Signature Present — NOT Verified</div>
              <div class="text-xs text-slate-600 mt-0.5">Cryptographic verification was not performed</div>
            </div>
          </div>
          <!-- Sig details -->
          <div class="mt-4 grid grid-cols-2 gap-px bg-slate-800/50 rounded-lg overflow-hidden" v-if="cert.signature.method || cert.signature.certificateHash">
            <div v-if="cert.signature.method" class="bg-slate-900 p-3">
              <div class="text-[10px] uppercase tracking-wider text-slate-600 mb-0.5">Signature Algorithm</div>
              <div class="font-mono text-xs text-slate-300 truncate">{{ cert.signature.method.split("/").pop() }}</div>
            </div>
            <div v-if="cert.signature.certificateHash" class="bg-slate-900 p-3">
              <div class="text-[10px] uppercase tracking-wider text-slate-600 mb-0.5">Certificate Hash</div>
              <div class="font-mono text-xs text-slate-300">{{ cert.signature.certificateHash }}</div>
            </div>
          </div>
        </div>
      </div>

      <!-- XML source -->
      <div class="slide-up rounded-xl border border-slate-800 bg-slate-900 overflow-hidden">
        <button @click="showXml = !showXml" class="w-full px-5 py-3 flex items-center justify-between text-xs font-semibold uppercase tracking-wide text-slate-500 hover:bg-slate-800/50 transition-colors">
          <span>XML Source</span>
          <span>{{ showXml ? "▲" : "▼" }}</span>
        </button>
        <div v-if="showXml" class="p-5 overflow-auto max-h-96">
          <pre class="text-xs text-slate-400 font-mono whitespace-pre-wrap">{{ rawXml }}</pre>
        </div>
      </div>
    </div>
  </div>
</template>
