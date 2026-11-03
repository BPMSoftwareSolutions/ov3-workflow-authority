// The wildlife application's operations, one per canonical feature. Each takes the request body and the trusted
// user (null when no session was verified) and returns the operation's result, the shape its feature asserts.
// They are ports of the slice's mechanics (nerdery/wildlife/wildlife.procedures.sql), which met every case of their
// features; invoke() runs each in one transaction and answers a storage failure with the operation's named refusal.
import crypto from "node:crypto";
import { StorageError, canonicalLocation, integer, scalar, sha256 } from "./store.mjs";

const contract = (operation) => `${operation}-result.v1`;
const refused = (operation, code, extra = {}) => ({ contractId: contract(operation), status: "REFUSED", reason: { code }, ...extra });
const notApplied = () => ({ mutation: { applied: false } });
// FOR JSON without INCLUDE_NULL_VALUES leaves a null member out.
const compact = (record) => Object.fromEntries(Object.entries(record).filter(([, value]) => value !== null && value !== undefined));
// JSON_QUERY: an object or an array, or null.
const structured = (value) => (value !== null && typeof value === "object" ? value : null);
const blank = (text) => text === null || text.trim().length === 0;
const byCodePoint = (a, b) => (a < b ? -1 : a > b ? 1 : 0);
const hasDuplicates = (values) => new Set(values).size !== values.length;
// A JSON array of strings, as OPENJSON types it: null when any element is not a string.
const strings = (list) => (list.every((value) => typeof value === "string") ? list : null);

function animalFields(definition, collected) {
  const locked = { commonName: definition.commonName, collectionNumber: definition.collectionNumber, range: definition.range,
    avatarPhotoRef: definition.avatarPhotoRef };
  if (!collected) return compact(locked);
  return compact({ ...locked, scientificName: definition.scientificName, types: definition.types, stats: definition.stats,
    attributes: definition.attributes });
}

// ---------- reads ----------
function browseAnimalCollection(tx, request, userId) {
  const op = "nerdery-browse-animal-collection";
  if (userId === null) return refused(op, "AUTHENTICATION_REQUIRED");
  // D04: a case-insensitive common-name substring; an all-digit query also matches that collection number. Locked
  // fields are never searched.
  const search = (scalar(request.search) ?? "").replace(/^ +| +$/g, "");
  const number = search !== "" && /^[0-9]+$/.test(search) && search.length <= 9 ? Number(search) : null;
  const definitions = tx.get("definitions"), encounters = tx.get("encounters");
  const items = definitions
    .filter((d) => d.active && (search === "" || String(d.commonName).toLowerCase().includes(search.toLowerCase()) || d.collectionNumber === number))
    .sort((a, b) => a.collectionNumber - b.collectionNumber)
    .map((d) => {
      const collected = encounters.some((e) => e.ownerUserId === userId && e.definitionId === d.definitionId);
      return { definitionId: d.definitionId, collectionState: collected ? "COLLECTED" : "UNCOLLECTED", animal: animalFields(d, collected) };
    });
  return { contractId: contract(op), status: "LISTED", search, total: items.length, items };
}

function viewAnimalDefinition(tx, request, userId) {
  const op = "nerdery-view-animal-definition";
  const id = scalar(request.definitionId);
  let code = null, definition = null;
  if (userId === null) code = "AUTHENTICATION_REQUIRED";
  else if (id === null) code = "ANIMAL_SELECTION_REQUIRED";
  else {
    definition = tx.get("definitions").find((d) => d.definitionId === id) ?? null;
    if (!definition) code = "ANIMAL_DEFINITION_NOT_FOUND";
    else if (!definition.active) code = "ANIMAL_DEFINITION_UNAVAILABLE";
  }
  if (code) return refused(op, code);
  const collected = tx.get("encounters").some((e) => e.ownerUserId === userId && e.definitionId === id);
  const animal = animalFields(definition, collected);
  if (collected) {
    // D14: resolved attribute details are ordered by attributeId; selected values keep their selectable order.
    const chosen = new Map();
    for (const entry of definition.attributes || []) for (const valueId of entry.valueIds || []) {
      if (!chosen.has(entry.attributeId)) chosen.set(entry.attributeId, new Set());
      chosen.get(entry.attributeId).add(valueId);
    }
    animal.attributeDetails = tx.get("attributes").filter((a) => chosen.has(a.attributeId))
      .sort((a, b) => byCodePoint(a.attributeId, b.attributeId))
      .map((a) => compact({ attributeId: a.attributeId, name: a.name, description: a.description,
        selectedValues: a.selectableValues.filter((v) => chosen.get(a.attributeId).has(v.valueId)).map((v) => compact({ valueId: v.valueId, label: v.label })) }));
  }
  return { contractId: contract(op), status: "VISIBLE", definitionId: definition.definitionId, collectionState: collected ? "COLLECTED" : "UNCOLLECTED", animal };
}

function viewCollectedAnimals(tx, request, userId) {
  const op = "nerdery-view-collected-animals";
  if (userId === null) return refused(op, "AUTHENTICATION_REQUIRED");
  // Each recorded encounter is one individual, in encounterId order (D14), shown with the user's photo and nickname,
  // or the definition's common name when no nickname was given.
  const encounters = tx.get("encounters"), definitions = new Map(tx.get("definitions").map((d) => [d.definitionId, d]));
  const items = encounters.filter((e) => e.ownerUserId === userId && definitions.has(e.definitionId))
    .sort((a, b) => byCodePoint(a.encounterId, b.encounterId))
    .map((e) => ({ encounterId: e.encounterId, ownerUserId: e.ownerUserId, definitionId: e.definitionId, photoRef: e.photoRef,
      nickname: e.nickname ?? null, displayName: e.nickname ?? definitions.get(e.definitionId).commonName ?? null }));
  return { contractId: contract(op), status: "LISTED", total: items.length, items };
}

function viewCollectedAnimal(tx, request, userId) {
  const op = "nerdery-view-collected-animal";
  const id = scalar(request.encounterId);
  let code = null;
  if (userId === null) code = "AUTHENTICATION_REQUIRED";
  else if (id === null || id.replace(/ +$/, "").length === 0) code = "ENCOUNTER_SELECTION_REQUIRED";
  // D05: another user's individual is answered as not found, so its existence is not revealed.
  else if (!tx.get("encounters").some((e) => e.ownerUserId === userId && e.encounterId === id)) code = "ENCOUNTER_NOT_FOUND";
  if (code) return refused(op, code);
  // D10: the individual is shown with the bytes of the owner's photo it was recorded with, base64 encoded, and the
  // media type and digest kept at upload.
  const encounter = tx.get("encounters").find((e) => e.ownerUserId === userId && e.encounterId === id);
  const definition = tx.get("definitions").find((d) => d.definitionId === encounter.definitionId);
  const photo = tx.get("photos").find((p) => p.photoRef === encounter.photoRef && p.ownerUserId === encounter.ownerUserId);
  const bytes = photo ? tx.blob(photo.photoRef) : null;
  const result = { contractId: contract(op), status: "VISIBLE" };
  if (definition) result.animal = { encounterId: encounter.encounterId, ownerUserId: encounter.ownerUserId, definitionId: encounter.definitionId,
    commonName: definition.commonName ?? null, nickname: encounter.nickname ?? null, displayName: encounter.nickname ?? definition.commonName ?? null,
    location: encounter.location ?? null,
    photo: photo ? { photoRef: photo.photoRef, mediaType: photo.mediaType, byteLength: photo.byteLength ?? null,
      contentSha256: String(photo.contentSha256).toLowerCase(), contentBase64: bytes ? bytes.toString("base64") : null } : null };
  return result;
}

function viewWildlifeHome(tx, request, userId) {
  const op = "nerdery-view-wildlife-home";
  if (userId === null) return refused(op, "AUTHENTICATION_REQUIRED");
  const team = tx.get("teams").find((t) => t.ownerUserId === userId) ?? null;
  const encounters = tx.get("encounters"), definitions = new Map(tx.get("definitions").map((d) => [d.definitionId, d]));
  const members = (team ? team.encounterIds : []).map((id) => encounters.find((e) => e.ownerUserId === userId && e.encounterId === id))
    .filter((e) => e && definitions.has(e.definitionId))
    .map((e) => ({ encounterId: e.encounterId, definitionId: e.definitionId, photoRef: e.photoRef, nickname: e.nickname ?? null,
      displayName: e.nickname ?? definitions.get(e.definitionId).commonName ?? null }));
  return { contractId: contract(op), status: "VISIBLE", team: { revision: team ? team.revision : 0, size: members.length, members } };
}

// ---------- writes ----------
function uploadEncounterPhoto(tx, request, userId) {
  const op = "nerdery-upload-encounter-photo";
  const b64 = scalar(request.contentBase64), mediaType = scalar(request.mediaType);
  let code = null, bytes = null;
  if (userId === null) code = "AUTHENTICATION_REQUIRED";
  else if (b64 === null || b64.length === 0) code = "PHOTO_REQUIRED";
  else if (mediaType === null || !/^image\/[\s\S]+$/i.test(mediaType)) code = "PHOTO_MEDIA_TYPE_REQUIRED";
  else {
    const text = b64.replace(/\s+/g, "");
    if (text.length % 4 === 0 && /^[A-Za-z0-9+/]*={0,2}$/.test(text)) bytes = Buffer.from(text, "base64");
    if (!bytes || bytes.length === 0) code = "PHOTO_REQUIRED";
  }
  if (code) return refused(op, code, notApplied());
  // D10: the image bytes are retained for the owner under their sha256; retaining them is not species verification.
  const photoRef = `photo-${crypto.randomBytes(8).toString("hex")}`;
  const contentSha256 = `sha256:${sha256(bytes)}`;
  tx.put("photos", (photos) => photos.push({ photoRef, ownerUserId: userId, purpose: "encounter", mediaType, contentSha256,
    byteLength: bytes.length, durable: true }));
  tx.putBlob(photoRef, bytes);
  return { contractId: contract(op), status: "UPLOADED",
    photo: { photoRef, ownerUserId: userId, mediaType, contentSha256, byteLength: bytes.length, durable: true, verificationPerformed: false },
    mutation: { applied: true } };
}

function recordAnimalEncounter(tx, request, userId) {
  const op = "nerdery-record-animal-encounter";
  const encounterId = scalar(request.encounterId), definitionId = scalar(request.definitionId), photoRef = scalar(request.photoRef);
  const nickname = scalar(request.nickname), given = structured(request.location), location = given === null ? null : canonicalLocation(given);
  let code = null;
  if (userId === null) code = "AUTHENTICATION_REQUIRED";
  else if (definitionId === null) code = "ANIMAL_SELECTION_REQUIRED";
  else if (given === null) code = "LOCATION_REQUIRED";
  else if (photoRef === null) code = "PHOTO_REQUIRED";
  else if (encounterId === null) code = "ENCOUNTER_ID_REQUIRED";
  else if (location === null) code = "LOCATION_INVALID";
  const recorded = (encounter, replayed) => ({ contractId: contract(op), status: "RECORDED", encounter, collectionState: "COLLECTED",
    verificationPerformed: false, replayed, mutation: { applied: !replayed } });
  if (code === null) {
    // D07: the encounterId is the owner's retry key. The same key with the same content returns the recorded
    // encounter; the same key with other content is refused.
    const old = tx.get("encounters").find((e) => e.ownerUserId === userId && e.encounterId === encounterId);
    if (old) {
      if (old.definitionId === definitionId && JSON.stringify(old.location) === JSON.stringify(location) && old.photoRef === photoRef
        && (old.nickname ?? null) === (nickname ?? null))
        return recorded({ encounterId, ownerUserId: userId, definitionId: old.definitionId, location: old.location, photoRef: old.photoRef,
          nickname: old.nickname ?? null }, true);
      code = "ENCOUNTER_ID_CONFLICT";
    }
  }
  if (code === null) {
    const definition = tx.get("definitions").find((d) => d.definitionId === definitionId);
    if (!definition) code = "ANIMAL_DEFINITION_NOT_FOUND";
    else if (!definition.active) code = "ANIMAL_DEFINITION_UNAVAILABLE";
    else if (!tx.get("photos").some((p) => p.photoRef === photoRef && p.ownerUserId === userId && p.purpose === "encounter" && p.durable))
      code = "PHOTO_NOT_AVAILABLE_TO_USER";
  }
  if (code) return refused(op, code, notApplied());
  const encounter = { encounterId, ownerUserId: userId, definitionId, location, photoRef, nickname: nickname ?? null };
  tx.put("encounters", (encounters) => encounters.push({ ...encounter }));
  return recorded(encounter, false);
}

function setAnimalTeam(tx, request, userId) {
  const op = "nerdery-set-animal-team";
  const ids = structured(request.encounterIds), expected = integer(request.expectedRevision);
  const members = Array.isArray(ids) ? strings(ids) : null;
  let code = null;
  if (userId === null) code = "AUTHENTICATION_REQUIRED";
  else if (members === null) code = "TEAM_REQUEST_INVALID";
  else if (expected === null) code = "REVISION_REQUIRED";
  else if (members.length > 6) code = "TEAM_LIMIT_EXCEEDED";
  else if (hasDuplicates(members)) code = "TEAM_MEMBER_DUPLICATE";
  // D06: members are the owner's own recorded individuals; distinct individuals of one definition may both be members.
  else if (members.some((id) => !tx.get("encounters").some((e) => e.ownerUserId === userId && e.encounterId === id))) code = "TEAM_MEMBER_NOT_AVAILABLE";
  if (code) return refused(op, code, notApplied());
  // D06/D13: the submitted list replaces the team atomically when the expected revision is current.
  const current = tx.get("teams").find((t) => t.ownerUserId === userId)?.revision ?? 0;
  if (current !== expected) return { ...refused(op, "REVISION_CONFLICT"), currentRevision: current, ...notApplied() };
  tx.put("teams", (teams) => {
    const team = teams.find((t) => t.ownerUserId === userId);
    if (team) { team.revision = current + 1; team.encounterIds = [...members]; }
    else teams.push({ ownerUserId: userId, revision: current + 1, encounterIds: [...members] });
  });
  return { contractId: contract(op), status: "SAVED", team: { ownerUserId: userId, revision: current + 1, size: members.length, encounterIds: [...members] },
    mutation: { applied: true } };
}

// ---------- the catalog, maintained by biologists ----------
const isBiologist = (tx, userId) => (tx.get("users").find((u) => u.userId === userId)?.roles ?? []).includes("biologist");
const byNumber = (a, b) => a.collectionNumber - b.collectionNumber;
const definitionRecord = (d) => ({ definitionId: d.definitionId, revision: d.revision, active: d.active, commonName: d.commonName, scientificName: d.scientificName,
  avatarPhotoRef: d.avatarPhotoRef, collectionNumber: d.collectionNumber, range: d.range, types: d.types, stats: d.stats, attributes: d.attributes });
const attributeRecord = (a) => ({ attributeId: a.attributeId, revision: a.revision, active: a.active, name: a.name, description: a.description,
  selectableValues: a.selectableValues });

// The proposed properties of a definition, as adding and updating both check them; selfId is the definition an
// update keeps, whose own collection number is not a conflict.
function checkAnimal(tx, given, selfId = null) {
  const a = structured(given);
  const field = (name) => (a && !Array.isArray(a) ? a[name] : undefined);
  const common = scalar(field("commonName")), scientific = scalar(field("scientificName")), avatar = scalar(field("avatarPhotoRef"));
  const number = integer(field("collectionNumber"));
  const range = structured(field("range")), types = structured(field("types")), stats = structured(field("stats"));
  const attributes = structured(field("attributes")) ?? [];
  const rangeIds = Array.isArray(range) ? strings(range) : null, typeNames = Array.isArray(types) ? strings(types) : null;
  const attributeRows = Array.isArray(attributes) ? attributes.map((entry) => {
    const record = entry !== null && typeof entry === "object" && !Array.isArray(entry) ? entry : {};
    const valueIds = structured(record.valueIds);
    return { attributeId: scalar(record.attributeId), valueIds: Array.isArray(valueIds) ? strings(valueIds) : valueIds === null ? null : false };
  }) : null;
  let code = null;
  if (a === null || blank(common) || blank(scientific) || blank(avatar) || number === null || number < 1 || rangeIds === null || typeNames === null
    || stats === null || Array.isArray(stats) || attributeRows === null
    || attributeRows.some((r) => r.attributeId === null || r.valueIds === null || r.valueIds === false))
    code = "ANIMAL_DEFINITION_INCOMPLETE";
  else if (typeNames.length > 2) code = "ANIMAL_TYPE_LIMIT_EXCEEDED";
  else if (typeNames.some((t) => !tx.get("types").includes(t))) code = "ANIMAL_TYPE_UNKNOWN";
  else if (hasDuplicates(typeNames)) code = "ANIMAL_TYPE_DUPLICATE";
  else if (rangeIds.some((id) => !tx.get("counties").some((c) => c.countyId === id))) code = "COUNTY_UNKNOWN";
  else if (hasDuplicates(rangeIds)) code = "COUNTY_DUPLICATE";
  else if (tx.get("definitions").some((d) => d.collectionNumber === number && d.definitionId !== selfId)) code = "COLLECTION_NUMBER_NOT_UNIQUE";
  else if (attributeRows.some((r) => !tx.get("attributes").some((x) => x.attributeId === r.attributeId && x.active))) code = "ATTRIBUTE_UNKNOWN";
  else if (hasDuplicates(attributeRows.map((r) => r.attributeId))) code = "ATTRIBUTE_DUPLICATE";
  else if (attributeRows.some((r) => r.valueIds.some((v) => !tx.get("attributes").find((x) => x.attributeId === r.attributeId).selectableValues.some((s) => s.valueId === v))))
    code = "ATTRIBUTE_VALUE_NOT_SELECTABLE";
  else if (attributeRows.some((r) => hasDuplicates(r.valueIds))) code = "ATTRIBUTE_VALUE_DUPLICATE";
  else if (!tx.get("photos").some((p) => p.photoRef === avatar && p.purpose === "avatar" && p.durable)) code = "AVATAR_PHOTO_NOT_RETAINED";
  if (code) return { code };
  return { animal: { commonName: common, scientificName: scientific, avatarPhotoRef: avatar, collectionNumber: number, range: [...rangeIds], types: [...typeNames],
    stats: structuredClone(stats), attributes: attributeRows.map((r) => ({ attributeId: r.attributeId, valueIds: [...r.valueIds] })) } };
}

function addAnimalDefinition(tx, request, userId) {
  const op = "nerdery-add-animal-definition";
  if (userId === null) return refused(op, "AUTHENTICATION_REQUIRED", notApplied());
  if (!isBiologist(tx, userId)) return refused(op, "BIOLOGIST_ROLE_REQUIRED", notApplied());
  const { code, animal } = checkAnimal(tx, request.animal);
  if (code) return refused(op, code, notApplied());
  let definitionId = `animal-${animal.collectionNumber < 1000 ? String(animal.collectionNumber).padStart(3, "0") : animal.collectionNumber}`;
  if (tx.get("definitions").some((d) => d.definitionId === definitionId)) definitionId = `animal-${crypto.randomBytes(6).toString("hex")}`;
  tx.put("definitions", (definitions) => definitions.push({ definitionId, revision: 1, active: true, ...structuredClone(animal) }));
  return { contractId: contract(op), status: "ADDED", definitionId, revision: 1, animal, mutation: { applied: true } };
}

// D13: a catalog change names the revision its author saw; a stale change is refused and changes nothing.
function targetAt(tx, collection, idField, id, expected, notFound) {
  if (id === null || id.trim() === "") return { code: idField === "definitionId" ? "ANIMAL_SELECTION_REQUIRED" : "ATTRIBUTE_SELECTION_REQUIRED" };
  if (expected === null) return { code: "REVISION_REQUIRED" };
  const target = tx.get(collection).find((x) => x[idField] === id);
  if (!target) return { code: notFound };
  if (target.revision !== expected) return { code: "REVISION_CONFLICT", currentRevision: target.revision };
  return { target };
}
const conflictRefusal = (op, found) => ({ ...refused(op, found.code), ...(found.currentRevision !== undefined ? { currentRevision: found.currentRevision } : {}), ...notApplied() });

function updateAnimalDefinition(tx, request, userId) {
  const op = "nerdery-update-animal-definition";
  if (userId === null) return refused(op, "AUTHENTICATION_REQUIRED", notApplied());
  if (!isBiologist(tx, userId)) return refused(op, "BIOLOGIST_ROLE_REQUIRED", notApplied());
  const found = targetAt(tx, "definitions", "definitionId", scalar(request.definitionId), integer(request.expectedRevision), "ANIMAL_DEFINITION_NOT_FOUND");
  if (found.code) return conflictRefusal(op, found);
  const { code, animal } = checkAnimal(tx, request.animal, found.target.definitionId);
  if (code) return refused(op, code, notApplied());
  // The definition keeps its identity: encounters, teams and unlocks that name it keep naming it.
  const revision = found.target.revision + 1;
  tx.put("definitions", (definitions) => Object.assign(definitions.find((d) => d.definitionId === found.target.definitionId), structuredClone(animal), { revision }));
  return { contractId: contract(op), status: "UPDATED",
    animal: { definitionId: found.target.definitionId, revision, active: found.target.active, ...animal }, mutation: { applied: true } };
}

function removeAnimalDefinition(tx, request, userId) {
  const op = "nerdery-remove-animal-definition";
  if (userId === null) return refused(op, "AUTHENTICATION_REQUIRED", notApplied());
  if (!isBiologist(tx, userId)) return refused(op, "BIOLOGIST_ROLE_REQUIRED", notApplied());
  const found = targetAt(tx, "definitions", "definitionId", scalar(request.definitionId), integer(request.expectedRevision), "ANIMAL_DEFINITION_NOT_FOUND");
  if (found.code) return conflictRefusal(op, found);
  if (!found.target.active) return refused(op, "ANIMAL_DEFINITION_UNAVAILABLE", notApplied());
  // Removal takes the definition out of the active catalog; recorded individuals and team memberships stay as they are.
  const id = found.target.definitionId, revision = found.target.revision + 1;
  const encounters = tx.get("encounters");
  const encountersRetained = encounters.filter((e) => e.definitionId === id).length;
  const teamReferencesRetained = tx.get("teams").reduce((n, t) => n + t.encounterIds.filter((eid) =>
    encounters.some((e) => e.ownerUserId === t.ownerUserId && e.encounterId === eid && e.definitionId === id)).length, 0);
  tx.put("definitions", (definitions) => Object.assign(definitions.find((d) => d.definitionId === id), { active: false, revision }));
  return { contractId: contract(op), status: "REMOVED", definitionId: id, active: false, revision, history: { encountersRetained, teamReferencesRetained },
    mutation: { applied: true } };
}

// A reusable attribute's name, description and selectable values: all required, the values each with an id and a label.
function checkAttribute(given) {
  const a = structured(given);
  const field = (name) => (a && !Array.isArray(a) ? a[name] : undefined);
  const name = scalar(field("name")), description = scalar(field("description")), values = structured(field("selectableValues"));
  const rows = Array.isArray(values) ? values.map((v) => (v !== null && typeof v === "object" && !Array.isArray(v) ? { valueId: scalar(v.valueId), label: scalar(v.label) } : null)) : null;
  if (blank(name) || blank(description) || rows === null || rows.length === 0 || rows.some((r) => r === null || blank(r.valueId) || blank(r.label)))
    return { code: "ANIMAL_ATTRIBUTE_INCOMPLETE" };
  if (hasDuplicates(rows.map((r) => r.valueId))) return { code: "ATTRIBUTE_VALUE_DUPLICATE" };
  return { attribute: { name, description, selectableValues: rows } };
}

function addAnimalAttribute(tx, request, userId) {
  const op = "nerdery-add-animal-attribute";
  if (userId === null) return refused(op, "AUTHENTICATION_REQUIRED", notApplied());
  if (!isBiologist(tx, userId)) return refused(op, "BIOLOGIST_ROLE_REQUIRED", notApplied());
  const { code, attribute } = checkAttribute(request.attribute);
  if (code) return refused(op, code, notApplied());
  const attributes = tx.get("attributes");
  if (attributes.some((x) => x.active && x.name.trim().toLowerCase() === attribute.name.trim().toLowerCase())) return refused(op, "ATTRIBUTE_NAME_NOT_UNIQUE", notApplied());
  const slug = attribute.name.trim().toLowerCase().replace(/[^a-z0-9]+/g, "-").replace(/^-+|-+$/g, "") || "attribute";
  let attributeId = slug;
  for (let n = 2; attributes.some((x) => x.attributeId === attributeId); n += 1) attributeId = `${slug}-${n}`;
  const record = { attributeId, revision: 1, active: true, ...attribute };
  tx.put("attributes", (list) => list.push(structuredClone(record)));
  // An attribute describes animals; adding one changes no animal's stats.
  return { contractId: contract(op), status: "ADDED", attribute: record, mutation: { applied: true, animalStatChanges: 0 } };
}

function updateAnimalAttribute(tx, request, userId) {
  const op = "nerdery-update-animal-attribute";
  if (userId === null) return refused(op, "AUTHENTICATION_REQUIRED", notApplied());
  if (!isBiologist(tx, userId)) return refused(op, "BIOLOGIST_ROLE_REQUIRED", notApplied());
  const found = targetAt(tx, "attributes", "attributeId", scalar(request.attributeId), integer(request.expectedRevision), "ANIMAL_ATTRIBUTE_NOT_FOUND");
  if (found.code) return conflictRefusal(op, found);
  const { code, attribute } = checkAttribute(request.attribute);
  if (code) return refused(op, code, notApplied());
  // A value a definition still selects cannot be dropped here; migrating those definitions is a separate decision.
  const kept = new Set(attribute.selectableValues.map((v) => v.valueId)), id = found.target.attributeId;
  const inUse = tx.get("definitions").some((d) => (d.attributes || []).some((r) => r.attributeId === id && (r.valueIds || []).some((v) => !kept.has(v))));
  if (inUse) return refused(op, "ATTRIBUTE_VALUE_IN_USE", notApplied());
  const record = { attributeId: id, revision: found.target.revision + 1, active: found.target.active, ...attribute };
  tx.put("attributes", (list) => Object.assign(list.find((x) => x.attributeId === id), structuredClone(record)));
  return { contractId: contract(op), status: "UPDATED", attribute: record, mutation: { applied: true } };
}

function removeAnimalAttribute(tx, request, userId) {
  const op = "nerdery-remove-animal-attribute";
  if (userId === null) return refused(op, "AUTHENTICATION_REQUIRED", notApplied());
  if (!isBiologist(tx, userId)) return refused(op, "BIOLOGIST_ROLE_REQUIRED", notApplied());
  const found = targetAt(tx, "attributes", "attributeId", scalar(request.attributeId), integer(request.expectedRevision), "ANIMAL_ATTRIBUTE_NOT_FOUND");
  if (found.code) return conflictRefusal(op, found);
  if (!found.target.active) return refused(op, "ANIMAL_ATTRIBUTE_UNAVAILABLE", notApplied());
  // Removal ends new selections of the attribute; definitions that reference it keep resolving it.
  const id = found.target.attributeId, revision = found.target.revision + 1;
  const definitionReferencesRetained = tx.get("definitions").filter((d) => (d.attributes || []).some((r) => r.attributeId === id)).length;
  tx.put("attributes", (list) => Object.assign(list.find((x) => x.attributeId === id), { active: false, revision }));
  return { contractId: contract(op), status: "REMOVED", attributeId: id, active: false, revision, history: { definitionReferencesRetained }, mutation: { applied: true } };
}

// Everything a biologist maintains, with the revisions a change must name; citizens are refused.
function viewCatalogForMaintenance(tx, request, userId) {
  const op = "nerdery-view-catalog-for-maintenance";
  if (userId === null) return refused(op, "AUTHENTICATION_REQUIRED");
  if (!isBiologist(tx, userId)) return refused(op, "BIOLOGIST_ROLE_REQUIRED");
  return { contractId: contract(op), status: "VISIBLE",
    definitions: [...tx.get("definitions")].sort(byNumber).map(definitionRecord),
    attributes: [...tx.get("attributes")].sort((a, b) => byCodePoint(a.attributeId, b.attributeId)).map(attributeRecord),
    types: [...tx.get("types")], counties: tx.get("counties").map((c) => ({ countyId: c.countyId, name: c.name })),
    avatarPhotoRefs: tx.get("photos").filter((p) => p.purpose === "avatar" && p.durable).map((p) => p.photoRef).sort(byCodePoint) };
}

// ---------- identity: the local stand-in for the DNR identity service ----------
// D02: the identity response is resolved and validated on the server; the application keeps no passwords.
function signInWildlifeUser(tx, request) {
  const op = "nerdery-sign-in-wildlife-user";
  const notEstablished = () => ({ session: { established: false } });
  const ref = scalar(request.identityResponseRef);
  if (ref === null || ref.trim() === "") return refused(op, "IDENTITY_RESPONSE_REQUIRED", notEstablished());
  if (tx.identityService() === "UNAVAILABLE") return refused(op, "IDENTITY_SERVICE_UNAVAILABLE", notEstablished());
  const response = tx.get("identityResponses")[ref];
  if (response && response.validation === "EXPIRED") return refused(op, "IDENTITY_RESPONSE_EXPIRED", notEstablished());
  if (!response || response.validation !== "VALID") return refused(op, "IDENTITY_NOT_VALIDATED", notEstablished());
  const user = tx.get("users").find((u) => u.identitySubject === response.subject);
  if (!user) return refused(op, "REGISTRATION_REQUIRED", notEstablished());
  return { contractId: contract(op), status: "SIGNED_IN",
    user: { userId: user.userId, firstName: user.firstName, lastName: user.lastName, email: user.email, roles: [...user.roles] },
    session: { established: true } };
}

export const OPERATIONS = {
  "nerdery-browse-animal-collection": browseAnimalCollection,
  "nerdery-view-animal-definition": viewAnimalDefinition,
  "nerdery-view-collected-animals": viewCollectedAnimals,
  "nerdery-view-collected-animal": viewCollectedAnimal,
  "nerdery-view-wildlife-home": viewWildlifeHome,
  "nerdery-upload-encounter-photo": uploadEncounterPhoto,
  "nerdery-record-animal-encounter": recordAnimalEncounter,
  "nerdery-set-animal-team": setAnimalTeam,
  "nerdery-add-animal-definition": addAnimalDefinition,
  "nerdery-update-animal-definition": updateAnimalDefinition,
  "nerdery-remove-animal-definition": removeAnimalDefinition,
  "nerdery-add-animal-attribute": addAnimalAttribute,
  "nerdery-update-animal-attribute": updateAnimalAttribute,
  "nerdery-remove-animal-attribute": removeAnimalAttribute,
  "nerdery-view-catalog-for-maintenance": viewCatalogForMaintenance,
  "nerdery-sign-in-wildlife-user": signInWildlifeUser
};
const WRITES = new Set(["nerdery-upload-encounter-photo", "nerdery-record-animal-encounter", "nerdery-set-animal-team", "nerdery-add-animal-definition",
  "nerdery-update-animal-definition", "nerdery-remove-animal-definition", "nerdery-add-animal-attribute", "nerdery-update-animal-attribute", "nerdery-remove-animal-attribute"]);
const STORAGE_REFUSAL = {
  "nerdery-upload-encounter-photo": "PHOTO_STORAGE_UNAVAILABLE",
  "nerdery-record-animal-encounter": "COLLECTION_STORAGE_UNAVAILABLE",
  "nerdery-view-collected-animals": "COLLECTION_STORAGE_UNAVAILABLE",
  "nerdery-view-collected-animal": "COLLECTION_STORAGE_UNAVAILABLE",
  "nerdery-set-animal-team": "TEAM_STORAGE_UNAVAILABLE",
  "nerdery-view-wildlife-home": "TEAM_STORAGE_UNAVAILABLE"
};

// Runs one operation for the trusted user. A store that cannot be read or written answers the operation's own
// storage refusal, and nothing is kept.
export function invoke(store, operation, request, userId) {
  const run = OPERATIONS[operation];
  if (!run) return { status: "REFUSED", reason: { code: "OPERATION_NOT_DECLARED" } };
  const body = request !== null && typeof request === "object" && !Array.isArray(request) ? request : {};
  try {
    return store.transaction((tx) => run(tx, body, userId ?? null));
  } catch (error) {
    if (!(error instanceof StorageError)) throw error;
    return { ...refused(operation, STORAGE_REFUSAL[operation] ?? "CATALOG_STORAGE_UNAVAILABLE"), ...(WRITES.has(operation) ? notApplied() : {}) };
  }
}
