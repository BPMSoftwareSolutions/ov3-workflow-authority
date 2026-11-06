# Markdown page cultivation

## Hosted flight

OV3 flew revision 3 and closed the creation obligation. The public capability, its private Python operation and its publication verifier were admitted. Default discovery selected `render-markdown-html-page` for both the Python report and the harbor log.

The flight ended `DEVIATED` after 21 of 25 steps passed. The report's first call encountered a missing execution overlay. A fresh harbor-log pursuit and a direct private-operation control reached the installed binding and returned `PROVIDER_LANGUAGE_UNAVAILABLE`. The estate declares the operation for Python. The hosted worker that received it runs C#. Both objectives returned `NOT_FULFILLED`, and the content store contained zero matching publications for either expected digest.

Hosted acceptance requires dispatching the Python-only operation to a Python resolver and repeating both default objectives. The [executed flight report](flight-report.md) and [hosted receipts](../../outputs/markdown-page-flight-evidence.json) identify the approved plan, execution, provider pins, objective turns and worker configuration.

The [feature](render-markdown-html-page.feature) defines a reusable page publication with an inline or content-addressed Markdown source, title, language, filename and approved presentation profile. Its [DSL](render-markdown-html-page.dsl) binds the source reader, Python operation, content writer and publication readback. Callers receive compact receipts. The full HTML stays in the content store.

## Execution boundary

The [Python provider entry](native-profile.mjs) declares the target language, importable module, export, operation program and return encoding. It selects the executing interpreter through `sys.executable`. The fixed entry verifies the SHA-256 of its entire package before loading the pinned wheels in a private temporary directory. Requests cannot select imports, extensions, executable paths, network locations, styles or sanitizer policy. The package is retained as an inert content artifact until the profile is admitted. Its [identity](provider-identity.json) binds the [wheel pins](provider-lock.json) and [presentation profile](presentation.json).

The provider also has a C# entry, so a run that starts on the hosted C# worker stays there. Its program starts `/usr/local/bin/python3` through coreutils `timeout`, which ends the child after 100 s, with an empty environment and `-I -S -B`. Both entries run the fixed [launcher](provider-launcher.py) around the same package entry.

The launcher ends the entry at 80 s and always answers one JSON object. It answers `PROVIDER_DEADLINE_EXCEEDED` for an entry that overruns, `PROVIDER_EXITED_<code>` with the last 300 bytes of stderr for one that fails, and `PROVIDER_OUTPUT_INVALID` for output that is not a JSON object with a status. Otherwise it passes the entry's answer through unchanged.

The launcher was rehearsed with the C# program's exact arguments, under coreutils `timeout` with an empty environment, against a tampered bundle (`PACKAGE_CLOSURE_MISMATCH`), an entry that exits 3, output that is not JSON, a 6 MB answer passed through byte for byte, and a hung entry ended at 80.1 s. The package entry itself is unchanged, and it passed rehearsal earlier on CPython 3.12.16 from the deployed image. [Revision 4](build-flight-r4.mjs) declares and binds the C# entry, then proves it on `sfx-api-test`. It checks that the private operation and the page are eligible for C# and that a tampered package is refused there, then fulfills both objectives through default discovery.

The [renderer](page_provider.py) handles Markdown, sanitization, navigation, metadata escaping and static HTML assembly. Its technical-document dialect preserves Python double-underscore identifiers and recognizes lists after bold section labels. Code spans and fenced code keep their original meaning. The report includes one title, 297 current and 24 removed module entries. The unrelated harbor log exercises tables, Unicode and hostile HTML.

## Verification

The declared writer retains the normalized request, then the HTML under a kind bound to that request digest. A second invocation reloads both from the content store, checks their hashes, parses the DOM and compares the article against a fresh conversion of the source. The [page proof](../objective-verification/profiles/markdown-page-proof.sql) binds those results to the actual objective, publication turn, source and output. Its typed obligations cover the source, selected renderer and standalone page. The existing Jev scope decision determines the outer outcome after the deterministic gates pass.

The [acceptance pins](acceptance.json) identify the two input and output byte sequences. The [stdlib acceptance checker](check-outputs.py) compares their heading text, fenced code and links directly against the original Markdown. Run it with the directory that contains the two HTML files. The [report preview](../../outputs/markdown-page-preflight/python-library-provider-report.html) and [harbor log preview](../../outputs/markdown-page-preflight/harbor-log.html) were produced during the isolated native Python rehearsal. The hosted acceptance requires separate OV3 receipts.
