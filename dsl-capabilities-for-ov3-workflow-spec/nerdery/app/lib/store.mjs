// The wildlife store: the application's state as plain records, and the photo bytes beside it.
// Every operation runs in a transaction over a draft copy of the state. A failure leaves the state as it was, so a
// refusal or a storage failure keeps nothing. Storage faults are injectable per collection, as the acceptance cases
// arrange them: UNAVAILABLE makes every access fail, and FAIL_BEFORE_COMMIT makes every write fail.
import fs from "node:fs";
import path from "node:path";
import crypto from "node:crypto";

export class StorageError extends Error {
  constructor(collection) { super(`storage for ${collection} failed`); this.collection = collection; }
}

export const sha256 = (bytes) => crypto.createHash("sha256").update(bytes).digest("hex");

// A stored location is the canonical form record_animal_encounter keeps: a manual description or device coordinates.
export function canonicalLocation(location) {
  if (location === null || typeof location !== "object" || Array.isArray(location)) return null;
  const source = scalar(location.source);
  if (source === "manual") {
    const description = scalar(location.description);
    return description !== null && description.trim().length > 0 ? { source: "manual", description } : null;
  }
  if (source === "device") {
    const latitude = decimal6(location.latitude), longitude = decimal6(location.longitude);
    if (latitude === null || longitude === null || latitude < -90 || latitude > 90 || longitude < -180 || longitude > 180) return null;
    return { source: "device", latitude, longitude };
  }
  return null;
}

// JSON_VALUE: a scalar as text, or null for an object, an array, null or a missing member.
export function scalar(value) {
  if (typeof value === "string") return value;
  if (typeof value === "number") return String(value);
  if (typeof value === "boolean") return value ? "true" : "false";
  return null;
}

// TRY_CONVERT(int, JSON_VALUE(...)).
export function integer(value) {
  const text = scalar(value);
  if (text === null || !/^\s*[+-]?\d+\s*$/.test(text)) return null;
  const number = Number(text.trim());
  return Number.isSafeInteger(number) && Math.abs(number) <= 2147483647 ? number : null;
}

// TRY_CONVERT(decimal(9,6), JSON_VALUE(...)).
function decimal6(value) {
  const text = scalar(value);
  if (text === null || !/^\s*[+-]?(\d+\.?\d*|\.\d+)\s*$/.test(text)) return null;
  const number = Math.round(Number(text) * 1e6) / 1e6;
  return Math.abs(number) < 1000 ? number : null;
}

// The state of a fixture arrangement: the pinned base with the case's top-level replacements and retained avatars.
export function stateFromFixture(base, media, fixture = {}) {
  const s = { ...base, ...(fixture.replaceTopLevel || {}) };
  const extraAvatars = ((fixture.arrangement || {}).retainedAvatarReferences || [])
    .map((photoRef) => ({ photoRef, path: base.avatarPhotos[0].path, sha256: base.avatarPhotos[0].sha256 }));
  const blobs = new Map();
  const bytesFor = (digest) => media.get(String(digest || "").replace(/^sha256:/, "")) || null;
  const photos = [];
  for (const p of s.photos || []) {
    const bytes = bytesFor(p.contentSha256);
    if (bytes) blobs.set(p.photoRef, bytes);
    photos.push({ photoRef: p.photoRef, ownerUserId: p.ownerUserId ?? null, purpose: "encounter", mediaType: p.mediaType,
      contentSha256: p.contentSha256, byteLength: bytes ? bytes.length : null, durable: p.durable === true });
  }
  for (const a of [...(s.avatarPhotos || []), ...extraAvatars]) {
    const bytes = bytesFor(a.sha256);
    if (bytes) blobs.set(a.photoRef, bytes);
    photos.push({ photoRef: a.photoRef, ownerUserId: null, purpose: "avatar", mediaType: "image/png", contentSha256: a.sha256,
      byteLength: bytes ? bytes.length : null, durable: true });
  }
  const state = {
    users: (s.users || []).map((u) => ({ userId: u.userId, identitySubject: u.identitySubject, firstName: u.firstName, lastName: u.lastName,
      email: u.email, roles: [...(u.roles || [])] })),
    counties: (s.counties || []).map((c) => ({ countyId: c.countyId, name: c.name })),
    types: [...(s.types || [])],
    attributes: (s.attributes || []).map((a) => ({ attributeId: a.attributeId, revision: a.revision, active: a.active, name: a.name,
      description: a.description ?? null, selectableValues: (a.selectableValues || []).map((v) => ({ valueId: v.valueId, label: v.label })) })),
    definitions: (s.animalDefinitions || []).map((d) => structuredClone(d)),
    photos,
    encounters: (s.encounters || []).map((e) => ({ encounterId: e.encounterId, ownerUserId: e.ownerUserId, definitionId: e.definitionId,
      location: canonicalLocation(e.location) ?? e.location, photoRef: e.photoRef, nickname: e.nickname ?? null })),
    teams: (s.teams || []).map((t) => ({ ownerUserId: t.ownerUserId, revision: t.revision, encounterIds: [...t.encounterIds] })),
    identityResponses: structuredClone(s.identityResponses || {})
  };
  return { state, blobs };
}

// The faults a case arranges: storage per collection, and the DNR identity service.
export function faultsFromFixture(fixture = {}) {
  const faults = { unavailable: new Set(), failWrites: new Set(), identityService: "AVAILABLE" };
  const collections = { catalogStorage: "definitions", photoStorage: "photos", encounterStorage: "encounters", teamStorage: "teams" };
  for (const [key, value] of Object.entries(fixture.providerBehavior || {})) {
    if (key === "dnrIdentity") { faults.identityService = value; continue; }
    const collection = collections[key];
    if (!collection) throw new Error(`no fault injection for ${key}`);
    if (value === "UNAVAILABLE") faults.unavailable.add(collection);
    else if (value === "FAIL_BEFORE_COMMIT") faults.failWrites.add(collection);
    else throw new Error(`fault ${key}=${value}`);
  }
  return faults;
}

export class Store {
  constructor({ state, blobs, faults, persist }) {
    this.state = state;
    this.blobs = blobs;
    this.faults = faults || { unavailable: new Set(), failWrites: new Set(), identityService: "AVAILABLE" };
    this.persist = persist || null;
  }

  // Runs fn over a draft; keeps the draft and the new photo bytes only when fn returns and wrote something.
  transaction(fn) {
    const draft = structuredClone(this.state);
    const newBlobs = new Map();
    let dirty = false;
    const guard = (name, write) => {
      if (this.faults.unavailable.has(name) || (write && this.faults.failWrites.has(name))) throw new StorageError(name);
    };
    const tx = {
      get: (name) => { guard(name, false); return draft[name]; },
      put: (name, mutate) => { guard(name, true); mutate(draft[name]); dirty = true; },
      blob: (photoRef) => newBlobs.get(photoRef) ?? this.blobs.get(photoRef) ?? null,
      putBlob: (photoRef, bytes) => { newBlobs.set(photoRef, bytes); },
      identityService: () => this.faults.identityService
    };
    const result = fn(tx);
    if (dirty) {
      this.state = draft;
      for (const [ref, bytes] of newBlobs) this.blobs.set(ref, bytes);
      if (this.persist) this.persist(this, [...newBlobs.keys()]);
    }
    return result;
  }

  // The digest of everything stored, to prove a refusal or a read left it unchanged.
  digest() {
    const blobs = [...this.blobs.entries()].map(([ref, bytes]) => [ref, sha256(bytes)]).sort(([a], [b]) => (a < b ? -1 : a > b ? 1 : 0));
    return sha256(Buffer.from(JSON.stringify({ state: this.state, blobs }), "utf8"));
  }
}

// ---------- the local application's store on disk ----------
export function readFixtures(packageDir) {
  const base = JSON.parse(fs.readFileSync(path.join(packageDir, "fixtures/base-state.json"), "utf8"));
  const media = new Map();
  for (const file of fs.readdirSync(path.join(packageDir, "fixtures/media"))) {
    const bytes = fs.readFileSync(path.join(packageDir, "fixtures/media", file));
    media.set(sha256(bytes), bytes);
  }
  return { base, media };
}

// The demo starts as the SideFX slice's seed did: the synthetic catalog and the other users' collections, with
// Avery (user-a) holding no photos, encounters or team.
export function demoSeed(base, media) {
  const seedBase = { ...base,
    photos: base.photos.filter((p) => p.ownerUserId !== "user-a"),
    encounters: base.encounters.filter((e) => e.ownerUserId !== "user-a"),
    teams: base.teams.filter((t) => t.ownerUserId !== "user-a") };
  return stateFromFixture(seedBase, media);
}

export function openDiskStore(dataDir, packageDir, { reset = false } = {}) {
  const statePath = path.join(dataDir, "state.json"), photoDir = path.join(dataDir, "photos");
  if (reset) fs.rmSync(dataDir, { recursive: true, force: true });
  fs.mkdirSync(photoDir, { recursive: true });
  const persist = (store, newRefs) => {
    for (const ref of newRefs) fs.writeFileSync(path.join(photoDir, `${ref}.bin`), store.blobs.get(ref));
    const tmp = `${statePath}.tmp`;
    fs.writeFileSync(tmp, JSON.stringify(store.state, null, 1));
    fs.renameSync(tmp, statePath);
  };
  if (!fs.existsSync(statePath)) {
    const { base, media } = readFixtures(packageDir);
    const { state, blobs } = demoSeed(base, media);
    const store = new Store({ state, blobs, persist });
    persist(store, [...blobs.keys()]);
    return store;
  }
  const state = JSON.parse(fs.readFileSync(statePath, "utf8"));
  const blobs = new Map();
  for (const file of fs.readdirSync(photoDir)) if (file.endsWith(".bin")) blobs.set(file.slice(0, -4), fs.readFileSync(path.join(photoDir, file)));
  return new Store({ state, blobs, persist });
}
