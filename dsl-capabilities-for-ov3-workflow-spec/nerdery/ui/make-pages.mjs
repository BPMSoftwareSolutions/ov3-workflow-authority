// The wildlife application's presentation: declared ui-page-definition.v1 pages over the slice's declared
// capabilities, published through the estate's own page writers and served by the SideFX shell.
//   nerdery/ui/pages/<slug>.json                the page declarations, each at the revision it is published as
//   nerdery/ui/manifest.json                    each page's revision and the digest of its staged text
// Publication: nerdery/sql/pages-1-estate(.commit).sql staged and promoted the first eight pages as revision 1 on
// 2026-11-03 and has run; this generator no longer writes it. A later revision is published by the package that
// needs it: nerdery/make-individual.mjs publishes wildlife-mine revision 2 and wildlife-individual revision 1.
// Each page runs a capability only when the viewer submits a form or presses a button; the caller comes from
// the signed-in session (/workspace/session) and the capability verifies it against [identity].session. The
// results are the capabilities' own outputs, projected for display; no business rule lives in a page.
// Needs the shell's observe results (sfx-platform live-circuit/circuit/page-runtime.js): nested input bindings,
// the run source, read maps and when.result; the individual's photo also needs a figure that shows a digest-checked
// image data URL and the map's concat. Every page is validated here against that runtime's validatePage.
import fs from "node:fs";
import path from "node:path";
import crypto from "node:crypto";
import { fileURLToPath, pathToFileURL } from "node:url";
const here = path.dirname(fileURLToPath(import.meta.url));
const nerdery = path.resolve(here, "..");
const sha = (s) => crypto.createHash("sha256").update(Buffer.from(s, "utf8")).digest("hex");
const lit = (s) => {
  if (/^\s*GO\s*$/im.test(s)) throw new Error("a GO line inside a literal");
  if (/[^\x09\x0a\x20-\x7e]/.test(s)) throw new Error("non-ASCII inside a literal");
  return "N'" + s.split("'").join("''") + "'";
};
const RUNTIME = process.env.SFX_PAGE_RUNTIME ?? "C:/lab/repos/sfx-platform/live-circuit/circuit/page-runtime.js";
const LAYOUT = { layoutId: "ui-layout-marketing.v1", digest: "e2591ca34ce894541132dccaca54fa77d8e98b84e7f8c8c8c93ff320fe9db58c" };
const NS = "sidefx:capabilities";
const PUBLISHER = "owner:nerdery-citizen-slice";

// ---------- building blocks ----------
const caller = { principalId: { source: "session", pointer: "/principalId" }, sessionId: { source: "session", pointer: "/sessionId" } };
const observe = (actionId, capability, request, result) => ({ actionId, kind: "observe", subject: capability, namespace: NS, result,
  input: { input: { caller, request } } });
const run = (result, pointer, map) => ({ kind: "read", reader: "run", result, pointer, ...(map ? { map } : {}) });
const when = (result, pointer, equals) => (pointer ? { result, pointer, equals } : { result });
let order = 0;
const section = (sectionId, kind, rest) => ({ sectionId, regionId: "main", order: ++order, component: { kind, version: 1 }, ...rest });
const hero = (capability, eyebrow, headline, lede) => section("hero", "hero", {
  props: { eyebrow, headline, lede, primaryActionId: "open-circuit" },
  bindings: { figure: { kind: "read", reader: "scenario", input: { capabilityId: capability, namespaceId: NS, page: "scenario-1" }, pointer: "/slides/0" } },
  actions: [{ actionId: "open-circuit", kind: "navigate", to: `/circuit/explorer?capability=${capability}&namespace=${encodeURIComponent(NS)}` }]
});
const heading = (sectionId, text) => section(sectionId, "heading", { props: { text, level: 2 } });
const text = (sectionId, role, value) => section(sectionId, "text", { props: { role, text: value } });
const refused = (sectionId, result) => section(sectionId, "notice", { props: { tone: "error", title: "Refused by the capability" },
  bindings: { body: run(result, "/reason/code") }, when: when(result, "/status", "REFUSED") });
const animals = [
  { value: "animal-001", label: "No. 001 Demo Heron" },
  { value: "animal-002", label: "No. 002 Demo Fox" },
  { value: "animal-003", label: "No. 003 Demo Beetle" }
];
const navigation = { items: [
  { label: "Overview", href: "/circuit/wildlife" }, { label: "Collection", href: "/circuit/wildlife-collection" },
  { label: "Animal", href: "/circuit/wildlife-animal" }, { label: "Capture", href: "/circuit/wildlife-capture" },
  { label: "My animals", href: "/circuit/wildlife-mine" }, { label: "Team", href: "/circuit/wildlife-team" },
  { label: "Home", href: "/circuit/wildlife-home" }, { label: "Refusals", href: "/circuit/wildlife-refusals" }
] };
const page = (slug, title, sections, extraSources = [], revision = 1) => ({ document: "ui-page-definition.v1", pageId: `ui-page-${slug}`, namespaceId: "sidefx:ui",
  path: `/circuit/${slug}`, revision, title, layoutRef: LAYOUT, navigation, sources: [{ sourceId: "session", reader: "session" }, ...extraSources], sections });
const pages = [];
const add = (slug, title, build, extraSources, revision) => { order = 0; pages.push(page(slug, title, build(), extraSources, revision)); };

// ---------- the pages ----------
add("wildlife", "Wildlife Collection", () => [
  hero("nerdery-record-animal-encounter", "Wildlife Collection, citizen slice",
    "Collect the wildlife around you",
    "Browse the catalog, photograph what you find and build a team. Each screen runs a declared capability as you, and shows that capability's own answer."),
  section("signed-in", "stat", { props: { label: "Signed in as" }, bindings: { value: { kind: "read", reader: "session", pointer: "/principalId" },
    sub: { kind: "read", reader: "session", pointer: "/expiresAt" } } }),
  section("journey", "card-list", { props: { title: "The journey", cards: [
    { cardId: "before", title: "1. Before you collect", body: "Browse and search the catalog. An animal you have not collected shows only its common name, number, range and picture.", promise: "Locked fields never leave the server.", meta: "Collection", link: "/circuit/wildlife-collection", linkLabel: "Open" },
    { cardId: "capture", title: "2. Capture an encounter", body: "Upload a photo and record where you saw the animal, with an optional nickname.", promise: "Photo verification is deferred and recorded as not performed.", meta: "Capture", link: "/circuit/wildlife-capture", linkLabel: "Open" },
    { cardId: "after", title: "3. After you collect", body: "The animal's scientific name, types, stats and attributes unlock, for you alone. A second encounter is a second individual.", promise: "Unlocks are per user.", meta: "Animal", link: "/circuit/wildlife-animal", linkLabel: "Open" },
    { cardId: "team", title: "4. Build your team", body: "Choose up to six of your individuals and see them on your home page.", promise: "A seventh member is refused and the saved team stays as it was.", meta: "Team", link: "/circuit/wildlife-team", linkLabel: "Open" },
    { cardId: "refusals", title: "5. What the system refuses", body: "A citizen adding to the catalog, and a session presented under someone else's identity.", promise: "Each refusal is named by the capability.", meta: "Refusals", link: "/circuit/wildlife-refusals", linkLabel: "Open" }
  ] } }),
  section("capabilities", "card-list", { props: { title: "The declared capabilities behind these screens", catalogSourceId: "catalog", cards: [
    ["nerdery-browse-animal-collection", "Browse the collection", "Search the catalog in collection-number order, with what each user has unlocked."],
    ["nerdery-view-animal-definition", "View an animal", "Read one animal with only the information this user has unlocked."],
    ["nerdery-upload-encounter-photo", "Upload a photo", "Keep the photo's exact bytes under their digest for later verification."],
    ["nerdery-record-animal-encounter", "Record an encounter", "Record one individual per request; a retry replays without a second write."],
    ["nerdery-view-collected-animals", "My animals", "List this user's individuals with their photos and nicknames."],
    ["nerdery-set-animal-team", "Set the team", "Save up to six of this user's individuals against the revision the user saw."],
    ["nerdery-view-wildlife-home", "Home", "Show this user's saved team."],
    ["nerdery-add-animal-definition", "Add to the catalog", "Biologists add animal definitions; citizens are refused."]
  ].map(([id, title, body]) => ({ cardId: id, capabilityId: id, namespaceId: NS, title, body, meta: `${NS}/${id}`,
    link: `/circuit/explorer?capability=${id}&namespace=${encodeURIComponent(NS)}`, linkLabel: "Open circuit" })) } }),
  text("data-note", "note", "Synthetic catalog and people from the challenge fixtures. Identity, photos and encounters are stored by the slice's own mechanics in the wildlife store.")
], [{ sourceId: "catalog", reader: "catalog" }]);

add("wildlife-collection", "Animal collection", () => [
  hero("nerdery-browse-animal-collection", "Before and after you collect", "Animal collection",
    "Search by name or collection number. An animal you have not collected shows only its common name, number, range and picture; its other fields stay on the server until you collect it."),
  section("search", "form", { props: { fields: [{ name: "search", label: "Search by name or number (leave empty for every animal)", kind: "search" }], submit: "Show the collection" },
    actions: [observe("browse", "nerdery-browse-animal-collection", { search: { form: "search", optional: true } }, "browse")],
    events: [{ on: "submit", actionId: "browse" }] }),
  section("browse-total", "stat", { props: { label: "Animals listed" }, bindings: { value: run("browse", "/total"), sub: run("browse", "/search") },
    when: when("browse", "/status", "LISTED") }),
  section("browse-rows", "table", { when: when("browse", "/status", "LISTED"),
    props: { columns: [{ key: "number", label: "No." }, { key: "name", label: "Animal" }, { key: "range", label: "Range" }, { key: "state", label: "Your collection" },
      { key: "scientific", label: "Scientific name" }, { key: "types", label: "Types" }, { key: "strength", label: "Strength" }, { key: "size", label: "Size" },
      { key: "speed", label: "Speed" }], empty: "No animal matches this search." },
    bindings: { rows: run("browse", "/items", { number: "/animal/collectionNumber", name: "/animal/commonName", range: { pointer: "/animal/range", join: ", " },
      state: { label: "/collectionState", state: "/collectionState" }, scientific: "/animal/scientificName", types: { pointer: "/animal/types", join: ", " },
      strength: "/animal/stats/Strength", size: "/animal/stats/Size", speed: "/animal/stats/Speed" }) } }),
  refused("browse-refused", "browse"),
  text("disclosure-note", "note", "A dash is a field the capability did not return for you. Collecting the animal is what unlocks it.")
]);

add("wildlife-animal", "Animal detail", () => [
  hero("nerdery-view-animal-definition", "Direct detail read", "One animal, as you are allowed to see it",
    "The detail read applies the same rule as the catalog. Ask for an animal you have not collected and the restricted fields are simply not there."),
  section("pick", "form", { props: { fields: [{ name: "definitionId", label: "Animal", kind: "select", options: animals, value: "animal-001" }], submit: "Show the animal" },
    actions: [observe("view", "nerdery-view-animal-definition", { definitionId: { form: "definitionId" } }, "detail")],
    events: [{ on: "submit", actionId: "view" }] }),
  section("locked", "notice", { props: { tone: "warning", title: "Locked until you collect it",
    body: "Record an encounter with this animal to unlock its scientific name, types, stats and attributes.", actionId: "go-capture" },
    actions: [{ actionId: "go-capture", kind: "navigate", to: "/circuit/wildlife-capture" }],
    when: when("detail", "/collectionState", "UNCOLLECTED") }),
  section("unlocked", "notice", { props: { tone: "info", title: "Collected: everything is unlocked for you" }, when: when("detail", "/collectionState", "COLLECTED") }),
  section("detail-fields", "field-list", { props: { label: "What the capability returned" }, when: when("detail", "/status", "VISIBLE"),
    bindings: { fields: run("detail", "", { "Animal": "/animal/commonName", "Collection number": "/animal/collectionNumber", "Range": { pointer: "/animal/range", join: ", " },
      "Your collection": "/collectionState", "Scientific name": "/animal/scientificName", "Types": { pointer: "/animal/types", join: ", " },
      "Strength": "/animal/stats/Strength", "Size": "/animal/stats/Size", "Speed": "/animal/stats/Speed" }) } }),
  section("detail-attributes", "table", { when: when("detail", "/collectionState", "COLLECTED"),
    props: { caption: "Attributes", columns: [{ key: "name", label: "Attribute" }, { key: "values", label: "Value" }, { key: "description", label: "About" }] },
    bindings: { rows: run("detail", "/animal/attributeDetails", { name: "/name", values: { pointer: "/selectedValues", field: "label", join: ", " }, description: "/description" }) } }),
  refused("detail-refused", "detail")
]);

add("wildlife-capture", "Capture an encounter", () => [
  hero("nerdery-record-animal-encounter", "Capture", "Photograph it, then record it",
    "Upload the photo first: the slice keeps its exact bytes under their digest. Then record the encounter with that photo. Recording collects the animal for you."),
  heading("upload-heading", "1. Upload a photo"),
  section("upload", "form", { props: { fields: [{ name: "photo", label: "Photo", kind: "file", accept: "image/*", required: true, hint: "Keep it small for the demo (under 8 MB)" }], submit: "Upload photo" },
    actions: [observe("upload", "nerdery-upload-encounter-photo",
      { fileName: { form: "photo", as: "file-name" }, mediaType: { form: "photo", as: "media-type" }, contentBase64: { form: "photo", as: "base64" } }, "upload")],
    events: [{ on: "submit", actionId: "upload" }] }),
  section("upload-result", "field-list", { props: { label: "Retained photo" }, when: when("upload", "/status", "UPLOADED"),
    bindings: { fields: run("upload", "/photo", { "Photo reference": "/photoRef", "Bytes": "/byteLength", "Content digest": "/contentSha256", "Durable": "/durable",
      "Verified now": "/verificationPerformed" }) } }),
  refused("upload-refused", "upload"),
  heading("record-heading", "2. Record the encounter"),
  section("record", "form", {
    props: { fields: [
      { name: "encounterId", label: "Encounter id (one per individual; the same id and content again replays)", value: "enc-interview-1" },
      { name: "definitionId", label: "Animal", kind: "select", options: animals, value: "animal-001" },
      { name: "place", label: "Where you saw it", value: "Synthetic park, north path" },
      { name: "nickname", label: "Nickname (optional)", value: "Reed" },
      { name: "photoRef", label: "Photo reference (filled in from the upload above)", required: true }
    ], submit: "Record encounter" },
    bindings: { values: run("upload", "/photo") },
    actions: [observe("record", "nerdery-record-animal-encounter", {
      encounterId: { form: "encounterId" }, definitionId: { form: "definitionId" },
      location: { source: "manual", description: { form: "place" } },
      photoRef: { form: "photoRef" }, nickname: { form: "nickname", optional: true } }, "record")],
    events: [{ on: "submit", actionId: "record" }] }),
  section("record-result", "field-list", { props: { label: "Recorded" }, when: when("record", "/status", "RECORDED"),
    bindings: { fields: run("record", "", { "Encounter": "/encounter/encounterId", "Animal": "/encounter/definitionId", "Nickname": "/encounter/nickname",
      "Where": "/encounter/location/description", "Your collection": "/collectionState", "Photo verified": "/verificationPerformed", "Replayed": "/replayed" }) } }),
  section("record-replayed", "notice", { props: { tone: "info", title: "Replayed, not written twice",
    body: "The same encounter id and content were submitted again. The capability returned the original record and wrote nothing new." },
    when: when("record", "/replayed", true) }),
  refused("record-refused", "record"),
  section("record-next", "notice", { props: { tone: "info", title: "Collected", body: "Open the animal again: its locked fields are now yours.", actionId: "go-animal" },
    actions: [{ actionId: "go-animal", kind: "navigate", to: "/circuit/wildlife-animal" }], when: when("record", "/status", "RECORDED") })
]);

// Revision 2: each card opens its individual, with the photo, on wildlife-individual.
add("wildlife-mine", "My animals", () => [
  hero("nerdery-view-collected-animals", "Personal collection", "My animals",
    "Every encounter you recorded is its own individual, shown with your photo and nickname. Two herons are two animals. Open one to see your photo."),
  section("load", "section", { props: { actions: [{ actionId: "mine", label: "Show my animals" }] },
    actions: [observe("mine", "nerdery-view-collected-animals", {}, "mine")] }),
  section("mine-total", "stat", { props: { label: "Individuals" }, bindings: { value: run("mine", "/total") }, when: when("mine", "/status", "LISTED") }),
  section("mine-cards", "card-list", { when: when("mine", "/status", "LISTED"),
    bindings: { cards: run("mine", "/items", { title: "/displayName", body: { pointer: "/nickname", default: "No nickname: shown by its species name" },
      promise: "/photoRef", meta: "/encounterId", linkLabel: "See the photo",
      link: { concat: [{ literal: "/circuit/wildlife-individual?encounter=" }, { pointer: "/encounterId", encode: "uri" }] } }) } }),
  refused("mine-refused", "mine")
], [], 2);

add("wildlife-individual", "My animal", () => [
  hero("nerdery-view-collected-animal", "One of your animals", "Your animal, with your photo",
    "The photo you uploaded, read back from the store for you alone, with what you recorded about it. Anyone else asking for this animal is told it does not exist."),
  section("show", "section", { props: { actions: [{ actionId: "view", label: "Show the photo" }] },
    actions: [observe("view", "nerdery-view-collected-animal", { encounterId: { kind: "route", name: "encounter" } }, "animal")] }),
  section("photo", "media.figure", { when: when("animal", "/status", "VISIBLE"),
    bindings: { src: run("animal", "", { concat: ["data:", "/animal/photo/mediaType", ";base64,", "/animal/photo/contentBase64"] }),
      digest: run("animal", "/animal/photo/contentSha256"), alt: run("animal", "/animal/displayName"), caption: run("animal", "/animal/commonName") } }),
  section("facts", "field-list", { props: { label: "What you recorded" }, when: when("animal", "/status", "VISIBLE"),
    bindings: { fields: run("animal", "/animal", { "Name": "/displayName", "Animal": "/commonName", "Nickname": { pointer: "/nickname", default: "None" },
      "Where": { pointer: "/location/description", default: "Recorded from the device position" }, "Encounter": "/encounterId",
      "Photo": "/photo/photoRef", "Media type": "/photo/mediaType", "Bytes": "/photo/byteLength", "Photo digest": "/photo/contentSha256" }) } }),
  refused("animal-refused", "animal"),
  section("back", "notice", { props: { tone: "info", title: "Your other animals", body: "Every individual you recorded is on My animals. Open any of them here.", actionId: "go-mine" },
    actions: [{ actionId: "go-mine", kind: "navigate", to: "/circuit/wildlife-mine" }] })
]);

add("wildlife-team", "Team", () => [
  hero("nerdery-set-animal-team", "Team selection", "Build your team of up to six",
    "Load your animals and your current team, tick up to six and save. The save names the team revision you saw, so a stale or oversized team is refused and the saved team is kept."),
  section("load", "section", { props: { heading: "Start here", actions: [{ actionId: "mine", label: "1. Load my animals" }, { actionId: "home", label: "2. Load my current team" }] },
    actions: [observe("mine", "nerdery-view-collected-animals", {}, "mine"), observe("home", "nerdery-view-wildlife-home", {}, "home")] }),
  section("current", "field-list", { props: { label: "Current team" }, when: when("home", "/status", "VISIBLE"),
    bindings: { fields: run("home", "/team", { "Revision": "/revision", "Size": "/size", "Members": { pointer: "/members", field: "displayName", join: ", " } }) } }),
  section("pick", "form", { when: when("mine", "/status", "LISTED"), props: { submit: "3. Save this team" },
    bindings: { fields: run("mine", "/items", { name: "encounterIds", kind: "checkbox", id: "/encounterId", label: "/displayName", value: "/encounterId", checked: { literal: false } }) },
    actions: [observe("save", "nerdery-set-animal-team",
      { expectedRevision: { source: "run", result: "home", pointer: "/team/revision" }, encounterIds: { form: "encounterIds", as: "list" } }, "team")],
    events: [{ on: "submit", actionId: "save" }] }),
  section("saved", "field-list", { props: { label: "Saved" }, when: when("team", "/status", "SAVED"),
    bindings: { fields: run("team", "/team", { "Revision": "/revision", "Size": "/size", "Members": { pointer: "/encounterIds", join: ", " } }) } }),
  refused("team-refused", "team"),
  heading("seven-heading", "Try a team of seven"),
  section("seven", "section", { props: { body: ["A team holds at most six animals. After loading your current team, this sends seven and shows the capability's refusal; the saved team does not change."],
    actions: [{ actionId: "seven", label: "Send a team of seven" }] },
    actions: [observe("seven", "nerdery-set-animal-team", { expectedRevision: { source: "run", result: "home", pointer: "/team/revision" },
      encounterIds: ["enc-interview-1", "enc-interview-2", "e3", "e4", "e5", "e6", "e7"] }, "seven")] }),
  refused("seven-refused", "seven")
]);

add("wildlife-home", "Home", () => [
  hero("nerdery-view-wildlife-home", "Your home page", "My team",
    "The team you saved, shown on your home page. Another user sees their own team, never yours."),
  section("load", "section", { props: { actions: [{ actionId: "home", label: "Show my home" }] },
    actions: [observe("home", "nerdery-view-wildlife-home", {}, "home")] }),
  section("size", "stat", { props: { label: "Team members" }, bindings: { value: run("home", "/team/size"), sub: run("home", "/team/revision") },
    when: when("home", "/status", "VISIBLE") }),
  section("members", "card-list", { when: when("home", "/status", "VISIBLE"),
    bindings: { cards: run("home", "/team/members", { title: "/displayName", body: "/definitionId", promise: "/photoRef", meta: "/encounterId" }) } }),
  section("empty", "notice", { props: { tone: "info", title: "No team yet", body: "Pick up to six of your animals.", actionId: "go-team" },
    actions: [{ actionId: "go-team", kind: "navigate", to: "/circuit/wildlife-team" }], when: when("home", "/team/size", 0) }),
  refused("home-refused", "home")
]);

add("wildlife-refusals", "Refusals", () => [
  hero("nerdery-add-animal-definition", "Boundaries", "What the system refuses",
    "Rules live in the capabilities, not in these screens. Each button sends a request the capability must refuse, and shows the refusal it names."),
  heading("add-heading", "A citizen adds to the catalog"),
  section("add", "section", { props: { body: ["Only biologists maintain the catalog. This sends a complete new animal as you, a citizen."],
    actions: [{ actionId: "add", label: "Add Demo Owl as a citizen" }] },
    actions: [observe("add", "nerdery-add-animal-definition", { animal: { commonName: "Demo Owl", scientificName: "Synthetic scientific label 4", avatarPhotoRef: "avatar-001",
      collectionNumber: 4, range: ["county-a"], types: ["Flying"], stats: { Strength: 5, Size: 6, Speed: 7 }, attributes: [] } }, "add")] }),
  refused("add-refused", "add"),
  section("add-added", "notice", { props: { tone: "warning", title: "Added", body: "This session belongs to a biologist, who may add animals." }, when: when("add", "/status", "ADDED") }),
  heading("forged-heading", "Someone else's identity"),
  section("forged", "section", { props: { body: ["This presents your session under another principal. The capability checks the pair against the identity store and treats the caller as anonymous."],
    actions: [{ actionId: "forged", label: "Browse as another principal" }] },
    actions: [{ actionId: "forged", kind: "observe", subject: "nerdery-browse-animal-collection", namespace: NS, result: "forged",
      input: { input: { caller: { principalId: "00000000-0000-4000-8000-000000000001", sessionId: { source: "session", pointer: "/sessionId" } }, request: { search: "" } } } }] }),
  refused("forged-refused", "forged")
]);

// ---------- validate against the shell ----------
const { validatePage } = await import(pathToFileURL(RUNTIME).href);
for (const p of pages) {
  const { ok, refusals } = validatePage(p);
  if (!ok) throw new Error(`${p.path}: ${JSON.stringify(refusals)}`);
}

// ---------- files ----------
const files = {};
for (const p of pages) files[`ui/pages/${p.path.slice("/circuit/".length)}.json`] = JSON.stringify(p, null, 1) + "\n";
const docs = pages.map((p) => ({ ...p, text: JSON.stringify(p) }));
for (const [rel, content] of Object.entries(files)) {
  if (/[^\x09\x0a\x20-\x7e]/.test(content)) throw new Error(`${rel}: non-ASCII`);
  fs.mkdirSync(path.dirname(path.join(nerdery, rel)), { recursive: true });
  fs.writeFileSync(path.join(nerdery, rel), content);
}
const manifest = { generated: "2026-11-03", runtime: RUNTIME, pages: docs.map((d) => ({ path: d.path, pageId: d.pageId, revision: d.revision, sections: d.sections.length, digest: `sha256:${sha(d.text)}` })),
  files: Object.keys(files).map((f) => ({ file: `nerdery/${f}`, sha256: `sha256:${sha(files[f])}` })) };
fs.writeFileSync(path.join(nerdery, "ui/manifest.json"), JSON.stringify(manifest, null, 1) + "\n");
console.log(JSON.stringify(manifest.pages, null, 1));
