extends Node

# Script de prueba para verificar que LevelStateManager funciona

func _ready() -> void:
	print("=== TEST AUTOLOAD ===")
	
	# Verificar que LevelStateManager existe
	if LevelStateManager:
		print("✅ LevelStateManager está disponible")
		print("✅ Estado actual:", LevelStateManager.current_level_state)
	else:
		print("❌ LevelStateManager NO está disponible")
	
	# Verificar GameManager
	if GameManager:
		print("✅ GameManager está disponible")
	else:
		print("❌ GameManager NO está disponible")
	
	print("=== FIN TEST ===")
