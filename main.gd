extends Node2D

const CAPITAL := "Север"
const SUPPLY_RANGE := 1
const MAX_STRENGTH := 100

var regions := {}       # имя региона -> его прямоугольник
var base_colors := {}   # имя региона -> исходный цвет
var neighbors := {
	"Север": ["Восток", "Юг"],
	"Восток": ["Север", "Юг", "Юго-Восток"],
	"Юг": ["Север", "Восток", "Юго-Восток"],
	"Юго-Восток": ["Восток", "Юг"],
}
var info_label: Label
var status_label: Label

var army: ColorRect
var army_region := "Север"
var army_selected := false
var army_strength := MAX_STRENGTH
var army_alive := true


func _ready() -> void:
	# Панель с информацией сверху экрана
	var ui := CanvasLayer.new()
	add_child(ui)
	info_label = Label.new()
	info_label.position = Vector2(20, 10)
	info_label.text = "Кликни по региону или по армии"
	ui.add_child(info_label)
	# Строка состояния армии внизу
	status_label = Label.new()
	status_label.position = Vector2(20, 440)
	ui.add_child(status_label)

	make_region("Север", Vector2(100, 100), Color.STEEL_BLUE)
	make_region("Восток", Vector2(310, 100), Color.INDIAN_RED)
	make_region("Юг", Vector2(100, 260), Color.SEA_GREEN)
	make_region("Юго-Восток", Vector2(310, 260), Color.GOLDENROD)
	make_army()
	update_status("")

func make_region(region_name: String, pos: Vector2, col: Color) -> void:
	var r := ColorRect.new()
	r.position = pos
	r.size = Vector2(200, 150)
	r.color = col
	var label := Label.new()
	label.text = region_name
	if region_name == CAPITAL:
		label.text += " (столица)"
	r.add_child(label)
	r.gui_input.connect(_on_region_input.bind(region_name))
	add_child(r)
	regions[region_name] = r
	base_colors[region_name] = col

func make_army() -> void:
	army = ColorRect.new()
	army.size = Vector2(30, 30)
	army.color = Color.BLACK
	army.position = region_center(army_region) - army.size / 2
	army.gui_input.connect(_on_army_input)
	add_child(army)  # добавлена последней, значит рисуется поверх регионов

func region_center(region_name: String) -> Vector2:
	var r: ColorRect = regions[region_name]
	return r.position + r.size / 2

# Сколько регионов от столицы до данного (по цепочке соседей)
func supply_distance(region_name: String) -> int:
	var dist := {CAPITAL: 0}
	var queue := [CAPITAL]
	while not queue.is_empty():
		var current: String = queue.pop_front()
		for n in neighbors[current]:
			if not dist.has(n):
				dist[n] = dist[current] + 1
				queue.append(n)
	return dist[region_name]

func update_status(extra: String) -> void:
	var d := supply_distance(army_region)
	var supplied := d <= SUPPLY_RANGE
	var text := "Армия: сила %d/%d | регион: %s | снабжение: %s" % [
		army_strength, MAX_STRENGTH, army_region,
		"есть" if supplied else "НЕТ (далеко от столицы)"
	]
	if extra != "":
		text += "\n" + extra
	status_label.text = text

func _on_region_input(event, region_name: String) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if army_selected:
			move_army(region_name)
		else:
			select_region(region_name)

func _on_army_input(event) -> void:
	if not army_alive:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		army_selected = true
		army.color = Color.YELLOW
		info_label.text = "Армия выбрана (сейчас: %s)\nКликни по соседнему региону, чтобы отправить её." % army_region

func move_army(target: String) -> void:
	army_selected = false
	army.color = Color.BLACK
	if target == army_region:
		info_label.text = "Армия уже в регионе %s" % army_region
		return
	if not neighbors[army_region].has(target):
		info_label.text = "Туда не добраться: %s не граничит с %s" % [target, army_region]
		return
	army_region = target
	var tween := create_tween()
	tween.tween_property(army, "position", region_center(target) - army.size / 2, 0.6)
	select_region(target)
	end_turn()

# Каждое перемещение армии = один ход
func end_turn() -> void:
	var extra := ""
	if supply_distance(army_region) <= SUPPLY_RANGE:
		army_strength = mini(army_strength + 10, MAX_STRENGTH)
	else:
		army_strength = maxi(army_strength - 25, 0)
		extra = "Армия без снабжения теряет силу!"
	if army_strength == 0:
		army_alive = false
		army.color = Color.DIM_GRAY
		extra = "Армия разбита. Нажми F5 в Godot (перезапуск), чтобы начать заново."
	update_status(extra)

func select_region(region_name: String) -> void:
	# Сначала вернём всем исходный цвет
	for n in regions:
		regions[n].color = base_colors[n]
	# Выбранный регион светлее всех, соседи чуть светлее
	regions[region_name].color = base_colors[region_name].lightened(0.35)
	for n in neighbors[region_name]:
		regions[n].color = base_colors[n].lightened(0.12)
	var list := ", ".join(PackedStringArray(neighbors[region_name]))
	info_label.text = "Регион: %s\nСоседи: %s" % [region_name, list]
