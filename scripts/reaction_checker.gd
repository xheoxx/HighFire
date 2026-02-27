# =============================================================================
# DATEINAME: reaction_checker.gd
# ZWECK:     Prueft bei jedem add_effect()-Aufruf ob eine Reaktion ausgeloest
#            wird. Laeuft synchron in add_effect() – keine asynchrone Verzoegerung.
#            Alle 4 Reaktionen aus DESIGN.md implementiert.
#            Reaktionsregeln kommen aus status_effects.tres (reactions-Dictionary).
# ABHAENGIG VON: resources/status_effects.tres
# =============================================================================

class_name ReactionChecker
extends Node

# Geladene Reaktions-Definitionen aus status_effects.tres
var _reactions_config: Dictionary = {}

# Prueft ob aktive Effekte eine Reaktion ausloesen.
# Gibt ein leeres Dictionary zurueck wenn keine Reaktion, sonst { reaction_id, consumed_effects, ... }
func check_reactions(active_stacks: Dictionary, effects_config: Resource) -> Dictionary:
	if not effects_config:
		return {}

	if _reactions_config.is_empty():
		_reactions_config = effects_config.get("reactions") if effects_config.get("reactions") else {}

	for reaction_key in _reactions_config.keys():
		var parts: Array = reaction_key.split("+")
		if parts.size() != 2:
			continue

		var eff_a: String = parts[0]
		var eff_b: String = parts[1]

		# Beide Effekte muessen aktiv sein
		if active_stacks.has(eff_a) and not active_stacks[eff_a].is_empty() \
				and active_stacks.has(eff_b) and not active_stacks[eff_b].is_empty():
			var reaction_def: Dictionary = _reactions_config[reaction_key]
			# Reaktionsdaten mit konsumierten Effekten zurueckgeben
			var result: Dictionary = reaction_def.duplicate()
			result["consumed_effects"] = [eff_a, eff_b]
			return result

	return {}
