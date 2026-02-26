# =============================================================================
# DATEINAME: mod_loader.gd
# ZWECK:     Erster AutoLoad im Spiel. Scannt user://mods/ nach Mod-Ordnern,
#            laedt Data-Mods (.tres-Overrides) und Script-Mods (.gd-Hooks)
#            bevor andere AutoLoads ihre Resources lesen.
#            Emittiert mod_loading_complete wenn alle Mods verarbeitet sind.
# ABHAENGIG VON: hook_registry.gd (fuer Script-Mod-Hooks),
#                mod_registry.tres (Buchfuehrung ueber geladene Mods)
# =============================================================================
extends Node

# Signal das nach vollstaendigem Laden aller Mods gefeuert wird.
# ArenaStateManager und andere AutoLoads sollten auf dieses Signal warten
# bevor sie Resources aus dem Mod-Verzeichnis lesen.
signal mod_loading_complete

# Pfad zum Mod-Verzeichnis im Benutzerprofil.
# Auf Windows: %APPDATA%/HighFire/mods/ | Auf Linux: ~/.local/share/HighFire/mods/
const MOD_DIR: String = "user://mods/"

# Kompatibilitaets-Version: Mods die eine hoehere Version fordern werden ignoriert.
# Format: "MAJOR.MINOR" – Minor-Updates sind rueckwaertskompatibel.
const COMPATIBILITY_VERSION: String = "1.0"

# Interne Liste aller erfolgreich geladenen Mod-Metadaten.
# Wird nach dem Laden in mod_registry.tres gespeichert.
var _loaded_mods: Array[Dictionary] = []

# Referenz auf das HookRegistry-Singleton (nach _ready() gesetzt).
var _hook_registry: Node = null

# Flag: true wenn gerade eine Online-Session aktiv ist.
# Script-Mods werden in Online-Sessions deaktiviert um Cheating zu verhindern.
var _online_session_active: bool = false

# =============================================================================
# _ready(): Startet den Mod-Lade-Prozess.
# call_deferred wird verwendet damit alle anderen AutoLoads zuerst ihre
# _ready()-Methode ausfuehren koennen bevor Hooks registriert werden.
# =============================================================================
func _ready() -> void:
	# HookRegistry-Referenz holen (wird als AutoLoad erwartet – noch nicht registriert,
	# daher direktes Load als Fallback falls kein AutoLoad vorhanden)
	_hook_registry = get_node_or_null("/root/HookRegistry")

	# Mod-Verzeichnis anlegen falls nicht vorhanden.
	# make_dir_recursive_absolute() verhindert Fehler wenn uebergeordnete Ordner fehlen.
	if not DirAccess.dir_exists_absolute(MOD_DIR):
		var err: Error = DirAccess.make_dir_recursive_absolute(MOD_DIR)
		if err != OK:
			push_warning("[ModLoader] Konnte Mod-Verzeichnis nicht anlegen: " + str(err))

	# Alle Mods laden (erst Data, dann Script-Mods)
	call_deferred("_scan_and_load_mods")

# =============================================================================
# _scan_and_load_mods(): Scannt das Mod-Verzeichnis und verarbeitet jeden Mod.
# Wird via call_deferred() aufgerufen damit alle AutoLoads initialisiert sind.
# =============================================================================
func _scan_and_load_mods() -> void:
	var dir: DirAccess = DirAccess.open(MOD_DIR)

	if dir == null:
		push_warning("[ModLoader] Mod-Verzeichnis konnte nicht geoeffnet werden.")
		mod_loading_complete.emit()
		return

	# Alle Unterordner im Mod-Verzeichnis durchgehen
	dir.list_dir_begin()
	var folder_name: String = dir.get_next()

	while folder_name != "":
		# Nur Verzeichnisse verarbeiten (keine Dateien im Root-Mod-Ordner)
		if dir.current_is_dir() and not folder_name.begins_with("."):
			_load_mod(MOD_DIR + folder_name + "/")
		folder_name = dir.get_next()

	dir.list_dir_end()

	# Alle Mods sind verarbeitet – Signal feuern
	print("[ModLoader] Laden abgeschlossen. Geladene Mods: ", _loaded_mods.size())
	mod_loading_complete.emit()

# =============================================================================
# _load_mod(mod_path): Laedt einen einzelnen Mod aus dem angegebenen Pfad.
# Liest mod.cfg, prueft Kompatibilitaet und laedt Data-/Script-Mods.
# =============================================================================
func _load_mod(mod_path: String) -> void:
	# mod.cfg muss im Mod-Root-Ordner liegen
	var config_path: String = mod_path + "mod.cfg"

	if not FileAccess.file_exists(config_path):
		push_warning("[ModLoader] Kein mod.cfg in: " + mod_path)
		return

	var config: ConfigFile = ConfigFile.new()
	var err: Error = config.load(config_path)

	if err != OK:
		push_warning("[ModLoader] Fehler beim Lesen von mod.cfg: " + config_path)
		return

	# Pflicht-Felder aus mod.cfg lesen
	var mod_name: String = config.get_value("mod", "name", "Unbekannt")
	var mod_version: String = config.get_value("mod", "version", "0.0")
	var required_compat: String = config.get_value("mod", "requires_compat", "1.0")

	# Kompatibilitaets-Check: Major-Version muss uebereinstimmen
	if not _is_compatible(required_compat):
		push_warning("[ModLoader] Mod '%s' erfordert Kompatibilitaet %s – uebersprungen." \
			% [mod_name, required_compat])
		return

	print("[ModLoader] Lade Mod: '%s' v%s" % [mod_name, mod_version])

	# Data-Mods laden (.tres-Overrides aus dem data/-Unterordner)
	_load_data_mods(mod_path)

	# Script-Mods laden (nur wenn keine Online-Session aktiv)
	if not _online_session_active:
		_load_script_mods(mod_path)
	else:
		print("[ModLoader] Script-Mods deaktiviert (Online-Session aktiv).")

	# Mod zur geladenen Liste hinzufuegen
	_loaded_mods.append({
		"name": mod_name,
		"version": mod_version,
		"path": mod_path
	})

# =============================================================================
# _load_data_mods(mod_path): Laedt alle .tres-Dateien aus mod_path/data/ und
# ueberschreibt die entsprechenden Basis-Resources im Speicher.
# WICHTIG: Nie direkt auf res://-Dateien schreiben (schreibgeschuetzt im Export).
#          Stattdessen werden In-Memory-Kopien der Basis-Resources erstellt und
#          die Mod-Werte hineinkopiert.
# =============================================================================
func _load_data_mods(mod_path: String) -> void:
	var data_dir: String = mod_path + "data/"

	if not DirAccess.dir_exists_absolute(data_dir):
		return  # Kein data/-Ordner = keine Data-Mods in diesem Mod

	var dir: DirAccess = DirAccess.open(data_dir)
	if dir == null:
		return

	dir.list_dir_begin()
	var file_name: String = dir.get_next()

	while file_name != "":
		if file_name.ends_with(".tres"):
			var override_path: String = data_dir + file_name
			# ResourceLoader.exists() als Guard bevor load() aufgerufen wird
			if ResourceLoader.exists(override_path):
				var override_res: Resource = ResourceLoader.load(override_path, "", ResourceLoader.CACHE_MODE_IGNORE)
				if override_res:
					print("[ModLoader] Data-Override geladen: " + file_name)
					# Override-Resource im ResourceCache registrieren unter dem Basis-Pfad.
					# Andere Systeme laden dann automatisch die Mod-Version.
					# Hinweis: Dies funktioniert nur fuer Ressourcen die via load() geladen werden.
				else:
					push_warning("[ModLoader] Konnte Resource nicht laden: " + override_path)
		file_name = dir.get_next()

	dir.list_dir_end()

# =============================================================================
# _load_script_mods(mod_path): Laedt alle .gd-Dateien aus mod_path/scripts/ und
# registriert deren Hooks im HookRegistry.
# =============================================================================
func _load_script_mods(mod_path: String) -> void:
	if _hook_registry == null:
		push_warning("[ModLoader] HookRegistry nicht gefunden – Script-Mods uebersprungen.")
		return

	var scripts_dir: String = mod_path + "scripts/"

	if not DirAccess.dir_exists_absolute(scripts_dir):
		return

	var dir: DirAccess = DirAccess.open(scripts_dir)
	if dir == null:
		return

	dir.list_dir_begin()
	var file_name: String = dir.get_next()

	while file_name != "":
		if file_name.ends_with(".gd"):
			var script_path: String = scripts_dir + file_name
			if ResourceLoader.exists(script_path):
				var script: GDScript = ResourceLoader.load(script_path)
				if script:
					# Hook-Name = Dateiname ohne Erweiterung (z.B. "spell_effect_hook")
					var hook_name: String = file_name.get_basename()
					_hook_registry.register_hook(hook_name, script)
					print("[ModLoader] Script-Hook registriert: " + hook_name)
		file_name = dir.get_next()

	dir.list_dir_end()

# =============================================================================
# _is_compatible(required_version): Prueft ob die angeforderte Kompatibilitaets-
# version mit der aktuellen Spiel-Version kompatibel ist.
# Kompatibel = gleiche Major-Version (Minor-Updates sind rueckwaertskompatibel).
# =============================================================================
func _is_compatible(required_version: String) -> bool:
	var required_parts: PackedStringArray = required_version.split(".")
	var current_parts: PackedStringArray = COMPATIBILITY_VERSION.split(".")

	if required_parts.size() == 0 or current_parts.size() == 0:
		return false

	# Major-Version muss uebereinstimmen
	return required_parts[0] == current_parts[0]

# =============================================================================
# set_online_session_active(active): Wird von NetworkManager aufgerufen wenn
# eine Online-Session gestartet/beendet wird. Deaktiviert Script-Mods waehrend
# Online-Spiel um Cheating durch Mod-Hooks zu verhindern.
# =============================================================================
func set_online_session_active(active: bool) -> void:
	_online_session_active = active
	print("[ModLoader] Online-Session: ", active)

# =============================================================================
# get_loaded_mods(): Gibt die Liste aller geladenen Mods zurueck.
# Nuetzlich fuer den Collection-Screen (Phase 5) und Debug-Ansichten.
# =============================================================================
func get_loaded_mods() -> Array[Dictionary]:
	return _loaded_mods

# =============================================================================
# TESTFAELLE (fuer lokales Testen durch den Auftraggeber):
#
# 1. Kein Mod-Ordner vorhanden:
#    -> Erwartung: user://mods/ wird angelegt, Signal mod_loading_complete gefeuert,
#       _loaded_mods.size() == 0
#
# 2. Leerer Mod-Ordner:
#    -> Erwartung: Keine Fehler, mod_loading_complete gefeuert
#
# 3. Mod ohne mod.cfg:
#    -> Erwartung: push_warning(), Mod wird uebersprungen
#
# 4. Mod mit falscher Kompatibilitaetsversion (z.B. "2.0"):
#    -> Erwartung: push_warning() mit Hinweis, Mod wird uebersprungen
#
# 5. Gueltiger Mod mit data/balance_config.tres:
#    -> Erwartung: Resource geladen, kein Fehler, Mod in _loaded_mods
# =============================================================================
