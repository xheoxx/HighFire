# =============================================================================
# DATEINAME: arena_grid.gd
# ZWECK:     Verwaltet das 32×32-Tile-Raster der Arena.
#            Instanziiert alle Tile-Nodes aus tile.tscn, positioniert sie
#            relativ zur Arena-Mitte (0,0) und stellt O(1)-Zugriff via
#            Vector2i-Index bereit.
#            Leitet tile_state_changed-Signale weiter, damit uebergeordnete
#            Systeme (item_system in Phase 2B, weapon_system in Phase 2C)
#            auf Tile-Zerstoerung reagieren koennen.
# ABHAENGIG VON: tile.tscn, tile.gd, arena_config.tres (optional – Spawn-Positionen)
# =============================================================================

class_name ArenaGrid
extends Node2D

# =============================================================================
# SIGNALE
# =============================================================================

# Wird weitergeleitet wenn sich ein Tile-Zustand aendert.
# Empfaenger: item_system.gd (Phase 2B), weapon_system.gd (Phase 2C),
#             arena_state_manager.gd (Phase 3A)
# state:    neuer TileState-Wert (0=INTACT, 1=CRACKED, 2=DESTROYED)
# grid_pos: Gitter-Position des veraenderten Tiles als Vector2i
signal tile_state_changed(state: int, grid_pos: Vector2i)

# =============================================================================
# KONFIGURATION
# =============================================================================

# Anzahl Spalten (X-Richtung) des Rasters
const GRID_COLS: int = 32

# Anzahl Zeilen (Y-Richtung) des Rasters
const GRID_ROWS: int = 32

# Abstand zwischen Tile-Mittelpunkten in Pixeln (Tile selbst ist 30×30, 1px Luft rundherum)
const TILE_SIZE: int = 32

# Pfad zur Tile-Szene (vorgefertigte Szene mit StaticBody2D, CollisionShape2D, ColorRect etc.)
const TILE_SCENE_PATH: String = "res://scenes/tile.tscn"

# =============================================================================
# EXPORTS
# =============================================================================

# Optional: Tile-Szene kann via Editor/Instanz gesetzt werden (statt hardcoded TILE_SCENE_PATH).
# Wenn nicht gesetzt, wird automatisch TILE_SCENE_PATH geladen.
@export var tile_scene: PackedScene = null

# =============================================================================
# INTERNE ZUSTAENDE
# =============================================================================

# Dictionary fuer O(1)-Zugriff: Vector2i(col, row) → Tile-Node
# Beispiel: _tiles[Vector2i(0, 0)] = oberster linker Tile
var _tiles: Dictionary = {}

# Vorgeladene Tile-Szene (preload statt load() fuer Performance)
var _tile_scene: PackedScene

# =============================================================================
# GODOT-LIFECYCLE
# =============================================================================

# _ready() wird aufgerufen wenn der Node in den SceneTree eingehaengt wurde.
# Hier wird das gesamte Grid aufgebaut.
func _ready() -> void:
	# Tile-Szene vorladen – wenn über @export gesetzt, das nutzen, sonst TILE_SCENE_PATH laden
	if tile_scene:
		_tile_scene = tile_scene
	else:
		_tile_scene = load(TILE_SCENE_PATH)
	
	if not _tile_scene:
		push_error("ArenaGrid: Tile-Szene nicht gefunden unter " + TILE_SCENE_PATH)
		return

	_build_grid()

# =============================================================================
# GRID-AUFBAU
# =============================================================================

# Erstellt alle 1024 Tile-Nodes und positioniert sie relativ zur Arena-Mitte.
# Gitter-Ursprung: Vector2i(0,0) = oben links.
# Welt-Position (0,0) = Arena-Mitte (Mittelpunkt des gesamten Grids).
func _build_grid() -> void:
	# Offset damit das Grid um (0,0) zentriert ist.
	# Gesamtbreite = 32 × 32px = 1024px → Halbbreite = 512px, aber
	# wir rechnen bis zur Mitte des ersten bzw. letzten Tiles:
	# erster Tile-Mittelpunkt: -(GRID_COLS/2 - 0.5) × TILE_SIZE
	var half_w: float = (GRID_COLS - 1) * 0.5 * TILE_SIZE
	var half_h: float = (GRID_ROWS - 1) * 0.5 * TILE_SIZE

	for row in range(GRID_ROWS):
		for col in range(GRID_COLS):
			var grid_pos := Vector2i(col, row)

			# Welt-Position des Tile-Mittelpunkts (relativ zu ArenaGrid-Node)
			var world_x: float = col * TILE_SIZE - half_w
			var world_y: float = row * TILE_SIZE - half_h

			var tile: Tile = _tile_scene.instantiate()
			tile.position = Vector2(world_x, world_y)

			# grid_pos ist @export auf Tile – wird gesetzt damit das Signal
			# die Gitter-Koordinate mitliefert (kein Lookup-Overhead zur Laufzeit)
			tile.grid_pos = grid_pos

			# Signal des Tiles mit eigenem weiterleitenden Callable verbinden.
			# Lambda-Closure fuer forward: gibt state und grid_pos weiter.
			# call_deferred nicht noetig – Signal-Verbindung ist kein Physics-Callback.
			tile.tile_state_changed.connect(_on_tile_state_changed)

			add_child(tile)
			_tiles[grid_pos] = tile

# =============================================================================
# OEFFENTLICHE API
# =============================================================================

# Gibt den Tile an der angegebenen Gitter-Position zurueck.
# Gibt null zurueck wenn die Position ausserhalb des Rasters liegt.
# Laufzeit: O(1) – Dictionary-Lookup
# Beispiel: var t = arena_grid.get_tile(Vector2i(5, 3))
func get_tile(grid_pos: Vector2i) -> Tile:
	return _tiles.get(grid_pos, null)

# Gibt den Tile an der angegebenen Welt-Position zurueck.
# Rechnet Welt-Koordinaten in Gitter-Koordinaten um und macht einen Dictionary-Lookup.
# Wird von spell_projectile.gd (Phase 2B) genutzt um Treffer auf Tiles zu erkennen.
# Gibt null zurueck wenn die Position ausserhalb des Rasters liegt.
func get_tile_at_world_pos(world_pos: Vector2) -> Tile:
	# Welt-Position des ersten Tiles (oben links)
	var half_w: float = (GRID_COLS - 1) * 0.5 * TILE_SIZE
	var half_h: float = (GRID_ROWS - 1) * 0.5 * TILE_SIZE

	# Offset zum lokalen Raum des ArenaGrid-Nodes berechnen
	# (falls ArenaGrid selbst verschoben ist, global_position einbeziehen)
	var local_pos: Vector2 = world_pos - global_position

	# Welt-Offset → Gitter-Index (round() statt floor() damit Treffer auf Tile-Mitte toleriert werden)
	var col: int = int(round((local_pos.x + half_w) / TILE_SIZE))
	var row: int = int(round((local_pos.y + half_h) / TILE_SIZE))

	return get_tile(Vector2i(col, row))

# Setzt alle Tiles auf INTACT zurueck (fuer Runden-Reset).
# Wird von arena_state_manager.gd (Phase 3A) beim State-Wechsel zu LOBBY/COUNTDOWN aufgerufen.
func reset_all_tiles() -> void:
	for tile in _tiles.values():
		if tile:
			(tile as Tile).reset()

# Gibt die Anzahl der derzeit zerstoerten Tiles zurueck.
# Nuetzlich fuer das Score-System (Phase 3C) und Tutorial (Phase 4D).
func get_destroyed_count() -> int:
	var count: int = 0
	for tile in _tiles.values():
		if tile and (tile as Tile).get_state() == Tile.TileState.DESTROYED:
			count += 1
	return count

# =============================================================================
# SIGNAL-WEITERLEITUNG
# =============================================================================

# Empfaengt tile_state_changed vom einzelnen Tile und leitet es weiter.
# So muss kein anderes System auf jeden einzelnen Tile-Node verbinden –
# alle hoeren auf das zentralisierte ArenaGrid-Signal.
func _on_tile_state_changed(state: int, grid_pos: Vector2i) -> void:
	tile_state_changed.emit(state, grid_pos)
