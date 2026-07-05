class_name BSPNode
extends RefCounted

var rect: Rect2i
var left_child: BSPNode = null
var right_child: BSPNode = null
var room: Rect2i = Rect2i()
var corridors: Array[Rect2i] = []

const MIN_LEAF_SIZE: int = 6

func _init(_rect: Rect2i):
    rect = _rect

func split() -> bool:
    if left_child != null or right_child != null:
        return false
    if rect.size.width < MIN_LEAF_SIZE * 2 and rect.size.height < MIN_LEAF_SIZE * 2:
        return false
    var split_h = randf() > 0.5
    if rect.size.width > rect.size.height and rect.size.width / rect.size.height >= 1.25:
        split_h = false
    elif rect.size.height > rect.size.width and rect.size.height / rect.size.width >= 1.25:
        split_h = true
    var max_size = (rect.size.height if split_h else rect.size.width) - MIN_LEAF_SIZE
    if max_size <= MIN_LEAF_SIZE:
        return false
    var split_at = randi_range(MIN_LEAF_SIZE, max_size)
    if split_h:
        left_child = BSPNode.new(Rect2i(rect.position, Vector2i(rect.size.width, split_at)))
        right_child = BSPNode.new(Rect2i(Vector2i(rect.position.x, rect.position.y + split_at), Vector2i(rect.size.width, rect.size.height - split_at)))
    else:
        left_child = BSPNode.new(Rect2i(rect.position, Vector2i(split_at, rect.size.height)))
        right_child = BSPNode.new(Rect2i(Vector2i(rect.position.x + split_at, rect.position.y), Vector2i(rect.size.width - split_at, rect.size.height)))
    return true

func create_rooms() -> void:
    if left_child != null and right_child != null:
        left_child.create_rooms()
        right_child.create_rooms()
        corridors.append(_create_corridor(left_child.get_room_center(), right_child.get_room_center()))
    else:
        var w = randi_range(MIN_LEAF_SIZE - 2, rect.size.width - 2)
        var h = randi_range(MIN_LEAF_SIZE - 2, rect.size.height - 2)
        var x = rect.position.x + randi_range(1, rect.size.width - w - 1)
        var y = rect.position.y + randi_range(1, rect.size.height - h - 1)
        room = Rect2i(x, y, w, h)

func get_room_center() -> Vector2i:
    if room.has_area():
        return Vector2i(room.get_center().x, room.get_center().y)
    if left_child != null:
        return left_child.get_room_center()
    if right_child != null:
        return right_child.get_room_center()
    return Vector2i(rect.get_center().x, rect.get_center().y)

func _create_corridor(start: Vector2i, end: Vector2i) -> Rect2i:
    var x1 = start.x
    var x2 = end.x
    var y1 = start.y
    var y2 = end.y
    if randf() > 0.5:
        return Rect2i(min(x1, x2), y1, abs(x2 - x1) + 1, 2)
    else:
        return Rect2i(x1, min(y1, y2), 2, abs(y2 - y1) + 1)

func get_all_rooms() -> Array[Rect2i]:
    var rooms: Array[Rect2i] = []
    if room.has_area():
        rooms.append(room)
    if left_child:
        rooms.append_array(left_child.get_all_rooms())
    if right_child:
        rooms.append_array(right_child.get_all_rooms())
    return rooms

func get_all_corridors() -> Array[Rect2i]:
    var cors: Array[Rect2i] = []
    cors.append_array(corridors)
    if left_child:
        cors.append_array(left_child.get_all_corridors())
    if right_child:
        cors.append_array(right_child.get_all_corridors())
    return cors
