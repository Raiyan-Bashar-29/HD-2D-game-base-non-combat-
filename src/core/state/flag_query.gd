class_name FlagQuery
extends RefCounted
## Evaluates a `GameEnums.FlagTest` against `Flags`. The ONE implementation of the closed set.
##
## WHY IT IS ITS OWN FILE, AND WHY IT WAS EXTRACTED RATHER THAN COPIED
## Until WP-08 this `match` lived privately inside `DialogueRunner`, which was correct while
## dialogue was the only thing that asked a flag a question. A quest step asks the same
## question, with the same six comparisons and the same meaning, and copying fifteen lines
## would have made "what does AT_LEAST mean" a fact stored in two places. This project has
## already written that reasoning down twice - a weather emitter is TOLD its weight rather than
## reading `Weather` itself, and a `Theme` colour lives once rather than per variation - both
## for the same reason: two copies of a rule eventually disagree, and the disagreement surfaces
## as a quest that will not complete for a flag a conversation is perfectly happy with.
##
## THE SET IS CLOSED AND STAYS CLOSED. Six comparisons, and when six are genuinely not enough
## the answer is a seventh, never an expression language - see `GameEnums.FlagTest`.
##
## ONLY THE READ HALF IS HERE. `GameEnums.FlagWrite` has exactly one caller,
## `DialogueRunner._apply_effect`, so extracting it would create a shared file to serve a single
## consumer. When a second thing writes a flag from authored data, this is where it belongs and
## the file name already covers it.
##
## OWNS: turning a (flag, test, value) triple into a bool.
## MUST NOT: write a flag, cache an answer, or know what any flag means. It reads `Flags` and
## nothing else, which is also why it is not in `src/core/util/` - a content class must be
## loadable by a `--script` tool, and this touches an autoload on purpose.


## Does this condition hold right now?
##
## ALWAYS, and an EMPTY FLAG NAME, both pass. An unconditional line or step should need no
## fields filled in at all, and a test that names nothing is authored-but-unfinished rather than
## false - `problems()` on the owning resource is what reports it, loudly, at load time.
static func passes(flag: StringName, test: GameEnums.FlagTest, value: int) -> bool:
	if test == GameEnums.FlagTest.ALWAYS or flag == &"":
		return true
	match test:
		GameEnums.FlagTest.IS_TRUE:
			return Flags.get_bool(flag, false)
		GameEnums.FlagTest.IS_FALSE:
			return not Flags.get_bool(flag, false)
		GameEnums.FlagTest.EQUALS:
			return Flags.get_int(flag, 0) == value
		GameEnums.FlagTest.AT_LEAST:
			return Flags.get_int(flag, 0) >= value
		GameEnums.FlagTest.AT_MOST:
			return Flags.get_int(flag, 0) <= value
	return true
