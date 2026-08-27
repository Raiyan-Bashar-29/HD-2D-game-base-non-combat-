# Authoring content on this template

**Task-first.** Every section starts from something you want to add and ends with a command that
tells you whether you got it right. If you are looking for how a *system* works, read the file
header — this document is the other direction.

Read [`TEMPLATE.md`](TEMPLATE.md) once before this: it says which parts of the tree are yours
(`data/**`, `scenes/areas/**`, half of `localization/strings.csv`) and which are the engine's.
[`NEW_GAME.md`](NEW_GAME.md) is what to delete before you start. This is what to write afterwards.

**What you never do:** edit anything under `src/`. If a task below seems to need it, that is a
missing seam and it is worth reporting as one. Which classes you *may* extend, and which are the
engine's own business, is [`ARCHITECTURE.md` § The extension surface](ARCHITECTURE.md#the-extension-surface).

---

## Before anything

```bash
G=/c/Rai/softwares/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe
"$G" --headless --import
```

**On a fresh clone this comes first, always.** `class_name` globals (`GameEnums`, `DictRead`,
`AreaRoot`) live in the gitignored `.godot/` cache. Without the import every script referencing
one fails to parse, the autoloads never load, and the tools look broken rather than un-imported.

Run it again after editing `localization/strings.csv` — the `.translation` file is generated.

## Six rules that catch most of it

1. **No player-facing text in a file you author.** Every visible string is a localization key
   with a row in `localization/strings.csv`. A property whose name ends in `_key` holds a key,
   never a sentence.
2. **A CSV value containing a comma must be quoted.** Unquoted, the parser truncates the value at
   the comma and `tr()` still returns a plausible-looking string. This shipped a half-sentence for
   three packages. `check_content` fails any row that parses to more than two columns.
3. **A content id equals its file name.** `data/items/rose_key.tres` declares
   `id = &"item/rose_key"`; `data/dialogue/gardener.tres` declares `id = &"talk/gardener"`;
   `scenes/areas/courtyard/courtyard.tscn` declares `area_id = &"courtyard"`. The registries
   refuse a mismatch by name, so a copy-paste slip is loud.
4. **An `object_id` is unique and permanent.** It is the key an object's state is saved under.
   Renaming one orphans every existing save's memory of it.
5. **A hand-authored `.tscn` that overrides a node *inside* an instanced scene needs
   `[editable path="<the instance>"]`** at the foot of the file. See § The editable trap.
6. **Nothing is authored until the engine has run it.** The gates at the bottom of this document
   are the answer, not a reading of your own file.

---

## Add an area

An area is one folder and one scene: `scenes/areas/<id>/<id>.tscn`, with the folder name, the file
name and the `area_id` all equal. `Director` resolves an id to a path with that template and
nothing else, which is why there is no registration step and no list to add yourself to.

### The ten required children

`AreaRoot`'s contract, asserted in `tests/unit/transitions_test.gd` for **every** area a game has
authored. All ten must exist, spelled exactly like this, even when empty:

| Child | Type | Holds |
|---|---|---|
| `Environment` | `Node3D` | `WorldEnvironment`, `Sun`, an `EnvironmentDriver`, a `WeatherVisuals` |
| `Terrain` | `Node3D`, in group `navmesh_source` | ground and walls: `StaticBody3D` with mesh and collision |
| `Props` | `Node3D` | scenery nothing can interact with — lights, decoration |
| `Interactables` | `Node3D` | every instanced object the player can act on |
| `Actors` | `Node3D` | NPCs |
| `Spawns` | `Node3D` | one `Marker3D` per arrival point; **at least one is required** |
| `Triggers` | `Node3D` | `TriggerVolume` instances |
| `Camera` | `Node3D` | the camera rig and its `Camera3D` |
| `Navigation` | `Node3D` | a `NavigationRegion3D` **named `Region`**, carrying a `NavigationMesh` |
| `Waypoints` | `Node3D` | one `Marker3D` per named place an NPC can be sent to |

Two names are load-bearing beyond the list: `Navigation/Region` is the exact path `AreaRoot`
bakes, and a spawn marker's **node name** is the `target_spawn` a door asks for. A spawn called
`default` is what `[game] world/first_spawn` looks for on a new game.

### The root's own fields

```
[node name="MyArea" type="Node3D"]
script = ExtResource("1_area")
area_id = &"my_area"                        ; must equal the folder and file name
display_name_key = "area.my_area.name"      ; a CSV row, not a name
sheltered = true                            ; an interior: weather runs but is not seen or felt
flag_prefix = "area/my_area"                ; namespace for this area's flags
```

Also available: `allowed_weather`, `force_weather_on_entry` / `forced_weather`, `music`,
`ambience`. Leaving `allowed_weather` empty means anything may occur.

### The navmesh, and the one number that will strand an NPC

The mesh is **baked at load from the geometry that is actually there**, never committed — a
checked-in navmesh goes stale the moment a wall moves, and a stale navmesh fails silently.
Two settings are not optional:

```
[sub_resource type="NavigationMesh" id="navmesh"]
agent_radius = 0.4
agent_height = 1.7
agent_max_climb = 0.2
cell_size = 0.2
cell_height = 0.1
geometry_parsed_geometry_type = 1
geometry_source_geometry_mode = 1                   ; GROUPS_WITH_CHILDREN
geometry_source_group_name = &"navmesh_source"
filter_walkable_low_height_spans = true
```

- **`geometry_source_geometry_mode = 1`** with the group name. Godot's default parses the
  children of the `NavigationRegion3D`, which in this layout has none — the terrain is a sibling.
  A bake that finds nothing takes 0ms and reports success, and then every NPC concludes it has
  already arrived, everywhere. Put `groups=["navmesh_source"]` on your `Terrain` node.
- **Keep `agent_max_climb` below any step your geometry has.** The bake will happily bridge a
  knee-high riser; `CharacterBody3D.move_and_slide()` has **no step-up at all**, so the body walks
  into it and stops while the agent insists it has not arrived. Vertical movement in this template
  is authored — a `ClimbPoint` — not jumped.

The log tells you which happened, on a run that actually enters the area:

```
[INFO] [area] Navmesh for 'my_area' baked: 2 polygons in 5ms
[ERROR] [area] Navmesh for 'my_area' baked EMPTY; nothing can path here
```

**Any non-zero count is a success** — a single flat floor is two triangles. Zero is the failure,
and it is the one the log had to be taught to report, because an empty bake also takes no time.

### An interior does not follow the sun

Set `sheltered = true` on the root **and** `follow_clock = false` on the `EnvironmentDriver`, and
then author that area's own ambient light — an interior with `follow_clock = false` and no light
of its own is pitch black. `transitions_test.gd` asserts the two agree, because a stray edit that
flips one and not the other only shows up in a capture at midnight.

### A complete minimal area

Written out in full, because ten children plus a working navmesh is more than a snippet:

```
[gd_scene load_steps=9 format=3]

[ext_resource type="Script" path="res://src/gameplay/world/area_root.gd" id="1_area"]
[ext_resource type="Script" path="res://src/gameplay/world/environment_driver.gd" id="2_env"]
[ext_resource type="Script" path="res://src/gameplay/world/weather_visuals.gd" id="3_weather"]
[ext_resource type="Script" path="res://src/gameplay/camera/hd2d_camera_rig.gd" id="4_cam"]
[ext_resource type="Texture2D" path="res://assets/placeholder/stone.png" id="5_stone"]

[sub_resource type="StandardMaterial3D" id="m_floor"]
albedo_texture = ExtResource("5_stone")
texture_filter = 0
uv1_scale = Vector3(8, 8, 1)

[sub_resource type="BoxMesh" id="mesh_floor"]
size = Vector3(20, 1, 20)

[sub_resource type="BoxShape3D" id="shape_floor"]
size = Vector3(20, 1, 20)

[sub_resource type="NavigationMesh" id="navmesh"]
agent_radius = 0.4
agent_height = 1.7
agent_max_climb = 0.2
cell_size = 0.2
cell_height = 0.1
geometry_parsed_geometry_type = 1
geometry_source_geometry_mode = 1
geometry_source_group_name = &"navmesh_source"
filter_walkable_low_height_spans = true

[node name="MyArea" type="Node3D"]
script = ExtResource("1_area")
area_id = &"my_area"
display_name_key = "area.my_area.name"

[node name="Environment" type="Node3D" parent="."]

[node name="WorldEnvironment" type="WorldEnvironment" parent="Environment"]

[node name="Sun" type="DirectionalLight3D" parent="Environment"]
transform = Transform3D(1, 0, 0, 0, 0.34, 0.94, 0, -0.94, 0.34, 0, 9, 0)
shadow_enabled = true

[node name="EnvironmentDriver" type="Node" parent="Environment" node_paths=PackedStringArray("world_environment", "sun")]
script = ExtResource("2_env")
world_environment = NodePath("../WorldEnvironment")
sun = NodePath("../Sun")

[node name="WeatherVisuals" type="Node3D" parent="Environment"]
script = ExtResource("3_weather")

[node name="Terrain" type="Node3D" parent="." groups=["navmesh_source"]]

[node name="Floor" type="StaticBody3D" parent="Terrain"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, -0.5, 0)
collision_layer = 1
collision_mask = 0

[node name="Mesh" type="MeshInstance3D" parent="Terrain/Floor"]
mesh = SubResource("mesh_floor")
surface_material_override/0 = SubResource("m_floor")

[node name="Shape" type="CollisionShape3D" parent="Terrain/Floor"]
shape = SubResource("shape_floor")

[node name="Props" type="Node3D" parent="."]

[node name="Interactables" type="Node3D" parent="."]

[node name="Actors" type="Node3D" parent="."]

[node name="Spawns" type="Node3D" parent="."]

[node name="default" type="Marker3D" parent="Spawns"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.1, 4)

[node name="Triggers" type="Node3D" parent="."]

[node name="Camera" type="Node3D" parent="."]

[node name="CameraRig" type="Node3D" parent="Camera"]
script = ExtResource("4_cam")

[node name="Camera3D" type="Camera3D" parent="Camera/CameraRig"]

[node name="Navigation" type="Node3D" parent="."]

[node name="Region" type="NavigationRegion3D" parent="Navigation"]
navigation_mesh = SubResource("navmesh")

[node name="Waypoints" type="Node3D" parent="."]
```

Add `area.my_area.name,My Area` to `localization/strings.csv`, then:

```bash
"$G" --headless --import
"$G" --headless --script tools/check_content.gd
"$G" --headless res://tests/test_runner.tscn --quit-after 400
```

Every area adds **20 assertions** to `transitions_test.gd`, computed from the areas found — the
plan is `PER_AREA_ASSERTIONS * areas + fixed`, so authoring an area does not mean editing a plan.

None of those three enters your area. To actually see it, and you must:

```bash
"$G" --resolution 960x540 --quit-after 90 -- --new-game --goto=my_area \
     --shot="$(pwd)/build/shots/my_area.png" --shot-frame=70 --time=12:00 --freeze-time
```

Then **look at the PNG.** See § Nothing above ever enters your area.

### Reaching it

An area nothing travels to is dead content. Two ways in:

- **Make it the start:** `[game] world/first_area="my_area"` in `project.godot`.
- **Put a door in another area:** an `area_door.tscn` instance whose `target_area` is your id and
  whose `target_spawn` names a `Marker3D` under your `Spawns`. Doors are one-directional; author
  the return door too, and give each area a spawn named for where it is arrived from.

---

## Add an interactable object

Everything the player can act on is an **instance of a prefab from `scenes/objects/`**, placed
under an area's `Interactables` (or `Triggers`, for a volume). You write no code for any of these.

| Prefab | Class | The fields that matter |
|---|---|---|
| `sign.tscn` | `Readable` | `text_key`, `display_seconds` |
| `lever.tscn` | `Lever` | `world_flag`, `notify_on_key`, `notify_off_key` |
| `gate.tscn` | `Gate` | `requires_flag` **or** `requires_item`, `locked_key`, `opened_key`, `stays_open`, `blocker` |
| `pickup.tscn` | `Pickup` | `item` (an `ExtResource` pointing at an `ItemDefinition`), `count` |
| `chest.tscn` | `ItemContainer` | `contents` — `Array[ItemDefinition]([...])`, repeat an entry for a second copy |
| `rest_point.tscn` | `RestPoint` | `target_hour`, `night_only`, `rested_key` |
| `climb_point.tscn` | `ClimbPoint` | `bottom_point`, `top_point` (`Marker3D`s), `requires_flag` |
| `area_door.tscn` | `AreaDoor` | `target_area`, `target_spawn` |
| `trigger_volume.tscn` | `TriggerVolume` | `world_flag`, `notify_key`, `fires_once`, `notify_seconds` |
| `path_action.tscn` | `PathActionPoint` | `action` (a `PathAction` resource), `standing_id` |
| `speaker.tscn` | `Speaker` | `conversation_id` |

Every one of them also takes the `Interactable` fields: `object_id`, `label_key`, `verb`,
`interact_priority`, `available`, `one_shot`, `hold_seconds`.

```
[node name="GardenNotice" parent="Interactables" instance=ExtResource("7_sign")]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 2, 0.9, -3)
object_id = &"garden_notice"
label_key = "object.sign.garden.label"
text_key = "object.sign.garden.text"
```

**A trigger volume never names its consequence.** It sets a flag and emits
`Events.trigger_fired`; anything may watch either. Same for a lever. That is what stops the object
catalogue growing a class per plot beat.

**`verb` is stored as an ordinal.** `GameEnums.InteractVerb` is appended to and never reordered
for exactly this reason: moving a value would silently repoint every authored scene at a different
verb. Write the number (`verb = 5` is `TALK`) or leave the prefab's default.

---

## Add an item

One file, four fields, no registration:

```
[gd_resource type="Resource" script_class="ItemDefinition" load_steps=2 format=3]

[ext_resource type="Script" path="res://src/content/items/item_definition.gd" id="1_def"]

[resource]
script = ExtResource("1_def")
id = &"item/rose_key"
name_key = "item.rose_key.name"
category = 2
max_stack = 1
```

- Save it in **`data/items/`**. `ItemDb` finds it by scanning that directory (ADR-0006) — an
  `ItemDefinition` anywhere else is invisible to `Inventory.add(id)` while still being loadable by
  a `Pickup`, which is the one silent failure this design admits, and `check_content` reports it.
- `id` is `item/` plus the file name. `max_stack = 1` is how a unique key item is expressed;
  there is no `stackable` bool, because two fields encoding one fact eventually disagree.
- `category` is a `GameEnums.ItemCategory` ordinal: `0` TOOL, `1` CONSUMABLE, `2` KEY_ITEM,
  `3` QUEST, `4` MATERIAL, `5` CLOTHING, `6` DOCUMENT, `7` TREASURE. There is no weapon or armour
  category and there will not be one.
- `name_key` must have a CSV row, or the inventory screen prints the key at the player.
- `equip_slot` is optional and defaults to `0` NONE, which is what almost every item is. See the
  next section for what a non-zero value buys.

---

## Make an item equippable, and gate a way through on it

An equippable item is an ordinary item with one extra field. There is no equipment resource, no
slot table to register in and nothing to wire:

```
[gd_resource type="Resource" script_class="ItemDefinition" load_steps=2 format=3]

[ext_resource type="Script" path="res://src/content/items/item_definition.gd" id="1_def"]

[resource]
script = ExtResource("1_def")
id = &"item/brass_lantern"
name_key = "item.brass_lantern.name"
category = 0
max_stack = 1
equip_slot = 1
```

`equip_slot` is a `GameEnums.EquipSlot` ordinal: `0` NONE, `1` LIGHT, `2` TOOL, `3` GARMENT,
`4` TRINKET. There is no weapon slot and no armour slot, for the same reason `ItemCategory` has
no weapon category. Like `InteractVerb`, the enum is appended to and never reordered, because
your `.tres` stores the number.

The player equips it from the satchel screen: `I` to open, arrow keys to the row, **Enter** to
hold or stow. A held row reads `Brass Lantern  x1   [in hand]`. **The item stays in the bag while
it is held** — so a gate that wants it *carried* is still satisfied, and `Inventory.count_of()`
never disagrees with the screen.

### The seam: what is held is a FLAG

Holding an item writes one flag, and that is the whole interface:

```
equip/<wearer id>/<item id>          e.g.  equip/player/item/brass_lantern
```

The wearer id is `player` unless a scene overrode it on that carrier's `Equipment` node. Because
it is a flag, **everything that can already read a flag can gate on what is in hand, with no code
and no new field**:

| To make | Set |
|---|---|
| a way through that needs a light | a `Gate` with `requires_flag = &"equip/player/item/brass_lantern"` |
| a quest step that ends when you pick the lantern up and hold it | a `QuestStep` with that flag and `condition_test = 1` |
| a reply that only appears with a light in hand | a `DialogueChoice` with that flag and `condition_test = 1` |
| a climb only possible unencumbered | a `ClimbPoint`'s `requires_flag`, tested the other way |

None of those four classes knows equipment exists. The gate in the demo courtyard is exactly the
first row:

```
[node name="ShadowedArch" parent="Interactables" instance=ExtResource("9_gate")]
object_id = &"shadowed_arch"
label_key = "object.gate.arch.label"
requires_flag = &"equip/player/item/brass_lantern"
locked_key = "object.gate.arch.locked"
opened_key = "object.gate.arch.opened"
```

### Write the refusal, or the player gets a line about a different door

`locked_key` is what the player reads when they are turned away. Leave it out and they get the
generic `refusal.locked` — *"It will not budge. Something holds it shut."* — which is true of
every locked thing in every game and tells them nothing about needing a light. Every `Interactable`
may name a line this way for the reason it refuses; `Gate` names one for LOCKED, and a
`PathAction`'s `refusal_key` names one for LOW_STANDING.

### Three behaviours worth knowing before you write

- **One item per slot, and the newcomer wins.** Holding a second LIGHT stows the first rather than
  being refused, because a refusal would make swapping a lantern a two-step chore.
- **Losing the item stows it.** Sell, drop or lose an item and the flag goes with it, so a gate
  gated on it locks again — though a `Gate` with `stays_open = true`, which is the default, has
  already opened for good.
- **A new game clears it, and a save restores it.** Equipment has no save section of its own; it
  IS flags, so it round-trips through the machinery that already exists.

### Seeing it

```bash
G=/c/Rai/softwares/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe
"$G" --resolution 960x540 --quit-after 90 -- --new-game --give=item/brass_lantern \
     --equip=item/brass_lantern --open-inventory --shot=held.png --shot-frame=70 \
     --time=12:00 --freeze-time
```

`--equip` applies **after** the area lands, for the same reason `--flag` does: the flag it writes
is a flag, and `--new-game` clears every one of them first. Swap `--open-inventory` for
`--stand-by=ShadowedArch --interact=1` to photograph the gate being refused, and then the same
line with `--equip` to photograph it opening.

---

## Add a conversation

A conversation is a `.tres` in `data/dialogue/`, found by scan like an item. It is an **ordered
array of nodes**, and the runner falls through — the entry point is the first node whose condition
passes, not `nodes[0]`. That is what makes "if we have met, greet me differently" two nodes and no
wiring at all.

### The three resources

- **`Conversation`** — `id` (equal to `talk/` plus the file name) and `nodes`, in authored order.
- **`DialogueNode`** — `node_id`, `speaker_key`, `text_key`, and then either `next_node` or
  `choices`. Plus one condition (`condition_flag`, `condition_test`, `condition_value`) and one
  effect (`effect_flag`, `effect_write`, `effect_value`).
- **`DialogueChoice`** — `text_key`, `target_node`, and a condition of its own. **No effect:**
  effects fire on *arrival* at a node, so a node has the same consequence however it was reached.

`condition_test` is a `GameEnums.FlagTest` ordinal — `0` ALWAYS, `1` IS_TRUE, `2` IS_FALSE,
`3` EQUALS, `4` AT_LEAST, `5` AT_MOST. `effect_write` is `GameEnums.FlagWrite` — `0` NONE,
`1` SET_TRUE, `2` SET_FALSE, `3` SET_INT, `4` ADD.

**It is a closed set of comparisons, deliberately, and not an expression language.** The moment a
conversation can hold an expression it needs a parser, error reporting and a sandbox, and the
`.tres` stops being reviewable in a diff. If six tests are genuinely not enough, the answer is a
seventh, not a grammar.

Two behaviours worth knowing before you write:

- **An empty `next_node` ends the conversation.** It does *not* fall through to the next node in
  the array — "ends here" and "continues to whatever happens to be next" must not look identical.
- **A choice whose condition fails is omitted, not greyed out.** The opposite of a locked gate,
  on purpose: a gate you cannot open tells you to come back, a reply you cannot give tells you
  only that the writer thought of it.

### A worked conversation

Sub-resources are declared before `[resource]` and referenced by `SubResource("id")`:

```
[gd_resource type="Resource" script_class="Conversation" load_steps=8 format=3]

[ext_resource type="Script" path="res://src/content/dialogue/conversation.gd" id="1_talk"]
[ext_resource type="Script" path="res://src/content/dialogue/dialogue_node.gd" id="2_node"]
[ext_resource type="Script" path="res://src/content/dialogue/dialogue_choice.gd" id="3_choice"]

[sub_resource type="Resource" id="choice_ask"]
script = ExtResource("3_choice")
text_key = "talk.warden.choice.ask"
target_node = &"answer"

[sub_resource type="Resource" id="choice_leave"]
script = ExtResource("3_choice")
text_key = "talk.warden.choice.leave"
target_node = &""

[sub_resource type="Resource" id="node_greet_again"]
script = ExtResource("2_node")
node_id = &"greet_again"
speaker_key = "talk.warden.name"
text_key = "talk.warden.greet_again"
next_node = &"menu"
condition_flag = &"met/warden"
condition_test = 1

[sub_resource type="Resource" id="node_greet_first"]
script = ExtResource("2_node")
node_id = &"greet_first"
speaker_key = "talk.warden.name"
text_key = "talk.warden.greet_first"
next_node = &"menu"
effect_flag = &"met/warden"
effect_write = 1

[sub_resource type="Resource" id="node_menu"]
script = ExtResource("2_node")
node_id = &"menu"
speaker_key = "talk.warden.name"
text_key = "talk.warden.menu"
choices = Array[DialogueChoice]([SubResource("choice_ask"), SubResource("choice_leave")])

[sub_resource type="Resource" id="node_answer"]
script = ExtResource("2_node")
node_id = &"answer"
speaker_key = "talk.warden.name"
text_key = "talk.warden.answer"

[resource]
script = ExtResource("1_talk")
id = &"talk/warden"
nodes = Array[DialogueNode]([SubResource("node_greet_again"), SubResource("node_greet_first"), SubResource("node_menu"), SubResource("node_answer")])
```

`greet_again` comes **before** `greet_first` in the array: the runner takes the first node whose
condition passes, so the conditional greeting has to be offered the chance to win.

Every `text_key`, `speaker_key` and choice `text_key` needs a CSV row. `check_content` resolves
all of them, and resolves dangling `next_node` / `target_node` links as well — the single most
likely mistake in a format like this, and otherwise invisible until a player walks that branch.

**A conversation is not saved.** Persisting a position would write a node id into the save file
and make every node id in every `.tres` a permanent public identifier. A save taken
mid-conversation reloads with the conversation over and control returned.

---

## Add an NPC

An NPC is an instance of `scenes/characters/npc.tscn` under an area's `Actors`. The prefab already
carries the brain, the sprite, a navigation agent, a `PersistentState` and a `Talk` speaker; you
override their fields from the area scene.

### 1. A schedule, if it should move

`data/schedules/<name>.tres`, found by scan:

```
[gd_resource type="Resource" script_class="NpcSchedule" load_steps=5 format=3]

[ext_resource type="Script" path="res://src/content/npc/npc_schedule.gd" id="1_sched"]
[ext_resource type="Script" path="res://src/content/npc/schedule_entry.gd" id="2_entry"]

[sub_resource type="Resource" id="morning"]
script = ExtResource("2_entry")
from_hour = 6
waypoint = &"gate_post"
activity = 1

[sub_resource type="Resource" id="night"]
script = ExtResource("2_entry")
from_hour = 20
waypoint = &"bench"
activity = 2

[resource]
script = ExtResource("1_sched")
id = &"schedule/keeper"
entries = Array[ScheduleEntry]([SubResource("morning"), SubResource("night")])
```

- `id` is `schedule/` plus the file name.
- `activity` is a `GameEnums.NpcActivity` ordinal: `0` STAND, `1` WANDER, `2` SLEEP.
- **An entry has no `until_hour`.** It runs until the next begins, and the last wraps past
  midnight, so a day is always completely covered and two entries cannot disagree about who owns
  14:00. List them in ascending `from_hour`.
- **`waypoint` names a `Marker3D` under some area's `Waypoints`, by node name.** `check_content`
  fails a schedule that names a waypoint no area has — an NPC sent somewhere that does not exist
  stands still forever and nothing says why. It cannot check that the marker is in the *right*
  area; that is a placement mistake, and it looks like an NPC that never leaves its spawn.
- **Put waypoints somewhere the body can walk**, which is not the same as somewhere the navmesh
  covers. See `agent_max_climb`, above.

### 2. Placing it, and the editable trap

Declare the prefab as an `ExtResource` at the top of the area scene, then instance it:

```
[ext_resource type="PackedScene" path="res://scenes/characters/npc.tscn" id="19_npc"]

[node name="Warden" parent="Actors" instance=ExtResource("19_npc")]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 1.7, 0, 4.2)
schedule_id = &"schedule/warden"

[node name="PersistentState" parent="Actors/Warden"]
object_id = &"warden"

[node name="Talk" parent="Actors/Warden"]
object_id = &"warden_talk"
label_key = "object.warden.label"
conversation_id = &"talk/warden"

[editable path="Actors/Warden"]
```

`schedule_id` is on the instance root, so it needs no marker. `PersistentState` and `Talk` are
**children of the instanced prefab**, and overriding them is what requires the `[editable]` line.

An NPC with no `schedule_id` stands where it was placed, which is a legitimate thing to author.
An NPC with no `conversation_id` on its `Talk` offers a prompt that does nothing, which is not.

### 3. Optional: path actions on the same NPC

An NPC's non-combat verbs — scrutinise, barter, inquire — are **overlapping interactables, not a
menu**: the sensor already ranks and Tab-cycles between overlapping targets, and a menu would be a
second selection mechanism competing with the first. Instance `path_action.tscn` as an extra child
of the NPC (also inside the `[editable]`), point its `action` at a `PathAction` in `data/actions/`,
and set `standing_id` to the same name the NPC's standing is kept under.

`PathAction` distinguishes a **refusal** from a **failure**, and the distinction is the design: a
refusal happens before anything, costs nothing and explains itself; a failure happens after
committing and costs something. `once` applies to success only, or one early failure would lock
the player out forever.

Unlike items, conversations and schedules, a `PathAction` is **referenced by path, not found by
scan** — there is no registry and no id-equals-filename rule. `check_content` still validates
every `.tres` in `data/actions/`.

---

## Add a quest

A quest is a `.tres` in `data/quests/`, found by scan like an item. **You never write code and you
never wire anything to it.** A quest names the flag conditions it cares about, and `QuestTracker`
watches `Flags` and does the rest.

### The one idea to get first: a quest observes, it is never told

There is no "give quest" call, no `start_quest()` and nothing for an NPC to point at. A quest
declares:

- a **start condition** — one flag test. When it passes, the quest is active.
- **steps in order** — one flag test each. The current objective is the *first* step whose test
  does not pass. When none is left, the quest is complete.

So a conversation that already writes `met/warden` starts any quest that tests `met/warden`, and
the conversation has never heard of quests. Same for a lever, a trigger volume, a gate, or a path
action — anything that writes a flag can advance a quest, and none of them needs changing.

Which means the practical question when authoring a quest is **"what flag does the thing I want
already write?"** The six writers, and where each is documented:

| To finish a step on | The flag comes from | Set it in |
|---|---|---|
| talking to someone | a `DialogueNode` effect | § Add a conversation — `effect_flag` / `effect_write` |
| throwing a lever | `Lever.world_flag` | § Add an interactable object |
| walking somewhere | `TriggerVolume.world_flag` | § Add an interactable object |
| opening a gate, emptying a chest | `PersistentState` — `obj/<area_id>/<object_id>/<field>` | ADR-0005 |
| a path action succeeding | `PathAction.success_flag` | § Add an NPC, step 3 |
| holding an item | `Equipment` — `equip/<wearer>/<item id>` | § Make an item equippable |

**AN ITEM COUNT IS NOT A FLAG, and this is the one thing the design does not give you.**
`Inventory` keeps counts, not flags, so "bring me three petals" cannot be written as a step
today. **"Hold ONE of this" CAN be**, since WP-09 — see § Make an item equippable, whose
`equip/<wearer>/<item>` flag is a legal step condition. For a real count the nearest working
thing is a `Pickup` or an `ItemContainer` beside a `TriggerVolume`, or a path action gated on
the item. A step that reads a count is a *template* change, recorded as T3.3 in
`docs/WORK_PACKAGES.md` — do not work around it by putting a script under `src/`.

### The two resources

- **`Quest`** — `id` (equal to `quest/` plus the file name), `name_key`, `summary_key`, `steps` in
  authored order, and one start condition (`condition_flag`, `condition_test`, `condition_value`).
- **`QuestStep`** — `step_id` (unique within the quest), `summary_key`, and one completion
  condition with the same three field names.

`condition_test` is a `GameEnums.FlagTest` ordinal, the same closed set a dialogue condition uses —
`0` ALWAYS, `1` IS_TRUE, `2` IS_FALSE, `3` EQUALS, `4` AT_LEAST, `5` AT_MOST. `ALWAYS` as a start
condition means the quest is active from the first frame of a new game, which is right for a
tutorial objective and wrong for everything else.

### A worked quest

Sub-resources are declared before `[resource]` and referenced by `SubResource("id")`:

```
[gd_resource type="Resource" script_class="Quest" load_steps=4 format=3]

[ext_resource type="Script" path="res://src/content/quest/quest.gd" id="1_quest"]
[ext_resource type="Script" path="res://src/content/quest/quest_step.gd" id="2_step"]

[sub_resource type="Resource" id="step_lantern"]
script = ExtResource("2_step")
step_id = &"lantern"
summary_key = "quest.warden_lamps.step.lantern"
condition_flag = &"count/lanterns_lit"
condition_test = 4
condition_value = 3

[sub_resource type="Resource" id="step_report"]
script = ExtResource("2_step")
step_id = &"report"
summary_key = "quest.warden_lamps.step.report"
condition_flag = &"story/warden_thanked"
condition_test = 1

[resource]
script = ExtResource("1_quest")
id = &"quest/warden_lamps"
name_key = "quest.warden_lamps.name"
summary_key = "quest.warden_lamps.summary"
steps = Array[QuestStep]([SubResource("step_lantern"), SubResource("step_report")])
condition_flag = &"met/warden"
condition_test = 1
```

Save it in **`data/quests/`**. `name_key`, `summary_key` and every step's `summary_key` need a CSV
row, and `check_content` fails on any that does not have one — plus it prints every flag the quest
and its steps name, which is the line to read when a quest starts and can never finish.

### Four behaviours worth knowing before you write

- **Step order is authored, not chronological.** Satisfying step two before step one leaves step
  one as the current objective. That is what makes a journal read like instructions.
- **Completion is permanent; a step is not.** Once every step has passed, the quest is complete and
  *stays* complete even if the flags move back — a counter that gets decremented must not reopen a
  finished quest. An **active** quest's objective, by contrast, is re-derived every time a flag
  changes, so clearing the flag behind objective two brings objective two back. Both are
  deliberate; the reasoning is in `src/systems/quest/quest_tracker.gd`.
- **A completed quest gives you nothing by itself.** It emits `Events.quest_completed(quest_id)`
  and stops. To hand over an item, open a gate or start the next chapter, listen to that signal —
  or, with no code at all, have a conversation node condition on the flag the last step tested.
- **A quest is saved by id.** Started and completed are written to the save; the current objective
  is re-derived on load, so renaming a `step_id` does not break an old save. Renaming a **quest
  id** does: it is a public identifier, exactly like an `object_id`.

### Seeing it

The journal is the `J` key, or `--open-menu=journal` for a capture. Because a step is a flag
condition, `--flag=` poses quest progress without playing to it:

```bash
G=/c/Rai/softwares/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe
"$G" --resolution 960x540 --quit-after 90 -- --new-game --flag=met/warden:true \
     --open-menu=journal --shot=journal.png --shot-frame=70 --time=12:00 --freeze-time
```

`--flag` applies **after** the area lands, because `--new-game` clears every flag first.

---

## The editable trap

**A `[node]` block whose `parent=` descends into an instanced node requires
`[editable path="<that instance>"]` at the foot of the scene.**

Without it, running from source works perfectly — the text loader applies the override. An export
converts `.tscn` to binary `.scn`, and the conversion **silently discards** the override, so the
prefab reverts to its defaults in the shipped build *only*. The demo's NPC shipped with no
`object_id`, no prompt and no conversation exactly this way, while every ladder rung, both CI jobs
and 930 assertions stayed green.

`tools/check_content.gd` gates it now, and is deliberately stricter than the failure needs — an
*added* node inside an instance survives the conversion and is still required to be declared,
because "which of the two kinds is this" is a distinction the exporter makes and an author should
not have to remember. Godot needs the marker at **every** level, so a nested instance needs one
per level.

Two related notes. `index="4"` on such a block is written by the editor and is **not** what
resolves the node — the name is; stale indices look like the culprit here and are not. And
overriding a property on the instance's *root* (like `schedule_id` above) needs no marker at all.

---

## Localization

`localization/strings.csv`, header row `keys,en`. Which prefixes are yours and which are the
engine's is the table in [`TEMPLATE.md`](TEMPLATE.md): `area.*`, `object.*`, `item.*`
(except `item.category.*`), `talk.*` and `action.*` are content; `ui.*`, `verb.*`, `refusal.*`,
`notify.*`, `weather.*`, `time.*`, `keys.*` are engine.

```
area.my_area.name,My Area
object.sign.garden.label,Weathered Notice
object.sign.garden.text,"Mind the thorns, and the hour."
```

Quote any value containing a comma. Re-run `--headless --import` afterwards to regenerate the
`.translation`. A key with no row is not an error at load — `tr()` returns the key itself, and the
player reads `object.sign.garden.label` on screen — which is why `check_content` resolves every
`_key` literal in every scene and every key a conversation or a path action names.

---

## The gates, and what each one catches

Run all of them. In this order, because a later one assumes the earlier passed.

```bash
G=/c/Rai/softwares/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe
"$G" --headless --import                                     # grep for SCRIPT ERROR / Parse Error
"$G" --headless --quit-after 120                             # must end "0 warnings, 0 errors"
"$G" --headless res://tests/test_runner.tscn --quit-after 400
"$G" --headless --script tools/check_content.gd
"$G" --headless --script tools/check_boundary.gd
"$G" --headless --script tools/check_budgets.gd
"$G" --resolution 960x540 --quit-after 90 -- --new-game --shot=shot.png --shot-frame=70 \
     --time=12:00 --freeze-time
```

| Gate | Catches, for an author |
|---|---|
| `--import` | a `.tscn` that does not load, a script that does not parse |
| boot run | that the game boots clean to its main menu. **It does not enter an area** — see below |
| test suite | a missing required child, an area with no spawn, an interior that follows the sun, a schedule waypoint no area has, a quest with no steps |
| `check_content` | a duplicate `object_id`, a `_key` with no CSV row, an unquoted comma, a dangling dialogue link, an id that disagrees with its file name, a stray `ItemDefinition`, a quest step whose objective has no CSV row, a gate whose `locked_key` has no row, **a missing `[editable]` marker** |
| `check_boundary` | your content id appearing in `src/` — which is a bug in the *engine*, not in your content |
| `check_budgets` | 250 code lines per file, 40 per function. Markdown is not counted |
| windowed capture | everything the other six cannot see |

### Nothing above ever enters your area, and that surprises everyone once

**A plain run stops at the main menu.** `--headless --quit-after 120` boots, reports
`0 warnings, 0 errors` and never loads an area, so it cannot tell you that your `area_id` is
wrong, that your navmesh baked empty, or that your NPC has no schedule. Neither can a `--shot`
on its own: the PNG is the title screen.

**`--new-game` is what starts a game**, and it is one of a set of debug flags the development
harness answers. They are behind `OS.is_debug_build()`, so they do not exist in a shipped build.

| Flag | Does |
|---|---|
| `--new-game` | starts a game — enters `[game] world/first_area` |
| `--goto=<area_id>` | travels to an area, so you can capture one that is not the first |
| `--shot=<abs path>` and `--shot-frame=<n>` | capture a PNG, at that frame. The area load is threaded and needs frames — 70 with `--quit-after 90` is a safe pair |
| `--time=HH:MM` and `--freeze-time` | a reproducible hour. Without the freeze, weather and the clock keep rolling and no two captures match |
| `--stand-by=<node name>` | put the player beside a node, by its **node name** — not its `object_id`. Asking for `warden_talk` fails; ask for `Warden` |
| `--equip=<item id>[,<id>]` | put carried items **in hand**, after the area lands. `--give` first, on the same line — an item nobody carries is refused |
| `--flag=<key>:<value>` | forge a plot flag **after** the area lands, so quest progress can be posed: `--flag=met/warden:true`, `--flag=count/lit:3`. `--new-game` clears flags first, which is why it cannot be earlier |
| `--interact=<frame>`, `--cycle=<n>`, `--talk-advance=<frame>` | press the interact key, Tab between overlapping targets, advance a conversation |
| `--give=<item id>[:count]`, `--standing=<who>:<n>`, `--weather=<kind>` | pose the world before the shutter |

**Capture your first version of an area at midday.** A new area has no props and no lanterns, and
the shipped dusk hour renders it very nearly black — which looks exactly like a lighting bug and
is not one.

**`--headless` shades nothing.** It uses a dummy rasteriser, so a visual claim — an area is lit, a
sprite is drawn from the right cell, a menu is legible — needs the windowed capture, and needs you
to *look at the PNG*. A day/night system once ran, logged correct times, reported no errors and lit
nothing at all, because one `@export` was unwired.

**And `0 warnings, 0 errors` does not mean the scripts compiled.** That line counts the game's own
`Log.warn` / `Log.error` calls; an engine-level `Parse Error` is neither. The import rung is the
compile check — grep its output for `SCRIPT ERROR` and `Parse Error` and require zero.

## Read next

[`ART_CONTRACT.md`](ART_CONTRACT.md) — what art has to satisfy to drop in ·
[`TESTING.md`](TESTING.md) — adding assertions to a template you did not write ·
[`ARCHITECTURE.md`](ARCHITECTURE.md#the-extension-surface) — what you may subclass and what is the
engine's own business ·
[`NEW_GAME.md`](NEW_GAME.md) · [`TEMPLATE.md`](TEMPLATE.md)
