extends SceneTree
var failures := 0
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		printerr("FAIL: " + message)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var scene = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	await create_timer(2.5).timeout
	check(scene.camera != null and scene.card_root.get_child_count() > 0, "3D table loads and cards are dealt")
	check(scene.seat_labels.size() == 4, "four player avatars")
	for avatar in scene.avatars:
		var skeletons = avatar.find_children("*", "Skeleton3D", true, false)
		check(skeletons.size() == 1 and skeletons[0].get_bone_count() > 100, "adult skinned character loaded")
		var animation = avatar.find_child("AnimationPlayer", true, false)
		check(animation != null and animation.has_animation("idle") and animation.has_animation("deal"), "character animation clips imported")
	check(scene.dealer_player != null and scene.dealer_player.has_animation("deal"), "dealer has skeletal dealing animation")
	scene.peek_button.pressed.emit()
	check(scene.peek and not scene.hand_label.text.contains("▧"), "peek button reveals player cards")
	if "--capture" in OS.get_cmdline_user_args():
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("/tmp/poke3d-screenshot.png")
	var actions := 0
	while not scene.game.finished and actions < 150:
		scene.animation_busy = false
		if scene.game.actor == 0:
			scene.update_buttons()
			check(not scene.call_button.disabled, "call enabled on human turn")
			scene.call_button.pressed.emit()
		else: scene.game.ai_action()
		actions += 1
		await process_frame
	check(scene.game.finished, "UI and AI complete hand")
	check(not scene.game.result.is_empty(), "result displayed")
	await create_timer(3).timeout
	if scene.game.players[0].stack > 0:
		var old_hand: int = scene.game.hand_no
		scene.next_button.pressed.emit()
		check(scene.game.hand_no == old_hand + 1, "next-hand button")
	await create_timer(3).timeout
	# Exercise raise/fold, audio and quality controls through their real signals.
	for control in scene.find_children("*", "Button", true, false):
		if control.text.begins_with("Son :"):
			control.pressed.emit()
			check(scene.muted, "mute button")
			control.pressed.emit()
		if control.text.begins_with("Rendu :"):
			control.pressed.emit()
			check(not scene.room_environment.ssao_enabled and not scene.high_quality, "fluid quality toggle")
			var keys = scene.find_children("TableKey*", "Light3D", true, false)
			check(keys.size() == 2, "two named shadow-casting table lights")
			for light in keys: check(not light.shadow_enabled, "fluid mode disables nested shadow lights")
			control.pressed.emit()
	scene.game.finished = true
	scene.reset_game()
	var safety := 0
	while scene.game.actor != 0 and not scene.game.finished and safety < 50:
		scene.game.act("check_call")
		safety += 1
	scene.animation_busy = false
	scene.update_buttons()
	scene.raise_amount.value = scene.game.minimum_target()
	var target: int = scene.raise_amount.value
	scene.raise_button.pressed.emit()
	check(scene.game.current_bet == target and scene.game.players[0].bet == target, "raise button commits selected total")
	safety = 0
	while scene.game.actor != 0 and not scene.game.finished and safety < 50:
		scene.game.act("check_call")
		safety += 1
	scene.animation_busy = false
	scene.fold_button.pressed.emit()
	check(scene.game.players[0].folded, "fold button")
	await create_timer(3).timeout
	print("Scene: %d actions plus raise/fold/audio/quality controls, %d failures" % [actions, failures])
	scene.queue_free()
	await process_frame
	quit(1 if failures else 0)
