extends Node

enum GameState { MENU, PLAYING, PAUSED, INVENTORY, DIALOGUE, GAME_OVER, VICTORY }

var current_state: GameState = GameState.MENU
var player: Node2D
var current_level: String = ""
var difficulty_multiplier: float = 1.0

signal game_state_changed(new_state: GameState)
signal level_loaded(level_name: String)
signal game_over()
signal victory()


var auto_connect_to_server: bool = false
var auto_start_server: bool = false


func _ready() -> void:
    process_mode = PROCESS_MODE_ALWAYS
    _parse_cmd_args()


func _parse_cmd_args() -> void:
    var args = OS.get_cmdline_args()
    if "--server" in args:
        auto_start_server = true
        var NM = get_node("/root/NetworkManager")
        if NM:
            NM.start_server(8910, 100)
            load_level("res://Scenes/World/WorldMap.tscn")
    elif "--client" in args:
        auto_connect_to_server = true
        var NM = get_node("/root/NetworkManager")
        if NM:
            NM.connect_to_server("127.0.0.1", 8910)


func change_state(new_state: GameState) -> void:
    current_state = new_state
    game_state_changed.emit(new_state)
    match new_state:
        GameState.PLAYING:
            Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
        GameState.PAUSED, GameState.MENU:
            Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
        GameState.GAME_OVER:
            game_over.emit()
        GameState.VICTORY:
            victory.emit()


func load_level(level_path: String) -> void:
    var prev_level = current_level
    current_level = level_path
    var result := get_tree().change_scene_to_file(level_path)
    if result != OK:
        push_error("Error al cargar nivel: ", level_path)
        current_level = prev_level
        return
    level_loaded.emit(level_path)
    change_state(GameState.PLAYING)


func register_player(p: Node2D) -> void:
    player = p


func set_player(p: Node2D) -> void:
    register_player(p)


func is_playing() -> bool:
    return current_state == GameState.PLAYING


func quit_game() -> void:
    get_tree().quit()
