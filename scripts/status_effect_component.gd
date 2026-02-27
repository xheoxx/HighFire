# =============================================================================
# DATEINAME: status_effect_component.gd
# ZWECK:     Component auf jedem Spieler-Node. Verwaltet alle aktiven
#            Statuseffekte mit Stack-Mechanik (geometrisch abnehmend),
#            eigenen Timern pro Stack und Immunitats-Regeln lt. DESIGN.md.
#            Delegiert Reaktionspruefung an reaction_checker.gd.
# ABHAENGIG VON: resources/status_effects.tres, reaction_checker.gd,
#                player.gd (fuer Input-Block und Speed-Modifikation),
#                player_input.gd (stun/freeze Flag)
# =============================================================================

class_name StatusEffectComponent
extends Node

# =============================================================================
# SIGNALE
# =============================================================================

# Wird gesendet wenn sich ein Effekt aendert (Stack hinzugefuegt/entfernt).
# effect_id: z.B. "burning", "slow", "stun" – stack_count: 0 = Effekt vorbei
# status_effect_hud.gd hoert auf dieses Signal und aktualisiert das HUD.
signal effect_changed(effect_id: String, stack_count: int)

# Wird gesendet wenn eine Reaktion ausgeloest wurde (fuer VFX/Sound).
signal reaction_triggered(reaction_id: String, position: Vector2)

# =============================================================================
# INTERNER STATE
# =============================================================================

# Geladene Effekt-Definitionen aus status_effects.tres
var _effects_config: Resource

# Geladener ReactionChecker (Sibling-Node oder wird via NodePath gesetzt)
var _reaction_checker: ReactionChecker

# Aktive Effekte: { "burning": [ {timer, stack_value}, ... ], ... }
# Jeder Stack hat seinen eigenen Timer-Countdown.
var _active_stacks: Dictionary = {}

# Immunitats-Timer: { "frozen": 2.7 (verbleibende Zeit), ... }
var _immunity_timers: Dictionary = {}

# Reaktions-Cooldown: { "steam_burst": 2.4, ... }
var _reaction_cooldown_timers: Dictionary = {}

# Anti-Frustrations-Cap: maximal 3 verschiedene Debuff-Typen gleichzeitig.
# Wird aus status_effects.tres gelesen (max_debuff_types).
var _max_debuff_types: int = 3

# Reaktions-Cooldown-Dauer (aus status_effects.tres).
var _reaction_cooldown_duration: float = 3.0

# Referenz auf den Spieler-Owner (fuer Speed-Modifikation, Input-Block).
var _player: Player

# Referenz auf PlayerInput-Node (fuer stun/freeze Input-Block).
var _player_input: PlayerInput

# =============================================================================
# LIFECYCLE
# =============================================================================

# Laedt Konfiguration, holt Sibling-Referenzen und verbindet Signale.
func _ready() -> void:
	_effects_config = load("res://resources/status_effects.tres")
	if _effects_config:
		_max_debuff_types = int(_effects_config.get("max_debuff_types") if _effects_config.get("max_debuff_types") != null else 3)
		_reaction_cooldown_duration = float(_effects_config.get("reaction_cooldown") if _effects_config.get("reaction_cooldown") != null else 3.0)

	# ReactionChecker ist ein Sibling-Node in player.tscn
	_reaction_checker = get_parent().get_node_or_null("ReactionChecker")
	if not _reaction_checker:
		# Fallback: als Child anlegen wenn nicht als Sibling vorhanden
		_reaction_checker = ReactionChecker.new()
		add_child(_reaction_checker)

	# Spieler-Owner holen fuer Speed/HP-Modifikation
	_player = get_parent() as Player
	_player_input = get_parent().get_node_or_null("PlayerInput") as PlayerInput

	# Dodge-Signal vom Spieler verbinden → Soft-CC entfernen
	if _player and _player.has_signal("dodged"):
		_player.dodged.connect(_on_player_dodged)

# Tickt alle aktiven Stack-Timer und prueft Immunitaets-Ablauf.
func _process(delta: float) -> void:
	_tick_immunity_timers(delta)
	_tick_reaction_cooldowns(delta)
	_tick_active_stacks(delta)
	_apply_ongoing_effects()

# =============================================================================
# OEFFENTLICHE API
# =============================================================================

# Fuegt einen Statuseffekt-Stack hinzu. Prueft Immunitat, Max-Stacks und
# Anti-Frustrations-Cap. Loest danach Reaktionspruefung aus.
# effect_id: z.B. "burning", "slow", "stun"
# source_player_id: Spieler der den Effekt ausgeloest hat (-1 = System/Arena)
func add_effect(effect_id: String, source_player_id: int = -1) -> void:
	if not _effects_config:
		return

	# Immunitat pruefen – Effekt wird ignoriert wenn Immunitat aktiv
	if _immunity_timers.has(effect_id) and _immunity_timers[effect_id] > 0.0:
		return

	var effect_def: Dictionary = _get_effect_def(effect_id)
	if effect_def.is_empty():
		push_warning("StatusEffectComponent: unbekannter Effekt-ID '%s'" % effect_id)
		return

	# Anti-Frustrations-Cap: max_debuff_types verschiedene Typen erlaubt
	# Buff-Effekte (hot, invisible) zaehlen nicht als Debuff
	var is_debuff: bool = effect_def.get("is_soft_cc", false) or effect_def.get("is_hard_cc", false) or _is_damage_debuff(effect_id)
	if is_debuff:
		_enforce_debuff_cap(effect_id)

	# Max-Stacks pruefen
	var max_stacks: int = int(effect_def.get("max_stacks", 4))
	if _active_stacks.has(effect_id) and _active_stacks[effect_id].size() >= max_stacks:
		return

	# Stack hinzufuegen
	var duration: float = float(effect_def.get("duration", 2.0))
	var stack_index: int = _active_stacks.get(effect_id, []).size()
	var stack_factor: float = float(effect_def.get("stack_factor", 0.5))
	var stack_value: float = pow(stack_factor, stack_index)  # geometrisch abnehmend

	if not _active_stacks.has(effect_id):
		_active_stacks[effect_id] = []
	_active_stacks[effect_id].append({
		"timer": duration,
		"value": stack_value,
		"tick_timer": float(effect_def.get("tick_interval", 0.0)),
		"source": source_player_id,
	})

	effect_changed.emit(effect_id, _active_stacks[effect_id].size())
	_apply_immediate_effect(effect_id, effect_def)

	# Reaktionspruefung nach jedem neuen Stack
	if _reaction_checker:
		var reaction := _reaction_checker.check_reactions(_active_stacks, _effects_config)
		if not reaction.is_empty():
			_trigger_reaction(reaction)

# Entfernt alle Stacks eines Effekts sofort (z.B. durch Reaktion oder externe Ausloesung).
func remove_effect(effect_id: String) -> void:
	if not _active_stacks.has(effect_id):
		return
	_active_stacks.erase(effect_id)
	effect_changed.emit(effect_id, 0)
	_clear_immediate_effect(effect_id)

# Entfernt alle aktiven Soft-CC-Stacks (Verlangsamung, Betaeubung, Blind).
# Wird beim Dodge ausgeloest (Anti-Frustrations-Regel lt. DESIGN.md).
func clear_soft_cc() -> void:
	var soft_cc_ids: Array[String] = []
	if _effects_config:
		var effects: Dictionary = _effects_config.get("effects") if _effects_config.get("effects") else {}
		for eff_id in effects.keys():
			var def: Dictionary = effects[eff_id]
			if def.get("is_soft_cc", false):
				soft_cc_ids.append(eff_id)

	for eff_id in soft_cc_ids:
		if _active_stacks.has(eff_id):
			remove_effect(eff_id)

# Gibt den aktuellen Geschwindigkeits-Multiplikator zurueck (1.0 = kein Effekt).
# player.gd multipliziert speed damit in _physics_process.
func get_speed_multiplier() -> float:
	if not _active_stacks.has("slow"):
		return 1.0
	var total_malus: float = 0.0
	var base_slow: float = 0.3
	for stack in _active_stacks["slow"]:
		total_malus += base_slow * float(stack["value"])
	return clamp(1.0 - total_malus, 0.1, 1.0)

# Gibt den Schadens-Multiplikator fuer eingehenden Schaden zurueck (Ruestungs-Debuff).
# damage_system.gd multipliziert den Schaden damit.
func get_armor_multiplier() -> float:
	if not _active_stacks.has("armor_break"):
		return 1.0
	var total_multiplier: float = 1.0
	var base_mult: float = 1.25
	for stack in _active_stacks["armor_break"]:
		# Jeder Stack multipliziert geometrisch: Stack 1=x1.25, Stack 2=x1.125 etc.
		total_multiplier += (base_mult - 1.0) * float(stack["value"])
	return total_multiplier

# Prueft ob der Spieler aktuell betaeubt oder eingefroren ist (Input-Block).
func is_cc_active() -> bool:
	return _active_stacks.has("stun") or _active_stacks.has("frozen")

# Prueft ob der Spieler aktuell eingefroren ist (Physics-Block).
func is_frozen() -> bool:
	return _active_stacks.has("frozen")

# Prueft ob der Spieler geblendet ist (fuer target_system.gd).
func is_blinded() -> bool:
	return _active_stacks.has("blind")

# Gibt die Stack-Anzahl eines Effekts zurueck (0 = nicht aktiv).
func get_stack_count(effect_id: String) -> int:
	if not _active_stacks.has(effect_id):
		return 0
	return _active_stacks[effect_id].size()

# =============================================================================
# INTERNER TICK
# =============================================================================

# Reduziert alle Stack-Timer und entfernt abgelaufene Stacks.
func _tick_active_stacks(delta: float) -> void:
	var to_remove: Array[String] = []
	for effect_id in _active_stacks.keys():
		var stacks: Array = _active_stacks[effect_id]
		var effect_def: Dictionary = _get_effect_def(effect_id)
		var tick_interval: float = float(effect_def.get("tick_interval", 0.0))

		var expired_indices: Array[int] = []
		for i in range(stacks.size()):
			var stack: Dictionary = stacks[i]
			stack["timer"] -= delta

			# Tick-basierte Effekte (z.B. Brennen, HoT) verarbeiten
			if tick_interval > 0.0:
				stack["tick_timer"] -= delta
				if stack["tick_timer"] <= 0.0:
					stack["tick_timer"] = tick_interval
					_apply_tick_effect(effect_id, effect_def, stack)

			if stack["timer"] <= 0.0:
				expired_indices.append(i)

		# Abgelaufene Stacks entfernen (rueckwaerts um Indizes nicht zu verschieben)
		for i in range(expired_indices.size() - 1, -1, -1):
			stacks.remove_at(expired_indices[i])

		if stacks.is_empty():
			to_remove.append(effect_id)
			_on_effect_expired(effect_id, effect_def)
		else:
			effect_changed.emit(effect_id, stacks.size())

	for eff_id in to_remove:
		_active_stacks.erase(eff_id)
		effect_changed.emit(eff_id, 0)

# Reduziert alle Immunitaets-Timer.
func _tick_immunity_timers(delta: float) -> void:
	var expired: Array[String] = []
	for eff_id in _immunity_timers.keys():
		_immunity_timers[eff_id] -= delta
		if _immunity_timers[eff_id] <= 0.0:
			expired.append(eff_id)
	for eff_id in expired:
		_immunity_timers.erase(eff_id)

# Reduziert Reaktions-Cooldown-Timer.
func _tick_reaction_cooldowns(delta: float) -> void:
	var expired: Array[String] = []
	for r_id in _reaction_cooldown_timers.keys():
		_reaction_cooldown_timers[r_id] -= delta
		if _reaction_cooldown_timers[r_id] <= 0.0:
			expired.append(r_id)
	for r_id in expired:
		_reaction_cooldown_timers.erase(r_id)

# Wendet kontinuierliche Effekte an die nicht tick-basiert sind (Einfrieren, Betaeubung).
func _apply_ongoing_effects() -> void:
	# Einfrieren: Physics-Prozess des Spielers blockieren
	if _player:
		var should_freeze: bool = is_frozen()
		_player.set_physics_process(not should_freeze)

	# Betaeubung + Einfrieren: Input blockieren
	if _player_input:
		var block_input: bool = is_cc_active()
		if _player_input.has_method("set_input_blocked"):
			_player_input.set_input_blocked(block_input)

	# Blind: target_system informieren
	var target_sys: Node = get_parent().get_node_or_null("TargetSystem") if _player else null
	if target_sys and target_sys.has_method("set_blinded"):
		target_sys.set_blinded(is_blinded())

# =============================================================================
# SOFORTIGE EFFEKTE (bei add_effect)
# =============================================================================

# Wendet den Ersteffekt eines Stacks an (Einfrieren sofort, etc.)
func _apply_immediate_effect(effect_id: String, effect_def: Dictionary) -> void:
	match effect_id:
		"invisible":
			# Unsichtbarkeit: Alpha auf dem Spieler setzen
			if _player and _player.has_method("set_invisible"):
				_player.set_invisible(true)
		"slow":
			# Verlangsamungs-Schwelle pruefen → eventuell EINFRIEREN ausloesen
			var freeze_threshold: int = int(effect_def.get("freeze_threshold_stacks", 3))
			if _active_stacks.has("slow") and _active_stacks["slow"].size() >= freeze_threshold:
				add_effect("frozen")
		_:
			pass

# Hebt einen sofortigen Effekt auf (wenn der letzte Stack ablaeuft).
func _clear_immediate_effect(effect_id: String) -> void:
	match effect_id:
		"invisible":
			if _player and _player.has_method("set_invisible"):
				_player.set_invisible(false)
		"frozen":
			# Physics-Prozess wieder aktivieren (wird auch in _apply_ongoing_effects gemacht)
			if _player:
				_player.set_physics_process(true)
		_:
			pass

# Wendet Tick-Schaden oder -Heilung an (Brennen, HoT).
func _apply_tick_effect(effect_id: String, _effect_def: Dictionary, stack: Dictionary) -> void:
	match effect_id:
		"burning":
			# Brennen-Schaden: Basiswert aus status_effects.tres × Stack-Wert
			var base_dmg: int = _get_base_damage(effect_id)
			var actual_dmg: int = int(float(base_dmg) * float(stack.get("value", 1.0)))
			if _player:
				_player.take_damage(actual_dmg)
		"hot":
			# Heilung ueber Zeit: Basiswert × Stack-Wert
			var base_heal: int = _get_base_heal(effect_id)
			var actual_heal: int = int(float(base_heal) * float(stack.get("value", 1.0)))
			if _player:
				_player.heal(actual_heal)

# Wird aufgerufen wenn alle Stacks eines Effekts abgelaufen sind.
func _on_effect_expired(effect_id: String, effect_def: Dictionary) -> void:
	# Immunitat setzen falls konfiguriert
	var immunity: float = float(effect_def.get("immunity_after", 0.0))
	if immunity > 0.0:
		_immunity_timers[effect_id] = immunity

	_clear_immediate_effect(effect_id)

# =============================================================================
# REAKTIONEN
# =============================================================================

# Loest eine erkannte Reaktion aus: konsumiert Stacks, wendet Einmal-Effekt an.
func _trigger_reaction(reaction: Dictionary) -> void:
	var reaction_id: String = reaction.get("reaction_id", "")

	# Reaktions-Cooldown pruefen
	if _reaction_cooldown_timers.has(reaction_id) and _reaction_cooldown_timers[reaction_id] > 0.0:
		return

	# Cooldown setzen
	_reaction_cooldown_timers[reaction_id] = _reaction_cooldown_duration

	# Beteiligte Stacks konsumieren
	var consumed_effects: Array = reaction.get("consumed_effects", [])
	for eff_id in consumed_effects:
		remove_effect(eff_id)

	# Reaktionseffekt anwenden
	var pos: Vector2 = _player.global_position if _player else Vector2.ZERO
	reaction_triggered.emit(reaction_id, pos)

	match reaction_id:
		"steam_burst":
			# Knockback ~200px in eine zufaellige Richtung
			var knockback_dist: float = reaction.get("knockback_distance", 200.0)
			if _player:
				var dir: Vector2 = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
				_player.velocity = dir * knockback_dist / 0.2  # kurzer Impuls
		"conductivity":
			# Betaeubungs-Dauer verdoppeln und auf nahe Spieler springen
			_apply_conductivity_reaction(reaction)
		"meltdown":
			# Burst-Schaden durch Brennen-Tick
			if _player and _active_stacks.has("burning") and not _active_stacks["burning"].is_empty():
				var burst_mult: float = float(reaction.get("burst_multiplier", 2.0))
				var base_dmg: int = _get_base_damage("burning")
				_player.take_damage(int(float(base_dmg) * burst_mult))
		"panic":
			# Experimentell: zufaellige Bewegungsrichtungs-Drift fuer 2s
			if _player:
				var panic_dur: float = float(reaction.get("panic_duration", 2.0))
				if _player.has_method("set_panic_mode"):
					_player.set_panic_mode(panic_dur)

# Wendet Leitfaehigkeits-Reaktion an (Blitz springt auf nahe Spieler).
func _apply_conductivity_reaction(reaction: Dictionary) -> void:
	# Betaeubungs-Dauer auf diesem Spieler verdoppeln
	if _active_stacks.has("stun"):
		for stack in _active_stacks["stun"]:
			stack["timer"] *= 2.0

	# Kettenblitz auf nahe Spieler
	var chain_radius: float = float(reaction.get("chain_radius", 150.0))
	var chain_factor: float = float(reaction.get("chain_stun_factor", 0.5))
	if not _player:
		return
	var nearby: Array = get_tree().get_nodes_in_group("players")
	for other in nearby:
		if other == _player:
			continue
		if other.global_position.distance_to(_player.global_position) <= chain_radius:
			var other_sec: StatusEffectComponent = other.get_node_or_null("StatusEffectComponent")
			if other_sec:
				# Halbe Betaeubungsdauer
				var stun_def: Dictionary = _get_effect_def("stun")
				var half_duration: float = float(stun_def.get("duration", 0.6)) * chain_factor
				var stack_factor_val: float = float(stun_def.get("stack_factor", 0.5))
				var stack_val: float = 1.0
				if other_sec._active_stacks.has("stun"):
					stack_val = pow(stack_factor_val, other_sec._active_stacks["stun"].size())
				if not other_sec._active_stacks.has("stun"):
					other_sec._active_stacks["stun"] = []
				other_sec._active_stacks["stun"].append({"timer": half_duration, "value": stack_val, "tick_timer": 0.0, "source": -1})
				other_sec.effect_changed.emit("stun", other_sec._active_stacks["stun"].size())

# =============================================================================
# ANTI-FRUSTRATIONS-CAP
# =============================================================================

# Stellt sicher dass nie mehr als max_debuff_types verschiedene Effekt-Typen aktiv sind.
# Wenn das Cap ueberschritten wird, wird der aelteste Effekt-Typ entfernt.
func _enforce_debuff_cap(new_effect_id: String) -> void:
	if _active_stacks.has(new_effect_id):
		return  # Neuer Stack auf bestehendem Effekt – kein Cap-Problem

	var debuff_ids: Array[String] = _get_active_debuff_ids()
	if debuff_ids.size() < _max_debuff_types:
		return

	# Aeltesten Debuff bestimmen und entfernen (Stack mit kuerzester Timer-Restzeit = laeuft als naechstes ab)
	var oldest_id: String = debuff_ids[0]
	var oldest_timer: float = 999.0
	for eff_id in debuff_ids:
		if _active_stacks.has(eff_id) and not _active_stacks[eff_id].is_empty():
			var first_timer: float = float(_active_stacks[eff_id][0]["timer"])
			if first_timer < oldest_timer:
				oldest_timer = first_timer
				oldest_id = eff_id
	remove_effect(oldest_id)

# Gibt alle aktuell aktiven Debuff-Effekt-IDs zurueck (Soft-CC + Schadens-Debuffs).
func _get_active_debuff_ids() -> Array[String]:
	var result: Array[String] = []
	if not _effects_config:
		return result
	var effects: Dictionary = _effects_config.get("effects") if _effects_config.get("effects") else {}
	for eff_id in _active_stacks.keys():
		if effects.has(eff_id):
			var def: Dictionary = effects[eff_id]
			if def.get("is_soft_cc", false) or def.get("is_hard_cc", false) or _is_damage_debuff(eff_id):
				result.append(eff_id)
	return result

# Prueft ob ein Effekt ein Schadens-Debuff ist (fuer Cap-Zaehlung).
func _is_damage_debuff(effect_id: String) -> bool:
	return effect_id in ["burning", "armor_break", "blind"]

# =============================================================================
# HELPER
# =============================================================================

# Gibt die Effekt-Definition aus status_effects.tres zurueck.
func _get_effect_def(effect_id: String) -> Dictionary:
	if not _effects_config:
		return {}
	var effects: Dictionary = _effects_config.get("effects") if _effects_config.get("effects") else {}
	return effects.get(effect_id, {})

# Liest den Basis-Schaden pro Tick fuer einen Effekt (Brennen).
func _get_base_damage(effect_id: String) -> int:
	var def: Dictionary = _get_effect_def(effect_id)
	return int(def.get("base_damage_per_tick", 5))

# Liest die Basis-Heilung pro Tick (HoT).
func _get_base_heal(effect_id: String) -> int:
	var def: Dictionary = _get_effect_def(effect_id)
	return int(def.get("base_heal_per_tick", 8))

# =============================================================================
# SIGNAL-HANDLER
# =============================================================================

# Wird aufgerufen wenn der Spieler einen erfolgreichen Dodge macht.
# Entfernt alle Soft-CC-Stacks (Anti-Frustrations-Regel).
func _on_player_dodged() -> void:
	clear_soft_cc()
