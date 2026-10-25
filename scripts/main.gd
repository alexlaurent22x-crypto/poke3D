extends Node3D
## Presentation layer: CC0-derived adult meshes and original Art Deco scene assets.
const Poker = preload("res://scripts/poker.gd")
const Room = preload("res://scripts/casino_room.gd")
const Table = preload("res://scripts/table_visuals.gd")
const CHARACTER_PATHS = ["res://assets/characters/gabriel.glb", "res://assets/characters/gabriel.glb", "res://assets/characters/elise.glb", "res://assets/characters/nora.glb"]
const GOLD = Color("ddb975")
const INK = Color("141a2c")
var game = Poker.new()
var camera: Camera3D
var card_root: Node3D
var dealer_player: AnimationPlayer
var avatars: Array[Node3D] = []
var seat_labels: Array[Label3D] = []
var seats := [Vector3(0, 0, 2.35), Vector3(-3.15, 0, 0), Vector3(-0.85, 0, -2.35), Vector3(3.15, 0, 0)]
var headline: Label
var status: Label
var history: RichTextLabel
var hand_label: Label
var call_button: Button
var fold_button: Button
var raise_button: Button
var allin_button: Button
var peek_button: Button
var next_button: Button
var raise_amount: SpinBox
var sound: AudioStreamPlayer
var ai_clock := 0.0
var peek := false
var orbit := 0.22
var zoom := 6.1
var time := 0.0
var deal_tween: Tween
var previous_hand := 0
var previous_board := 0
var animation_busy := false
var muted := false
var room_environment: Environment
var high_quality := true

func _ready() -> void:
	build_room()
	build_ui()
	build_audio()
	game.changed.connect(refresh)
	game.new_hand()

func material(color: Color, metal := 0.0, rough := 0.6) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.metallic = metal
	mat.roughness = rough
	return mat

func shape(parent: Node3D, mesh: Mesh, pos: Vector3, mat: Material, size := Vector3.ONE) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.material_override = mat
	node.position = pos
	node.scale = size
	parent.add_child(node)
	return node

func box(parent: Node3D, pos: Vector3, size: Vector3, mat: Material) -> MeshInstance3D:
	return shape(parent, BoxMesh.new(), pos, mat, size)

func cylinder(parent: Node3D, pos: Vector3, radius: float, height: float, mat: Material, oval := 1.0) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 64
	return shape(parent, mesh, pos, mat, Vector3(1, 1, oval))

func label_3d(parent: Node3D, value: String, pos: Vector3, font_size := 40) -> Label3D:
	var label := Label3D.new()
	label.text = value
	label.position = pos
	label.font_size = font_size
	label.pixel_size = 0.003
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = false
	label.modulate = Color("f4e9d1")
	parent.add_child(label)
	return label

func build_room() -> void:
	var world := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("11151b")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("b8c0c8")
	environment.ambient_light_energy = 0.48
	environment.tonemap_mode = Environment.TONE_MAPPER_ACES
	environment.ssao_enabled = true
	environment.ssao_radius = 0.6
	environment.ssao_intensity = 1.3
	environment.glow_enabled = true
	environment.glow_intensity = 0.28
	room_environment = environment
	world.environment = environment
	add_child(world)
	Room.build(self)
	Table.build(self)
	for i in seats.size():
		var avatar := character(seats[i], CHARACTER_PATHS[i])
		avatars.append(avatar)
		seat_labels.append(label_3d(self, "", seats[i] + Vector3(0, 2.36, 0), 28))
		seat_labels[i].modulate = Color("c9c4b9")
		seat_labels[i].pixel_size = 0.0048
		if i == 0:
			seat_labels[i].position = seats[i] + Vector3(-0.75, 1.3, 0.1)
			seat_labels[i].font_size = 20
		chair(seats[i])
	var dealer := character(Vector3(1.15, 0.1, -2.3), "res://assets/characters/maya.glb")
	dealer.name = "CroupiereAdulte"
	dealer_player = dealer.find_child("AnimationPlayer", true, false) as AnimationPlayer
	label_3d(self, "MAYA  /  CROUPIÈRE", Vector3(1.15, 2.42, -2.3), 21)
	camera = Camera3D.new()
	camera.fov = 56
	camera.far = 45
	camera.current = true
	add_child(camera)
	update_camera()
	card_root = Node3D.new()
	card_root.name = "AnimatedCards"
	add_child(card_root)

func character(pos: Vector3, path: String) -> Node3D:
	var root := Node3D.new()
	root.name = "AdultAvatar"
	add_child(root)
	root.position = pos
	root.look_at(Vector3(0, pos.y, 0), Vector3.UP)
	var packed := load(path) as PackedScene
	var model := packed.instantiate() as Node3D
	root.add_child(model)
	var player := model.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if player and player.has_animation("idle"):
		player.get_animation("idle").loop_mode = Animation.LOOP_LINEAR
		player.play("idle")
	return root

func chair(pos: Vector3) -> void:
	var root := Node3D.new()
	add_child(root)
	root.position = pos
	root.look_at(Vector3(0, 0, 0), Vector3.UP)
	var leather := material(Color("152725"), 0.02, 0.64)
	var brass := material(Color("8b7046"), 0.75, 0.3)
	var seat := SphereMesh.new()
	seat.height = 0.22
	seat.radius = 0.43
	shape(root, seat, Vector3(0, 0.65, 0), leather, Vector3(1, 1, 0.95))
	var back := SphereMesh.new()
	back.height = 0.85
	back.radius = 0.42
	shape(root, back, Vector3(0, 1.05, 0.3), leather, Vector3(1, 1, 0.27))
	for x in [-0.3, 0.3]:
		cylinder(root, Vector3(x, 0.3, 0.18), 0.025, 0.6, brass)
		cylinder(root, Vector3(x, 0.3, -0.25), 0.025, 0.6, brass)
	for x in [-0.39, 0.39]:
		var armrest := SphereMesh.new()
		armrest.radius = 0.075
		armrest.height = 0.6
		var node := shape(root, armrest, Vector3(x, 0.92, 0), leather)
		node.rotation.x = PI / 2

func panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.018, 0.024, 0.029, 0.88)
	style.border_color = Color(0.62, 0.48, 0.27, 0.6)
	style.set_border_width_all(1)
	style.set_corner_radius_all(5)
	style.content_margin_left = 18
	style.content_margin_right = 18
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	return style

func ui_label(value: String, size: int, parent: Node) -> Label:
	var label := Label.new()
	label.text = value
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", Color("f1e7d5"))
	parent.add_child(label)
	return label

func button(value: String, parent: Node, callback: Callable) -> Button:
	var node := Button.new()
	node.text = value
	node.custom_minimum_size = Vector2(145, 44)
	node.add_theme_font_size_override("font_size", 18)
	var normal := panel_style()
	normal.bg_color = Color("24322f")
	node.add_theme_stylebox_override("normal", normal)
	var hover := normal.duplicate()
	hover.bg_color = Color("4c5343")
	node.add_theme_stylebox_override("hover", hover)
	node.pressed.connect(callback)
	parent.add_child(node)
	return node

func build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(root)
	var top := PanelContainer.new()
	top.position = Vector2(24, 20)
	top.size = Vector2(480, 90)
	top.add_theme_stylebox_override("panel", panel_style())
	root.add_child(top)
	var titles := VBoxContainer.new()
	top.add_child(titles)
	ui_label("M I N U I T   /   P O K E R", 24, titles).modulate = GOLD
	headline = ui_label("", 19, titles)
	ui_label("SALON PRIVÉ     /     TEXAS HOLD’EM     /     10–20", 14, titles)
	var side := PanelContainer.new()
	side.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	side.position = Vector2(-270, 20)
	side.size = Vector2(246, 230)
	side.add_theme_stylebox_override("panel", panel_style())
	root.add_child(side)
	var info := VBoxContainer.new()
	side.add_child(info)
	ui_label("LE SALON", 20, info).modulate = GOLD
	history = RichTextLabel.new()
	history.custom_minimum_size = Vector2(200, 58)
	history.add_theme_font_size_override("normal_font_size", 16)
	history.scroll_following = true
	info.add_child(history)
	var sound_button := button("Son : activé", info, func(): pass)
	sound_button.pressed.connect(func():
		muted = not muted
		sound_button.text = "Son : coupé" if muted else "Son : activé"
	)
	var quality_button := button("Rendu : élevé", info, func(): pass)
	quality_button.pressed.connect(func():
		high_quality = not high_quality
		room_environment.ssao_enabled = high_quality
		room_environment.glow_enabled = high_quality
		get_viewport().msaa_3d = Viewport.MSAA_2X if high_quality else Viewport.MSAA_DISABLED
		for node in find_children("TableKey*", "Light3D", true, false):
			node.shadow_enabled = high_quality
		quality_button.text = "Rendu : élevé" if high_quality else "Rendu : fluide"
	)
	button("Nouvelle partie", info, reset_game)
	var bottom := PanelContainer.new()
	bottom.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	bottom.offset_left = 24
	bottom.offset_right = -24
	bottom.offset_top = -190
	bottom.offset_bottom = -18
	bottom.add_theme_stylebox_override("panel", panel_style())
	root.add_child(bottom)
	var controls := VBoxContainer.new()
	controls.add_theme_constant_override("separation", 8)
	bottom.add_child(controls)
	status = ui_label("", 21, controls)
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hand_label = ui_label("", 23, controls)
	hand_label.modulate = GOLD
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	controls.add_child(row)
	fold_button = button("Passer [F]", row, func(): player_action("fold"))
	call_button = button("Suivre [C]", row, func(): player_action("check_call"))
	raise_amount = SpinBox.new()
	raise_amount.custom_minimum_size = Vector2(135, 44)
	raise_amount.step = 10
	raise_amount.max_value = 4000
	row.add_child(raise_amount)
	raise_button = button("Relancer [R]", row, func(): player_action("raise", int(raise_amount.value)))
	allin_button = button("Tapis", row, func(): player_action("raise", game.players[0].stack + game.players[0].bet))
	peek_button = button("Voir cartes [V]", row, toggle_peek)
	next_button = button("Main suivante", row, next_hand)
	ui_label("Mise = total engagé sur ce tour • Q / E : caméra • molette : zoom • V : cartes • Échap : quitter", 15, controls)

func build_audio() -> void:
	sound = AudioStreamPlayer.new()
	add_child(sound)

func play_sound(pitch: float = 1.0) -> void:
	if muted: return
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = 22050
	var bytes := PackedByteArray()
	bytes.resize(3308)
	for i in 1654:
		var t := float(i) / 22050.0
		var sample := sin(t * 2 * PI * 850 * pitch) * exp(-t * 65) * 0.16
		bytes.encode_s16(i * 2, int(sample * 32767))
	wav.data = bytes
	sound.stream = wav
	sound.play()

func player_action(action: String, amount := 0) -> void:
	if game.actor != 0 or animation_busy: return
	if game.act(action, amount): play_sound(0.7)

func toggle_peek() -> void:
	peek = not peek
	refresh_cards(false)
	update_hand_label()

func next_hand() -> void:
	if not game.finished or animation_busy: return
	peek = false
	game.new_hand()

func reset_game() -> void:
	if not game.finished:
		status.text = "Terminez cette main avant de recommencer la partie."
		return
	game = Poker.new()
	game.changed.connect(refresh)
	peek = false
	game.new_hand()

func refresh() -> void:
	ai_clock = 0.0
	var new_cards: bool = game.hand_no != previous_hand or game.board.size() != previous_board
	previous_hand = game.hand_no
	previous_board = game.board.size()
	headline.text = "Main %d   •   %s   •   Pot %d" % [game.hand_no, game.STREETS[game.street], game.paid_pot if game.finished else game.pot()]
	if game.finished:
		status.text = game.result
		if game.players[0].stack == 0: status.text += " · Vous êtes éliminé. Nouvelle partie pour rejouer."
	else:
		status.text = "À vous · %d à suivre · tapis %d" % [mini(game.to_call(0), game.players[0].stack), game.players[0].stack] if game.actor == 0 else "%s réfléchit…" % game.players[game.actor].name
	for i in 4:
		var p = game.players[i]
		seat_labels[i].text = "%s%s\n%d jetons · %s" % ["● " if game.actor == i else "", p.name, p.stack, "PASSÉ" if p.folded else ("TAPIS" if p.stack == 0 else "%d misés" % p.bet)]
		seat_labels[i].modulate = GOLD if game.actor == i else Color("dfddd9")
	history.text = "\n".join(game.log_lines.slice(maxi(0, game.log_lines.size() - 10)))
	var minimum: int = mini(game.minimum_target(), game.players[0].bet + game.players[0].stack)
	raise_amount.min_value = minimum
	raise_amount.max_value = game.players[0].bet + game.players[0].stack
	raise_amount.value = clampf(raise_amount.value, minimum, raise_amount.max_value)
	call_button.text = "Parole [C]" if game.to_call(0) == 0 else "Suivre %d [C]" % mini(game.to_call(0), game.players[0].stack)
	raise_button.text = "Miser [R]" if game.current_bet == 0 else "Relancer [R]"
	refresh_cards(new_cards)
	update_hand_label()
	update_buttons()

func update_hand_label() -> void:
	var hole: Array = game.players[0].hole
	hand_label.text = "Vos cartes : " + (Poker.cards_text(hole) if peek or game.revealed else "▧  ▧   — appuyez sur V pour regarder")
	if (peek or game.revealed) and hole.size() == 2 and game.board.size() >= 3:
		hand_label.text += "   •   " + Poker.hand_name(Poker.evaluate(hole + game.board))

func update_buttons() -> void:
	var turn: bool = game.actor == 0 and not game.finished and not animation_busy
	fold_button.disabled = not turn
	call_button.disabled = not turn
	raise_button.disabled = not turn or not game.can_raise(0)
	allin_button.disabled = raise_button.disabled
	raise_amount.editable = not raise_button.disabled
	next_button.disabled = not game.finished or animation_busy or game.players[0].stack <= 0

func card_mesh(card: int, visible_face: bool, target: Vector3, angle: float, delay: float) -> void:
	var root := Table.card(card_root, card, visible_face)
	root.rotation.y = angle
	if delay >= 0:
		root.position = Vector3(1.1, 1.75, -1.65)
		var tween := create_tween()
		tween.tween_interval(delay)
		tween.tween_callback(func(): play_sound(1.4))
		tween.tween_property(root, "position", target + Vector3(0, 0.2, 0), 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(root, "position", target, 0.15)
	else: root.position = target

func refresh_cards(animate: bool) -> void:
	for node in card_root.get_children():
		card_root.remove_child(node)
		node.queue_free()
	var delay := 0.0
	for i in 4:
		var p = game.players[i]
		if p.folded: continue
		var anchor: Vector3 = seats[i] * 0.57
		anchor.y = 1.372
		for j in p.hole.size():
			card_mesh(p.hole[j], (i == 0 and peek) or game.revealed, anchor + Vector3((j - 0.5) * 0.41, 0, 0), 0.0, delay if animate else -1.0)
			delay += 0.12
	for j in game.board.size():
		card_mesh(game.board[j], true, Vector3((j - 2) * 0.47, 1.372, -0.2), 0.0, delay if animate else -1.0)
		delay += 0.12
	# Bets and pot use reusable low-poly stacks.
	for i in 4:
		var p = game.players[i]
		var spot: Vector3 = seats[i] * 0.42
		for k in mini(10, int(ceil(p.bet / 20.0))):
			Table.chip(card_root, Vector3(spot.x + 0.42, 1.375 + k * 0.021, spot.z), [Color("c3af69"), Color("bf4561"), Color("6eaeb5")][k % 3], k % 3)
	if animate:
		if deal_tween: deal_tween.kill()
		animation_busy = true
		deal_tween = create_tween()
		if dealer_player and dealer_player.has_animation("deal"):
			dealer_player.play("deal", 0.12)
		deal_tween.tween_interval(delay + 0.6)
		deal_tween.tween_callback(func():
			animation_busy = false
			if dealer_player and dealer_player.has_animation("idle"): dealer_player.play("idle", 0.25)
			update_buttons()
		)

func update_camera() -> void:
	camera.position = Vector3(sin(orbit) * zoom, 2.95, cos(orbit) * zoom)
	camera.look_at(Vector3(0, 1.45, -0.4), Vector3.UP)

func _process(delta: float) -> void:
	time += delta
	if Input.is_physical_key_pressed(KEY_Q):
		orbit -= delta * 0.5
		update_camera()
	if Input.is_physical_key_pressed(KEY_E):
		orbit += delta * 0.5
		update_camera()
	if not game.finished and game.actor > 0 and not animation_busy:
		ai_clock += delta
		if ai_clock >= 1.05: game.ai_action()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP: zoom = maxf(3.8, zoom - 0.25)
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN: zoom = minf(7.0, zoom + 0.25)
		update_camera()
	if event is InputEventKey and event.pressed and not event.echo:
		match event.physical_keycode:
			KEY_V: toggle_peek()
			KEY_F: player_action("fold")
			KEY_C: player_action("check_call")
			KEY_R: player_action("raise", int(raise_amount.value))
			KEY_ESCAPE: get_tree().quit()
