// HighFire Spellcraft Arena – Strudel-Kompositionsskript
// Einfügen auf https://strudel.cc und Play drücken
//
// Konzept: 85 BPM Basis, DnB-Percussion intern 170 BPM (Halbzeit-Feel),
// Power-Metal-Gitarren-Riffs, dunkle arkane Akkorde.
//
// LAYER-ÜBERSICHT (entspricht den 6 Godot-Music-Slots in Phase 4F):
//   basis_loop        → Drums + Bass (immer aktiv im Combat)
//   combat_layer      → Gitarren-Riff (aktiv ab COMBAT-State)
//   intensity_layer   → Lead-Melodie + Dissonanz (aktiv wenn HP < 30%)
//   finale_layer      → Brass / Choir-Pad (aktiv wenn 2 Spieler übrig)
//   round_end_stinger → kurzer Einmal-Sting (ROUND_END) – loopt hier zur Vorschau
//   menu_theme        → ruhigeres Ambient-Theme für Hauptmenü/Lobby
//
// Alle Layer laufen hier gleichzeitig via $:-Syntax.
// Für Godot-Export: jeden $:-Block einzeln solo nehmen und aufnehmen,
// dann in DAW auf Loop-Punkte schneiden → OGG exportieren.
//
// SOLO-TIPP: Einen Block kommentieren um die anderen zu hören.
// MUTE-TIPP:  .gain(0) an einen Block anhängen um ihn stummzuschalten.

// --- GLOBALE EINSTELLUNGEN ---
// 85 BPM: cps = BPM / 60 / Beats-pro-Cycle
// Mit 4 Beats pro Cycle: 85/60/4 ≈ 0.354 cps
setcps(85/60/4)

// =============================================================
// $: basis_loop  – Drums + Bass (Fundament, immer aktiv)
// =============================================================
$: stack(
  // Kick: Halbzeit-Groove auf 1 und 3
  s("bd").struct("x ~ ~ ~ x ~ ~ ~").bank("RolandTR808"),

  // Snare: auf 2 und 4 mit Ghost-Note
  s("sd").struct("~ x ~ [~ x] ~ x ~ ~").gain(0.7).bank("RolandTR808"),

  // Hi-Hat: 16tel-Groove mit Lücken
  s("hh").struct("x x ~ x x ~ x ~").gain(0.5).bank("RolandTR808"),

  // Sub-Bass-Linie: dunkel, treibend
  note("c1 ~ eb1 ~ f1 ~ g1 [~ f1]")
    .s("sawtooth")
    .lpf(300)
    .gain(0.8)
    .slow(2)
)

// =============================================================
// $: combat_layer  – Gitarren-Riff (ab COMBAT-State)
// =============================================================
$: note("<[c2 c2 eb2 ~ c2] [f2 ~ eb2 ~ d2]>")
  .s("sawtooth")
  .distort(0.8)
  .lpf(2000)
  .gain(0.6)
  .slow(2)

// =============================================================
// $: intensity_layer  – Lead + Dissonanz (HP < 30%)
// =============================================================
$: note("<[c4 b3 bb3 a3] [ab3 g3 f#3 f3]>")
  .s("square")
  .gain(0.5)
  .delay(0.25)
  .delaytime(0.2)
  .delayfeedback(0.4)
  .slow(4)

// =============================================================
// $: finale_layer  – Breiter Akkord-Pad (letzte 2 Spieler)
// =============================================================
$: chord("<Cm7 Fm7 Gm Cm>")
  .voicing()
  .s("pad")
  .gain(0.45)
  .attack(0.8)
  .release(1.2)
  .slow(4)

// =============================================================
// $: round_end_stinger  – Fallende Fanfare (ROUND_END)
// Im Spiel nur einmal abgespielt – hier loopt sie zur Vorschau.
// =============================================================
$: note("c5 g4 eb4 c4")
  .s("sawtooth")
  .gain(0.9)
  .slow(4)
  .attack(0.01)
  .release(0.5)

// =============================================================
// $: menu_theme  – Ambient-Pad + Melodie (Hauptmenü/Lobby)
// =============================================================
$: stack(
  chord("<Cm Abmaj7 Eb Gm>")
    .voicing()
    .s("pad")
    .gain(0.4)
    .attack(1.2)
    .release(2.0)
    .slow(8),

  note("<[~ c5 ~ eb5] [~ f5 ~ g5] [~ eb5 ~ d5] [c5 ~ ~ ~]>")
    .s("sine")
    .gain(0.3)
    .delay(0.3)
    .delaytime(0.375)
    .delayfeedback(0.5)
    .slow(4)
)
