extends Node

## ════════════════════════════════════════════════════════════════
## AUDIO MANAGER — NK-7
## ════════════════════════════════════════════════════════════════
## Genera sonidos procedurales con AudioStreamGenerator.
## No requiere archivos .ogg/.wav externos.
## Todos los sonidos se sintetizan en tiempo real.
##
## USO:
##   AudioManager.play_sfx("jump")
##   AudioManager.play_sfx("coin")
##   AudioManager.play_music("level_01")
## ════════════════════════════════════════════════════════════════

# ── Buses ─────────────────────────────────────────────────────────
const BUS_MUSIC := "Music"
const BUS_SFX   := "SFX"

# ── Pool de reproductores SFX ─────────────────────────────────────
const SFX_POOL_SIZE := 8
var _sfx_pool : Array[AudioStreamPlayer] = []
var _sfx_pool_idx : int = 0

# ── Reproductor de música ─────────────────────────────────────────
var _music_player : AudioStreamPlayer = null
var _current_track : String = ""

# ── Catálogo de sonidos (parámetros de síntesis) ──────────────────
# Cada entrada: { "type": "...", ...parámetros }
const SFX_CATALOG := {
	# ── Jugador ──────────────────────────────────────────────────
	"jump":        { "type": "tone",  "freq": 320.0, "freq2": 520.0, "dur": 0.12, "vol": 0.55, "env": "exp" },
	"land":        { "type": "noise", "freq": 80.0,  "dur": 0.08,  "vol": 0.45, "env": "exp" },
	"run_step":    { "type": "noise", "freq": 120.0, "dur": 0.06,  "vol": 0.25, "env": "exp" },
	"walk_step":   { "type": "noise", "freq": 100.0, "dur": 0.07,  "vol": 0.20, "env": "exp" },
	"hurt":        { "type": "tone",  "freq": 180.0, "freq2": 90.0, "dur": 0.22, "vol": 0.70, "env": "exp" },
	"die":         { "type": "tone",  "freq": 220.0, "freq2": 55.0, "dur": 0.60, "vol": 0.80, "env": "exp" },
	"crouch":      { "type": "noise", "freq": 90.0,  "dur": 0.05,  "vol": 0.18, "env": "exp" },
	"climb":       { "type": "noise", "freq": 110.0, "dur": 0.06,  "vol": 0.15, "env": "exp" },
	# ── Acciones ─────────────────────────────────────────────────
	"hack":        { "type": "beep",  "freq": 880.0, "freq2": 1320.0, "dur": 0.18, "vol": 0.50, "env": "lin" },
	"use_tool":    { "type": "noise", "freq": 200.0, "dur": 0.14,  "vol": 0.40, "env": "exp" },
	"interact":    { "type": "beep",  "freq": 660.0, "freq2": 880.0,  "dur": 0.10, "vol": 0.45, "env": "lin" },
	"attack":      { "type": "noise", "freq": 300.0, "dur": 0.10,  "vol": 0.55, "env": "exp" },
	# ── Coleccionables ───────────────────────────────────────────
	"coin":        { "type": "beep",  "freq": 1047.0, "freq2": 1568.0, "dur": 0.14, "vol": 0.55, "env": "lin" },
	"cube":        { "type": "beep",  "freq": 784.0,  "freq2": 1047.0, "dur": 0.18, "vol": 0.50, "env": "lin" },
	"energy":      { "type": "beep",  "freq": 523.0,  "freq2": 1047.0, "dur": 0.22, "vol": 0.55, "env": "lin" },
	"keycard":     { "type": "beep",  "freq": 880.0,  "freq2": 1760.0, "dur": 0.25, "vol": 0.60, "env": "lin" },
	# ── Puertas / Interruptores ───────────────────────────────────
	"door_open":   { "type": "tone",  "freq": 220.0, "freq2": 440.0, "dur": 0.30, "vol": 0.55, "env": "lin" },
	"door_locked": { "type": "tone",  "freq": 110.0, "freq2": 90.0,  "dur": 0.20, "vol": 0.50, "env": "exp" },
	"switch_on":   { "type": "beep",  "freq": 660.0, "freq2": 880.0, "dur": 0.12, "vol": 0.45, "env": "lin" },
	"repair":      { "type": "noise", "freq": 180.0, "dur": 0.20,   "vol": 0.40, "env": "exp" },
	# ── Ukibuki ──────────────────────────────────────────────────
	"ukibuki_alert":   { "type": "tone",  "freq": 440.0, "freq2": 660.0, "dur": 0.25, "vol": 0.65, "env": "lin" },
	"ukibuki_shoot":   { "type": "beep",  "freq": 330.0, "freq2": 165.0, "dur": 0.15, "vol": 0.60, "env": "exp" },
	"ukibuki_damage":  { "type": "noise", "freq": 250.0, "dur": 0.12,   "vol": 0.55, "env": "exp" },
	"ukibuki_destroy": { "type": "noise", "freq": 120.0, "dur": 0.55,   "vol": 0.80, "env": "exp" },
	# ── Proyectil ────────────────────────────────────────────────
	"projectile_hit":  { "type": "noise", "freq": 200.0, "dur": 0.08, "vol": 0.50, "env": "exp" },
	# ── Dash / Dodge ─────────────────────────────────────────────
	"dash":            { "type": "tone",  "freq": 600.0, "freq2": 900.0, "dur": 0.10, "vol": 0.50, "env": "exp" },
	"dodge":           { "type": "noise", "freq": 150.0, "dur": 0.08,   "vol": 0.35, "env": "exp" },
	# ── Combo ────────────────────────────────────────────────────
	"combo_hit_1":     { "type": "noise", "freq": 280.0, "dur": 0.08, "vol": 0.50, "env": "exp" },
	"combo_hit_2":     { "type": "noise", "freq": 320.0, "dur": 0.09, "vol": 0.55, "env": "exp" },
	"combo_finisher":  { "type": "tone",  "freq": 200.0, "freq2": 80.0, "dur": 0.20, "vol": 0.75, "env": "exp" },
	"combo_break":     { "type": "tone",  "freq": 300.0, "freq2": 150.0, "dur": 0.15, "vol": 0.40, "env": "exp" },
	# ── Guardia ──────────────────────────────────────────────────
	"guardia_shield":  { "type": "beep",  "freq": 500.0, "freq2": 800.0, "dur": 0.20, "vol": 0.60, "env": "lin" },
	"guardia_rush":    { "type": "noise", "freq": 200.0, "dur": 0.12,   "vol": 0.55, "env": "exp" },
	"berserk":         { "type": "tone",  "freq": 180.0, "freq2": 90.0,  "dur": 0.40, "vol": 0.80, "env": "exp" },
	# ── UI ───────────────────────────────────────────────────────
	"ui_confirm":  { "type": "beep",  "freq": 880.0,  "freq2": 1320.0, "dur": 0.12, "vol": 0.45, "env": "lin" },
	"ui_cancel":   { "type": "tone",  "freq": 330.0,  "freq2": 220.0,  "dur": 0.12, "vol": 0.40, "env": "exp" },
	"ui_hover":    { "type": "beep",  "freq": 660.0,  "freq2": 770.0,  "dur": 0.06, "vol": 0.25, "env": "lin" },
	"checkpoint":  { "type": "beep",  "freq": 523.0,  "freq2": 784.0,  "dur": 0.30, "vol": 0.60, "env": "lin" },
	"level_clear": { "type": "beep",  "freq": 523.0,  "freq2": 1047.0, "dur": 0.50, "vol": 0.70, "env": "lin" },
	"achievement": { "type": "beep",  "freq": 784.0,  "freq2": 1568.0, "dur": 0.40, "vol": 0.65, "env": "lin" },
}

# ── Música procedural por nivel ───────────────────────────────────
const MUSIC_CATALOG := {
	"menu":    { "bpm": 80,  "key": 220.0,  "style": "ambient" },
	"level_01": { "bpm": 100, "key": 261.63, "style": "tense"   },
	"level_02": { "bpm": 110, "key": 293.66, "style": "tense"   },
	"level_03": { "bpm": 115, "key": 261.63, "style": "danger"  },
	"level_04": { "bpm": 120, "key": 246.94, "style": "danger"  },
	"level_05": { "bpm": 130, "key": 220.0,  "style": "boss"    },
}

# ── Tween de música ───────────────────────────────────────────────
var _music_tween : Tween = null

# ══════════════════════════════════════════════════════════════════
# INICIALIZACIÓN
# ══════════════════════════════════════════════════════════════════

func _ready() -> void:
	_build_sfx_pool()
	_build_music_player()

func _build_sfx_pool() -> void:
	for i in range(SFX_POOL_SIZE):
		var p := AudioStreamPlayer.new()
		p.bus = BUS_SFX
		p.volume_db = 0.0
		add_child(p)
		_sfx_pool.append(p)

func _build_music_player() -> void:
	_music_player = AudioStreamPlayer.new()
	_music_player.bus = BUS_MUSIC
	_music_player.volume_db = -6.0
	add_child(_music_player)

# ══════════════════════════════════════════════════════════════════
# API PÚBLICA — SFX
# ══════════════════════════════════════════════════════════════════

func play_sfx(sfx_name: String, pitch_variation: float = 0.0) -> void:
	"""Reproducir efecto de sonido por nombre"""
	if not SFX_CATALOG.has(sfx_name):
		push_warning("[AudioManager] SFX desconocido: %s" % sfx_name)
		return
	
	var params : Dictionary = SFX_CATALOG[sfx_name]
	var stream := _synthesize(params)
	if not stream:
		return
	
	var player := _get_sfx_player()
	player.stream = stream
	player.pitch_scale = 1.0 + pitch_variation
	player.play()

func play_sfx_at(sfx_name: String, position: Vector2, pitch_variation: float = 0.0) -> void:
	"""Reproducir SFX posicional (usa AudioStreamPlayer2D temporal)"""
	if not SFX_CATALOG.has(sfx_name):
		return
	
	var params : Dictionary = SFX_CATALOG[sfx_name]
	var stream := _synthesize(params)
	if not stream:
		return
	
	var p2d := AudioStreamPlayer2D.new()
	p2d.bus = BUS_SFX
	p2d.stream = stream
	p2d.pitch_scale = 1.0 + pitch_variation
	p2d.global_position = position
	p2d.max_distance = 800.0
	get_tree().root.add_child(p2d)
	p2d.play()
	p2d.finished.connect(p2d.queue_free)

# ══════════════════════════════════════════════════════════════════
# API PÚBLICA — MÚSICA
# ══════════════════════════════════════════════════════════════════

func play_music(track_name: String, fade_in: float = 1.5) -> void:
	"""Reproducir pista de música con fade in"""
	if _current_track == track_name:
		return
	
	if _music_player.playing:
		_fade_out_music(func(): _start_music(track_name, fade_in))
	else:
		_start_music(track_name, fade_in)

func stop_music(_fade_out: float = 1.0) -> void:
	"""Detener música con fade out"""
	_fade_out_music(func(): pass)

func _start_music(track_name: String, fade_in: float) -> void:
	if not MUSIC_CATALOG.has(track_name):
		return
	
	_current_track = track_name
	var params : Dictionary = MUSIC_CATALOG[track_name]
	var stream := _synthesize_music(params)
	if not stream:
		return
	
	_music_player.stream = stream
	_music_player.volume_db = -80.0
	_music_player.play()
	
	if _music_tween:
		_music_tween.kill()
	_music_tween = create_tween()
	_music_tween.tween_property(_music_player, "volume_db", -6.0, fade_in)

func _fade_out_music(callback: Callable) -> void:
	if _music_tween:
		_music_tween.kill()
	_music_tween = create_tween()
	_music_tween.tween_property(_music_player, "volume_db", -80.0, 0.8)
	_music_tween.tween_callback(func():
		_music_player.stop()
		_current_track = ""
		callback.call()
	)

# ══════════════════════════════════════════════════════════════════
# SÍNTESIS DE AUDIO
# ══════════════════════════════════════════════════════════════════

func _get_sfx_player() -> AudioStreamPlayer:
	"""Obtener el siguiente reproductor disponible del pool"""
	var player := _sfx_pool[_sfx_pool_idx]
	_sfx_pool_idx = (_sfx_pool_idx + 1) % SFX_POOL_SIZE
	if player.playing:
		player.stop()
	return player

func _synthesize(params: Dictionary) -> AudioStreamWAV:
	"""Sintetizar un sonido según los parámetros"""
	var type : String = params.get("type", "tone")
	var dur  : float  = params.get("dur",  0.1)
	var vol  : float  = params.get("vol",  0.5)
	var env  : String = params.get("env",  "exp")
	var freq : float  = params.get("freq", 440.0)
	var freq2: float  = params.get("freq2", freq)
	
	match type:
		"tone":  return _gen_tone(freq, freq2, dur, vol, env)
		"beep":  return _gen_beep(freq, freq2, dur, vol, env)
		"noise": return _gen_noise(freq, dur, vol, env)
	
	return null

func _gen_tone(freq_start: float, freq_end: float, dur: float,
		vol: float, env: String) -> AudioStreamWAV:
	"""Tono con sweep de frecuencia (para saltos, daño, etc.)"""
	const SAMPLE_RATE := 22050
	var num_samples := int(SAMPLE_RATE * dur)
	var data := PackedByteArray()
	data.resize(num_samples * 2)
	
	var phase := 0.0
	for i in range(num_samples):
		var t : float = float(i) / float(num_samples)
		var freq : float = lerp(freq_start, freq_end, t)
		phase += freq / float(SAMPLE_RATE)
		var sample : float = sin(phase * TAU)
		var envelope : float = _envelope(t, env)
		var value := int(sample * envelope * vol * 32767.0)
		value = clampi(value, -32768, 32767)
		data[i * 2]     = value & 0xFF
		data[i * 2 + 1] = (value >> 8) & 0xFF
	
	return _make_wav(data, SAMPLE_RATE)

func _gen_beep(freq_a: float, freq_b: float, dur: float,
		vol: float, env: String) -> AudioStreamWAV:
	"""Dos tonos en secuencia (para UI, coleccionables)"""
	const SAMPLE_RATE := 22050
	var num_samples := int(SAMPLE_RATE * dur)
	var half : int = int(num_samples * 0.5)
	var data := PackedByteArray()
	data.resize(num_samples * 2)
	
	var phase := 0.0
	for i in range(num_samples):
		var t : float = float(i) / float(num_samples)
		var freq : float = freq_a if i < half else freq_b
		phase += freq / float(SAMPLE_RATE)
		var sample : float = sin(phase * TAU)
		var envelope : float = _envelope(t, env)
		var value := int(sample * envelope * vol * 32767.0)
		value = clampi(value, -32768, 32767)
		data[i * 2]     = value & 0xFF
		data[i * 2 + 1] = (value >> 8) & 0xFF
	
	return _make_wav(data, SAMPLE_RATE)

func _gen_noise(cutoff: float, dur: float, vol: float, env: String) -> AudioStreamWAV:
	"""Ruido filtrado (para pasos, explosiones, impactos)"""
	const SAMPLE_RATE := 22050
	var num_samples := int(SAMPLE_RATE * dur)
	var data := PackedByteArray()
	data.resize(num_samples * 2)
	
	# Filtro paso-bajo simple (media móvil)
	var alpha := clampf(cutoff / float(SAMPLE_RATE) * 2.0, 0.01, 0.99)
	var prev := 0.0
	
	for i in range(num_samples):
		var t : float = float(i) / float(num_samples)
		var raw : float = randf_range(-1.0, 1.0)
		prev = lerp(prev, raw, alpha)
		var envelope : float = _envelope(t, env)
		var value := int(prev * envelope * vol * 32767.0)
		value = clampi(value, -32768, 32767)
		data[i * 2]     = value & 0xFF
		data[i * 2 + 1] = (value >> 8) & 0xFF
	
	return _make_wav(data, SAMPLE_RATE)

func _synthesize_music(params: Dictionary) -> AudioStreamWAV:
	"""Sintetizar un loop de música ambiental procedural"""
	const SAMPLE_RATE := 22050
	var bpm   : float = params.get("bpm",   100.0)
	var key   : float = params.get("key",   261.63)
	var style : String = params.get("style", "tense")
	
	# 4 compases de 4/4
	var beat_dur := 60.0 / bpm
	var total_dur := beat_dur * 16.0
	var num_samples := int(SAMPLE_RATE * total_dur)
	var data := PackedByteArray()
	data.resize(num_samples * 2)
	
	# Escala menor para tensión
	var scale_intervals : Array[int] = [0, 2, 3, 5, 7, 8, 10]  # menor natural
	
	for i in range(num_samples):
		var t : float = float(i) / float(SAMPLE_RATE)
		var beat_pos : float = fmod(t / beat_dur, 4.0)
		var bar_pos  : float = fmod(t / (beat_dur * 4.0), 4.0)
		
		var sample : float = 0.0
		
		# Bajo pulsante en tiempos 1 y 3
		if beat_pos < 0.05:
			var bass_freq : float = key * 0.5
			sample += sin(t * bass_freq * TAU) * 0.3 * exp(-beat_pos * 40.0)
		
		# Pad ambiental (acorde)
		var chord_note : int = scale_intervals[int(bar_pos) % scale_intervals.size()]
		var chord_freq := key * pow(2.0, chord_note / 12.0)
		sample += sin(t * chord_freq * TAU) * 0.15
		sample += sin(t * chord_freq * 2.0 * TAU) * 0.08
		
		# Arpeggio en corcheas
		var eighth_pos : float = fmod(t / (beat_dur * 0.5), 1.0)
		var arp_idx : int = int(t / (beat_dur * 0.5)) % scale_intervals.size()
		var arp_note : int = scale_intervals[arp_idx]
		var arp_freq := key * pow(2.0, arp_note / 12.0)
		if style == "boss":
			arp_freq *= 2.0
		sample += sin(t * arp_freq * TAU) * 0.10 * exp(-eighth_pos * 8.0)
		
		# Limitar
		sample = clampf(sample, -1.0, 1.0)
		var value := int(sample * 28000.0)
		value = clampi(value, -32768, 32767)
		data[i * 2]     = value & 0xFF
		data[i * 2 + 1] = (value >> 8) & 0xFF
	
	var wav := _make_wav(data, SAMPLE_RATE)
	wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
	wav.loop_begin = 0
	wav.loop_end = num_samples
	return wav

func _envelope(t: float, env_type: String) -> float:
	"""Calcular envolvente ADSR simplificada"""
	match env_type:
		"exp":
			# Ataque rápido, decaimiento exponencial
			if t < 0.05:
				return t / 0.05
			return exp(-(t - 0.05) * 8.0)
		"lin":
			# Ataque rápido, decaimiento lineal
			if t < 0.05:
				return t / 0.05
			return 1.0 - ((t - 0.05) / 0.95)
		_:
			return 1.0 - t

func _make_wav(data: PackedByteArray, sample_rate: int) -> AudioStreamWAV:
	"""Crear AudioStreamWAV desde datos PCM 16-bit mono"""
	var wav := AudioStreamWAV.new()
	wav.data = data
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = sample_rate
	wav.stereo = false
	return wav

# ══════════════════════════════════════════════════════════════════
# UTILIDADES
# ══════════════════════════════════════════════════════════════════

func set_sfx_volume(linear: float) -> void:
	var idx := AudioServer.get_bus_index(BUS_SFX)
	if idx >= 0:
		AudioServer.set_bus_volume_db(idx, linear_to_db(linear))

func set_music_volume(linear: float) -> void:
	var idx := AudioServer.get_bus_index(BUS_MUSIC)
	if idx >= 0:
		AudioServer.set_bus_volume_db(idx, linear_to_db(linear))
