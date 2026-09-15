extends SceneTree

func _initialize() -> void:
	call_deferred("_capture_views")

func _capture_views() -> void:
	var artifact_dir := ProjectSettings.globalize_path("res://tests/artifacts")
	DirAccess.make_dir_recursive_absolute(artifact_dir)
	root.size = Vector2i(1440, 900)
	var scene = load("res://main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame
	_save_view("setup.png")

	scene.setup_view.visible = false
	scene.game_view.visible = true
	scene.core.reset()
	scene.core.next_guest()
	scene.core.current_guest["role_revealed"] = true
	scene._refresh_all()
	scene.dialogue.clear()
	scene._append_system("上午，第一位客人走进店里。来意需要通过交谈确认。")
	scene._append_npc("家里最近收拾老宅，翻出一件旧东西。想着您这里懂行，先拿来请您掌掌眼。")
	await process_frame
	await process_frame
	_save_view("counter.png")
	scene._show_item_record()
	await process_frame
	await process_frame
	_save_view("item_record.png")
	scene.item_record_dialog.hide()

	for guest in scene.core.guests:
		guest["completed"] = true
		guest["outcome"] = "视觉验收示例"
	scene._show_closing()
	await process_frame
	await process_frame
	_save_view("review.png")
	quit(0)

func _save_view(filename: String) -> void:
	var image := root.get_texture().get_image()
	var path := ProjectSettings.globalize_path("res://tests/artifacts/%s" % filename)
	var error := image.save_png(path)
	if error != OK:
		push_error("Failed to save %s: %d" % [path, error])
	else:
		print("Captured %s" % path)
