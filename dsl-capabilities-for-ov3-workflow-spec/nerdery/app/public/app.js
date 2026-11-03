// The Wildlife Collection web application. Every screen runs a canonical feature's operation through the local
// server and renders that operation's own answer, refusals included; no business rule lives in the page. Its labels
// come from nerdery-present-wildlife-experience in the chosen locale; the animals and their data never change with it.
const view = document.getElementById("view");
const nav = document.getElementById("nav");
const who = document.getElementById("who");
let session = { authenticated: false };
let reference = { counties: [], types: [] };
let labels = {};
let locale = (() => { try { return localStorage.getItem("nrd-locale") === "es" ? "es" : "en"; } catch { return "en"; } })();

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
// The SideFX run behind each answer, for its evidence line and its circuit link.
const runIds = new WeakMap();
async function call(method, url, body) {
  const response = await fetch(url, { method, credentials: "same-origin", headers: body ? { "content-type": "application/json" } : {},
    body: body ? JSON.stringify(body) : undefined });
  const answer = await response.json();
  const runId = response.headers.get("x-sfx-run-id");
  if (runId && answer && typeof answer === "object") runIds.set(answer, runId);
  return answer;
}
const run = (capability, request = {}) => call("POST", `/api/run/${capability}`, request);
const declared = (capability) => (session.declared || []).includes(capability);
const CIRCUIT = "https://sidefx-web-staging.azurewebsites.net/circuit/explorer";
// A label in the current locale, with {name} filled from vars.
const t = (key, vars = {}) => String(labels[key] ?? key).replace(/\{(\w+)\}/g, (_, name) => (vars[name] === undefined ? "" : String(vars[name])));
const number = (value) => Number(value).toLocaleString(locale);

function refusal(result, titleKey = "refused") {
  const code = result?.reason?.code ?? "NO_ANSWER";
  const reason = labels[`reason.${code}`] ?? t("reason.default");
  return h("div", { class: "notice error" }, h("strong", { text: `${t(titleKey)}: ${reason}` }), h("code", { text: code }));
}
// The operation's own answer, for whoever wants to see what the screen was built from.
function evidence(capability, result) {
  const text = JSON.stringify(result, (key, value) => (key === "contentBase64" && typeof value === "string"
    ? `<${Math.floor(value.length * 3 / 4).toLocaleString()} bytes, base64>` : key === "labels" && value && typeof value === "object" ? `<${Object.keys(value).length} labels>` : value), 2);
  const runId = result && typeof result === "object" ? runIds.get(result) : null;
  const label = `${capability} · ${result?.status ?? "no answer"}${result?.reason ? ` · ${result.reason.code}` : ""}${runId ? ` · ${t("evidence.run")} ${runId.slice(0, 8)}` : ""}`;
  const link = runId ? h("p", {}, h("a", { href: `${CIRCUIT}?${new URLSearchParams({ capability, namespace: "sidefx:capabilities", run: runId })}`, target: "_blank", rel: "noopener",
    text: t("evidence.openRun") })) : null;
  return h("details", { class: "evidence" }, h("summary", { text: label }), link, h("pre", { text }));
}
const countyName = (id) => reference.counties.find((c) => c.countyId === id)?.name ?? id;
const photoUrl = (photo) => (photo?.contentBase64 ? `data:${photo.mediaType};base64,${photo.contentBase64}` : null);
function tile(animal, locked) {
  const hue = ((animal.collectionNumber ?? 1) * 67) % 360;
  return h("div", { class: `tile${locked ? " locked" : ""}`, style: `--hue:${hue}` },
    h("span", { class: "number", text: `No. ${String(animal.collectionNumber ?? "?").padStart(3, "0")}` }), (animal.commonName || "?").trim().split(/\s+/).pop().slice(0, 1));
}
const stateChip = (collected) => h("span", { class: `chip${collected ? "" : " uncollected"}`, text: collected ? t("state.collected") : t("state.notYet") });
function statBars(stats) {
  return h("div", { class: "stats" }, Object.entries(stats || {}).map(([name, value]) =>
    h("div", { class: "stat" }, h("span", { text: name }), h("div", { class: "bar" }, h("span", { style: `width:${Math.min(100, Number(value) * 10)}%` })), h("span", { text: value }))));
}
function photoBox(result) {
  const box = h("div", { class: "photo", text: t("photo.loading") });
  Promise.resolve(result).then((answer) => {
    const url = photoUrl(answer?.animal?.photo);
    box.replaceChildren(url ? h("img", { src: url, alt: answer.animal.displayName ?? "" }) : h("span", { text: t("photo.none") }));
  });
  return box;
}
const viewIndividual = (encounterId) => run("nerdery-view-collected-animal", { encounterId });
const page = (title, lede, ...content) => h("section", {}, h("h1", { text: title }), lede ? h("p", { class: "lede", text: lede }) : null, ...content);

// ---------- screens ----------
// Every run goes out as the SideFX session the local sfx-api client holds; without one there is nothing to show.
async function sideFxSignInView() {
  return page(t("sign-in.sidefx.title"), t("sign-in.sidefx.lede"), h("pre", { class: "panel", text: "sfx-api login" }),
    h("p", {}, h("button", { class: "button", text: t("sign-in.sidefx.retry"), onclick: () => render() })));
}
async function signInView() {
  if (!declared("nerdery-sign-in-wildlife-user")) return sideFxSignInView();
  const identities = await call("GET", "/api/identities");
  const message = h("div");
  const cards = identities.map((i) => {
    const valid = i.validation === "VALID";
    const label = i.name ?? (i.validation === "EXPIRED" ? t("sign-in.expired") : t("sign-in.rejected"));
    const detail = !valid ? t("sign-in.answers", { value: i.validation }) : i.registered
      ? t("sign-in.roles", { roles: i.roles.map((r) => labels[`role.${r}`] ?? r).join(", ") || t("sign-in.none") }) : t("sign-in.unregistered");
    const initials = i.name ? i.name.split(" ").map((p) => p[0]).join("") : "?";
    // A validated DNR subject without a wildlife profile is told so by sign-in, and offered registration.
    const register = async () => {
      const answer = await call("POST", "/api/register", { identityResponseRef: i.identityResponseRef });
      if (answer.signIn?.status === "SIGNED_IN") { location.hash = "#/"; return; }
      message.replaceChildren(refusal(answer.signIn ?? answer.registration, "sign-in.notRegistered"), evidence("nerdery-register-wildlife-user", answer.registration),
        answer.signIn ? evidence("nerdery-sign-in-wildlife-user", answer.signIn) : null);
    };
    return h("button", { class: `card identity${valid && i.registered ? "" : " refusal"}`, onclick: async () => {
      const result = await call("POST", "/api/sign-in", { identityResponseRef: i.identityResponseRef });
      if (result.status === "SIGNED_IN") { location.hash = "#/"; return; }
      message.replaceChildren(refusal(result, "sign-in.refused"),
        result.reason?.code === "REGISTRATION_REQUIRED" ? h("p", {}, h("button", { class: "button", text: t("sign-in.register", { name: i.name ?? "" }), onclick: register })) : null,
        evidence("nerdery-sign-in-wildlife-user", result));
    } }, h("div", { class: "body row" }, h("div", { class: "avatar", text: initials }), h("div", {}, h("div", { class: "title", text: label }), h("div", { class: "sub", text: detail }))));
  });
  return page(t("sign-in.title"), t("sign-in.lede"), h("div", { class: "grid" }, cards), message);
}

async function homeView() {
  const [home, mine] = await Promise.all([run("nerdery-view-wildlife-home"), run("nerdery-view-collected-animals")]);
  if (home.status !== "VISIBLE") return page(t("home.title"), null, refusal(home), evidence("nerdery-view-wildlife-home", home));
  const members = home.team.members;
  return page(session.user?.firstName ? t("home.hello", { name: session.user.firstName }) : t("home.welcome"), t("home.lede"),
    h("div", { class: "row" },
      h("div", { class: "panel" }, h("div", { class: "sub", text: t("home.collected") }), h("h1", { text: mine.total ?? 0 })),
      h("div", { class: "panel" }, h("div", { class: "sub", text: t("home.onTeam") }), h("h1", { text: `${home.team.size} / 6` })),
      h("span", { class: "spacer" }),
      h("a", { class: "button", href: "#/capture", text: t("home.capture") }), h("a", { class: "button secondary", href: "#/collection", text: t("home.browse") })),
    h("h2", { text: t("home.team") }),
    members.length ? h("div", { class: "grid" }, members.map((m) => h("a", { class: "card", href: `#/mine/${encodeURIComponent(m.encounterId)}` },
      photoBox(viewIndividual(m.encounterId)), h("div", { class: "body" }, h("div", { class: "title", text: m.displayName }), h("div", { class: "sub", text: m.encounterId })))))
      : h("div", { class: "empty" }, `${t("home.noTeam")} `, h("a", { href: "#/team", text: t("home.pickTeam") })),
    evidence("nerdery-view-wildlife-home", home), evidence("nerdery-view-collected-animals", mine));
}

function animalCard(item) {
  const a = item.animal, collected = item.collectionState === "COLLECTED";
  return h("a", { class: "card", href: `#/animal/${encodeURIComponent(item.definitionId)}` }, tile(a, !collected),
    h("div", { class: "body" },
      h("div", { class: "row" }, h("div", { class: "title", text: a.commonName }), h("span", { class: "spacer" }), stateChip(collected)),
      h("div", { class: "sub", text: (a.range || []).map(countyName).join(", ") }),
      collected ? [h("div", { class: "sub", text: a.scientificName }), h("div", { class: "chips" }, (a.types || []).map((x) => h("span", { class: "chip amber", text: x }))), statBars(a.stats)]
        : h("div", { class: "sub", text: t("collection.locked") })));
}
async function collectionView(params, title) {
  const input = h("input", { type: "search", placeholder: t("collection.search"), value: params.get("q") ?? "", style: "width:100%;max-width:420px" });
  const results = h("div");
  let latest = 0;
  const load = async () => {
    const ticketNow = ++latest;
    const result = await run("nerdery-browse-animal-collection", { search: input.value });
    if (ticketNow !== latest) return;
    results.replaceChildren(...(result.status === "LISTED"
      ? [h("p", { class: "sub", text: result.total === 1 ? t("collection.countOne") : t("collection.count", { count: result.total }) }),
        result.items.length ? h("div", { class: "grid" }, result.items.map(animalCard)) : h("div", { class: "empty", text: t("collection.none") })]
      : [refusal(result)]), evidence("nerdery-browse-animal-collection", result));
  };
  let timer = null;
  input.addEventListener("input", () => { clearTimeout(timer); timer = setTimeout(load, 200); });
  await load();
  return page(title ?? t("collection.title"), t("collection.lede"), h("div", { class: "row" }, input), results);
}

async function animalView(definitionId) {
  const [result, mine] = await Promise.all([run("nerdery-view-animal-definition", { definitionId }), run("nerdery-view-collected-animals")]);
  if (result.status !== "VISIBLE") return page(t("animal.title"), null, refusal(result), evidence("nerdery-view-animal-definition", result));
  const a = result.animal, collected = result.collectionState === "COLLECTED";
  const individuals = (mine.items || []).filter((i) => i.definitionId === result.definitionId);
  return h("section", {},
    h("p", {}, h("a", { href: "#/collection", text: t("animal.back") })),
    h("div", { class: "split" },
      h("div", { class: "card" }, tile(a, !collected)),
      h("div", {},
        h("div", { class: "row" }, h("h1", { text: a.commonName }), stateChip(collected)),
        h("dl", { class: "facts" }, h("dt", { text: t("animal.number") }), h("dd", { text: a.collectionNumber }),
          h("dt", { text: t("animal.range") }), h("dd", { text: (a.range || []).map(countyName).join(", ") }),
          collected ? [h("dt", { text: t("animal.scientific") }), h("dd", { text: a.scientificName }),
            h("dt", { text: t("animal.types") }), h("dd", {}, h("div", { class: "chips" }, (a.types || []).map((x) => h("span", { class: "chip amber", text: x }))))] : null),
        collected ? [h("h2", { text: t("animal.stats") }), statBars(a.stats),
          h("h2", { text: t("animal.attributes") }),
          h("table", { class: "list" }, h("thead", {}, h("tr", {}, h("th", { text: t("animal.attribute") }), h("th", { text: t("animal.value") }), h("th", { text: t("animal.about") }))),
            h("tbody", {}, (a.attributeDetails || []).map((d) => h("tr", {}, h("td", { text: d.name }), h("td", { text: (d.selectedValues || []).map((v) => v.label).join(", ") }), h("td", { text: d.description ?? "" })))))]
          : h("div", { class: "notice locked" }, h("strong", { text: t("animal.lockedTitle") }), `${t("animal.lockedBody")} `,
            h("a", { class: "button small", href: `#/capture?animal=${encodeURIComponent(result.definitionId)}`, text: t("animal.captureIt") })))),
    individuals.length ? [h("h2", { text: t("animal.yours") }),
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
async function captureView(params, title) {
  const browse = await run("nerdery-browse-animal-collection", { search: "" });
  const animals = browse.items || [];
  // One encounter id per capture, kept across a retry so a resubmission replays instead of recording twice (D07).
  const state = { encounterId: null, upload: null, file: null, position: null };
  const preview = h("div", { class: "sub", text: t("capture.noPhoto") });
  const fileInput = h("input", { type: "file", accept: "image/*", onchange: () => {
    state.file = fileInput.files[0] ?? null; state.upload = null; state.encounterId = null;
    preview.replaceChildren(state.file ? h("img", { src: URL.createObjectURL(state.file), alt: t("capture.chosen") }) : t("capture.noPhoto"));
  } });
  const animal = h("select", { name: "definitionId" }, animals.map((i) => h("option", { value: i.definitionId, selected: i.definitionId === params.get("animal"),
    text: `No. ${String(i.animal.collectionNumber).padStart(3, "0")} ${i.animal.commonName}${i.collectionState === "COLLECTED" ? ` ${t("capture.collectedSuffix")}` : ""}` })));
  const positionNote = h("span", { class: "hint" });
  const where = h("input", { type: "text", placeholder: t("capture.wherePlaceholder"), oninput: () => { state.position = null; positionNote.textContent = ""; } });
  const usePosition = h("button", { type: "button", class: "button secondary small", text: t("capture.usePosition"), onclick: () => {
    if (!navigator.geolocation) { positionNote.textContent = t("capture.noGeo"); return; }
    positionNote.textContent = t("capture.finding");
    navigator.geolocation.getCurrentPosition((p) => {
      state.position = { latitude: Number(p.coords.latitude.toFixed(6)), longitude: Number(p.coords.longitude.toFixed(6)) };
      where.value = ""; positionNote.textContent = t("capture.position", state.position);
    }, (error) => { positionNote.textContent = t("capture.noPosition", { message: error.message }); });
  } });
  const nickname = h("input", { type: "text", placeholder: t("capture.nicknamePlaceholder") });
  const submit = h("button", { class: "button", type: "submit", text: t("capture.record") });
  const outcome = h("div");
  const form = h("form", { class: "stack panel", onsubmit: async (event) => {
    event.preventDefault();
    submit.disabled = true; submit.textContent = t("capture.recording");
    const shown = [];
    try {
      if (!state.upload) {
        const file = state.file;
        const upload = await run("nerdery-upload-encounter-photo", { fileName: file?.name ?? "", mediaType: file?.type ?? "", contentBase64: file ? await fileBase64(file) : "" });
        shown.push(evidence("nerdery-upload-encounter-photo", upload));
        if (upload.status !== "UPLOADED") { outcome.replaceChildren(refusal(upload, "capture.photoNotKept"), ...shown); return; }
        state.upload = upload;
      }
      state.encounterId ??= `enc-${Date.now().toString(36)}-${Math.random().toString(36).slice(2, 6)}`;
      const location = state.position ? { source: "device", ...state.position } : { source: "manual", description: where.value };
      const record = await run("nerdery-record-animal-encounter", { encounterId: state.encounterId, definitionId: animal.value, location,
        photoRef: state.upload.photo.photoRef, ...(nickname.value.trim() ? { nickname: nickname.value.trim() } : {}) });
      shown.push(evidence("nerdery-record-animal-encounter", record));
      if (record.status !== "RECORDED") { outcome.replaceChildren(refusal(record, "capture.notRecorded"), ...shown); return; }
      const id = record.encounter.encounterId;
      const name = animals.find((i) => i.definitionId === record.encounter.definitionId)?.animal.commonName ?? record.encounter.definitionId;
      outcome.replaceChildren(h("div", { class: "notice ok" }, h("strong", { text: t("capture.inCollection", { name: record.encounter.nickname ?? name }) }),
        `${record.replayed ? t("capture.replayed") : t("capture.unlocked", { name })} `,
        h("a", { class: "button small", href: `#/mine/${encodeURIComponent(id)}`, text: t("capture.seeIt") })), ...shown);
      state.encounterId = null; state.upload = null; state.file = null; fileInput.value = ""; nickname.value = "";
      preview.replaceChildren(t("capture.noPhoto"));
    } finally { submit.disabled = false; submit.textContent = t("capture.record"); }
  } },
    h("label", { class: "field" }, t("capture.photo"), h("div", { class: "drop" }, preview, fileInput)),
    h("label", { class: "field" }, t("capture.animal"), animal),
    h("label", { class: "field" }, t("capture.where"), where, h("div", { class: "row" }, usePosition, positionNote)),
    h("label", { class: "field" }, t("capture.nickname"), nickname),
    h("div", { class: "row" }, submit));
  return page(title ?? t("capture.title"), t("capture.lede"), h("div", { class: "split" }, form, outcome));
}

async function mineView(params, presentedTitle) {
  const title = presentedTitle ?? t("collected-animals.title");
  const mine = await run("nerdery-view-collected-animals");
  if (mine.status !== "LISTED") return page(title, null, refusal(mine), evidence("nerdery-view-collected-animals", mine));
  const cards = mine.items.map((item) => {
    const answer = viewIndividual(item.encounterId);
    const species = h("div", { class: "sub", text: item.definitionId });
    answer.then((r) => { if (r.animal) species.textContent = item.nickname ? r.animal.commonName : t("mine.noNickname"); });
    return h("a", { class: "card", href: `#/mine/${encodeURIComponent(item.encounterId)}` }, photoBox(answer),
      h("div", { class: "body" }, h("div", { class: "title", text: item.displayName }), species));
  });
  return page(title, t("mine.lede"),
    cards.length ? h("div", { class: "grid" }, cards) : h("div", { class: "empty" }, `${t("mine.none")} `, h("a", { href: "#/capture", text: t("mine.captureFirst") })),
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
  const back = h("p", {}, h("a", { href: "#/mine", text: t("individual.back") }));
  if (result.status !== "VISIBLE") return h("section", {}, back, refusal(result), evidence("nerdery-view-collected-animal", result));
  const a = result.animal, photo = a.photo, where = a.location || {};
  const matches = await digestMatches(photo);
  return h("section", {}, back,
    h("div", { class: "split" },
      h("div", { class: "hero-photo" }, photoUrl(photo) ? h("img", { src: photoUrl(photo), alt: a.displayName }) : h("div", { class: "photo", text: t("individual.noPhoto") })),
      h("div", {},
        h("h1", { text: a.displayName }),
        h("p", {}, h("a", { class: "chip", href: `#/animal/${encodeURIComponent(a.definitionId)}`, text: a.commonName }),
          matches === null ? null : h("span", { class: `chip${matches ? "" : " uncollected"}`, style: "margin-left:6px", text: matches ? t("individual.digestOk") : t("individual.digestBad") })),
        h("dl", { class: "facts" },
          h("dt", { text: t("individual.nickname") }), h("dd", { text: a.nickname ?? t("individual.none") }),
          h("dt", { text: t("individual.where") }), h("dd", { text: where.source === "device" ? t("individual.device", where) : where.description ?? "" }),
          h("dt", { text: t("individual.encounter") }), h("dd", { text: a.encounterId }),
          h("dt", { text: t("individual.photo") }), h("dd", { text: photo ? t("individual.bytes", { mediaType: photo.mediaType, count: number(photo.byteLength) }) : t("individual.none") }),
          h("dt", { text: t("individual.digest") }), h("dd", { text: photo?.contentSha256 ?? "" })),
        h("div", { class: "row", style: "margin-top:18px" }, h("a", { class: "button secondary", href: "#/team", text: t("individual.toTeam") }),
          h("a", { class: "button secondary", href: `#/capture?animal=${encodeURIComponent(a.definitionId)}`, text: t("individual.another") })))),
    evidence("nerdery-view-collected-animal", result));
}

async function teamView(params, title) {
  const [mine, home] = await Promise.all([run("nerdery-view-collected-animals"), run("nerdery-view-wildlife-home")]);
  if (mine.status !== "LISTED") return page(title ?? t("team.title"), null, refusal(mine), evidence("nerdery-view-collected-animals", mine));
  if (home.status !== "VISIBLE") return page(title ?? t("team.title"), null, refusal(home), evidence("nerdery-view-wildlife-home", home));
  const onTeam = new Set(home.team.members.map((m) => m.encounterId));
  const outcome = h("div");
  const picks = mine.items.map((item) => {
    const box = h("input", { type: "checkbox", value: item.encounterId, checked: onTeam.has(item.encounterId) });
    const card = h("label", { class: `card pick${box.checked ? " checked" : ""}` }, box, photoBox(viewIndividual(item.encounterId)),
      h("div", { class: "body" }, h("div", { class: "title", text: item.displayName }), h("div", { class: "sub", text: item.encounterId })));
    box.addEventListener("change", () => card.classList.toggle("checked", box.checked));
    return { box, card };
  });
  const save = h("button", { class: "button", text: t("team.save"), onclick: async () => {
    save.disabled = true;
    const result = await run("nerdery-set-animal-team", { expectedRevision: home.team.revision, encounterIds: picks.filter((p) => p.box.checked).map((p) => p.box.value) });
    save.disabled = false;
    if (result.status === "SAVED") {
      home.team.revision = result.team.revision;
      outcome.replaceChildren(h("div", { class: "notice ok" }, h("strong", { text: t("team.savedOk", { size: result.team.size }) }), `${t("team.revision", { revision: result.team.revision })} `,
        h("a", { href: "#/", text: t("team.seeHome") })), evidence("nerdery-set-animal-team", result));
    } else outcome.replaceChildren(refusal(result, "team.notSaved"), evidence("nerdery-set-animal-team", result));
  } });
  return page(title ?? t("team.title"), t("team.lede"),
    h("div", { class: "row" }, h("span", { class: "chip", text: t("team.saved", { size: home.team.size, revision: home.team.revision }) }), h("span", { class: "spacer" }), save),
    outcome,
    picks.length ? h("div", { class: "grid", style: "margin-top:16px" }, picks.map((p) => p.card)) : h("div", { class: "empty" }, `${t("team.captureFirst")} `, h("a", { href: "#/capture", text: t("nav.capture") })),
    evidence("nerdery-view-wildlife-home", home));
}

// The biologist's catalog maintenance. Each change names the revision it was made from, as the features require;
// the operations decide what is allowed and this screen shows their answers.
const checks = (options, selected) => h("div", { class: "checks" }, options.map((o) => h("label", { class: "check" },
  h("input", { type: "checkbox", value: o.value, checked: selected.includes(o.value) }), o.label)));
const checked = (group) => [...group.querySelectorAll("input:checked")].map((input) => input.value);
const field = (label, input, hint) => h("label", { class: "field" }, label, hint ? h("span", { class: "hint", text: hint }) : null, input);
const slug = (text) => text.trim().toLowerCase().replace(/[^a-z0-9]+/g, "-").replace(/^-+|-+$/g, "");
async function catalogView(params, title) {
  const lists = h("div"), outcome = h("div"), editor = h("div");
  let catalog = null;
  const report = (capability, result, success) => {
    outcome.replaceChildren(result.mutation?.applied ? h("div", { class: "notice ok" }, h("strong", { text: success(result) })) : refusal(result, "catalog.nothingChanged"),
      evidence(capability, result));
    outcome.scrollIntoView({ block: "nearest" });
    if (result.mutation?.applied) { editor.replaceChildren(); load(); }
  };
  const editAnimal = (d) => {
    const v = d ?? { commonName: "", scientificName: "", collectionNumber: Math.max(0, ...catalog.definitions.map((x) => x.collectionNumber)) + 1,
      avatarPhotoRef: catalog.avatarPhotoRefs[0], range: [], types: [], stats: { Strength: 5, Size: 5, Speed: 5 }, attributes: [] };
    const common = h("input", { type: "text", value: v.commonName }), scientific = h("input", { type: "text", value: v.scientificName });
    const collectionNumber = h("input", { type: "number", min: "1", value: v.collectionNumber });
    const avatar = h("select", {}, catalog.avatarPhotoRefs.map((ref) => h("option", { value: ref, selected: ref === v.avatarPhotoRef, text: ref })));
    const range = checks(catalog.counties.map((c) => ({ value: c.countyId, label: c.name })), v.range);
    const types = checks(catalog.types.map((x) => ({ value: x, label: x })), v.types);
    const stats = Object.entries(v.stats).map(([name, value]) => ({ name, input: h("input", { type: "number", value }) }));
    const chosen = (id) => (v.attributes.find((a) => a.attributeId === id) || {}).valueIds || [];
    const attributes = catalog.attributes.filter((a) => a.active || chosen(a.attributeId).length)
      .map((a) => ({ id: a.attributeId, group: checks(a.selectableValues.map((s) => ({ value: s.valueId, label: s.label })), chosen(a.attributeId)), name: a.name }));
    const save = h("button", { class: "button", type: "submit", text: d ? t("catalog.saveRevision", { revision: d.revision + 1 }) : t("catalog.addToCatalog") });
    const form = h("form", { class: "panel stack editor", onsubmit: async (event) => {
      event.preventDefault();
      const animal = { commonName: common.value, scientificName: scientific.value, avatarPhotoRef: avatar.value, collectionNumber: Number(collectionNumber.value),
        range: checked(range), types: checked(types), stats: Object.fromEntries(stats.map((s) => [s.name, Number(s.input.value)])),
        attributes: attributes.map((a) => ({ attributeId: a.id, valueIds: checked(a.group) })).filter((a) => a.valueIds.length) };
      save.disabled = true;
      const result = d ? await run("nerdery-update-animal-definition", { definitionId: d.definitionId, expectedRevision: d.revision, animal })
        : await run("nerdery-add-animal-definition", { animal });
      save.disabled = false;
      report(d ? "nerdery-update-animal-definition" : "nerdery-add-animal-definition", result,
        (r) => (d ? t("catalog.savedAt", { name: r.animal.commonName, revision: r.animal.revision }) : t("catalog.addedAs", { name: r.animal.commonName, id: r.definitionId })));
    } },
      h("h2", { text: d ? t("catalog.editName", { name: d.commonName }) : t("catalog.addAnimal") }),
      h("div", { class: "two" }, field(t("catalog.commonName"), common), field(t("catalog.scientific"), scientific), field(t("catalog.collectionNumber"), collectionNumber),
        field(t("catalog.avatar"), avatar)),
      field(t("catalog.range"), range), field(t("catalog.types"), types, t("catalog.atMostTwo")),
      field(t("catalog.stats"), h("div", { class: "two" }, stats.map((s) => field(s.name, s.input)))),
      attributes.length ? field(t("catalog.attributes"), h("div", { class: "stack" }, attributes.map((a) => h("div", {}, h("div", { class: "sub", text: a.name }), a.group)))) : null,
      h("div", { class: "row" }, save, h("button", { type: "button", class: "button secondary", text: t("catalog.cancel"), onclick: () => editor.replaceChildren() })));
    editor.replaceChildren(form);
    form.scrollIntoView({ block: "start" });
  };
  const editAttribute = (a) => {
    const name = h("input", { type: "text", value: a?.name ?? "" }), description = h("input", { type: "text", value: a?.description ?? "" });
    const rows = h("div", { class: "stack" });
    const addRow = (value) => {
      const label = h("input", { type: "text", value: value?.label ?? "", placeholder: t("catalog.labelPlaceholder") });
      const row = h("div", { class: "row value-row" }, label, h("button", { type: "button", class: "button secondary small", text: t("catalog.removeValue"), onclick: () => row.remove() }));
      row.valueId = value?.valueId ?? null; row.label = label;
      rows.append(row);
    };
    (a?.selectableValues ?? [{}, {}]).forEach((value) => addRow(value.valueId ? value : null));
    const save = h("button", { class: "button", type: "submit", text: a ? t("catalog.saveRevision", { revision: a.revision + 1 }) : t("catalog.addTheAttribute") });
    const form = h("form", { class: "panel stack editor", onsubmit: async (event) => {
      event.preventDefault();
      const attribute = { name: name.value, description: description.value,
        selectableValues: [...rows.children].map((row) => ({ valueId: row.valueId ?? slug(row.label.value), label: row.label.value })) };
      save.disabled = true;
      const result = a ? await run("nerdery-update-animal-attribute", { attributeId: a.attributeId, expectedRevision: a.revision, attribute })
        : await run("nerdery-add-animal-attribute", { attribute });
      save.disabled = false;
      report(a ? "nerdery-update-animal-attribute" : "nerdery-add-animal-attribute", result, (r) => {
        const values = r.attribute.selectableValues.map((s) => s.label).join(", ");
        return a ? t("catalog.attributeSaved", { name: r.attribute.name, revision: r.attribute.revision, values }) : t("catalog.attributeAdded", { name: r.attribute.name, values });
      });
    } },
      h("h2", { text: a ? t("catalog.editName", { name: a.name }) : t("catalog.addAttribute") }),
      h("div", { class: "two" }, field(t("catalog.name"), name), field(t("catalog.description"), description)),
      field(t("catalog.selectable"), h("div", { class: "stack" }, rows, h("div", {}, h("button", { type: "button", class: "button secondary small", text: t("catalog.addValue"), onclick: () => addRow(null) })))),
      h("div", { class: "row" }, save, h("button", { type: "button", class: "button secondary", text: t("catalog.cancel"), onclick: () => editor.replaceChildren() })));
    editor.replaceChildren(form);
    form.scrollIntoView({ block: "start" });
  };
  const removeAnimal = async (d) => {
    if (!confirm(t("catalog.confirmRemoveAnimal", { name: d.commonName }))) return;
    report("nerdery-remove-animal-definition", await run("nerdery-remove-animal-definition", { definitionId: d.definitionId, expectedRevision: d.revision }),
      (r) => t("catalog.animalRemoved", { name: d.commonName, encounters: r.history.encountersRetained, places: r.history.teamReferencesRetained }));
  };
  const removeAttribute = async (a) => {
    if (!confirm(t("catalog.confirmRemoveAttribute", { name: a.name }))) return;
    report("nerdery-remove-animal-attribute", await run("nerdery-remove-animal-attribute", { attributeId: a.attributeId, expectedRevision: a.revision }),
      (r) => t("catalog.attributeRemoved", { name: a.name, count: r.history.definitionReferencesRetained }));
  };
  const removedChip = (active) => (active ? null : h("span", { class: "chip uncollected", text: t("catalog.removed") }));
  const headings = (keys) => h("thead", {}, h("tr", {}, keys.map((k) => h("th", { text: k ? t(k) : "" }))));
  const load = async () => {
    catalog = await run("nerdery-view-catalog-for-maintenance");
    if (catalog.status !== "VISIBLE") { lists.replaceChildren(refusal(catalog), evidence("nerdery-view-catalog-for-maintenance", catalog)); return; }
    reference = { counties: catalog.counties, types: catalog.types };
    lists.replaceChildren(
      h("div", { class: "row" }, h("h2", { text: t("catalog.animals") }), h("span", { class: "spacer" }), h("button", { class: "button small", text: t("catalog.addAnimal"), onclick: () => editAnimal(null) })),
      h("table", { class: "list" }, headings(["catalog.number", "catalog.animal", "catalog.scientific", "catalog.types", "catalog.range", "catalog.revision", null]),
        h("tbody", {}, catalog.definitions.map((d) => h("tr", {},
          h("td", { text: String(d.collectionNumber).padStart(3, "0") }), h("td", {}, d.commonName, " ", removedChip(d.active)), h("td", { text: d.scientificName }),
          h("td", { text: (d.types || []).join(", ") }), h("td", { text: (d.range || []).map(countyName).join(", ") }), h("td", { text: d.revision }),
          h("td", { class: "actions" }, h("button", { class: "button secondary small", text: t("catalog.edit"), onclick: () => editAnimal(d) }),
            d.active ? h("button", { class: "button secondary small", text: t("catalog.remove"), onclick: () => removeAnimal(d) }) : null))))),
      h("div", { class: "row" }, h("h2", { text: t("catalog.attributes") }), h("span", { class: "spacer" }), h("button", { class: "button small", text: t("catalog.addAttribute"), onclick: () => editAttribute(null) })),
      h("table", { class: "list" }, headings(["catalog.attribute", "catalog.description", "catalog.values", "catalog.revision", null]),
        h("tbody", {}, catalog.attributes.map((a) => h("tr", {},
          h("td", {}, a.name, " ", removedChip(a.active)), h("td", { text: a.description }), h("td", { text: a.selectableValues.map((s) => s.label).join(", ") }),
          h("td", { text: a.revision }),
          h("td", { class: "actions" }, h("button", { class: "button secondary small", text: t("catalog.edit"), onclick: () => editAttribute(a) }),
            a.active ? h("button", { class: "button secondary small", text: t("catalog.remove"), onclick: () => removeAttribute(a) }) : null))))),
      evidence("nerdery-view-catalog-for-maintenance", catalog));
  };
  await load();
  return page(title ?? t("animal-definitions-admin.title"), t("catalog.lede"), outcome, editor, lists);
}

// ---------- routing ----------
// Each route has its page for nerdery-present-wildlife-experience and its section for nerdery-resolve-wildlife-access.
const routes = [
  [/^\/sign-in$/, signInView, "sign-in", null], [/^\/$/, homeView, "home", "home"], [/^\/collection$/, collectionView, "collection", "collection"],
  [/^\/animal\/([^/]+)$/, animalView, "animal", "collection"], [/^\/capture$/, captureView, "capture", "collected-animals"],
  [/^\/mine$/, mineView, "collected-animals", "collected-animals"], [/^\/mine\/([^/]+)$/, individualView, "individual", "collected-animals"],
  [/^\/team$/, teamView, "team", "team"], [/^\/catalog$/, catalogView, "animal-definitions-admin", "animal-definitions-admin"]
];
let maintenance = null;
function renderChrome(path) {
  document.documentElement.lang = locale;
  nav.hidden = !session.authenticated;
  for (const link of nav.querySelectorAll("a")) {
    const target = link.getAttribute("href").slice(1);
    link.classList.toggle("active", target === "/" ? path === "/" : path.startsWith(target));
    link.textContent = t({ "/": "nav.home", "/collection": "nav.collection", "/capture": "nav.capture", "/mine": "nav.mine", "/team": "nav.team", "/catalog": "nav.catalog" }[target]);
  }
  // The catalog is offered when the access operation allows it; its operations refuse anyone else whatever is shown.
  document.getElementById("nav-catalog").hidden = maintenance?.status !== "ALLOWED";
  document.getElementById("footer").textContent = t("chrome.footer");
  const switcher = h("div", { class: "locale", role: "group", "aria-label": t("chrome.language") }, ["en", "es"].map((code) =>
    h("button", { class: `button small ${code === locale ? "" : "secondary"}`, "aria-pressed": code === locale ? "true" : "false", text: code.toUpperCase(),
      onclick: () => { locale = code; try { localStorage.setItem("nrd-locale", code); } catch { /* the choice lasts this page only */ } render(); } })));
  if (!session.authenticated) { who.replaceChildren(switcher); return; }
  const user = session.user;
  if (!user) {
    // The SideFX session the runs go out as; signing out is sfx-api logout.
    who.replaceChildren(switcher, h("span", { class: "chip role", text: t("chrome.sidefx") }),
      h("span", { class: "name", title: `${session.endpoint ?? ""} · ${session.expiresAt ?? ""}`, text: `${String(session.principalId).slice(0, 8)}…` }));
    return;
  }
  who.replaceChildren(switcher, h("span", { class: "name", text: `${user.firstName} ${user.lastName}` }),
    ...user.roles.map((r) => h("span", { class: "chip role", text: labels[`role.${r}`] ?? r })),
    h("button", { class: "button secondary small", text: t("chrome.signOut"), onclick: async () => { await call("POST", "/api/sign-out"); location.hash = "#/sign-in"; } }));
}
let ticket = 0;
async function render() {
  const mine = ++ticket;
  const [path, query] = (location.hash.replace(/^#/, "") || "/").split("?");
  session = await call("GET", "/api/session");
  if (!session.authenticated && path !== "/sign-in") { location.hash = "#/sign-in"; return; }
  if (session.authenticated && path === "/sign-in") { location.hash = "#/"; return; }
  const [pattern, screen, pageKey, section] = routes.find(([re]) => re.test(path)) ?? routes[1];
  // The page's labels and title in the chosen locale: from nerdery-present-wildlife-experience once the estate
  // declares it, until then from the interface's own labels. A page the user may not see still gets the account labels.
  let presented = null;
  if (declared("nerdery-present-wildlife-experience")) {
    presented = await run("nerdery-present-wildlife-experience", { page: pageKey, locale });
    if (presented.status !== "PRESENTED") presented = await run("nerdery-present-wildlife-experience", { page: "sign-in", locale });
    if (presented.status === "PRESENTED") labels = presented.presentation.labels;
  } else labels = (await call("GET", `/api/labels?locale=${locale}`)).labels;
  // Section access from nerdery-resolve-wildlife-access once the estate declares it; each capability refuses on its own regardless.
  const guarded = declared("nerdery-resolve-wildlife-access");
  maintenance = guarded && session.authenticated && declared("nerdery-view-catalog-for-maintenance")
    ? await run("nerdery-resolve-wildlife-access", { section: "animal-definitions-admin" }) : null;
  renderChrome(path);
  view.replaceChildren(h("p", { class: "lede", text: t("chrome.loading") }));
  if (section && guarded) {
    const access = section === "animal-definitions-admin" ? maintenance : await run("nerdery-resolve-wildlife-access", { section });
    // Only a refusal closes the screen; a run SideFX did not answer leaves it to the screen's own capabilities.
    if (access.status === "REFUSED") {
      if (mine === ticket) view.replaceChildren(page(t("access.notAvailable"), null, refusal(access, "access.noAccess"), evidence("nerdery-resolve-wildlife-access", access)));
      return;
    }
  }
  const title = presented?.presentation?.page === pageKey ? presented.presentation.title : labels[`${pageKey}.title`];
  const args = (path.match(pattern) || []).slice(1).map(decodeURIComponent);
  const content = await screen(...args, new URLSearchParams(query || ""), title);
  if (mine === ticket) {
    view.replaceChildren(content, presented ? evidence("nerdery-present-wildlife-experience", presented) : "");
    document.title = `${title ?? t(`${pageKey}.title`)} · Wildlife Collection`;
    window.scrollTo(0, 0);
  }
}
window.addEventListener("hashchange", render);
render();
