# =============================================================================
# DATEINAME: line_of_sight.gd
# ZWECK:     Prueft ob die Sichtlinie zwischen zwei Weltpositionen frei ist.
#            Wird von target_system.gd genutzt um zu pruefen ob ein Spieler
#            seinen aktuellen Lock-Ziel noch "sehen" kann (kein Terrain dazwischen).
#            LOS-Reduktion beeinflusst Schaden in damage_system.gd (Phase 2D).
# ABHAENGIG VON: Physics-Layer-Konfiguration aus project.godot
#                (Terrain muss auf einem eigenen Layer liegen – lt. DESIGN.md Layer 2)
# =============================================================================

class_name LineOfSight
extends RefCounted

# =============================================================================
# KONSTANTEN
# =============================================================================

# Physics-Layer-Bit fuer Terrain (Layer 2 in Godot = Bit 1 = Wert 2).
# Nur Terrain-Nodes blockieren LOS – Spieler-Nodes ignoriert.
# Wert muss mit project.godot collision_layer-Einstellung von tile.tscn uebereinstimmen.
const TERRAIN_LAYER_BIT: int = 2

# =============================================================================
# OEFFENTLICHE API
# =============================================================================

# Prueft ob die Sichtlinie von 'from' nach 'to' unblockiert ist.
# Gibt true zurueck wenn kein Terrain-Tile die Linie schneidet.
# Gibt false zurueck wenn Terrain die Sicht blockiert.
#
# from:        Startpunkt der Sichtlinie (Welt-Koordinaten), z.B. Angreifer-Position
# to:          Endpunkt der Sichtlinie, z.B. Ziel-Position
# world:       Referenz auf den PhysicsDirectSpaceState2D fuer Raycasts –
#              bekomme ihn via get_world_2d().direct_space_state im Node
# exclude:     Array von Kollisionsobjekten die NICHT als Hindernis zaehlen
#              (z.B. der abfragende Spieler selbst und das Ziel)
# Gibt true zurueck = Sicht frei; false = blockiert
static func has_clear_los(
	from: Vector2,
	to: Vector2,
	world: PhysicsDirectSpaceState2D,
	exclude: Array = []
) -> bool:
	# Raycast-Parameter konfigurieren.
	# PhysicsRayQueryParameters2D ist das Godot 4-API fuer Raycasts in _physics_process.
	var query := PhysicsRayQueryParameters2D.create(from, to)

	# Nur gegen Terrain-Layer casten – Spieler-Nodes blockieren LOS nicht
	query.collision_mask = TERRAIN_LAYER_BIT

	# Spieler selbst und Ziel aus dem Raycast ausschliessen damit sie sich nicht selbst blockieren
	# exclude erwartet Array[RID] – wir akzeptieren auch CollisionObject2D-Nodes
	var exclude_rids: Array[RID] = []
	for obj in exclude:
		if obj is CollisionObject2D:
			exclude_rids.append((obj as CollisionObject2D).get_rid())
		elif obj is RID:
			exclude_rids.append(obj)
	query.exclude = exclude_rids

	# Raycast ausfuehren – gibt leeres Dictionary zurueck wenn nichts getroffen
	var result: Dictionary = world.intersect_ray(query)

	# Wenn result leer ist: kein Hindernis gefunden → Sicht frei
	return result.is_empty()

# Prueft LOS und gibt einen Schaden-Multiplikator zurueck.
# Wird von damage_system.gd (Phase 2D) genutzt um Schaden hinter Terrain zu reduzieren.
#
# Rueckgabewert:
#   1.0  = Sicht frei, voller Schaden
#   0.5  = Terrain teilweise im Weg (einfache Haelfte-Regel fuer Phase 1, verfeinert in Phase 2D)
#   0.0  = koennte in Zukunft fuer vollstaendigen Block genutzt werden
#
# from, to, world, exclude: gleiche Bedeutung wie in has_clear_los()
static func get_damage_multiplier(
	from: Vector2,
	to: Vector2,
	world: PhysicsDirectSpaceState2D,
	exclude: Array = []
) -> float:
	if has_clear_los(from, to, world, exclude):
		return 1.0
	# Terrain blockiert – Schaden auf 50% reduziert (Deckung als taktisches Element lt. DESIGN.md)
	# Phase 2D verfeinert dies mit mehrfachen Raycasts und Tile-HP-Zustand
	return 0.5
