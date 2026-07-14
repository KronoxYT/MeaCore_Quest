extends Node2D

class_name WorldMap

@export var grid_size: Vector2i = Vector2i(20, 20)
@export var tile_size: int = 16


func _ready() -> void:
    _ensure_tileset()
    _paint_grass_tiles()
    _generate_navigation_polygon()


func _ensure_tileset() -> void:
    var tilemap := $TileMap as TileMap
    if not tilemap:
        return
    if tilemap.tile_set:
        return
    var ts = TileSet.new()
    ts.tile_size = Vector2i(tile_size, tile_size)
    tilemap.tile_set = ts


func _paint_grass_tiles() -> void:
    var tilemap := $TileMap as TileMap
    if not tilemap or not tilemap.tile_set:
        return
    for x in grid_size.x:
        for y in grid_size.y:
            tilemap.set_cell(0, Vector2i(x, y), 0, Vector2i(0, 0))


func _generate_navigation_polygon() -> void:
    var nav_region = $NavigationRegion2D
    if not nav_region:
        return
    var world_size := Vector2(grid_size * tile_size)
    var polygon := NavigationPolygon.new()
    polygon.agent_radius = 12.0
    var outline := PackedVector2Array([
        Vector2(0, 0),
        Vector2(world_size.x, 0),
        Vector2(world_size.x, world_size.y),
        Vector2(0, world_size.y)
    ])
    polygon.add_outline(outline)
    var source_geo := NavigationMeshSourceGeometryData2D.new()
    NavigationServer2D.parse_source_geometry_data(polygon, source_geo, nav_region)
    NavigationServer2D.bake_from_source_geometry_data(polygon, source_geo)
    nav_region.navigation_polygon = polygon
