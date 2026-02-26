# =============================================================================
# DATEINAME: player.gd
# ZWECK:     Steuert einen einzelnen Spieler – Bewegung, Dodge, Farbidentitaet
#            und Animations-Signale. Liest Balance-Werte aus balance_config.tres
#            und Farbdaten aus player_data.tres. Versorgt player_input.gd mit
#            dem Spieler-Index und empfaengt daraus den Bewegungsvektor.
# ABHAENGIG VON: player_input.gd, balance_config.tres, player_data.tres,
#                player.tscn (Nodes: ColorRect, AnimatedSprite2D, Line2D,
#                              GPUParticles2D "DodgeTrail", Timer "DodgeCooldown")
# =============================================================================

class_name Player
extends CharacterBody2D

# =============================================================================
# SIGNALE
# =============================================================================

# Wird gesendet wenn die aktive Animation sich aendert (Phase 4H: Sprite-Integration).
# player_animator.gd hoert auf dieses Signal und setzt AnimatedSprite2D.play().
# direction: "up" | "down" | "left" | "right"
signal animation_changed(anim_name: String, direction: String)

# Wird gesendet wenn der Spieler einen erfolgreichen Dodge abschliesst.
# status_effect_component.gd hoert darauf und entfernt Soft-CC-Stacks (Phase 2B).
signal dodged()

# Wird gesendet wenn sich die HP aendern (Phase 2D: health_component verarbeitet das).
# Hier als Vorbereitung fuer spaeteren health_component-Austausch.
signal hp_changed(new_hp: int)

# =============================================================================
# EXPORTS (konfigurierbar im Godot-Editor oder per Szene-Parameter)
# =============================================================================

# Spieler-Index (0–3) – bestimmt Farbe, Input-Actions-Prefix und HUD-Position.
# Wird von player_spawner.gd (Phase 3B) oder main_arena.gd gesetzt.
@export var player_id: int = 0

# =============================================================================
# NODE-REFERENZEN (werden in _ready() befuellt)
# =============================================================================

# ColorRect-Platzhalter (sichtbar wenn use_sprites = false in player_data.tres)
@onready var color_rect: ColorRect = $ColorRect

# AnimatedSprite2D – bereit fuer Phase 4H, standardmaessig unsichtbar
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

# Line2D Rim-Glow – Kreis aus 32 Punkten um den Spieler, Farbe = Spielerfarbe
@onready var rim_glow: Line2D = $RimGlow

# GPUParticles2D fuer den Dodge-Trail-Effekt (Partikel in Spielerfarbe)
@onready var dodge_trail: GPUParticles2D = $DodgeTrail

# Timer der den Dodge-Cooldown verwaltet (0.8s lt. balance_config.tres)
@onready var dodge_cooldown_timer: Timer = $DodgeCooldown

# =============================================================================
# INTERNE ZUSTAENDE
# =============================================================================

# Resource-Handles – werden in _ready() geladen
var _balance: Resource   # balance_config.tres
var _player_data: Resource  # player_data.tres

# Aktuelle Bewegungsgeschwindigkeit in px/s (aus balance_config.tres, 250 Standard)
var speed: float = 250.0

# Dodge-Geschwindigkeit in px/s (aus balance_config.tres, 600 Standard)
var dodge_speed: float = 600.0

# Wie lange ein einzelner Dodge dauert in Sekunden (aus balance_config.tres, 0.2s)
var dodge_duration: float = 0.2

# Ob der Spieler gerade dodged (true = unverwundbar, Input gesperrt waehrend Dash)
# Wird von damage_system.gd abgefragt bevor Schaden angewendet wird.
var is_dodging: bool = false

# Ob der Dodge-Cooldown gerade aktiv ist (true = kein weiterer Dodge moeglich)
var _dodge_on_cooldown: bool = false

# Interner Timer fuer die Dodge-Dauer (wird in _physics_process heruntergezaehlt)
var _dodge_timer: float = 0.0

# Richtungsvektor des letzten Dodges (damit der Spieler korrekt in diese Richtung dasht)
var _dodge_direction: Vector2 = Vector2.ZERO

# Aktuelle Bewegungsrichtung (zuletzt nicht-null), fuer Animations-Signale
var _last_direction: String = "down"

# HP-Verwaltung – temporaer hier bis health_component in Phase 2D hinzukommt
var current_hp: int = 100
var max_hp: int = 100

# Input-Komponente – wird in _ready() erzeugt und konfiguriert
var _input: PlayerInput

# =============================================================================
# GODOT-LIFECYCLE
# =============================================================================

# _ready() wird einmalig aufgerufen wenn der Node in den Szenenbaum eingefuegt wird.
# Hier werden Resources geladen, Input konfiguriert und Farben gesetzt.
func _ready() -> void:
	# Resources laden – beide Dateien muessen im Projekt existieren (Stream F hat sie angelegt)
	_balance = load("res://resources/balance_config.tres")
	_player_data = load("res://resources/player_data.tres")

	# Balance-Werte uebernehmen – so sind alle Werte ohne Code-Aenderung anpassbar
	if _balance:
		speed = _balance.get("player_speed") if _balance.get("player_speed") else 250.0
		dodge_speed = _balance.get("dodge_speed") if _balance.get("dodge_speed") else 600.0
		dodge_duration = _balance.get("dodge_duration") if _balance.get("dodge_duration") else 0.2
		max_hp = _balance.get("player_hp") if _balance.get("player_hp") else 100
		current_hp = max_hp

	# Dodge-Cooldown-Timer konfigurieren
	# Der Timer laeuft einmal ab und setzt dann _dodge_on_cooldown zurueck.
	dodge_cooldown_timer.wait_time = _balance.get("dodge_cooldown") if (_balance and _balance.get("dodge_cooldown")) else 0.8
	dodge_cooldown_timer.one_shot = true
	# call_deferred wird hier NICHT genutzt – Timer verbinden ist sicher in _ready()
	dodge_cooldown_timer.timeout.connect(_on_dodge_cooldown_finished)

	# Input-Komponente erzeugen und als Child hinzufuegen
	# Als Child-Node statt AutoLoad: jeder Spieler hat seine eigene Instanz
	_input = PlayerInput.new()
	_input.name = "PlayerInput"
	add_child(_input)
	# Joypad-Index: Spieler 0 und 1 nutzen Tastatur (joypad_index = -1),
	# Spieler 2 und 3 bekommen Joypad-Index 0 und 1.
	# player_spawner.gd (Phase 3B) wird das genauer steuern.
	var joy_idx: int = player_id - 2 if player_id >= 2 else -1
	_input.init(player_id, joy_idx)

	# Spielerfarbe setzen (aus player_data.tres)
	_apply_player_color()

	# Sprite-Modus anwenden (use_sprites aus player_data.tres)
	_apply_sprite_mode()

	# Spieler zur Gruppe hinzufuegen – fuer einfachen Zugriff von anderen Nodes
	add_to_group("player")

# _physics_process(delta) laeuft jeden Physik-Frame (60 fps Standard in Godot).
# Hier wird Bewegung und Dodge berechnet.
# delta = Zeit seit letztem Frame in Sekunden (Framerate-unabhaengige Bewegung)
func _physics_process(delta: float) -> void:
	if is_dodging:
		# Waehrend Dodge: Spieler bewegt sich in festgelegter Richtung mit Dodge-Speed.
		# move_and_slide() uebernimmt Kollisionserkennung automatisch.
		velocity = _dodge_direction * dodge_speed
		move_and_slide()

		# Dodge-Dauer-Timer herunterzaehlen
		_dodge_timer -= delta
		if _dodge_timer <= 0.0:
			_end_dodge()
		return

	# --- Normale Bewegung ---
	var move_vec: Vector2 = _input.get_move_vector()
	velocity = move_vec * speed
	move_and_slide()

	# Animations-Signal nur senden wenn sich die Richtung geaendert hat
	if move_vec.length_squared() > 0.01:
		var new_dir: String = _vec_to_direction(move_vec)
		if new_dir != _last_direction:
			_last_direction = new_dir
			animation_changed.emit("walk", _last_direction)
	else:
		# Spieler steht still
		animation_changed.emit("idle", _last_direction)

	# --- Dodge-Trigger pruefen ---
	# is_action_just_pressed: nur im Frame des ersten Drueckens true (kein Dauerfeuer)
	if _input.is_action_just_pressed("action_dodge") and not _dodge_on_cooldown:
		_start_dodge()

# =============================================================================
# DODGE-LOGIK
# =============================================================================

# Startet den Dodge in der aktuellen Bewegungsrichtung (oder letzter Richtung).
# Setzt is_dodging = true (Unverwundbarkeit) und startet den Dash.
func _start_dodge() -> void:
	# Dodge-Richtung: aktuelle Eingabe oder (wenn keine) letzte Bewegungsrichtung
	var input_vec: Vector2 = _input.get_move_vector()
	if input_vec.length_squared() > 0.01:
		_dodge_direction = input_vec.normalized()
	else:
		# Fallback: Dodge in Blickrichtung (letzte bekannte Richtung)
		_dodge_direction = _direction_to_vec(_last_direction)

	is_dodging = true
	_dodge_on_cooldown = true
	_dodge_timer = dodge_duration

	# Dodge-Trail-Partikel aktivieren (werden automatisch nach Lifetime deaktiviert)
	if dodge_trail:
		dodge_trail.emitting = true

	# Animations-Signal fuer Dodge-Animation
	animation_changed.emit("dodge", _last_direction)

# Beendet den Dodge, setzt Zustand zurueck und startet Cooldown-Timer.
func _end_dodge() -> void:
	is_dodging = false
	_dodge_timer = 0.0

	# Signal senden: status_effect_component.gd entfernt Soft-CC-Stacks (Phase 2B)
	dodged.emit()

	# Cooldown-Timer starten – bis dieser ablaeuft kein weiterer Dodge moeglich
	# call_deferred ist hier nicht noetig, Timer.start() ist sicher in _physics_process
	dodge_cooldown_timer.start()

	# Partikel-Emitter stoppen (Partikel die bereits existieren laufen noch aus)
	if dodge_trail:
		dodge_trail.emitting = false

# Wird vom Timer aufgerufen wenn Dodge-Cooldown abgelaufen ist.
func _on_dodge_cooldown_finished() -> void:
	_dodge_on_cooldown = false

# =============================================================================
# HP-VERWALTUNG (Temporaer bis health_component in Phase 2D hinzukommt)
# =============================================================================

# Wendet Schaden auf diesen Spieler an.
# Wird von damage_system.gd aufgerufen (Phase 2D).
# amount: positiver Wert = Schaden, negativer Wert = Heilung
func take_damage(amount: int) -> void:
	# Waehrend Dodge ist der Spieler unverwundbar
	if is_dodging:
		return

	current_hp = clamp(current_hp - amount, 0, max_hp)
	hp_changed.emit(current_hp)

	# Spieler-Tod pruefen
	if current_hp <= 0:
		_die()

# Heilt den Spieler um amount HP.
func heal(amount: int) -> void:
	current_hp = clamp(current_hp + amount, 0, max_hp)
	hp_changed.emit(current_hp)

# Wird aufgerufen wenn HP auf 0 fallen.
func _die() -> void:
	animation_changed.emit("death", _last_direction)
	# Weitere Death-Logik wird in Phase 3A (ArenaStateManager) ergaenzt.
	# Spieler nicht sofort aus dem Baum loeschen – ArenaStateManager entscheidet das.
	set_physics_process(false)
	_input.block_input()

# =============================================================================
# VISUELLE KONFIGURATION
# =============================================================================

# Setzt Spieler-Primaerfarbe auf ColorRect und AnimatedSprite2D.modulate.
# Rim-Glow (Line2D) bekommt ebenfalls die Spielerfarbe.
func _apply_player_color() -> void:
	if not _player_data:
		return

	var colors = _player_data.get("player_primary_colors")
	if not colors or player_id >= colors.size():
		return

	var primary: Color = colors[player_id]

	# ColorRect-Platzhalter einfaerben
	if color_rect:
		color_rect.color = primary

	# AnimatedSprite2D modulate – Sprites werden in Neutral-Palette geliefert,
	# modulate faerbt sie in Spielerfarbe ein
	if animated_sprite:
		animated_sprite.modulate = primary

	# Rim-Glow einfaerben
	if rim_glow:
		rim_glow.default_color = primary

	# Dodge-Trail in Spielerfarbe
	# GPUParticles2D nutzt ein ProcessMaterial – Farbe direkt auf Modulate setzen
	if dodge_trail:
		dodge_trail.modulate = primary

# Schaltet zwischen ColorRect-Platzhalter und AnimatedSprite2D um.
# Gesteuert durch use_sprites in player_data.tres.
func _apply_sprite_mode() -> void:
	if not _player_data:
		return

	var use_sprites: bool = _player_data.get("use_sprites") if _player_data.get("use_sprites") != null else false

	if color_rect:
		color_rect.visible = not use_sprites

	if animated_sprite:
		animated_sprite.visible = use_sprites

# =============================================================================
# HILFSFUNKTIONEN
# =============================================================================

# Wandelt einen Vector2-Bewegungsvektor in eine Richtungs-String um.
# Genutzt fuer animation_changed-Signal und Fallback-Dodge-Richtung.
func _vec_to_direction(vec: Vector2) -> String:
	# Dominante Achse bestimmt die Richtung (einfacher als 8-Richtungs-Lookup)
	if abs(vec.x) >= abs(vec.y):
		return "right" if vec.x > 0 else "left"
	else:
		return "down" if vec.y > 0 else "up"

# Wandelt einen Richtungs-String zurueck in einen normalisierten Vector2.
# Genutzt fuer Dodge-Richtung wenn kein Input aktiv ist.
func _direction_to_vec(dir: String) -> Vector2:
	match dir:
		"up":    return Vector2.UP
		"down":  return Vector2.DOWN
		"left":  return Vector2.LEFT
		"right": return Vector2.RIGHT
	return Vector2.DOWN  # Fallback

# =============================================================================
# TESTFAELLE (fuer manuelle lokale Pruefung)
# =============================================================================
# 1. Spieler 1 (WASD) bewegt sich – animation_changed-Signal wird gefeuert
# 2. Dodge (K bei P1) loest Dash aus, is_dodging wird true, dann false nach 0.2s
# 3. Kein zweiter Dodge waehrend Cooldown (0.8s nach Dodge-Ende)
# 4. take_damage(50) reduziert HP auf 50, hp_changed-Signal korrekt
# 5. take_damage(60) bei 50 HP: HP = 0, _die() aufgerufen, Input geblockt
# 6. heal(25) bei 50 HP: HP = 75, hp_changed korrekt
# 7. Dodge waehrend take_damage(): Schaden wird ignoriert (is_dodging = true)
# 8. use_sprites = false (default): ColorRect sichtbar, AnimatedSprite2D unsichtbar
