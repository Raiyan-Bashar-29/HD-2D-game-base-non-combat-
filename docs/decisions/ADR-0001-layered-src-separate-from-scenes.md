# ADR-0001 — Code lives in `src/`, separate from `scenes/`

**Status:** Accepted, 2026-08-23

## Context
Godot convention is to keep a script next to the scene that uses it. That is ergonomic: one
folder per feature, everything to hand. The alternative is a layered code tree separate from
the scene tree.

## Decision
Code goes in `src/`, in five layers: `core`, `systems`, `gameplay`, `content`, `ui`. Scenes go
in `scenes/`.

## Why
The dependency rule — layers may only depend downward — becomes checkable by **path**. A tool
can read an import and know whether it crosses a layer illegally. With colocated scripts,
"core must not depend on gameplay" is a sentence in a document that nothing can verify, which
is precisely the class of rule that failed in the previous project.

## Costs, accepted
Jumping between a scene and its script means crossing folders. Scene files reference scripts
by `res://src/...` path, which is slightly more verbose.

## Revisit if
A layer-violation checker turns out to be unbuildable, which would remove the only reason for
the split.
