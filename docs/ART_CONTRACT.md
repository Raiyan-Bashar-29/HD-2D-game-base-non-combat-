# The art contract

**This template ships a contract art must satisfy, never art.** Every system runs on the
procedural placeholders in `assets/placeholder/`, indefinitely, and a consuming game brings its
own. This document is what your art has to be shaped like for it to drop in without a code change.

Nothing here requires editing `src/`. If satisfying one of these seams seems to, that is a bug in
the seam.

---

## Character sprite sheets

### The grid

**Facings across, frames down, and the rows grouped into animation blocks.**

```
facings = 4, frames = 3, animations = 2, idle_row = 0, walk_row = 1

        col 0    col 1    col 2    col 3
row 0   idle.0   idle.0   idle.0   idle.0     <- animation 0 (idle), frame 0
row 1   idle.1   ...                          <- animation 0, frame 1
row 2   idle.2   ...                          <- animation 0, frame 2
row 3   walk.0   ...                          <- animation 1 (walk), frame 0
row 4   walk.1   ...
row 5   walk.2   ...
```

So the sheet is `facings` cells wide and `frames * animations` cells tall, and an animation is
addressed by **index**, not by its first row — move the walk block down and you do not recount.

`animations = 1` with both row fields at `0` is a single-cycle sheet with no separate idle. That
is legal, it is what this project shipped before the layout resource existed, and every such sheet
still works unchanged.

### The declaration

One `.tres` beside the texture:

```
[gd_resource type="Resource" script_class="SpriteSheetLayout" load_steps=2 format=3]

[ext_resource type="Script" path="res://src/content/art/sprite_sheet_layout.gd" id="1_layout"]

[resource]
script = ExtResource("1_layout")
facings = 8
frames = 4
animations = 1
cell_size = Vector2i(32, 48)
idle_row = 0
walk_row = 0
```

| Field | Means |
|---|---|
| `facings` | how many directions **the art** distinguishes. 1–32 |
| `frames` | cells down within one animation: the length of its cycle. 1–64 |
| `animations` | how many blocks are stacked down the sheet. 1–32 |
| `cell_size` | one cell in texture pixels |
| `idle_row` / `walk_row` | which block plays standing still, and which moving. Equal means no separate idle |

**The cell size is declared, not divided out of the texture.** A sheet of the wrong size is then a
named problem — `expects a (256, 192) sheet; the texture is (240, 192)` — instead of every
character in the game being silently misplaced by a few pixels.

**A facing is not a column.** `GameEnums.Facing` has eight values because eight is how many
directions the *game* reasons about; `facings` is how many the *art* distinguishes. The two are
quantised separately from the same angle, and the sector width is derived — `TAU / facings` — so
there is no second place holding the number.

### Wiring a sheet in

Two `ExtResource` paths on a `CharacterVisual` node, and nothing else:

```
[node name="Visual" type="Node3D" parent="."]
script = ExtResource("2_vis")
texture = ExtResource("3_tex")
layout = ExtResource("6_layout")
```

The layout is **per node**, not global: the player and each NPC may use different sheets with
different geometry in the same scene. Also on `CharacterVisual`, and independent of the sheet:
`pixel_size` (world scale), `walk_fps`, `reference_speed`, `ground_offset`.

**An unwired `layout` is legal and loud.** `CharacterVisual` falls back to 8×4 on a 32×48 cell and
warns, naming the node. That fallback exists so a node stays recognisable while the log says it is
unwired; nothing should rely on it.

### What the engine does with the sheet

`Sprite3D` is configured with `billboard = BILLBOARD_FIXED_Y` (upright, turns only around Y),
`alpha_cut = ALPHA_CUT_DISCARD` (so the sprite is opaque geometry that sorts by depth and casts a
real shadow), `texture_filter = NEAREST`, and `shaded = true` (so a character under a lantern is
actually lit). Those are the HD-2D look and they are not negotiable per sheet.

Practically, that means **your art needs hard alpha**, not soft edges: anything below the discard
threshold disappears rather than fading. Which is the correct trade for pixel art and the wrong
one for anything painted.

### Import settings

**You do not have to touch a `.import` file.** `project.godot` carries an `[importer_defaults]`
section, so a PNG dropped into this project imports correctly the first time:

```
[importer_defaults]

texture={
"detect_3d/compress_to": 0
}
```

Exactly one value is set, because exactly one was wrong by default. `detect_3d/compress_to=0`
disables the editor's *"this texture was used in 3D, so switch it to VRAM compression"* rewrite.
Every character sheet in an HD-2D game **is** used in 3D, through `Sprite3D`, so at the stock value
of `1` a re-import puts block artefacts through your pixel art — silently, and only in the picture.
The committed `.import` files carry `0` as well, so the hazard is closed for what is already here
and for whatever you import next. Everything else — `compress/mode=0` (lossless),
`mipmaps/generate=false`, `process/fix_alpha_border=true` — is already Godot's own default for a
2D texture and needs no help.

**This section is undocumented and does not appear in `--doctool`**, which is why the template went
five packages without one: the project rule is to check every name against the API dump, and for
this there is no dump to check. It is written on a **measurement** instead. A throwaway texture was
imported with stock defaults, the section was added, its `.import` was deleted, and
`--headless --import` regenerated it carrying the values set here — `detect_3d/compress_to` moved
`1 → 0` and a control value `mipmaps/generate` moved `false → true`. The key is the **importer's**
name (`texture`), the value is a Dictionary of param paths, and
`ProjectSettings.get_setting("importer_defaults/texture")` reads it back at runtime. A test asserts
that, and asserts every committed `.import` agrees, so an editor session that clears the section
fails the suite rather than a screenshot six months later.

### The two placeholders, and why one of them counts its own cells

- `character_placeholder.png` — 8 facings × 4 frames, 32×48 cells, one animation block. 256×192.
- `character_alt.png` — 4 facings × 3 frames in **2** blocks, 24×40 cells. 96×240. It disagrees
  with the first on every number, and exists so the "swap a sheet, change no code" claim can be
  demonstrated rather than asserted.

**Every cell of the alt sheet labels itself**, and the reason generalises to any art you make for
testing this seam. A day/night system that lights nothing is at least obviously wrong on screen; a
character drawn from the *wrong cell* still looks like a character — upright, lit, facing *some*
direction. So a capture of it cannot be judged, it has to be **read**. Each cell carries
`column + 1` bright pips down its left edge and `frame + 1` along its foot, and the two blocks wear
different body tints. Four left pips and two foot pips on an orange body is block 1, frame 1,
column 3 — index `(1*3 + 1) * 4 + 3 = 19` — and no amount of plausible pixel art fakes that number.

Regenerate both with `tools/gen_placeholders.gd`.

---

## The UI look

### One file

`assets/theme/ui_theme.tres`, wired as `gui/theme/custom` in `project.godot`. That setting is what
makes it resolve from **any** `Control` in the tree, including the HUD, which is drawn under
`UiRoot` and would be missed by handing the theme to the screen stack. No screen is ever handed a
theme.

A consuming game replaces this file, or points `gui/theme/custom` at its own. Adding a `fonts/`
entry here is how real type arrives when art stops being deferred. Nothing in `src/` changes.

### The three-way split, and why it is not the obvious design

**A `Theme` resource has no variables.** Items are stored per type with no reference between them,
so the natural-looking design — where `TitleText` carries both its `font_size` and its
`font_color` — writes the accent colour into as many variations as use it, and "one edit restyles
every screen" becomes false the moment there are two.

So:

| Part | Carries | Read by a screen as |
|---|---|---|
| Type variations (`TitleText`, `MenuRow`, `DialogueText`, …) | **only** `font_size` — the one thing that genuinely differs by role | `control.theme_type_variation = &"TitleText"` |
| `UiPalette` | the four colours, once each: `text`, `accent`, `dim`, `solid` | `get_theme_color(&"accent", &"UiPalette")` |
| `UiMetrics` | the six insets and separations: `margin`, `side_margin`, `box_margin`, `separation`, `row_separation`, `tight_separation` | `get_theme_constant(&"margin", &"UiMetrics")` |

`dim` is translucent, for a panel over a live or frozen world; `solid` is opaque, for a panel with
nothing behind it that must also cover the HUD.

A test case fails if any styled screen writes a `Color(` or an `add_theme_font_size_override` back
down into itself. The look reached five files one reasonable line at a time once already, and
nothing but a check stops it going back.

### Restyling

Edit that one file. Six lines is a complete change of look: the palette's four colours, a metric,
a title size. This was demonstrated with captures before and after — the main menu and the
inventory screen both restyled, and the HUD clock followed without being mentioned.

### The known gap: no `Button` styleboxes

**The theme sets font sizes for `MenuRow` and `ChoiceRow` but no styleboxes, so every menu row and
every dialogue reply draws Godot's default dark panel.**

Against the shipped near-black palette that is invisible. Against a **light palette it is
immediately wrong** — dark-on-light rows in an otherwise parchment UI, legible but plainly not
restyled with the rest. A consuming game that picks a light look hits this in its first capture.

The seam is right and it is in the same file — `MenuRow/styles/normal`, `hover`, `pressed`,
`focus` and the same for `ChoiceRow`, taking `StyleBoxFlat` sub-resources, no code anywhere. It is
simply unpopulated, because the template has no look to populate it with and a stylebox authored
against the placeholder palette would be a *decision* shipped as a *default*. Populate it when you
choose your look; that is one edit to `ui_theme.tres` and nothing else.

This is stated rather than hidden because it was found by a capture that was looked at, and
because a gap you are told about costs ten minutes while a gap you discover costs an afternoon of
suspecting the theme system.

---

---

## The look of an area

Three seams, and none of them is code. All three were opened by T3.2, and each was demonstrated
with a before/after windowed capture in which **one edit to one file** was the only difference.

### Shared materials

`assets/materials/` holds `StandardMaterial3D` resources that more than one area points at:

```
[node name="Mesh" type="MeshInstance3D" parent="Terrain/Dais"]
mesh = SubResource("mesh_pillar")
surface_material_override/0 = ExtResource("6_wood")
```

…where `6_wood` is `[ext_resource type="Material" path="res://assets/materials/wood.tres" …]`.
Edit that one file and every area using it changes. Drop your own `.tres` in that folder, or
replace the texture the shipped one names.

**Share a material when two areas genuinely want the same thing, and not before.** The template
ships exactly one, and the other five materials in the two demo areas are deliberately still
inline, because they are *not* duplicates: one area tiles stone at `uv1_scale (3, 3)` and the other
floors it at `(8, 8)` and walls it at `(6, 2)`. A tiling rate is a property of the surface it is
stretched over, not of the substance, so hoisting those would produce a shared file with a
per-area override on every user — the duplication with an extra indirection.

A test fails if **two areas declare the same material inline**, with `ExtResource` ids resolved to
paths so the comparison actually works. That is the defect this seam was built for: the two demo
areas each carried a byte-identical copy, invisible until someone read both files side by side.

Nothing in `src/` knows `assets/materials/` exists. A shared material is a scene-authoring
convention, not a system — no registry, no id, no directory scan.

**One thing that makes sharing safe**, and it was already true: `SurfaceWetness` *duplicates* every
material before it darkens it, so rain outdoors cannot leave an interior's floor wet on the far
side of an area change.

### The environment post stack

Every value in the HD-2D post stack — tonemap exposure, the seven glow numbers, depth fog,
volumetric fog, and the four expensive effects that are off — is an `@export` on the
`EnvironmentDriver` node in each area scene:

```
[node name="EnvironmentDriver" type="Node" parent="Environment"]
script = ExtResource("2_env")
follow_clock = true
volumetric_fog_density = 0.06
```

The defaults are exactly what the template shipped when these were literals, so an area that
leaves them alone renders identically. Per **area** rather than per project, because the driver
already lives in the area scene and its `Interior` group already varies that way: a game that
wants one look everywhere authors its areas from one copy, and a game that wants a bright market
and a smoky cellar has the seam without having asked for it.

What stays in code is the *structure* — which tonemapper, which fog mode, that ambient light comes
from a colour — because those are what the rest of the driver assumes rather than what an area
tunes. A test fails if a **number** is assigned to the environment anywhere in that file again.

The day/night keyframe table is a separate thing and is still a `const` in the driver. It is a
curve, not a look setting, and no seam has been claimed for it.

### Per-area camera framing

`HD2DCameraRig` has carried its framing as `@export`s since it was written; what was missing was
an area using them. Set them on the rig node in your area scene:

```
[node name="CameraRig" type="Node3D" parent="Camera"]
script = ExtResource("3_cam")
distance = 9.5
fov = 36.0
height_offset = 0.95
```

`distance`, `pitch_degrees`, `yaw_degrees`, `fov`, `height_offset`, `follow_lag`, `frame_bias`, and
the depth-of-field group. **A long lens from far away is most of the HD-2D look** — 25–30 degrees
at 12–16 metres — so treat the defaults as the house style and reframe where a space asks for it.
The demo's interior does: 36 degrees at 9.5 metres, because a room reads better close. Depth of
field is expressed *relative* to the target, so it follows a reframe without being retuned.

A test fails if a number is assigned to the camera or its attributes in the rig, and fails if **no
area authors its own framing** — a seam nothing uses is a seam nobody has tried.

---

## What is deliberately not here

**No Git LFS, and this one is a refusal rather than an omission.** `.gitattributes` keeps the
`filter=lfs` line commented, and it should stay commented until you bring real art. Three reasons,
and the third is the one that decides it: LFS pointers for a 2 KB procedural placeholder are pure
overhead; enabling them puts the CI checkout on a dependency it does not currently declare
(`actions/checkout` needs `lfs: true`, and without it every PNG arrives as a text pointer and the
project fails to import); and **the template cannot verify the change it would be making** —
proving LFS works needs an LFS-enabled remote and a CI run against real binaries, neither of which
exists while art is deferred. A configuration nobody can test is exactly the change that looks
applied and does nothing, which is the failure this project is built to prevent. When you bring
art: uncomment the line, run `git lfs install`, and add `lfs: true` to the checkout step in
`.github/workflows/ladder.yml`.

**No audio assets.** The ambience bed runs on procedurally generated filtered noise, for the same
reason art is deferred.

## Read next

[`AUTHORING.md`](AUTHORING.md) · [`TESTING.md`](TESTING.md) · [`TEMPLATE.md`](TEMPLATE.md) ·
`src/content/art/sprite_sheet_layout.gd` and `assets/theme/ui_theme.tres` — both headers are
written to be read by a consuming game, and go further than this document does.
