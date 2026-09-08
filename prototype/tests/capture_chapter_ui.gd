extends SceneTree

class LocalReply extends DemoLLMClient:
	func request_npc_reply(_name: String, _personality: String, player: String,
			instruction: String, _history: Array[String], speaker: String = "npc") -> Error:
		var text := "这件东西我想再看看。来历和品相，还是得一项一项说清楚。"
		if player == "客人刚刚进店。":
			text = "家里收拾老宅，翻出一件东西。拿来请您看看，合适的话就留在您店里。" if instruction.contains("你是来出售的客人") else "我想找件合适的旧物，先看看，不一定今天买。"
		if speaker == "inner": text = "底足的磨痕有些过于一致。现在的线索还不够，我不能把家里的传闻当成保证。"
		response_ready.emit.call_deferred(true, text, "")
		return OK

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	root.size = Vector2i(1440, 900)
	root.gui_embed_subwindows = true
	var scene = load("res://chapter.tscn").instantiate()
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
	await screenshot("chapter_setup")
	scene._begin_day()
	await process_frame
	await process_frame
	await screenshot("chapter_counter")
	scene._perform_action("source", {}, "想问问这件东西是怎么来的。")
	await process_frame
	scene._perform_action("appraise", {}, "让我先看看器物。")
	await process_frame
	scene._perform_action("decline", {}, "这次先不收。")
	await process_frame
	scene._continue_flow()
	await process_frame
	scene._perform_action("need", {}, "您具体想找什么类别？")
	await process_frame
	scene.chapter.select_item("inkstone")
	scene._perform_action("recommend", {}, "您看看这方旧端砚。")
	await process_frame
	await screenshot("chapter_buyer")
	scene._item_modal(scene.chapter.get_inventory_item("inkstone"))
	await screenshot("chapter_item")
	scene.modal.hide()
	scene._perform_action("decline", {}, "您可以再考虑一下。")
	await process_frame
	scene._continue_flow()
	await process_frame
	scene._story_modal()
	await screenshot("chapter_story")
	scene.modal.hide()
	scene._market_modal()
	await screenshot("chapter_market")
	scene.modal.hide()
	scene.chapter.day = 3
	scene._auction_modal()
	await screenshot("chapter_auction")
	scene.modal.hide()
	scene._expert_modal()
	await screenshot("chapter_expert")
	scene.modal.hide()
	scene.chapter.day = 10
	scene.chapter.phase = "closing"
	scene.chapter.current_guest = {}
	scene.chapter.flags = {"consent": true, "catalogue": true}
	scene.chapter.finish_chapter("sale")
	scene._refresh_all()
	scene._ending_modal()
	await screenshot("chapter_ending")
	scene.modal.hide()
	root.size = Vector2i(1280, 800)
	scene.chapter.reset()
	scene.chapter.next_guest()
	scene.chapter.reveal_opening()
	scene.chapter.current_guest = scene.chapter.guests[1]
	scene._refresh_all()
	await screenshot("chapter_small")
	print("PASS: chapter views rendered with local simulated replies; no paid API calls")
	scene.queue_free()
	await process_frame
	quit(0)

func screenshot(name: String) -> void:
	await process_frame
	await process_frame
	var picture := root.get_texture().get_image()
	if picture == null:
		push_error("Rendering required")
		quit(1)
		return
	var error := picture.save_png("res://tests/artifacts/%s.png" % name)
	if error != OK: push_error("Screenshot failed")
