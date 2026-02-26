# =============================================================================
# DATEINAME: target_system.gd
# ZWECK:     Verwaltet den Target-Lock fuer einen einzelnen Spieler.
#            Jeder Spieler hat eine eigene Instanz (kein AutoLoad).
#            Steuert: Ziel-Auswahl, Zielwechsel, LOS-Pruefung und
#            Sichtbarkeit des Target-Indicator-Rings.
#
#            Eingabe-Events (target_lock, target_prev, target_next) kommen
#            von player_input.gd und werden in _unhandled_input() verarbeitet.
#            Die eigentliche Tippen/Halten-Unterscheidung (< 200ms) wird hier
#            noch nicht implementiert – das ist Aufgabe von motion_input_parser.gd
#            in Phase 2A. Hier reagieren wir nur auf die finalen Action-Events.
#
# ABHAENGIG VON: line_of_sight.gd, player_input.gd, target_indicator.tscn,
#                player.tscn (Gruppe "players" fuer Spieler-Suche)
# =============================================================================

class_name TargetSystem
extends Node

# =============================================================================
# SIGNALE
# =============================================================================

# Wird gesendet wenn sich das Ziel aendert (oder der Lock verloren geht).
# Empfaenger: combo_chain.gd (Phase 2A), damage_system.gd (Phase 2D),
#             spell_system.gd (Phase 2B)
# new_target: Spieler-Node oder null wenn kein Ziel
signal target_changed(new_target: Node)

# Wird gesendet wenn LOS-Status sich aendert (relevant fuer damage_system.gd).
# has_los: true = Sicht frei, false = Terrain blockiert
signal los_changed(has_los: bool)

# =============================================================================
# EXPORTS
# =============================================================================

# Spieler-ID (0–3) des Besitzers dieses TargetSystem.
# Wird von player_spawner.gd (Phase 3B) oder player.gd gesetzt.
@export var player_id: int = 0

# Pfad zur target_indicator.tscn-Instanz die diesem Spieler gehoert.
# Alternativ: wird in _ready() automatisch instanziiert wenn nicht gesetzt.
@export var indicator_scene: PackedScene

# =============================================================================
# INTERNE ZUSTAENDE
# =============================================================================

# Aktuell gelocktes Ziel (null = kein Ziel)
var _current_target: Node = null

# Flag ob Sichtlinie zum Ziel frei ist (wird in _process aktualisiert)
var _has_los: bool = true

# Cooldown-Timer fuer Zielwechsel (0.2s lt. DESIGN.md)
var _switch_cooldown: float = 0.0

# Cooldown-Dauer fuer Zielwechsel in Sekunden
const TARGET_SWITCH_COOLDOWN: float = 0.2

# Instanz des Target-Indicator-Rings (folgt dem Ziel)
var _indicator: Node = null

# Ob der eigene Spieler aktuell blind ist (gesetzt von status_effect_component, Phase 2B)
# Wenn blind: kein neuer Auto-Lock, LOS-Raycast-Maske wird auf 0 gesetzt
var is_blinded: bool = false

# =============================================================================
# GODOT-LIFECYCLE
# =============================================================================

# _ready() initialisiert den Target-Indicator und registriert den Node in der Gruppe.
func _ready() -> void:
	# Target-Indicator instanziieren und als Child hinzufuegen
	# Der Indicator folgt dem Ziel via _process() – er ist kein HUD-Element, sondern in der Welt
	if indicator_scene:
		_indicator = indicator_scene.instantiate()
		# Indicator zum SceneTree hinzufuegen (als Child des uebergeordneten Spieler-Nodes)
		get_parent().add_child(_indicator)
		_indicator.visible = false  # Erst sichtbar wenn Ziel gelockt

	# In Gruppe registrieren damit andere Systeme alle TargetSystems finden koennen
	add_to_group("target_systems")

# _process(delta) wird jeden Frame aufgerufen.
# Aktualisiert: Cooldown, Indicator-Position, LOS-Status
func _process(delta: float) -> void:
	# Zielwechsel-Cooldown runterzaehlen
	if _switch_cooldown > 0.0:
		_switch_cooldown -= delta

	# Wenn kein Ziel: Indicator verstecken und beenden
	if not is_instance_valid(_current_target):
		if _current_target != null:
			# Ziel war gesetzt aber ist jetzt weg (z.B. Spieler tot) → aufraumen
			_clear_target()
		return

	# Indicator-Position auf Ziel aktualisieren
	if _indicator and _indicator.visible:
		_indicator.global_position = _current_target.global_position

	# LOS-Check ausfuehren (jeden Frame – Performance unkritisch bei 4 Spielern)
	_update_los()

# =============================================================================
# EINGABE-VERARBEITUNG
# =============================================================================

# _unhandled_input() verarbeitet Target-Aktionen die nicht von anderen Nodes
# konsumiert wurden (z.B. bei offenem Menü werden Events nicht hierher weitergeleitet).
func _unhandled_input(event: InputEvent) -> void:
	if is_blinded:
		return  # Blinder Spieler kann kein Ziel wechseln

	# Input-Action-Namen mit player_id-Prefix – z.B. "p0_target_lock", "p1_target_next"
	# (Naming-Konvention aus project.godot Stream E)
	var prefix: String = "p" + str(player_id) + "_"

	# Auto-Lock: naechsten Gegner automatisch als Ziel setzen
	if event.is_action_pressed(prefix + "target_lock"):
		_auto_lock_nearest()

	# Ziel im Uhrzeigersinn wechseln (rechte Schultertaste kurz tippen)
	elif event.is_action_pressed(prefix + "target_next"):
		_switch_target(1)

	# Ziel gegen Uhrzeigersinn wechseln (linke Schultertaste kurz tippen)
	elif event.is_action_pressed(prefix + "target_prev"):
		_switch_target(-1)

# =============================================================================
# OEFFENTLICHE API
# =============================================================================

# Gibt das aktuell gelockte Ziel zurueck (null = kein Ziel).
# Wird von spell_system.gd (Phase 2B) und damage_system.gd (Phase 2D) abgefragt.
func get_current_target() -> Node:
	return _current_target

# Gibt zurueck ob die Sichtlinie zum Ziel frei ist.
# Wird von damage_system.gd (Phase 2D) abgefragt vor Schadensanwendung.
func get_has_los() -> bool:
	return _has_los

# Setzt ein Ziel direkt (ohne Input) – wird von arena_state_manager.gd (Phase 3A)
# und bot_controller.gd (Phase 4G) genutzt.
func set_target(new_target: Node) -> void:
	_set_target(new_target)

# Entfernt den aktuellen Target-Lock (z.B. bei Spieler-Tod oder Runden-Ende).
func clear_target() -> void:
	_clear_target()

# =============================================================================
# INTERNE LOGIK
# =============================================================================

# Automatischer Lock auf den naechstgelegenen sichtbaren Gegner.
# Sortiert nach Distanz, bevorzugt Ziele mit freier LOS.
func _auto_lock_nearest() -> void:
	if is_blinded:
		return

	var candidates := _get_enemy_players()
	if candidates.is_empty():
		return

	var owner_node := get_parent()
	if not owner_node:
		return

	var best: Node = null
	var best_dist: float = INF

	for candidate in candidates:
		if not is_instance_valid(candidate):
			continue
		var dist: float = owner_node.global_position.distance_to(candidate.global_position)
		if dist < best_dist:
			best_dist = dist
			best = candidate

	if best:
		_set_target(best)

# Wechselt das Ziel in einer Richtung (direction: +1 = CW, -1 = CCW).
# Sortiert die Gegner nach Winkel relativ zum Besitzer und waehlt den naechsten.
# Cooldown: 0.2s damit schnelles Durchklicken nicht alle Ziele ueberlaeuft.
func _switch_target(direction: int) -> void:
	if _switch_cooldown > 0.0:
		return  # Noch im Cooldown

	var candidates := _get_enemy_players()
	if candidates.is_empty():
		return

	var owner_node := get_parent()
	if not owner_node:
		return

	# Alle Gegner nach Winkel zum Besitzer sortieren
	var owner_pos: Vector2 = owner_node.global_position
	candidates.sort_custom(func(a, b):
		var angle_a = owner_pos.angle_to_point(a.global_position)
		var angle_b = owner_pos.angle_to_point(b.global_position)
		return angle_a < angle_b
	)

	if candidates.is_empty():
		return

	# Index des aktuellen Ziels in der sortierten Liste finden
	var current_index: int = -1
	for i in range(candidates.size()):
		if candidates[i] == _current_target:
			current_index = i
			break

	# Naechsten Index in der gewuenschten Richtung berechnen (zyklisch)
	var next_index: int
	if current_index == -1:
		# Noch kein Ziel gelockt: erstes Element waehlen (bei CW) oder letztes (bei CCW)
		next_index = 0 if direction > 0 else candidates.size() - 1
	else:
		next_index = (current_index + direction) % candidates.size()
		# GDScript modulo kann negativ sein fuer negative Operanden
		if next_index < 0:
			next_index += candidates.size()

	_set_target(candidates[next_index])
	_switch_cooldown = TARGET_SWITCH_COOLDOWN

# Setzt ein neues Ziel und emittiert das target_changed-Signal.
func _set_target(new_target: Node) -> void:
	if _current_target == new_target:
		return  # Kein Wechsel noetig

	_current_target = new_target

	# Indicator sichtbar machen und zur Ziel-Position springen
	if _indicator:
		_indicator.visible = (new_target != null)
		if new_target and is_instance_valid(new_target):
			_indicator.global_position = new_target.global_position

			# Indicator-Farbe = Farbe des Angreifers (lt. DESIGN.md: HUD-Ring zeigt Angreifer-Farbe)
			# _indicator muss eine Methode set_color(color) bereitstellen
			if _indicator.has_method("set_color"):
				var owner_node := get_parent()
				if owner_node and owner_node.has_method("get_primary_color"):
					_indicator.set_color(owner_node.get_primary_color())

	target_changed.emit(new_target)

# Entfernt den Target-Lock und versteckt den Indicator.
func _clear_target() -> void:
	_current_target = null
	if _indicator:
		_indicator.visible = false
	target_changed.emit(null)

# Fuehrt den LOS-Check aus und emittiert los_changed wenn sich der Status aendert.
func _update_los() -> void:
	if not is_instance_valid(_current_target):
		return

	var owner_node := get_parent()
	if not owner_node or not owner_node.is_inside_tree():
		return

	# PhysicsDirectSpaceState2D fuer Raycasts benoetigt get_world_2d().direct_space_state
	# Dies geht nur in _physics_process oder wenn der Node im Baum ist
	var space_state := owner_node.get_world_2d().direct_space_state
	if not space_state:
		return

	# Angreifer und Ziel aus dem Raycast ausschliessen damit sie sich nicht selbst blockieren
	var exclude: Array = [owner_node, _current_target]
	var new_los: bool = LineOfSight.has_clear_los(
		owner_node.global_position,
		_current_target.global_position,
		space_state,
		exclude
	)

	# Signal nur emittieren wenn sich der Status geaendert hat (vermeidet Signal-Spam)
	if new_los != _has_los:
		_has_los = new_los
		los_changed.emit(_has_los)

# Gibt alle Spieler-Nodes zurueck die nicht der Besitzer dieses TargetSystem sind.
# Nutzt die Godot-Gruppen-API ("players") damit kein direkter Node-Referenz noetig ist.
func _get_enemy_players() -> Array:
	var owner_node := get_parent()
	var all_players := get_tree().get_nodes_in_group("players")
	var enemies: Array = []
	for p in all_players:
		if p != owner_node and is_instance_valid(p):
			enemies.append(p)
	return enemies
