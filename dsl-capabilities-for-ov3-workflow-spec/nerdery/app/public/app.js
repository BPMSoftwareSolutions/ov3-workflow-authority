// The Wildlife Collection web application. Every screen runs a canonical feature's operation through the local
// server and renders that operation's own answer, refusals included; no business rule lives in the page.
const view = document.getElementById("view");
const nav = document.getElementById("nav");
const who = document.getElementById("who");
let session = { authenticated: false };
let reference = { counties: [], types: [] };

// ---------- building blocks ----------
function h(tag, attrs, ...children) {
  const node = document.createElement(tag);
  for (const [key, value] of Object.entries(attrs || {})) {
    if (value === null || value === undefined || value === false) continue;
    if (key === "class") node.className = value;
    else if (key === "text") node.textContent = value;
    else if (key.startsWith("on")) node.addEventListener(key.slice(2), value);
    else node.setAttribute(key, value === true ? "" : value);
  }
  for (const child of children.flat(Infinity)) if (child !== null && child !== undefined && child !== false) node.append(child instanceof Node ? child : String(child));
  return node;
}
async function call(method, url, body) {
  const response = await fetch(url, { method, credentials: "same-origin", headers: body ? { "content-type": "application/json" } : {},
    body: body ? JSON.stringify(body) : undefined });
  return response.json();
}
const run = (capability, request = {}) => call("POST", `/api/run/${capability}`, request);

const REASONS = {
  AUTHENTICATION_REQUIRED: "Sign in to continue.",
  ANIMAL_SELECTION_REQUIRED: "Choose the animal you saw.",
  ANIMAL_DEFINITION_NOT_FOUND: "That animal is not in the catalog.",
  ANIMAL_DEFINITION_UNAVAILABLE: "That animal is no longer in the catalog.",
  PHOTO_REQUIRED: "Choose a photo of the animal first.",
  PHOTO_MEDIA_TYPE_REQUIRED: "The photo must be an image file.",
  PHOTO_NOT_AVAILABLE_TO_USER: "That photo is not yours to use.",
  LOCATION_REQUIRED: "Say where you saw it, or use your device's position.",
  LOCATION_INVALID: "Say where you saw it, or use your device's position.",
  ENCOUNTER_ID_CONFLICT: "That encounter was already recorded with other details.",
  ENCOUNTER_NOT_FOUND: "This animal is not in your collection.",
  ENCOUNTER_SELECTION_REQUIRED: "Open an animal from My animals.",
  TEAM_LIMIT_EXCEEDED: "A team holds at most six animals. Your saved team did not change.",
  TEAM_MEMBER_DUPLICATE: "An animal can be on your team only once.",
  TEAM_MEMBER_NOT_AVAILABLE: "Only animals you recorded can join your team.",
  TEAM_REQUEST_INVALID: "The team could not be read.",
  REVISION_CONFLICT: "Your team changed since you opened it. Reload and try again.",
  REVISION_REQUIRED: "Reload your team and try again.",
  BIOLOGIST_ROLE_REQUIRED: "Only biologists can change the catalog.",
  IDENTITY_NOT_VALIDATED: "The DNR identity service did not validate this sign-in.",
  IDENTITY_RESPONSE_EXPIRED: "This sign-in response has expired. Sign in again.",
  IDENTITY_SERVICE_UNAVAILABLE: "The DNR identity service is unavailable right now.",
  REGISTRATION_REQUIRED: "This DNR account has no wildlife profile yet.",
  CATALOG_STORAGE_UNAVAILABLE: "The catalog is unavailable right now. Nothing was changed.",
  COLLECTION_STORAGE_UNAVAILABLE: "Your collection is unavailable right now. Nothing was changed.",
  PHOTO_STORAGE_UNAVAILABLE: "Photo storage is unavailable right now. Nothing was kept.",
  TEAM_STORAGE_UNAVAILABLE: "Team storage is unavailable right now. Nothing was changed.",
  ANIMAL_DEFINITION_INCOMPLETE: "Every animal needs a common and scientific name, a collection number, an avatar, a range, types and stats.",
  ANIMAL_TYPE_LIMIT_EXCEEDED: "An animal has at most two types.",
  ANIMAL_TYPE_UNKNOWN: "One of the types is not in the catalog.",
  ANIMAL_TYPE_DUPLICATE: "A type is listed twice.",
  COUNTY_UNKNOWN: "One of the counties is not known.",
  COUNTY_DUPLICATE: "A county is listed twice.",
  COLLECTION_NUMBER_NOT_UNIQUE: "Another animal already has this collection number.",
  ATTRIBUTE_UNKNOWN: "One of the attributes is not active.",
  ATTRIBUTE_DUPLICATE: "An attribute is listed twice.",
  ATTRIBUTE_VALUE_NOT_SELECTABLE: "One of the chosen values is not offered by its attribute.",
  ATTRIBUTE_VALUE_DUPLICATE: "A value is listed twice.",
  AVATAR_PHOTO_NOT_RETAINED: "The avatar picture is not on file.",
  ANIMAL_ATTRIBUTE_INCOMPLETE: "An attribute needs a name, a description and at least one value, each with a label.",
  ANIMAL_ATTRIBUTE_NOT_FOUND: "That attribute is not in the catalog.",
  ANIMAL_ATTRIBUTE_UNAVAILABLE: "That attribute was already removed.",
  ATTRIBUTE_VALUE_IN_USE: "An animal still uses a value this change drops. Change those animals first.",
  ATTRIBUTE_NAME_NOT_UNIQUE: "An active attribute already has this name.",
  ATTRIBUTE_SELECTION_REQUIRED: "Choose an attribute first.",
  IDENTITY_RESPONSE_REQUIRED: "Sign in through DNR first.",
  ALREADY_REGISTERED: "This DNR account already has a wildlife profile. Sign in instead.",
  USER_PROFILE_INCOMPLETE: "DNR's profile for this account lacks a first name, last name or email.",
  EMAIL_NOT_UNIQUE: "Another wildlife account already uses this email.",
  WILDLIFE_ROLE_REQUIRED: "This account has no wildlife role assigned by DNR.",
  SECTION_UNKNOWN: "That part of the application does not exist."
};
function refusal(result, title = "Refused") {
  const code = result?.reason?.code ?? "NO_ANSWER";
  return h("div", { class: "notice error" }, h("strong", { text: `${title}: ${REASONS[code] ?? "The request was refused."}` }), h("code", { text: code }));
}
// The operation's own answer, for whoever wants to see what the screen was built from.
function evidence(capability, result) {
  const text = JSON.stringify(result, (key, value) => (key === "contentBase64" && typeof value === "string"
    ? `<${Math.floor(value.length * 3 / 4).toLocaleString()} bytes, base64>` : value), 2);
  const label = `${capability} · ${result?.status ?? "no answer"}${result?.reason ? ` · ${result.reason.code}` : ""}`;
  return h("details", { class: "evidence" }, h("summary", { text: label }), h("pre", { text }));
}
const countyName = (id) => reference.counties.find((c) => c.countyId === id)?.name ?? id;
const photoUrl = (photo) => (photo?.contentBase64 ? `data:${photo.mediaType};base64,${photo.contentBase64}` : null);
function tile(animal, locked) {
  const hue = ((animal.collectionNumber ?? 1) * 67) % 360;
  return h("div", { class: `tile${locked ? " locked" : ""}`, style: `--hue:${hue}` },
    h("span", { class: "number", text: `No. ${String(animal.collectionNumber ?? "?").padStart(3, "0")}` }), (animal.commonName || "?").trim().split(/\s+/).pop().slice(0, 1));
}
const stateChip = (collected) => h("span", { class: `chip${collected ? "" : " uncollected"}`, text: collected ? "Collected" : "Not yet" });
function statBars(stats) {
  return h("div", { class: "stats" }, Object.entries(stats || {}).map(([name, value]) =>
    h("div", { class: "stat" }, h("span", { text: name }), h("div", { class: "bar" }, h("span", { style: `width:${Math.min(100, Number(value) * 10)}%` })), h("span", { text: value }))));
}
function photoBox(result) {
  const box = h("div", { class: "photo", text: "Photo loading…" });
  Promise.resolve(result).then((answer) => {
    const url = photoUrl(answer?.animal?.photo);
    box.replaceChildren(url ? h("img", { src: url, alt: answer.animal.displayName ?? "" }) : h("span", { text: "No photo" }));
  });
  return box;
}
const viewIndividual = (encounterId) => run("nerdery-view-collected-animal", { encounterId });
const page = (title, lede, ...content) => h("section", {}, h("h1", { text: title }), lede ? h("p", { class: "lede", text: lede }) : null, ...content);

// ---------- screens ----------
async function signInView() {
  const identities = await call("GET", "/api/identities");
  const message = h("div");
  const cards = identities.map((i) => {
    const valid = i.validation === "VALID";
    const label = i.name ?? (i.validation === "EXPIRED" ? "An expired sign-in" : "A sign-in DNR rejects");
    const detail = !valid ? `DNR answers ${i.validation}` : i.registered ? `DNR roles: ${i.roles.join(", ") || "none"}` : "Validated by DNR, no wildlife profile yet";
    const initials = i.name ? i.name.split(" ").map((p) => p[0]).join("") : "?";
    // A validated DNR subject without a wildlife profile is told so by sign-in, and offered registration.
    const register = async () => {
      const answer = await call("POST", "/api/register", { identityResponseRef: i.identityResponseRef });
      if (answer.signIn?.status === "SIGNED_IN") { location.hash = "#/"; return; }
      message.replaceChildren(refusal(answer.signIn ?? answer.registration, "Not registered"), evidence("nerdery-register-wildlife-user", answer.registration),
        answer.signIn ? evidence("nerdery-sign-in-wildlife-user", answer.signIn) : null);
    };
    return h("button", { class: `card identity${valid && i.registered ? "" : " refusal"}`, onclick: async () => {
      const result = await call("POST", "/api/sign-in", { identityResponseRef: i.identityResponseRef });
      if (result.status === "SIGNED_IN") { location.hash = "#/"; return; }
      message.replaceChildren(refusal(result, "Not signed in"),
        result.reason?.code === "REGISTRATION_REQUIRED" ? h("p", {}, h("button", { class: "button", text: `Register ${i.name ?? ""} with DNR`, onclick: register })) : null,
        evidence("nerdery-sign-in-wildlife-user", result));
    } }, h("div", { class: "body row" }, h("div", { class: "avatar", text: initials }), h("div", {}, h("div", { class: "title", text: label }), h("div", { class: "sub", text: detail }))));
  });
  return page("Sign in with DNR", "This local demo stands in for the DNR identity service with the challenge's identity responses. The application keeps no passwords: it starts a session only for a response DNR validated, for a registered wildlife user.",
    h("div", { class: "grid" }, cards), message);
}

async function homeView() {
  const [home, mine] = await Promise.all([run("nerdery-view-wildlife-home"), run("nerdery-view-collected-animals")]);
  if (home.status !== "VISIBLE") return page("Home", null, refusal(home), evidence("nerdery-view-wildlife-home", home));
  const members = home.team.members;
  return page(`Hello, ${session.user.firstName}`, "Your team and your collection, as you left them.",
    h("div", { class: "row" },
      h("div", { class: "panel" }, h("div", { class: "sub", text: "Individuals collected" }), h("h1", { text: mine.total ?? 0 })),
      h("div", { class: "panel" }, h("div", { class: "sub", text: "On your team" }), h("h1", { text: `${home.team.size} / 6` })),
      h("span", { class: "spacer" }),
      h("a", { class: "button", href: "#/capture", text: "Capture an encounter" }), h("a", { class: "button secondary", href: "#/collection", text: "Browse the collection" })),
    h("h2", { text: "My team" }),
    members.length ? h("div", { class: "grid" }, members.map((m) => h("a", { class: "card", href: `#/mine/${encodeURIComponent(m.encounterId)}` },
      photoBox(viewIndividual(m.encounterId)), h("div", { class: "body" }, h("div", { class: "title", text: m.displayName }), h("div", { class: "sub", text: m.encounterId })))))
      : h("div", { class: "empty" }, "No team yet. ", h("a", { href: "#/team", text: "Pick up to six of your animals." })),
    evidence("nerdery-view-wildlife-home", home), evidence("nerdery-view-collected-animals", mine));
}

function animalCard(item) {
  const a = item.animal, collected = item.collectionState === "COLLECTED";
  return h("a", { class: "card", href: `#/animal/${encodeURIComponent(item.definitionId)}` }, tile(a, !collected),
    h("div", { class: "body" },
      h("div", { class: "row" }, h("div", { class: "title", text: a.commonName }), h("span", { class: "spacer" }), stateChip(collected)),
      h("div", { class: "sub", text: (a.range || []).map(countyName).join(", ") }),
      collected ? [h("div", { class: "sub", text: a.scientificName }), h("div", { class: "chips" }, (a.types || []).map((t) => h("span", { class: "chip amber", text: t }))), statBars(a.stats)]
        : h("div", { class: "sub", text: "Collect it to unlock the rest." })));
}
async function collectionView(params) {
  const input = h("input", { type: "search", placeholder: "Search by name or collection number", value: params.get("q") ?? "", style: "width:100%;max-width:420px" });
  const results = h("div");
  let latest = 0;
  const load = async () => {
    const ticket = ++latest;
    const result = await run("nerdery-browse-animal-collection", { search: input.value });
    if (ticket !== latest) return;
    results.replaceChildren(...(result.status === "LISTED"
      ? [h("p", { class: "sub", text: `${result.total} animal${result.total === 1 ? "" : "s"}` }),
        result.items.length ? h("div", { class: "grid" }, result.items.map(animalCard)) : h("div", { class: "empty", text: "No animal matches this search." })]
      : [refusal(result)]), evidence("nerdery-browse-animal-collection", result));
  };
  let timer = null;
  input.addEventListener("input", () => { clearTimeout(timer); timer = setTimeout(load, 200); });
  await load();
  return page("Animal collection", "An animal you have not collected shows only its common name, number, range and picture; the server keeps the rest until you collect it, for you alone.",
    h("div", { class: "row" }, input), results);
}

async function animalView(definitionId) {
  const [result, mine] = await Promise.all([run("nerdery-view-animal-definition", { definitionId }), run("nerdery-view-collected-animals")]);
  if (result.status !== "VISIBLE") return page("Animal", null, refusal(result), evidence("nerdery-view-animal-definition", result));
  const a = result.animal, collected = result.collectionState === "COLLECTED";
  const individuals = (mine.items || []).filter((i) => i.definitionId === result.definitionId);
  return h("section", {},
    h("p", {}, h("a", { href: "#/collection", text: "← Collection" })),
    h("div", { class: "split" },
      h("div", { class: "card" }, tile(a, !collected)),
      h("div", {},
        h("div", { class: "row" }, h("h1", { text: a.commonName }), stateChip(collected)),
        h("dl", { class: "facts" }, h("dt", { text: "Collection number" }), h("dd", { text: a.collectionNumber }),
          h("dt", { text: "Range" }), h("dd", { text: (a.range || []).map(countyName).join(", ") }),
          collected ? [h("dt", { text: "Scientific name" }), h("dd", { text: a.scientificName }),
            h("dt", { text: "Types" }), h("dd", {}, h("div", { class: "chips" }, (a.types || []).map((t) => h("span", { class: "chip amber", text: t }))))] : null),
        collected ? [h("h2", { text: "Stats" }), statBars(a.stats),
          h("h2", { text: "Attributes" }),
          h("table", { class: "list" }, h("thead", {}, h("tr", {}, h("th", { text: "Attribute" }), h("th", { text: "Value" }), h("th", { text: "About" }))),
            h("tbody", {}, (a.attributeDetails || []).map((d) => h("tr", {}, h("td", { text: d.name }), h("td", { text: (d.selectedValues || []).map((v) => v.label).join(", ") }), h("td", { text: d.description ?? "" })))))]
          : h("div", { class: "notice locked" }, h("strong", { text: "Locked until you collect it" }),
            "Record an encounter with this animal to unlock its scientific name, types, stats and attributes. ",
            h("a", { class: "button small", href: `#/capture?animal=${encodeURIComponent(result.definitionId)}`, text: "Capture it" })))),
    individuals.length ? [h("h2", { text: `Your ${a.commonName}${individuals.length === 1 ? "" : "s"}` }),
      h("div", { class: "grid" }, individuals.map((i) => h("a", { class: "card", href: `#/mine/${encodeURIComponent(i.encounterId)}` },
        photoBox(viewIndividual(i.encounterId)), h("div", { class: "body" }, h("div", { class: "title", text: i.displayName }), h("div", { class: "sub", text: i.encounterId })))))] : null,
    evidence("nerdery-view-animal-definition", result));
}

const fileBase64 = (file) => new Promise((resolve, reject) => {
  const reader = new FileReader();
  reader.onload = () => resolve(String(reader.result).replace(/^data:[^,]*,/, ""));
  reader.onerror = () => reject(reader.error);
  reader.readAsDataURL(file);
});
async function captureView(params) {
  const browse = await run("nerdery-browse-animal-collection", { search: "" });
  const animals = browse.items || [];
  // One encounter id per capture, kept across a retry so a resubmission replays instead of recording twice (D07).
  const state = { encounterId: null, upload: null, file: null, position: null };
  const preview = h("div", { class: "sub", text: "No photo chosen yet" });
  const fileInput = h("input", { type: "file", accept: "image/*", onchange: () => {
    state.file = fileInput.files[0] ?? null; state.upload = null; state.encounterId = null;
    preview.replaceChildren(state.file ? h("img", { src: URL.createObjectURL(state.file), alt: "Chosen photo" }) : "No photo chosen yet");
  } });
  const animal = h("select", { name: "definitionId" }, animals.map((i) => h("option", { value: i.definitionId, selected: i.definitionId === params.get("animal"),
    text: `No. ${String(i.animal.collectionNumber).padStart(3, "0")} ${i.animal.commonName}${i.collectionState === "COLLECTED" ? " (collected)" : ""}` })));
  const where = h("input", { type: "text", placeholder: "e.g. north path of the park", oninput: () => { state.position = null; positionNote.textContent = ""; } });
  const positionNote = h("span", { class: "hint" });
  const usePosition = h("button", { type: "button", class: "button secondary small", text: "Use my position", onclick: () => {
    if (!navigator.geolocation) { positionNote.textContent = "This browser has no position service."; return; }
    positionNote.textContent = "Finding your position…";
    navigator.geolocation.getCurrentPosition((p) => {
      state.position = { latitude: Number(p.coords.latitude.toFixed(6)), longitude: Number(p.coords.longitude.toFixed(6)) };
      where.value = ""; positionNote.textContent = `Device position ${state.position.latitude}, ${state.position.longitude}`;
    }, (error) => { positionNote.textContent = `No position: ${error.message}`; });
  } });
  const nickname = h("input", { type: "text", placeholder: "Optional, e.g. Reed" });
  const submit = h("button", { class: "button", type: "submit", text: "Record encounter" });
  const outcome = h("div");
  const form = h("form", { class: "stack panel", onsubmit: async (event) => {
    event.preventDefault();
    submit.disabled = true; submit.textContent = "Recording…";
    const shown = [];
    try {
      if (!state.upload) {
        const file = state.file;
        const upload = await run("nerdery-upload-encounter-photo", { fileName: file?.name ?? "", mediaType: file?.type ?? "", contentBase64: file ? await fileBase64(file) : "" });
        shown.push(evidence("nerdery-upload-encounter-photo", upload));
        if (upload.status !== "UPLOADED") { outcome.replaceChildren(refusal(upload, "Photo not kept"), ...shown); return; }
        state.upload = upload;
      }
      state.encounterId ??= `enc-${Date.now().toString(36)}-${Math.random().toString(36).slice(2, 6)}`;
      const location = state.position ? { source: "device", ...state.position } : { source: "manual", description: where.value };
      const record = await run("nerdery-record-animal-encounter", { encounterId: state.encounterId, definitionId: animal.value, location,
        photoRef: state.upload.photo.photoRef, ...(nickname.value.trim() ? { nickname: nickname.value.trim() } : {}) });
      shown.push(evidence("nerdery-record-animal-encounter", record));
      if (record.status !== "RECORDED") { outcome.replaceChildren(refusal(record, "Not recorded"), ...shown); return; }
      const id = record.encounter.encounterId;
      const name = animals.find((i) => i.definitionId === record.encounter.definitionId)?.animal.commonName ?? record.encounter.definitionId;
      outcome.replaceChildren(h("div", { class: "notice ok" }, h("strong", { text: `${record.encounter.nickname ?? name} is in your collection` }),
        record.replayed ? "This encounter was already recorded; nothing was written twice. " : `${name} is unlocked for you. Photo verification is deferred. `,
        h("a", { class: "button small", href: `#/mine/${encodeURIComponent(id)}`, text: "See it with your photo" })), ...shown);
      state.encounterId = null; state.upload = null; state.file = null; fileInput.value = ""; nickname.value = "";
      preview.replaceChildren("No photo chosen yet");
    } finally { submit.disabled = false; submit.textContent = "Record encounter"; }
  } },
    h("label", { class: "field" }, "Photo", h("div", { class: "drop" }, preview, fileInput)),
    h("label", { class: "field" }, "Animal", animal),
    h("label", { class: "field" }, "Where you saw it", where, h("div", { class: "row" }, usePosition, positionNote)),
    h("label", { class: "field" }, "Nickname", nickname),
    h("div", { class: "row" }, submit));
  return page("Capture an encounter", "Photograph it and say where you saw it. The photo is kept with its exact bytes under their digest; recording the encounter collects the animal for you.",
    h("div", { class: "split" }, form, outcome));
}

async function mineView() {
  const mine = await run("nerdery-view-collected-animals");
  if (mine.status !== "LISTED") return page("My animals", null, refusal(mine), evidence("nerdery-view-collected-animals", mine));
  const cards = mine.items.map((item) => {
    const answer = viewIndividual(item.encounterId);
    const species = h("div", { class: "sub", text: item.definitionId });
    answer.then((r) => { if (r.animal) species.textContent = item.nickname ? r.animal.commonName : "No nickname"; });
    return h("a", { class: "card", href: `#/mine/${encodeURIComponent(item.encounterId)}` }, photoBox(answer),
      h("div", { class: "body" }, h("div", { class: "title", text: item.displayName }), species));
  });
  return page("My animals", "Every encounter you recorded is its own individual, shown with your photo and nickname. Two herons are two animals.",
    cards.length ? h("div", { class: "grid" }, cards) : h("div", { class: "empty" }, "No animals yet. ", h("a", { href: "#/capture", text: "Capture your first encounter." })),
    evidence("nerdery-view-collected-animals", mine));
}

async function digestMatches(photo) {
  if (!photo?.contentBase64 || !crypto.subtle) return null;
  const bytes = Uint8Array.from(atob(photo.contentBase64), (c) => c.charCodeAt(0));
  const hash = [...new Uint8Array(await crypto.subtle.digest("SHA-256", bytes))].map((b) => b.toString(16).padStart(2, "0")).join("");
  return `sha256:${hash}` === photo.contentSha256;
}
async function individualView(encounterId) {
  const result = await viewIndividual(encounterId);
  const back = h("p", {}, h("a", { href: "#/mine", text: "← My animals" }));
  if (result.status !== "VISIBLE") return h("section", {}, back, refusal(result), evidence("nerdery-view-collected-animal", result));
  const a = result.animal, photo = a.photo, location = a.location || {};
  const checked = await digestMatches(photo);
  return h("section", {}, back,
    h("div", { class: "split" },
      h("div", { class: "hero-photo" }, photoUrl(photo) ? h("img", { src: photoUrl(photo), alt: a.displayName }) : h("div", { class: "photo", text: "No photo stored" })),
      h("div", {},
        h("h1", { text: a.displayName }),
        h("p", {}, h("a", { class: "chip", href: `#/animal/${encodeURIComponent(a.definitionId)}`, text: a.commonName }),
          checked === null ? null : h("span", { class: `chip${checked ? "" : " uncollected"}`, style: "margin-left:6px", text: checked ? "Photo matches its stored digest" : "Photo does not match its digest" })),
        h("dl", { class: "facts" },
          h("dt", { text: "Nickname" }), h("dd", { text: a.nickname ?? "None" }),
          h("dt", { text: "Where" }), h("dd", { text: location.source === "device" ? `Device position ${location.latitude}, ${location.longitude}` : location.description ?? "" }),
          h("dt", { text: "Encounter" }), h("dd", { text: a.encounterId }),
          h("dt", { text: "Photo" }), h("dd", { text: photo ? `${photo.mediaType}, ${Number(photo.byteLength).toLocaleString()} bytes` : "None" }),
          h("dt", { text: "Digest" }), h("dd", { text: photo?.contentSha256 ?? "" })),
        h("div", { class: "row", style: "margin-top:18px" }, h("a", { class: "button secondary", href: "#/team", text: "Put it on my team" }),
          h("a", { class: "button secondary", href: `#/capture?animal=${encodeURIComponent(a.definitionId)}`, text: "Capture another" })))),
    evidence("nerdery-view-collected-animal", result));
}

async function teamView() {
  const [mine, home] = await Promise.all([run("nerdery-view-collected-animals"), run("nerdery-view-wildlife-home")]);
  if (mine.status !== "LISTED") return page("Team", null, refusal(mine), evidence("nerdery-view-collected-animals", mine));
  if (home.status !== "VISIBLE") return page("Team", null, refusal(home), evidence("nerdery-view-wildlife-home", home));
  const onTeam = new Set(home.team.members.map((m) => m.encounterId));
  const outcome = h("div");
  const picks = mine.items.map((item) => {
    const box = h("input", { type: "checkbox", value: item.encounterId, checked: onTeam.has(item.encounterId) });
    const card = h("label", { class: `card pick${box.checked ? " checked" : ""}` }, box, photoBox(viewIndividual(item.encounterId)),
      h("div", { class: "body" }, h("div", { class: "title", text: item.displayName }), h("div", { class: "sub", text: item.encounterId })));
    box.addEventListener("change", () => card.classList.toggle("checked", box.checked));
    return { box, card };
  });
  const save = h("button", { class: "button", text: "Save my team", onclick: async () => {
    save.disabled = true;
    const result = await run("nerdery-set-animal-team", { expectedRevision: home.team.revision, encounterIds: picks.filter((p) => p.box.checked).map((p) => p.box.value) });
    save.disabled = false;
    if (result.status === "SAVED") {
      home.team.revision = result.team.revision;
      outcome.replaceChildren(h("div", { class: "notice ok" }, h("strong", { text: `Saved: ${result.team.size} on your team` }), `Team revision ${result.team.revision}. `,
        h("a", { href: "#/", text: "See it on your home page" })), evidence("nerdery-set-animal-team", result));
    } else outcome.replaceChildren(refusal(result, "Team not saved"), evidence("nerdery-set-animal-team", result));
  } });
  return page("Your team", "Choose up to six of your animals. The save names the team revision you saw, so a stale or oversized team is refused and your saved team is kept.",
    h("div", { class: "row" }, h("span", { class: "chip", text: `Saved team: ${home.team.size} (revision ${home.team.revision})` }), h("span", { class: "spacer" }), save),
    outcome,
    picks.length ? h("div", { class: "grid", style: "margin-top:16px" }, picks.map((p) => p.card)) : h("div", { class: "empty" }, "Capture an animal first. ", h("a", { href: "#/capture", text: "Capture" })),
    evidence("nerdery-view-wildlife-home", home));
}

// The biologist's catalog maintenance. Each change names the revision it was made from, as the features require;
// the operations decide what is allowed and this screen shows their answers.
const checks = (options, selected) => h("div", { class: "checks" }, options.map((o) => h("label", { class: "check" },
  h("input", { type: "checkbox", value: o.value, checked: selected.includes(o.value) }), o.label)));
const checked = (group) => [...group.querySelectorAll("input:checked")].map((input) => input.value);
const field = (label, input, hint) => h("label", { class: "field" }, label, hint ? h("span", { class: "hint", text: hint }) : null, input);
const slug = (text) => text.trim().toLowerCase().replace(/[^a-z0-9]+/g, "-").replace(/^-+|-+$/g, "");
async function catalogView() {
  const lists = h("div"), outcome = h("div"), editor = h("div");
  let catalog = null;
  const report = (capability, result, success) => {
    outcome.replaceChildren(result.mutation?.applied ? h("div", { class: "notice ok" }, h("strong", { text: success(result) })) : refusal(result, "Nothing changed"),
      evidence(capability, result));
    outcome.scrollIntoView({ block: "nearest" });
    if (result.mutation?.applied) { editor.replaceChildren(); load(); }
  };
  const editAnimal = (d) => {
    const v = d ?? { commonName: "", scientificName: "", collectionNumber: Math.max(0, ...catalog.definitions.map((x) => x.collectionNumber)) + 1,
      avatarPhotoRef: catalog.avatarPhotoRefs[0], range: [], types: [], stats: { Strength: 5, Size: 5, Speed: 5 }, attributes: [] };
    const common = h("input", { type: "text", value: v.commonName }), scientific = h("input", { type: "text", value: v.scientificName });
    const number = h("input", { type: "number", min: "1", value: v.collectionNumber });
    const avatar = h("select", {}, catalog.avatarPhotoRefs.map((ref) => h("option", { value: ref, selected: ref === v.avatarPhotoRef, text: ref })));
    const range = checks(catalog.counties.map((c) => ({ value: c.countyId, label: c.name })), v.range);
    const types = checks(catalog.types.map((t) => ({ value: t, label: t })), v.types);
    const stats = Object.entries(v.stats).map(([name, value]) => ({ name, input: h("input", { type: "number", value }) }));
    const chosen = (id) => (v.attributes.find((a) => a.attributeId === id) || {}).valueIds || [];
    const attributes = catalog.attributes.filter((a) => a.active || chosen(a.attributeId).length)
      .map((a) => ({ id: a.attributeId, group: checks(a.selectableValues.map((s) => ({ value: s.valueId, label: s.label })), chosen(a.attributeId)), name: a.name }));
    const save = h("button", { class: "button", type: "submit", text: d ? `Save revision ${d.revision + 1}` : "Add to the catalog" });
    const form = h("form", { class: "panel stack editor", onsubmit: async (event) => {
      event.preventDefault();
      const animal = { commonName: common.value, scientificName: scientific.value, avatarPhotoRef: avatar.value, collectionNumber: Number(number.value),
        range: checked(range), types: checked(types), stats: Object.fromEntries(stats.map((s) => [s.name, Number(s.input.value)])),
        attributes: attributes.map((a) => ({ attributeId: a.id, valueIds: checked(a.group) })).filter((a) => a.valueIds.length) };
      save.disabled = true;
      const result = d ? await run("nerdery-update-animal-definition", { definitionId: d.definitionId, expectedRevision: d.revision, animal })
        : await run("nerdery-add-animal-definition", { animal });
      save.disabled = false;
      report(d ? "nerdery-update-animal-definition" : "nerdery-add-animal-definition", result,
        (r) => (d ? `${r.animal.commonName} saved at revision ${r.animal.revision}.` : `${r.animal.commonName} added as ${r.definitionId}.`));
    } },
      h("h2", { text: d ? `Edit ${d.commonName}` : "Add an animal" }),
      h("div", { class: "two" }, field("Common name", common), field("Scientific name", scientific), field("Collection number", number), field("Avatar picture", avatar)),
      field("Range", range), field("Types", types, "At most two"),
      field("Stats", h("div", { class: "two" }, stats.map((s) => field(s.name, s.input)))),
      attributes.length ? field("Attributes", h("div", { class: "stack" }, attributes.map((a) => h("div", {}, h("div", { class: "sub", text: a.name }), a.group)))) : null,
      h("div", { class: "row" }, save, h("button", { type: "button", class: "button secondary", text: "Cancel", onclick: () => editor.replaceChildren() })));
    editor.replaceChildren(form);
    form.scrollIntoView({ block: "start" });
  };
  const editAttribute = (a) => {
    const name = h("input", { type: "text", value: a?.name ?? "" }), description = h("input", { type: "text", value: a?.description ?? "" });
    const rows = h("div", { class: "stack" });
    const addRow = (value) => {
      const label = h("input", { type: "text", value: value?.label ?? "", placeholder: "Label, e.g. Night" });
      const row = h("div", { class: "row value-row" }, label, h("button", { type: "button", class: "button secondary small", text: "Remove", onclick: () => row.remove() }));
      row.valueId = value?.valueId ?? null; row.label = label;
      rows.append(row);
    };
    (a?.selectableValues ?? [{}, {}]).forEach((value) => addRow(value.valueId ? value : null));
    const save = h("button", { class: "button", type: "submit", text: a ? `Save revision ${a.revision + 1}` : "Add the attribute" });
    const form = h("form", { class: "panel stack editor", onsubmit: async (event) => {
      event.preventDefault();
      const attribute = { name: name.value, description: description.value,
        selectableValues: [...rows.children].map((row) => ({ valueId: row.valueId ?? slug(row.label.value), label: row.label.value })) };
      save.disabled = true;
      const result = a ? await run("nerdery-update-animal-attribute", { attributeId: a.attributeId, expectedRevision: a.revision, attribute })
        : await run("nerdery-add-animal-attribute", { attribute });
      save.disabled = false;
      report(a ? "nerdery-update-animal-attribute" : "nerdery-add-animal-attribute", result,
        (r) => `${r.attribute.name} ${a ? `saved at revision ${r.attribute.revision}` : "added"}; it offers ${r.attribute.selectableValues.map((s) => s.label).join(", ")}.`);
    } },
      h("h2", { text: a ? `Edit ${a.name}` : "Add an attribute" }),
      h("div", { class: "two" }, field("Name", name), field("Description", description)),
      field("Selectable values", h("div", { class: "stack" }, rows, h("div", {}, h("button", { type: "button", class: "button secondary small", text: "Add a value", onclick: () => addRow(null) })))),
      h("div", { class: "row" }, save, h("button", { type: "button", class: "button secondary", text: "Cancel", onclick: () => editor.replaceChildren() })));
    editor.replaceChildren(form);
    form.scrollIntoView({ block: "start" });
  };
  const removeAnimal = async (d) => {
    if (!confirm(`Remove ${d.commonName} from the active catalog? Individuals already recorded keep it.`)) return;
    report("nerdery-remove-animal-definition", await run("nerdery-remove-animal-definition", { definitionId: d.definitionId, expectedRevision: d.revision }),
      (r) => `${d.commonName} is out of the active catalog. ${r.history.encountersRetained} recorded encounters and ${r.history.teamReferencesRetained} team places keep it.`);
  };
  const removeAttribute = async (a) => {
    if (!confirm(`Remove ${a.name}? Animals that use it keep showing it.`)) return;
    report("nerdery-remove-animal-attribute", await run("nerdery-remove-animal-attribute", { attributeId: a.attributeId, expectedRevision: a.revision }),
      (r) => `${a.name} can no longer be chosen. ${r.history.definitionReferencesRetained} animal definitions keep it.`);
  };
  const removedChip = (active) => (active ? null : h("span", { class: "chip uncollected", text: "Removed" }));
  const load = async () => {
    catalog = await run("nerdery-view-catalog-for-maintenance");
    if (catalog.status !== "VISIBLE") { lists.replaceChildren(refusal(catalog), evidence("nerdery-view-catalog-for-maintenance", catalog)); return; }
    lists.replaceChildren(
      h("div", { class: "row" }, h("h2", { text: "Animals" }), h("span", { class: "spacer" }), h("button", { class: "button small", text: "Add an animal", onclick: () => editAnimal(null) })),
      h("table", { class: "list" }, h("thead", {}, h("tr", {}, ["No.", "Animal", "Scientific name", "Types", "Range", "Revision", ""].map((t) => h("th", { text: t })))),
        h("tbody", {}, catalog.definitions.map((d) => h("tr", {},
          h("td", { text: String(d.collectionNumber).padStart(3, "0") }), h("td", {}, d.commonName, " ", removedChip(d.active)), h("td", { text: d.scientificName }),
          h("td", { text: (d.types || []).join(", ") }), h("td", { text: (d.range || []).map(countyName).join(", ") }), h("td", { text: d.revision }),
          h("td", { class: "actions" }, h("button", { class: "button secondary small", text: "Edit", onclick: () => editAnimal(d) }),
            d.active ? h("button", { class: "button secondary small", text: "Remove", onclick: () => removeAnimal(d) }) : null))))),
      h("div", { class: "row" }, h("h2", { text: "Attributes" }), h("span", { class: "spacer" }), h("button", { class: "button small", text: "Add an attribute", onclick: () => editAttribute(null) })),
      h("table", { class: "list" }, h("thead", {}, h("tr", {}, ["Attribute", "Description", "Values", "Revision", ""].map((t) => h("th", { text: t })))),
        h("tbody", {}, catalog.attributes.map((a) => h("tr", {},
          h("td", {}, a.name, " ", removedChip(a.active)), h("td", { text: a.description }), h("td", { text: a.selectableValues.map((s) => s.label).join(", ") }),
          h("td", { text: a.revision }),
          h("td", { class: "actions" }, h("button", { class: "button secondary small", text: "Edit", onclick: () => editAttribute(a) }),
            a.active ? h("button", { class: "button secondary small", text: "Remove", onclick: () => removeAttribute(a) }) : null))))),
      evidence("nerdery-view-catalog-for-maintenance", catalog));
  };
  await load();
  return page("Maintain the catalog", "Add, change and remove animals and their shared attributes. Every change names the revision you opened, so an edit made from an older revision is refused and nothing is overwritten. Removing keeps recorded individuals intact.",
    outcome, editor, lists);
}

// ---------- routing ----------
const routes = [
  [/^\/sign-in$/, signInView], [/^\/$/, homeView], [/^\/collection$/, collectionView], [/^\/animal\/([^/]+)$/, animalView],
  [/^\/capture$/, captureView], [/^\/mine$/, mineView], [/^\/mine\/([^/]+)$/, individualView], [/^\/team$/, teamView], [/^\/catalog$/, catalogView]
];
// Each screen belongs to a section whose access nerdery-resolve-wildlife-access decides from the user's current roles.
const SECTIONS = [[/^\/$/, "home"], [/^\/(collection|animal\/)/, "collection"], [/^\/(capture|mine)/, "collected-animals"], [/^\/team$/, "team"],
  [/^\/catalog$/, "animal-definitions-admin"]];
let maintenance = null;
function renderChrome(path) {
  nav.hidden = !session.authenticated;
  // The catalog is offered when the access operation allows it; its operations refuse anyone else whatever is shown.
  document.getElementById("nav-catalog").hidden = maintenance?.status !== "ALLOWED";
  for (const link of nav.querySelectorAll("a")) {
    const target = link.getAttribute("href").slice(1);
    link.classList.toggle("active", target === "/" ? path === "/" : path.startsWith(target));
  }
  if (!session.authenticated) { who.replaceChildren(); return; }
  const user = session.user;
  who.replaceChildren(h("span", { class: "name", text: `${user.firstName} ${user.lastName}` }), ...user.roles.map((r) => h("span", { class: "chip role", text: r })),
    h("button", { class: "button secondary small", text: "Sign out", onclick: async () => { await call("POST", "/api/sign-out"); location.hash = "#/sign-in"; } }));
}
let ticket = 0;
async function render() {
  const mine = ++ticket;
  const [path, query] = (location.hash.replace(/^#/, "") || "/").split("?");
  session = await call("GET", "/api/session");
  if (!reference.counties.length) reference = await call("GET", "/api/reference");
  maintenance = session.authenticated ? await run("nerdery-resolve-wildlife-access", { section: "animal-definitions-admin" }) : null;
  renderChrome(path);
  if (!session.authenticated && path !== "/sign-in") { location.hash = "#/sign-in"; return; }
  if (session.authenticated && path === "/sign-in") { location.hash = "#/"; return; }
  const [pattern, screen] = routes.find(([re]) => re.test(path)) ?? routes[1];
  const args = (path.match(pattern) || []).slice(1).map(decodeURIComponent);
  view.replaceChildren(h("p", { class: "lede", text: "Loading…" }));
  const section = SECTIONS.find(([re]) => re.test(path))?.[1];
  if (section && session.authenticated) {
    const access = section === "animal-definitions-admin" ? maintenance : await run("nerdery-resolve-wildlife-access", { section });
    if (access.status !== "ALLOWED") {
      if (mine === ticket) view.replaceChildren(page("Not available to you", null, refusal(access, "No access"), evidence("nerdery-resolve-wildlife-access", access)));
      return;
    }
  }
  const content = await screen(...args, new URLSearchParams(query || ""));
  if (mine === ticket) { view.replaceChildren(content); window.scrollTo(0, 0); }
}
window.addEventListener("hashchange", render);
render();
