extends Node

signal weather_changed(new_weather: String)
signal weather_intensity_changed(intensity: float)

enum WeatherType { CLEAR, CLOUDY, RAIN, SNOW, STORM, HEATWAVE, FOG }

const SEASONS = ["spring", "summer", "autumn", "winter"]

var current_weather: String = "clear"
var current_intensity: float = 0.0
var weather_timer: float = 0.0
var weather_duration: float = 600.0
var current_biome: String = "valdris"
var current_season: String = "summer"
var weather_particles: Dictionary = {}


func _ready():
    process_mode = PROCESS_MODE_ALWAYS
    weather_timer = weather_duration


func _process(delta: float) -> void:
    weather_timer -= delta
    if weather_timer <= 0:
        _change_weather_randomly()
        weather_timer = randf_range(600, 1800)


func set_weather(new_weather: String, duration: float = 0, intensity: float = 1.0) -> void:
    if new_weather == current_weather and abs(intensity - current_intensity) < 0.01:
        return
    current_weather = new_weather
    current_intensity = intensity
    if duration > 0:
        weather_duration = duration
        weather_timer = duration
    _update_weather_effects()
    weather_changed.emit(new_weather)
    weather_intensity_changed.emit(intensity)
    var EM = get_node("/root/EventManager")
    if EM:
        EM.weather_changed.emit(new_weather)


func _change_weather_randomly() -> void:
    var weights: Dictionary = {}
    match current_biome:
        "valdris":
            weights = {"clear": 0.4, "cloudy": 0.3, "rain": 0.2, "fog": 0.1}
        "frostheim":
            weights = {"snow": 0.4, "cloudy": 0.3, "clear": 0.2, "storm": 0.1}
        "kharos":
            weights = {"clear": 0.6, "heatwave": 0.2, "storm": 0.2}
        "nocturnis":
            weights = {"fog": 0.4, "rain": 0.3, "cloudy": 0.3}
        "ignaris":
            weights = {"heatwave": 0.5, "clear": 0.3, "storm": 0.2}
        _:
            weights = {"clear": 0.6, "cloudy": 0.3, "rain": 0.1}
    set_weather(_weighted_random(weights), 0, randf_range(0.5, 1.0))


func _weighted_random(weights: Dictionary) -> String:
    var total = 0.0
    for w in weights.values():
        total += w
    var roll = randf() * total
    var accumulated = 0.0
    for key in weights.keys():
        accumulated += weights[key]
        if roll <= accumulated:
            return key
    return weights.keys()[0]


func _update_weather_effects() -> void:
    match current_weather:
        "rain":
            _enable_particle_vfx("rain_particles", current_intensity)
        "snow":
            _enable_particle_vfx("snow_particles", current_intensity)
        "storm":
            _enable_particle_vfx("rain_particles", 1.0)
            _enable_storm_lightning()
        "heatwave":
            _enable_heat_distortion()
        "fog":
            _enable_fog_overlay(current_intensity)
        _:
            _disable_all_vfx()


func _enable_particle_vfx(particle_name: String, intensity: float) -> void:
    print("[Weather] VFX activado: %s (%.2f)" % [particle_name, intensity])


func _disable_all_vfx() -> void:
    print("[Weather] VFX desactivados")


func _enable_storm_lightning() -> void:
    await get_tree().create_timer(randf_range(5.0, 20.0)).timeout
    if current_weather == "storm":
        _enable_particle_vfx("lightning", 1.0)
        _enable_storm_lightning()


func _enable_heat_distortion() -> void:
    print("[Weather] Distorsión de calor aplicada")


func _enable_fog_overlay(intensity: float) -> void:
    print("[Weather] Niebla con intensidad %.2f" % intensity)


func set_biome(biome: String) -> void:
    current_biome = biome


func set_season(season: String) -> void:
    current_season = season
