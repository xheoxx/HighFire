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

* Thumbstick- und Motion-Inputs erzeugen sichtbare Trails
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

### Design Intent
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

### Design Intent
Motion-Combos sind die Sprache des Spiels. Jede Bewegung hat eine Bedeutung – der Spieler lernt eine Grammatik, keine Menüs. Inputs fühlen sich physisch an.

### Grundbewegungen (Basis-Lexikon)

| Symbol | Motion | Beschreibung |
|--------|--------|--------------|
| ↑ | Stick gerade hoch | Aufwärtsstoß |
| ↓ | Stick gerade runter | Stampf / Erdanker |
| → | Stick gerade rechts | Vorwärtsstoß (relativ zu Spieler) |
| ← | Stick gerade links | Rückzug / Konter-Setup |
| ↓→ | Viertelkreis vorwärts | Klassischer Feuerball-Input |
| ↓← | Viertelkreis rückwärts | Defensiv-Spell / Schild |
| →↓→ | Z-Motion | Schwere Kombo-Finale |
| ○ | Vollkreis | Ladeangriff / AoE-Spell |
| ←→ | Hin-und-Her | Schnell-Angriff / Burst |

### Combo-Struktur
Combos bestehen aus **3 Ebenen**:
1. **Motion** (Joystick-Geste) – definiert Spell-Typ
2. **Element** (welcher Spell gerade gecharged ist) – definiert Schadenstyp
3. **Finish-Button** (Schultertaste L2/R2) – löst aus

Beispiel: `↓→` + `[Fire-Element aktiv]` + `R2` = Feuerball geradeaus

### Timing-Fenster
* Motion muss innerhalb von **0,4 Sekunden** abgeschlossen sein
* Zu langsam: Input verfällt, kein Verbrauch von Spell-Ressourcen
* Perfect-Timing (< 0,15s): Bonus-Effekt (z. B. größerer AoE, mehr Schaden)

---

## Spellcrafting-System

### Design Intent
Spells werden aus Elementen zusammengebaut wie Rezepte. Das Crafting fühlt sich wie ein Ritual an – nicht wie ein Shop.

### Elemente

| Element | Symbol | Primäreffekt | Sekundäreffekt |
|---------|--------|-------------|----------------|
| Feuer | 🔥 | Direktschaden | Brennen (DoT) |
| Eis | ❄️ | Verlangsamung | Einfrieren bei Stack |
| Blitz | ⚡ | Ketteneffekt | Betäubung |
| Erde | 🪨 | Terrain-Zerstörung | Rüstungs-Debuff |
| Schatten | 🌑 | Line-of-Sight-Blocker | Unsichtbarkeit (kurz) |
| Licht | ✨ | Heilung (selbst/ally) | Blend-Effekt |

### Crafting-Rezepte (Kombinationen)

| Rezept | Effekt | Besonderheit |
|--------|--------|--------------|
| Feuer + Eis | Dampfwolke (AoE) | Blockiert Sicht |
| Blitz + Erde | Seismischer Impuls | Zerstört Tiles im Radius |
| Schatten + Licht | Spiegelklon | Täuschungs-Decoy |
| Feuer + Blitz | Plasmabolt | Schnellster Projektil |
| Eis + Erde | Frostwall | Terrain-Blockade |
| Licht + Erde | Heilfeld | Permanenter HoT-Bereich |

### Crafting-Flow
1. Spieler sammelt Elemente durch Treffer landen oder Terrain-Interaktion
2. Crafting-Panel öffnet sich mit `L1` (Kurzdruck = Spell-Slot wechseln, Langdruck = Crafting-UI)
3. Zwei Elemente auswählen → Spell wird gebaut
4. Spell belegt einen von **3 Spell-Slots** am HUD

---

## Weaponcrafting-System

### Design Intent
Waffen sind die physische Erweiterung der Spells. Eine Waffe ohne passenden Spell ist schwächer; zusammen entstehen Synergien.

### Waffen-Archetypen

| Typ | Reichweite | Tempo | Spell-Synergie |
|-----|-----------|-------|----------------|
| **Klinge** | Nah | Schnell | Feuer, Blitz |
| **Stab** | Mittel | Mittel | Alle Spells |
| **Kanone** | Fern | Langsam | Eis, Erde |
| **Klaue** | Nah | Sehr schnell | Schatten |
| **Schild-Arm** | Nah | Sehr langsam | Licht, Eis |

### Upgrade-Nodes
Jede Waffe hat **3 Upgrade-Nodes**, die mit gesammelten Materialien (aus Terrain-Zerstörung) freigeschaltet werden:
- **Node 1**: Basis-Stat (Schaden oder Reichweite)
- **Node 2**: Spell-Synergie-Bonus
- **Node 3**: Sonder-Effekt (z. B. Kettenangriff, Durchdringung)

### Crafting-Flow
1. Materialien aus zerstörten Tiles sammeln (automatisch aufgehoben)
2. Weapon-Crafting via `R1` (Langdruck) öffnet das Waffen-Panel
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

### Design Intent
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
* Vollständiges Button-Remapping für alle Aktionen
* Combo-Assist-Modus: Motion-Inputs vereinfacht (nur Richtung + Button, keine Geste nötig)
* Mono-Audio-Option (für einseitige Hörbeeinträchtigung)

### UI & Lesbarkeit
* Alle Textgrößen skalierbar (80% – 150%)
* HUD-Elemente können auf eine Seite des Bildschirms verschoben werden
* Option: Immer Spielernamen über Charakteren anzeigen (nicht nur bei Hover)

### Subtitles / Untertitel
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

Ende des Dokuments.
