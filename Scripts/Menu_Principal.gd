extends Control

# ─── Paleta ───────────────────────────────────────────────────────────
const C_BG_TOP    = Color(0.04, 0.04, 0.10, 1.0)
const C_BG_BOT    = Color(0.08, 0.02, 0.16, 1.0)
const C_GOLD      = Color(0.95, 0.78, 0.20, 1.0)
const C_GOLD_DIM  = Color(0.70, 0.55, 0.10, 1.0)
const C_WHITE     = Color(0.95, 0.95, 1.00, 1.0)
const C_GREY      = Color(0.50, 0.52, 0.60, 1.0)
const C_BTN_N     = Color(0.12, 0.14, 0.22, 0.95)
const C_BTN_H     = Color(0.20, 0.14, 0.36, 0.98)
const C_BTN_BRD   = Color(0.45, 0.30, 0.70, 1.0)
const C_BTN_BRD_H = Color(0.78, 0.55, 1.00, 1.0)
const C_GLOW      = Color(0.65, 0.35, 1.0, 0.18)

# ─── Partículas ───────────────────────────────────────────────────────
var particles: Array = []
const PARTICLE_COUNT = 60

# ─── Animación ────────────────────────────────────────────────────────
var time: float = 0.0
var title_alpha: float = 0.0
var btn_alpha: float   = 0.0
var subtitle_alpha: float = 0.0

# ─── Nodos UI ─────────────────────────────────────────────────────────
var btn_start:  Button
var btn_config: Button
var btn_quit:   Button
var vbox:       VBoxContainer

# ─── Estrella parpadeante ─────────────────────────────────────────────
func _ready() -> void:
	# Fullscreen
	anchor_left   = 0.0; anchor_top    = 0.0
	anchor_right  = 1.0; anchor_bottom = 1.0
	offset_left   = 0.0; offset_top    = 0.0
	offset_right  = 0.0; offset_bottom = 0.0

	_init_particles()
	_build_ui()


func _init_particles() -> void:
	randomize()
	for i in PARTICLE_COUNT:
		particles.append({
			"pos":   Vector2(randf() * 1920, randf() * 1080),
			"vel":   Vector2(randf_range(-6, 6), randf_range(-12, -3)),
			"size":  randf_range(1.0, 3.5),
			"alpha": randf_range(0.2, 0.9),
			"phase": randf() * TAU,
		})


func _build_ui() -> void:
	# VBox centrado
	vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_CENTER)
	vbox.offset_left   = -160.0
	vbox.offset_right  =  160.0
	vbox.offset_top    = -90.0
	vbox.offset_bottom =  90.0
	vbox.add_theme_constant_override("separation", 14)
	add_child(vbox)

	btn_start  = _make_button("⚔  Iniciar Aventura")
	btn_config = _make_button("⚙  Configuración")
	btn_quit   = _make_button("✕  Salir del Juego")

	vbox.add_child(btn_start)
	vbox.add_child(btn_config)
	vbox.add_child(btn_quit)

	btn_start.pressed.connect(_on_iniciar_aventura_pressed)
	btn_config.pressed.connect(_on_configuracion_pressed)
	btn_quit.pressed.connect(_on_salir_del_juego_pressed)


func _make_button(label: String) -> Button:
	var b = Button.new()
	b.text             = label
	b.custom_minimum_size = Vector2(320, 52)
	b.add_theme_font_size_override("font_size", 18)
	b.add_theme_color_override("font_color",        C_WHITE)
	b.add_theme_color_override("font_hover_color",  C_GOLD)
	b.add_theme_color_override("font_pressed_color", C_GOLD_DIM)

	var sn = _make_stylebox(C_BTN_N,  C_BTN_BRD)
	var sh = _make_stylebox(C_BTN_H,  C_BTN_BRD_H)
	b.add_theme_stylebox_override("normal",  sn)
	b.add_theme_stylebox_override("hover",   sh)
	b.add_theme_stylebox_override("pressed", sh)
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	return b


func _make_stylebox(bg: Color, border: Color) -> StyleBoxFlat:
	var s = StyleBoxFlat.new()
	s.bg_color        = bg
	s.border_color    = border
	s.border_width_left   = 1
	s.border_width_right  = 1
	s.border_width_top    = 1
	s.border_width_bottom = 1
	s.corner_radius_top_left     = 8
	s.corner_radius_top_right    = 8
	s.corner_radius_bottom_left  = 8
	s.corner_radius_bottom_right = 8
	s.shadow_size   = 6
	s.shadow_color  = C_GLOW
	s.shadow_offset = Vector2(0, 3)
	return s


# ─── Loop ─────────────────────────────────────────────────────────────
func _process(delta: float) -> void:
	time += delta
	title_alpha    = min(1.0, title_alpha    + delta * 1.4)
	subtitle_alpha = min(1.0, subtitle_alpha + delta * 0.9)
	btn_alpha      = min(1.0, btn_alpha      + delta * 0.7)

	# Move particles
	for p in particles:
		p["pos"] += p["vel"] * delta * 60.0
		if p["pos"].y < -10:
			p["pos"] = Vector2(randf() * 1920, 1100)
		if p["pos"].x < -10 or p["pos"].x > 1930:
			p["vel"].x *= -1

	# Fade in buttons container
	vbox.modulate.a = btn_alpha

	# Offset title subtle bob
	queue_redraw()


func _draw() -> void:
	var W := size.x
	var H := size.y

	# Background gradient (manual rects)
	var steps := 16
	for i in steps:
		var t   = float(i) / steps
		var col = C_BG_TOP.lerp(C_BG_BOT, t)
		draw_rect(Rect2(0, H * t / 1.0, W, H / steps + 2), col)

	# Particles
	for p in particles:
		var a   = (0.5 + 0.5 * sin(time * 1.8 + p["phase"])) * p["alpha"]
		var col = Color(0.65, 0.40, 1.0, a)
		draw_circle(p["pos"], p["size"], col)

	# Decorative horizontal rule
	var rule_y = H * 0.25
	draw_line(Vector2(W * 0.10, rule_y), Vector2(W * 0.90, rule_y),
	          Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.25 * title_alpha), 1)

	# Title glow
	var title = "MeaCore Quest"
	var ts    = 64
	var ty    = H * 0.14 + sin(time * 0.9) * 3.0
	# Outer glow pass (large, transparent)
	draw_string(ThemeDB.fallback_font, Vector2(W * 0.5 - 220, ty),
	            title, HORIZONTAL_ALIGNMENT_CENTER, 440, ts + 4,
	            Color(0.7, 0.4, 1.0, 0.15 * title_alpha))
	# Main title
	draw_string(ThemeDB.fallback_font, Vector2(W * 0.5 - 220, ty),
	            title, HORIZONTAL_ALIGNMENT_CENTER, 440, ts,
	            Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, title_alpha))

	# Subtitle
	var sub = "Un mundo de héroes, mazmorras y leyendas"
	draw_string(ThemeDB.fallback_font, Vector2(W * 0.5 - 300, ty + 56),
	            sub, HORIZONTAL_ALIGNMENT_CENTER, 600, 18,
	            Color(C_GREY.r, C_GREY.g, C_GREY.b, subtitle_alpha * 0.85))

	# Version tag
	draw_string(ThemeDB.fallback_font, Vector2(W - 130, H - 16),
	            "v0.1-alfa", HORIZONTAL_ALIGNMENT_LEFT, 120, 12,
	            Color(0.4, 0.4, 0.5, 0.6))

	# Footer decoration
	draw_line(Vector2(W * 0.10, H * 0.88), Vector2(W * 0.90, H * 0.88),
	          Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.15 * btn_alpha), 1)

	# Reposition vbox dynamically
	if vbox:
		vbox.position = Vector2(W * 0.5 - 160, H * 0.46)


# ─── Button handlers ──────────────────────────────────────────────────
func _on_iniciar_aventura_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/MainGame.tscn")

func _on_configuracion_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/Configuracion.tscn")

func _on_salir_del_juego_pressed() -> void:
	get_tree().quit()
