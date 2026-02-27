# =============================================================================
# DATEINAME: tile.gd
# ZWECK:     Zustandsmaschine fuer einen einzelnen Arena-Tile.
#            Verwaltet die drei Zustaende INTACT, CRACKED und DESTROYED,
#            wechselt visuelle Darstellung und deaktiviert Kollision wenn
#            ein Tile zerstoert wird. Emittiert tile_state_changed-Signal
#            damit arena_grid.gd, item_system (Phase 2B) und
#            weapon_system (Phase 2C) reagieren koennen.
# ABHAENGIG VON: tile_config.tres, tile.tscn
#                (Nodes: TileColor, CrackLines, HoleGlow, CollisionShape2D)
# =============================================================================

class_name Tile
extends StaticBody2D

# =============================================================================
# SIGNALE
# =============================================================================

# Wird gesendet wenn sich der Zustand dieses Tiles aendert.
# Empfaenger: arena_grid.gd (Bookkeeping), item_system.gd (Drop-Trigger, Phase 2B),
#             weapon_system.gd (Material-Sammlung, Phase 2C)
# state: neuer TileState-Wert (INTACT=0, CRACKED=1, DESTROYED=2)
# grid_pos: Gitter-Position des Tiles als Vector2i (fuer schnellen Zugriff)
signal tile_state_changed(state: int, grid_pos: Vector2i)

# =============================================================================
# ENUMS
# =============================================================================

# Moegliche Zustaende eines Tiles.
# INTACT:    Volle Kollision, dunkle Obsidian-Farbe
# CRACKED:   Volle Kollision, Riss-Linien sichtbar (Warnung fuer Spieler)
# DESTROYED: Keine Kollision, Loch-Glow sichtbar (faellt man hindurch → Out-of-Bounds)
enum TileState { INTACT = 0, CRACKED = 1, DESTROYED = 2 }

# =============================================================================
# EXPORTS
# =============================================================================

# Gitter-Position dieses Tiles (Vector2i, z.B. Vector2i(5, 3)).
# Wird von arena_grid.gd beim Instanziieren gesetzt.
# Im tile_state_changed-Signal mitgegeben damit Empfaenger den Tile identifizieren koennen.
@export var grid_pos: Vector2i = Vector2i.ZERO

# =============================================================================
# NODE-REFERENZEN
# =============================================================================

# Haupt-Farbflaeche des Tiles (sichtbar in INTACT und CRACKED)
@onready var tile_color: ColorRect = $TileColor

# Container fuer alle Riss-Line2D-Nodes (sichtbar nur in CRACKED)
@onready var crack_lines: Node2D = $CrackLines

# Orangeroter Loch-Glow (sichtbar nur in DESTROYED)
@onready var hole_glow: ColorRect = $HoleGlow

# Kollisionsform – wird bei DESTROYED deaktiviert damit Spieler hindurchfallen
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

# =============================================================================
# INTERNE ZUSTAENDE
# =============================================================================

# Aktuelle HP dieses Tiles. Startet bei tile_max_hp aus tile_config.tres.
var _hp: int = 60

# Maximale HP (aus tile_config.tres)
var _max_hp: int = 60

# HP-Schwellwert fuer Uebergang INTACT → CRACKED
var _crack_threshold: int = 30

# Aktueller Zustand des Tiles
var _state: TileState = TileState.INTACT

# Konfiguration aus tile_config.tres (geladen in _ready)
var _config: Resource

# Pulsier-Phase fuer den Loch-Glow (Sinus-basiert, laeuft in _process)
var _pulse_phase: float = 0.0

# =============================================================================
# GODOT-LIFECYCLE
# =============================================================================

# _ready() laedt Konfiguration und initialisiert den Tile im INTACT-Zustand.
func _ready() -> void:
	_config = load("res://resources/tile_config.tres")

	if _config:
		_max_hp = _config.get("tile_max_hp") if _config.get("tile_max_hp") != null else 60
		_crack_threshold = _config.get("tile_crack_threshold") if _config.get("tile_crack_threshold") != null else 30

	_hp = _max_hp
	_apply_state(TileState.INTACT)

# _process(delta) laeuft jeden Render-Frame.
# Nur aktiv wenn der Tile DESTROYED ist (Loch-Glow-Pulsieren).
func _process(delta: float) -> void:
	if _state != TileState.DESTROYED:
		return

	# Sinus-Pulsieren des Loch-Glows – erzeugt lebendige Gefahren-Wahrnehmung
	if _config:
		var hz: float = _config.get("hole_glow_pulse_hz") if _config.get("hole_glow_pulse_hz") != null else 1.5
		var base_alpha: float = _config.get("hole_glow_alpha") if _config.get("hole_glow_alpha") != null else 0.8
		_pulse_phase += delta * hz * TAU  # TAU = 2*PI
		var pulsed_alpha: float = base_alpha * (0.75 + 0.25 * sin(_pulse_phase))
		if hole_glow:
			hole_glow.modulate.a = pulsed_alpha

# =============================================================================
# OEFFENTLICHE API
# =============================================================================

# Wendet Schaden auf diesen Tile an und loest ggf. Zustandswechsel aus.
# Wird von spell_projectile.gd (Phase 2B) und arena_grid.gd aufgerufen.
# amount: Schadenspunkte (positiv = Schaden)
func take_damage(amount: int) -> void:
	# Zerstoerte Tiles koennen keinen weiteren Schaden nehmen
	if _state == TileState.DESTROYED:
		return

	_hp = clamp(_hp - amount, 0, _max_hp)

	# Zustandsuebergaenge pruefen
	if _hp <= 0 and _state != TileState.DESTROYED:
		_set_state(TileState.DESTROYED)
	elif _hp <= _crack_threshold and _state == TileState.INTACT:
		_set_state(TileState.CRACKED)

# Gibt den aktuellen Zustand zurueck.
# Wird von arena_grid.gd fuer das Grid-Dictionary genutzt.
func get_state() -> TileState:
	return _state

# Gibt die aktuellen HP zurueck (fuer Debugging und Tests).
func get_hp() -> int:
	return _hp

# Setzt den Tile zurueck auf INTACT mit vollen HP.
# Wird von arena_grid.gd genutzt wenn Runden-Reset noetig ist.
func reset() -> void:
	_hp = _max_hp
	_apply_state(TileState.INTACT)

# =============================================================================
# INTERNE ZUSTANDSVERWALTUNG
# =============================================================================

# Setzt neuen Zustand, wendet visuelle Aenderungen an und emittiert Signal.
func _set_state(new_state: TileState) -> void:
	if _state == new_state:
		return
	_state = new_state
	_apply_state(new_state)
	tile_state_changed.emit(int(new_state), grid_pos)

	# Item-Drop-Trigger (Phase 2B): bei DESTROYED item_system.try_drop() aufrufen.
	# ItemSystem ist ein AutoLoad-Node (oder wird in main_arena.gd gesucht).
	if new_state == TileState.DESTROYED:
		var item_system: Node = get_tree().current_scene.get_node_or_null("ItemSystem")
		if item_system and item_system.has_method("try_drop"):
			item_system.call("try_drop", global_position)

# Wendet den visuellen Zustand an (Farben, sichtbare Nodes, Kollision).
func _apply_state(new_state: TileState) -> void:
	match new_state:
		TileState.INTACT:
			# Voller Tile: Farbe sichtbar, keine Risse, keine Loecher, Kollision aktiv
			if tile_color:
				tile_color.visible = true
				tile_color.color = _get_color("color_intact", Color(0.102, 0.102, 0.18, 1.0))
			if crack_lines:
				crack_lines.visible = false
			if hole_glow:
				hole_glow.visible = false
			_set_collision(true)
			set_process(false)  # Kein _process noetig im INTACT-Zustand

		TileState.CRACKED:
			# Gerissener Tile: gleiche Grundfarbe, Riss-Linien sichtbar, Kollision aktiv
			if tile_color:
				tile_color.visible = true
				tile_color.color = _get_color("color_cracked_base", Color(0.102, 0.102, 0.18, 1.0))
			if crack_lines:
				crack_lines.visible = true
			if hole_glow:
				hole_glow.visible = false
			_set_collision(true)
			set_process(false)  # Kein Pulsieren im CRACKED-Zustand

		TileState.DESTROYED:
			# Zerstoerter Tile: Flaeche unsichtbar, Loch-Glow sichtbar, Kollision deaktiviert
			if tile_color:
				tile_color.visible = false
			if crack_lines:
				crack_lines.visible = false
			if hole_glow:
				hole_glow.visible = true
				hole_glow.color = _get_color("color_hole_glow", Color(1.0, 0.267, 0.0, 0.85))
			# call_deferred ist Pflicht: CollisionShape2D darf nicht waehrend _physics_process
			# direkt deaktiviert werden – Godot verbietet das und wirft einen Fehler.
			collision_shape.call_deferred("set_disabled", true)
			set_process(true)  # _process fuer Loch-Glow-Pulsieren aktivieren

# Aktiviert oder deaktiviert die Kollisionsform des Tiles.
# Fuer DESTROYED: call_deferred verwenden (nicht direkt in Physics-Callbacks aufrufen).
func _set_collision(enabled: bool) -> void:
	if collision_shape:
		if enabled:
			# Direkt setzen ist sicher ausserhalb von _physics_process
			collision_shape.set_disabled(not enabled)
		# Deaktivieren immer via call_deferred – sicher auch wenn unerwartet in Physics-Callback

# Liest eine Farbe aus tile_config.tres oder gibt den Fallback-Wert zurueck.
# key: Property-Name in tile_config.tres (z.B. "color_intact")
# fallback: Farbe die genutzt wird wenn die Resource nicht geladen ist
func _get_color(key: String, fallback: Color) -> Color:
	if not _config:
		return fallback
	var raw = _config.get(key)
	if raw == null:
		return fallback
	# tile_config.tres speichert Farben als Hex-String z.B. "#1A1A2E"
	if raw is String:
		return Color(raw)
	if raw is Color:
		return raw
	return fallback

# =============================================================================
# TESTFAELLE (fuer manuelle lokale Pruefung)
# =============================================================================
# 1. Tile startet mit HP=60, Zustand INTACT, Kollision aktiv
# 2. take_damage(31): HP=29, Zustand wechselt zu CRACKED, crack_lines sichtbar
# 3. take_damage(29): HP=0, Zustand wechselt zu DESTROYED, Kollision deaktiviert
# 4. tile_state_changed-Signal wird bei jedem Zustandswechsel gefeuert
# 5. reset(): HP=60, Zustand INTACT, Kollision wieder aktiv
# 6. take_damage() auf DESTROYED-Tile: keine weitere Reaktion
# 7. Loch-Glow pulsiert via _process() nach DESTROYED-Wechsel
