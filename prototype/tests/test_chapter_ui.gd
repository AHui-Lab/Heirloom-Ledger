extends SceneTree

class LocalReply extends DemoLLMClient:
	var fail_next := false
	var last_instruction := ""
	func request_npc_reply(npc_name: String, _voice: String, _player: String, instruction: String, _history: Array[String], speaker: String = "npc") -> Error:
		last_instruction = instruction
		if fail_next:
			fail_next = false
			response_ready.emit.call_deferred(false, "", "本地模拟失败")
		else:
			response_ready.emit.call_deferred(true, "本地内心样例" if speaker == "inner" else npc_name + "的本地测试回应", "")
		return OK

var failures: Array[String] = []

func _initialize() -> void:
	_run.call_deferred()

func check(value: bool, label: String) -> void:
	if not value: failures.append(label)

func settle() -> void:
	await process_frame
	await process_frame

func _run() -> void:
	var scene = load("res://chapter.tscn").instantiate()
	root.add_child(scene)
	scene.is_test_mode = true
	scene.sound_enabled = false
	scene.motion_enabled = false
	scene.llm.queue_free()
	var stub := LocalReply.new()
	scene.add_child(stub)
	scene.llm = stub
	stub.response_ready.connect(scene._on_llm_response)
	scene._begin_day()
	await settle()
	for day in range(1, 11):
		check(scene.chapter.day == day, "UI advances to day %d" % day)
		for slot in range(4):
			check(not scene.awaiting_llm and scene.chapter.current_index == slot, "Ready guest %d/%d" % [day, slot])
			var guest: Dictionary = scene.chapter.current_guest
			if guest["role"] == "seller":
				scene._perform_action("source", {}, "请问这件怎么来的？")
				await settle()
				scene._perform_action("appraise", {}, "我先核对一下。")
				await settle()
				check(not "\n".join(scene.conversation_history).contains("本地内心样例"), "Private thoughts excluded from shared history")
				if scene.chapter.money >= int(guest["min_price"]):
					var before: int = scene.chapter.money
					stub.fail_next = true
					scene._perform_action("offer", {"amount": guest["min_price"]}, "我按这个价格收。")
					await settle()
					check(scene.reply_needs_retry and scene.send_button.disabled, "Failure freezes next transaction")
					scene._continue_flow()
					await settle()
					check(scene.chapter.money == before - int(guest["min_price"]), "Retry does not double pay")
			else:
				scene._perform_action("need", {}, "您具体想找哪一类？")
				await settle()
				for item in scene.chapter.inventory:
					if scene.chapter.get_match_level(item, guest) == "exact" and not item["custody"]:
						scene.chapter.select_item(item["id"])
						scene._perform_action("recommend", {}, "看看这件。")
						await settle()
						check(scene.suggestion_row.get_child_count() == 4, "Three editable answers displayed")
						scene.suggestion_row.get_child(1).pressed.emit()
						check(not scene.input_edit.text.is_empty(), "Draft goes into editable input")
						scene._send_free_text()
						await settle()
						if day == 1:
							scene.input_edit.text = "不卖了"
							scene._send_free_text()
							await settle()
							check(guest["completed"], "Decline after recommendation is not swallowed")
						else:
							scene._perform_action("offer", {"amount": guest["need"]["max_price"]}, "这是我的售价。")
							await settle()
						break
			if not guest["completed"]:
				scene._perform_action("decline", {}, "这次先不成交。")
				await settle()
			check(scene.continue_button.visible, "Completed visit has continuation")
			scene._continue_flow()
			await settle()
			if slot == 1:
				check(scene.chapter.phase == "noon", "Noon pause reached via UI")
				scene._continue_flow()
				await settle()
		check(scene.chapter.phase == "closing", "Closing reached via UI")
		for node in scene.chapter.available_story(): scene.chapter.choose_story(node["id"], node["choices"][0]["id"])
		if day < 10:
			scene._continue_flow()
			await settle()
		scene._refresh_all()
	scene._continue_flow()
	await settle()
	check(scene.modal.visible, "Final chapter choice modal reachable")
	scene.chapter.finish_chapter("sale")
	scene._ending_modal()
	check(scene.chapter.chapter_ending == "sale", "Full UI route supports authorized ending")
	scene.queue_free()
	await settle()
	if failures.is_empty(): print("PASS: complete ten-day UI walkthrough, failed trade retries, speaker isolation, editable answers, decline and ending; no external requests")
	else:
		for failure in failures: push_error(failure)
	quit(0 if failures.is_empty() else 1)
