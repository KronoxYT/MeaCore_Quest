extends Node

enum MusicState {
    EXPLORATION,
    COMBAT,
    BOSS,
    CITY,
    DUNGEON,
    MENU,
    VICTORY,
    DEATH
}

const STEM_PATHS: Dictionary = {
    MusicState.EXPLORATION: {
        "base": "res://Assets/Audio/Music/exploration_base.ogg"
    },
    MusicState.COMBAT: {
        "base": "res://Assets/Audio/Music/combat_base.ogg"
    },
    MusicState.BOSS: {
        "base": "res://Assets/Audio/Music/boss_base.ogg"
    },
    MusicState.CITY: {
        "base": "res://Assets/Audio/Music/city_base.ogg"
    },
    MusicState.DUNGEON: {
        "base": "res://Assets/Audio/Music/dungeon_base.ogg"
    },
    MusicState.MENU: {
        "base": "res://Assets/Audio/Music/menu_base.ogg"
    },
    MusicState.VICTORY: {
        "base": "res://Assets/Audio/Music/victory_fanfare.ogg"
    },
    MusicState.DEATH: {
        "base": "res://Assets/Audio/Music/death_theme.ogg"
    }
}

var _current_state: MusicState = MusicState.EXPLORATION
var _previous_state: MusicState = MusicState.EXPLORATION
var _current_player: AudioStreamPlayer
var _crossfade_tween: Tween
var _combat_timer: float = 0.0
var _combat_cooldown: float = 15.0
var _in_combat: bool = false
var _volume_db: float = 0.0

func _ready():
    _current_player = AudioStreamPlayer.new()
    _current_player.name = "MusicPlayer"
    _current_player.volume_db = _volume_db
    add_child(_current_player)
    _play_state(_current_state)

func _process(delta: float):
    if _in_combat:
        _combat_timer -= delta
        if _combat_timer <= 0.0:
            _in_combat = false
            if _current_state == MusicState.COMBAT:
                transition_to(MusicState.EXPLORATION)

func transition_to(state: MusicState):
    _previous_state = _current_state
    _current_state = state
    if not STEM_PATHS.has(state):
        return
    _crossfade_to_state(state)

func _crossfade_to_state(state: MusicState):
    var stems = STEM_PATHS[state]
    if not stems.has("base"):
        return
    var path = stems["base"]
    var new_player = AudioStreamPlayer.new()
    new_player.name = "MusicPlayer_New"
    new_player.volume_db = -80.0
    add_child(new_player)
    var stream = load(path) if ResourceLoader.exists(path) else null
    if stream:
        new_player.stream = stream
        new_player.play()
    if _crossfade_tween and _crossfade_tween.is_valid():
        _crossfade_tween.kill()
    _crossfade_tween = create_tween()
    _crossfade_tween.set_parallel(true)
    _crossfade_tween.tween_property(_current_player, "volume_db", -80.0, 2.0).set_ease(Tween.EASE_IN)
    _crossfade_tween.tween_property(new_player, "volume_db", _volume_db, 2.0).set_ease(Tween.EASE_OUT)
    _crossfade_tween.tween_callback(Callable(self, "_swap_player").bind(new_player))

func _swap_player(new_player: AudioStreamPlayer):
    _current_player.queue_free()
    _current_player = new_player
    _current_player.name = "MusicPlayer"

func _play_state(state: MusicState):
    var stems = STEM_PATHS.get(state, {})
    if not stems.has("base"):
        return
    var path = stems["base"]
    var stream = load(path) if ResourceLoader.exists(path) else null
    if stream and _current_player:
        _current_player.stream = stream
        _current_player.play()

func notify_combat():
    _in_combat = true
    _combat_timer = _combat_cooldown
    if _current_state != MusicState.COMBAT:
        transition_to(MusicState.COMBAT)

func notify_boss():
    transition_to(MusicState.BOSS)

func notify_victory():
    transition_to(MusicState.VICTORY)

func notify_death():
    transition_to(MusicState.DEATH)

func notify_city():
    transition_to(MusicState.CITY)

func notify_dungeon():
    transition_to(MusicState.DUNGEON)

func notify_menu():
    transition_to(MusicState.MENU)

func set_volume(db: float):
    _volume_db = db
    if _current_player:
        _current_player.volume_db = db

func get_current_state() -> MusicState:
    return _current_state
