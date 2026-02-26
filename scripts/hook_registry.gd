# =============================================================================
# DATEINAME: hook_registry.gd
# ZWECK:     Zentrales Hook-System fuer Script-Mods (Ebene 2 des Mod-Systems).
#            Mods registrieren hier ihre Hooks – Spiel-Systeme rufen run_hook()
#            auf um Mods die Moeglichkeit zu geben Werte zu modifizieren oder
#            auf Ereignisse zu reagieren.
# ABHAENGIG VON: mod_loader.gd (registriert Hooks via register_hook())
# =============================================================================
extends Node

# Dictionary: hook_name (String) -> Array of GDScript-Instanzen
# Jeder Hook-Slot kann mehrere Mods bedienen (mehrere Listener).
# Beispiel: {"spell_effect_hook": [<script_inst_1>, <script_inst_2>]}
var _hooks: Dictionary = {}

# =============================================================================
# register_hook(hook_name, script): Registriert ein GDScript als Hook-Handler.
# Das Script muss eine Funktion mit dem selben Namen wie hook_name enthalten.
# Beispiel: hook_name="spell_effect_hook" -> Script muss spell_effect_hook() haben.
# =============================================================================
func register_hook(hook_name: String, script: GDScript) -> void:
	# Instanz des Scripts erstellen damit es state behalten kann
	var instance: Object = script.new()

	if not _hooks.has(hook_name):
		_hooks[hook_name] = []

	_hooks[hook_name].append(instance)
	print("[HookRegistry] Hook registriert: '%s' (Gesamtzahl: %d)" \
		% [hook_name, _hooks[hook_name].size()])

# =============================================================================
# run_hook(hook_name, payload): Fuehrt alle registrierten Hooks fuer hook_name aus.
# payload ist ein Dictionary das die Hook-Handler lesen und modifizieren koennen.
# Rueckgabewert: das (moeglicherweise modifizierte) payload Dictionary.
#
# Beispiel-Aufruf aus spell_system.gd:
#   var result = HookRegistry.run_hook("spell_effect_hook", {"damage": 20, "spell": "fireball"})
#   var final_damage = result.get("damage", 20)
# =============================================================================
func run_hook(hook_name: String, payload: Dictionary) -> Dictionary:
	if not _hooks.has(hook_name):
		# Kein Hook registriert fuer diesen Slot – unveraendert zurueckgeben
		return payload

	var result: Dictionary = payload.duplicate(true)

	for handler in _hooks[hook_name]:
		# Pruefen ob der Handler die erwartete Methode hat
		if handler.has_method(hook_name):
			# Handler darf result veraendern und gibt es zurueck
			var handler_result = handler.call(hook_name, result)
			if handler_result is Dictionary:
				result = handler_result
		else:
			push_warning("[HookRegistry] Handler fuer '%s' hat keine Methode '%s'" \
				% [hook_name, hook_name])

	return result

# =============================================================================
# clear_hooks(): Entfernt alle registrierten Hooks.
# Wird benoetigt wenn Mods zur Laufzeit deaktiviert werden (z.B. bei Online-Start).
# =============================================================================
func clear_hooks() -> void:
	_hooks.clear()
	print("[HookRegistry] Alle Hooks geleert.")

# =============================================================================
# has_hook(hook_name): Prueft ob mindestens ein Hook fuer diesen Slot registriert ist.
# Nuetzlich fuer Systeme die wissen wollen ob ein Mod aktiv ist.
# =============================================================================
func has_hook(hook_name: String) -> bool:
	return _hooks.has(hook_name) and _hooks[hook_name].size() > 0

# =============================================================================
# TESTFAELLE (fuer lokales Testen durch den Auftraggeber):
#
# 1. run_hook() ohne registrierten Hook:
#    -> Erwartung: payload unveraendert zurueck, kein Fehler
#
# 2. register_hook() + run_hook() mit korrektem Handler:
#    -> Erwartung: payload wird durch Handler modifiziert
#
# 3. Handler ohne erwartete Methode:
#    -> Erwartung: push_warning(), payload unveraendert
#
# 4. Mehrere Handler fuer denselben Hook:
#    -> Erwartung: beide Handler ausgefuehrt, payload von beiden modifiziert
# =============================================================================
