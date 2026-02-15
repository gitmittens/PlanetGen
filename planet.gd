extends Node3D


const RES: int = 1920
const NOISE_MULTI = 1.75

var spin_speed = 0.06

var Tile: Dictionary = {
	FROZEN_WATER = 0, DEEP_WATER = 1, WATER = 2,
	FROZEN_PLAINS = 3, TUNDRA = 4, FOREST = 5,
	GRASS_LAND = 6, PLAINS = 7, DESERT = 8, 
	SAVANNA = 9, JUNGLE = 10, BEACH = 11
}

@onready var texture_rect: TextureRect = $TextureRect
@onready var planet_render: MeshInstance3D = $PlanetRender
@onready var temp_noise: FastNoiseLite = FastNoiseLite.new()
@onready var mois_noise: FastNoiseLite = FastNoiseLite.new()
@onready var elev_noise: FastNoiseLite = FastNoiseLite.new()


func _ready() -> void:
	var ran_seed = randi()
	temp_noise.seed = ran_seed
	temp_noise.noise_type = FastNoiseLite.TYPE_PERLIN
	temp_noise.frequency = 8
	temp_noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	temp_noise.fractal_octaves = 5
	temp_noise.fractal_gain = 0.4
	
	mois_noise.seed = ran_seed + 1
	mois_noise.noise_type = FastNoiseLite.TYPE_PERLIN
	mois_noise.frequency = 2

	# ELEVATION SETTINGS
	elev_noise.seed = ran_seed + 2
	elev_noise.noise_type = FastNoiseLite.TYPE_PERLIN
	
	# 1. Frequency: LOW (1.0 to 1.5)
	# This decides "How many continents?"
	# 1.0 = 2-3 Supercontinents.
	# 2.0 = Earth-like mix.
	# 4.0+ = Broken Archipelago (Too messy).
	elev_noise.frequency = 1.2

	# 2. Fractals: ON (Crucial!)
	elev_noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	
	# 3. Octaves: HIGH (6)
	# This adds the tiny wiggles to the coastlines.
	# If you set this to 1, your coasts will be smooth circles.
	elev_noise.fractal_octaves = 6
	
	# 4. Gain: STANDARD (0.5)
	# How "rough" the rocky surface is.
	elev_noise.fractal_gain = 0.5

	generate_planet(planet_render, -40, 50)


func _process(delta: float) -> void:
	planet_render.rotate_y(spin_speed * delta)
	planet_render.rotate_x(spin_speed / 5 * delta)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_speed"):
		var new_speed: float = 0
		if spin_speed == 0:
			new_speed = 0.02
		elif spin_speed >= 2:
			new_speed = 0
		else:
			new_speed = spin_speed * 3
		spin_speed = new_speed


func generate_planet(planet: MeshInstance3D, min_temp, max_temp):
	var width: int = RES
	var height: int = int(ceil(RES * 0.5))
	var image = Image.create(width, height, true, Image.FORMAT_RGBA8)
	for x in range(width):
		for y in range(height):
			var u = float(x) / float(width)
			var v = float(y) / float(height)
			var theta = u * TAU
			var phi = (v - 0.5) * PI
			
			var vec = Vector3.ZERO
			vec.x = cos(phi) * sin(theta)
			vec.y = sin(phi)
			vec.z = cos(phi) * cos(theta)
			
			var temp_raw = temp_noise.get_noise_3d(vec.x, vec.y, vec.z)
			var temp_val = (temp_raw + 1.0) / 2.0
			var base_temp = 1.0 - abs(vec.y)
			var temp_offset = temp_val - 0.5
			var temp = base_temp + temp_offset
			temp = clamp(temp, 0.0, 1.0)
			var celsius = lerp(min_temp, max_temp, temp)
			
			var mois_raw = mois_noise.get_noise_3d(vec.x, vec.y, vec.z)
			var mois = (mois_raw + 1.0) / 2.0
			mois = clamp(mois, 0.0, 1.0)
			
			var elev_raw = elev_noise.get_noise_3d(vec.x, vec.y, vec.z)
			var elev = (elev_raw + 1.0) / 2.0
			
			var biome = get_biome(celsius, mois, elev)
			var biome_color = get_color_from_id(biome)
			if elev > 0.485:
				biome_color.a = elev
			else:
				biome_color.a = 0.485
			
			image.set_pixel(x, y, biome_color)
	
	var tex = ImageTexture.create_from_image(image)
	texture_rect.texture = tex
	var material = ShaderMaterial.new()
	if material:
		material.shader = load("res://planet.gdshader")
		material.set_shader_parameter("planet_texture", tex)
		material.set_shader_parameter("height_scale", 1)
	planet.material_override = material


func get_biome(temp: float, mois: float, elev: float) -> int:
	if elev < 0.45:
		if temp < -25: return Tile["FROZEN_WATER"]
		return Tile["DEEP_WATER"]
	if elev < 0.48:
		if temp < -10: return Tile["FROZEN_WATER"]
		return Tile["WATER"]
	if elev < 0.485: return Tile["BEACH"]
	if temp < -10:
		if mois < 0.5: return Tile["FROZEN_PLAINS"]
		return Tile["TUNDRA"]
	if temp < 30:
		if mois < 0.45: return Tile["PLAINS"]
		if mois < 0.55: return Tile["GRASS_LAND"]
		return Tile["FOREST"]
	if mois < 0.45: return Tile["DESERT"]
	if mois < 0.55: return Tile["SAVANNA"]
	return Tile["JUNGLE"]


func get_color_from_id(id: int) -> Color:
	if id == Tile["DEEP_WATER"]: return Color("#1f4c8a")
	if id == Tile["WATER"]:      return Color("#2b63a8")
	if id == Tile["FROZEN_WATER"]: return Color("#73bed3")
	if id == Tile["FROZEN_PLAINS"]:     return Color("#CCDBCF")
	if id == Tile["TUNDRA"]:     return Color("#8db598")
	if id == Tile["FOREST"]:      return Color("#2f5727")
	if id == Tile["GRASS_LAND"]:     return Color("#4b8a3b")
	if id == Tile["PLAINS"]:     return Color("#75AB6A")
	if id == Tile["DESERT"] or id == Tile["BEACH"]:       return Color("#e6c86e")
	if id == Tile["SAVANNA"]:   return Color("#b57d45")
	if id == Tile["JUNGLE"]:   return Color("#1C3B16")
	
	return Color.MAGENTA
