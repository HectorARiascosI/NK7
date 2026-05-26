extends Node

## Script de prueba para verificar funcionalidad del menú de ajustes

func _ready() -> void:
	print("\n=== PRUEBA DE AJUSTES ===")
	
	# Verificar que GameManager tiene todas las variables
	print("\n1. Variables de GameManager:")
	print("  - master_volume: ", GameManager.master_volume)
	print("  - music_volume: ", GameManager.music_volume)
	print("  - sfx_volume: ", GameManager.sfx_volume)
	print("  - screen_shake_enabled: ", GameManager.screen_shake_enabled)
	print("  - camera_smoothing_speed: ", GameManager.camera_smoothing_speed)
	
	# Verificar buses de audio
	print("\n2. Buses de audio:")
	var master_idx = AudioServer.get_bus_index("Master")
	var music_idx = AudioServer.get_bus_index("Music")
	var sfx_idx = AudioServer.get_bus_index("SFX")
	print("  - Master bus index: ", master_idx)
	print("  - Music bus index: ", music_idx)
	print("  - SFX bus index: ", sfx_idx)
	
	# Probar cambio de volumen
	print("\n3. Probando cambio de volumen...")
	GameManager.master_volume = 0.5
	_apply_audio()
	print("  - Master volume cambiado a 50%")
	
	# Probar screen shake
	print("\n4. Probando screen shake...")
	GameManager.screen_shake_enabled = false
	print("  - Screen shake desactivado: ", GameManager.screen_shake_enabled)
	GameManager.screen_shake_enabled = true
	print("  - Screen shake activado: ", GameManager.screen_shake_enabled)
	
	# Probar guardado
	print("\n5. Probando guardado...")
	_save_test()
	print("  - Configuración guardada en user://settings.cfg")
	
	# Probar carga
	print("\n6. Probando carga...")
	GameManager.load_settings()
	print("  - Configuración cargada desde archivo")
	print("  - master_volume después de cargar: ", GameManager.master_volume)
	
	print("\n=== PRUEBA COMPLETADA ===\n")
	
	# Limpiar
	queue_free()


func _apply_audio() -> void:
	var master_idx = AudioServer.get_bus_index("Master")
	if master_idx >= 0:
		AudioServer.set_bus_volume_db(master_idx, linear_to_db(GameManager.master_volume))


func _save_test() -> void:
	var config = ConfigFile.new()
	config.set_value("audio", "master_volume", int(GameManager.master_volume * 100))
	config.set_value("audio", "music_volume", int(GameManager.music_volume * 100))
	config.set_value("audio", "sfx_volume", int(GameManager.sfx_volume * 100))
	config.set_value("accessibility", "screen_shake", GameManager.screen_shake_enabled)
	config.set_value("accessibility", "camera_smoothing", GameManager.camera_smoothing_speed)
	config.save("user://settings.cfg")
