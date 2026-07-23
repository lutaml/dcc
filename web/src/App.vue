<script setup lang="ts">
import { ref, computed } from "vue";
import { parseDcc, validateDcc, verifySignature, type DccCert, type ValidationResult } from "./lib/dcc";
import { emptyForm, emptyQuantity, generateDccXml, type BuilderForm } from "./lib/builder";
import unitData from "./lib/units.json";

interface UnitEntry { label: string; symbol: string; siunitx: string }
interface QuantityType { name: string; short: string; units: UnitEntry[] }

type Mode = "validate" | "create";
const mode = ref<Mode>("validate");

// === Validate ===
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
      } catch (e) { sigResult.value = { verified: false, error: (e as Error).message }; }
      sigVerifying.value = false;
    }
  } catch (e) {
    validation.value = { ok: false, issues: [{ severity: "error", message: (e as Error).message }] };
    cert.value = null;
  }
  loading.value = false;
}

function onUpload(e: Event) { const f = (e.target as HTMLInputElement).files?.[0]; if (f) f.text().then(processXml); }
function onDrop(e: DragEvent) { dragActive.value = false; const f = e.dataTransfer?.files?.[0]; if (f) f.text().then(processXml); }

function demoForm(): BuilderForm {
  const f = emptyForm();
  f.uniqueId = "R117-PROMASS-F300"; f.country = "NL"; f.languages = "en, de";
  f.itemName = "Promass F 300 Coriolis Flow Meter"; f.itemModel = "Promass F 300 DNx";
  f.manufacturer = "Endress+Hauser Flowtec AG"; f.labName = "NMi Certin B.V.";
  f.labEmail = "info@nmi.nl"; f.labCode = "NL1"; f.signerName = "M. Schmidt, Ph.D.";
  f.signerEmail = "m.schmidt@nmi.nl"; f.customerName = "Endress+Hauser Flowtec AG";
  f.measurements = [{ name: "Mass flow calibration", quantities: [
    { ...emptyQuantity(), name: "Max mass flow", value: "300", quantityType: "mass_flow", unitLabel: "kg/min", unitSiunitx: "\\kilogram\\per\\minute", uncertainty: "0.15" },
    { ...emptyQuantity(), name: "Density min", value: "300", quantityType: "density", unitLabel: "kg/m³", unitSiunitx: "\\kilogram\\per\\metre\\tothe{3}", hasUncertainty: false },
    { ...emptyQuantity(), name: "Density max", value: "1400", quantityType: "density", unitLabel: "kg/m³", unitSiunitx: "\\kilogram\\per\\metre\\tothe{3}", hasUncertainty: false },
  ]}];
  return f;
}

function loadDemo() { processXml(generateDccXml(demoForm())); }
function initials(name: string): string {
  if (!name) return "?"; const p = name.trim().split(/\s+/);
  return p.length === 1 ? p[0][0].toUpperCase() : (p[0][0] + p[p.length-1][0]).toUpperCase();
}

// === Create ===
const form = ref<BuilderForm>(emptyForm());
const previewXml = ref("");
const showPreview = ref(false);
const buildErrors = ref<string[]>([]);
const quantities = unitData as QuantityType[];

function addMeasurement() { form.value.measurements.push({ name: "", quantities: [emptyQuantity()] }); }
function removeMeasurement(i: number) { form.value.measurements.splice(i, 1); }
function addQuantity(mi: number) { form.value.measurements[mi].quantities.push(emptyQuantity()); }
function removeQuantity(mi: number, qi: number) { form.value.measurements[mi].quantities.splice(qi, 1); }

function onQuantityTypeChange(q: BuilderQuantity) {
  const qt = quantities.find(qt => qt.short === q.quantityType);
  if (qt && qt.units.length > 0) {
    q.unitSiunitx = qt.units[0].siunitx;
    q.unitLabel = qt.units[0].label;
  }
}

function onUnitChange(q: BuilderQuantity) {
  const qt = quantities.find(qt => qt.short === q.quantityType);
  if (qt) {
    const u = qt.units.find(u => u.label === q.unitLabel);
    if (u) q.unitSiunitx = u.siunitx;
  }
}

function onCoverageFactorChange(q: BuilderQuantity) {
  q.coverageProbability = q.coverageFactor === "1" ? "0.68" : q.coverageFactor === "2" ? "0.95" : q.coverageFactor === "3" ? "0.99" : "0.95";
}
function generatePreview() {
  previewXml.value = generateDccXml(form.value);
  buildErrors.value = validateDcc(previewXml.value).issues.filter(i => i.severity === "error").map(i => i.message);
  showPreview.value = true;
}
function downloadXml() {
  const xml = previewXml.value || generateDccXml(form.value);
  const blob = new Blob([xml], { type: "application/xml" });
  const url = URL.createObjectURL(blob);
  const a = document.createElement("a"); a.href = url;
  a.download = (form.value.uniqueId || "certificate").replace(/[^a-zA-Z0-9-]/g, "_") + ".xml";
  a.click(); URL.revokeObjectURL(url);
}
function loadDemoForm() { form.value = demoForm(); }
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
          <span class="font-semibold text-slate-100">DCC</span>
        </div>
        <!-- Tabs -->
        <div class="flex gap-1 ml-2">
          <button @click="mode = 'validate'" :class="['px-3 py-1.5 text-xs font-medium rounded-lg transition-colors', mode === 'validate' ? 'bg-cyan-500/10 text-cyan-400 border border-cyan-500/30' : 'text-slate-500 hover:text-slate-300']">Validate</button>
          <button @click="mode = 'create'" :class="['px-3 py-1.5 text-xs font-medium rounded-lg transition-colors', mode === 'create' ? 'bg-cyan-500/10 text-cyan-400 border border-cyan-500/30' : 'text-slate-500 hover:text-slate-300']">Create</button>
        </div>
        <div class="flex-1"></div>
        <template v-if="mode === 'validate'">
          <button @click="loadDemo" class="px-3 py-1.5 text-xs font-medium rounded-lg border border-slate-700 hover:border-cyan-500/50 hover:text-cyan-400 transition-colors">Demo</button>
          <label class="cursor-pointer px-3 py-1.5 text-xs font-medium rounded-lg bg-cyan-500/10 border border-cyan-500/30 text-cyan-400 hover:bg-cyan-500/20 transition-colors">Upload XML<input type="file" accept=".xml,.dcc" class="hidden" @change="onUpload" /></label>
        </template>
        <template v-else>
          <button @click="loadDemoForm" class="px-3 py-1.5 text-xs font-medium rounded-lg border border-slate-700 hover:border-cyan-500/50 hover:text-cyan-400 transition-colors">Fill Demo</button>
          <button @click="generatePreview" class="px-3 py-1.5 text-xs font-medium rounded-lg bg-cyan-500/10 border border-cyan-500/30 text-cyan-400 hover:bg-cyan-500/20 transition-colors">Generate</button>
        </template>
      </div>
    </div>

    <!-- ===== VALIDATE ===== -->
    <template v-if="mode === 'validate'">
      <div v-if="!cert && !loading" class="max-w-2xl mx-auto px-6 pt-24">
        <div @dragover.prevent="dragActive = true" @dragleave.prevent="dragActive = false" @drop.prevent="onDrop" :class="['border-2 border-dashed rounded-2xl p-16 text-center transition-all', dragActive ? 'border-cyan-500 bg-cyan-500/5' : 'border-slate-800']">
          <div class="text-5xl mb-4 opacity-30">📋</div>
          <p class="text-slate-400 mb-1">Drag a DCC XML file here</p>
          <p class="text-slate-600 text-sm">or click upload above</p>
          <button @click="loadDemo" class="mt-6 px-4 py-2 text-sm font-medium rounded-lg bg-cyan-500/10 border border-cyan-500/30 text-cyan-400 hover:bg-cyan-500/20 transition-colors">Try a demo certificate →</button>
        </div>
      </div>
      <div v-if="loading" class="max-w-2xl mx-auto px-6 pt-32 text-center">
        <div class="inline-block w-8 h-8 border-2 border-cyan-500/30 border-t-cyan-500 rounded-full animate-spin mb-4"></div>
        <p class="text-slate-400 text-sm">Validating...</p>
      </div>
      <div v-if="cert && !loading" class="max-w-5xl mx-auto px-6 py-8 space-y-4">
        <div :class="['rounded-2xl p-5 border slide-up flex items-center gap-4', validation.ok ? 'bg-green-500/5 border-green-500/20' : 'bg-red-500/5 border-red-500/20']">
          <div :class="['w-12 h-12 rounded-xl flex items-center justify-center text-2xl', validation.ok ? 'bg-green-500/10' : 'bg-red-500/10']">{{ validation.ok ? '✓' : '✕' }}</div>
          <div class="flex-1">
            <div :class="['font-semibold text-lg', validation.ok ? 'text-green-400' : 'text-red-400']">{{ validation.ok ? 'Certificate Valid' : 'Validation Failed' }}</div>
            <div class="text-sm text-slate-500">{{ errors.length }} error{{ errors.length === 1 ? '' : 's' }}, {{ warnings.length }} warning{{ warnings.length === 1 ? '' : 's' }}<span v-if="cert.schemaVersion"> · Schema v{{ cert.schemaVersion }}</span></div>
          </div>
          <div :class="['flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-medium', validation.ok ? 'bg-green-500/10 text-green-400 border border-green-500/20' : 'bg-red-500/10 text-red-400 border border-red-500/20']"><span class="w-1.5 h-1.5 rounded-full pulse-dot" :class="validation.ok ? 'bg-green-400' : 'bg-red-400'"></span>{{ validation.ok ? 'VALID' : 'INVALID' }}</div>
        </div>
        <div v-if="errors.length" class="slide-up rounded-xl border border-red-500/15 bg-red-500/[0.03] overflow-hidden">
          <div class="px-5 py-3 border-b border-red-500/10 text-xs font-semibold uppercase tracking-wide text-red-400/80">Validation Errors</div>
          <div class="divide-y divide-red-500/5"><div v-for="(e, i) in errors" :key="i" class="px-5 py-3 flex gap-3"><span class="text-red-500/50 text-xs font-mono pt-0.5">{{ e.line ? 'L' + e.line : '—' }}</span><span class="text-sm text-slate-300">{{ e.message }}</span></div></div>
        </div>
        <div class="slide-up rounded-2xl border border-slate-800 bg-slate-900 overflow-hidden">
          <div class="bg-gradient-to-br from-slate-900 to-slate-800/50 p-6 relative overflow-hidden">
            <div class="absolute top-0 right-0 w-64 h-64 bg-cyan-500/5 rounded-full blur-3xl"></div>
            <div class="relative flex justify-between items-start gap-4">
              <div>
                <div class="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-[10px] font-semibold uppercase tracking-wider border border-cyan-500/30 text-cyan-400 bg-cyan-500/5 mb-3"><span class="w-1 h-1 rounded-full bg-cyan-400 pulse-dot"></span>Digital Calibration Certificate</div>
                <h1 class="text-2xl font-bold text-slate-100 mb-1">{{ cert.itemName || 'Calibration Certificate' }}</h1>
                <p class="text-slate-400">{{ cert.labName }}</p>
                <p class="font-mono text-xs text-slate-600 mt-1.5">ID: {{ cert.uniqueId || '—' }}</p>
              </div>
              <div class="text-right border-l border-slate-700 pl-6">
                <div class="text-[10px] uppercase tracking-wider text-slate-500">Schema</div><div class="font-mono text-green-400 font-medium">v{{ cert.schemaVersion }}</div>
                <div v-if="cert.country" class="mt-2"><div class="text-[10px] uppercase tracking-wider text-slate-500">Country</div><div class="font-mono text-lg">{{ cert.country }}</div></div>
              </div>
            </div>
          </div>
        </div>
        <div v-if="cert.coreData.length" class="slide-up rounded-xl border border-slate-800 bg-slate-900 overflow-hidden">
          <div class="px-5 py-3 border-b border-slate-800 text-xs font-semibold uppercase tracking-wide text-slate-500">Core Data</div>
          <div class="grid grid-cols-2 sm:grid-cols-3 gap-px bg-slate-800/50"><div v-for="f in cert.coreData" :key="f.label" class="bg-slate-900 p-3"><div class="text-[10px] uppercase tracking-wider text-slate-600 mb-0.5">{{ f.label }}</div><div class="font-mono text-sm text-slate-200">{{ f.value }}</div></div></div>
        </div>
        <div v-if="cert.measurements.length" class="slide-up rounded-xl border border-slate-800 bg-slate-900 overflow-hidden">
          <div class="px-5 py-3 border-b border-slate-800 text-xs font-semibold uppercase tracking-wide text-slate-500">Measurement Results</div>
          <div class="p-5 space-y-3">
            <div v-for="mr in cert.measurements" :key="mr.name" class="rounded-lg border border-slate-800 bg-slate-800/40 p-4">
              <div class="font-medium text-slate-200 mb-3">{{ mr.name }}</div>
              <div class="space-y-2">
                <div v-for="r in mr.results" :key="r.name" class="py-2 border-l-2 border-cyan-500/30 pl-3 bg-cyan-500/[0.03] rounded-r-lg">
                  <div class="text-sm text-slate-400 mb-1">{{ r.name }}</div>
                  <div v-for="q in r.quantities" :key="q.name" class="flex items-baseline gap-2 font-mono text-sm pl-2"><span v-if="q.name !== r.name" class="text-slate-500 text-xs">{{ q.name }}:</span><span class="text-green-400">{{ q.value }}</span><span class="text-slate-600">{{ q.unit }}</span><span v-if="q.uncertainty" class="text-amber-400/60 text-xs">±{{ q.uncertainty }}</span></div>
                </div>
              </div>
            </div>
          </div>
        </div>
        <div v-if="cert.signature?.present" class="slide-up rounded-xl border border-slate-800 bg-slate-900 overflow-hidden">
          <div class="px-5 py-3 border-b border-slate-800 flex items-center gap-2"><span>🔏</span><span class="text-xs font-semibold uppercase tracking-wide text-slate-500">Digital Signature</span></div>
          <div class="p-5">
            <div v-if="sigVerifying" class="flex items-center gap-3"><div class="inline-block w-5 h-5 border-2 border-cyan-500/30 border-t-cyan-500 rounded-full animate-spin"></div><span class="text-sm text-slate-400">Verifying signature...</span></div>
            <div v-else-if="sigResult?.verified" class="flex items-center gap-4">
              <div :class="['w-10 h-10 rounded-lg flex items-center justify-center text-xl', sigResult.result ? 'bg-green-500/10 text-green-400' : 'bg-red-500/10 text-red-400']">{{ sigResult.result ? '✓' : '✕' }}</div>
              <div class="flex-1"><div :class="['font-medium', sigResult.result ? 'text-green-400' : 'text-red-400']">{{ sigResult.result ? 'Signature Valid' : 'Signature Invalid' }}</div><div v-if="sigResult.error" class="text-xs text-red-400/60 mt-0.5">{{ sigResult.error }}</div></div>
            </div>
            <div v-else class="flex items-center gap-4"><div class="w-10 h-10 rounded-lg bg-amber-500/10 flex items-center justify-center text-xl text-amber-400">⚠</div><div class="font-medium text-amber-400">Signature Present — NOT Verified</div></div>
          </div>
        </div>
        <div class="slide-up grid sm:grid-cols-2 gap-4">
          <div v-if="cert.labName" class="rounded-xl border border-slate-800 bg-slate-900 overflow-hidden"><div class="px-5 py-3 border-b border-slate-800 text-xs font-semibold uppercase tracking-wide text-slate-500">Calibration Laboratory</div><div class="p-5"><div class="font-medium text-slate-200 mb-1">{{ cert.labName }}</div><div v-if="cert.labEmail" class="font-mono text-xs text-slate-500">{{ cert.labEmail }}</div></div></div>
          <div v-if="cert.signers.length" class="rounded-xl border border-slate-800 bg-slate-900 overflow-hidden"><div class="px-5 py-3 border-b border-slate-800 text-xs font-semibold uppercase tracking-wide text-slate-500">Responsible Persons</div><div class="p-5 space-y-2"><div v-for="s in cert.signers" :key="s.name" class="flex items-center gap-3 rounded-lg border border-slate-800 bg-slate-800/40 px-3 py-2"><div class="w-8 h-8 rounded-full bg-cyan-500 text-slate-900 flex items-center justify-center text-xs font-bold">{{ initials(s.name) }}</div><div class="flex-1"><div class="text-sm font-medium text-slate-200">{{ s.name }}</div><div v-if="s.email" class="font-mono text-xs text-slate-500">{{ s.email }}</div></div><span v-if="s.mainSigner" class="px-2 py-0.5 rounded-full text-[10px] font-semibold uppercase tracking-wider text-green-400 border border-green-500/20 bg-green-500/10">Main</span></div></div></div>
        </div>
        <div class="slide-up rounded-xl border border-slate-800 bg-slate-900 overflow-hidden"><button @click="showXml = !showXml" class="w-full px-5 py-3 flex items-center justify-between text-xs font-semibold uppercase tracking-wide text-slate-500 hover:bg-slate-800/50 transition-colors"><span>XML Source</span><span>{{ showXml ? '▲' : '▼' }}</span></button><div v-if="showXml" class="p-5 overflow-auto max-h-96"><pre class="text-xs text-slate-400 font-mono whitespace-pre-wrap">{{ rawXml }}</pre></div></div>
      </div>
    </template>

    <!-- ===== CREATE ===== -->
    <template v-else>
      <div class="max-w-3xl mx-auto px-6 py-8 space-y-5">
        <div class="rounded-xl border border-slate-800 bg-slate-900 overflow-hidden slide-up">
          <div class="px-5 py-3 border-b border-slate-800 text-xs font-semibold uppercase tracking-wide text-slate-500">Certificate Identity</div>
          <div class="p-5 grid grid-cols-2 gap-4">
            <label class="block"><span class="text-xs text-slate-500">Unique Identifier *</span><input v-model="form.uniqueId" placeholder="e.g. PTB-12345-2026" class="mt-1 w-full bg-slate-800 border border-slate-700 rounded-lg px-3 py-2 text-sm text-slate-200 focus:border-cyan-500 focus:outline-none" /></label>
            <label class="block"><span class="text-xs text-slate-500">Country (ISO 3166-1) *</span><input v-model="form.country" maxlength="2" class="mt-1 w-full bg-slate-800 border border-slate-700 rounded-lg px-3 py-2 text-sm text-slate-200 uppercase focus:border-cyan-500 focus:outline-none" /></label>
            <label class="block"><span class="text-xs text-slate-500">Languages</span><input v-model="form.languages" placeholder="en, de" class="mt-1 w-full bg-slate-800 border border-slate-700 rounded-lg px-3 py-2 text-sm text-slate-200 focus:border-cyan-500 focus:outline-none" /></label>
            <label class="block"><span class="text-xs text-slate-500">Schema Version</span><select v-model="form.schemaVersion" class="mt-1 w-full bg-slate-800 border border-slate-700 rounded-lg px-3 py-2 text-sm text-slate-200 focus:border-cyan-500 focus:outline-none"><option>3.3.0</option><option>3.2.1</option><option>2.3.0</option></select></label>
            <label class="block"><span class="text-xs text-slate-500">Begin Date</span><input type="date" v-model="form.beginDate" class="mt-1 w-full bg-slate-800 border border-slate-700 rounded-lg px-3 py-2 text-sm text-slate-200 focus:border-cyan-500 focus:outline-none" /></label>
            <label class="block"><span class="text-xs text-slate-500">End Date</span><input type="date" v-model="form.endDate" class="mt-1 w-full bg-slate-800 border border-slate-700 rounded-lg px-3 py-2 text-sm text-slate-200 focus:border-cyan-500 focus:outline-none" /></label>
          </div>
        </div>
        <div class="rounded-xl border border-slate-800 bg-slate-900 overflow-hidden slide-up">
          <div class="px-5 py-3 border-b border-slate-800 text-xs font-semibold uppercase tracking-wide text-slate-500">Calibrated Item</div>
          <div class="p-5 grid grid-cols-2 gap-4">
            <label class="block col-span-2"><span class="text-xs text-slate-500">Item Name *</span><input v-model="form.itemName" placeholder="e.g. Resistance Thermometer Pt100" class="mt-1 w-full bg-slate-800 border border-slate-700 rounded-lg px-3 py-2 text-sm text-slate-200 focus:border-cyan-500 focus:outline-none" /></label>
            <label class="block"><span class="text-xs text-slate-500">Model</span><input v-model="form.itemModel" class="mt-1 w-full bg-slate-800 border border-slate-700 rounded-lg px-3 py-2 text-sm text-slate-200 focus:border-cyan-500 focus:outline-none" /></label>
            <label class="block"><span class="text-xs text-slate-500">Manufacturer</span><input v-model="form.manufacturer" class="mt-1 w-full bg-slate-800 border border-slate-700 rounded-lg px-3 py-2 text-sm text-slate-200 focus:border-cyan-500 focus:outline-none" /></label>
          </div>
        </div>
        <div class="rounded-xl border border-slate-800 bg-slate-900 overflow-hidden slide-up">
          <div class="px-5 py-3 border-b border-slate-800 text-xs font-semibold uppercase tracking-wide text-slate-500">Calibration Laboratory</div>
          <div class="p-5 grid grid-cols-2 gap-4">
            <label class="block"><span class="text-xs text-slate-500">Lab Name</span><input v-model="form.labName" class="mt-1 w-full bg-slate-800 border border-slate-700 rounded-lg px-3 py-2 text-sm text-slate-200 focus:border-cyan-500 focus:outline-none" /></label>
            <label class="block"><span class="text-xs text-slate-500">Lab Code</span><input v-model="form.labCode" placeholder="e.g. DE1, NL1" class="mt-1 w-full bg-slate-800 border border-slate-700 rounded-lg px-3 py-2 text-sm text-slate-200 focus:border-cyan-500 focus:outline-none" /></label>
            <label class="block col-span-2"><span class="text-xs text-slate-500">Email</span><input v-model="form.labEmail" class="mt-1 w-full bg-slate-800 border border-slate-700 rounded-lg px-3 py-2 text-sm text-slate-200 focus:border-cyan-500 focus:outline-none" /></label>
          </div>
        </div>
        <div class="rounded-xl border border-slate-800 bg-slate-900 overflow-hidden slide-up">
          <div class="px-5 py-3 border-b border-slate-800 text-xs font-semibold uppercase tracking-wide text-slate-500">Responsible Person</div>
          <div class="p-5 grid grid-cols-2 gap-4">
            <label class="block"><span class="text-xs text-slate-500">Name</span><input v-model="form.signerName" class="mt-1 w-full bg-slate-800 border border-slate-700 rounded-lg px-3 py-2 text-sm text-slate-200 focus:border-cyan-500 focus:outline-none" /></label>
            <label class="block"><span class="text-xs text-slate-500">Email</span><input v-model="form.signerEmail" class="mt-1 w-full bg-slate-800 border border-slate-700 rounded-lg px-3 py-2 text-sm text-slate-200 focus:border-cyan-500 focus:outline-none" /></label>
          </div>
        </div>
        <div class="rounded-xl border border-slate-800 bg-slate-900 overflow-hidden slide-up">
          <div class="px-5 py-3 border-b border-slate-800 text-xs font-semibold uppercase tracking-wide text-slate-500">Customer</div>
          <div class="p-5"><label class="block"><span class="text-xs text-slate-500">Customer Name</span><input v-model="form.customerName" class="mt-1 w-full bg-slate-800 border border-slate-700 rounded-lg px-3 py-2 text-sm text-slate-200 focus:border-cyan-500 focus:outline-none" /></label></div>
        </div>
        <div class="rounded-xl border border-slate-800 bg-slate-900 overflow-hidden slide-up">
          <div class="px-5 py-3 border-b border-slate-800 flex items-center justify-between">
            <span class="text-xs font-semibold uppercase tracking-wide text-slate-500">Measurement Results</span>
            <button @click="addMeasurement" class="text-xs text-cyan-400 hover:text-cyan-300">+ Add Result</button>
          </div>
          <div class="p-5 space-y-4">
            <div v-for="(m, mi) in form.measurements" :key="mi" class="rounded-lg border border-slate-800 bg-slate-800/40 p-4">
              <div class="flex items-center gap-2 mb-3">
                <input v-model="m.name" :placeholder="'Result ' + (mi + 1)" class="flex-1 bg-slate-900 border border-slate-700 rounded-lg px-3 py-2 text-sm text-slate-200 focus:border-cyan-500 focus:outline-none" />
                <button v-if="form.measurements.length > 1" @click="removeMeasurement(mi)" class="text-xs text-red-400/60 hover:text-red-400">Remove</button>
              </div>
              <div class="space-y-3">
                <div v-for="(q, qi) in m.quantities" :key="qi" class="rounded-lg border border-slate-700/50 bg-slate-900/60 p-3 space-y-2">
                  <!-- Row 1: name + value -->
                  <div class="grid grid-cols-3 gap-2">
                    <input v-model="q.name" placeholder="Quantity name" class="bg-slate-800 border border-slate-700 rounded-lg px-2.5 py-1.5 text-xs text-slate-200 focus:border-cyan-500 focus:outline-none" />
                    <input v-model="q.value" placeholder="Measured value" class="bg-slate-800 border border-slate-700 rounded-lg px-2.5 py-1.5 text-xs text-green-400/90 font-mono focus:border-cyan-500 focus:outline-none" />
                    <button v-if="m.quantities.length > 1" @click="removeQuantity(mi, qi)" class="text-xs text-red-400/40 hover:text-red-400 justify-self-end px-2">Remove</button>
                  </div>
                  <!-- Row 2: quantity type + unit picker -->
                  <div class="grid grid-cols-2 gap-2">
                    <select v-model="q.quantityType" @change="onQuantityTypeChange(q)" class="bg-slate-800 border border-slate-700 rounded-lg px-2.5 py-1.5 text-xs text-slate-300 focus:border-cyan-500 focus:outline-none">
                      <option value="">Select quantity type...</option>
                      <option v-for="qt in quantities" :key="qt.short" :value="qt.short">{{ qt.name }}</option>
                    </select>
                    <select v-model="q.unitLabel" @change="onUnitChange(q)" :disabled="!q.quantityType" class="bg-slate-800 border border-slate-700 rounded-lg px-2.5 py-1.5 text-xs text-slate-400 font-mono focus:border-cyan-500 focus:outline-none disabled:opacity-40">
                      <option value="">Unit...</option>
                      <option v-for="u in (quantities.find(qt => qt.short === q.quantityType)?.units || [])" :key="u.label" :value="u.label">{{ u.label }}</option>
                    </select>
                  </div>
                  <!-- Row 3: uncertainty (structured) -->
                  <div class="flex items-center gap-2 pt-1">
                    <label class="flex items-center gap-1.5 text-xs text-slate-500 cursor-pointer">
                      <input type="checkbox" v-model="q.hasUncertainty" class="accent-cyan-500" />
                      Expanded uncertainty
                    </label>
                    <template v-if="q.hasUncertainty">
                      <input v-model="q.uncertainty" placeholder="U" class="w-20 bg-slate-800 border border-slate-700 rounded-lg px-2 py-1 text-xs text-amber-400/70 font-mono focus:border-cyan-500 focus:outline-none" />
                      <span class="text-slate-600 text-xs">k=</span>
                      <select v-model="q.coverageFactor" @change="onCoverageFactorChange(q)" class="bg-slate-800 border border-slate-700 rounded-lg px-2 py-1 text-xs text-slate-400 font-mono focus:border-cyan-500 focus:outline-none">
                        <option value="1">1</option><option value="2">2</option><option value="3">3</option>
                      </select>
                      <span class="text-slate-600 text-xs">p={{ q.coverageProbability }}</span>
                    </template>
                  </div>
                </div>
              </div>
              <button @click="addQuantity(mi)" class="mt-2 text-xs text-cyan-400/70 hover:text-cyan-400">+ Add Quantity</button>
            </div>
          </div>
        </div>
        <div v-if="showPreview" class="rounded-xl border border-slate-800 bg-slate-900 overflow-hidden slide-up">
          <div class="px-5 py-3 border-b border-slate-800 flex items-center justify-between">
            <span class="text-xs font-semibold uppercase tracking-wide" :class="buildErrors.length ? 'text-red-400' : 'text-green-400'">{{ buildErrors.length ? 'Validation Issues' : 'DCC XML Generated ✓' }}</span>
            <button @click="downloadXml" class="px-3 py-1.5 text-xs font-medium rounded-lg bg-cyan-500/10 border border-cyan-500/30 text-cyan-400 hover:bg-cyan-500/20 transition-colors">⬇ Download .xml</button>
          </div>
          <div v-if="buildErrors.length" class="px-5 py-3 space-y-1"><div v-for="(e, i) in buildErrors" :key="i" class="text-xs text-red-400/80">• {{ e }}</div></div>
          <div class="p-5 overflow-auto max-h-64"><pre class="text-xs text-slate-400 font-mono whitespace-pre-wrap">{{ previewXml }}</pre></div>
        </div>
      </div>
    </template>
  </div>
</template>
