# =============================================================================
# DATEINAME: spell_system.gd
# ZWECK:     Spell-Verwaltung und Casting pro Spieler. Hoert auf
#            combo_recognized-Signale von motion_input_parser.gd und wirkt
#            den zugehoerigen Spell (Modus L/R/B). Verwaltet den Magie-Timeout-
#            Zyklus und emittiert magic_changed fuer die Gauge-HUD.
#            Kein Wert hardcodiert – alle Werte aus spell_definitions.tres
#            und spell_values.tres.
# ABHAENGIG VON: spell_definitions.tres, spell_values.tres, combo_definitions.tres,
#                hook_registry.gd (ModLoader-Hook), spell_projectile.gd,
#                status_effect_component.gd (auf Ziel-Spieler),
#                motion_input_parser.gd (emittiert combo_recognized)
# =============================================================================

class_name SpellSystem
extends Node

# =============================================================================
# SIGNALE
# =============================================================================

# Wird gesendet wenn sich der Magie-Fuellstand aendert (0.0 = leer, 1.0 = voll).
# magic_gauge_ui.gd hoert auf dieses Signal und aktualisiert den Glow-Indikator.
signal magic_changed(current_ratio: float)

# Wird gesendet wenn ein Spell erfolgreich gewirkt wird.
# sound_system und vfx_system koennen dieses Signal hoeren.
signal spell_cast(spell_id: String, player_id: int, target_pos: Vector2)

# Wird gesendet wenn Magie aufgebraucht ist (fuer HUD-Feedback).
signal magic_depleted()

# Wird gesendet wenn Magie wieder vollstaendig regeneriert ist.
signal magic_recharged()

# =============================================================================
# EXPORTS
# =============================================================================

# Spieler-Index dieses Systems (wird automatisch vom Player-Node gesetzt).
@export var player_id: int = 0

# NodePath zum MotionInputParser-Sibling (wird automatisch verbunden).
@export var motion_input_parser_path: NodePath

# =============================================================================
# INTERNE ZUSTAENDE
# =============================================================================

# Geladene Spell-Definitionen (Element-Kodierung, Kombinations-Tabelle)
var _spell_definitions: Resource

# Geladene Spell-Werte (Schaden, Reichweite, Cooldown, Magie-Timeout)
var _spell_values: Resource

# Vorgefertigtes Projektil-Prefab (fuer Performance in _ready() laden)
var _projectile_scene: PackedScene

# Magie ist aktiv (Modus L/R/B verfuegbar) oder erschoepft
var _magic_active: bool = true

# Aktueller Magie-Fuellstand (0.0–1.0)
var _magic_ratio: float = 1.0

# Wie lange Magie noch verfuegbar ist (zaehlt herunter wenn aktiv)
var _magic_active_timer: float = 0.0

# Wie lange bis Magie wieder voll ist (zaehlt herunter wenn erschoepft)
var _magic_regen_timer: float = 0.0

# Konfigurierbare Magie-Werte (aus spell_values.tres)
var _magic_active_time: float = 8.0
var _magic_regen_time: float = 5.0
var _magic_regen_trigger: String = "passive"

# Spell-Cooldown-Timer: { "fireball": 0.8 (verbleibend), ... }
var _cooldown_timers: Dictionary = {}

# Referenz auf HookRegistry-AutoLoad fuer Mod-Hooks
var _hook_registry: Node

# Referenz auf den MotionInputParser dieses Spielers
var _motion_parser: MotionInputParser

# Referenz auf den Player-Owner (fuer Positions- und Richtungsinfo)
var _player: Player

# Ob der Overcharge-Item-Effekt aktiv ist (naechster Spell 2x Schaden)
var _overcharge_active: bool = false

# =============================================================================
# LIFECYCLE
# =============================================================================

# Laedt Ressourcen, verbindet Signale und praelaedt Projektil-Scene.
func _ready() -> void:
	_spell_definitions = load("res://resources/spell_definitions.tres")
	_spell_values = load("res://resources/spell_values.tres")

	if _spell_values:
		_magic_active_time = float(_spell_values.get("magic_active_time") if _spell_values.get("magic_active_time") != null else 8.0)
		_magic_regen_time = float(_spell_values.get("magic_regen_time") if _spell_values.get("magic_regen_time") != null else 5.0)
		_magic_regen_trigger = str(_spell_values.get("magic_regen_trigger") if _spell_values.get("magic_regen_trigger") != null else "passive")

	_magic_active_timer = _magic_active_time

	# Projektil-Szene voraufladen fuer bessere Performance beim ersten Cast
	if ResourceLoader.exists("res://scenes/spell_projectile.tscn"):
		_projectile_scene = load("res://scenes/spell_projectile.tscn")

	# HookRegistry holen (AutoLoad)
	_hook_registry = get_node_or_null("/root/HookRegistry")

	# Spieler-Owner holen
	_player = get_parent() as Player

	# MotionInputParser verbinden
	if motion_input_parser_path != NodePath():
		_motion_parser = get_node_or_null(motion_input_parser_path) as MotionInputParser
	else:
		# Sibling-Suche als Fallback
		_motion_parser = get_parent().get_node_or_null("MotionInputParser") as MotionInputParser

	if _motion_parser:
		_motion_parser.combo_recognized.connect(_on_combo_recognized)

# Verwaltet Magie-Timer und Spell-Cooldowns.
func _process(delta: float) -> void:
	_tick_magic_timer(delta)
	_tick_cooldowns(delta)

# =============================================================================
# OEFFENTLICHE API
# =============================================================================

# Aktiviert Overcharge-Modus (naechster Spell 2x Schaden).
# Wird von item_system.gd aufgerufen wenn "overcharge"-Item aktiv ist.
func activate_overcharge() -> void:
	_overcharge_active = true

# Deaktiviert Overcharge-Modus.
func deactivate_overcharge() -> void:
	_overcharge_active = false

# Gibt zurueck ob Magie aktuell verfuegbar ist.
func is_magic_available() -> bool:
	return _magic_active

# Registriert einen Waffen-Treffer fuer Magie-Regeneration (on_hit-Trigger).
# Wird von damage_system.gd aufgerufen wenn der Spieler einen Treffer landet.
func on_weapon_hit() -> void:
	if _magic_regen_trigger in ["on_hit", "both"] and not _magic_active:
		# Treffer beschleunigt Regeneration
		_magic_regen_timer = max(0.0, _magic_regen_timer - (_magic_regen_time * 0.2))

# =============================================================================
# COMBO-HANDLING
# =============================================================================

# Wird aufgerufen wenn motion_input_parser.gd eine gueltige Combo erkennt.
# combo_name: Spell-ID oder Modus-L-Sequenz ("mode_l:UP,DOWN" o.ae.)
# mode: ComboMode-Enum (1=MODE_L, 2=MODE_R, 3=MODE_B)
func _on_combo_recognized(combo_name: String, mode: int) -> void:
	# Magie-Timeout pruefen – Eingabe verfaellt lautlos wenn keine Magie
	if not _magic_active:
		return

	# Spell-ID bestimmen
	var spell_id: String = _resolve_spell_id(combo_name, mode)
	if spell_id.is_empty():
		return

	# Cooldown pruefen
	if _cooldown_timers.has(spell_id) and _cooldown_timers[spell_id] > 0.0:
		return

	_cast_spell(spell_id)

# Ermittelt die konkrete Spell-ID aus Combo-Name und Modus.
func _resolve_spell_id(combo_name: String, mode: int) -> String:
	# Modus L: combo_name = "mode_l:DIR1,DIR2" – aus Kombinations-Tabelle nachschlagen
	if mode == 1 and combo_name.begins_with("mode_l:"):
		return _resolve_mode_l_spell(combo_name.substr(7))

	# Modus R und B: combo_name ist direkt die Spell-ID (aus combo_definitions.tres)
	return combo_name

# Loest Modus-L-Spell auf: zwei Richtungs-Strings → Element-IDs → Kombinations-Tabelle.
func _resolve_mode_l_spell(direction_sequence: String) -> String:
	if not _spell_definitions:
		return ""

	var dirs: PackedStringArray = direction_sequence.split(",")
	if dirs.size() < 2:
		return ""

	# Richtung → Element (aus element_by_direction in spell_definitions.tres)
	var elem_map: Dictionary = _spell_definitions.get("element_by_direction") if _spell_definitions.get("element_by_direction") else {}
	var elem_a: String = str(elem_map.get(dirs[0], ""))
	var elem_b: String = str(elem_map.get(dirs[1], ""))

	if elem_a.is_empty() or elem_b.is_empty():
		return ""

	# Reihenfolge-unabhaengiger Key: alphabetisch sortiert
	var sorted_key: String = _make_combination_key(elem_a, elem_b)
	var combo_table: Dictionary = _spell_definitions.get("combination_table") if _spell_definitions.get("combination_table") else {}
	return str(combo_table.get(sorted_key, ""))

# Erstellt einen reihenfolge-unabhaengigen Kombinationsschluessel.
func _make_combination_key(elem_a: String, elem_b: String) -> String:
	var items: Array[String] = [elem_a, elem_b]
	items.sort()
	return items[0] + "+" + items[1]

# =============================================================================
# CASTING
# =============================================================================

# Fuehrt den eigentlichen Spell-Cast durch.
func _cast_spell(spell_id: String) -> void:
	if not _spell_values:
		return

	var spell_vals: Dictionary = _spell_values.get("spell_values") if _spell_values.get("spell_values") else {}
	var spell_data: Dictionary = spell_vals.get(spell_id, {})
	if spell_data.is_empty():
		push_warning("SpellSystem: unbekannte Spell-ID '%s'" % spell_id)
		return

	# Mod-Hook vor Casting aufrufen (Mods koennen Spell-Daten modifizieren)
	if _hook_registry and _hook_registry.has_method("run_hook"):
		var hook_data: Dictionary = {"spell_id": spell_id, "player_id": player_id, "spell_data": spell_data}
		_hook_registry.run_hook("spell_effect_hook", hook_data)
		spell_data = hook_data.get("spell_data", spell_data)

	# Overcharge-Multiplikator anwenden
	var damage_mult: float = 1.0
	if _overcharge_active:
		damage_mult = 2.0
		_overcharge_active = false

	# Cooldown starten
	var cooldown: float = float(spell_data.get("cooldown", 1.0))
	_cooldown_timers[spell_id] = cooldown

	# Magie-Verbrauch: Aktivzeit reduzieren
	_magic_active_timer -= cooldown * 0.5

	# Ziel-Position fuer Spell bestimmen
	var cast_pos: Vector2 = _player.global_position if _player else Vector2.ZERO
	var cast_dir: Vector2 = _get_aim_direction()
	var target_pos: Vector2 = cast_pos + cast_dir * float(spell_data.get("range", 400))

	# Spell-Effekt anwenden
	_apply_spell_effect(spell_id, spell_data, cast_pos, cast_dir, target_pos, damage_mult)

	spell_cast.emit(spell_id, player_id, target_pos)

# Wendet den Spell-Effekt an (Projektil, AoE, Teleport, Shield, etc.)
func _apply_spell_effect(spell_id: String, spell_data: Dictionary, cast_pos: Vector2, cast_dir: Vector2, target_pos: Vector2, damage_mult: float) -> void:
	var spell_speed: float = float(spell_data.get("speed", 0))
	var aoe_radius: float = float(spell_data.get("aoe_radius", 0))
	var damage_min: int = int(float(spell_data.get("damage_min", 0)) * damage_mult)
	var damage_max: int = int(float(spell_data.get("damage_max", 0)) * damage_mult)
	var applies_wet: bool = bool(spell_data.get("applies_wet", false))

	match spell_id:
		"ice_shield":
			# Defensiv-Spell: Schild auf dem Spieler aktivieren
			if _player and _player.has_method("activate_shield"):
				_player.activate_shield()

		"shadow_jump":
			# Teleport in Blickrichtung
			var range_px: float = float(spell_data.get("range", 200))
			if _player:
				_player.global_position += cast_dir * range_px

		"mirror_clone":
			# Decoy-Klon an Position des Spielers spawnen
			_spawn_mirror_clone(cast_pos)

		"heal_field":
			# Heilfeld-AoE auf dem Boden
			_apply_aoe_effect(cast_pos, aoe_radius, "hot", applies_wet)

		"steam_cloud":
			# Sichtblocker-AoE (kein Schaden, macht alle NASS)
			_apply_aoe_effect(cast_pos, aoe_radius, "", applies_wet)

		"seismic_pulse", "earth_stomp":
			# AoE-Schadens-Spell + Tile-Zerstoerung
			_apply_aoe_damage(cast_pos, aoe_radius, damage_min, damage_max)
			_destroy_tiles_in_radius(cast_pos, aoe_radius)

		"frostwall":
			# Terrain-Blockade erstellen
			_create_frostwall(cast_pos, cast_dir)

		_:
			# Standard: Projektil abschiessen (fireball, plasmabolt, lightning_strike, light_beam)
			if spell_speed > 0.0 or damage_min > 0:
				_spawn_projectile(spell_id, cast_pos, cast_dir, spell_data, damage_min, damage_max, applies_wet)

# Schiesst ein Projektil in die Zielrichtung.
func _spawn_projectile(spell_id: String, cast_pos: Vector2, direction: Vector2, spell_data: Dictionary, damage_min: int, damage_max: int, applies_wet: bool) -> void:
	if not _projectile_scene:
		return

	var projectile: SpellProjectile = _projectile_scene.instantiate() as SpellProjectile
	if not projectile:
		return

	# Projektil-Parameter setzen
	projectile.global_position = cast_pos + direction * 32.0  # leicht vor dem Spieler starten
	projectile.spell_id = spell_id
	projectile.direction = direction
	projectile.speed = float(spell_data.get("speed", 450))
	projectile.max_range = float(spell_data.get("range", 600))
	projectile.damage_min = damage_min
	projectile.damage_max = damage_max
	projectile.applies_wet = applies_wet
	projectile.caster_player_id = player_id

	# Element-Effekt fuer Statuseffekt-Anwendung bestimmen
	if _spell_definitions:
		var elem_effects: Dictionary = _spell_definitions.get("element_primary_effect") if _spell_definitions.get("element_primary_effect") else {}
		# Spell-ID → Element → Effekt
		var spell_element: String = _get_spell_element(spell_id)
		if not spell_element.is_empty():
			projectile.status_effect_id = str(elem_effects.get(spell_element, ""))

	get_tree().current_scene.add_child(projectile)

# Wendet AoE-Schaden auf alle Spieler in Radius an.
func _apply_aoe_damage(center: Vector2, radius: float, damage_min: int, damage_max: int) -> void:
	if radius <= 0.0:
		return
	var players: Array = get_tree().get_nodes_in_group("players")
	for p in players:
		if p == _player:
			continue
		if p.global_position.distance_to(center) <= radius:
			if p.has_method("take_damage"):
				var dmg: int = randi_range(damage_min, max(damage_min, damage_max))
				p.take_damage(dmg)

# Wendet einen AoE-Statuseffekt auf alle Spieler in Radius an.
func _apply_aoe_effect(center: Vector2, radius: float, effect_id: String, applies_wet: bool) -> void:
	if radius <= 0.0:
		return
	var players: Array = get_tree().get_nodes_in_group("players")
	for p in players:
		if p.global_position.distance_to(center) <= radius:
			var sec: StatusEffectComponent = p.get_node_or_null("StatusEffectComponent") as StatusEffectComponent
			if sec:
				if not effect_id.is_empty():
					sec.add_effect(effect_id, player_id)
				if applies_wet:
					sec.add_effect("wet", player_id)

# Zerstoert alle Tiles in einem Radius (seismic_pulse, earth_stomp).
func _destroy_tiles_in_radius(center: Vector2, radius: float) -> void:
	var arena_grid: Node = get_tree().current_scene.get_node_or_null("ArenaGrid")
	if arena_grid and arena_grid.has_method("damage_tiles_in_radius"):
		arena_grid.damage_tiles_in_radius(center, radius, 999)  # Instant-Zerstoerung

# Spawnt einen Spiegelklon (Platzhalter-ColorRect als Decoy).
func _spawn_mirror_clone(position: Vector2) -> void:
	# Einfacher Decoy: ColorRect fuer 3 Sekunden
	var clone: ColorRect = ColorRect.new()
	clone.size = Vector2(24, 24)
	clone.position = position - Vector2(12, 12)
	if _player:
		clone.color = _player.color_rect.color if _player.has_node("ColorRect") else Color.GRAY
	clone.color.a = 0.6
	get_tree().current_scene.add_child(clone)

	# Nach 3 Sekunden entfernen
	var tween: Tween = get_tree().create_tween()
	tween.tween_interval(3.0)
	tween.tween_callback(clone.queue_free)

# Erstellt eine Frostwall (Platzhalter-Kollisionsblock).
func _create_frostwall(position: Vector2, direction: Vector2) -> void:
	var wall_pos: Vector2 = position + direction * 80.0
	var wall: StaticBody2D = StaticBody2D.new()
	var shape_node: CollisionShape2D = CollisionShape2D.new()
	var rect_shape: RectangleShape2D = RectangleShape2D.new()
	rect_shape.size = Vector2(64, 16)
	shape_node.shape = rect_shape
	wall.global_position = wall_pos

	var visual: ColorRect = ColorRect.new()
	visual.size = Vector2(64, 16)
	visual.position = Vector2(-32, -8)
	visual.color = Color(0.267, 0.667, 1.0, 0.8)

	wall.add_child(shape_node)
	wall.add_child(visual)
	get_tree().current_scene.add_child(wall)

	# Nach 3 Sekunden entfernen
	var tween: Tween = get_tree().create_tween()
	tween.tween_interval(3.0)
	tween.tween_callback(wall.queue_free)

# =============================================================================
# MAGIE-TIMER
# =============================================================================

# Tickt den Magie-Aktiv/Regen-Zyklus.
func _tick_magic_timer(delta: float) -> void:
	if _magic_active:
		_magic_active_timer -= delta
		if _magic_active_timer <= 0.0:
			_magic_active = false
			_magic_active_timer = 0.0
			_magic_regen_timer = _magic_regen_time
			_magic_ratio = 0.0
			magic_changed.emit(0.0)
			magic_depleted.emit()
		else:
			_magic_ratio = _magic_active_timer / _magic_active_time
			magic_changed.emit(_magic_ratio)
	else:
		# Passive Regeneration (wenn konfiguriert)
		if _magic_regen_trigger in ["passive", "both"]:
			_magic_regen_timer -= delta

		if _magic_regen_timer <= 0.0:
			_magic_active = true
			_magic_active_timer = _magic_active_time
			_magic_ratio = 1.0
			magic_changed.emit(1.0)
			magic_recharged.emit()
		else:
			# Regen-Fortschritt als negativen Ratio ausgeben (0.0 = leer, 1.0 = fast voll)
			_magic_ratio = 1.0 - (_magic_regen_timer / _magic_regen_time)
			magic_changed.emit(_magic_ratio)

# Reduziert alle aktiven Spell-Cooldown-Timer.
func _tick_cooldowns(delta: float) -> void:
	for spell_id in _cooldown_timers.keys():
		_cooldown_timers[spell_id] = max(0.0, _cooldown_timers[spell_id] - delta)

# =============================================================================
# HELPER
# =============================================================================

# Gibt die Zielrichtung des Spielers zurueck (nach letzter Bewegungsrichtung).
func _get_aim_direction() -> Vector2:
	if not _player:
		return Vector2.RIGHT

	# Aktive Bewegungsrichtung bevorzugen, sonst zuletzt gespeicherte
	var vel: Vector2 = _player.velocity
	if vel.length() > 10.0:
		return vel.normalized()

	# Fallback: Richtung zum gelockten Ziel (wird in Phase 3C implementiert)
	return Vector2.RIGHT

# Bestimmt das Element eines Spells (fuer Statuseffekt-Mapping).
func _get_spell_element(spell_id: String) -> String:
	match spell_id:
		"fireball":
			return "fire"
		"ice_shield", "frostwall":
			return "ice"
		"lightning_strike":
			return "lightning"
		"earth_stomp", "seismic_pulse":
			return "earth"
		"shadow_jump", "mirror_clone":
			return "shadow"
		"light_beam", "heal_field":
			return "light"
	return ""
