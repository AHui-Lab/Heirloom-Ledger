extends "res://tests/capture_chapter_ui.gd"

func run() -> void:
	root.size = Vector2i(1440, 900)
	root.gui_embed_subwindows = true
	var scene = load("res://immersive.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	scene.is_test_mode = true
	scene.sound_enabled = false
	scene.motion_enabled = false
	scene.llm.queue_free()
	var stub := LocalReply.new()
	scene.add_child(stub)
	scene.llm = stub
	stub.response_ready.connect(scene._on_llm_response)
	await screenshot("immersive_setup")
	scene._begin_day()
	await process_frame
	await process_frame
	scene._perform_action("source", {}, "这件东西是怎么来的？")
	await process_frame
	await screenshot("immersive_dialogue")
	scene.suggestion_toggle.pressed.emit()
	await process_frame
	await screenshot("immersive_guidance_popup")
	scene.suggestion_panel.hide()
	scene.meeting_toggle.pressed.emit()
	await process_frame
	await screenshot("immersive_meeting_popup")
	scene.meeting_panel.hide()
	scene._toggle_bargaining()
	await process_frame
	await screenshot("immersive_bargaining")
	scene._toggle_bargaining()
	scene._perform_action("appraise", {}, "我先看看。")
	await process_frame
	await screenshot("immersive_private")
	scene.world.phase = "noon"
	scene.world.current_guest = {}
	scene._refresh_all()
	await screenshot("immersive_noon_progression")
	scene._go("market")
	await screenshot("immersive_market")
	for child in scene.stage.get_children():
		if child.get_meta("merchant_id", "") == "qingshan":
			child.mouse_entered.emit()
	await screenshot("immersive_market_hover")
	scene.scene_hint_popup.hide()
	scene.world.enter_merchant("qingshan")
	scene._render_location()
	scene._refresh_all()
	await screenshot("immersive_merchant")
	scene.world.view_merchant_item(scene.world.merchant_stock("qingshan")[0]["id"])
	scene._item_modal(scene.world.active_item())
	await screenshot("immersive_external_item")
	scene.modal.hide()
	scene._perform_action("appraise", {}, "我先上手看看。")
	await process_frame
	await process_frame
	scene._item_modal(scene.world.active_item())
	await screenshot("immersive_merchant_appraised")
	scene.modal.hide()
	scene.world.travel("market")
	scene.world.day = 3
	scene.world.phase = "noon"
	scene._go("auction")
	await screenshot("immersive_auction_preview")
	scene.world.start_auction()
	scene._render_location()
	await screenshot("immersive_auction_bidding")
	scene.world.travel("shop")
	scene.world.phase = "closing"
	scene.world.flags["ledger"] = true
	scene._go("tea")
	scene.world.meet_at_night("zhou")
	scene._refresh_all()
	scene._perform_action("show_item", {"item_id": "inkstone"}, "您看看这方砚。")
	await process_frame
	await screenshot("immersive_night")
	scene._notebook_modal()
	await screenshot("immersive_notebook")
	scene.modal.hide()
	scene._settings_modal()
	await screenshot("immersive_settings")
	scene.story_page = 2
	scene._show_prologue()
	await screenshot("immersive_photo")
	print("PASS: immersive UI rendered through shop, market, merchant, night and notebook; local replies only")
	scene.queue_free()
	await process_frame
	quit(0)
