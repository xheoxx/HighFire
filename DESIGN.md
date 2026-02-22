# Arena Visual & Gameplay Design Dokument

Zweck: Dieses Dokument übersetzt drei visuelle Moodboards in konkretes, systemorientiertes Design-Wissen, das als strukturierter Input für GitHub Copilot bei der Implementierung des Spiels in Godot genutzt wird. Schwerpunkte sind Determinismus, Modularität, Lesbarkeit und Umsetzung mit Primitiven (ColorRect, Line2D, Labels, GPUParticles2D).

---

## Spielpositionierung & Design-Leitlinie

### Referenzpunkt: Bomberman
HighFire teilt mit Bomberman das Fundament das Klassiker ausmacht: **sofort verständlich, sofort spaßig, sofort kompetitiv**. Lokaler Multiplayer, Arena, zerstörbares Terrain – dieser erste Eindruck ist kein Problem, sondern ein Vertrauensvorschuss beim Spieler.

Bomberman ist der **Einstiegspunkt**, nicht das Ziel.

### Die eigenen Stärken – immer herausstellen

| HighFire | Bomberman |
|----------|-----------|
| Freie 8-Richtungs-Bewegung + Dodge – du bist nie gefangen | Grid-Lock – eine falsche Bombe und du stirbst |
| Direkte Konfrontation, Skill-Ausdruck ist sichtbar | Indirekter Kampf, viel Positions- und Glückszufall |
| Fighting-Game-Tiefe – Combos lohnen sich zu lernen | Flache Mechaniken – Runde 1 und Runde 100 spielen sich gleich |
| Statuseffekte + Reaktionen – Synergien entstehen spontan | Keine Synergie-Systeme |
| Terrain als taktische Deckung (Line-of-Sight) | Terrain nur als Hindernis |
| Spellcrafting + Weaponcrafting – Ausdruck durch Builds | Keine Customization |

### Goldene Regel für alle Implementierungsentscheidungen
> **Der erste Eindruck muss so schnell funktionieren wie Bomberman – zwei Spieler, Controller rein, sofort kämpfen, sofort lachen. Die Tiefe darf nie eine Hürde für den ersten Spaß sein.**

Konkret bedeutet das:
- Jede neue Mechanik muss ohne Erklärung zumindest *ausprobierbar* sein
- Komplexität (Combos, Crafting, Statuseffekte) ist Belohnung für Erfahrung – kein Pflichtprogramm
- Der Combo-Assist (Accessibility) ist keine Krücke, sondern ein legitimer Spielmodus
- Wenn eine Entscheidung das Spiel taktisch reicher aber sofort weniger spaßig macht: erst testen, dann entscheiden

---

## Moodboard 01 – Arcane Foundry (Arena-Atmosphäre)

### Design-Absicht

Eine ritualhafte, industriell-fantastische Arena erschaffen, die kraftvoll und bewusst wirkt. Die Arena soll Wichtigkeit und Gefahr ohne visuelles Rauschen kommunizieren. Das Zentrum der Arena muss stets als primärer Gameplay-Fokuspunkt lesbar sein.

### Visuelle Säulen

* Dunkle, minimale Basis mit hochkontrastreichen emissiven Elementen
* Starker Warm-Kalt-Farbkontrast
* Abstrakte Geometrie statt detaillierter Texturen
* Magie dargestellt als präzise Energie, nicht als Chaos

### Arena-Boden

* Basis: dunkle Obsidian-artige Fläche (flache Farbe oder subtiler Verlauf)
* Runen-Risse: dünne emissive Linien im Boden eingebettet

  * Farben: elektrisches Blau und arkanes Violett
  * Verhalten: langsames Pulsieren (sinusbasierte Alpha- oder Breitenmodulation)
  * Umsetzung: Line2D oder dünne ColorRect-Streifen mit additivem Blending

### Arena-Zentrum (Spell Foundry)

* Schwebende Glyphen-Formen, die um einen Mittelpunkt kreisen
* Glyphen drehen sich langsam und kommen nie vollständig zum Stillstand
* Farbe kodiert Spell-Zustand oder Crafting-Phase

  * Blau = Kontrolle / neutral
  * Violett = Transformation
  * Amber = Überlastung / Instabilität

### Charaktere

* Charaktere werden als **Pixelart-Sprites** dargestellt (48×48 px, 4 Richtungen, Spritesheets vom Auftraggeber geliefert)
* Bis Sprites vorliegen: Platzhalter als `ColorRect`-Silhouette – Sprite-Integration ist von Anfang an vorbereitet
* Spielerfarbe wird via `AnimatedSprite2D.modulate` aufgemalt – Sprites selbst sind farbneutral
* Nur Hände, Waffen und aktive Spell-Komponenten leuchten (Rim-Glow bleibt als `Line2D`-Overlay prozedural)
* Waffen sind Hybridformen (Stab + Klinge) – als Sprite oder als `ColorRect`-Geometrie

### Nebel und Tiefe

* Volumetrisches Gefühl ohne echtes Volumetrics
* Halbtransparente violette Nebelschichten an den Arena-Rändern
* Das Zentrum bleibt stets visuell klar

### Wände und Arena-Rahmen

* Metallische, segmentierte Wände
* Eingebettete arkane Schaltkreislinien (emissiv)
* Randbeleuchtungseffekt:

  * Warmes Amber von den äußeren/oberen Kanten
  * Kühles Blau von den inneren/unteren Kanten

### Technische Einschränkungen

* Einzelne Arena-Szene
* Keine Textur-Abhängigkeit erforderlich
* Alle Effekte mit CanvasItem-basierten Nodes umsetzbar

---

## Moodboard 02 – Destructible Rift Grounds (Gameplay-Moment)

### Design-Absicht

Hochgeschwindigkeitskampf und großflächige Zerstörung zeigen, ohne die Übersichtlichkeit zu verlieren. Die Arena selbst ist ein aktiver Teilnehmer im Kampf und kommuniziert Gefahrenzustände klar.

### Visuelle Säulen

* Kontrolliertes Chaos
* Starkes Telegraphieren von Gefahr und Zerstörung
* Geschwindigkeit durch Bewegungshinweise kommuniziert, nicht durch Kameraverwischung

### Zerstörbarer Boden

* Arena-Boden aus modularen Tiles aufgebaut

* Tiles können durch Zustände wechseln:

  * Intakt
  * Gerissen (Warnung)
  * Zerstört (Loch / Gefahr)

* Unterlage-Glühen:

  * Helles Rift-Orange sichtbar durch Risse

### Zerstörungs-Feedback

* Explosionen schleudern Trümmer aufwärts (nur visuell)
* Trümmer können nicht-physikalische Partikel sein
* Einschlagkrater:

  * Kreisförmige Neon-Decals
  * Verblassen über Zeit, um Timing-Fenster anzuzeigen

### Architektur

* Säulen und Strukturen brechen in Segmenten
* Jedes Segment ist ein eigenständiger Node
* Elektrische Bögen springen zwischen instabilen Segmenten

  * Zur visuellen Gefahren-Telegraphierung eingesetzt

### Spieler und Bewegung

* Spieler-Lesbarkeit hat Vorrang vor der Umgebung
* Leichte Bewegungsschlieren oder Nachbilder
* Farbidentität stärker als Silhouetten-Detail

### Zielerfassungssystem

* HUD-Ringe um Gegner

  * Cyan = aktuelles Ziel
  * Rot = feindlich / Bedrohung
* Ringe pulsieren oder drehen sich subtil, um bei Chaos sichtbar zu bleiben

### Beleuchtung und Raum

* Deckenstrahler definiert die Kampf-Fokuszone
* Staubwolken als große, halbtransparente Schichten
* Hintergrund reduziert auf ferne leuchtende Punkte (Stadtruinen)

### Technische Einschränkungen

* Keine physikintensive Zerstörung erforderlich
* Zerstörung ist zustandsbasiert, nicht simulationsbasiert
* Multiplayer-sicher und deterministisch

---

## Moodboard 03 – Crafted Combo Flow (Crafting & Input-Gefühl)

### Design-Absicht

Spieler-Inputs sichtbar, ausdrucksstark und befriedigend machen. Crafting und Combos sollen sich wie physische Handlungen anfühlen, nicht wie Menü-Interaktionen.

### Visuelle Säulen

* Input ist Magie
* Bewegung schafft Bedeutung
* Feedback ist sofort und lesbar

### Controller und Input-Visualisierung

* D-Pad- und Motion-Inputs erzeugen sichtbare Trails (bei Analogstick: auch Analogstick-Inputs)
* Trails bilden Bögen, Spiralen und Winkel
* Die Bewegung selbst definiert die Spell-Signatur

### Combo-Ketten

* Combo-Inputs als Runen-Kette visualisiert
* Jeder erfolgreiche Input fügt ein neues Runen-Element hinzu
* Timing-Qualität beeinflusst visuelle Stabilität:

  * Sauberes Timing = stabiles Glühen
  * Schlechtes Timing = Flackern oder Verzerrung

### Crafting-HUD

* Schwebende holographische Panels
* Zeigt:

  * Spell-Zutaten-Slots
  * Waffen-Upgrade-Nodes
* Panels verwenden nur Linien, Icons und Farbzustände
* Kein dichter Text oder dekorative Rahmen

### Visueller Fokus

* Hintergrund-Gameplay bleibt sichtbar, aber unscharf/entsättigt
* Input- und HUD-Elemente bleiben scharf und hochkontrastreich

### Farbsprache

* Primärer Verlauf: Violett zu Orange
* Input-Trails übernehmen die aktuelle Spell-Farbe
* Fehlgeschlagene Inputs blinken kurz in Warnfarben

### Technische Einschränkungen

* Motion-Trails mit Line2D und zeitbasiertem Abbau implementiert
* Combo-Kette mit UI-Containern und Animationen umgesetzt
* HUD immer aktiv über CanvasLayer
* Vollständig deterministisch für Multiplayer

---

## Sound Design

### Design-Absicht
Sound ist das unsichtbare Feedback-System. Jeder Motion-Input, jede Destruction und jeder State-Wechsel braucht eine akustische Antwort – kurz, präzise, unverwechselbar.

### Klang-Kategorien

| Kategorie | Trigger | Charakter |
|-----------|---------|-----------|
| **Combo-Input** | Jeder erfolgreicher Eingabeschritt | Kurzer, heller Ton; skaliert in Tonhöhe mit Combo-Länge |
| **Spell-Cast** | Spell-Auslösung nach vollständiger Combo | Tiefer, resonanter Impact mit Nachhall |
| **Weapon-Craft** | Waffe fertiggestellt | Metallisches Klicken + magischer Sweep |
| **Target-Lock** | Ziel wird eingerastet | Kurzes, präzises Ping (hoher Ton) |
| **Target-Switch** | Zielwechsel | Schneller Sweep von alt zu neu |
| **Tile-Crack** | Terrain-Schaden Stufe 1 | Tiefes Knacken, leichte Vibration |
| **Tile-Destroy** | Terrain zerstört | Explosiver Impact + Partikel-Rauschen |
| **Hit-Receive** | Spieler wird getroffen | Kurzer, dumpfer Schlag + kurzes Stille-Moment |
| **Player-Death** | Spieler eliminiert | Langer Abklington, Arena-Echo |

### Technische Umsetzung
* Alle Sounds initial via Godot `AudioStreamGenerator` oder einfache `.wav`-Dateien ohne externe Dependencies
* Pitch-Shift per Code für Combo-Skalierung
* Spatial Audio für Arena-Tiefe (links/rechts, nah/fern)
* Deterministische Trigger über Spielzustand, nicht über Physics-Events

---

## Spieler-Farbidentität

Jeder Spieler hat eine eindeutige Primärfarbe, die konsequent auf alle visuellen Elemente angewendet wird: Silhouette-Rim, Spell-Trails, Combo-Rune-Kette, HUD-Ring.

| Spieler | Primärfarbe | Hex | Akzentfarbe | Hex |
|---------|-------------|-----|-------------|-----|
| Spieler 1 | Cyan-Blau | `#00D4FF` | Weiß | `#FFFFFF` |
| Spieler 2 | Magenta | `#FF0080` | Orange | `#FF6600` |
| Spieler 3 | Gelbgrün | `#A0FF00` | Weiß | `#FFFFFF` |
| Spieler 4 | Gold | `#FFD700` | Rot | `#FF2200` |

### Regeln
* Spielerfarbe dominiert immer über Umgebungsfarbe
* Bei Target-Lock übernimmt die **Farbe des Angreifers** den HUD-Ring des Ziels (sodass jeder sieht, wer locked ist)
* Neutrale Spells (nicht einem Spieler zugeordnet) erscheinen in Weiß/Grau

---

## Arena & Match State Machine

Überblick über alle Zustände des Arena-Matches, damit alle Subsysteme (Combat, Crafting, UI, Multiplayer) wissen, wann sie aktiv sind.

```
[Lobby / Waiting]
       │  alle Spieler bereit
       ▼
[Countdown] (3 Sekunden)
       │  Timer abgelaufen
       ▼
[Combat Active] ◄──────────────────────┐
       │  ein Spieler übrig / Zeit 0   │
       │                               │ Respawn (falls aktiviert)
       ▼                               │
[Round End]  ──── Spieler eliminiert ──┘
       │  Sieg-Screen gezeigt
       ▼
[Score Screen] (Punkte, Stats, Crafting-Highlights)
       │  Rückkehr gewählt
       ▼
[Lobby / Waiting]
```

### State-Details

| State | Aktive Systeme | Gesperrte Systeme |
|-------|---------------|-------------------|
| **Lobby** | Spieler-Auswahl, Input-Mapping | Combat, Terrain-Destruction |
| **Countdown** | Kamera, Musik, HUD-Init | Bewegung, Spells, Crafting |
| **Combat Active** | Alle Systeme | – |
| **Round End** | Kamera-Freeze, Highlight-VFX | Input, neue Crafting |
| **Score Screen** | UI, Stats | Alle Gameplay-Systeme |

### Wichtige Regeln
* State-Wechsel immer über einen zentralen `ArenaStateManager`-Node
* Kein Subsystem darf den State selbst ändern – nur Signale senden
* Deterministisch für Multiplayer: alle Clients folgen dem selben State-Timer

---

## Combo-Grammatik & Motion-Input-Lexikon

> **Resource-Datei:** `res://resources/combo_definitions.tres` — D-Pad-Sequenz-zu-Spell-Mapping (Modus R) und Pattern-Erkennungs-Tabellen. Vom `motion_input_parser.gd` geladen.

### Design-Absicht
Motion-Combos sind die Sprache des Spiels. Jede Bewegung hat eine Bedeutung – der Spieler lernt eine Grammatik, keine Menüs. Inputs fühlen sich physisch an.

### Grundbewegungen (Basis-Lexikon)

| Symbol | Motion | Beschreibung |
|--------|--------|--------------|
| ↑ | D-Pad oben | Aufwärtsstoß |
| ↓ | D-Pad unten | Stampf / Erdanker |
| → | D-Pad rechts | Vorwärtsstoß (relativ zu Spieler) |
| ← | D-Pad links | Rückzug / Konter-Setup |
| ↓→ | Viertelkreis vorwärts | Klassischer Feuerball-Input |
| ↓← | Viertelkreis rückwärts | Defensiv-Spell / Schild |
| →↓→ | Z-Motion | Schwere Kombo-Finale |
| ←→ | Hin-und-Her | Schnell-Angriff / Burst |

> **Hinweis**: Der Vollkreis (○) aus analogen Fighting-Games entfällt – auf D-Pad ist er unpräzise. Stattdessen wird ←→ (Hin-und-Her) für AoE/Ladeangriffe verwendet. Falls ein Analogstick vorhanden ist, wird er als alternative Eingabe für alle Motions akzeptiert (Analogwert-Deadzone: 0.3).

### Combo-Struktur
Combos bestehen aus **3 Ebenen**:
1. **Motion** (D-Pad-Geste / Analogstick-Geste) – definiert Spell-Typ
2. **Element** (welcher Spell gerade gecharged ist) – definiert Schadenstyp
3. **Finish-Button** (`B`) – löst aus

Beispiel: `↓→` + `[Fire-Element aktiv]` + `B` = Feuerball geradeaus

### Timing-Fenster
* Motion muss innerhalb von **0,4 Sekunden** abgeschlossen sein
* Zu langsam: Input verfällt, kein Verbrauch von Spell-Ressourcen
* Perfect-Timing (< 0,15s): Bonus-Effekt (z. B. größerer AoE, mehr Schaden)

---

## Controller-Layout & Input-Architektur

### Design-Absicht
SNES-Layout als Referenz: Das Spiel muss mit nur 12 Inputs (D-Pad 4×, A/B/X/Y, L/R, Start/Select) vollständig spielbar sein. Wenn ein moderner Controller mit Analogsticks erkannt wird, werden diese als **alternative Eingabe** für Bewegung und Motion-Inputs akzeptiert – aber nie vorausgesetzt.

### Referenz-Controller: SNES-Layout

```
         ┌───┐     ┌───┐
         │ L │     │ R │
         └───┘     └───┘
    ┌─────────────────────┐
    │                     │
    │  ┌───┐     ╭─╮     │
    │  │ ↑ │     │X│     │
    │ ┌┴┐ ┌┴┐  ╭─╯ ╰─╮   │
    │ │←│ │→│  │Y│ │A│   │
    │ └┬┘ └┬┘  ╰─╮ ╭─╯   │
    │  │ ↓ │     │B│     │
    │  └───┘     ╰─╯     │
    │  [Select]  [Start]  │
    └─────────────────────┘
```

### Button-Belegung (Standard)

| Button | Funktion | Godot-Action-Name |
|--------|----------|-------------------|
| **D-Pad** | Bewegung (8 Richtungen) + Motion-Input-Gesten (im Combo-Modus: nur Combo-Input) | `move_up`, `move_down`, `move_left`, `move_right` |
| **B** | Angriff / Spell auslösen (Finish-Button) | `action_attack` |
| **A** | Dodge / Ausweichen | `action_dodge` |
| **Y** | Element-Modus wechseln (tippen) – reserviert für spätere Nutzung | `action_element` |
| **X** | Waffen-Panel öffnen (halten 0.5s) / Waffen-Spezial (tippen) | `action_special` |
| **L** | Siehe L/R-System unten | `combo_mode_l`, `target_prev` |
| **R** | Siehe L/R-System unten | `combo_mode_r`, `target_next` |
| **Start** | Pause-Menü | `menu_pause` |
| **Select** | Scoreboard / Info-Overlay | `menu_info` |

### L/R-Input-System (Tippen vs. Halten)

L und R übernehmen je nach Eingabedauer unterschiedliche Funktionen. Grundprinzip: **kurz tippen (< 200ms) = Target-Management, halten (≥ 200ms) = Combo-Modus**.

#### Target-Management (kein Combo-Modus aktiv)

| Input | Funktion | Godot-Action |
|-------|----------|-------------|
| L + R gleichzeitig tippen (< 200ms) | Nächsten Gegner auto-markieren (Target-Lock) | `target_lock` |
| L tippen (< 200ms) | Ziel wechseln gegen Uhrzeigersinn | `target_prev` |
| R tippen (< 200ms) | Ziel wechseln im Uhrzeigersinn | `target_next` |

#### Combo-Modi (Halten ≥ 200ms)

| Input | Modus | D-Pad-Funktion | Bewegung |
|-------|-------|----------------|----------|
| R halten | **Modus R** – Offensiv / Nahkampf-Combos | Combo-Input + Bewegung | Normal |
| L halten | **Modus L** – Defensiv / Zauber-Combos | Combo-Input + Bewegung | Normal |
| L + R halten | **Modus B** – Mächtigste Combos | Nur Combo-Input | Stillstand (v1.0) |

#### Zielwechsel im Combo-Modus ⚠ EXPERIMENTELL

Wenn ein Combo-Modus aktiv ist, kann das Ziel durch kurzes Antippen der jeweils anderen Schultertaste gewechselt werden:

| Input | Funktion |
|-------|----------|
| Modus R aktiv + L tippen (< 200ms) | Ziel wechseln |
| Modus L aktiv + R tippen (< 200ms) | Ziel wechseln |

> **Hinweis**: Diese Mechanik ist experimentell. Das 200ms-Zeitfenster muss in der Testphase kalibriert werden. Falls die Tippen/Halten-Unterscheidung in Stresssituationen nicht zuverlässig funktioniert, wird Zielwechsel im Combo-Modus deaktiviert.

---

## Combo-Modi

### Design-Absicht
Die drei Combo-Modi erweitern die Kampfgrammatik ohne neue Buttons zu verbrauchen. L und R als Modifier schaffen drei distinkte Kampfstile die sich unterschiedlich anfühlen und unterschiedliche taktische Situationen begünstigen.

### Modus-Übersicht

| Modus | Aktivierung | Stil | D-Pad | Bewegung |
|-------|-------------|------|-------|----------|
| **Modus R** | R ≥ 200ms halten | Offensiv – Nahkampf-Combos | Combo + Bewegung | Normal |
| **Modus L** | L ≥ 200ms halten | Defensiv – Zauber-Combos | Combo + Bewegung | Normal |
| **Modus B** | L + R ≥ 200ms halten | Mächtigste Combos | Nur Combo-Input | Stillstand |

### Modus B – Stillstand-Regel
Im Modus B steht der Spieler still – er ist verwundbar und muss sich bewusst **vor** der Aktivierung positionieren. Das erzeugt taktische Tiefe: wann ist der richtige Moment für Modus B?

### Modus-B-Momentum (Unlock) ⚠ Balance-Check nach Testphase erforderlich
Nach Freischaltung via Achievement `momentum_master` kann der Spieler in Modus B aktivieren während er sich noch bewegt – das Momentum bleibt erhalten, D-Pad steuert jedoch nur noch Combo-Input. Der Spieler läuft dann in der letzten Bewegungsrichtung weiter, bis Modus B beendet wird oder er eine Wand trifft.

> **Hinweis**: Falls dieses Feature die Balance bricht, wird es nach der Testphase entfernt.

### Combo-Inhalte
Die konkreten Combo-Definitionen pro Modus werden in Phase 2 (Stream A – Motion-Input Parser) festgelegt. Grundregel:
- **Modus R**: Nahkampf-Finisher, hoher Direktschaden, kurze Reichweite
- **Modus L**: Zauber-Combos, Effekte (DoT, Verlangsamung, Schild), mittlere Reichweite
- **Modus B**: Kombinationen aus beiden, hoher Ressourcenverbrauch

---

### Analog-Erweiterung (wenn verfügbar)

| Input | Funktion | Godot-Action |
|-------|----------|-------------|
| **Linker Stick** | Alternative Bewegung + Motion-Inputs (Deadzone: 0.3) | gleiche Actions wie D-Pad |
| **Rechter Stick** | Manuelle Zielauswahl (überschreibt L/R-Targeting) | `aim_x`, `aim_y` |
| **L2/LT** | Modifier: Element-Vorschau (hält Crafting-Raster offen) | `modifier_left` |
| **R2/RT** | Modifier: Power-Attack (langsamer, mehr Schaden) | `modifier_right` |

### Tastatur-Fallback (Spieler 1 + 2 lokal)

| Spieler | Bewegung | B | A | Y | X | L | R | Start | Select |
|---------|----------|---|---|---|---|---|---|-------|--------|
| **P1** | WASD | J | K | I | U | Q | E | Esc | Tab |
| **P2** | Pfeiltasten | Num1 | Num2 | Num4 | Num5 | Num7 | Num9 | Num0 | Num. |

### Godot-Input-Mapping-Regeln
- Alle Actions verwenden `InputMap` in `project.godot` (keine hardcodierten Keycodes)
- `player_id` → Joypad-Index via `Input.get_connected_joypads()`
- Tastatur-Spieler: immer `player_id = 0` (P1) und `player_id = 1` (P2)
- Joypad-Hot-Plug: `Input.joy_connection_changed`-Signal abfangen, Spieler-Zuordnung aktualisieren
- Button-Remapping wird in `user://controls.tres` persistiert (Accessibility)

### Button-Prompts im HUD
- Standard: SNES-Notation (A/B/X/Y/L/R)
- Erkennung via `Input.get_joy_name()`:
  - Xbox-Controller → „A/B/X/Y/LB/RB/LT/RT"
  - PlayStation → „✕/○/□/△/L1/R1/L2/R2"
  - Nintendo Switch Pro → SNES-Notation beibehalten
  - Unbekannt / Tastatur → Tasten-Buchstaben anzeigen

---

## Spellcrafting-System

> **Resource-Dateien:** Element-Definitionen und Kombinations-Tabellen → `res://resources/spell_definitions.tres` | Schaden, Reichweite, Cooldowns, Timeout-Werte → `res://resources/spell_values.tres`. Beide werden vom `ModLoader` zuerst geladen.

### Design-Absicht
Spells werden in Echtzeit während des Kampfes durch Combo-Eingaben gewirkt – kein Panel, kein Inventar. Die Bewegung selbst ist die Magie. Das System ist in zwei Modi aufgeteilt: **Modus L** (generische Element-Grammatik, flexibel) und **Modus R** (feste Spell-Sequenzen, präzise). Magie ist Waffen überlegen – aber zeitlich limitiert. Wenn der Magie-Timeout abläuft, ist der Spieler auf seine Waffe angewiesen.

---

### Elemente & D-Pad-Kodierung (Modus L)

In Modus L kodiert jede D-Pad-Richtung ein Element. Die Sequenz zweier Richtungen bestimmt den Spell.

| D-Pad | Element | Symbol |
|-------|---------|--------|
| ↑ | Feuer | 🔥 |
| ↓ | Eis | ❄️ |
| → | Blitz | ⚡ |
| ← | Erde | 🪨 |
| ↗ (diagonal) | Schatten | 🌑 |
| ↙ (diagonal) | Licht | ✨ |

### Element-Effekte

| Element | Primäreffekt | Sekundäreffekt |
|---------|-------------|----------------|
| Feuer | Direktschaden | Brennen (DoT) |
| Eis | Verlangsamung | Einfrieren bei Stack |
| Blitz | Ketteneffekt | Betäubung |
| Erde | Terrain-Zerstörung | Rüstungs-Debuff |
| Schatten | Line-of-Sight-Blocker | Unsichtbarkeit (kurz) |
| Licht | Heilung (selbst/ally) | Blend-Effekt |

### Modus L – Generische Element-Grammatik

**Eingabe:** `L halten + D-Pad-Sequenz (2 Eingaben, max. 0.4s) + B`

Der Spieler kombiniert zwei Elemente frei. Die Reihenfolge der Eingabe ist egal – nur die Kombination zählt.

| Kombination | Spell | Effekt |
|-------------|-------|--------|
| Feuer + Eis | Dampfwolke (AoE) | Blockiert Sicht |
| Feuer + Blitz | Plasmabolt | Schnellstes Projektil |
| Blitz + Erde | Seismischer Impuls | Zerstört Tiles im Radius |
| Eis + Erde | Frostwall | Terrain-Blockade |
| Schatten + Licht | Spiegelklon | Täuschungs-Decoy |
| Licht + Erde | Heilfeld | Permanenter HoT-Bereich |

Unbekannte Kombinationen (nicht in der Tabelle) = kein Spell, Eingabe verfällt.

### Modus R – Feste Spell-Sequenzen

**Eingabe:** `R halten + D-Pad-Sequenz (vordefiniert) + B`

Feste, benannte Angriffe mit klaren Eigenschaften. Schneller lernbar, einfacher balancierbar. Fokus auf Nahkampf und direkte Offensiv-Magie.

| Sequenz | Spell | Charakter |
|---------|-------|-----------|
| ↓→ + B | Feuerball | Klassischer Projektil-Angriff, mittlerer Schaden |
| ↓← + B | Eisschild | Defensiv, blockiert nächsten Treffer |
| →↓→ + B | Blitzschlag (Z-Motion) | Hoher Schaden, kurze Reichweite |
| ←→ + B | Erdstampf | AoE um Spieler, zerstört nahe Tiles |
| ↑↓ + B | Schattensprung | Kurze Teleport-Dash in Blickrichtung |
| ↑→ + B | Lichtstrahl | Langer Strahl, trifft durch Gegner |

> **Hinweis**: Konkrete Spell-Werte (Schaden, Reichweite, Cooldown) werden in der Testphase festgelegt. ⚠ Balance-Check erforderlich.

### Modus B – Lange Kombos (High Risk / High Reward)

**Eingabe:** `L + R halten + D-Pad-Sequenz (3+ Eingaben, max. 0.6s) + B`

Mächtigste Spells. Spieler steht still (Stillstand-Regel). Sequenzen werden in Phase 2 definiert – Grundregel: mindestens 3 D-Pad-Eingaben, Effekt kombiniert Elemente aus Modus L und R.

> ⚠ Konkrete Modus-B-Sequenzen: offen bis Testphase.

---

### Magie-Timeout (Kern-Limiter)

Magie ist Waffen überlegen – aber zeitlich begrenzt. Nach einer definierten Aktivzeit ist kein Modus L/R/B mehr verfügbar bis die Magie sich erholt hat.

| Parameter | Startwert | Anpassbar |
|-----------|-----------|-----------|
| Magie-Aktivzeit (wie lange L/R nutzbar) | ⚠ offen | Ja |
| Regenerationszeit (bis Magie wieder voll) | ⚠ offen | Ja |
| Regenerations-Trigger | ⚠ offen (passiv / durch Waffen-Treffer / beides) | Ja |

> ⚠ Alle Timeout-Werte und der Regenerations-Trigger werden in der Testphase ermittelt. Grundregel: Magie-Phasen und Waffen-Phasen sollen sich im Kampf natürlich abwechseln.

**HUD-Darstellung:** Magie-Verfügbarkeit als schmaler Balken oder Glüh-Indikator an den Spieler-Farben (kein separater Mana-Balken – visuell in die Spieler-Silhouette integriert).

---

## Statuseffekt-System

> **Resource-Datei:** `res://resources/status_effects.tres` — alle Effekt-Definitionen, Basiswerte und Stapel-Parameter. Kein Wert hardcoded.

### Design-Absicht

Statuseffekte sind die taktische Schicht zwischen Rohschaden und Instant-Kill. Sie belohnen Element-Wissen, schaffen Lese-Anforderungen im Kampf und geben jedem Spell eine eigene Identität. Das System muss lesbar bleiben — ein Spieler soll auf einen Blick erkennen, was sein Gegner gerade erleidet.

---

### Stapel-Mechanik

Jeder Effekt kann sich bis zu einem konfigurierbaren Maximum stapeln. Jeder neue Stack auf demselben Ziel fügt eine neue Instanz hinzu, aber mit geometrisch abnehmendem Beitrag:

```
Stack-Wert(n) = Basiswert × Stapel-Faktor^(n-1)
```

**Stapel-Faktor** ist pro Effekt konfigurierbar (Standard: `0.5`). Beispiel mit Basiswert `1.0` und Faktor `0.5`:

| Stack | Multiplikator | Kumulierter Effekt |
|-------|--------------|-------------------|
| 1 | 1.0 × | 1.0 |
| 2 | 0.5 × | 1.5 |
| 3 | 0.25 × | 1.75 |
| 4 | 0.125 × | 1.875 |

Das Gesetz der abnehmenden Erträge verhindert, dass ein einziges Element einen Gegner durch pures Spammen sofort eliminiert. Der Startfaktor (z.B. `0.75` statt `0.5`) und das Maximum sind über `status_effects.tres` anpassbar und können durch Waffen-Upgrade-Nodes oder Mod-Skills modifiziert werden.

**Regeln:**
- Jeder Stack hat einen **eigenen, unabhängigen Timer** — ältere Stacks laufen zuerst ab
- Kein Refresh: ein neuer Stack verlängert nicht die Laufzeit bestehender Stacks
- **Max-Stack-Cap** pro Effekt in `status_effects.tres` definiert (Standard: 4)
- Der aktuell stärkste Stack (Stack 1) bestimmt den visuellen Intensitätsgrad des Effekts am Charakter

---

### Statuseffekte im Detail

#### BRENNEN *(Feuer)*
- **Typ**: DoT (Schaden über Zeit)
- **Basisschaden pro Tick**: `⚠ offen — Balance-Check` (aus `status_effects.tres`)
- **Tick-Intervall**: 0.5s
- **Dauer pro Stack**: 3.0s
- **Stapel-Faktor**: 0.5 (Standard)
- **Max-Stacks**: 4
- **Visuell**: Orange-rote Partikel (`GPUParticles2D`) über dem Spieler, Intensität steigt mit Stack-Zahl; Rim-Glow pulsiert in `#FF4400`
- **Synergie**: Eis löscht alle Brennen-Stacks sofort (→ „Dampfstoß"-Reaktion, see Reaktions-Tabelle)

#### VERLANGSAMUNG *(Eis)*
- **Typ**: Debuff (Movement-Speed-Multiplikator)
- **Multiplikator pro Stack**: `1.0 × Stapel-Faktor^(n-1)` auf den Speed-Malus; Stack 1 = 30% langsamer, Stack 2 = +15%, Stack 3 = +7.5% usw.
- **Dauer pro Stack**: 2.5s
- **Stapel-Faktor**: 0.5
- **Max-Stacks**: 3 — bei Stack 3 und vollem Bonus → EINFRIEREN ausgelöst (siehe unten)
- **Visuell**: Blauweißes Frost-Overlay auf dem Charakter (`ColorRect` mit Transparenz), Bewegungs-Partikel werden träge
- **Synergie**: Blitz auf einem verlangsamten Ziel → NASS+BLITZ-Reaktion (verstärkte Betäubung)

#### EINFRIEREN *(Eis, Stack-Schwelle)*
- **Typ**: Hard-CC (vollständige Bewegungs- und Input-Sperre)
- **Auslösung**: Wenn Verlangsamungs-Stack-Bonus einen Schwellwert überschreitet (`⚠ offen — in Testphase mit Stack-Cap abstimmen`)
- **Dauer**: 1.5s (nicht stapelbar, wird immer refreshed)
- **Stapel**: Nicht stapelbar — einmalig ausgelöst, dann Immunität für 3.0s (Cooldown verhindert Freeze-Lock)
- **Visuell**: Charakter wird hellblau eingefärbt (`ColorRect` Overlay, Opacity 60%), GPUParticles2D frieren ein, keine Bewegungsanimation
- **Technisch**: `CharacterBody2D.set_physics_process(false)` + Input-Block-Flag auf `player_input.gd`

#### BETÄUBUNG *(Blitz)*
- **Typ**: Soft-CC (Input-Sperre, Bewegung bleibt aktiv mit Trägheit)
- **Dauer pro Stack**: 0.6s
- **Stapel-Faktor**: 0.5
- **Max-Stacks**: 2 (kurze Betäubungen stapeln sich kaum sinnvoll)
- **Visuell**: Gelbe Blitz-Partikel um den Kopf des Charakters, Screen-Noise-Flash (`ColorRect` kurz gelb, Opacity 20%)
- **Technisch**: Input-Block-Flag auf `player_input.gd` — Physik läuft weiter (Spieler gleitet aus)
- **Synergie**: Betäubung auf einem NASSEN Ziel wird in der Dauer verdoppelt (Reaktions-Tabelle)

#### RÜSTUNGS-DEBUFF *(Erde)*
- **Typ**: Multiplikativer Schadens-Verstärker auf eingehenden Schaden
- **Multiplikator pro Stack**: Stack 1 = eingehender Schaden ×1.25, Stack 2 = ×1.125, Stack 3 = ×1.0625 (geometrisch)
- **Dauer pro Stack**: 5.0s (lange Dauer — Erde ist der Setup-Effekt)
- **Stapel-Faktor**: 0.5
- **Max-Stacks**: 3
- **Visuell**: Braun-graue Risse im Charakter-Sprite (`Line2D`-Overlay), Partikel fallen wie Staub herab
- **Technisch**: `damage_system.gd` multipliziert Schaden wenn Ziel Rüstungs-Debuff trägt

#### BLIND *(Schatten)*
- **Typ**: Sicht-Einschränkung + LOS-Manipulation
- **Effekt**: Das Ziel verliert die Fähigkeit, Gegner via Target-Lock zu locken. Bestehender Lock bleibt, aber LOS-Raycast des Ziels wird blockiert (Gegner erscheinen als außerhalb der Sicht)
- **Dauer pro Stack**: 2.0s
- **Stapel-Faktor**: 0.5
- **Max-Stacks**: 2
- **Visuell**: Schwarzer Partikel-Nebel über dem Charakter; für den betroffenen Spieler: leichte Vignetten-Verdunkelung am Bildschirmrand (nur auf dessen SubViewport)
- **Technisch**: Flag `is_blinded` auf `target_system.gd` — blockiert neue Lock-Anfragen und setzt LOS-Raycast-Maske auf 0

#### NASS *(Kombinations-Vorbereitung, kein eigener Spell)*
- **Typ**: Reaktions-Primer (kein direkter Schadenseffekt)
- **Auslösung**: Dampfwolke (Feuer+Eis), Frostwall-Treffer, bestimmte Arena-Effekte
- **Dauer**: 4.0s (nicht stapelbar)
- **Visuell**: Charakter glänzt leicht (Shine-Overlay), kleine Wassertropfen-Partikel
- **Allein**: Kein Effekt auf Kampfwerte — reiner Reaktions-Enabler
- **Synergie**: Wird durch Blitz-Treffer zu NASS+BLITZ-Reaktion konsumiert

#### UNSICHTBARKEIT *(Schatten, Sekundäreffekt)*
- **Typ**: Caster-Buff (Selbst-Anwendung — der Spieler der den Schatten-Spell wirkt wird unsichtbar, kein Debuff auf Gegner)
- **Dauer**: 1.5s (nicht stapelbar — erneutes Auslösen refresht die Dauer)
- **Stapel**: Nicht stapelbar
- **Bricht bei**: Erstem ausgeführten Angriff oder Spell-Cast (Angriff beendet Unsichtbarkeit sofort)
- **Visuell**: Charakter-Alpha auf 30% — für alle anderen Spieler kaum sichtbar; eigener Spieler sieht sich selbst bei 60% Alpha (damit er sich selbst steuern kann)
- **Technisch**: Flag `is_invisible` auf `player.gd`; `target_system.gd` ignoriert unsichtbare Spieler beim Auto-Lock; manueller Lock bleibt erhalten (Spieler der locked hält seinen Lock)
- **Synergie**: Kein Reaktions-Primer — funktioniert unabhängig von anderen Effekten
- **Anti-Frustrations-Regel**: Nach Ende der Unsichtbarkeit 1.0s Immunität gegen erneute Unsichtbarkeit (verhindert permanentes Verschwinden durch Spam)

#### HEILUNG ÜBER ZEIT *(Licht, HoT)*
- **Typ**: Regen (HP-Regeneration über Zeit)
- **Heilung pro Tick**: `⚠ offen — Balance-Check`
- **Tick-Intervall**: 1.0s
- **Dauer pro Stack**: 4.0s
- **Stapel-Faktor**: 0.5
- **Max-Stacks**: 2
- **Visuell**: Goldene aufsteigende Partikel, Rim-Glow pulsiert in Spielerfarbe (heller)
- **Besonderheit**: Kann auf Verbündete angewendet werden (einziger supportive Effekt im Spiel)

---

### Reaktions-Tabelle (Synergien)

Wenn zwei kompatible Effekte auf demselben Ziel zusammentreffen, wird eine **Reaktion** ausgelöst. Die Reaktion konsumiert alle beteiligten Stacks und erzeugt einen einmaligen, stärkeren Effekt.

| Effekt A | Effekt B | Reaktion | Effekt |
|----------|----------|----------|--------|
| BRENNEN | VERLANGSAMUNG/EINFRIEREN | **Dampfstoß** | Alle Eis/Feuer-Stacks werden konsumiert; AoE-Druckwelle schleudert Ziel weg (Knockback ~200px), kein weiterer Schaden |
| NASS | BETÄUBUNG (Blitz) | **Leitfähigkeit** | Betäubungs-Dauer wird verdoppelt; Blitz-Ketteneffekt springt auf alle Spieler in 150px Radius (jeweils halbe Betäubung) |
| RÜSTUNGS-DEBUFF | BRENNEN | **Schmelze** | Rüstungs-Debuff-Multiplikator wird für 1 Tick auf ×2.0 erhöht; DoT-Tick löst sofort einen Burst-Schaden aus |
| BLIND | RÜSTUNGS-DEBUFF | **Panik** | Ziel verliert für 2s die Kontrolle über die Bewegungsrichtung (zufällige Drift-Vektoren) — ⚠ EXPERIMENTELL, nach Testphase evaluieren |

> Reaktionen können durch Mod-Skripte (`spell_effect_hook`) erweitert werden — neue Reaktionstypen ohne Core-Code-Änderung.

---

### Immunität & Anti-Frustrations-Regeln

Damit kein Spieler durch reine CC-Ketten aus dem Kampf ausgesperrt wird:

| Regel | Detail |
|-------|--------|
| **Einfrieren-Immunität** | Nach Ende eines Einfrierens: 3.0s Immunität gegen erneutes Einfrieren |
| **Betäubungs-Immunität** | Nach Ende einer Betäubung: 1.5s Immunität gegen erneute Betäubung |
| **Unsichtbarkeits-Immunität** | Nach Ende der Unsichtbarkeit: 1.0s Immunität gegen erneute Unsichtbarkeit |
| **Dodge bricht CC** | Ein erfolgreicher Dodge entfernt alle aktiven Soft-CC-Stacks (Verlangsamung, Betäubung, Blind) — Hard-CC (Einfrieren) wird nicht gebrochen |
| **Reaktions-Cooldown** | Dieselbe Reaktionsart kann auf dem selben Ziel nicht zweimal in 3.0s ausgelöst werden |
| **Max-Debuff-Cap** | Ein Ziel kann gleichzeitig maximal 3 verschiedene Effekt-**Typen** tragen (Stacks innerhalb eines Typs nicht mitgezählt) |

---

### HUD-Darstellung

Icons schweben **über dem Charakter-Sprite** in der Welt (kein HUD-Panel). Damit sind Effekte räumlich direkt dem Ziel zugeordnet.

```
Aufbau (pro Effekt-Slot):
  [Icon-ColorRect, 16×16px]
    └── Label: Stack-Zahl (wenn > 1)
    └── Unter-Icon: kleiner Timer-Balken (schwindet über die Dauer des ältesten Stacks)
```

- Icons sind einfache `ColorRect`-Formen + `Label` (keine externen Sprites nötig)
- Farb-Kodierung nach Element: Feuer=#FF4400, Eis=#44AAFF, Blitz=#FFE000, Erde=#8B5E3C, Schatten=#6622AA, Licht=#FFD700, Nass=#0088FF
- Maximal 5 Icon-Slots sichtbar (bei mehr Effekten: „+N"-Label)
- Immunität: Icon wird grau und durchgestrichen für die Immunitäts-Dauer angezeigt
- Icons verblassen (Alpha-Tween) in den letzten 0.5s bevor der Stack abläuft

---

### Technische Architektur

```
status_effect_component.gd      ← Component auf jedem Spieler-Node
    ├── add_effect(effect_id, source_player)
    ├── remove_effect(effect_id)
    ├── _process(delta)          ← tickt alle aktiven Timer, prüft Reaktionen
    └── Signal: effect_changed(effect_id, stack_count)  → status_effect_hud.gd

status_effect_hud.gd            ← Icon-Visualisierung über dem Spieler
reaction_checker.gd             ← Prüft bei jedem add_effect() auf Reaktionen
```

- `status_effect_component` ist ein `Node`-Child auf `player.tscn` (kein AutoLoad)
- Alle Effekt-Definitionen (Dauer, Stapel-Faktor, Max-Stacks, Icon-Farbe) aus `status_effects.tres`
- `reaction_checker.gd` läuft synchron in `add_effect()` — keine asynchrone Reaktionsverzögerung
- Mod-Hook `on_player_hit` kann Effekte vor Anwendung modifizieren (Stapel-Faktor überschreiben, Effekt-Typ tauschen)

---

## Weaponcrafting-System

> **Resource-Datei:** `res://resources/weapon_definitions.tres` — Archetypen, Stats und Upgrade-Nodes. Nie als Dictionary im Code hardcoden.

### Design-Absicht
Waffen sind der verlässliche Fallback wenn die Magie im Timeout ist. Sie sind nie so mächtig wie Magie – aber immer verfügbar. Weaponcrafting passiert **zwischen Runden oder in ruhigen Kampfmomenten** über ein Panel, das mit `X halten (0.5s)` geöffnet wird. Materialien werden durch Terrain-Zerstörung gesammelt.

### Waffen-Archetypen

| Typ | Reichweite | Tempo | Stärke ohne Magie | Spell-Synergie |
|-----|-----------|-------|-------------------|----------------|
| **Klinge** | Nah | Schnell | Gut | Feuer, Blitz |
| **Stab** | Mittel | Mittel | Mittel | Alle Spells |
| **Kanone** | Fern | Langsam | Mittel | Eis, Erde |
| **Klaue** | Nah | Sehr schnell | Gut | Schatten |
| **Schild-Arm** | Nah | Sehr langsam | Defensiv | Licht, Eis |

### Upgrade-Nodes
Jede Waffe hat **3 Upgrade-Nodes**, die mit gesammelten Materialien (aus Terrain-Zerstörung) freigeschaltet werden:
- **Node 1**: Basis-Stat (Schaden oder Reichweite)
- **Node 2**: Spell-Synergie-Bonus (wirkt nur wenn Magie aktiv)
- **Node 3**: Sonder-Effekt (z. B. Kettenangriff, Durchdringung)

### Crafting-Flow
1. Materialien aus zerstörten Tiles sammeln (automatisch aufgehoben)
2. `X halten (0.5s)` → Waffen-Panel öffnet sich
3. Waffentyp wählen → verfügbare Upgrade-Nodes sichtbar
4. Node bestätigen → Waffe ändert Form und Glüh-Farbe

---

## Game Feel / Juice

### Prinzip
Jede Aktion braucht eine sofortige, spürbare Rückmeldung. Juice macht den Unterschied zwischen „funktioniert" und „befriedigend".

### Effekt-Tabelle

| Ereignis | Screen Shake | Hit-Pause | Rumble | Visuelle Reaktion |
|----------|-------------|-----------|--------|-------------------|
| Leichter Treffer | Minimal (1–2px) | 2 Frames | Leicht | Flash auf Spieler-Sprite |
| Schwerer Treffer | Mittel (4–6px) | 4 Frames | Mittel | Größerer Flash + Farbinversion kurz |
| Spell-Einschlag | Stark (8–10px) | 6 Frames | Stark | Shockwave-Ring + Partikel |
| Tile-Destroy | Lokal (nur Bereich) | – | Mittel | Debris-Partikel + Glow-Burst |
| Spieler-Tod | Dramatisch (Freeze 1s) | 12 Frames | Max | Zeitlupe + Farbentsättigung |
| Perfect-Timing | – | – | Kurz | Gold-Flash auf Combo-Chain |

### Slow-Motion-Momente
* Letzter Treffer eines Matches → 0.3x Zeitskala für 1 Sekunde
* Auslösung über `Engine.time_scale` in Godot, sofort zurückgesetzt

---

## Kamera-System

### Lokaler Multiplayer

| Spieleranzahl | Kamera-Modus |
|--------------|-------------|
| 1 | Einzelne Kamera, folgt Spieler |
| 2 | Shared-Screen mit dynamischem Zoom-Out; Split-Screen bei großem Abstand |
| 3–4 | Feste geteilte Bildschirme (2x2) oder Shared-Screen mit maximalem Zoom |

### Shared-Screen-Logik
* Kamera zentriert sich zwischen allen aktiven Spielern
* Zoom skaliert dynamisch, sodass alle Spieler immer sichtbar sind
* Minimaler Zoom: 0.5x (Arena voll sichtbar)
* Maximaler Zoom: 1.5x (nahes Duell)

### Split-Screen-Trigger
* Abstand zwischen Spielern > 60% der Arena-Breite → sanfter Übergang zu Split
* Split-Linie verläuft immer durch die Mitte der Verbindungslinie zwischen Spielern

### Technische Umsetzung (Godot)
* `Camera2D` pro Spieler auf eigenem `SubViewport`
* Zoom via `lerp()` über `_process()`
* Kein Sprung – immer geglätteter Übergang

---

## Balance-Parameter

> **Resource-Datei:** `res://resources/balance_config.tres` — alle Werte dieser Sektion werden daraus geladen. Nie als `const` hardcoden.

### Basis-Spielerwerte

| Parameter | Wert | Anpassbar |
|-----------|------|-----------|
| HP | 100 | Ja |
| Bewegungsgeschwindigkeit | 250 px/s | Ja |
| Dodge-Geschwindigkeit | 600 px/s | Ja |
| Dodge-Dauer | 0.2s | Nein |
| Dodge-Cooldown | 0.8s | Ja |

### Schadensklassen

| Klasse | Schaden | Beispiel |
|--------|---------|---------|
| Leicht | 8–12 | Schneller Nahkampftreffer |
| Mittel | 18–25 | Standard-Spell |
| Schwer | 35–50 | Combo-Finale, Vollkreis-Spell |
| Instant-Kill | 100 | – (nicht geplant für Base-Game) |

### Cooldowns

| Aktion | Cooldown |
|--------|---------|
| Leichter Angriff | 0.15s |
| Schwerer Angriff | 0.6s |
| Spell-Cast | 1.0–2.5s (abhängig von Spell) |
| Crafting öffnen | 0.5s (Debounce) |
| Target-Switch | 0.2s |

### Respawn
* Standard: kein Respawn (Last Man Standing)
* Optionaler Modus: 3 Leben, Respawn nach 3s mit kurzer Unverwundbarkeit (1.5s)

---

## Item-System

### Designprinzip
Items droppen beim Zerstören von Terrain-Tiles und werden automatisch aufgesammelt wenn ein Spieler darüber läuft. Es gibt keine feste Slot-Begrenzung – alle aktiven Items werden in einer **horizontalen Item-Leiste** am oberen oder unteren Bildschirmrand dargestellt. Eine Slot-Begrenzung kann nach der Testphase auf Basis von Balancing-Erfahrungen eingeführt werden.

Items sind entweder **passiv** (wirken dauerhaft solange im Besitz) oder **bedingt** (aktivieren sich automatisch bei Eintreten einer definierten Bedingung). Es gibt keine manuell zu betätigende Item-Taste.

---

### Item-Drop-Mechanik
- **Quelle**: Jedes zerstörte Tile (Zustand `DESTROYED`) hat eine konfigurierbare Drop-Chance
- **Drop-Chance**: Standard 15%, konfigurierbar per `item_config.tres`
- **Item-Typ**: zufällig aus einer gewichteten Tabelle (auch in `item_config.tres`)
- **Aufsammeln**: Kollision Spieler ↔ Item-Node → sofort in Item-Leiste aufnehmen, Item-Node entfernen
- **Item-Node**: kleines `ColorRect` + `Label` (Symbol) auf dem Boden, kurze Einblend-Animation (Tween)

---

### Item-Typen

| ID | Name | Typ | Effekt | Bedingung |
|----|------|-----|--------|-----------|
| `shield_shard` | Splitter-Schild | Passiv | Reduziert nächsten eingehenden Schaden um 50% (einmalig, danach verbraucht) | – |
| `ember_core` | Glut-Kern | Passiv | Alle Treffer hinterlassen Brennen-Statuseffekt (1 Stack) für 5s | – |
| `frost_vein` | Frost-Ader | Passiv | Alle Treffer hinterlassen Nass-Statuseffekt für 5s (Reaktionsprimer) | – |
| `speed_rune` | Tempo-Rune | Passiv | +20% Bewegungsgeschwindigkeit für 8s, dann verbraucht | – |
| `life_shard` | Leben-Splitter | Bedingt | Heilt 25 HP automatisch wenn HP unter 30% fallen (einmalig) | HP < 30% |
| `dodge_crystal` | Ausweich-Kristall | Bedingt | Löst automatisch einen Dodge aus wenn ein Projektil < 80px entfernt erkannt wird (einmalig) | Projektil-Proximity |
| `overcharge` | Überladung | Bedingt | Nächster Spell nach Aufsammeln verursacht 2× Schaden (einmalig, verfällt nach 10s ungenutzt) | Erster Spell-Cast |
| `terrain_anchor` | Terrain-Anker | Passiv | Spieler fällt nicht durch zerstörte Tiles (schwebt über Lücken) für 6s | – |

> **⚠ Balance-Check nach Testphase**: Item-Spawn-Rate, Dauer-Werte und Effektstärken sind Startwerte. Alle Werte liegen in `item_config.tres` und können ohne Code-Änderung angepasst werden.

---

### HUD-Darstellung (Item-Leiste)
- **Position**: am unteren Bildschirmrand, zentriert unter dem Spieler-HUD
- **Darstellung pro Item**: `ColorRect` (Hintergrund in Element-Farbe, gedimmt) + `Label` (Icon-Symbol, weiß) + bei bedingten Items: kleiner Zustandsindikator (Pulsieren wenn Bedingung fast erfüllt)
- **Layout**: horizontale `HBoxContainer`, keine feste Maximalbreite in der Testphase
- **Verbraucht**: Item-Icon graut aus und verschwindet nach 0.5s (Tween)
- **Neu aufgesammelt**: kurzes Aufleuchten (Flash-Tween) in Spielerfarbe

#### Item-Farb-Kodierung (HUD-Hintergrund)
| Element | Hex |
|---------|-----|
| Schutz (Schild, Anker) | `#1A3A5C` (Dunkelblau) |
| Angriff (Glut, Überladung) | `#5C1A1A` (Dunkelrot) |
| Reaktion (Frost) | `#1A4A5C` (Dunkeltürkis) |
| Bewegung (Tempo) | `#3A4A1A` (Dunkelgrün) |
| Überleben (Leben, Dodge) | `#3A1A5C` (Dunkelviolett) |

---

### Technische Architektur

```
/scripts/item_system.gd          ← Verwaltet aktive Items pro Spieler, prüft Bedingungen in _process()
/scripts/item_pickup.gd          ← Node auf dem Boden (Area2D), emittiert picked_up(item_id, player_id)
/scenes/item_pickup.tscn         ← Visueller Item-Drop (ColorRect + Label + AnimationPlayer)
/scenes/ui/item_bar_ui.tscn      ← HUD-Element: horizontale Item-Leiste
/scripts/item_bar_ui.gd          ← Reagiert auf item_added / item_consumed Signale
/resources/item_config.tres      ← Drop-Chancen, Gewichtungstabelle, alle Item-Werte
```

**Signale:**
- `item_system` emittiert `item_added(player_id, item_id)`
- `item_system` emittiert `item_consumed(player_id, item_id)`
- `item_pickup.gd` emittiert `picked_up(item_id, player_id)` → `item_system` empfängt

**Bedingungsprüfung:**
- Passive Items: einmalig bei Aufnahme anwenden, Flag `is_active = true` setzen
- Bedingte Items: `item_system._process(delta)` prüft pro Spieler alle bedingten Items gegen ihre Trigger-Bedingung
- Verbrauchte Items: Flag `is_consumed = true`, wird in nächstem Frame aus Liste entfernt und Signal `item_consumed` gefeuert

**Integration mit bestehenden Systemen:**
- `tile.gd` → bei `DESTROYED`-Übergang: `item_system.try_drop(tile_position)` aufrufen
- `damage_system.gd` → vor Schadensanwendung: `item_system.get_damage_modifier(player_id)` abfragen (für `shield_shard`, `overcharge`)
- `player.gd` → `speed` wird durch `item_system.get_speed_multiplier(player_id)` skaliert
- `status_effect_component.gd` → `ember_core` / `frost_vein` hookten sich in `damage_system`-Treffer ein via `item_system`-Signal `on_hit_effect(attacker_id, target_id)`

---

### Phase-Zuordnung
Das Item-System wird in **Phase 2 Stream B** (Spellcrafting) als zusätzliche Komponente implementiert, da es dieselbe Infrastruktur nutzt (`status_effect_component`, `damage_system`, Spieler-Signale). Der Drop-Trigger in `tile.gd` wird in Phase 2 nachgetragen (Stream B koordiniert mit Phase 1 Stream D).

> **Slot-Limit-Entscheidung nach Testphase**: Falls in der Testphase Übersichtlichkeit ein Problem wird, wird ein konfigurierbares Maximum (z.B. 4 Items) in `item_config.tres` eingeführt. Die HUD-Darstellung unterstützt das bereits durch die `HBoxContainer`-Struktur.

---

## Charakter-Sprites & Asset-Integration

### Designprinzip
Das Spiel ist **2D Top-Down Pixelart** mit prozeduralen Primitiven für Arena und Effekte. Charaktere und Waffen werden als **Pixelart-Spritesheets** dargestellt sobald die Assets vorliegen. Bis dahin laufen Platzhalter (`ColorRect`) – der Agent baut die Sprite-Integration von Anfang an vor, sodass Assets jederzeit eintauschbar sind.

> **Lieferpflicht extern**: Charakter-Sprites und Waffen-Sprites werden vom Auftraggeber geliefert. Der Agent wartet nicht darauf – Platzhalter bleiben aktiv bis Assets vorhanden sind.

---

### Spritesheet-Spezifikation – Charaktere

| Eigenschaft | Wert |
|-------------|------|
| Tile-Größe | 48×48 px (kann angepasst werden) |
| Richtungen | 4 (Oben, Unten, Links, Rechts) – kein Diagonalset nötig, Godot interpoliert |
| Format | PNG, transparenter Hintergrund |
| Farbgebung | Neutral (Graustufen oder einheitliche Basisfarbe) – Spielerfarbe wird per `modulate` in Godot aufgemalt |

#### Benötigte Animationen pro Charakter

| Animation | Frames | Loop | Hinweis |
|-----------|--------|------|---------|
| `idle` | 4 | Ja | Leichtes Atmen / Pulsieren |
| `walk` | 6 | Ja | Alle 4 Richtungen |
| `dodge` | 4 | Nein | Richtungsunabhängig, schnell |
| `attack_light` | 3 | Nein | Leichter Angriff |
| `attack_heavy` | 5 | Nein | Schwerer Angriff / Combo-Finale |
| `cast` | 4 | Nein | Spell-Cast-Pose |
| `hit` | 2 | Nein | Treffer-Reaktion |
| `death` | 6 | Nein | Endet auf letztem Frame eingefroren |

**Gesamt pro Charakter**: ~34 Frames × 4 Richtungen = ~136 Frames pro Charakter-Sprite  
**Anzahl Charaktere**: 1 Basis-Charakter reicht für v1.0 (Spielerfarbe via `modulate` differenziert)

---

### Spritesheet-Spezifikation – Waffen

| Eigenschaft | Wert |
|-------------|------|
| Tile-Größe | 32×32 px |
| Format | PNG, transparenter Hintergrund |
| Animationen | `idle` (2 Frames), `attack` (4 Frames) |
| Anzahl | 5 Archetypen (Stab, Klinge, Bogen, Hammer, Dual) |

> Waffen-Sprites sind optional für v1.0 – der Agent baut Waffen-Darstellung als `ColorRect`-Geometrie vor. Sprites können nachträglich eingetauscht werden.

---

### Technische Integration (Agent-Aufgabe)

```
/scenes/player.tscn         → AnimatedSprite2D-Node als Child von CharacterBody2D
/scripts/player_animator.gd → Steuert AnimatedSprite2D (Animation-State-Machine)
/resources/sprite_config.tres → Pfade zu Spritesheets, Tile-Größen, Frame-Counts
```

**Sprite-Modus-Toggle in `sprite_config.tres`:**
- `use_sprites = false` → Platzhalter-`ColorRect` aktiv, `AnimatedSprite2D` unsichtbar
- `use_sprites = true` → `AnimatedSprite2D` aktiv, `ColorRect` unsichtbar
- Umschalten ohne Code-Änderung – nur Resource-Wert ändern

**Spielerfarbe via `modulate`:**
- Sprites werden in Neutral-Palette geliefert
- `AnimatedSprite2D.modulate` wird auf Spieler-Primärfarbe gesetzt (aus `DESIGN.md` Farbpalette)
- Rim-Glow bleibt als `Line2D`-Overlay erhalten (prozedural, unabhängig vom Sprite)

**`player_animator.gd` reagiert auf Signale:**
- `player.gd` emittiert `animation_changed(anim_name, direction)` bei jedem State-Wechsel
- `player_animator.gd` setzt `AnimatedSprite2D.play(anim_name)` und `flip_h` für Links/Rechts

---

### Asset-Übersicht: Was kommt woher?

| Asset | Verantwortlich | Format | Wann benötigt |
|-------|---------------|--------|---------------|
| Alle `.gd`-Scripts | Agent | GDScript | Fortlaufend |
| Alle `.tscn`-Szenen | Agent | Godot TSCN | Fortlaufend |
| Alle `.tres`-Resources | Agent | Godot Resource | Fortlaufend |
| SFX (Treffer, Dodge, Combo) | Agent | Prozedural via Code | Phase 4B |
| Arena-Grafik (Boden, Wände, Runen) | Agent | Primitive (ColorRect, Line2D) | Phase 1A |
| VFX (Partikel, Trails, Shockwave) | Agent | GPUParticles2D, Line2D | Phase 4C |
| **Charakter-Spritesheets** | **Auftraggeber** | **PNG** | **Phase 4H** (neuer Stream) |
| **Waffen-Sprites** (optional v1.0) | **Auftraggeber** | **PNG** | **Phase 4H oder später** |
| **Musik (6 OGG-Tracks)** | **Auftraggeber** | **OGG (geloopt)** | **Phase 4F** |

---

## Arena-Layout-Varianten

### Grundregeln für alle Arenen
* Immer quadratisch oder leicht rechteckig (max. 2:1 Verhältnis)
* Kein Bereich darf dauerhaft außerhalb der Kamera liegen
* Mindestens 30% zerstörbare Tiles
* Immer mindestens ein zentrales Feature (Erhebung, Grube, Objekt)

### Variante 1 – „The Crucible" (Standard)
* Quadratische Arena, 32x32 Tiles
* Zentrales erhöhtes Plateau (4x4 Tiles)
* Rune-Cracks symmetrisch um das Zentrum
* Geeignet für 2–4 Spieler

### Variante 2 – „Rift Canyon"
* Rechteckig, 40x20 Tiles
* Breite Schlucht in der Mitte (unpassierbar, nur über 2 Brücken)
* Brücken zerstörbar → Spieler können isoliert werden
* Geeignet für 2 Spieler (1v1)

### Variante 3 – „Collapsed Foundry"
* Asymmetrisch, 36x28 Tiles
* Trümmer und Hindernisse verteilt
* Mehrere Ebenen (erhöhte Plattformen)
* Geeignet für 3–4 Spieler

### Variante 4 – „Void Ring"
* Ringförmig, Mitte ist eine Grube (Out-of-Bounds)
* Schmalste Punkte: 4 Tiles breit
* Chaos-Modus-Map (hohe Fallgefahr)
* Geeignet für 2–4 Spieler (hohe Spannung)

---

## Onboarding / Tutorial-Flow

### Design-Absicht
Spieler lernen durch Tun, nicht durch Lesen. Jede Mechanic wird isoliert eingeführt, dann kombiniert.

### Tutorial-Sequenz

| Schritt | Mechanic | Methode |
|---------|---------|---------|
| 1 | Bewegung & Dodge | Freies Erkunden mit Zielpfeilen |
| 2 | Target-Lock & Switch | Dummy-Gegner im Ring, Tutorial-Text |
| 3 | Basis-Angriff (Klinge) | Dummy trifft zurück (sanft) |
| 4 | Motion-Input (↓→) | Geführter Input mit visueller Spur |
| 5 | Spell-Cast | Erster Spell vorgegeben, dann frei |
| 6 | Spellcrafting | Zwei Elemente liegen bereit, Crafting erzwungen |
| 7 | Weaponcrafting | Ein Upgrade-Node mit Tutorial-Pfeil |
| 8 | Terrain-Destruction | Explodierender Tile demonstriert Mechanik |
| 9 | Freier Kampf | Trainings-KI auf niedrigem Level |

### Tutorial-Regeln
* Kein langer Text – max. 1 Satz pro Schritt
* Visuelles Highlight zeigt immer den relevanten HUD-Bereich
* Spieler kann Tutorial jederzeit überspringen
* Tutorial-Fortschritt wird gespeichert (nicht wiederholend)

---

## Accessibility

### Farbenblindmodus
* Spieler-Farbidentität wechselbar zu farbenblindfreundlichen Paletten:
  - **Deuteranopie** (Rot-Grün-Schwäche): Blau/Orange statt Cyan/Magenta — Spieler 1: `#0077FF`, Spieler 2: `#FF7700`, Spieler 3: `#FFFFFF`, Spieler 4: `#FF00FF`
  - **Protanopie** (Rot-Schwäche): Gelb/Blau statt Grün/Rot — Spieler 1: `#0077FF`, Spieler 2: `#FFDD00`, Spieler 3: `#FFFFFF`, Spieler 4: `#AA00FF`
  - **Tritanopie** (Blau-Gelb-Schwäche): Orange/Pink statt Gold/Gelb — Spieler 1: `#FF6600`, Spieler 2: `#FF007F`, Spieler 3: `#00CC88`, Spieler 4: `#CC0000`
* Option im Einstellungsmenü unter „Barrierefreiheit"
* Alle 3 Paletten mit Coblis oder ähnlichem Simulator testen vor Festlegung der finalen Hex-Werte

### Controller & Input
* Vollständiges Button-Remapping für alle Aktionen (persistiert in `user://controls.tres`)
* Combo-Assist-Modus: Motion-Inputs vereinfacht (nur Richtung + `B`, keine Geste nötig)
* SNES-Layout als Referenz – alle Funktionen mit 12 Buttons bedienbar
* Mono-Audio-Option (für einseitige Hörbeeinträchtigung)

### UI & Lesbarkeit
* Alle Textgrößen skalierbar (80% – 150%)
* HUD-Elemente können auf eine Seite des Bildschirms verschoben werden
* Option: Immer Spielernamen über Charakteren anzeigen (nicht nur bei Hover)

### Untertitel
* Alle Tutorial-Texte als geschlossene Untertitel verfügbar
* Wichtige Spielereignisse als Text-Ankündigung (z. B. „PLAYER 2 ELIMINATED")

---

## Mod-System

### Design-Absicht
Alle Spiel-relevanten Werte und Definitionen sind in externen Ressourcen-Dateien gespeichert – nie hardcodiert. Das ermöglicht zwei Ebenen der Modbarkeit: einfache Daten-Mods (Werte ändern) und fortgeschrittene Skript-Mods (neue Logik). Die Core-Engine-Systeme (Physik, State Machine, Input-Parsing, Netzwerk) sind bewusst nicht modbar – sie müssen intern konsistent bleiben.

---

### Ebene 1 – Data Mods (einfach, sicher)

Nur `.tres`-Ressourcen-Dateien im `user://mods/`-Ordner. Kein Quellcode-Zugriff nötig. Sicher für lokalen Multiplayer (beide Clients müssen identische Mod-Daten laden – prüfbar via Hash).

| Resource-Datei | Inhalt | Modbar |
|----------------|--------|--------|
| `res://resources/spell_definitions.tres` | Element-Kodierung, Kombinationen, Effekt-Typen | ✅ |
| `res://resources/spell_values.tres` | Schaden, Reichweite, Cooldown pro Spell | ✅ |
| `res://resources/combo_definitions.tres` | D-Pad-Sequenzen → Spell-Mapping (Modus R) | ✅ |
| `res://resources/weapon_definitions.tres` | Archetypen, Stats, Upgrade-Nodes | ✅ |
| `res://resources/balance_config.tres` | HP, Speed, Dodge, Magie-Timeout, Schadensklassen | ✅ |
| `res://resources/bot_config.tres` | KI-Schwierigkeitsstufen, Reaktionszeiten | ✅ |
| `res://resources/arena_config.tres` | Spawn-Positionen pro Arena, Arena-spezifische Tile-Verteilung (welche Tiles zerstörbar sind) | ✅ |
| `res://resources/tile_config.tres` | Tile-interne Werte: Farben der Zustände (INTACT/CRACKED/DESTROYED), HP-Schwellwerte für State-Wechsel | ✅ |

**Mod-Ordner-Konvention:**
```
user://mods/
    mein_mod/
        spell_values.tres       ← überschreibt res://resources/spell_values.tres
        combo_definitions.tres  ← überschreibt res://resources/combo_definitions.tres
        mod.cfg                 ← Name, Version, Autor, Kompatibilitäts-Version
```

Der `ModLoader` lädt alle `.tres`-Dateien aus `user://mods/` und merged sie mit den Basis-Ressourcen. Fehlende Felder fallen auf den Basiswert zurück – Mods müssen nicht vollständig sein.

---

### Ebene 2 – Script Mods (fortgeschritten)

Externe `.gd`-Dateien werden zur Laufzeit via `load()` geladen und in definierte Hook-Punkte eingehängt. Neue Spell-Effekte, neue KI-Verhalten, neue Mechaniken – ohne das Spiel neu zu kompilieren.

> ⚠ Script-Mods sind **nur für Singleplayer und lokalen Multiplayer** vorgesehen. Im Online-Multiplayer werden Script-Mods deaktiviert (Cheating-Risiko).

**Verfügbare Hook-Punkte:**

| Hook | Datei | Wann aufgerufen |
|------|-------|----------------|
| `spell_effect_hook` | `spell_system.gd` | Nach Spell-Einschlag, vor Schadensanwendung |
| `on_tile_destroyed` | `arena_grid.gd` | Nach Tile-Zerstörung |
| `on_player_hit` | `damage_system.gd` | Nach Treffer, vor HP-Abzug |
| `bot_decision_hook` | `bot_controller.gd` | Pro Bot-Entscheidungs-Tick |
| `on_round_end` | `arena_state_manager.gd` | Bei Rundenende |

**Beispiel-Skript-Mod** (`user://mods/mein_mod/spell_effect.gd`):
```gdscript
# Überschreibt den Feuer+Blitz-Spell-Effekt
func on_spell_hit(spell_type: String, target: Node, damage: int) -> void:
    if spell_type == "plasma_bolt":
        target.apply_status("burning", 3.0)   # 3s Brennen
        target.apply_status("shocked", 0.5)   # 0.5s Betäubung
```

**Hook-Registrierung** erfolgt über `mod.cfg`:
```ini
[hooks]
spell_effect_hook = "spell_effect.gd"
bot_decision_hook = "my_bot.gd"
```

---

### ModLoader – Architektur

`ModLoader` ist ein AutoLoad das beim Spielstart läuft – vor allen anderen Systemen.

```
Spielstart
    │
    ▼
ModLoader._ready()
    ├── user://mods/ scannen
    ├── mod.cfg lesen + Kompatibilität prüfen
    ├── Ebene 1: .tres-Dateien laden + in Basis-Resources mergen
    ├── Ebene 2: .gd-Dateien laden + in Hook-Registry eintragen
    └── Signal mod_loading_complete → restliche AutoLoads starten
```

**Technische Umsetzung:**
```
/scripts/mod_loader.gd          ← AutoLoad (lädt vor allen anderen)
/resources/mod_registry.tres    ← Liste aller geladenen Mods (Name, Version, Hash)
/scripts/hook_registry.gd       ← Verwaltet Script-Mod-Hooks zur Laufzeit
```

### Regeln für Implementierer
- Alle Konstanten und Balancing-Werte **immer** aus der zugehörigen `.tres`-Resource lesen – nie als `const` im Skript hardcoden
- Neue Systeme müssen beim Entwurf sofort ihre Resource-Datei definieren
- Hook-Punkte werden in den jeweiligen Kern-Skripten als leere `_run_hooks(hook_name, args)`-Aufrufe vorbereitet
- `ModLoader` muss als erster AutoLoad in `project.godot` registriert sein

---

## Übergreifende Design-Regeln

* Lesbarkeit über Realismus
* Farbe kodiert Spielzustand
* Alles Animierte hat einen Gameplay-Grund
* Kein visuelles Element ist rein dekorativ
* Systeme-zuerst-Visuals: jeder Effekt entspricht einem Zustand

## Copilot-Nutzungshinweise

Dieses Dokument dient als:

* Übergeordneter Kontext für Copilot beim Generieren von Godot-Skripten
* Referenz für Namenskonventionen (ArenaCenter, DestructibleTile, ComboChain)
* Einschränkungs-Leitfaden zur Vermeidung von Überentwicklung oder visuellem Rauschen

---

## Pause-Menü

### Verhalten
- `Start`-Button während `COMBAT`-State → Spiel wird lokal pausiert (`get_tree().paused = true`)
- Nur der Spieler der pausiert hat sieht das Menü – andere sehen „PAUSE" als Label
- Online-Multiplayer: Pause **deaktiviert** (Echtzeit-Zwang), stattdessen Disconnect-Option

### Optionen im Pause-Menü
- Fortsetzen
- Einstellungen (gleiche Tabs wie Hauptmenü)
- Runde aufgeben (zurück zur Lobby)
- Spiel beenden (zurück zum Hauptmenü)

---

## Out-of-Bounds-Verhalten

### Was passiert bei zerstörtem Tile?
- Spieler der auf einem `DESTROYED`-Tile steht fällt nicht sofort – erst wenn er sich bewegt und kein intaktes Tile mehr erreichbar ist
- Fallen = kurze Sink-Animation (0.3s), dann **sofortiger Tod**
- Kein Respawn auf zerstörtem Tile – Spawn immer auf `INTACT`-Tile

### Arena-Rand
- Unsichtbare `StaticBody2D`-Wand am Rand → Spieler können nicht herauslaufen
- Wand-Kollision hat keinen Schadens-Effekt

---

## Spawn-Positionen

### Pro Arena-Variante

| Arena | Spawns (relativ zum Zentrum) |
|-------|------------------------------|
| **The Crucible** (32×32) | (–10, –10), (+10, +10), (–10, +10), (+10, –10) |
| **Rift Canyon** (40×20) | (–16, 0), (+16, 0), (–16, –8), (+16, +8) |
| **Collapsed Foundry** (36×28) | (–12, –10), (+12, +10), (+12, –10), (–12, +10) |
| **Void Ring** | (0, –12), (0, +12), (–12, 0), (+12, 0) |

### Spawn-Regeln
- Minimaler Abstand zwischen Spawns: 8 Tiles
- Alle Spawns auf garantiert `INTACT`-Tiles
- Bei 2 Spielern: nur Spawns 1 + 2 verwenden (maximaler Abstand)

---

## Musik-Konzept

### Design-Absicht
Die Musik unterstreicht die Phasen der Arena, ohne die Gameplay-Sounds zu übertönen. Sie ist dynamisch – sie reagiert auf den Spielzustand. Der Kernstil im Combat ist eine Fusion aus **Power Metal** und **Drum and Bass**: epische Gitarrenmelodik trifft auf aggressive DnB-Breaks. Referenzpunkte: Pendulum („Blood Sugar", „Propane Nightmares"), Mick Gordon (Doom Eternal), Perturbator.

### BPM & Timing-Struktur

| Element | BPM | Gefühl |
|---------|-----|--------|
| **Melodie / Gitarre** | 85 BPM (Halbzeit) | Episch, atmend, Power Metal |
| **DnB-Breaks** | 170 BPM (Doppelzeit) | Aggressiv, treibend, präzise |
| **Menü / Basis** | 85 BPM | Ruhig, atmosphärisch |

Alle Layer starten synchron auf demselben Grid (85 BPM Grundraster). Die DnB-Percussion läuft intern auf Doppelzeit – das ist exakt die Technik die Pendulum verwendet.

### Musik-Layer

| Layer | Wann aktiv | Stil & Charakter |
|-------|-----------|-----------------|
| **Basis-Loop** | Immer (auch im Menü, gedämpft) | Atmosphärische E-Gitarren-Harmonie (clean, langsam), tiefer Synth-Drone, kein Schlagzeug – Spannung ohne Druck |
| **Combat-Layer** | `COMBAT`-State | DnB-Breaks bei 170 BPM (rollende Amen-Break-Variante) + verzerrtes Power-Metal-Gitarrenriff; Bassline treibend und fett |
| **Intensity-Layer** | HP < 30% bei irgendeinem Spieler | Gitarren-Solo-Fragment oder Doppel-Bass-Drum-Eskalation; höhere Frequenzen, mehr Dringlichkeit |
| **Finale-Layer** | Nur 2 Spieler übrig | Alles auf Maximum: Gitarre + volle DnB-Energie + kurze Orchesterakkorde als dramatische Hits |
| **Round-End-Stinger** | `ROUND_END`-State | Kurzer Power-Chord mit Hall (1–2 Sekunden), dann Stille – kein sofortiger Loop-Einstieg |
| **Menü-Theme** | Hauptmenü | Basis-Loop solo, 85 BPM, clean Gitarre + Synth-Pad, einladend aber dunkel |

### Technische Umsetzung
- Musik als mehrere `AudioStreamPlayer`-Nodes mit synchronem Start
- Layer-Aktivierung via `volume_db`-Fade (Tween, 0.5s), nicht via Play/Stop
- Alle Layer starten gleichzeitig bei Spielstart – Lautstärke steuert was hörbar ist
- Grundraster: **85 BPM** (Melodie/Gitarre), DnB-Percussion intern auf **170 BPM**
- Initiale Musik via Godot `AudioStreamOggVorbis`; OGG-Dateien müssen Loop-Punkte auf Beat-Grenzen gesetzt haben
- Audio-Bus „Music" in `project.godot` anlegen (getrennt von SFX-Bus)

---

## Physics-Layer-Definition

| Layer | Bit | Verwendung |
|-------|-----|-----------|
| 1 | Spieler | `CharacterBody2D` der Spieler-Nodes |
| 2 | Terrain | Tile-`CollisionShape2D` (INTACT + CRACKED) |
| 3 | Projektile | Spell-Projektile, Waffen-Hitboxen |
| 4 | Arena-Wände | Äußere Begrenzung |
| 5 | Raycast-only | LOS-Checks, Target-Lock-Raycasts |

### Kollisions-Matrix

| | Spieler | Terrain | Projektile | Wände | Raycast |
|---|---------|---------|-----------|-------|---------|
| **Spieler** | ✅ | ✅ | ✅ | ✅ | – |
| **Terrain** | ✅ | – | ✅ | – | ✅ |
| **Projektile** | ✅ | ✅ | – | ✅ | – |
| **Wände** | ✅ | – | ✅ | – | – |
| **Raycast** | – | ✅ | – | – | – |

---

## Hauptmenü & Einstellungsmenü

### Hauptmenü-Flow
```
[Hauptmenü]
    ├── Spielen
    │     ├── Lokal (1–4 Spieler)
    │     │     ├── Spieleranzahl wählen
    │     │     ├── Arena wählen
    │     │     └── Start
    │     └── Online
    │           ├── Spiel hosten
    │           └── Spiel beitreten (IP-Eingabe / Steam-Lobby)
    ├── Tutorial
    ├── Einstellungen
    └── Beenden
```

### Design-Regeln Hauptmenü
- Hintergrund: animierte Arena-Silhouette (Loop, sehr dunkel, wenig Bewegung)
- Schriftart: monospaced, emissiv wirkend (weiß auf schwarz mit leichtem Glow)
- Keine 3D-Menüs – flache `VBoxContainer`-Struktur mit `ColorRect`-Buttons
- Musik: ruhige, atmosphärische Loop-Version des Arena-Soundtracks

### Einstellungsmenü-Kategorien

| Kategorie | Einstellungen |
|-----------|--------------|
| **Video** | Vollbild / Fenster, Auflösung, VSync, FPS-Limit |
| **Audio** | Master-Lautstärke, SFX-Lautstärke, Musik-Lautstärke, Mono-Audio |
| **Steuerung** | Button-Remapping pro Spieler, Deadzone-Schwellwert |
| **Barrierefreiheit** | Farbenblindmodus, Combo-Assist, Textgröße (80–150%), Spielernamen immer anzeigen |
| **Spiel** | Best-of (3/5/7), Respawn-Modus, Timer (aus/2min/5min) |

### Technische Umsetzung
```
/scenes/ui/main_menu.tscn         → Hauptmenü
/scenes/ui/settings_menu.tscn     → Einstellungen (Tab-basiert)
/scenes/ui/lobby_screen.tscn      → Spieler-Auswahl vor Match
/scripts/ui/main_menu.gd
/scripts/ui/settings_menu.gd
```

---

## KI / Bot-Gegner

### Design-Absicht
Bots ermöglichen Solo-Spiel, dienen als Trainingspartner im Tutorial und füllen offene Slots im lokalen Multiplayer auf. Sie sollen fordernd aber fair sein.

### Schwierigkeitsstufen

| Stufe | Reaktionszeit | Zielgenauigkeit | Combo-Nutzung | Crafting |
|-------|--------------|-----------------|---------------|---------|
| **Einsteiger** | 600ms | 40% | Nur Basis-Angriff | Nein |
| **Normal** | 350ms | 65% | Einfache Combos (↓→) | Gelegentlich |
| **Experte** | 150ms | 85% | Alle Combos | Ja, aktiv |
| **Meister** | 80ms | 95% | Perfect-Timing | Ja, optimal |

### Bot-Verhaltenssystem
- **Wahrnehmung**: Bot liest Spieler-Positionen, HP und aktiven Spell direkt aus dem Spielzustand (LOS-Regeln gelten auch für Bots)
- **Entscheidungsbaum:**
  ```
  wenn eigene_hp < 30%  → Dodge + Abstand halten
  wenn ziel_in_los      → Combo ausführen (mit Reaktionsverzögerung)
  wenn crafting_möglich → Spell craften (Experte+)
  sonst                 → Annähern an nächsten Spieler
  ```
- **Zufalls-Varianz**: ±20% auf alle Timing-Werte – damit Bots nicht roboterhaft wirken
- Bots nutzen dieselbe `player_input.gd`-Abstraktion – `BotInput`-Klasse überschreibt `get_move_vector()` und `get_action()`

### Technische Umsetzung
```
/scripts/bot_controller.gd        → Bot-KI-Hauptlogik
/scripts/bot_input.gd             → Implementiert player_input-Interface (BotInput-Klasse überschreibt get_move_vector() und get_action())
/resources/bot_config.tres        → Schwierigkeits-Parameter (zentrale Datei, referenziert die 4 Stufen-Resources)
/resources/bot_einsteiger.tres    → Einsteiger-Parameter (Reaktionszeit 600ms, Fehlerrate etc.)
/resources/bot_normal.tres        → Normal-Parameter (Reaktionszeit 350ms)
/resources/bot_experte.tres       → Experte-Parameter (Reaktionszeit 150ms)
/resources/bot_meister.tres       → Meister-Parameter (Reaktionszeit 80ms)
```

---

## Vollständige Farbpalette

### Spielfeld & Umgebung

| Element | Farbe | Hex |
|---------|-------|-----|
| Arena-Hintergrund | Tiefschwarz | `#0A0A12` |
| Tile Intakt | Dunkles Obsidian | `#1A1A2E` |
| Tile Gerissen (Highlight) | Rift-Orange | `#FF6600` |
| Tile Zerstört (Loch) | Tiefes Rot-Schwarz | `#1A0000` |
| Rune-Cracks | Elektrisch Blau | `#00AAFF` |
| Rune-Cracks Alternativ | Arkanes Violett | `#8B00FF` |
| Arena-Wände | Dunkles Metall | `#2A2A3E` |
| Wand-Circuitry (emissiv) | Emissiv Blau | `#0044FF` |
| Glyph – Neutral | Blau | `#0088FF` |
| Glyph – Transformation | Violett | `#AA00FF` |
| Glyph – Overcharge | Amber | `#FFAA00` |

### UI & HUD

| Element | Farbe | Hex |
|---------|-------|-----|
| HUD-Hintergrund | Semi-transparent Dunkel | `#000000AA` |
| HUD-Text | Weiß | `#FFFFFF` |
| HUD-Text Sekundär | Hellgrau | `#AAAAAA` |
| HP-Balken Voll | Grün | `#00FF88` |
| HP-Balken Mittel | Gelb | `#FFCC00` |
| HP-Balken Kritisch | Rot | `#FF2200` |
| Item-Leiste Hintergrund (leer) | Dunkelgrau | `#333344` |
| Combo-Chain Aktiv | Gold | `#FFD700` |
| Combo-Chain Fehler | Warnrot | `#FF4400` |

### Elemente & Spells

| Element | Farbe | Hex |
|---------|-------|-----|
| Feuer | Orange-Rot | `#FF4400` |
| Eis | Eisblau | `#88DDFF` |
| Blitz | Gelb-Weiß | `#FFFF88` |
| Erde | Braun-Orange | `#AA6600` |
| Schatten | Dunkles Lila | `#440066` |
| Licht | Weiß-Gold | `#FFFFAA` |

---

## Progressions- & Unlock-System

### Design-Absicht
Kein Pay-to-Win. Alle spielerischen Inhalte sind von Beginn an verfügbar. Unlocks sind rein kosmetischer Natur und schaffen Langzeitmotivation ohne die Balance zu brechen.

### Unlock-Kategorien

| Kategorie | Unlock-Bedingung | Beispiele |
|-----------|-----------------|---------|
| **Spieler-Farb-Skins** | Matches gewonnen (10/25/50/100) | Neon-Pink, Arktisches Weiß, Lava-Rot |
| **Rim-Glow-Muster** | Achievements | Pulsierend, Blitz-Statisch, Regenbogen |
| **Arena-Farbthemen** | Stunden gespielt | Blutmond, Frostrift, Void-Schwarz |
| **Waffen-Glüh-Farben** | Alle Rezepte eines Elements verwendet | Feuer-Schwert in reinem Weiß |
| **Titel** (Lobby-Anzeige) | Besondere Leistungen | „Combo-Gott", „Architekt", „Unberührt" |
| **Modus-B-Momentum** | Achievement `momentum_master` (Bedingung offen) | Bewegung bleibt in Modus B erhalten ⚠ Balance-Check nach Testphase |

### Persistenz
- Fortschritt wird in `user://progress.tres` gespeichert
- Steam-Achievements triggern parallel (kein doppeltes System)
- Alles lokal für v1.0 – kein Server-seitiger Anti-Cheat nötig

### Achievement-Liste

| ID | Name | Bedingung | Unlock |
|----|------|-----------|--------|
| `first_kill` | „Erster Bluttest" | Ersten Kill landen | – |
| `combo_master` | „Combo-Meister" | Z-Motion 10× erfolgreich | – |
| `architect` | „Zerstörer" | 500 Tiles zerstören | – |
| `craftsman` | „Schmiedemeister" | Alle 5 Waffen-Archetypen craften | – |
| `elementalist` | „Elementarmagier" | Alle 6 Rezepte einmal verwenden | – |
| `survivor` | „Überlebender" | Match ohne Dodge-Nutzung gewinnen | – |
| `momentum_master` | „Unaufhaltsam" | *(Bedingung offen – wird nach Testphase festgelegt)* | Modus-B-Momentum ⚠ Balance-Check nach Testphase |

> **Hinweis zu `momentum_master`**: Modus-B-Momentum ist das einzige Unlock das einen spielerischen Unterschied macht (alle anderen sind kosmetisch). Falls es die Balance bricht, wird es nach der Testphase entfernt.

---

Ende des Dokuments.
