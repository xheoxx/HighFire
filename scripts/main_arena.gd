# =============================================================================
# DATEINAME: main_arena.gd
# ZWECK:     Haupt-Szenen-Controller fuer die Arena. Initialisiert das Spiel,
#            verwaltet das HUD-Layer und verbindet Kern-Signale.
#            Dieser Node ist der Root der main_arena.tscn-Szene.
# ABHAENGIG VON: arena_grid.gd (wird in Phase 1 Stream D eingebunden),
#                player.tscn (wird in Phase 1 Stream B benoetigt),
#                hud.tscn (liegt im gleichen Verzeichnis)
# =============================================================================
extends Node2D

# Referenz auf das Arena-Grid (wird nach Szenenstart gefunden).
# Das Grid instanziiert alle 32x32 Tiles und verwaltet deren Zustaende.
@onready var arena_grid: Node2D = $ArenaGrid

# Referenz auf den HUD-Canvas-Layer (immer im Vordergrund, unabhaengig von Kamera).
@onready var hud_layer: CanvasLayer = $HUDLayer

# Referenz auf die Kamera. In Phase 3 Stream B wird diese durch einen
# dynamischen CameraController ersetzt der alle Spieler im Blick behaelt.
@onready var main_camera: Camera2D = $Camera2D

# Spieler-Nodes: werden spaeter vom PlayerSpawner (Phase 3 Stream B) befuellt.
# Vorab als leeres Array – Phase 1 platziert Spieler direkt in der Szene.
var players: Array = []

# =============================================================================
# _ready(): Wird aufgerufen sobald die Szene vollstaendig geladen ist.
# Sammelt alle Spieler-Nodes ein und bereitet das HUD vor.
# =============================================================================
func _ready() -> void:
	# Alle Nodes mit der Gruppe "player" einsammeln.
	# Spieler muessen in _ready() der player.tscn der Gruppe hinzugefuegt werden.
	players = get_tree().get_nodes_in_group("player")

	# Kamera zentriert auf Arena-Mittelpunkt (0,0) ausrichten.
	# In Phase 3 wird die Kamera dynamisch angepasst.
	if main_camera:
		main_camera.position = Vector2.ZERO

	print("[MainArena] Bereit. Spieler gefunden: ", players.size())
