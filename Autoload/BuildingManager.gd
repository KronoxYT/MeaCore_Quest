extends Node

@warning_ignore("unused_signal")
signal build_started(structure_id: String)
signal build_completed(structure_id: String, position: Vector2)
signal build_failed(structure_id: String, reason: String)
signal territory_claimed(owner_id: String, bounds: Rect2)

const TILE_SIZE: Vector2i = Vector2i(64, 64)
const CLAIM_PLOT_SIZE: Vector2i = Vector2i(20, 20)

var is_in_building_mode: bool = false
var current_ghost = null
var current_rotation: int = 0
var current_structure = null

var claimed_territories: Dictionary = {}


func _ready():
    process_mode = PROCESS_MODE_ALWAYS


func _unhandled_input(event: InputEvent) -> void:
    if not is_in_building_mode:
        if event.is_action_pressed("toggle_building"):
            _toggle_building_mode()
        return
    if event.is_action_pressed("rotate_structure"):
        _rotate_structure()
    elif event.is_action_pressed("cancel_action") or event.is_action_pressed("toggle_building"):
        _exit_building_mode()
    elif event is InputEventMouseButton and event.pressed:
        if event.button_index == MOUSE_BUTTON_LEFT:
            _try_place_structure()
        elif event.button_index == MOUSE_BUTTON_RIGHT:
            _exit_building_mode()
    if event is InputEventMouseMotion and current_ghost:
        _update_ghost_position()


func enter_building_mode(structure) -> void:
    current_structure = structure
    current_rotation = 0
    is_in_building_mode = true
    _create_ghost_structure()
    var EM = get_node("/root/EventManager")
    if EM:
        EM.notification_shown.emit("Modo construcción: %s" % structure.display_name, "info")


func _exit_building_mode() -> void:
    is_in_building_mode = false
    current_structure = null
    if current_ghost and is_instance_valid(current_ghost):
        current_ghost.queue_free()
    current_ghost = null


func _create_ghost_structure() -> void:
    if not current_structure or not current_structure.scene:
        return
    if current_ghost:
        current_ghost.queue_free()
    current_ghost = current_structure.scene.instantiate()
    current_ghost.modulate = Color(0.5, 0.5, 0.5, 0.7)
    get_tree().current_scene.add_child(current_ghost)


func _rotate_structure() -> void:
    current_rotation = (current_rotation + 90) % 360
    if current_ghost and current_structure.can_rotate:
        current_ghost.rotation_degrees = current_rotation


func _update_ghost_position() -> void:
    if not current_ghost:
        return
    var world_pos = get_viewport().get_camera_2d().get_global_mouse_position()
    var grid_x = int(world_pos.x / TILE_SIZE.x) * TILE_SIZE.x
    var grid_y = int(world_pos.y / TILE_SIZE.y) * TILE_SIZE.y
    current_ghost.global_position = Vector2(grid_x, grid_y)
    var can_place = _can_place_at(Vector2(grid_x, grid_y))
    current_ghost.modulate = Color(0.5, 1.0, 0.5, 0.7) if can_place else Color(1.0, 0.5, 0.5, 0.7)


func _try_place_structure() -> void:
    if not current_ghost or not current_structure:
        return
    var pos = current_ghost.global_position
    var grid_pos = Vector2(int(pos.x / TILE_SIZE.x) * TILE_SIZE.x, int(pos.y / TILE_SIZE.y) * TILE_SIZE.y)
    if not _can_place_at(grid_pos):
        build_failed.emit(current_structure.id, "invalid_position")
        return
    var player = get_node("/root/GameManager").player if get_node("/root/GameManager") else null
    if not player or not player.inventory_comp:
        return
    for material in current_structure.materials_required:
        if not player.inventory_comp.has_item(material.item_id, material.quantity):
            build_failed.emit(current_structure.id, "insufficient_materials")
            @warning_ignore("confusable_local_declaration")
            var EM = get_node("/root/EventManager")
            if EM:
                EM.notification_shown.emit("Materiales insuficientes", "danger")
            return
    if player.gold < current_structure.gold_cost:
        build_failed.emit(current_structure.id, "insufficient_gold")
        return
    for material in current_structure.materials_required:
        player.inventory_comp.remove_item(material.item_id, material.quantity)
    player.gold -= current_structure.gold_cost
    var structure_instance = current_structure.scene.instantiate()
    structure_instance.global_position = grid_pos
    structure_instance.rotation_degrees = current_rotation
    structure_instance.add_to_group("player_structures")
    structure_instance.set_meta("structure_id", current_structure.id)
    structure_instance.set_meta("owner_id", player.player_id)
    structure_instance.set_meta("built_time", Time.get_unix_time_from_system())
    get_tree().current_scene.add_child(structure_instance)
    build_completed.emit(current_structure.id, grid_pos)
    var EM = get_node("/root/EventManager")
    if EM:
        EM.notification_shown.emit("Construcción completada: %s" % current_structure.display_name, "success")
    if is_in_building_mode:
        _create_ghost_structure()


func _can_place_at(grid_pos: Vector2) -> bool:
    if not current_structure:
        return false
    if not _is_in_player_territory(grid_pos):
        return false
    var space_state = get_tree().current_scene.get_world_2d().direct_space_state
    if space_state:
        var query = PhysicsShapeQueryParameters2D.new()
        var shape = RectangleShape2D.new()
        shape.size = Vector2(current_structure.size.x * TILE_SIZE.x, current_structure.size.y * TILE_SIZE.y)
        query.shape = shape
        query.transform = Transform2D(0, grid_pos + shape.size / 2)
        query.collision_mask = 0xFFFF
        var results = space_state.intersect_shape(query)
        for result in results:
            var collider = result.collider
            if collider and not (collider.is_in_group("player_structures") and collider.get_meta("structure_id", "") == current_structure.id):
                if not (_get_structure_category(current_structure) == "FLOOR" and collider.is_in_group("terrain")):
                    return false
    if current_structure.requires_floor:
        if not _has_floor_at(grid_pos):
            return false
    return true


func _is_in_player_territory(pos: Vector2) -> bool:
    var player = get_node("/root/GameManager").player if get_node("/root/GameManager") else null
    if not player:
        return false
    var grid_tile = Vector2i(int(pos.x / TILE_SIZE.x), int(pos.y / TILE_SIZE.y))
    if grid_tile in claimed_territories:
        return claimed_territories[grid_tile] == player.player_id
    return false


func _has_floor_at(pos: Vector2) -> bool:
    var structures = get_tree().get_nodes_in_group("player_structures")
    for structure in structures:
        if structure.global_position == pos and structure.has_meta("structure_id"):
            var struct_res = _load_structure_resource(structure.get_meta("structure_id"))
            if struct_res and _get_structure_category(struct_res) == "FLOOR":
                return true
    return false


func _get_structure_category(struct) -> String:
    var cat_enum = struct.get("category")
    if cat_enum == null:
        return ""
    var enum_names = ["FLOOR", "WALL", "DOOR", "ROOF", "STATION", "FURNITURE", "DEFENSE", "DECORATION"]
    var idx = int(cat_enum)
    return enum_names[idx] if idx >= 0 and idx < enum_names.size() else ""


func _load_structure_resource(structure_id: String):
    var paths = {
        "wooden_floor": "res://Resources/Building/wooden_floor.tres",
        "stone_wall": "res://Resources/Building/stone_wall.tres",
    }
    var path = paths.get(structure_id)
    if path:
        return load(path)
    return null


func claim_territory(center_tile: Vector2i, owner_id: String) -> bool:
    for x in range(center_tile.x, center_tile.x + CLAIM_PLOT_SIZE.x):
        for y in range(center_tile.y, center_tile.y + CLAIM_PLOT_SIZE.y):
            if Vector2i(x, y) in claimed_territories:
                return false
    for x in range(center_tile.x, center_tile.x + CLAIM_PLOT_SIZE.x):
        for y in range(center_tile.y, center_tile.y + CLAIM_PLOT_SIZE.y):
            claimed_territories[Vector2i(x, y)] = owner_id
    var bounds = Rect2(center_tile.x * TILE_SIZE.x, center_tile.y * TILE_SIZE.y, CLAIM_PLOT_SIZE.x * TILE_SIZE.x, CLAIM_PLOT_SIZE.y * TILE_SIZE.y)
    territory_claimed.emit(owner_id, bounds)
    return true


func _toggle_building_mode() -> void:
    if is_in_building_mode:
        _exit_building_mode()
    else:
        var UM = get_node("/root/UIManager")
        if UM:
            UM.open_ui("building_menu")
