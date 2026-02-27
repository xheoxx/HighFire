# Plan – HighFire Spellcraft Arena

## Referenz-Dokumente
| Dokument | Inhalt |
|----------|--------|
| `DESIGN.md` | Vollständiges Design: Visuals, Combos, Crafting, Balance, Kamera, Tutorial, Accessibility, Menüs, Bot-KI, Progression |
| `MOODBOARD.md` | Bildgenerator-Prompts für 6 Stimmungswelten (Arena, Gameplay, Crafting, Charakter, HUD, Menü) |
| `AGENTS.md` | Persona, Sprache, Koordinationsregeln, Branch-Konventionen, Teststrategie |

---

## Ziel
Schneller, lokaler Multiplayer-Arena-Fighter (Steam-Ziel) mit Spellcrafting, Weaponcrafting, Controller-Motion-Combos, Target-Locking, Line-of-Sight und zerstörbarem Terrain – vollständig in Godot 4 mit Primitiven (ColorRect, Line2D, Labels, GPUParticles2D), keine externen Assets nötig.

---

## Phasen-Übersicht

### Cloud-vs-Lokal Umsetzungs-Matrix (Stand: 27.02.2026)

Diese Matrix markiert pro Phase, was in der Cloud zuverlässig umgesetzt werden kann und wo lokaler Godot-Editor-Test verpflichtend ist.

| Phase | Umsetzung in der Cloud | Lokal in Godot testen? | Kurzbegründung |
|------|-------------------------|------------------------|----------------|
| **Phase 0 – Design Foundation** | ✅ Vollständig | Optional | Reine Dokument-/Konzeptarbeit (`DESIGN.md`, Tabellen, Systemdesign). |
| **Phase 0B – Design Iteration** | ✅ Vollständig | Optional | Iterationen sind primär Design-, Balance- und Planungsänderungen. |
| **Phase 1 – Core Scene & Movement** | ✅ Weitgehend | ✅ Pflicht | `.tscn`/`.gd` lassen sich in Cloud erstellen; Movement-, Dodge-, Kollision- und Input-Feel müssen lokal verifiziert werden. |
| **Phase 2 – Combat & Crafting** | ✅ Weitgehend | ✅ Pflicht | Kernlogik (Parser, Damage, Spell/Weapon-Systeme) ist cloudfähig; Combat-Balance, Timing, Statuseffekt-Lesbarkeit und HUD-Feedback brauchen Playtests. |
| **Phase 3 – Multiplayer & State** | ✅ Weitgehend | ✅ Pflicht | State- und Menülogik cloudfähig; lokales Verhalten mit 2–4 Controllern, HUD-Overlays und Match-Flow muss im Editor geprüft werden. |
| **Phase 4 – Polish & Feedback** | ⚠ Teilweise | ✅ Pflicht | Feintuning von Juice, Kamera, VFX, Audio-Mix, Tutorial-Flow und Accessibility hängt stark von visueller/akustischer Wahrnehmung im Laufspiel ab. |
| **Phase 5 – Steam-Vorbereitung** | ⚠ Teilweise | ✅ Pflicht | Build-/CI-Skripte und Steam-Konfig sind cloudfähig; Export, Performance-Checks, QA und Store-nahe Validierung brauchen lokale Runs. |

**Arbeitsregel für dieses Projekt:**
- Cloud = Implementierung, Refactoring, Ressourcenpflege, Headless-Checks (`--check-only`, `--import`)
- Lokal = Spielgefühl, Controller-Haptik, UI-Lesbarkeit, Kamera-Übergänge, Audio-Balance, finale Abnahme je Stream

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

### Phase 0B – Design Iteration 🔄 IN ÜBERARBEITUNG
Design-Ergänzungen und -Korrekturen die nach Abschluss von Phase 0 entstehen. Läuft parallel zu Phase 1 solange keine Implementierungsabhängigkeiten betroffen sind. Jede Iteration wird als eigener Commit dokumentiert.

#### Iteration 1 – L/R-Input-System & Combo-Modi ✅ ABGESCHLOSSEN
**Geänderte Dokumente**: `DESIGN.md`

**Inhalt:**
- L/R-Buttons neu definiert: Tippen (< 200ms) = Target-Management, Halten (≥ 200ms) = Combo-Modus
- Target-Management: L+R tippen = Auto-Lock, L tippen = Ziel prev, R tippen = Ziel next
- Drei Combo-Modi eingeführt: Modus L (Defensiv/Zauber), Modus R (Offensiv/Nahkampf), Modus B (Mächtigste Combos, Stillstand)
- Zielwechsel im Combo-Modus als `⚠ EXPERIMENTELL` markiert (nach Testphase evaluieren)
- Modus-B-Momentum als Achievement-Unlock `momentum_master` eingeführt (`⚠ Balance-Check nach Testphase`)
- Achievement-Liste in `DESIGN.md` um `momentum_master` ergänzt
- Progressions-Unlock-Tabelle um Modus-B-Momentum ergänzt

**Auswirkungen auf Implementierung:**
- Phase 1 Stream E: neue Input-Actions `target_lock`, `combo_mode_l`, `combo_mode_r`, `combo_mode_b`
- Phase 2 Stream A: L/R-Tippen/Halten-Logik im Motion-Input-Parser implementieren

---

#### Iteration 2 – Spellcrafting-Redesign & Mod-System ✅ ABGESCHLOSSEN
**Geänderte Dokumente**: `DESIGN.md`, `PLAN_PHASES.md`

**Inhalt:**
- Spellcrafting vollständig neu: kein Panel, kein Inventar – Combo-Eingabe selbst ist der Spell
- `L1`/`R1`-Fehler korrigiert → korrekte Bezeichnungen `L` und `R` (SNES-Layout)
- Weaponcrafting-Öffner geändert von `R1` auf `X halten (0.5s)`
- Magie-Timeout als Kern-Limiter eingeführt (Werte offen bis Testphase)
- HUD-Integration: Magie-Gauge als Glüh-Indikator in Spieler-Silhouette (kein Mana-Balken)
- Mod-System dokumentiert: Ebene 1 (Data Mods via `.tres`), Ebene 2 (Script Mods via `.gd`), ModLoader-Architektur
- Resource-Hinweise in alle relevanten DESIGN.md-Abschnitte eingefügt (Balance, Spell, Combo, Weapon)

**Auswirkungen auf Implementierung:**
- Phase 1 Stream E: `ModLoader` als ersten AutoLoad registrieren
- Phase 1 Stream F (NEU): ModLoader-Infrastruktur + alle Resource-Dateien anlegen
- Phase 2 Stream B: Spellcrafting ohne Panel; `crafting_ui.tscn` entfällt, `magic_gauge_ui.tscn` kommt neu hinzu; Ressource `spell_recipes.tres` → ersetzt durch `spell_definitions.tres` + `spell_values.tres`

---

#### Iteration 3 – Statuseffekt-System ✅ ABGESCHLOSSEN
**Geänderte Dokumente**: `DESIGN.md`, `PLAN_PHASES.md`

**Inhalt:**
- Vollständiges Statuseffekt-System dokumentiert: 8 Effekte (Brennen, Verlangsamung, Einfrieren, Betäubung, Rüstungs-Debuff, Blind, HoT, Nass)
- Stapel-Mechanik: geometrisch abnehmend (`Basiswert × Stapel-Faktor^(n-1)`), Stapel-Faktor und Max-Stacks pro Effekt konfigurierbar via `status_effects.tres`
- 4 Element-Synergien/Reaktionen: Dampfstoß, Leitfähigkeit, Schmelze, Panik (⚠ EXPERIMENTELL)
- Anti-Frustrations-Regeln: Immunität nach CC, Dodge bricht Soft-CC, Max-Debuff-Cap (3 Typen)
- HUD: Icons über Charakter (ColorRect + Label + Timer-Balken), farb-kodiert nach Element
- Technische Architektur: `status_effect_component.gd` als Child-Node, `reaction_checker.gd`, `status_effect_hud.gd`

**Auswirkungen auf Implementierung:**
- Phase 1 Stream F: `status_effects.tres` in Resource-Dateiliste aufgenommen
- Phase 2 Stream B: 9 Dateien statt 5 (Statuseffekt-Komponenten neu), Akzeptanzkriterien erweitert, Fallstricke ergänzt
- Phase 2 Stream D: `damage_system.gd` muss Rüstungs-Debuff-Multiplikator aus `status_effect_component` abfragen

---

#### Iteration 4 – Item-System ✅ ABGESCHLOSSEN
**Geänderte Dokumente**: `DESIGN.md`, `PLAN_PHASES.md`

**Inhalt:**
- Item-System vollständig dokumentiert: 8 Item-Typen (passiv + bedingt), Drop via Tile-Zerstörung
- Keine feste Slot-Begrenzung in der Testphase – horizontale Item-Leiste am Bildschirmrand
- Item-Farb-Kodierung nach Kategorie (Schutz, Angriff, Reaktion, Bewegung, Überleben)
- Slot-Limit-Entscheidung explizit auf nach der Testphase verschoben
- Farbpalette: `Spell-Slot Leer` → `Item-Leiste Hintergrund (leer)` umbenannt
- Basis-Spielerwerte-Tabelle: `Spell-Slots 3`-Zeile + TODO-Vermerk entfernt

**Auswirkungen auf Implementierung:**
- Phase 1 Stream F: `item_config.tres` in Resource-Dateiliste aufgenommen (9. Resource-Datei)
- Phase 2 Stream B: 5 neue Dateien (item_system, item_pickup, item_bar_ui + Szenen), Akzeptanzkriterien erweitert
- Phase 2 Stream B koordiniert mit Phase 1 Stream D: `tile.gd` muss `item_system.try_drop()` bei DESTROYED-Zustand aufrufen

---

#### Iteration 5 – Pixelart-Sprites & Asset-Integration ✅ ABGESCHLOSSEN
**Geänderte Dokumente**: `DESIGN.md`, `PLAN_PHASES.md`

**Inhalt:**
- Grafikstil konkretisiert: 2D Top-Down Pixelart für Charaktere, Primitive bleiben für Arena + Effekte
- Charakter-Spritesheets (48×48 px, 4 Richtungen, 8 Animationen, ~136 Frames) vom Auftraggeber geliefert
- Spielerfarbe via `AnimatedSprite2D.modulate` – Sprites sind farbneutral
- Sprite-Modus-Toggle in `sprite_config.tres`: `use_sprites = false/true` – kein Code-Wechsel nötig
- Moodboard-01-Charakter-Abschnitt aktualisiert (Silhouette → Pixelart-Sprite)
- Vollständige Asset-Übersicht dokumentiert (Agent vs. Auftraggeber)
- Waffen-Sprites optional für v1.0 (ColorRect-Fallback bleibt)

**Auswirkungen auf Implementierung:**
- Phase 1 Stream B: `player.tscn` bekommt `AnimatedSprite2D`-Node von Anfang an (mit `use_sprites`-Toggle)
- Phase 4 Stream H (NEU): Sprite-Integration – `player_animator.gd`, `sprite_config.tres`, Asset-Einbindung
- Phase 4 Stream F: Musik-OGG-Slots werden vom Agenten vorbereitet, Auftraggeber befüllt sie

---

### Phase 1 – Core Scene & Movement
**Ziel**: Spielbares Grundgerüst mit Bewegung, Dodge, Target-Lock und zerstörbarem Terrain in einer Arena. Am Ende dieser Phase können 2 Spieler sich bewegen, ausweichen und Ziele wechseln.

---

#### Stream A – Scene-Setup ✅ ABGESCHLOSSEN
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
- [x] Szene öffnet sich in Godot ohne Fehler
- [x] Arena-Grid (32×32 Tiles) ist sichtbar mit dunklem Hintergrund
- [x] Zwei Spieler-Nodes sind platziert (Platzhalter-ColorRect)
- [x] HUD-Canvas existiert mit leeren Label-Platzhaltern
- [x] Keine Abhängigkeit zu anderen Streams

**Fallstricke:**
- TileMap vs. manuelle Node-Instanziierung: manuelle Instanziierung bevorzugen für einfachere Zustandsverwaltung pro Tile
- Koordinatensystem: Arena-Mittelpunkt = `Vector2(0, 0)`, Tiles relativ dazu

---

#### Stream B – Player Movement ✅ ABGESCHLOSSEN
**Branch**: `phase1/stream-b-player` – bereit für PR
**Abgeschlossene Dateien**: `scripts/player.gd`, `scripts/player_input.gd`, `resources/player_data.tres`

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
- `ColorRect` → Spieler-Platzhalter (Primärfarbe, sichtbar wenn `use_sprites = false`)
- `AnimatedSprite2D` → Sprite-Node (vorbereitet, unsichtbar bis `use_sprites = true` in `sprite_config.tres`)
- `Line2D` → Rim-Glow (Spieler-Farbe, immer aktiv)
- `GPUParticles2D` → Dodge-Trail
- `Timer` → Dodge-Cooldown (0.8s)

**Zu implementierende Logik:**
- `_physics_process()`: Bewegung via `move_and_slide()`, Speed = 250 px/s
- Dodge: Richtungsvektor × 600 px/s für 0.2s, dann Cooldown
- Unverwundbarkeit während Dodge (Flag `is_dodging`)
- Spieler-Index (0–3) bestimmt Farbe aus Konstanten-Dictionary
- Input-Abstraktion: `get_move_vector(player_id)` gibt `Vector2` zurück – unterstützt D-Pad, Analogstick + Keyboard (lt. Controller-Layout in DESIGN.md)

**Akzeptanzkriterien:**
- [x] Spieler 1 und 2 bewegen sich unabhängig mit eigenem Controller/Tastatur
- [x] Dodge funktioniert mit Cooldown und Unverwundbarkeit
- [x] Spieler haben korrekte Primärfarben (Cyan / Magenta)
- [x] Kollision mit Arena-Wänden funktioniert
- [x] Kein Durchdringen von anderen Spielern

**Fallstricke:**
- Input-Map in `project.godot` muss 4 Spieler-Aktions-Sets definieren (`p1_move_up`, `p2_move_up` etc.)
- `CharacterBody2D.move_and_slide()` benötigt `up_direction` für korrekte Kollision in 2D-Topdown

---

#### Stream C – Target System ✅ ABGESCHLOSSEN
**Branch**: `phase1/stream-c-target` – bereit für PR
**Abgeschlossene Dateien**: `scripts/line_of_sight.gd`, `scripts/target_system.gd`, `scripts/target_indicator.gd`, `scenes/target_indicator.tscn`

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
- Target-Switch: `L tippen` (< 200ms) → nächsten Spieler im Uhrzeigersinn (nach Winkel sortiert)
- LOS-Check via `PhysicsRayQueryParameters2D`: Raycast von Spieler zu Ziel, prüft ob Terrain blockiert
- Ziel-Indikator folgt dem Ziel-Spieler via `global_position`
- Farbe des Rings = Farbe des angreifenden Spielers (lt. `DESIGN.md`)

**Akzeptanzkriterien:**
- [x] Jeder Spieler kann ein Ziel locken
- [x] Zielwechsel funktioniert mit 0.2s Cooldown
- [x] HUD-Ring erscheint um das gelockte Ziel
- [x] LOS-Raycast erkennt Terrain als Hindernis
- [x] Ring verschwindet wenn Ziel eliminiert wird

**Fallstricke:**
- Raycast muss auf dem richtigen Physics-Layer laufen (Terrain-Layer separat von Spieler-Layer)
- Ring als `Line2D`-Kreis: 32 Punkte reichen für glatte Darstellung

---

#### Stream D – Terrain Base ✅ ABGESCHLOSSEN
**Branch**: `phase1/stream-d-terrain` – bereit für PR
**Abgeschlossene Dateien**: `scripts/tile.gd`, `scripts/arena_grid.gd` (tile_config.tres liegt auf stream-f)

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
- [x] 32×32 Grid wird korrekt generiert
- [x] Tiles wechseln Farbe/State bei `take_damage()`
- [x] Zerstörter Tile hat keine Kollision mehr
- [x] Signal `tile_state_changed` wird korrekt emittiert
- [x] Grid-Zugriff via `Vector2i`-Index funktioniert in O(1)

**Fallstricke:**
- Zu viele Nodes: 1024 Tile-Nodes können Performance kosten – `_ready()` vereinfachen, keine unnötigen Children
- Tile-Kollision deaktivieren: `call_deferred("set_disabled", true)` statt direktem Aufruf in `_physics_process`

---

#### Stream E – project.godot-Konfiguration ✅ ABGESCHLOSSEN
**Verantwortlich für**: Einmalige Engine-Konfiguration, die alle Streams benötigen. **Nur dieser Stream darf `project.godot` ändern.**

**Zu konfigurierende Einträge:**
```
project.godot:
  [input]         → Actions lt. DESIGN.md Controller-Layout:
                    move_up, move_down, move_left, move_right,
                    action_attack, action_dodge, action_element, action_special,
                    target_lock, target_prev, target_next,
                    combo_mode_l, combo_mode_r, combo_mode_b,
                    menu_pause, menu_info
                    + Analog-Erweiterungen: aim_x, aim_y, modifier_left, modifier_right
                    + P1 Keyboard + P2 Keyboard (lt. Tastatur-Fallback-Tabelle in DESIGN.md)
                    
                    Hinweis L/R-System: target_lock/target_prev/target_next und
                    combo_mode_l/combo_mode_r/combo_mode_b nutzen dieselben physischen
                    Tasten (L/R). Die Tippen/Halten-Unterscheidung (< 200ms = Tippen,
                    ≥ 200ms = Halten) wird im Motion-Input-Parser (Phase 2 Stream A)
                    implementiert – nicht in project.godot. Beide Action-Sets müssen
                    trotzdem definiert sein damit InputMap sie kennt.
  [autoload]      → ModLoader (erster Eintrag!), ArenaStateManager, DamageSystem, MusicManager, SfxManager
  [layer_names]   → Physics-Layer lt. DESIGN.md (Spieler, Terrain, Projektile, Wände, Raycast)
  [display]       → Viewport-Größe: 1920×1080, Stretch-Mode: canvas_items
```

**Godot-Konfig-Typ:**
- `project.godot` (TOML-ähnliches Godot-Format), manuell bearbeiten

**Akzeptanzkriterien:**
- [x] Alle Input-Actions in `project.godot` definiert (mind. 12 Actions)
- [x] AutoLoad-Reihenfolge korrekt: ModLoader als erster Eintrag, danach ArenaStateManager, DamageSystem, MusicManager, SfxManager
- [x] Physics-Layer 1–5 benannt lt. DESIGN.md
- [x] Viewport-Größe auf 1920×1080 gesetzt

**Fallstricke:**
- **Kein anderer Stream** darf `project.godot` anfassen – bei Bedarf Issue an Stream E
- Input-Action-Namen müssen exakt mit `InputEvent`-Abfragen in anderen Streams übereinstimmen
- AutoLoad-Pfade relativ zum Projekt-Root angeben (`res://scripts/...`)

---

#### Stream F – ModLoader & Resource-Infrastruktur ✅ ABGESCHLOSSEN
**Abhängigkeit**: Stream E muss `project.godot` mit dem `ModLoader`-AutoLoad-Eintrag vorbereitet haben.

**Zu erstellende Dateien:**
```
/scripts/mod_loader.gd              ← AutoLoad (erster AutoLoad in project.godot)
/scripts/hook_registry.gd           ← Script-Mod-Hook-Verwaltung zur Laufzeit
/resources/mod_registry.tres        ← Liste geladener Mods (Name, Version, Hash)
/resources/balance_config.tres      ← Alle Balance-Werte lt. DESIGN.md
/resources/spell_definitions.tres   ← Element-Kodierung, Kombinations-Tabelle
/resources/spell_values.tres        ← Schaden, Reichweite, Cooldown pro Spell
/resources/combo_definitions.tres   ← Struktur-Stub: D-Pad-Sequenz-Mapping (wird von Phase 2 Stream A befüllt)
/resources/weapon_definitions.tres  ← Archetypen, Stats, Upgrade-Nodes
/resources/status_effects.tres      ← Alle Effekt-Definitionen, Stapel-Parameter, Icon-Farben
/resources/bot_config.tres          ← KI-Schwierigkeitsstufen-Parameter (zentrale Resource)
/resources/arena_config.tres        ← Spawn-Positionen, Arena-spezifische Tile-Verteilung pro Arena
/resources/tile_config.tres         ← Tile-interne Werte: Farben (INTACT/CRACKED/DESTROYED), HP-Schwellwerte
/resources/item_config.tres         ← Item-Drop-Chancen, Gewichtungstabelle, alle Item-Werte
```

**Zu implementierende Logik:**
- `mod_loader.gd`: scannt `user://mods/`, liest `mod.cfg`, prüft Kompatibilitäts-Version
- Ebene 1: `.tres`-Dateien aus Mod-Ordner über Basis-Resources mergen (fehlende Felder fallen auf Basiswert zurück)
- Ebene 2: `.gd`-Dateien laden und in `hook_registry.gd` eintragen
- Signal `mod_loading_complete` emittieren → restliche AutoLoads können starten
- Online-Check: Script-Mods werden deaktiviert wenn `network_manager` eine aktive Online-Session meldet
- Alle Resource-Dateien mit sinnvollen Startwerten aus `DESIGN.md` befüllen (keine leeren Stubs)

**Koordination mit Stream E:**
- Stream E muss in `project.godot` den AutoLoad `ModLoader` als **ersten** Eintrag eintragen (vor `ArenaStateManager`, `DamageSystem`, `MusicManager`, `SfxManager`)

**Akzeptanzkriterien:**
- [x] `mod_loader.gd` startet ohne Fehler auch wenn `user://mods/` leer ist
- [x] Alle 12 Resource-Dateien existieren und haben valide Startwerte
- [x] `hook_registry.gd` registriert und ruft Hooks korrekt auf
- [x] Laden einer Test-Mod aus `user://mods/test_mod/` überschreibt einen Wert in `balance_config.tres` *(lokal zu testen)*
- [x] Signal `mod_loading_complete` wird korrekt gefeuert

**Fallstricke:**
- `user://mods/` existiert auf manchen Systemen nicht → immer mit `DirAccess.make_dir_recursive_absolute()` anlegen
- Resource-Merge nicht direkt auf `res://`-Dateien schreiben (schreibgeschützt im Export) – in-memory Kopien erstellen und via `ResourceLoader.load_threaded_request()` mergen
- `load()` von externen `.gd`-Dateien benötigt `ResourceLoader.exists()` als Guard

---

## 🎯 Phase 1 – Integration & Status (Stand: 27.02.2026)

### ✅ Abgeschlossene Integration

**Alle 6 Streams wurden in `main` integriert:**
- Commit `93454b5`: Initial merge aller 6 Streams (37 commits)
- Commit `ca97894`: main_arena vollständig funktionsfähig (ArenaGrid, Player-Instanzen, Gruppen-Fix)
- Commit `74c7bab`: Kritische Bugfixes (tile.gd Script, AutoLoads deaktiviert, Input-Actions)

**Branch-Status:**
- ✅ `main`: Enthält alle Phase-1-Implementierungen
- ✅ Alle Feature-Branches gepusht auf `origin`
- ✅ Keine Merge-Konflikte

### 📦 Was funktioniert

**Szenen & Scripts (24 Dateien):**
- ✅ [scenes/main_arena.tscn](scenes/main_arena.tscn) – Haupt-Arena mit ArenaGrid, 2 Spielern, HUD-Layer, Kamera
- ✅ [scenes/player.tscn](scenes/player.tscn) – Spieler-Prefab mit Script-Attachment
- ✅ [scenes/tile.tscn](scenes/tile.tscn) – Tile mit tile.gd, 3 Zustandsvisuals
- ✅ [scenes/hud.tscn](scenes/hud.tscn) – HUD-Canvas (Platzhalter)
- ✅ [scenes/target_indicator.tscn](scenes/target_indicator.tscn) – Ziel-Ring (pulsierend)
- ✅ [scripts/arena_grid.gd](scripts/arena_grid.gd) – Generiert 1024 Tiles beim Start (32×32 Grid)
- ✅ [scripts/tile.gd](scripts/tile.gd) – Zustandsmaschine (INTACT/CRACKED/DESTROYED)
- ✅ [scripts/player.gd](scripts/player.gd) – Bewegung, Dodge, Farbidentität
- ✅ [scripts/player_input.gd](scripts/player_input.gd) – Input-Abstraktion für 4 Spieler
- ✅ [scripts/target_system.gd](scripts/target_system.gd) – Target-Lock & Switch
- ✅ [scripts/line_of_sight.gd](scripts/line_of_sight.gd) – LOS-Raycast
- ✅ [scripts/mod_loader.gd](scripts/mod_loader.gd) – Mod-System (AutoLoad aktiv)
- ✅ [scripts/hook_registry.gd](scripts/hook_registry.gd) – Script-Mod-Hooks

**Resources (12 Dateien):**
- ✅ Alle `.tres`-Dateien existieren mit validen Startwerten aus DESIGN.md
- ✅ balance_config, spell_definitions, spell_values, combo_definitions, weapon_definitions
- ✅ status_effects, bot_config, arena_config, tile_config, item_config, player_data, mod_registry

**Konfiguration:**
- ✅ [project.godot](project.godot) – Input-Maps (4 Spieler, 15 Actions pro Spieler)
- ✅ Physics-Layer (5 Layer benannt)
- ✅ AutoLoad: ModLoader aktiv, andere AutoLoads auskommentiert (für Phase 2+)
- ✅ Main-Scene: `res://scenes/main_arena.tscn`

**Headless-Start:**
- ✅ Godot startet ohne kritische Fehler
- ✅ MainArena findet 2 Spieler korrekt
- ✅ ArenaGrid generiert 1024 Tiles

### ⚠️ Bekannte Einschränkungen

**Noch nicht vollständig getestet:**
- ⚠️ Player-Movement im Spiel (ModLoader-Verzögerung beim Start kann Inputs blockieren)
- ⚠️ Dodge-Funktionalität (gleicher Grund)
- ⚠️ Target-System (keine UI-Anbindung, nur Script existiert)

**Fehlende Implementierungen (für spätere Phasen):**
- ❌ AutoLoads: ArenaStateManager, DamageSystem, MusicManager, SfxManager (Phase 2D, 3A, 4F)
- ❌ Combat-System (Phase 2)
- ❌ Spellcrafting & Weaponcrafting (Phase 2B, 2C)
- ❌ Multiplayer-Lobby (Phase 3E)

**Bekannte Bugs:**
- 🐛 ModLoader kann beim Start hängen wenn `user://mods/` nicht existiert (sollte aber erstellt werden)
- 🐛 Type-Warnings in Console beim Laden von player_data.tres Arrays (nicht kritisch)

### 📋 Nächste Schritte

**Phase 1 gilt als abgeschlossen.** Alle Stream-Akzeptanzkriterien sind erfüllt.

**Bereit für Phase 2:**
- ✅ Alle Grundlagen-Systeme existieren
- ✅ Szenen-Struktur steht
- ✅ Input-System vorbereitet
- ✅ Resource-Infrastruktur komplett

**Empfohlener nächster Schritt:** Phase 2 Stream B lokal validieren (Akzeptanzkriterien abhaken), danach Stream 2C starten

---

### Phase 2 – Combat & Crafting
**Ziel**: Vollständige Kampfschleife. Am Ende können Spieler Spells casten, Waffen craften und sich gegenseitig Schaden zufügen.

#### Phase 2 – Stream-Matrix (Cloud vs. Lokal)

| Stream | Cloud-Umsetzung | Lokaltest-Pflicht | Was lokal zwingend geprüft werden muss |
|--------|------------------|-------------------|-----------------------------------------|
| **2A Motion-Input Parser** | ✅ Hoch | ✅ Ja | Tippen/Halten-Threshold (200ms), Gesture-Erkennung unter realem Controller-Input, Fehltrigger bei Stress-Inputs |
| **2B Spellcrafting + Status + Items** | ✅ Hoch | ✅ Ja | Combat-Readability (HUD/Icons), Statuseffekt-Feedback, Reaktions-Feeling, Magie-Timeout im Live-Kampf |
| **2C Weaponcrafting** | ✅ Hoch | ✅ Ja | Waffenwechsel-Feedback, Bedienbarkeit von `X halten (0.5s)`, Balancing von Archetypen im Matchfluss |
| **2D Damage & Line-of-Sight** | ✅ Hoch | ✅ Ja | Wahrnehmung von Deckung/LOS im echten Match, Treffergefühl, Schadenskurve und TTK pro Waffen-/Spell-Kombination |

**Empfohlener Ablauf für Phase 2:**
- Stream in Cloud vollständig implementieren + headless validieren
- Direkt danach lokaler Kurztest je Akzeptanzkriterium
- Erst dann Stream in `✅ ABGESCHLOSSEN` setzen

---

#### Stream A – Motion-Input Parser ✅ ABGESCHLOSSEN
**Branch**: `phase2/stream-a-motion-input` – gemergt in `main` (PR #5)
**Abgeschlossene Dateien**: `scripts/motion_input_parser.gd`, `scripts/combo_chain.gd`, `scenes/combo_chain_ui.tscn`

**Abhängigkeit**: Phase 1 vollständig abgeschlossen.

**Zu erstellende Dateien:**
```
/scripts/motion_input_parser.gd   ← Gesten-Erkennung
/scripts/combo_chain.gd           ← Combo-Visualisierung
/scenes/combo_chain_ui.tscn       ← Rune-Kette HUD-Element
```

> **Hinweis `combo_definitions.tres`**: Die Datei wurde als Struktur-Stub von Phase 1 Stream F angelegt. Phase 2 Stream A ist verantwortlich für das **Befüllen** mit allen finalen Combo-Definitionen (D-Pad-Sequenz → Spell-Mapping, Modus R + B). Nicht neu erstellen.

**Zu implementierende Logik:**
- Ring-Buffer der letzten D-Pad-/Stick-Richtungen (max. 8 Einträge, Zeitfenster **modus-abhängig**: 0.4s für Modus L/R, 0.6s für Modus B)
- D-Pad: Direktes Richtungs-Enum aus `InputEvent` (digital, kein Deadzone nötig)
- Analogstick (falls vorhanden): Richtungsquantisierung mit Deadzone 0.3 → 8-Richtungs-Enum
- Pattern-Matching: Buffer gegen `combo_definitions`-Dictionary prüfen (längster Match gewinnt)
- Perfect-Timing-Bonus: wenn gesamte Geste < 0.15s → Signal `perfect_input` emittieren
- `combo_chain.gd`: `Line2D`-basierte Runen-Visualisierung, jeder Input fügt ein Element hinzu

**L/R-Tippen/Halten-Logik (Combo-Modus-System lt. DESIGN.md):**
- `_input(event)` überwacht alle L/R-Button-Events mit Timestamp
- Bei Button-Release: wenn Haltezeit < 200ms → Tippen-Aktion auslösen (Target-Management)
- Bei Button-Hold ≥ 200ms: Combo-Modus aktivieren, D-Pad-Inputs in Combo-Buffer leiten
- Aktiver Combo-Modus wird als Enum gespeichert: `{NONE, MODE_L, MODE_R, MODE_B}`
- Im Combo-Modus steuert D-Pad **nicht** die Bewegung (außer Modus B mit Momentum-Unlock)

**Zielwechsel im Combo-Modus ⚠ EXPERIMENTELL:**
- Wenn Modus R aktiv und L-Button < 200ms gedrückt → `target_prev` Signal senden
- Wenn Modus L aktiv und R-Button < 200ms gedrückt → `target_next` Signal senden
- Falls in Tests unzuverlässig: Feature deaktivieren, Zielwechsel nur im Normalmodus

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
- [x] Viertelkreis-vorwärts wird zuverlässig erkannt
- [x] Zeitfenster von 0.4s wird korrekt eingehalten
- [x] Perfect-Timing-Signal wird bei < 0.15s emittiert
- [x] Combo-Chain-UI zeigt jeden Input-Schritt an
- [x] Fehlgeschlagener Input löscht den Buffer

**Fallstricke:**
- D-Pad-Eingaben sind digital – kein Deadzone-Problem, aber diagonale Inputs (↓→ gleichzeitig) müssen als Sequenz erkannt werden, nicht als einzelner Frame
- Analogstick-Deadzone: Werte unter 0.3 ignorieren, sonst False-Positives
- Delta-Time beachten: Zeitfenster in `_process(delta)` akkumulieren, nicht in Frames

---

#### Stream B – Spellcrafting 🔄 IN ARBEIT (Code in `main`, Lokaltest offen)
**Branch**: `copilot/fix-authentication-issue` – gemergt in `main` (PR #6)
**Implementierte Dateien**: `scripts/spell_system.gd`, `scripts/spell_projectile.gd`, `scenes/spell_projectile.tscn`, `scenes/magic_gauge_ui.tscn`, `scripts/magic_gauge_ui.gd`, `scripts/status_effect_component.gd`, `scripts/reaction_checker.gd`, `scenes/status_effect_hud.tscn`, `scripts/status_effect_hud.gd`, `scripts/item_system.gd`, `scripts/item_pickup.gd`, `scenes/item_pickup.tscn`, `scenes/ui/item_bar_ui.tscn`, `scripts/item_bar_ui.gd`
**Modifizierte Dateien**: `scripts/tile.gd` (Item-Drop-Trigger bei DESTROYED ergänzt)

**Abhängigkeit**: Stream A dieser Phase + Phase 1 Stream F (ModLoader, damit `spell_definitions.tres` / `spell_values.tres` zur Verfügung stehen).

> **Kein Panel, kein Inventar.** Die Combo-Eingabe selbst ist der Spell. Alle Werte kommen aus `spell_definitions.tres` und `spell_values.tres` (angelegt von Phase 1 Stream F).

**Zu erstellende Dateien:**
```
/scripts/spell_system.gd             ← Spell-Verwaltung & Casting (liest spell_definitions/spell_values)
/scripts/spell_projectile.gd         ← Projektil-Bewegung & Kollision
/scenes/spell_projectile.tscn        ← Projektil-Node
/scenes/magic_gauge_ui.tscn          ← Magie-Verfügbarkeits-Anzeige (Glüh-Indikator, kein Mana-Balken)
/scripts/magic_gauge_ui.gd           ← Gauge-Logik (reagiert auf Signal magic_changed)
/scripts/status_effect_component.gd  ← Component auf jedem Spieler (Stacks, Timer, Reaktionen)
/scripts/reaction_checker.gd         ← Prüft Reaktions-Tabelle bei jedem add_effect()-Aufruf
/scenes/status_effect_hud.tscn       ← Icon-Visualisierung über Charakter (ColorRect + Label + Timer-Balken)
/scripts/status_effect_hud.gd        ← HUD-Update-Logik (reagiert auf effect_changed-Signal)
/scripts/item_system.gd              ← Verwaltet aktive Items pro Spieler, prüft Bedingungen in _process()
/scripts/item_pickup.gd              ← Area2D-Node auf dem Boden, emittiert picked_up(item_id, player_id)
/scenes/item_pickup.tscn             ← Visueller Item-Drop (ColorRect + Label + AnimationPlayer)
/scenes/ui/item_bar_ui.tscn          ← HUD-Element: horizontale Item-Leiste (keine Slot-Begrenzung in Testphase)
/scripts/item_bar_ui.gd              ← Reagiert auf item_added / item_consumed Signale
```

**Zu implementierende Logik:**
- `spell_system.gd`: lauscht auf `combo_recognized(combo_name, mode)`-Signal aus `motion_input_parser.gd`
- Modus L (L halten): Zwei-Element-Grammatik → Spell aus `spell_definitions.tres`-Kombinations-Tabelle nachschlagen
- Modus R (R halten): Feste Sequenzen → direkt benannten Spell aus `combo_definitions.tres` abrufen
- Modus B (L+R halten): Lange Combos (3+ Inputs), mächtigste Spells – Sequenzen kommen aus `combo_definitions.tres`
- Magie-Timeout: `magic_active_time` und `magic_regen_time` aus `spell_values.tres` lesen – ⚠ Startwerte offen bis Testphase
- Regenerations-Trigger: konfigurierbar (`passiv` / `durch Waffen-Treffer` / `beides`) – aus `spell_values.tres`
- Magie-Gauge-Signal: `spell_system` emittiert `magic_changed(current_ratio: float)` → `magic_gauge_ui.gd` reagiert
- HUD-Integration: kein separater Mana-Balken – Glüh-Indikator wird in Spieler-Silhouette integriert (Rim-Glow-Intensität)
- `spell_projectile.gd`: Bewegung via `velocity`, Kollision mit Spielern (Physics-Layer Spieler) und Terrain prüfen
- Spell-Effekte via Hook: `spell_system` ruft `hook_registry.run_hook("spell_effect_hook", ...)` vor Schadensanwendung
- Spell-Effekt-Dispatcher: Dictionary `{spell_name: Callable}` für saubere lokale Erweiterbarkeit (Fallback wenn kein Mod-Hook)
- Statuseffekte werden nicht direkt im Spell-Script angewendet — `spell_system` ruft `status_effect_component.add_effect(effect_id, source)` auf dem Ziel auf

**Statuseffekt-Komponente (lt. DESIGN.md Statuseffekt-System):**
- `status_effect_component.gd`: `add_effect(id, source)`, `remove_effect(id)`, eigener `_process(delta)` für Tick-Logik
- Stapel-Mechanik: geometrisch abnehmend (`Stack-Wert = Basiswert × Stapel-Faktor^(n-1)`), Stapel-Faktor aus `status_effects.tres`
- Jeder Stack hat eigenen Timer — kein Refresh, älteste Stacks laufen zuerst ab
- `reaction_checker.gd`: wird bei jedem `add_effect()` synchron aufgerufen, prüft alle 4 Reaktionen aus DESIGN.md
- Reaktion konsumiert beteiligte Stacks und triggert Einmal-Effekt (Knockback, Kettenblitz, Burst-Schaden, Panik ⚠ EXPERIMENTELL)
- Immunitäts-Flags: nach Einfrieren 3.0s Immunität, nach Betäubung 1.5s Immunität — als Timer auf `status_effect_component`
- Dodge bricht alle Soft-CC-Stacks (Signal `dodged` von `player.gd` → `status_effect_component.clear_soft_cc()`)
- Max-Debuff-Cap: maximal 3 verschiedene Effekt-Typen gleichzeitig — ältester Effekt-Typ wird bei Überschreitung entfernt
- Signal `effect_changed(effect_id, stack_count)` → `status_effect_hud.gd`

**Spell-Effekte → Statuseffekte (lt. DESIGN.md Statuseffekt-System):**
- Brennen: `status_effect_component.add_effect("burning", source)` — tickt via eigenem Timer alle 0.5s
- Verlangsamung: `add_effect("slow", source)` — Speed-Multiplikator auf `player.gd`
- Einfrieren: wird automatisch durch `status_effect_component` ausgelöst wenn Verlangsamungs-Schwelle erreicht
- Betäubung: `add_effect("stun", source)` — Input-Block-Flag auf `player_input.gd`
- Rüstungs-Debuff: `add_effect("armor_break", source)` — Multiplikator in `damage_system.gd` abgefragt
- Blind: `add_effect("blind", source)` — Flag `is_blinded` auf `target_system.gd`
- HoT (Heilung): `add_effect("hot", source)` — tickt `health_component.heal(amount)` alle 1.0s
- Nass: `add_effect("wet", source)` — kein direkter Effekt, nur Reaktions-Primer

**Akzeptanzkriterien:**
- [ ] Alle 6 Modus-L-Kombinationen aus `DESIGN.md` werden korrekt erkannt und gewirkt
- [ ] Alle 6 Modus-R-Sequenzen aus `DESIGN.md` funktionieren
- [ ] Magie-Timeout sperrt Modus L/R/B nach Ablauf und zeigt Gauge korrekt an
- [ ] Magie regeneriert sich nach konfiguriertem Trigger
- [ ] Projektile treffen Spieler und Terrain mit korrekten Kollisions-Layern
- [ ] Alle 8 Statuseffekte (Brennen, Verlangsamung, Einfrieren, Betäubung, Rüstungs-Debuff, Blind, HoT, Nass) werden korrekt angewendet
- [ ] Stapel-Mechanik: geometrische Abschwächung funktioniert, Stapel-Faktor aus `status_effects.tres` gelesen
- [ ] Alle 4 Reaktionen aus `DESIGN.md` werden bei korrekten Effekt-Kombinationen ausgelöst
- [ ] Immunitäts-Regeln verhindern CC-Dauerloop (Einfrieren 3.0s, Betäubung 1.5s Immunität)
- [ ] Dodge bricht Soft-CC-Stacks
- [ ] Max-Debuff-Cap (3 Effekt-Typen) wird eingehalten
- [ ] Status-Icons erscheinen korrekt über dem betroffenen Charakter mit Stack-Zahl und Timer-Balken
- [ ] Kein Spell wird gewirkt wenn Magie-Timeout aktiv (Eingabe verfällt lautlos)
- [ ] Werte aus `spell_values.tres` und `status_effects.tres` werden geladen – kein Wert ist im Code hardcodiert
- [ ] Items droppen bei Tile-Zerstörung mit korrekter Drop-Chance (aus `item_config.tres`)
- [ ] Aufsammeln fügt Item zur Item-Leiste hinzu (Signal `item_added` korrekt gefeuert)
- [ ] Passive Items wirken sofort nach Aufnahme (z.B. `speed_rune` erhöht Bewegungsgeschwindigkeit)
- [ ] Bedingte Items lösen korrekt bei Bedingungseintritt aus (z.B. `life_shard` bei HP < 30%)
- [ ] Verbrauchte Items verschwinden aus der Item-Leiste

**Fallstricke:**
- Projektil-Instanziierung: `preload()` statt `load()` für Performance (Szene bei Spielstart vorladen)
- `spell_definitions.tres`-Lookup: Kombinations-Reihenfolge ignorieren (Feuer+Blitz = Blitz+Feuer) → Set statt Array als Key
- Magie-Gauge: `Tween` für smooth Leerung/Füllung, kein abrupter Sprung
- Einfrieren via `set_physics_process(false)` — darauf achten dass Status-Icon-HUD weiterläuft (eigener `_process` auf `status_effect_hud`)
- Reaktions-Cooldown in `reaction_checker.gd` als Dictionary `{reaction_id: timestamp}` führen

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
- `X halten (0.5s)` → Waffen-Panel öffnen

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
- **Rüstungs-Debuff-Integration**: vor Schadensanwendung `status_effect_component.get_armor_multiplier()` auf dem Ziel abfragen und Schaden entsprechend skalieren
- Element-Drop bei Treffer: Signal `element_dropped(element_type)` → `spell_system.gd`

**Akzeptanzkriterien:**
- [ ] HP werden korrekt reduziert und im HUD angezeigt
- [ ] LOS-Block reduziert Schaden (Terrain als Deckung nutzbar)
- [ ] `died()`-Signal wird korrekt emittiert
- [ ] Element-Drop funktioniert nach Treffer
- [ ] Alle 3 Schadensklassen produzieren korrekte Werte
- [ ] Rüstungs-Debuff erhöht eingehenden Schaden korrekt (geometrische Stapel-Skalierung)

**Fallstricke:**
- LOS-Raycast auf separatem Physics-Layer (Terrain-Layer), damit Spieler-Nodes nicht blockieren
- `health_component` als AutoLoad oder als Child-Node – Child-Node bevorzugen für Multiplayer-Kompatibilität
- Rüstungs-Debuff-Abfrage defensiv schreiben: wenn `status_effect_component` nicht vorhanden (z.B. Tutorial-Dummy) → Multiplikator = 1.0

---

### Phase 3 – Multiplayer & State
**Ziel**: Vollständige lokale Multiplayer-Runde mit State-Management, Scoring und rundenbasiertem Flow.

#### Phase 3 – Stream-Matrix (Cloud vs. Lokal)

| Stream | Cloud-Umsetzung | Lokaltest-Pflicht | Was lokal zwingend geprüft werden muss |
|--------|------------------|-------------------|-----------------------------------------|
| **3A ArenaStateManager** | ✅ Hoch | ✅ Ja | State-Transitions unter echter Spielsituation (Countdown, Combat-Ende, Timer-Ende) |
| **3B Local Multiplayer** | ✅ Mittel-Hoch | ✅ Ja | 2–4 Controller-Zuordnung, Split-Screen-Trigger, Kamera-Zoom und Spawn-Flow im Live-Spiel |
| **3C Scoring & HUD** | ✅ Hoch | ✅ Ja | HUD-Lesbarkeit unter Last, richtige Event-Reihenfolge bei Tod/Rundenende |
| **3D Network Hooks** | ✅ Hoch | ⚠ Kurztest | Sicherstellen, dass Stubs lokales Spiel nicht beeinflussen und keine Sync-Nodes ungewollt aktiv sind |
| **3E Hauptmenü & Lobby** | ✅ Hoch | ✅ Ja | Navigation, Fokus/Inputs, Pause-Verhalten und Übergänge zwischen Menü ↔ Match |

**Empfohlener Ablauf für Phase 3:**
- Cloud-Implementierung pro Stream mit klaren Signalen/Interfaces
- lokaler Integrationslauf mit echter Controller-/UI-Bedienung
- danach Status in dieser Datei aktualisieren

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
- [ ] Runde endet korrekt wenn Timer abgelaufen (konfigurierbar: aus / 2 min / 5 min)
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
/scenes/ui/settings_menu.tscn     ← Einstellungen (Audio, Video, Controls) — Phase 3E ist Owner
/scenes/ui/lobby.tscn             ← Lobby für Arena-/Spielerauswahl
/scenes/ui/pause_menu.tscn        ← In-Game-Pause-Overlay
/scripts/main_menu.gd             ← Menü-Navigation
/scripts/settings_menu.gd         ← Einstellungs-Logik (Tabs: Video/Audio/Steuerung/Barrierefreiheit/Spiel)
/scripts/settings_manager.gd      ← Persistente Einstellungen (user://settings.tres)
/scripts/lobby.gd                 ← Lobby-Logik (Spieler hinzufügen, Arena wählen)
/scripts/pause_menu.gd            ← Pause-Verhalten lt. DESIGN.md
```

> **Hinweis**: `settings_menu.tscn` und `settings_menu.gd` werden hier vollständig angelegt (inkl. aller Tabs lt. DESIGN.md). Phase 4 Stream E erweitert nur `accessibility_manager.gd` — erstellt keine neue settings_menu-Szene.

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
- `ColorRect` → Hintergrund mit `MOODBOARD.md`-Farbpalette

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

#### Phase 4 – Stream-Matrix (Cloud vs. Lokal)

| Stream | Cloud-Umsetzung | Lokaltest-Pflicht | Was lokal zwingend geprüft werden muss |
|--------|------------------|-------------------|-----------------------------------------|
| **4A Game Feel / Juice** | ✅ Mittel | ✅ Ja | Hit-Pause-Impact, Shake-Stärke, Slow-Motion-Gefühl und Controller-Rumble im Moment-to-Moment-Gameplay |
| **4B Sound** | ✅ Mittel | ✅ Ja | Mix-Balance, Lautheit, räumliche Wahrnehmung, Audio-Artefakte bei vielen gleichzeitigen Events |
| **4C VFX** | ✅ Mittel-Hoch | ✅ Ja | Lesbarkeit der Effekte im Kampfchaos und Performance bei VFX-Spitzenlast |
| **4D Tutorial** | ✅ Hoch | ✅ Ja | Verständlichkeit der Schrittfolge, Highlight-Genauigkeit, Skip-Flow und Persistenz |
| **4E Accessibility** | ✅ Hoch | ✅ Ja | Farbenblind-Paletten, Remapping-Funktion, Textskalierung und Combo-Assist unter realem Input |
| **4F Musik-System** | ✅ Mittel | ✅ Ja | Layer-Übergänge ohne Knacksen, musikalisches Timing im Match-State-Flow |
| **4G Bot-KI** | ✅ Mittel-Hoch | ✅ Ja | Fairnessgefühl, Reaktionswirkung pro Schwierigkeitsgrad, keine Deadlocks oder unfaire Patterns |
| **4H Sprite-Integration** | ⚠ Mittel (asset-abhängig) | ✅ Ja | Animation-Lesbarkeit, Modulate-Farbidentität, Übergänge zwischen Idle/Walk/Combat |

**Empfohlener Ablauf für Phase 4:**
- Cloud für technische Umsetzung und Grundabstimmung
- lokales Feintuning pro Stream mit kurzen, wiederholbaren Playtest-Szenarien
- finale Abnahme erst nach Wahrnehmungs-Checks (Bild, Ton, Input)

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
/scripts/sfx_manager.gd           ← Zentraler Sound-Controller (AutoLoad)
/scripts/tone_generator.gd        ← Prozeduraler Ton-Generator
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
/scripts/user_preferences.gd      ← Präferenz-Resource-Klasse (extends Resource, liegt unter /scripts/)
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
- Alle Layer rhythmisch synchron (Grundraster 85 BPM, DnB-Percussion intern 170 BPM), starten gleichzeitig
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
/scripts/bot_input.gd              ← BotInput-Klasse implementiert player_input-Interface (überschreibt get_move_vector() und get_action())
/scripts/bot_difficulty.gd         ← Schwierigkeitsstufen-Konfiguration
/resources/bot_config.tres         ← Zentrale Schwierigkeits-Resource (referenziert die 4 Stufen-Resources)
/resources/bot_einsteiger.tres     ← Einsteiger-Parameter (Reaktionszeit, Fehlerrate)
/resources/bot_normal.tres
/resources/bot_experte.tres
/resources/bot_meister.tres
```

**Zu implementierende Logik (lt. DESIGN.md Bot-KI):**
- Bot ersetzt `_input()` mit eigenem Entscheidungssystem via `bot_input.gd`
- State-Machine für Bot: `IDLE → APPROACH → ATTACK → DODGE → RETREAT`
- Pro Schwierigkeitsstufe (lt. DESIGN.md):
  - **Einsteiger**: Reaktionszeit 600ms, keine Combos, zufällige Bewegung
  - **Normal**: Reaktionszeit 350ms, 2-Schritt-Combos, Dodge bei erkanntem Projektil
  - **Experte**: Reaktionszeit 150ms, volle Combos, prädiktives Dodging
  - **Meister**: Reaktionszeit 80ms, perfekte Combos, Frame-genaues Dodging, Terrain-Awareness
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

#### Stream H – Sprite-Integration
**Abhängigkeit**: Phase 3 vollständig (Spieler-Node stabil). Externe Assets (Spritesheets) müssen vorliegen.

> **Blockier-Bedingung**: Dieser Stream startet erst wenn der Auftraggeber die Charakter-Spritesheets geliefert hat. Bis dahin laufen Platzhalter (`ColorRect`) weiter. Stream als `⚠ BLOCKIERT (wartet auf externe Assets)` markieren bis Assets vorliegen.

**Zu erstellende Dateien:**
```
/scripts/player_animator.gd       ← Animation-State-Machine (reagiert auf animation_changed-Signal)
/resources/sprite_config.tres     ← Pfade zu Spritesheets, Tile-Größen, use_sprites-Toggle
```

**Zu ergänzende Dateien (bereits vorhanden):**
```
/scenes/player.tscn               ← AnimatedSprite2D-Node hinzufügen (war bereits vorbereitet)
```

**Sprite-Spezifikation (lt. DESIGN.md):**
- Tile-Größe: 48×48 px, PNG, transparenter Hintergrund
- Animationen: `idle` (4F), `walk` (6F×4 Richtungen), `dodge` (4F), `attack_light` (3F), `attack_heavy` (5F), `cast` (4F), `hit` (2F), `death` (6F)
- Farbneutrale Sprites – Spielerfarbe via `AnimatedSprite2D.modulate`

**Zu implementierende Logik:**
- `sprite_config.tres`: `use_sprites: bool` – wenn `false` → `ColorRect` sichtbar, `AnimatedSprite2D` unsichtbar (und umgekehrt)
- `player_animator.gd`: lauscht auf `player.animation_changed(anim_name, direction)`, setzt `AnimatedSprite2D.play()` und `flip_h` für Links/Rechts
- `player.gd`: emittiert `animation_changed` bei jedem State-Wechsel (Bewegung, Dodge, Cast, Treffer, Tod)
- Rim-Glow (`Line2D`-Overlay) bleibt unabhängig vom Sprite-System aktiv

**Waffen-Sprites (optional):**
- Falls Waffen-Sprites geliefert werden: separater `AnimatedSprite2D`-Node in `player.tscn` als Child
- Fallback: `ColorRect`-Geometrie bleibt aktiv wenn kein Waffen-Sprite vorhanden

**Akzeptanzkriterien:**
- [ ] `use_sprites = false` → Platzhalter-ColorRect sichtbar, kein Fehler
- [ ] `use_sprites = true` → AnimatedSprite2D spielt korrekte Animation ab
- [ ] Alle 8 Animationen wechseln korrekt bei State-Übergängen
- [ ] Spielerfarbe via `modulate` korrekt aufgemalt
- [ ] Rim-Glow bleibt sichtbar unabhängig vom Sprite-Modus
- [ ] Kein visuelles Flackern beim Animationswechsel

**Fallstricke:**
- `AnimatedSprite2D.play()` von außen aufrufen wenn Animation bereits läuft → erst prüfen ob `animation == anim_name` bevor neu starten
- `flip_h` für Links/Rechts reicht – keine gespiegelten Richtungs-Frames nötig (spart ~50% Spritesheet-Aufwand)
- Spritesheet-Import in Godot: `filter = false` (Pixelart!), sonst verschwommene Sprites

---

### Phase 5 – Steam-Vorbereitung
**Ziel**: Release-fähige Version auf Steam veröffentlichen.

#### Phase 5 – Stream-Matrix (Cloud vs. Lokal)

| Stream | Cloud-Umsetzung | Lokaltest-Pflicht | Was lokal zwingend geprüft werden muss |
|--------|------------------|-------------------|-----------------------------------------|
| **5A Weitere Arena-Varianten** | ✅ Hoch | ✅ Ja | Spawn-/Flow-Lesbarkeit je Arena, Destroy-Tile-Verhalten und Kameraführung im echten Match |
| **5B Online-Multiplayer** | ✅ Mittel | ✅ Ja | Latenzverhalten, Desync-Risiken, Join/Leave-Stabilität unter realen Netzwerkbedingungen |
| **5C Steam-Integration** | ⚠ Teilweise | ✅ Ja | Steam-Overlay, Achievement-Trigger, Lobby-/Name-Integration mit echter Steam-Session |
| **5D Build & QA** | ✅ Mittel-Hoch | ✅ Ja | Export-Builds auf Zielplattformen, Performance unter Last, 30+ Minuten Stabilitätsläufe |
| **5E Progressions- & Unlock-System** | ✅ Hoch | ✅ Ja | Persistenz über Neustarts, Popup-Timing, korrekte Sync-Pfade zu Steam-Achievements |

**Empfohlener Ablauf für Phase 5:**
- Cloud für Implementierung, Struktur, CI/CD-Vorbereitung und Vorvalidierung
- lokale Release-Checks auf Windows/Linux mit Controller- und Langzeittest
- finale Freigabe erst nach Build-, Performance- und Plattformprüfung

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

> **project.godot-Erweiterung**: Dieser Stream darf `project.godot` um den `ProgressionManager`-AutoLoad-Eintrag sowie den `SteamManager`-AutoLoad-Eintrag erweitern. Koordination mit dem für `project.godot` zuständigen Stream erfolgt über ein GitHub Issue mit Label `project-godot`.

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

---

## Post-Launch-Optionen (nach Steam-Release)

### Nintendo Switch Port
**Status**: Nicht geplant für v1.0 – Post-Launch-Evaluation nach erfolgreichem Steam-Launch.

**Voraussetzungen** (vollständige Details in `DESIGN.md` → Controller-Abschnitt):
- Nintendo Developer Account (Bewerbung, 1–6 Monate Wartezeit)
- Godot Switch Export Template via lizenziertem Partner (~2.000–5.000 €)
- Nintendo Devkit (~500 €/Jahr Leihgebühr)
- Nintendo Lotcheck-Prozess (4–8 Wochen)

**Hinweis**: Switch Pro Controller auf PC/Steam ist bereits vollständig unterstützt (kein Implementierungsaufwand). Switch-Spieler können ab Tag 1 mit ihrem vertrauten Controller spielen.
