# Arena Visual & Gameplay Design Dokument

Zweck: Dieses Dokument übersetzt drei visuelle Moodboards in konkretes, systemorientiertes Design-Wissen, das als strukturierter Input für GitHub Copilot bei der Implementierung des Spiels in Godot genutzt wird. Schwerpunkte sind Determinismus, Modularität, Lesbarkeit und Umsetzung mit Primitiven (ColorRect, Line2D, Labels, GPUParticles2D).

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

* Charaktere werden hauptsächlich als Silhouetten dargestellt
* Nur Hände, Waffen und aktive Spell-Komponenten leuchten
* Waffen sind Hybridformen (Stab + Klinge), aus einfacher Geometrie aufgebaut

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

## Weaponcrafting-System

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

### Basis-Spielerwerte

| Parameter | Wert | Anpassbar |
|-----------|------|-----------|
| HP | 100 | Ja |
| Bewegungsgeschwindigkeit | 250 px/s | Ja |
| Dodge-Geschwindigkeit | 600 px/s | Ja |
| Dodge-Dauer | 0.2s | Nein |
| Dodge-Cooldown | 0.8s | Ja |
| Spell-Slots | 3 | Nein |

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
  - Deuteranopie (Rot-Grün): Blau/Orange statt Cyan/Magenta
  - Protanopie: Gelb/Blau statt Grün/Rot
* Option im Einstellungsmenü unter „Barrierefreiheit"

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
/scripts/bot_input.gd             → Implementiert player_input-Interface
/resources/bot_config.tres        → Schwierigkeits-Parameter
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
| Spell-Slot Leer | Dunkelgrau | `#333344` |
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
