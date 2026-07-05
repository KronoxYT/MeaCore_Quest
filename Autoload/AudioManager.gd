extends Node

const MUSIC_BUS := "Music"
const SFX_BUS := "SFX"

var music_player: AudioStreamPlayer
var sfx_players: Array[AudioStreamPlayer] = []
var max_sfx_players: int = 8

var music_volume: float = 1.0:
    set(value):
        music_volume = clampf(value, 0.0, 1.0)
        _update_bus_volume(MUSIC_BUS, music_volume)
var sfx_volume: float = 1.0:
    set(value):
        sfx_volume = clampf(value, 0.0, 1.0)
        _update_bus_volume(SFX_BUS, sfx_volume)
var master_volume: float = 1.0:
    set(value):
        master_volume = clampf(value, 0.0, 1.0)
        _update_bus_volume("Master", master_volume)


func _ready() -> void:
    process_mode = PROCESS_MODE_ALWAYS
    _setup_buses()
    _create_music_player()
    _create_sfx_pool()


func _setup_buses() -> void:
    for bus_name in ["Master", MUSIC_BUS, SFX_BUS]:
        if AudioServer.get_bus_index(bus_name) == -1:
            var idx := AudioServer.bus_count
            AudioServer.add_bus(idx)
            AudioServer.set_bus_name(idx, bus_name)


func _create_music_player() -> void:
    music_player = AudioStreamPlayer.new()
    music_player.bus = MUSIC_BUS
    music_player.name = "MusicPlayer"
    add_child(music_player)


func _create_sfx_pool() -> void:
    for i in max_sfx_players:
        var player := AudioStreamPlayer.new()
        player.bus = SFX_BUS
        player.name = "SFXPlayer_%d" % i
        add_child(player)
        sfx_players.append(player)


func _update_bus_volume(bus_name: String, vol: float) -> void:
    var idx := AudioServer.get_bus_index(bus_name)
    if idx >= 0:
        AudioServer.set_bus_volume_db(idx, linear_to_db(vol))


func play_music(stream: AudioStream, fade_time: float = 0.5) -> void:
    if music_player.stream == stream:
        return
    var tween := create_tween()
    tween.tween_property(music_player, "volume_db", -80.0, fade_time)
    tween.tween_callback(_switch_music.bind(stream))
    tween.tween_property(music_player, "volume_db", linear_to_db(music_volume), fade_time)


func _switch_music(stream: AudioStream) -> void:
    music_player.stop()
    music_player.stream = stream
    music_player.play()


func stop_music(fade_time: float = 0.5) -> void:
    var tween := create_tween()
    tween.tween_property(music_player, "volume_db", -80.0, fade_time)
    tween.tween_callback(music_player.stop)


func play_sfx(stream: AudioStream) -> void:
    var player := _get_available_sfx_player()
    if not player:
        return
    player.stream = stream
    player.play()


func _get_available_sfx_player() -> AudioStreamPlayer:
    for player in sfx_players:
        if not player.playing:
            return player
    return sfx_players[0]
