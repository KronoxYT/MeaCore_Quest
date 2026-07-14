extends Node2D

# Preloads for scenes
const PLAYER_SCENE = preload("res://Scenes/entities/Player.tscn")
const ENEMY_SCENE = preload("res://Scenes/entities/Enemy.tscn")
const NPC_SCENE = preload("res://Scenes/entities/NPC.tscn")
const DAMAGE_NUMBER_SCENE = preload("res://Scenes/entities/DamageNumber.tscn")
const DEMON_SCENE = preload("res://Scenes/Enemies/Demonio.tscn")
const BLOOD_DEMON_SCENE = preload("res://Scenes/Enemies/Demonio de Sangre.tscn")

# Node references
@onready var tile_map_layer: TileMapLayer = $TileMapLayer
@onready var entity_container: Node2D = $Entities

# Portal Areas
var town_portal: Area2D
var arena_portal: Area2D

func _ready():
    randomize()
    
    # Generate procedural map
    _build_tilemap()
    
    # Spawn player and entities
    _spawn_world()
    
    # Connect global signal channels
    GameManager.show_damage_number.connect(on_show_damage_number)
    GameManager.play_effect.connect(on_play_effect)
    
    # Set up BGM if we want, or just system announcements
    GameManager.add_chat_msg("[Servidor]", "Servidor cargado de forma estable. Jugadores en línea: 1 (Tú).", Color(0.3, 0.9, 0.9))

# Procedurally generate the TileMap
func _build_tilemap():
    var tileset_resource = TileSet.new()
    tileset_resource.tile_size = Vector2i(16, 16)
    
    var source = TileSetAtlasSource.new()
    source.texture = load("res://Assets/Sprites/tileset.png")
    source.texture_region_size = Vector2i(16, 16)
    
    # Register tiles from atlas
    var cells = [
        Vector2i(0,0), # grass center
        Vector2i(1,0), # stone cobblestone
        Vector2i(2,0), # dirt path
        Vector2i(3,0), # water
        Vector2i(4,0), # brick wall
        Vector2i(5,0), # dark grass
        Vector2i(6,0), # tree trunk
        Vector2i(7,0), # leaves
        Vector2i(0,1), # signpost
        Vector2i(1,1), # chest
        Vector2i(2,1), # portal
        Vector2i(3,1), # dungeon pillar
    ]
    for cell in cells:
        source.create_tile(cell)
        
    tileset_resource.add_source(source, 1) # source ID 1
    tile_map_layer.tile_set = tileset_resource
    
    # PAINT MAP (-80 to 80)
    var map_size = 75
    
    # 1. Fill background with Water
    for x in range(-map_size, map_size):
        for y in range(-map_size, map_size):
            tile_map_layer.set_cell(Vector2i(x, y), 1, Vector2i(3, 0)) # Water
            
    # 2. Paint Grass Lands
    # Wilderness/Slime South: X: -30 to 50, Y: 30 to 70
    # Forest East: X: 30 to 70, Y: -20 to 30
    # Town Central: X: -10 to 30, Y: -10 to 30
    for x in range(-70, 70):
        for y in range(-70, 70):
            # Town
            if x >= -10 and x <= 30 and y >= -10 and y <= 30:
                tile_map_layer.set_cell(Vector2i(x, y), 1, Vector2i(0, 0)) # Grass
            # Slime Zone (South)
            elif x >= -40 and x <= 50 and y >= 30 and y <= 70:
                tile_map_layer.set_cell(Vector2i(x, y), 1, Vector2i(0, 0)) # Grass
            # Forest Zone (East)
            elif x >= 30 and x <= 70 and y >= -30 and y <= 40:
                tile_map_layer.set_cell(Vector2i(x, y), 1, Vector2i(0, 0)) # Grass

    # 3. Paint Cemetery Spooky Dark Grass (North West)
    for x in range(-70, -10):
        for y in range(-70, 20):
            if x >= -70 and x <= -10 and y >= -70 and y <= 20:
                tile_map_layer.set_cell(Vector2i(x, y), 1, Vector2i(5, 0)) # Dark Grass

    # 4. Paint Boss Arena Spooky Floor (North)
    for x in range(-10, 30):
        for y in range(-65, -30):
            tile_map_layer.set_cell(Vector2i(x, y), 1, Vector2i(5, 0)) # Dark Grass

    # 5. Draw Town Paths and Walls
    # Cobble Roads
    for y in range(-10, 31):
        tile_map_layer.set_cell(Vector2i(10, y), 1, Vector2i(1, 0)) # Main North-South Cobble Road
    for x in range(-10, 31):
        tile_map_layer.set_cell(Vector2i(x, 10), 1, Vector2i(1, 0)) # East-West Cobble Road

    # Town Walls enclosing town (from x=-10 to 30, y=-10 to 30)
    for x in range(-10, 31):
        # North wall (leave gate at x=10)
        if x != 10:
            tile_map_layer.set_cell(Vector2i(x, -10), 1, Vector2i(4, 0))
        # South wall (leave gate at x=10)
        if x != 10:
            tile_map_layer.set_cell(Vector2i(x, 30), 1, Vector2i(4, 0))
    for y in range(-10, 31):
        # Left wall
        tile_map_layer.set_cell(Vector2i(-10, y), 1, Vector2i(4, 0))
        # Right wall (leave gate at y=10)
        if y != 10:
            tile_map_layer.set_cell(Vector2i(30, y), 1, Vector2i(4, 0))

    # Enclose Boss Arena (x=-10 to 30, y=-65 to -30)
    for x in range(-10, 31):
        tile_map_layer.set_cell(Vector2i(x, -65), 1, Vector2i(4, 0))
        # Bottom wall (completely closed, only portal access!)
        tile_map_layer.set_cell(Vector2i(x, -30), 1, Vector2i(4, 0))
    for y in range(-65, -29):
        tile_map_layer.set_cell(Vector2i(-10, y), 1, Vector2i(4, 0))
        tile_map_layer.set_cell(Vector2i(30, y), 1, Vector2i(4, 0))

    # 6. Place Environmental Decor
    # Spooky pillars in cemetery
    for x in range(-60, -15, 12):
        for y in range(-60, 10, 12):
            tile_map_layer.set_cell(Vector2i(x, y), 1, Vector2i(3, 1)) # Dark pillar

    # Spooky dead trees in cemetery (just trunks)
    for i in range(25):
        var rx = randi_range(-65, -15)
        var ry = randi_range(-65, 15)
        if tile_map_layer.get_cell_atlas_coords(Vector2i(rx, ry)) == Vector2i(5, 0): # dark grass
            tile_map_layer.set_cell(Vector2i(rx, ry), 1, Vector2i(6, 0)) # Trunk

    # Regular trees in wilderness & forest (Trunk + Leaves above)
    # Wild trees
    for i in range(40):
        var rx = randi_range(-35, 45)
        var ry = randi_range(35, 65)
        if rx != 10: # avoid road
            tile_map_layer.set_cell(Vector2i(rx, ry), 1, Vector2i(6, 0))
            tile_map_layer.set_cell(Vector2i(rx, ry-1), 1, Vector2i(7, 0))
    # Forest trees (Denser)
    for i in range(80):
        var rx = randi_range(35, 65)
        var ry = randi_range(-25, 35)
        if ry != 10:
            tile_map_layer.set_cell(Vector2i(rx, ry), 1, Vector2i(6, 0))
            tile_map_layer.set_cell(Vector2i(rx, ry-1), 1, Vector2i(7, 0))

    # Place chest props in town
    tile_map_layer.set_cell(Vector2i(8, 8), 1, Vector2i(1, 1))
    tile_map_layer.set_cell(Vector2i(12, 8), 1, Vector2i(1, 1))

    # Portal graphics
    tile_map_layer.set_cell(Vector2i(10, -9), 1, Vector2i(2, 1))  # Town Portal (outside north wall)
    tile_map_layer.set_cell(Vector2i(10, -32), 1, Vector2i(2, 1)) # Arena exit portal

# Populate entities
func _spawn_world():
    # 1. Spawn Player in town center
    var player = PLAYER_SCENE.instantiate()
    player.global_position = Vector2(160, 160) # Tile (10, 10)
    player.set_physics_process(false) # Lock until class selected
    entity_container.add_child(player)
    
    # 2. Spawn NPCs
    var elder = NPC_SCENE.instantiate()
    elder.npc_id = "elder"
    elder.global_position = Vector2(240, 128) # Tile (15, 8)
    entity_container.add_child(elder)
    
    var merchant = NPC_SCENE.instantiate()
    merchant.npc_id = "merchant"
    merchant.global_position = Vector2(80, 128) # Tile (5, 8)
    entity_container.add_child(merchant)
    
    # 3. Spawn Training Dummies
    var dummy1 = ENEMY_SCENE.instantiate()
    dummy1.monster_id = "dummy"
    dummy1.global_position = Vector2(160, 250) # South town square
    entity_container.add_child(dummy1)
    
    var dummy2 = ENEMY_SCENE.instantiate()
    dummy2.monster_id = "dummy"
    dummy2.global_position = Vector2(192, 250)
    entity_container.add_child(dummy2)

    # 4. Spawn Wilderness Slimes (Level 1)
    for i in range(6):
        var slime = ENEMY_SCENE.instantiate()
        slime.monster_id = "slime"
        # Random position in South Grass: X: -300 to 500, Y: 600 to 1000
        slime.global_position = Vector2(randf_range(-150, 400), randf_range(600, 950))
        entity_container.add_child(slime)

    # 5. Spawn Forest Goblins (Level 2)
    for i in range(5):
        var goblin = ENEMY_SCENE.instantiate()
        goblin.monster_id = "goblin"
        # East Forest: X: 600 to 1000, Y: -200 to 400
        goblin.global_position = Vector2(randf_range(600, 1000), randf_range(-200, 400))
        entity_container.add_child(goblin)

    # 6. Spawn Cemetery Skeletons (Level 3)
    for i in range(5):
        var skeleton = ENEMY_SCENE.instantiate()
        skeleton.monster_id = "skeleton"
        # North West Spooky: X: -800 to -200, Y: -800 to 200
        skeleton.global_position = Vector2(randf_range(-800, -200), randf_range(-800, 200))
        entity_container.add_child(skeleton)

    # 7. Spawn Demons (Level 4) in North transition zone
    for i in range(3):
        var demon = DEMON_SCENE.instantiate()
        demon.monster_id = "demon"
        demon.global_position = Vector2(randf_range(-800, -300), randf_range(-800, -600))
        entity_container.add_child(demon)

    # 8. Spawn Blood Demons (Level 5) near Arena entrance
    for i in range(2):
        var bd = BLOOD_DEMON_SCENE.instantiate()
        bd.monster_id = "blood_demon"
        bd.global_position = Vector2(randf_range(-100, 300), randf_range(-500, -400))
        entity_container.add_child(bd)

    # 9. Spawn Demon Boss (Level 5) in North Arena
    var boss = ENEMY_SCENE.instantiate()
    boss.monster_id = "boss"
    boss.global_position = Vector2(160, -720) # Tile (10, -45)
    entity_container.add_child(boss)

    # 10. Setup Portal Triggers (Area2D programmatically)
    # Town Portal
    town_portal = Area2D.new()
    var coll_town = CollisionShape2D.new()
    coll_town.shape = CircleShape2D.new()
    coll_town.shape.radius = 12.0
    town_portal.add_child(coll_town)
    town_portal.global_position = Vector2(160, -144) # Tile (10, -9)
    town_portal.collision_layer = 0
    town_portal.collision_mask = 2 # Detect player
    town_portal.body_entered.connect(_on_town_portal_entered)
    add_child(town_portal)
    
    # Arena Exit Portal
    arena_portal = Area2D.new()
    var coll_arena = CollisionShape2D.new()
    coll_arena.shape = CircleShape2D.new()
    coll_arena.shape.radius = 12.0
    arena_portal.add_child(coll_arena)
    arena_portal.global_position = Vector2(160, -512) # Tile (10, -32)
    arena_portal.collision_layer = 0
    arena_portal.collision_mask = 2
    arena_portal.body_entered.connect(_on_arena_portal_entered)
    add_child(arena_portal)
    
    # Portal to Mapa seguro (zona segura)
    var mapa_portal = Area2D.new()
    var coll_mapa = CollisionShape2D.new()
    coll_mapa.shape = CircleShape2D.new()
    coll_mapa.shape.radius = 12.0
    mapa_portal.add_child(coll_mapa)
    var portal_sprite = Sprite2D.new()
    portal_sprite.texture = load("res://Assets/Sprites/tileset.png")
    portal_sprite.region_enabled = true
    portal_sprite.region_rect = Rect2(32, 16, 16, 16) # tile (2,1) portal
    portal_sprite.centered = false
    mapa_portal.add_child(portal_sprite)
    mapa_portal.global_position = Vector2(80, 160) # Tile (5, 10)
    mapa_portal.collision_layer = 0
    mapa_portal.collision_mask = 2
    mapa_portal.body_entered.connect(_on_mapa_portal_entered)
    add_child(mapa_portal)

# Teleportation behaviors
func _on_town_portal_entered(body):
    if body.is_in_group("player"):
        GameManager.add_chat_msg("[Portal]", "Te teletransportas a la Arena del Demon Lord. ¡Prepárate!", Color(1.0, 0.4, 0.4))
        body.global_position = Vector2(160, -640) # Teleport to bottom center of arena
        SoundManager.play_sfx("mana")

func _on_arena_portal_entered(body):
    if body.is_in_group("player"):
        GameManager.add_chat_msg("[Portal]", "Sales de la Arena y regresas a la Aldea.", Color(0.3, 0.8, 1.0))
        body.global_position = Vector2(160, -112) # Teleport back outside north gate
        SoundManager.play_sfx("mana")

func _on_mapa_portal_entered(body):
    if body.is_in_group("player"):
        GameManager.add_chat_msg("[Portal]", "Entras a una zona segura...", Color(0.3, 0.8, 1.0))
        get_tree().change_scene_to_file("res://Scenes/Mapa.tscn")

# Handle floating damage numbers
func on_show_damage_number(pos: Vector2, text: String, color: Color):
    var dmg_node = DAMAGE_NUMBER_SCENE.instantiate()
    dmg_node.global_position = pos
    dmg_node.setup(text, color)
    add_child(dmg_node)

# Handle spell particle effects programmatically
func on_play_effect(effect_name: String, pos: Vector2):
    var p = CPUParticles2D.new()
    p.global_position = pos
    p.one_shot = true
    p.emitting = true
    
    if effect_name == "level_up":
        var player = get_tree().get_first_node_in_group("player")
        if player:
            player.add_child(p)
            p.position = Vector2(0, -6)
        p.amount = 40
        p.lifetime = 1.0
        p.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
        p.emission_sphere_radius = 8.0
        p.direction = Vector2(0, -1)
        p.spread = 15.0
        p.gravity = Vector2(0, -90)
        p.initial_velocity_min = 30.0
        p.initial_velocity_max = 60.0
        p.color = Color(1.0, 0.84, 0.0) # Gold
    else:
        add_child(p)
        if effect_name == "atk_fireball_impact":
            p.amount = 20
            p.lifetime = 0.45
            p.spread = 180.0
            p.gravity = Vector2.ZERO
            p.initial_velocity_min = 40.0
            p.initial_velocity_max = 80.0
            p.color = Color(1.0, 0.4, 0.1) # Fire Orange
        elif effect_name == "atk_spell_impact":
            p.amount = 12
            p.lifetime = 0.35
            p.spread = 180.0
            p.gravity = Vector2.ZERO
            p.initial_velocity_min = 30.0
            p.initial_velocity_max = 60.0
            p.color = Color(0.2, 0.8, 1.0) # Magic Aqua
        elif effect_name == "atk_poison_impact":
            p.amount = 12
            p.lifetime = 0.35
            p.spread = 180.0
            p.gravity = Vector2.ZERO
            p.initial_velocity_min = 25.0
            p.initial_velocity_max = 50.0
            p.color = Color(0.3, 0.9, 0.3) # Poison Green
        elif effect_name == "atk_slash":
            p.amount = 15
            p.lifetime = 0.3
            p.spread = 45.0
            p.direction = Vector2.UP
            p.gravity = Vector2(0, 100)
            p.initial_velocity_min = 60.0
            p.initial_velocity_max = 120.0
            p.color = Color(1.0, 0.9, 0.3) # Sparks yellow
        elif effect_name == "atk_spin":
            p.amount = 30
            p.lifetime = 0.35
            p.spread = 180.0
            p.gravity = Vector2.ZERO
            p.initial_velocity_min = 50.0
            p.initial_velocity_max = 100.0
            p.color = Color(1.0, 0.85, 0.2)
        else:
            p.amount = 8
            p.lifetime = 0.3
            p.spread = 180.0
            p.gravity = Vector2.ZERO
            p.initial_velocity_min = 20.0
            p.initial_velocity_max = 40.0
            p.color = Color.WHITE

    # Auto-clean particles when finished
    p.finished.connect(p.queue_free)
