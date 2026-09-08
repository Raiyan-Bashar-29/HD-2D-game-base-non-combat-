extends TestCase
## THE SHAPE OF THE RECORD, CHECKED AGAINST THE RECORD.
##
## WHY THIS IS NOT `docs_test.gd` OR `doc_counts_test.gd`
## Three gates now watch the documents and each owns one kind of fact, because each has a
## different countable thing behind it. `docs_test.gd` owns what a document claims EXISTS - a
## `res://` path, a field in a worked example - and its MUST NOT line forbids asserting anything
## about what the prose SAYS. `doc_counts_test.gd` owns ONE number, the gotcha list's length, and
## its MUST NOT line forbids growing a second. Neither can hold what is here, and widening either
## would break a boundary a package wrote down on purpose. So this is a third case.
##
## WHAT IS HERE IS STRUCTURE, WHICH IS THE PART OF A DOCUMENT THAT IS NOT PROSE AT ALL.
## A file either opens with its own title or it does not. A package either has a row on the board
## or it does not. Neither question has a reading, an interpretation or a tone - which is exactly
## why they are assertable when the sentences around them are not.
##
## WHAT WENT WRONG WITHOUT IT
## T5.15 appended its `Row styles` row to `SYSTEMS_INVENTORY.md` at LINE 1, above the document's
## own `# Systems Inventory` heading. The row was the only copy, so the system it described was
## missing from the table it belonged in AND the file rendered with a stray table fragment before
## its title, and both survived three packages and a green ladder. T5.17 then shipped with no row
## on the board at all - the board's own closing checklist item 6 says "This file marks the
## package DONE with its commit" - and that survived too, because nothing counts the rows.
##
## T5.17 CONCLUDED "NOTHING GATES A PROSE CLAIM, AND NOTHING CAN", AND THAT IS RIGHT ABOUT PROSE.
## It is not right about a heading or a row, and the distinction is the whole justification for
## this file: five of that package's six defects were sentences and would defeat any tool, and
## the sixth was a count, which `doc_counts_test.gd` already gates. Structure is the third kind.
##
## THE PLAN IS COMPUTED from what the scan found, for `docs_test.gd`'s reason: adding a document
## or a package should not mean editing a number.
##
## OWNS: that every document opens with its own title, and that every package the log records has
##   a row on the board.
## MUST NOT: assert the wording of any prose, the ORDER of anything, or what a row SAYS. A row
##   that exists and is wrong is a review problem; a row that does not exist is this one.

const DOC_DIR: String = "res://docs"
const EXTRA_DOCS: Array[String] = ["res://CLAUDE.md"]
const BOARD: String = "res://docs/WORK_PACKAGES.md"
const LOG: String = "res://docs/DEVLOG.md"

## A log heading is `## <date> — <id> · <title>`. Only a WELL-FORMED package id is a package:
## `T5.17` and `WP-09b` are rows on the board, while `Audit`, `Phase` and `Work` open entries
## that are narrative and were never packages. Matching the id's SHAPE rather than listing the
## exceptions is what keeps this from becoming a list that rots - the same reasoning
## `check_boundary.gd` uses to derive its namespaces instead of naming them.
const HEADING_PATTERN: String = "^## [0-9-]{10} — (T[0-9]+[.][0-9]+|WP-[0-9]+[a-z]?)"

var _docs: Array[String] = []
var _packages: Array[String] = []


func run() -> void:
	_gather()
	plan(_docs.size() + _packages.size() + 2)
	equal("docs/ carries documents to check", _docs.size() > 0, true)
	equal("the log records packages to check", _packages.size() > 0, true)
	_every_document_opens_with_its_title()
	_every_recorded_package_has_a_board_row()


## A markdown file whose first content is not its heading has had something appended to the wrong
## end, and the appended thing is then invisible in every reader that renders a title.
func _every_document_opens_with_its_title() -> void:
	for path: String in _docs:
		var opens: bool = _first_content_line(path).begins_with("# ")
		equal("%s opens with its title" % path.get_file(), opens, true)


## The board is the index of what this project did. A package with no row on it is work that
## happened and cannot be found from the one file `CLAUDE.md` sends a reader to.
func _every_recorded_package_has_a_board_row() -> void:
	var board: String = FileAccess.get_file_as_string(BOARD)
	for id: String in _packages:
		equal("%s has a row on the board" % id, board.contains(id), true)


func _gather() -> void:
	_docs = _doc_files()
	var matcher := RegEx.create_from_string(HEADING_PATTERN)
	for line: String in FileAccess.get_file_as_string(LOG).split("\n"):
		var hit: RegExMatch = matcher.search(line)
		if hit == null:
			continue
		var id: String = hit.get_string(1)
		if not _packages.has(id):
			_packages.append(id)


## Blank lines before a heading render as nothing, so they are skipped rather than failed.
func _first_content_line(path: String) -> String:
	for line: String in FileAccess.get_file_as_string(path).split("\n"):
		if not line.strip_edges().is_empty():
			return line
	return ""


func _doc_files() -> Array[String]:
	var found: Array[String] = []
	for file_name: String in DirAccess.get_files_at(DOC_DIR):
		if file_name.ends_with(".md"):
			found.append("%s/%s" % [DOC_DIR, file_name])
	found.append_array(EXTRA_DOCS)
	return found
