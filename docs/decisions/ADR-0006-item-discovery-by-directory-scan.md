# ADR-0006 — Items are discovered by scanning a directory, not from a list

**Status:** Accepted, 2026-08-25

## Context

`docs/ARCHITECTURE.md` claims *"adding the fiftieth item must not touch a single line of code"*.
Until this change the project had zero `Resource` classes, so the claim had never been
exercised — the audit called it not merely untested but unrunnable. Items are the first content
type, so they decide what the claim actually means.

Something has to turn an item id into an `ItemDefinition`. Four options:

| Option | Fiftieth item touches code? | Failure mode |
|---|---|---|
| Hand-maintained registry resource | **Yes**, one edit per item | Rot, guaranteed |
| Generated manifest | Almost — you must remember to run a tool | **Silent.** A forgotten regeneration is indistinguishable from an item never added |
| `DirAccess.get_files_at()` | No | **Silent in an exported build.** Text resources are converted and reached through a remap, so matching on the extension finds nothing |
| `ResourceLoader.list_directory()` | No | Undocumented in 4.7.2 — semantics must be proven, not assumed |

## Decision

`ItemDb` scans `res://data/items` with `ResourceLoader.list_directory()`, falls back to
`DirAccess.get_files_at()` if that returns nothing, and normalises both possible return shapes
(bare filename or full path) plus the `.tres`, `.res`, `.remap` and `.import` suffixes.
Definitions are cached by id. **A definition's `id` must equal `item/` plus its filename**; a
mismatch is refused and reported with both values.

`ItemDb` is a static `class_name`, not an autoload.

## Why

- **A scan is the only option where dropping a `.tres` in a folder is the whole act.** A
  manifest is one forgotten command away from an item that does not exist, and silent-wrong is
  the failure mode this project exists to prevent.
- **`list_directory` is the resource-aware one** — it understands the indirection an exported
  pack uses, which a raw directory listing does not. Its doc description is empty in 4.7.2, so
  its behaviour is treated as unproven: `tools/check_content.gd` prints what it actually
  returned on every run, and a test cross-checks the count against an independent `DirAccess`
  listing, so a change fails a gate instead of silently shrinking the catalogue.
- **Static, not an autoload:** it holds no mutable state, has no lifecycle, is never saved and
  needs no init order, so an autoload would need an ADR and buy nothing. Decisively, an autoload
  **cannot** be used by `tools/check_content.gd`, because autoload identifiers do not resolve
  under `--headless --script` — the validator would have to duplicate the loading code it exists
  to test. This is also why no content class may touch an autoload: the moment one does, the
  validator stops compiling and the gate fails. That is mechanical enforcement of the content
  layer rule, which no other layer here has.
- **id equals filename** turns a copy-paste slip into a named startup failure rather than a
  duplicate that silently shadows another item.

## The honest limit

**There is no export preset yet, so the exported-build half of this is unproven.** Verified in
the editor and headless only. Two consequences, written down rather than assumed:

1. The export preset must export **all resources in the project**. A "selected scenes and
   dependencies" preset would strip these `.tres` files entirely, because nothing references
   most of them — they are found by scanning.
2. If a real export ever comes back with an empty catalogue, the remedy is a generated manifest,
   and `ItemDb.resource_paths()` is the single function that changes.

`ARCHITECTURE.md` therefore records the claim as *verified in editor and headless*, not as met.

## Revisit if

An export ships an empty catalogue, or item counts grow enough that a boot-time scan measures.
