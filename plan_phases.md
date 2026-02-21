# Plan – HighFire Spellcraft Arena

## Referenz-Dokumente
| Dokument | Inhalt |
|----------|--------|
| `DESIGN.md` | Vollständiges Design: Visuals, Combos, Crafting, Balance, Kamera, Tutorial, Accessibility, Menüs, Bot-KI, Progression |
| `moodboard.md` | Bildgenerator-Prompts für 6 Stimmungswelten (Arena, Gameplay, Crafting, Charakter, HUD, Menü) |
| `AGENTS.md` | Persona, Sprache, Koordinationsregeln, Branch-Konventionen, Teststrategie |

---

## Ziel
Schneller, lokaler Multiplayer-Arena-Fighter (Steam-Ziel) mit Spellcrafting, Weaponcrafting, Controller-Motion-Combos, Target-Locking, Line-of-Sight und zerstörbarem Terrain – vollständig in Godot 4 mit Primitiven (ColorRect, Line2D, Labels, GPUParticles2D), keine externen Assets nötig.

---

## Phasen-Übersicht

### Phase 0 – Design Foundation ✅ ABGESCHLOSSEN
Alle Design-Entscheidungen getroffen und in `DESIGN.md` dokumentiert:
- Combo-Grammatik & Motion-Input-Lexikon
- Spellcrafting-Rezepte (6 Elemente, Kombinationen)
- Weaponcrafting-Archetypen & Upgrade-Nodes
- Balance-Parameter (HP, Schaden, Cooldowns)
- Arena-Layout-Varianten (4 Maps)
- Kamera-System (Shared/Split-Screen)
- Game Feel / Juice
- Sound-Design
- Spieler-Farbidentität
- Arena State Machine
- Tutorial-Flow
- Accessibility
- Hauptmenü & Einstellungsmenü
- KI/Bot-Gegner (4 Schwierigkeitsstufen)
- Vollständige Farbpalette (Hex-Codes)
- Progressions- & Unlock-System
- Pause-Menü
- Out-of-Bounds-Verhalten
- Spawn-Positionen pro Arena
- Musik-Konzept (Layer-System)
- Physics-Layer-Definition

---

### Phase 1 – Core Scene & Movement
**Ziel**: Spielbares Grundgerüst mit Bewegung, Dodge, Target-Lock und zerstörbarem Terrain in einer Arena. Am Ende dieser Phase können 2 Spieler sich bewegen, ausweichen und Ziele wechseln.

---

#### Stream A – Scene-Setup
**Verantwortlich für**: Die grundlegende Szenenstruktur, auf der alle anderen Streams aufbauen.

**Zu erstellende Dateien:**
```
/scenes/main_arena.tscn       ← Haupt-Szene
/scenes/player.tscn           ← Spieler-Prefab
/scenes/hud.tscn              ← HUD-Canvas
/scenes/tile.tscn             ← Einzelner Arena-Tile
/scripts/main_arena.gd        ← Szenen-Controller
```

**Godot-Nodes:**
- `Node2D` → Root `MainArena`
- `TileMap` oder `Node2D` mit instanziierten `tile.tscn` → Arena-Grid (32×32)
- `CanvasLayer` → HUD-Overlay
- `Camera2D` → Kamera (wird in Phase 3 auf Multi-Camera erweitert)
- `ColorRect` → Hintergrund (dunkles Obsidian), Tile-Färbung
- `Line2D` → Runen-Risse im Boden

**Akzeptanzkriterien:**
- [ ] Szene öffnet sich in Godot ohne Fehler
- [ ] Arena-Grid (32×32 Tiles) ist sichtbar mit dunklem Hintergrund
- [ ] Zwei Spieler-Nodes sind platziert (Platzhalter-ColorRect)
- [ ] HUD-Canvas existiert mit leeren Label-Platzhaltern
- [ ] Keine Abhängigkeit zu anderen Streams

**Fallstricke:**
- TileMap vs. manuelle Node-Instanziierung: manuelle Instanziierung bevorzugen für einfachere Zustandsverwaltung pro Tile
- Koordinatensystem: Arena-Mittelpunkt = `Vector2(0, 0)`, Tiles relativ dazu

---

#### Stream B – Player Movement
**Abhängigkeit**: Stream A muss abgeschlossen sein.

**Zu erstellende Dateien:**
```
/scripts/player.gd            ← Spieler-Controller
/scripts/player_input.gd      ← Input-Abstraktion (Spieler 1/2/3/4)
/resources/player_data.tres   ← Spieler-Konfiguration (Farbe, Speed, HP)
```

**Godot-Nodes (in `player.tscn`):**
- `CharacterBody2D` → Root
- `CollisionShape2D` + `CapsuleShape2D` → Hitbox
- `ColorRect` → Spieler-Körper (Primärfarbe aus `DESIGN.md`)
- `Line2D` → Rim-Glow (Spieler-Farbe)
- `GPUParticles2D` → Dodge-Trail
- `Timer` → Dodge-Cooldown (0.8s)

**Zu implementierende Logik:**
- `_physics_process()`: Bewegung via `move_and_slide()`, Speed = 250 px/s
- Dodge: Richtungsvektor × 600 px/s für 0.2s, dann Cooldown
- Unverwundbarkeit während Dodge (Flag `is_dodging`)
- Spieler-Index (0–3) bestimmt Farbe aus Konstanten-Dictionary
- Input-Abstraktion: `get_move_vector(player_id)` gibt `Vector2` zurück – unterstützt D-Pad, Analogstick + Keyboard (lt. Controller-Layout in DESIGN.md)

**Akzeptanzkriterien:**
- [ ] Spieler 1 und 2 bewegen sich unabhängig mit eigenem Controller/Tastatur
- [ ] Dodge funktioniert mit Cooldown und Unverwundbarkeit
- [ ] Spieler haben korrekte Primärfarben (Cyan / Magenta)
- [ ] Kollision mit Arena-Wänden funktioniert
- [ ] Kein Durchdringen von anderen Spielern

**Fallstricke:**
- Input-Map in `project.godot` muss 4 Spieler-Aktions-Sets definieren (`p1_move_up`, `p2_move_up` etc.)
- `CharacterBody2D.move_and_slide()` benötigt `up_direction` für korrekte Kollision in 2D-Topdown

---

#### Stream C – Target System
**Abhängigkeit**: Stream A + B müssen abgeschlossen sein.

**Zu erstellende Dateien:**
```
/scripts/target_system.gd     ← Target-Lock & Switch Logik
/scenes/target_indicator.tscn ← HUD-Ring um Ziel
/scripts/line_of_sight.gd     ← LOS-Raycast
```

**Godot-Nodes (in `target_indicator.tscn`):**
- `Node2D` → Root
- `Line2D` (Ring aus Punkten) → Ziel-Ring (Cyan = aktives Ziel, Rot = Feind)
- `AnimationPlayer` → Pulsier-Animation

**Zu implementierende Logik:**
- `target_system.gd`: pro Spieler wird ein Ziel-Spieler gespeichert
- Target-Switch: `L1`-Tastendruck → nächsten Spieler im Uhrzeigersinn (nach Winkel sortiert)
- LOS-Check via `PhysicsRayQueryParameters2D`: Raycast von Spieler zu Ziel, prüft ob Terrain blockiert
- Ziel-Indikator folgt dem Ziel-Spieler via `global_position`
- Farbe des Rings = Farbe des angreifenden Spielers (lt. `DESIGN.md`)

**Akzeptanzkriterien:**
- [ ] Jeder Spieler kann ein Ziel locken
- [ ] Zielwechsel funktioniert mit 0.2s Cooldown
- [ ] HUD-Ring erscheint um das gelockte Ziel
- [ ] LOS-Raycast erkennt Terrain als Hindernis
- [ ] Ring verschwindet wenn Ziel eliminiert wird

**Fallstricke:**
- Raycast muss auf dem richtigen Physics-Layer laufen (Terrain-Layer separat von Spieler-Layer)
- Ring als `Line2D`-Kreis: 32 Punkte reichen für glatte Darstellung

---

#### Stream D – Terrain Base
**Abhängigkeit**: Stream A muss abgeschlossen sein (unabhängig von B und C).

**Zu erstellende Dateien:**
```
/scripts/tile.gd              ← Tile-Zustandsmaschine
/scripts/arena_grid.gd        ← Grid-Manager, Tile-Instanziierung
/resources/tile_config.tres   ← Tile-Farben und Schwellwerte
```

**Tile-Zustände & Farben:**
```
INTACT    → ColorRect: #1A1A2E (dunkel)
CRACKED   → ColorRect: #1A1A2E + Line2D Risse in #FF6600
DESTROYED → ColorRect unsichtbar, Loch-Effekt via #FF4400 darunter
```

**Zu implementierende Logik:**
- `tile.gd`: `enum TileState {INTACT, CRACKED, DESTROYED}`
- `take_damage(amount)`: HP reduzieren, State-Wechsel auslösen, Signal `tile_state_changed` emittieren
- `arena_grid.gd`: 32×32 Tiles instanziieren, Dictionary für schnellen Zugriff via `Vector2i`-Index
- Zerstörter Tile: `CollisionShape2D` deaktivieren → Spieler können hindurchfallen (Out-of-Bounds)
- Timer für Tile-Regeneration (optional, konfigurierbar)

**Akzeptanzkriterien:**
- [ ] 32×32 Grid wird korrekt generiert
- [ ] Tiles wechseln Farbe/State bei `take_damage()`
- [ ] Zerstörter Tile hat keine Kollision mehr
- [ ] Signal `tile_state_changed` wird korrekt emittiert
- [ ] Grid-Zugriff via `Vector2i`-Index funktioniert in O(1)

**Fallstricke:**
- Zu viele Nodes: 1024 Tile-Nodes können Performance kosten – `_ready()` vereinfachen, keine unnötigen Children
- Tile-Kollision deaktivieren: `call_deferred("set_disabled", true)` statt direktem Aufruf in `_physics_process`

---

#### Stream E – project.godot-Konfiguration
**Verantwortlich für**: Einmalige Engine-Konfiguration, die alle Streams benötigen. **Nur dieser Stream darf `project.godot` ändern.**

**Zu konfigurierende Einträge:**
```
project.godot:
  [input]         → Actions lt. DESIGN.md Controller-Layout:
                    move_up, move_down, move_left, move_right,
                    action_attack, action_dodge, action_element, action_special,
                    target_prev, target_next, menu_pause, menu_info
                    + Analog-Erweiterungen: aim_x, aim_y, modifier_left, modifier_right
                    + P1 Keyboard + P2 Keyboard (lt. Tastatur-Fallback-Tabelle in DESIGN.md)
  [autoload]      → ArenaStateManager, DamageSystem, MusicManager
  [layer_names]   → Physics-Layer lt. DESIGN.md (Spieler, Terrain, Projektile, Wände, Raycast)
  [display]       → Viewport-Größe: 1920×1080, Stretch-Mode: canvas_items
```

**Godot-Konfig-Typ:**
- `project.godot` (TOML-ähnliches Godot-Format), manuell bearbeiten

**Akzeptanzkriterien:**
- [ ] Alle Input-Actions in `project.godot` definiert (mind. 12 Actions)
- [ ] AutoLoad-Pfade korrekt und Dateien existieren
- [ ] Physics-Layer 1–5 benannt lt. DESIGN.md
- [ ] Viewport-Größe auf 1920×1080 gesetzt

**Fallstricke:**
- **Kein anderer Stream** darf `project.godot` anfassen – bei Bedarf Issue an Stream E
- Input-Action-Namen müssen exakt mit `InputEvent`-Abfragen in anderen Streams übereinstimmen
- AutoLoad-Pfade relativ zum Projekt-Root angeben (`res://scripts/...`)

---

### Phase 2 – Combat & Crafting
**Ziel**: Vollständige Kampfschleife. Am Ende können Spieler Spells casten, Waffen craften und sich gegenseitig Schaden zufügen.

---

#### Stream A – Motion-Input Parser
**Abhängigkeit**: Phase 1 vollständig abgeschlossen.

**Zu erstellende Dateien:**
```
/scripts/motion_input_parser.gd   ← Gesten-Erkennung
/scripts/combo_chain.gd           ← Combo-Visualisierung
/scenes/combo_chain_ui.tscn       ← Rune-Kette HUD-Element
/resources/combo_definitions.tres ← Dictionary aller Combos
```

**Zu implementierende Logik:**
- Ring-Buffer der letzten D-Pad-/Stick-Richtungen (max. 8 Einträge, 0.4s Zeitfenster)
- D-Pad: Direktes Richtungs-Enum aus `InputEvent` (digital, kein Deadzone nötig)
- Analogstick (falls vorhanden): Richtungsquantisierung mit Deadzone 0.3 → 8-Richtungs-Enum
- Pattern-Matching: Buffer gegen `combo_definitions`-Dictionary prüfen (längster Match gewinnt)
- Perfect-Timing-Bonus: wenn gesamte Geste < 0.15s → Signal `perfect_input` emittieren
- `combo_chain.gd`: `Line2D`-basierte Runen-Visualisierung, jeder Input fügt ein Element hinzu

**Combo-Definitions-Format:**
```gdscript
const COMBOS = {
  [DIR.DOWN, DIR.RIGHT]: "quarter_forward",
  [DIR.DOWN, DIR.LEFT]: "quarter_backward",
  [DIR.RIGHT, DIR.DOWN, DIR.RIGHT]: "z_motion",
  # etc.
}
```

**Akzeptanzkriterien:**
- [ ] Viertelkreis-vorwärts wird zuverlässig erkannt
- [ ] Zeitfenster von 0.4s wird korrekt eingehalten
- [ ] Perfect-Timing-Signal wird bei < 0.15s emittiert
- [ ] Combo-Chain-UI zeigt jeden Input-Schritt an
- [ ] Fehlgeschlagener Input löscht den Buffer

**Fallstricke:**
- D-Pad-Eingaben sind digital – kein Deadzone-Problem, aber diagonale Inputs (↓→ gleichzeitig) müssen als Sequenz erkannt werden, nicht als einzelner Frame
- Analogstick-Deadzone: Werte unter 0.3 ignorieren, sonst False-Positives
- Delta-Time beachten: Zeitfenster in `_process(delta)` akkumulieren, nicht in Frames

---

#### Stream B – Spellcrafting
**Abhängigkeit**: Stream A dieser Phase.

**Zu erstellende Dateien:**
```
/scripts/spell_system.gd          ← Spell-Verwaltung & Casting
/scripts/spell_projectile.gd      ← Projektil-Bewegung & Hit
/scenes/spell_projectile.tscn     ← Projektil-Node
/scenes/crafting_ui.tscn          ← Crafting-Panel HUD
/scripts/crafting_ui.gd           ← Panel-Logik
/resources/spell_recipes.tres     ← Alle Rezepte aus DESIGN.md
```

**Zu implementierende Logik:**
- `spell_system.gd`: 3 Spell-Slots pro Spieler, Element-Inventar (max. 2 pro Element)
- Element-Sammlung: Signal von `damage_system.gd` → Element zu Inventar hinzufügen
- Crafting-Flow: `L1` Langdruck → Panel öffnen, 2 Elemente wählen → Spell erzeugen
- `spell_projectile.gd`: Bewegung via `velocity`, Kollision mit Spielern und Terrain prüfen
- Spell-Effekte per Dictionary: `{Spell-Typ: Callable}` für saubere Erweiterbarkeit

**Akzeptanzkriterien:**
- [ ] Alle 6 Rezepte aus `DESIGN.md` funktionieren
- [ ] Crafting-UI öffnet/schließt korrekt
- [ ] Projektile treffen Spieler und Terrain
- [ ] Spell-Slots im HUD werden korrekt aktualisiert
- [ ] Element-Inventar wird nach Crafting geleert

**Fallstricke:**
- Projektil-Instanziierung: `preload()` statt `load()` für Performance
- Spell-Effekte wie DoT (Brennen) als `Timer`-Node auf dem Ziel, nicht als `_process()`-Loop

---

#### Stream C – Weaponcrafting
**Abhängigkeit**: Stream A dieser Phase (unabhängig von Stream B).

**Zu erstellende Dateien:**
```
/scripts/weapon_system.gd         ← Waffen-Verwaltung
/scenes/weapon_ui.tscn            ← Waffen-Panel HUD
/scripts/weapon_ui.gd             ← Panel-Logik
/resources/weapon_definitions.tres ← Alle Archetypen & Upgrade-Nodes
```

**Zu implementierende Logik:**
- 5 Waffen-Archetypen als Resource-Klassen mit Stats: `reach`, `speed`, `spell_affinity[]`
- Material-Inventar: wird bei `tile_state_changed(DESTROYED)` aufgefüllt
- Upgrade-Node-System: 3 Nodes pro Waffe als Enum, freigeschaltet wenn Material vorhanden
- Aktive Waffe bestimmt: erlaubte Angriffs-Combos, Spell-Synergie-Bonus, Animations-Farbe
- `R1` Langdruck → Waffen-Panel öffnen

**Akzeptanzkriterien:**
- [ ] Alle 5 Archetypen wählbar
- [ ] Upgrade-Nodes werden mit Materialien freigeschaltet
- [ ] Aktive Waffe beeinflusst Angriffs-Cooldown
- [ ] Spell-Synergie-Bonus wird korrekt berechnet
- [ ] Waffenwechsel ändert Rim-Glow-Farbe des Spielers

**Fallstricke:**
- Waffen-Daten als `Resource`-Klassen (`.tres`) statt hardcoded, damit Agenten sie unabhängig ändern können
- Synergie-Bonus nicht im Weapon-Script berechnen – Signal an `damage_system.gd` senden

---

#### Stream D – Damage & Line-of-Sight
**Abhängigkeit**: Phase 1 vollständig (unabhängig von A/B/C dieser Phase).

**Zu erstellende Dateien:**
```
/scripts/damage_system.gd         ← Zentrales Schadens-System
/scripts/health_component.gd      ← HP-Verwaltung als Component
/scenes/health_bar.tscn           ← HP-Anzeige über Spieler
```

**Zu implementierende Logik:**
- `health_component.gd`: `current_hp`, `max_hp`, Signal `hp_changed(new_hp)`, `died()`
- `damage_system.gd`: einziger Einstiegspunkt für Schadensbewerbung, prüft LOS vor Anwendung
- LOS-Prüfung: Raycast Angreifer → Ziel, wenn Terrain dazwischen → Schaden reduziert oder geblockt
- Schadensklassen aus `DESIGN.md`: Leicht (8–12), Mittel (18–25), Schwer (35–50)
- Element-Drop bei Treffer: Signal `element_dropped(element_type)` → `spell_system.gd`

**Akzeptanzkriterien:**
- [ ] HP werden korrekt reduziert und im HUD angezeigt
- [ ] LOS-Block reduziert Schaden (Terrain als Deckung nutzbar)
- [ ] `died()`-Signal wird korrekt emittiert
- [ ] Element-Drop funktioniert nach Treffer
- [ ] Alle 3 Schadensklassen produzieren korrekte Werte

**Fallstricke:**
- LOS-Raycast auf separatem Physics-Layer (Terrain-Layer), damit Spieler-Nodes nicht blockieren
- `health_component` als AutoLoad oder als Child-Node – Child-Node bevorzugen für Multiplayer-Kompatibilität

---

### Phase 3 – Multiplayer & State
**Ziel**: Vollständige lokale Multiplayer-Runde mit State-Management, Scoring und rundenbasiertem Flow.

---

#### Stream A – ArenaStateManager
**Abhängigkeit**: Phase 2 vollständig abgeschlossen.

**Zu erstellende Dateien:**
```
/scripts/arena_state_manager.gd   ← Globaler State-Controller (AutoLoad)
/scenes/countdown_ui.tscn         ← Countdown-Anzeige
/scenes/round_end_ui.tscn         ← Runden-End-Screen
```

**Zu implementierende Logik:**
- `enum ArenaState {LOBBY, COUNTDOWN, COMBAT, ROUND_END, SCORE_SCREEN}`
- Nur `arena_state_manager.gd` darf State wechseln
- Alle anderen Systeme reagieren auf Signal `state_changed(new_state: ArenaState)`
- Countdown: 3-Sekunden-Timer, alle Spieler-Inputs gesperrt
- Round-End: Trigger wenn nur 1 Spieler HP > 0 oder Timer abgelaufen
- AutoLoad registrieren in `project.godot` als `ArenaState`

**Akzeptanzkriterien:**
- [ ] State-Wechsel feuern korrekte Signale
- [ ] Countdown-UI erscheint und zählt korrekt herunter
- [ ] Runde endet korrekt bei 1 verbliebenem Spieler
- [ ] Kein System kann State außerhalb des Managers ändern
- [ ] State-Wechsel sind deterministisch (gleiche Inputs → gleiche States)

**Fallstricke:**
- AutoLoad-Reihenfolge in `project.godot` beachten: `ArenaStateManager` muss vor Spieler-Nodes geladen sein
- Keine direkten Node-Referenzen im Manager – nur Signale und Groups

---

#### Stream B – Local Multiplayer
**Abhängigkeit**: Stream A dieser Phase.

**Zu erstellende Dateien:**
```
/scripts/player_spawner.gd        ← Spawnt Spieler-Nodes mit korrektem Input-Index
/scripts/camera_controller.gd    ← Shared/Split-Screen-Logik
/scenes/split_screen_viewport.tscn ← SubViewport-Setup für Split
```

**Zu implementierende Logik:**
- `player_spawner.gd`: Spawnt 2–4 Spieler, weist `player_id` (0–3) und Spawn-Position zu
- Input-Mapping: `player_id` → Joypad-Index (SNES/Xbox/PS automatisch), Keyboard-Fallback lt. DESIGN.md Tastatur-Tabelle
- `camera_controller.gd`: berechnet Mittelpunkt aller aktiven Spieler, lerpt Zoom
- Split-Screen-Trigger: Abstand > 60% Arena-Breite → `SubViewport`-Modus aktivieren
- Zoom-Range: 0.5x – 1.5x, via `Camera2D.zoom`

**Akzeptanzkriterien:**
- [ ] 2 Spieler mit getrennten Controllern spielbar
- [ ] Kamera zentriert sich korrekt zwischen Spielern
- [ ] Zoom skaliert dynamisch
- [ ] Split-Screen aktiviert sich bei großem Abstand
- [ ] 3- und 4-Spieler-Modus ohne Fehler startbar

**Fallstricke:**
- `SubViewport` für Split-Screen hat eigene `Camera2D` pro Viewport – nicht die gleiche Camera teilen
- Joypad-Index kann sich bei Verbinden/Trennen ändern: `Input.get_connected_joypads()` beim Start einlesen

---

#### Stream C – Scoring & HUD
**Abhängigkeit**: Stream A dieser Phase.

**Zu erstellende Dateien:**
```
/scripts/score_manager.gd         ← Punkte & Runden-Tracking
/scenes/scoreboard_ui.tscn        ← End-Screen Scoreboard
/scenes/player_hud.tscn           ← Pro-Spieler HUD (HP, Spells, Waffe)
/scripts/player_hud.gd            ← HUD-Update-Logik
```

**Zu implementierende Logik:**
- `score_manager.gd`: Dictionary `{player_id: {kills, deaths, rounds_won}}`
- Punkte-Event: Signal von `health_component.died()` → `score_manager` aktualisieren
- `player_hud.gd`: reagiert auf `hp_changed`, `spell_slot_changed`, `weapon_changed`-Signale
- Scoreboard: wird bei `SCORE_SCREEN`-State eingeblendet, zeigt Kills/Deaths/Runden
- Best-of-3 oder Best-of-5 konfigurierbar

**Akzeptanzkriterien:**
- [ ] HP-Anzeige reagiert korrekt auf Schadensereignisse
- [ ] Kills und Deaths werden korrekt gezählt
- [ ] Scoreboard erscheint nach Rundenende
- [ ] Rundensieger wird korrekt ermittelt
- [ ] HUD zeigt aktive Spells und Waffe korrekt an

**Fallstricke:**
- HUD direkt an Signale binden, nicht via `_process()` pollen
- Score-Daten nicht im HUD-Script speichern – immer vom `score_manager` abrufen

---

#### Stream D – Network Hooks
**Abhängigkeit**: Stream A + B dieser Phase.

**Zu erstellende Dateien:**
```
/scripts/network_manager.gd       ← Abstraktionsschicht für Netcode
/scripts/sync_component.gd        ← Positions-Sync-Abstraktion
```

**Zu implementierende Logik:**
- `network_manager.gd`: leere Stubs für `host_game()`, `join_game()`, `sync_state()`
- `sync_component.gd`: Marker-Interface – lokal wird nichts gesynct, Online-Version überschreibt
- Alle Spieler-Positionsupdates laufen über `sync_component` (damit Online-Version einfach einhängbar ist)
- `MultiplayerSpawner` und `MultiplayerSynchronizer` als Nodes vorbereiten (deaktiviert)

**Akzeptanzkriterien:**
- [ ] Lokales Spiel läuft weiterhin stabil
- [ ] `network_manager.gd` ist registriert aber hat keinen Effekt
- [ ] Alle Spieler-Bewegungen laufen über `sync_component`
- [ ] `MultiplayerSynchronizer`-Nodes existieren und sind deaktiviert

**Fallstricke:**
- Netcode-Abstraktion zu früh zu komplex machen → einfache Stubs reichen für Phase 3
- Godot `MultiplayerSynchronizer` benötigt eindeutige `name`-Properties auf allen Nodes

---

#### Stream E – Hauptmenü & Lobby
**Abhängigkeit**: Stream A (ArenaStateManager) und Stream C (HUD).

**Zu erstellende Dateien:**
```
/scenes/ui/main_menu.tscn          ← Hauptmenü-Szene
/scenes/ui/settings_menu.tscn     ← Einstellungen (Audio, Video, Controls)
/scenes/ui/lobby.tscn             ← Lobby für Arena-/Spielerauswahl
/scenes/ui/pause_menu.tscn        ← In-Game-Pause-Overlay
/scripts/main_menu.gd             ← Menü-Navigation
/scripts/settings_manager.gd      ← Persistente Einstellungen (user://settings.tres)
/scripts/lobby.gd                 ← Lobby-Logik (Spieler hinzufügen, Arena wählen)
/scripts/pause_menu.gd            ← Pause-Verhalten lt. DESIGN.md
```

**Zu implementierende Logik:**
- Hauptmenü-Buttons: Spielen, Tutorial, Einstellungen, Beenden (lt. `DESIGN.md`)
- Lobby: Spieleranzahl wählen (2–4), Farbe zuweisen, Arena auswählen
- Einstellungen: Lautstärke-Regler, Auflösung, Fullscreen-Toggle, Tastenbelegung anzeigen
- Pause-Menü: `get_tree().paused = true`, nur Fortsetzen/Einstellungen/Aufgeben/Beenden

**Godot-Node-Typen:**
- `Control` → Root aller Menü-Szenen
- `VBoxContainer` → Button-Layout
- `HSlider` → Lautstärke
- `OptionButton` → Auflösung, Arena-Auswahl
- `ColorRect` → Hintergrund mit `moodboard.md`-Farbpalette

**Akzeptanzkriterien:**
- [ ] Hauptmenü startet bei Spielstart (Autoload oder default scene)
- [ ] Aus Lobby heraus wird korrekte Arena mit korrekter Spieleranzahl geladen
- [ ] Einstellungen persistieren in `user://settings.tres`
- [ ] Pause-Menü funktioniert im `COMBAT`-State
- [ ] Kein UI-Element blockiert Gameplay-Input im COMBAT-State

**Fallstricke:**
- `get_tree().paused = true` pausiert **alle** Nodes – Pause-Menü muss `process_mode = PROCESS_MODE_WHEN_PAUSED` haben
- Scene-Transition sauber machen: `get_tree().change_scene_to_packed()`, nicht `queue_free()` der aktuellen Szene

---

### Phase 4 – Polish & Feedback
**Ziel**: Das Spiel muss sich gut anfühlen. Alle Feedback-Systeme werden implementiert, Tutorial und Accessibility kommen hinzu.

---

#### Stream A – Game Feel / Juice
**Abhängigkeit**: Phase 3 vollständig.

**Zu erstellende Dateien:**
```
/scripts/screen_shake.gd          ← Camera-Shake-Controller
/scripts/hit_pause.gd             ← Engine.time_scale Manipulation
/scripts/slow_motion.gd           ← Match-Ende Slow-Motion
```

**Zu implementierende Logik:**
- `screen_shake.gd`: `shake(intensity, duration)` – addiert Noise-Offset zur `Camera2D.offset`
- `hit_pause.gd`: `Engine.time_scale = 0.0` für N Frames, dann zurücksetzen
- `slow_motion.gd`: bei `died()`-Signal des letzten Spielers → 0.3x für 1s
- Controller-Rumble: `Input.start_joy_vibration(device, weak, strong, duration)`
- Alle Intensitäten aus der Effekt-Tabelle in `DESIGN.md` übernehmen

**Akzeptanzkriterien:**
- [ ] Screen Shake bei allen Trefferklassen korrekt
- [ ] Hit-Pause unterbricht alle Animationen (nicht nur Spieler)
- [ ] Slow-Motion am Match-Ende funktioniert
- [ ] Controller-Rumble bei Treffer und Spell-Cast
- [ ] Kein permanenter Shake/Pause durch fehlende Reset-Logik

**Fallstricke:**
- `Engine.time_scale` beeinflusst alle Timers → `Timer`-Nodes die nicht pausieren sollen: `process_callback = TIMER_PROCESS_PHYSICS` und `pause_mode = PROCESS_MODE_ALWAYS`
- Screen Shake akkumuliert bei mehreren gleichzeitigen Hits → Intensitäten addieren, nicht ersetzen

---

#### Stream B – Sound
**Abhängigkeit**: Phase 2 vollständig.

**Zu erstellende Dateien:**
```
/audio/sfx_manager.gd             ← Zentraler Sound-Controller (AutoLoad)
/audio/tone_generator.gd          ← Prozeduraler Ton-Generator
/scenes/audio_player.tscn         ← AudioStreamPlayer2D-Prefab
```

**Zu implementierende Logik:**
- `tone_generator.gd`: generiert kurze Töne via `AudioStreamGenerator` – Frequenz, Dauer, Hüllkurve konfigurierbar
- Pitch-Shift für Combo-Eskalation: jeder Combo-Schritt erhöht Grundfrequenz um 1 Halbton
- `sfx_manager.gd`: reagiert auf alle Spiel-Signale und spielt passende Töne
- Spatial Audio: `AudioStreamPlayer2D` an Quell-Node gebunden, Godot berechnet Panning/Attenuation
- Mono-Audio-Option: alle `AudioStreamPlayer2D.max_distance` auf Maximum setzen

**Akzeptanzkriterien:**
- [ ] Alle 9 Klang-Kategorien aus `DESIGN.md` haben einen Ton
- [ ] Combo-Pitch-Eskalation hörbar
- [ ] Spatial Audio: Treffer von links klingt links
- [ ] Mono-Audio-Option unterdrückt Stereo-Panning
- [ ] Kein Audio-Crackling bei vielen gleichzeitigen Sounds

**Fallstricke:**
- `AudioStreamGenerator` ist Echtzeit-Audio – Buffer-Größe klein halten (512 Samples) für niedrige Latenz
- Zu viele gleichzeitige `AudioStreamPlayer2D`-Nodes: Pool von 16 Playern voralloziieren

---

#### Stream C – VFX
**Abhängigkeit**: Phase 2 vollständig.

**Zu erstellende Dateien:**
```
/scenes/vfx_debris.tscn           ← Tile-Zerstörungs-Partikel
/scenes/vfx_spell_trail.tscn      ← Spell-Projektil-Trail
/scenes/vfx_shockwave.tscn        ← Einschlag-Shockwave-Ring
/scenes/vfx_combo_chain.tscn      ← Combo-Rune-Kette (UI)
/scripts/vfx_manager.gd           ← VFX-Pool-Controller
```

**Zu implementierende Logik:**
- `vfx_manager.gd`: Object-Pool für alle VFX-Szenen (pre-instantiate, recycle)
- Debris: `GPUParticles2D` mit kurzer Lifetime, Richtung = aufwärts + zufälliger Spread
- Spell-Trail: `Line2D` dessen Punkte die letzten N Positionen des Projektils speichert, Alpha nimmt ab
- Shockwave-Ring: `Line2D`-Kreis, der sich in 0.2s aufweitet und ausblendet (Tween)
- Combo-Chain: `HBoxContainer` mit Label-Nodes, jedes Label = ein Rune-Symbol, Farbe = Spielerfarbe

**Akzeptanzkriterien:**
- [ ] Tile-Zerstörung erzeugt sichtbare Debris-Partikel
- [ ] Spell-Projektile haben sichtbaren Trail in Spielerfarbe
- [ ] Shockwave erscheint bei Spell-Einschlag
- [ ] Combo-Chain-UI füllt sich mit jedem Input-Schritt
- [ ] VFX-Pool verhindert Performance-Einbrüche bei vielen Effekten

**Fallstricke:**
- `GPUParticles2D` braucht `emitting = false` nach Auslösung – sonst Dauerschleife
- Line2D-Trail: maximal 20 Punkte speichern, älteste entfernen um Memory-Leak zu vermeiden

---

#### Stream D – Tutorial
**Abhängigkeit**: Phase 3 vollständig.

**Zu erstellende Dateien:**
```
/scenes/tutorial_controller.tscn  ← Tutorial-Ablauf-Controller
/scripts/tutorial_controller.gd   ← 9-Schritte-State-Machine
/scenes/tutorial_highlight.tscn   ← Highlight-Overlay für HUD-Elemente
/scenes/tutorial_dummy.tscn       ← Trainings-Dummy (stationär)
```

**Zu implementierende Logik:**
- `tutorial_controller.gd`: `enum TutorialStep` mit 9 Werten, State-Machine
- Jeder Schritt definiert: Trigger-Bedingung (was muss der Spieler tun), Text-Label, zu highlightender Node
- Highlight: Semi-transparentes `ColorRect` über dem relevanten HUD-Element
- Tutorial-Dummy: `CharacterBody2D` ohne Input, HP = 999, gibt kein Game-Over
- Skip: `Start`-Button hält 2s → Tutorial überspringen, Flag in `UserPreferences`-Resource speichern

**Akzeptanzkriterien:**
- [ ] Alle 9 Schritte aus `DESIGN.md` implementiert
- [ ] Jeder Schritt endet erst nach korrekter Spieler-Aktion
- [ ] Skip funktioniert und wird gespeichert
- [ ] Tutorial startet nicht erneut nach Skip
- [ ] Highlight zeigt immer auf den relevanten UI-Bereich

**Fallstricke:**
- Tutorial-State-Machine nicht mit ArenaStateManager vermischen – Tutorial ist ein separater Layer
- `UserPreferences`-Resource als `.tres` in `user://` speichern, nicht in `res://` (schreibgeschützt bei Exports)

---

#### Stream E – Accessibility
**Abhängigkeit**: Stream A–D dieser Phase abgeschlossen.

**Zu erstellende Dateien:**
```
/scripts/accessibility_manager.gd ← Zentrale Accessibility-Einstellungen (AutoLoad)
/scenes/settings_menu.tscn        ← Einstellungsmenü
/scripts/settings_menu.gd         ← Menü-Logik
/resources/user_preferences.gd    ← Präferenz-Resource-Klasse
```

**Zu implementierende Logik:**
- `accessibility_manager.gd`: lädt `user_preferences` beim Start, wendet Einstellungen global an
- Farbenblindmodus: swappt Spieler-Farb-Dictionary via Signal `color_scheme_changed`
- Combo-Assist: wenn aktiv, überspringt Motion-Geste und erlaubt Button-Only-Input
- Textgröße: `theme_override_font_sizes` auf allen Labels via `SceneTree`-Traversal anpassen
- Remapping: `InputMap`-API zum Überschreiben von Actions zur Laufzeit

**Akzeptanzkriterien:**
- [ ] Alle 3 Farbenblind-Modi wechseln korrekt
- [ ] Combo-Assist ermöglicht vollständiges Spielen ohne Gesten
- [ ] Textgröße ändert sich live ohne Neustart
- [ ] Remapping wird persistent gespeichert
- [ ] Mono-Audio-Option funktioniert

**Fallstricke:**
- `InputMap`-Änderungen zur Laufzeit werden nicht automatisch gespeichert – manuell in `user_preferences` serialisieren
- Farbenblind-Paletten testen mit Simulator (z. B. Coblis) bevor festlegen

---

#### Stream F – Musik-System
**Abhängigkeit**: Stream A (Game Feel) für Timing-Integration.

**Zu erstellende Dateien:**
```
/scripts/music_manager.gd          ← AutoLoad: Layer-basiertes Musik-System
/audio/music/basis_loop.ogg        ← Platzhalter oder prozedurale Generierung
/audio/music/combat_layer.ogg
/audio/music/intensity_layer.ogg
/audio/music/finale_layer.ogg
/audio/music/round_end_stinger.ogg
/audio/music/menu_theme.ogg
```

**Zu implementierende Logik:**
- `MusicManager` als AutoLoad mit `AudioStreamPlayer`-Nodes pro Layer
- Layer-Aktivierung via `volume_db`-Tween (lt. `DESIGN.md` Musik-Konzept)
- Alle Layer rhythmisch synchron (140 BPM), starten gleichzeitig
- State-Listening: `ArenaStateManager`-Signale triggern Layer-Wechsel
  - `LOBBY` → menu_theme aktiv, alle anderen aus
  - `COMBAT` → basis_loop + combat_layer
  - HP < 30% → intensity_layer einblenden
  - 2 Spieler übrig → finale_layer einblenden
  - `ROUND_END` → Stinger abspielen, dann zurück zu basis_loop

**Godot-Node-Typen:**
- `AudioStreamPlayer` → je ein Node pro Layer (kein 2D/3D nötig für Musik)
- `Tween` → Lautstärke-Fades (0.5s Crossfade)

**Akzeptanzkriterien:**
- [ ] Musik spielt ab Hauptmenü-Start
- [ ] Layer-Wechsel reagiert korrekt auf State-Änderungen
- [ ] Kein Knacksen oder Sprung bei Layer-Fades
- [ ] Lautstärke-Regler aus Einstellungen wirkt auf Musik-Bus
- [ ] Mute/Unmute funktioniert

**Fallstricke:**
- `AudioStreamPlayer.play()` startet von 0 – Layers müssen alle bei Spielstart `play()` aufrufen und dann via `volume_db` steuern
- Godot Audio-Bus „Music" muss in `project.godot` oder als `.tres` angelegt werden
- OGG-Dateien müssen Loop-Punkte korrekt gesetzt haben (`.import`-Einstellungen)

---

#### Stream G – Bot-KI
**Abhängigkeit**: Phase 3 vollständig (Damage-System, ArenaStateManager), Stream D (Tutorial) für Trainings-Bot-Nutzung.

**Zu erstellende Dateien:**
```
/scripts/bot_controller.gd         ← Haupt-Bot-Logik (ersetzt Input für Bot-Spieler)
/scripts/bot_difficulty.gd         ← Schwierigkeitsstufen-Konfiguration
/resources/bot_easy.tres           ← Schwierigkeits-Resource (Reaktionszeit, Fehlerrate)
/resources/bot_medium.tres
/resources/bot_hard.tres
/resources/bot_brutal.tres
```

**Zu implementierende Logik (lt. DESIGN.md Bot-KI):**
- Bot ersetzt `_input()` mit eigenem Entscheidungssystem
- State-Machine für Bot: `IDLE → APPROACH → ATTACK → DODGE → RETREAT`
- Pro Schwierigkeitsstufe (lt. DESIGN.md):
  - **Anfänger**: Reaktionszeit 0.8s, keine Combos, zufällige Bewegung
  - **Mittel**: Reaktionszeit 0.4s, 2-Schritt-Combos, Dodge bei erkanntem Projektil
  - **Schwer**: Reaktionszeit 0.15s, volle Combos, prädiktives Dodging
  - **Brutal**: Reaktionszeit 0.05s, perfekte Combos, Frame-genaues Dodging, Terrain-Awareness
- Target-Auswahl: Nächster Spieler mit niedrigstem HP
- LOS-Prüfung vor Angriff
- Bot-Nodes verwenden gleiche `player.tscn`-Szene, nur mit `bot_controller.gd` als Script-Override

**Godot-Node-Typen:**
- `Resource` → `bot_difficulty.gd` extends Resource (Reaktionszeit, Fehlerrate, Combo-Tiefe)
- `Timer` → Entscheidungs-Cooldown pro Schwierigkeitsstufe

**Akzeptanzkriterien:**
- [ ] Bot spielt autonom eine Runde gegen menschlichen Spieler
- [ ] Schwierigkeitsstufe wählbar in Lobby
- [ ] Bot weicht Projektilen aus (ab Schwierigkeit Mittel)
- [ ] Bot nutzt Spells und Combos (ab Schwierigkeit Schwer)
- [ ] Bot blockiert das Spiel nie (kein Freeze, kein ewiges IDLE)

**Fallstricke:**
- Bot darf **nicht** direkt State im ArenaStateManager ändern – nur über reguläre Spieler-Actions
- Brutale KI muss trotzdem Timing-Varianz haben (sonst unmenschlich und frustrierend)
- Bot-Input muss `InputEvent`-kompatibel sein, damit Replay-System (falls geplant) funktioniert

---

### Phase 5 – Steam-Vorbereitung
**Ziel**: Release-fähige Version auf Steam veröffentlichen.

---

#### Stream A – Weitere Arena-Varianten
**Abhängigkeit**: Phase 4 vollständig.

**Zu erstellende Dateien:**
```
/scenes/arenas/arena_crucible.tscn      ← Variante 1 (Standard, bereits vorhanden)
/scenes/arenas/arena_rift_canyon.tscn   ← Variante 2
/scenes/arenas/arena_collapsed.tscn     ← Variante 3
/scenes/arenas/arena_void_ring.tscn     ← Variante 4
/scripts/arena_loader.gd               ← Dynamischer Arena-Loader
```

**Akzeptanzkriterien:**
- [ ] Alle 4 Arenen aus `DESIGN.md` spielbar
- [ ] Arena-Auswahl im Lobby-Screen möglich
- [ ] Zerstörbare Tiles funktionieren in allen Varianten

---

#### Stream B – Online-Multiplayer
**Abhängigkeit**: Phase 3 Stream D (Network Hooks).

**Zu erstellende Dateien:**
```
/scripts/online_network_manager.gd     ← Implementiert network_manager.gd-Interface
/scenes/matchmaking_ui.tscn           ← Host/Join-Screen
```

**Zu implementierende Logik:**
- Godot High-Level Multiplayer API: `ENetMultiplayerPeer`
- `MultiplayerSynchronizer` für Spieler-Positionen und HP aktivieren
- Lag-Kompensation: Input-Prediction für lokalen Spieler
- Host als Authority: alle Schadens- und State-Berechnungen auf Host

**Akzeptanzkriterien:**
- [ ] 2 Spieler über LAN verbindbar
- [ ] Spieler-Positionen synchron
- [ ] Kein Desynch bei Tile-Zerstörung
- [ ] Verbindungsabbruch führt zu sauberem Rückkehr ins Menü

---

#### Stream C – Steam-Integration
**Abhängigkeit**: Stream A + B dieser Phase.

**Zu erstellende Dateien:**
```
/addons/godotsteam/                    ← GodotSteam Plugin
/scripts/steam_manager.gd             ← Steam-API-Wrapper (AutoLoad)
/resources/achievements.tres          ← Achievement-Definitionen
```

**Achievements (Vorschlag):**
| ID | Name | Bedingung |
|----|------|-----------|
| `first_kill` | „Erster Bluttest" | Ersten Kill landen |
| `combo_master` | „Combo-Meister" | Z-Motion 10× erfolgreich |
| `architect` | „Zerstörer" | 500 Tiles zerstören |
| `craftsman` | „Schmiedemeister" | Alle 5 Waffen-Archetypen craften |
| `elementalist` | „Elementarmagier" | Alle 6 Rezepte einmal verwenden |
| `survivor` | „Überlebender" | Match ohne Dodge-Nutzung gewinnen |

**Akzeptanzkriterien:**
- [ ] Steam-Overlay öffnet sich in-game
- [ ] Alle Achievements werden korrekt getriggert
- [ ] Leaderboard für Kills/Runden-Siege funktioniert
- [ ] Steam-Name im Lobby-Screen sichtbar

---

#### Stream D – Build & QA
**Abhängigkeit**: Stream A–C dieser Phase.

**Aufgaben:**
- Godot-Export-Templates für Windows (x64) und Linux (x86_64) einrichten
- `export_presets.cfg` konfigurieren (Steam-AppID, Icon, Produktname)
- Playtesting-Protokoll: 3 Testspieler, 5 Runden je Map, Feedback-Formular
- Balance-Tuning basierend auf Playtesting-Daten (Schadensklassen, Cooldowns)
- Performance-Profiling: Ziel 60 FPS bei 4 Spielern + voller Tile-Zerstörung

**Akzeptanzkriterien:**
- [ ] Windows-Build startet ohne Godot-Editor
- [ ] Linux-Build startet ohne Godot-Editor
- [ ] 60 FPS stabil bei 4 Spielern
- [ ] Kein Crash in 30-minütiger Session
- [ ] Steam-Depot korrekt konfiguriert

---

#### Stream E – Progressions- & Unlock-System
**Abhängigkeit**: Stream C (Steam-Integration für Achievement-Sync) und Phase 4 vollständig.

**Zu erstellende Dateien:**
```
/scripts/progression_manager.gd    ← AutoLoad: Trackt Statistiken & Unlocks
/resources/unlock_definitions.tres ← Alle Unlock-Kategorien und Bedingungen
/scenes/ui/unlock_popup.tscn      ← In-Game-Popup bei neuem Unlock
/scenes/ui/collection_screen.tscn ← Übersicht aller Unlocks
```

**Zu implementierende Logik (lt. DESIGN.md Progressions-System):**
- Persistenz in `user://progress.tres` (lokaler Speicher)
- Statistiken tracken: Matches gespielt/gewonnen, Kills, Tiles zerstört, Stunden gespielt
- Unlock-Kategorien (lt. DESIGN.md):
  - Spieler-Farb-Skins (10/25/50/100 Siege)
  - Rim-Glow-Muster (Achievements)
  - Arena-Farbthemen (Spielzeit)
  - Waffen-Glüh-Farben (Element-Rezepte verwendet)
  - Lobby-Titel (besondere Leistungen)
- Collection-Screen: Grid-Ansicht aller Unlocks, Locked-Items ausgegraut
- Unlock-Popup: kurze Animation (Tween) + Sound-Effekt bei Freischaltung
- Steam-Achievements parallel triggern (`SteamManager.unlock_achievement()`)

**Akzeptanzkriterien:**
- [ ] Fortschritt wird bei Spielende gespeichert
- [ ] Fortschritt bleibt nach Neustart erhalten
- [ ] Unlock-Popup erscheint genau einmal pro neuem Unlock
- [ ] Collection-Screen zeigt korrekte Unlock-Zählung
- [ ] Kein spielerischer Vorteil durch Unlocks (rein kosmetisch)

**Fallstricke:**
- `user://` ist plattformabhängig – auf Steam mit `OS.get_user_data_dir()` prüfen
- Save-Corruption vermeiden: Atomares Schreiben (temp-Datei → rename)
- Unlock-Definitionen als Resource, nicht hardcoded – erleichtert Balancing

---

## Koordinationsregeln für Agenten
- Jeder Agent arbeitet an einem Stream und hält seinen Output in seinem dedizierten Unterordner (`/scenes/`, `/scripts/`, `/audio/`, `/resources/`)
- UI-Szenen kommen unter `/scenes/ui/` (nicht in einen separaten `/ui/`-Ordner)
- Änderungen an shared Interfaces (z. B. `ArenaStateManager`-Signals) werden zuerst in `DESIGN.md` dokumentiert, bevor implementiert wird
- Commits immer mit Stream-Präfix: `[1A] feat: ...`, `[2B] fix: ...` (Phasennummer + Stream-Buchstabe)
- Bei Abhängigkeitskonflikten: Stream blockiert sich selbst (`⚠ BLOCKIERT` in dieser Datei) und erstellt GitHub Issue mit Label `blocked`
- Stream als `✅ ABGESCHLOSSEN` markieren wenn alle Akzeptanzkriterien erfüllt sind
- Pull Request pro abgeschlossenem Stream – kein direkter Push auf `main`
