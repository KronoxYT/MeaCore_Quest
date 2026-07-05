extends Node

var pool_size: int = 8
var players: Array[AudioStreamPlayer] = []
var current_player_idx: int = 0
var master_volume: float = 1.0

var sfx_streams: Dictionary = {}

func _ready():
	for i in range(pool_size):
		var p = AudioStreamPlayer.new()
		add_child(p)
		players.append(p)

	sfx_streams["hit"] = _generate_hit_sfx()
	sfx_streams["heal"] = _generate_heal_sfx()
	sfx_streams["mana"] = _generate_mana_sfx()
	sfx_streams["level_up"] = _generate_levelup_sfx()
	sfx_streams["quest_complete"] = _generate_quest_sfx()
	sfx_streams["equip"] = _generate_equip_sfx()
	sfx_streams["spell"] = _generate_spell_sfx()

func set_volume(v: float):
	master_volume = clamp(v, 0.0, 1.0)
	for p in players:
		p.volume_db = linear_to_db(master_volume)

func play_sfx(sfx_name: String, pitch_scale: float = 1.0):
	if not sfx_streams.has(sfx_name):
		return

	var player = players[current_player_idx]
	for p in players:
		if not p.playing:
			player = p
			break

	player.stream = sfx_streams[sfx_name]
	player.pitch_scale = pitch_scale
	player.volume_db = linear_to_db(master_volume)
	player.play()

	current_player_idx = (current_player_idx + 1) % pool_size

# Waveform Generation Helper
func _create_stream(data: PackedByteArray, mix_rate: int) -> AudioStreamWAV:
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_8_BITS
	stream.mix_rate = mix_rate
	stream.stereo = false
	stream.data = data
	return stream

# SFX 1: HIT (Downward sweep, triangle-like square wave)
func _generate_hit_sfx() -> AudioStreamWAV:
	var mix_rate = 22050
	var duration = 0.12
	var num_samples = int(mix_rate * duration)
	var data = PackedByteArray()
	
	for i in range(num_samples):
		var t = float(i) / mix_rate
		var progress = float(i) / num_samples
		# Frequency sweeps from 250Hz down to 60Hz
		var freq = 250.0 - (190.0 * progress)
		# Square/triangle hybrid wave
		var phase = int(t * freq * 256) % 256
		var val = 60 if phase < 128 else -60
		# Apply exponential decay volume envelope
		var env = exp(-progress * 5.0)
		var sample = int(val * env)
		data.append(sample)
		
	return _create_stream(data, mix_rate)

# SFX 2: HEAL (Upward sweep with vibrato, smooth sine wave)
func _generate_heal_sfx() -> AudioStreamWAV:
	var mix_rate = 22050
	var duration = 0.35
	var num_samples = int(mix_rate * duration)
	var data = PackedByteArray()
	
	for i in range(num_samples):
		var t = float(i) / mix_rate
		var progress = float(i) / num_samples
		# Sweep from 300Hz up to 900Hz with vibrato
		var vibrato = sin(2.0 * PI * 15.0 * t) * 40.0
		var freq = 300.0 + (600.0 * progress) + vibrato
		var val = sin(2.0 * PI * freq * t) * 80.0
		# Fade in and fade out envelope
		var env = sin(PI * progress)
		var sample = int(val * env)
		data.append(sample)
		
	return _create_stream(data, mix_rate)

# SFX 3: MANA (Shimmering upward sweep, square wave)
func _generate_mana_sfx() -> AudioStreamWAV:
	var mix_rate = 22050
	var duration = 0.3
	var num_samples = int(mix_rate * duration)
	var data = PackedByteArray()
	
	for i in range(num_samples):
		var t = float(i) / mix_rate
		var progress = float(i) / num_samples
		# Sweep from 600Hz to 1300Hz, fast tremolo
		var tremolo = 0.6 + 0.4 * sin(2.0 * PI * 30.0 * t)
		var freq = 600.0 + (700.0 * progress)
		var phase = int(t * freq * 256) % 256
		var val = 50 if phase < 128 else -50
		var env = (1.0 - progress) * tremolo
		var sample = int(val * env)
		data.append(sample)
		
	return _create_stream(data, mix_rate)

# SFX 4: LEVEL UP (Rising 8-bit arpeggio: C4, E4, G4, C5)
func _generate_levelup_sfx() -> AudioStreamWAV:
	var mix_rate = 22050
	var notes = [261.63, 329.63, 392.00, 523.25] # C4, E4, G4, C5
	var note_duration = 0.12
	var samples_per_note = int(mix_rate * note_duration)
	var data = PackedByteArray()
	
	for n_idx in range(notes.size()):
		var freq = notes[n_idx]
		for i in range(samples_per_note):
			var t = float(i) / mix_rate
			var progress = float(i) / samples_per_note
			var phase = int(t * freq * 256) % 256
			var val = 60 if phase < 128 else -60
			# Note decay
			var env = 1.0 - (progress * 0.4)
			var sample = int(val * env)
			data.append(sample)
			
	return _create_stream(data, mix_rate)

# SFX 5: QUEST COMPLETE (Triumphant chord arpeggio: F4, A4, C5, F5)
func _generate_quest_sfx() -> AudioStreamWAV:
	var mix_rate = 22050
	var notes = [349.23, 440.00, 523.25, 698.46] # F4, A4, C5, F5
	var note_duration = 0.15
	var samples_per_note = int(mix_rate * note_duration)
	var data = PackedByteArray()
	
	for n_idx in range(notes.size()):
		var freq = notes[n_idx]
		# For the last note, make it longer
		var duration_mult = 2 if n_idx == notes.size() - 1 else 1
		for i in range(samples_per_note * duration_mult):
			var t = float(i) / mix_rate
			var progress = float(i) / (samples_per_note * duration_mult)
			var phase = int(t * freq * 256) % 256
			var val = 60 if phase < 128 else -60
			var env = 1.0 - progress
			var sample = int(val * env)
			data.append(sample)
			
	return _create_stream(data, mix_rate)

# SFX 6: EQUIP (Short retro friction click)
func _generate_equip_sfx() -> AudioStreamWAV:
	var mix_rate = 22050
	var duration = 0.06
	var num_samples = int(mix_rate * duration)
	var data = PackedByteArray()
	
	for i in range(num_samples):
		var progress = float(i) / num_samples
		# White-noise like random values
		var val = randi_range(-60, 60)
		var env = exp(-progress * 8.0)
		var sample = int(val * env)
		data.append(sample)
		
	return _create_stream(data, mix_rate)

# SFX 7: SPELL SHOOT (High-pitch frequency drop, whoosh)
func _generate_spell_sfx() -> AudioStreamWAV:
	var mix_rate = 22050
	var duration = 0.18
	var num_samples = int(mix_rate * duration)
	var data = PackedByteArray()
	
	for i in range(num_samples):
		var t = float(i) / mix_rate
		var progress = float(i) / num_samples
		# Frequency sweeps from 900Hz down to 200Hz
		var freq = 900.0 - (700.0 * progress)
		var val = sin(2.0 * PI * freq * t) * 70.0
		var env = (1.0 - progress)
		var sample = int(val * env)
		data.append(sample)
		
	return _create_stream(data, mix_rate)
