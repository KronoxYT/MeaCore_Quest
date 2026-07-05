extends BaseComponent

var sprite: Sprite2D
var flash_material: ShaderMaterial
var flash_tween: Tween

func _ready():
    if not _find_sprite_and_material():
        set_physics_process(false)
        return
    var health = _find_health_component()
    if health:
        health.connect("damaged", Callable(self, "_on_owner_damaged"))

func _find_sprite_and_material() -> bool:
    sprite = owner.find_child("Sprite2D")
    if not sprite:
        return false
    for child in sprite.get_children():
        if child is ShaderMaterial:
            flash_material = child
            return true
    var shader = preload("res://Shaders/hit_flash.gdshader")
    flash_material = ShaderMaterial.new()
    flash_material.shader = shader
    return true

func _find_health_component():
    for child in owner.get_children():
        if child is Node and "damaged" in child.get_signal_list().map(func(s): return s.name):
            return child
    return null

func _on_owner_damaged(_amount: int):
    if not flash_material:
        return
    flash_material.set_shader_parameter("flash_intensity", 1.0)
    if flash_tween and flash_tween.is_valid():
        flash_tween.kill()
    flash_tween = create_tween()
    flash_tween.tween_method(_set_flash, 1.0, 0.0, 0.15).set_ease(Tween.EASE_OUT)

func _set_flash(value: float):
    if flash_material:
        flash_material.set_shader_parameter("flash_intensity", value)

func flash_custom(duration: float = 0.15, intensity: float = 1.0):
    if not flash_material:
        return
    flash_material.set_shader_parameter("flash_intensity", intensity)
    if flash_tween and flash_tween.is_valid():
        flash_tween.kill()
    flash_tween = create_tween()
    flash_tween.tween_method(_set_flash, intensity, 0.0, duration).set_ease(Tween.EASE_OUT)

func set_outline(enabled: bool, color: Color = Color(1, 0, 0, 1)):
    if not flash_material:
        return
    flash_material.set_shader_parameter("show_outline", enabled)
    flash_material.set_shader_parameter("outline_color", color)

func flash_and_outline(duration: float = 0.3):
    set_outline(true)
    flash_custom(duration, 1.0)
    if flash_tween:
        flash_tween.tween_callback(Callable(self, "set_outline").bind(false))
