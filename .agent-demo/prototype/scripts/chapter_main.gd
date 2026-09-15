extends "res://scripts/main.gd"

const ChapterScript = preload("res://scripts/chapter_core.gd")
const SHOP = preload("res://assets/shop-v2.png")
const PORTRAITS = preload("res://assets/portraits-v3-alpha.png")
const OBJECTS = preload("res://assets/objects-v3-alpha.png")

var chapter: ChapterCore
var scene_heading: Label
var scene_subtitle: Label
var portrait_art: TextureRect
var object_art: TextureRect
var object_caption: Label
var character_caption: Label
var dialogue_title: Label
var suggestion_row: VBoxContainer
var stage: Control
var modal: AcceptDialog
var modal_body: VBoxContainer
var nav_buttons: Array[Button] = []
var log_history: Array[Dictionary] = []
var submitted_answer := false
var queued_action: Dictionary = {}
var sound_enabled := true
var motion_enabled := true
var bell: AudioStreamPlayer
var settings_button: Button
var loading_save := false
var is_test_mode := false
var resume_check: CheckButton
var returning_to_game := false
var retry_after_configuration := false

func _ready() -> void:
	get_viewport().gui_embed_subwindows = true
	get_window().title = "Heirloom Ledger — 第一章 · 旧账未清"
	chapter = _create_chapter_core()
	core = chapter
	llm = LLMClientScript.new()
	add_child(llm)
	llm.response_ready.connect(_on_llm_response)
	_build_theme()
	_build_layout()
	_build_modal()
	_build_sound()
	_refresh_all()
	_show_setup()
	resume_check = CheckButton.new()
	resume_check.text = "继续已有章节（取消勾选将开始新章并覆盖旧进度）"
	resume_check.button_pressed = FileAccess.file_exists("user://chapter_save.json")
	resume_check.disabled = not resume_check.button_pressed
	start_button.get_parent().get_parent().add_child(resume_check)
	for label in root_stack.find_children("*", "Label", true, false):
		if label.text == "一日试营业 · 对话判断玩法原型": label.text = "第一章 · 旧账未清"
	var privacy_hint := Label.new()
	privacy_hint.text = "第一章 · 10个营业日。API Key仅存内存；下方测试会调用你填写的服务。"
	privacy_hint.add_theme_font_size_override("font_size", 13)
	privacy_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	start_button.get_parent().get_parent().add_child(privacy_hint)

func _create_chapter_core() -> ChapterCore:
	return ChapterScript.new()

func _build_game_view() -> Control:
	var view := VBoxContainer.new()
	view.size_flags_vertical = SIZE_EXPAND_FILL
	var nav := HFlowContainer.new()
	nav.add_theme_constant_override("h_separation", 8)
	view.add_child(nav)
	for entry in [["库存", "inventory"], ["笔记", "knowledge"], ["人物", "people"], ["旧账", "story"], ["店外", "outside"], ["交易账本", "ledger"], ["保存进度", "save"], ["读取进度", "load"], ["设置", "settings"]]:
		var key := str(entry[1])
		var button := _make_button(str(entry[0]), false)
		button.custom_minimum_size.y = 36
		button.pressed.connect(func(): _navigate(key))
		nav.add_child(button)
		nav_buttons.append(button)
	var columns := HBoxContainer.new()
	columns.size_flags_vertical = SIZE_EXPAND_FILL
	columns.add_theme_constant_override("separation", 16)
	view.add_child(columns)
	stage = Control.new()
	stage.size_flags_horizontal = SIZE_EXPAND_FILL
	stage.size_flags_stretch_ratio = 1.15
	stage.custom_minimum_size.x = 520
	columns.add_child(stage)
	var background := TextureRect.new()
	background.texture = SHOP
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	stage.add_child(background)
	var shade := ColorRect.new()
	shade.color = Color(0.06, 0.05, 0.03, 0.22)
	shade.mouse_filter = MOUSE_FILTER_IGNORE
	shade.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	stage.add_child(shade)
	scene_heading = Label.new()
	scene_heading.add_theme_font_size_override("font_size", 29)
	scene_heading.add_theme_color_override("font_color", GOLD_LIGHT)
	# Scene labels are pure visuals; hotspots live on a lower layer and must stay clickable beneath them.
	scene_heading.mouse_filter = MOUSE_FILTER_IGNORE
	_place(scene_heading, stage, Rect2(0.04, 0.03, 0.92, 0.07))
	scene_subtitle = Label.new()
	scene_subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	scene_subtitle.add_theme_color_override("font_color", PAPER)
	scene_subtitle.add_theme_font_size_override("font_size", 15)
	scene_subtitle.mouse_filter = MOUSE_FILTER_IGNORE
	_place(scene_subtitle, stage, Rect2(0.04, 0.11, 0.90, 0.14))
	portrait_art = TextureRect.new()
	portrait_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait_art.mouse_filter = MOUSE_FILTER_IGNORE
	_place(portrait_art, stage, Rect2(0.03, 0.31, 0.53, 0.56))
	character_caption = Label.new()
	character_caption.add_theme_color_override("font_color", GOLD_LIGHT)
	character_caption.add_theme_font_size_override("font_size", 22)
	character_caption.mouse_filter = MOUSE_FILTER_IGNORE
	_place(character_caption, stage, Rect2(0.06, 0.86, 0.49, 0.05))
	object_art = TextureRect.new()
	object_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	object_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	object_art.mouse_filter = MOUSE_FILTER_IGNORE
	_place(object_art, stage, Rect2(0.59, 0.57, 0.35, 0.31))
	object_caption = Label.new()
	object_caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	object_caption.add_theme_font_size_override("font_size", 15)
	object_caption.add_theme_color_override("font_color", PAPER)
	object_caption.mouse_filter = MOUSE_FILTER_IGNORE
	_place(object_caption, stage, Rect2(0.57, 0.85, 0.41, 0.06))
	for target in [["货架", "inventory", Rect2(0.02, 0.25, 0.18, 0.05)], ["旧账本", "story", Rect2(0.04, 0.94, 0.22, 0.055)], ["台面物件", "item", Rect2(0.61, 0.94, 0.28, 0.055)], ["门口", "outside", Rect2(0.80, 0.28, 0.17, 0.055)]]:
		var key := str(target[1])
		var hotspot := _make_button(str(target[0]), false)
		hotspot.custom_minimum_size = Vector2.ZERO
		hotspot.pressed.connect(func(): _navigate(key))
		_place(hotspot, stage, target[2])
	var panel := PanelContainer.new()
	panel.custom_minimum_size.x = 490
	panel.size_flags_horizontal = SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", _panel_style(PANEL, Color("#5b503d"), 1, 10))
	columns.add_child(panel)
	var margin := MarginContainer.new()
	for edge in ["left", "right", "top", "bottom"]: margin.add_theme_constant_override("margin_" + edge, 18)
	panel.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	margin.add_child(box)
	dialogue_title = Label.new()
	dialogue_title.add_theme_font_size_override("font_size", 23)
	dialogue_title.add_theme_color_override("font_color", GOLD_LIGHT)
	box.add_child(dialogue_title)
	dialogue = RichTextLabel.new()
	dialogue.bbcode_enabled = false
	dialogue.scroll_following = true
	dialogue.size_flags_vertical = SIZE_EXPAND_FILL
	dialogue.add_theme_color_override("default_color", PAPER)
	dialogue.add_theme_font_size_override("normal_font_size", 18)
	box.add_child(dialogue)
	quick_actions = HFlowContainer.new()
	quick_actions.add_theme_constant_override("h_separation", 6)
	quick_actions.add_theme_constant_override("v_separation", 6)
	box.add_child(quick_actions)
	suggestion_row = VBoxContainer.new()
	box.add_child(suggestion_row)
	var input_row := HBoxContainer.new()
	box.add_child(input_row)
	input_edit = LineEdit.new()
	input_edit.placeholder_text = "与客人交谈，或编辑建议后发送……"
	input_edit.size_flags_horizontal = SIZE_EXPAND_FILL
	input_edit.custom_minimum_size.y = 42
	_style_line_edit(input_edit)
	input_edit.text_submitted.connect(func(_text): _send_free_text())
	input_row.add_child(input_edit)
	send_button = _make_button("发送", true)
	send_button.pressed.connect(_send_free_text)
	input_row.add_child(send_button)
	var deals := HBoxContainer.new()
	box.add_child(deals)
	price_spin = SpinBox.new()
	price_spin.min_value = 0
	price_spin.max_value = 999999
	# Quotes are currency integers.  A ten-yuan step silently rounded away the
	# user's unit digits in the previous prototype.
	price_spin.step = 1
	price_spin.prefix = "¥ "
	price_spin.custom_minimum_size.x = 135
	deals.add_child(price_spin)
	offer_button = _make_button("报价", true)
	offer_button.pressed.connect(func(): _perform_action("offer", {"amount": int(price_spin.value)}, "我出价¥%d。" % int(price_spin.value)))
	deals.add_child(offer_button)
	end_button = _make_button("不成交", false)
	end_button.pressed.connect(func(): _perform_action("decline", {}, "这次先不成交。"))
	deals.add_child(end_button)
	continue_button = _make_button("继续", true)
	continue_button.pressed.connect(_continue_flow)
	box.add_child(continue_button)
	toast_label = Label.new()
	toast_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	toast_label.add_theme_font_size_override("font_size", 13)
	toast_label.add_theme_color_override("font_color", GOLD_LIGHT)
	view.add_child(toast_label)
	return view

func _place(control: Control, parent: Control, rect: Rect2) -> void:
	parent.add_child(control)
	control.anchor_left = rect.position.x
	control.anchor_top = rect.position.y
	control.anchor_right = rect.end.x
	control.anchor_bottom = rect.end.y

func _atlas(texture: Texture2D, index: int, columns: int, rows: int) -> AtlasTexture:
	var atlas := AtlasTexture.new()
	atlas.atlas = texture
	var cell := texture.get_size() / Vector2(columns, rows)
	atlas.region = Rect2(Vector2(index % columns, index / columns) * cell, cell)
	return atlas

func _build_modal() -> void:
	modal = AcceptDialog.new()
	modal.min_size = Vector2i(620, 450)
	modal.ok_button_text = "返回"
	modal.add_theme_stylebox_override("panel", _panel_style(PANEL, GOLD, 1, 12))
	modal.add_theme_stylebox_override("embedded_border", _panel_style(PANEL, GOLD, 1, 12))
	modal.get_ok_button().custom_minimum_size = Vector2(150, 38)
	modal.get_ok_button().add_theme_font_size_override("font_size", 18)
	modal.get_ok_button().add_theme_stylebox_override("normal", _panel_style(GOLD, GOLD, 1, 6))
	modal.get_ok_button().add_theme_color_override("font_color", INK)
	add_child(modal)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(680, 460)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	modal.add_child(scroll)
	modal_body = VBoxContainer.new()
	modal_body.size_flags_horizontal = SIZE_EXPAND_FILL
	modal_body.add_theme_constant_override("separation", 12)
	scroll.add_child(modal_body)

func _open_modal(title: String) -> void:
	for child in modal_body.get_children():
		modal_body.remove_child(child)
		child.queue_free()
	modal.title = title
	modal.popup_centered(Vector2i(760, 600))

func _paragraph(value: String, size: int = 17) -> Label:
	var label := Label.new()
	label.text = value
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", PAPER)
	modal_body.add_child(label)
	return label

func _modal_button(value: String, callback: Callable, primary := false) -> Button:
	var button := _make_button(value, primary)
	button.pressed.connect(callback)
	modal_body.add_child(button)
	return button

func _modal_art(texture: Texture2D, index: int, columns: int, rows: int, height: int = 170) -> void:
	var art := TextureRect.new()
	art.texture = _atlas(texture, index, columns, rows)
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.custom_minimum_size = Vector2(180, height)
	modal_body.add_child(art)

func _navigate(key: String) -> void:
	match key:
		"inventory": _inventory_modal()
		"item": _item_modal(_active_item())
		"knowledge": _knowledge_modal()
		"people": _people_modal()
		"story": _story_modal()
		"outside": _outside_modal()
		"ledger": _ledger_modal()
		"save": _save_progress()
		"load": _load_progress()
		"settings": _settings_modal()

func _begin_day() -> void:
	setup_view.hide()
	game_view.show()
	review_view.hide()
	if returning_to_game:
		returning_to_game = false
		_refresh_all()
		if retry_after_configuration:
			retry_after_configuration = false
			_request_llm(pending_player_text, pending_instruction, pending_completed, pending_speaker)
		return
	if loading_save or (not is_test_mode and resume_check != null and resume_check.button_pressed):
		loading_save = false
		_load_progress()
		return
	chapter.reset()
	log_history.clear()
	conversation_history.clear()
	dialogue.clear()
	_append_system(chapter.day_info()["intro"])
	_refresh_all()
	_start_next_guest()

func _active_item() -> Dictionary:
	if not chapter.current_guest.is_empty() and chapter.current_guest.get("role") == "seller" and chapter.current_guest.get("role_revealed", false):
		return chapter.current_guest["item"]
	return chapter.get_inventory_item(chapter.selected_item_id)

func _refresh_all() -> void:
	header_money.text = "资金 ¥%s" % _format_number(chapter.money)
	header_inventory.text = "库存 %d件" % chapter.inventory.size()
	header_growth.text = "信誉 · %s" % chapter.global_trust
	header_phase.text = "第%d日 · %s" % [chapter.day, {"morning": "上午", "noon": "午间", "afternoon": "下午", "closing": "闭店"}.get(chapter.phase, "")]
	scene_heading.text = chapter.day_info()["theme"]
	scene_subtitle.text = chapter.day_info()["intro"]
	var guest := chapter.current_guest
	portrait_art.visible = not guest.is_empty()
	if not guest.is_empty():
		portrait_art.texture = _atlas(PORTRAITS, int(guest["portrait_index"]), 4, 2)
		character_caption.text = "%s · %s" % [guest["name"], chapter.relationship(guest["id"])]
		dialogue_title.text = "%s · %s" % [guest["name"], chapter.patience_label()]
	else:
		character_caption.text = "柜台暂歇"
		dialogue_title.text = "闭店小记" if chapter.phase == "closing" else "午间 · 店里店外"
	var item := _active_item()
	object_art.visible = not item.is_empty()
	object_caption.text = "点击货架选择物件" if item.is_empty() else str(item["title"])
	if not item.is_empty(): object_art.texture = _atlas(OBJECTS, int(item["art"]), 6, 4)
	_build_quick_actions()
	_set_game_controls(not awaiting_llm and not guest.is_empty() and not guest.get("completed", false))

func _build_quick_actions() -> void:
	for child in quick_actions.get_children():
		quick_actions.remove_child(child)
		child.queue_free()
	for child in suggestion_row.get_children():
		suggestion_row.remove_child(child)
		child.queue_free()
	if chapter.current_guest.is_empty() or not chapter.current_guest.get("role_revealed", false): return
	var actions: Array = [["问来历", "source"], ["问修补", "repair"], ["问动机", "motive"], ["观察", "inspect"], ["鉴定", "appraise"]] if chapter.current_guest["role"] == "seller" else [["问需求", "need"], ["问用途", "purpose"], ["问预算", "budget"], ["问年代", "era"], ["推荐库存", "select"]]
	if chapter.current_guest.get("offended", false): actions.append(["道歉", "apologize"])
	for pair in actions:
		var action := str(pair[1])
		var words := str(pair[0])
		var button := _make_button(words, false)
		button.custom_minimum_size.y = 32
		button.pressed.connect(func():
			if action == "select": _inventory_modal()
			else: _perform_action(action, {}, "我想%s。" % words))
		quick_actions.add_child(button)
	if chapter.current_guest["role"] == "buyer" and chapter.current_guest.has("recommended_item_id"):
		var hint := Label.new()
		hint.text = "回答参考 · 点选后可以改写，再发送"
		hint.add_theme_font_size_override("font_size", 13)
		hint.add_theme_color_override("font_color", GOLD_LIGHT)
		suggestion_row.add_child(hint)
		var drafts := chapter.answer_suggestions()
		for i in range(drafts.size()):
			var draft := drafts[i]
			var label: String = ["按来历记录说明", "按已见线索说明", "坦诚保留意见"][i]
			var button := _make_button(label, false)
			button.custom_minimum_size.y = 28
			button.tooltip_text = draft
			button.pressed.connect(func():
				submitted_answer = true
				input_edit.text = draft
				input_edit.grab_focus())
			suggestion_row.add_child(button)

func _start_next_guest() -> void:
	continue_button.hide()
	submitted_answer = false
	input_edit.clear()
	var guest := chapter.next_guest()
	conversation_history.clear()
	if guest.is_empty():
		_show_phase_break()
		return
	dialogue.clear()
	log_history.clear()
	_refresh_all()
	_append_system("%s走进店里。%s" % [guest["name"], guest["subtitle"]])
	var memories: Array = chapter.contacts[guest["id"]]["memories"]
	if not memories.is_empty(): _append_system("上次往来：%s" % memories.back())
	price_spin.value = int(guest.get("ask_price", 1000))
	_chime()
	if motion_enabled:
		portrait_art.modulate.a = 0
		create_tween().tween_property(portrait_art, "modulate:a", 1.0, 0.5)
	_request_llm("客人刚刚进店。", guest["opening_fact"], false)

func _perform_action(action: String, payload: Dictionary, player_text: String) -> void:
	if awaiting_llm or chapter.current_guest.is_empty() or chapter.current_guest.get("completed", false): return
	_append_player(player_text)
	var result := chapter.process_action(action, payload)
	_append_system(result["system_text"])
	_refresh_all()
	if result.get("speaker") == "system": return
	_request_llm(player_text, result["llm_instruction"], result.get("completed", false), result.get("speaker", "npc"))

func _send_free_text() -> void:
	if awaiting_llm: return
	var words := input_edit.text.strip_edges()
	if words.is_empty(): return
	input_edit.clear()
	var explicit_trade := words.begins_with("报价") or words.begins_with("出价") or words.begins_with("我出")
	var explicit_decline := words in ["不卖", "不卖了", "不买", "不买了", "不成交", "算了", "放弃", "不收", "请回"]
	if explicit_decline:
		submitted_answer = false
		_perform_action("decline", {}, words)
	elif explicit_trade:
		submitted_answer = false
		var action := chapter.classify_free_text(words)
		_perform_action(action["action"], action, words)
	elif submitted_answer or (chapter.current_guest.get("role") == "buyer" and chapter.current_guest.has("recommended_item_id") and not words.ends_with("？") and not words.ends_with("?")):
		submitted_answer = false
		_perform_action("respond", {"text": words}, words)
	else:
		var action := chapter.classify_free_text(words)
		_perform_action(action["action"], action, words)

func _request_llm(player_text: String, instruction: String, completed: bool, speaker := "npc") -> void:
	pending_mode = "npc"
	pending_player_text = player_text
	pending_instruction = instruction
	pending_completed = completed
	pending_speaker = speaker
	awaiting_llm = true
	reply_needs_retry = false
	_set_game_controls(false)
	toast_label.text = "正在整理心中判断……" if speaker == "inner" else "客人正在组织语言……"
	var guest := chapter.current_guest
	var history: Array[String] = conversation_history.duplicate()
	var authorized := instruction + "\n可用的既有公开背景：\n" + chapter.public_dialogue_context()
	# Voice is public manner only; original personality includes secret motives.
	var voice: String = chapter.person(guest["id"])["voice"]
	llm.request_npc_reply(guest["name"], voice, player_text, authorized, history, speaker)

func _on_llm_response(ok: bool, text_value: String, error_message: String) -> void:
	if pending_mode in ["test", "start_test"]:
		super._on_llm_response(ok, text_value, error_message)
		return
	if pending_mode != "npc": return
	pending_mode = ""
	if not ok:
		awaiting_llm = true
		reply_needs_retry = true
		_set_game_controls(false)
		toast_label.text = "对白未完成：%s" % error_message
		_append_system("%s\n重试不会重复交易结算。" % error_message)
		continue_button.text = "重试这一句"
		continue_button.show()
		return
	awaiting_llm = false
	reply_needs_retry = false
	if pending_speaker == "inner": _append_inner(text_value)
	else: _append_npc(text_value)
	if pending_player_text == "客人刚刚进店。": chapter.reveal_opening()
	_refresh_all()
	toast_label.text = ""
	if pending_completed:
		continue_button.text = "送别客人 · 继续"
		continue_button.show()
		_chime()
	_auto_save()

func _set_game_controls(enabled: bool) -> void:
	if input_edit == null: return
	input_edit.editable = enabled
	send_button.disabled = not enabled
	price_spin.editable = enabled
	offer_button.disabled = not enabled
	end_button.disabled = not enabled
	for child in quick_actions.get_children():
		if child is Button: child.disabled = not enabled
	for child in suggestion_row.get_children():
		if child is Button: child.disabled = not enabled

func _continue_flow() -> void:
	if reply_needs_retry:
		continue_button.hide()
		_request_llm(pending_player_text, pending_instruction, pending_completed, pending_speaker)
		return
	if awaiting_llm: return
	if chapter.phase == "noon":
		chapter.continue_afternoon()
		_start_next_guest()
	elif chapter.phase == "closing":
		if chapter.day == 10:
			_ending_modal()
		else:
			chapter.next_day()
			_append_system(chapter.day_info()["intro"])
			_start_next_guest()
	else: _start_next_guest()

func _show_phase_break() -> void:
	_refresh_all()
	var message := "上午来客已处理完。可以查库存、翻旧账，或出门看看；准备好再进入下午。"
	if chapter.phase == "closing":
		message = "今日收支 ¥%d，现有库存%d件。晚间可以整理记录和查看已知回访，再进入下一天。" % [chapter.money - chapter.day_start_money, chapter.inventory.size()]
	_append_system(message)
	if not chapter.available_story().is_empty(): _append_system("旧账或来信有新的内容，可以打开“旧账”查看。")
	if not chapter.consequences.is_empty(): _append_system("人物往来中有已知的售后反馈，可以在旧账页查看。")
	continue_button.text = "进入下午营业" if chapter.phase == "noon" else ("第一章 · 整理旧账" if chapter.day == 10 else "休息 · 开始下一日")
	continue_button.show()
	_auto_save()

func _append_line(speaker: String, words: String) -> void:
	dialogue.append_text("%s\n%s\n\n" % [speaker, words])
	log_history.append({"speaker": speaker, "text": words})

func _append_player(text_value: String) -> void:
	_append_line("你 · 掌柜", text_value)
	conversation_history.append("掌柜说：" + text_value)

func _append_npc(text_value: String) -> void:
	var name_value := str(chapter.current_guest.get("name", "客人"))
	_append_line(name_value, text_value)
	conversation_history.append(name_value + "说：" + text_value)

func _append_inner(text_value: String) -> void:
	_append_line("心中判断 · 未说出口", text_value)
	# Deliberately excluded from shared dialogue history.

func _append_system(text_value: String) -> void:
	_append_line("记事", text_value)

func _inventory_modal() -> void:
	_open_modal("货架 · 已有物件")
	if chapter.inventory.is_empty(): _paragraph("货架暂时空了。可以继续接待、查看古玩街，或在符合条件时接受基础看货委托。")
	var display_items := chapter.inventory.duplicate()
	if chapter.current_guest.get("role") == "buyer":
		display_items.sort_custom(func(a, b):
			return int(chapter.get_match_level(a, chapter.current_guest) == "exact") > int(chapter.get_match_level(b, chapter.current_guest) == "exact"))
	for item in display_items:
		var id := str(item["id"])
		var row := HBoxContainer.new()
		modal_body.add_child(row)
		var art := TextureRect.new()
		art.texture = _atlas(OBJECTS, int(item["art"]), 6, 4)
		art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		art.custom_minimum_size = Vector2(84, 84)
		row.add_child(art)
		var label := "%s · %s\n成本¥%d" % [item["title"], item["category"], item["cost"]]
		if item.get("custody", false): label += " · 暂存待核"
		var match_level := chapter.get_match_level(item, chapter.current_guest) if chapter.current_guest.get("role") == "buyer" else "unknown"
		if match_level == "exact": label += " · 类别符合公开需求"
		if chapter.current_guest.get("revealed", {}).has("budget"):
			var public_budget: int = chapter._extract_number(chapter.current_guest["facts"]["budget"])
			if item.get("appraised", false) and int(item.get("estimated_low", 0)) > public_budget:
				label += "\n当前粗估高于其公开价位，仍可拿来谈"
		var button := _make_button(label, match_level == "exact")
		button.size_flags_horizontal = SIZE_EXPAND_FILL
		button.pressed.connect(func():
			chapter.select_item(id)
			_refresh_all()
			_item_modal(chapter.get_inventory_item(id)))
		row.add_child(button)

func _item_modal(item: Dictionary) -> void:
	_open_modal("物件资料 · 查看不消耗耐心")
	if item.is_empty():
		_paragraph("还没有选中具体物件。请从库存选择，或等卖家说明来意。")
		return
	var id := str(item["id"])
	var art := TextureRect.new()
	art.texture = _atlas(OBJECTS, int(item["art"]), 6, 4)
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.custom_minimum_size = Vector2(240, 220)
	modal_body.add_child(art)
	_paragraph("%s · 确定类别：%s" % [item["title"], item["category"]], 24)
	_paragraph(item["description"], 15)
	_paragraph("年代判断：%s；不是后台真实年代。" % item["era"], 15)
	var source := str(item.get("public_provenance", ""))
	_paragraph("来历：" + (source if not source.is_empty() else "尚未取得来源记录，可以先向卖家询问。"))
	_paragraph("已发现线索：\n" + ("\n".join(item["revealed_clues"]) if not item["revealed_clues"].is_empty() else "尚未记录。"))
	if item["appraised"]:
		_paragraph("当前判断：" + ("判定为假" if item["judged_fake"] else "%d%%真品可能性，仍有不确定性" % item["probability"]))
		if item.has("estimated_low"):
			_paragraph("你的粗略议价参考：¥%d～%d。是当前判断下的宽区间，不代表市场保证价或买家预算。" % [item["estimated_low"], item["estimated_high"]], 15)
	for record in chapter.appraisal_history:
		if record["item_id"] == id:
			_paragraph("第%d日 · %s：%s" % [int(record.get("day", 1)), record["context"], "判定为假" if record.get("judged_fake", false) else "%d%%" % record["probability"]], 14)
	_paragraph("可以说明已知记录，也可以坦诚未知；不要把卖方说法或一条线索当成真伪保证。", 14)
	if not awaiting_llm and not chapter.current_guest.is_empty() and not chapter.current_guest.get("completed", false):
		_modal_button("查看实物 · 形成私人判断", func():
			chapter.select_item(id)
			modal.hide()
			_perform_action("appraise_inventory" if item["location"] == "inventory" else "appraise", {}, "我再核对一下这件东西。"))
		if chapter.current_guest["role"] == "buyer" and item["location"] == "inventory":
			_modal_button("拿到柜台，向客人推荐", func():
				chapter.select_item(id)
				modal.hide()
				_perform_action("recommend", {}, "您看看这件《%s》。" % item["title"]), true)

func _knowledge_modal() -> void:
	_open_modal("笔记 · 判断是怎样形成的")
	for category in chapter.skills:
		_paragraph("%s · 知识%d / 实际经验%d\n圈内评价：%s" % [category, chapter.skills[category], chapter.practice[category], chapter.category_reputation[category]], 19)
	_paragraph("观察、鉴定、与懂行者复核和真实售后发现带来不同经验。成长后要主动复核库存，旧记录不会自动改写。")
	for note in chapter.day_notes: _paragraph(str(note), 15)

func _people_modal() -> void:
	_open_modal("人物往来 · 各人记得各人的事")
	for actor in chapter.content["people"]:
		var contact: Dictionary = chapter.contacts[actor["id"]]
		if not contact["met"]: continue
		_modal_art(PORTRAITS, int(actor["portrait"]), 4, 2, 130)
		_paragraph("%s · %s · %s" % [actor["name"], actor["identity"], chapter.relationship(actor["id"])], 22)
		for memory in contact["memories"]: _paragraph(str(memory), 15)

func _story_modal() -> void:
	_open_modal("旧账 · 来信与后续消息")
	if not chapter.can_go_out():
		_paragraph("当前还有客人。可以查阅已经取得的线索；新来信和走访请等午间或闭店后处理。")
	else:
		for node in chapter.available_story():
			var node_id := str(node["id"])
			_paragraph(node["title"], 24)
			_paragraph("%s：%s" % [chapter.person(node["actor"])["name"], node["text"]])
			for choice in node["choices"]:
				var choice_id := str(choice["id"])
				_modal_button(choice["label"], func():
					chapter.choose_story(node_id, choice_id)
					_auto_save()
					_story_modal())
	for event in chapter.consequences:
		var event_id := str(event["id"])
		_paragraph("售后回访 · %s\n%s" % [["个人关系圈", "行业圈", "公众/市场圈"][int(event["stage"])], event["text"]], 18)
		if chapter.can_go_out() and not event["contained"]:
			for method in [["联系买家解释", "explain"], ["补充已有鉴定记录", "evidence"]]:
				var key := str(method[1])
				_modal_button(method[0], func():
					var result := chapter.intervene(event_id, key)
					_refresh_all()
					_auto_save()
					_story_modal()
					_paragraph(result))
	_paragraph("已取得的记录", 22)
	for note in chapter.day_notes: _paragraph(str(note), 15)
	if chapter.day_notes.is_empty(): _paragraph("尚未整理。午间可以翻看爷爷留下的账本。")

func _outside_modal() -> void:
	_open_modal("门外 · 古玩街与业内往来")
	if not chapter.can_go_out():
		_paragraph("先把眼前客人接待完。午间和闭店后可以外出，没有倒计时，也不会因为看得慢损失机会。")
		return
	_paragraph("店外机会有各自的物件和条件，货不会通过反复进出刷新。", 17)
	_modal_button("古玩街 · 看货与补货", _market_modal, true)
	_modal_button("许闻溪工作室 · 携库存复核（¥100）", _expert_modal)
	_modal_button("小型拍卖 · 预展与举牌（第三日起）", _auction_modal)
	if chapter.recovery_available():
		_modal_button("街坊基础看货委托 · 无需收购资金", func():
			var message := chapter.complete_recovery()
			_refresh_all()
			_auto_save()
			_outside_modal()
			_paragraph(message))

func _market_modal() -> void:
	_open_modal("古玩街 · 摊前看货")
	var item := chapter.market_item()
	if item.is_empty():
		_paragraph("这批货已经成交。摊主仍在与别人聊天，没有因为你回来就又变出一件。")
		return
	_paragraph("%s · 卖方要价¥%d" % [item["title"], item["ask"]], 24)
	_modal_art(OBJECTS, int(item["art"]), 6, 4)
	_paragraph("来源记录：%s 这是卖方陈述，还没有独立核实。" % item["source_claim"])
	_modal_button("查看、观察并形成判断", func():
		var result := chapter.inspect_outside(item["id"])
		_paragraph(result.get("system_text", "暂无法查看。"))
		_auto_save())
	var amount := SpinBox.new()
	amount.max_value = 999999
	amount.value = int(item["ask"])
	amount.step = 1
	amount.prefix = "收购报价 ¥"
	modal_body.add_child(amount)
	_modal_button("向摊主提出收购价", func():
		var result := chapter.market_buy(int(amount.value))
		_refresh_all()
		_auto_save()
		_market_modal()
		_paragraph(result), true)

func _expert_modal() -> void:
	_open_modal("许闻溪工作室 · 只为证据说话")
	_modal_art(PORTRAITS, 5, 4, 2)
	_paragraph("带一件库存物品共同复核，费用¥100，每天一次。许闻溪更擅长瓷器与书画，文房和杂项仅能提供有限观察方法；超出她能帮助的范围时不收费。不保证每次得到确定结论。")
	if chapter.flags.has("photo"):
		_modal_button("聊聊旧照与修护记录", _story_modal)
	for item in chapter.inventory:
		var id := str(item["id"])
		_modal_button("带《%s》请教" % item["title"], func():
			var result := chapter.consult(id)
			_refresh_all()
			_auto_save()
			_expert_modal()
			_paragraph(result))
	if chapter.inventory.is_empty(): _paragraph("目前没有可携带的库存。")

func _auction_modal() -> void:
	_open_modal("小型拍卖 · 举牌前先想好价")
	var sale := chapter.auction_preview()
	if sale.is_empty():
		_paragraph("目前没有开放的拍品。第三日起可以来预展，已经成交的物品不会重新出现。")
		return
	var item: Dictionary = chapter.all_items[sale["item_id"]]
	_paragraph("《%s》 · 当前¥%d" % [item["title"], sale["price"]], 24)
	_modal_art(OBJECTS, int(item["art"]), 6, 4)
	_paragraph("委托说明：%s\n成交另加5%%费用。退出不扣款。其他竞买人的预算不公开。" % item["source_claim"])
	if sale["done"]:
		_paragraph("本场结果：%s" % sale["outcome"])
		return
	_modal_button("预展看货 · 形成自己的判断", func():
		var result := chapter.inspect_outside(item["id"])
		_paragraph(result.get("system_text", "暂无法查看。"))
		_auto_save())
	var amount := SpinBox.new()
	amount.max_value = 999999
	amount.value = int(sale["price"]) + 100
	amount.step = 1
	amount.prefix = "举牌 ¥"
	modal_body.add_child(amount)
	_modal_button("确认举牌", func():
		var result := chapter.bid(int(amount.value))
		_refresh_all()
		_auto_save()
		_auction_modal()
		_paragraph(result), true)
	_modal_button("放下号牌，退出本场", func():
		chapter.leave_auction()
		_auto_save()
		_auction_modal())

func _ledger_modal() -> void:
	_open_modal("交易账本 · 每一笔都能对上")
	_paragraph("当前资金 ¥%d" % chapter.money, 24)
	for entry in chapter.ledger:
		_paragraph("第%d日 · %s · %s · ¥%d\n%s" % [int(entry.get("day", 1)), entry["type"], entry["item"], entry["amount"], entry.get("guest", "")], 16)

func _ending_modal() -> void:
	_open_modal("第一章 · 你怎样记下这笔账")
	if chapter.chapter_ending.is_empty():
		_paragraph("现在可以先返回检查旧账，也可以决定这一章怎样收束。没有取得的证据不会凭结局选项自动补齐。")
		for entry in [["补齐寄存，归还旧画", "return"], ["按授权和如实清单推进委托", "sale"], ["保留待查事项，结束这一章", "open"]]:
			var route := str(entry[1])
			var button := _modal_button(entry[0], func():
				chapter.finish_chapter(route)
				_refresh_all()
				_auto_save()
				_ending_modal())
			var reason := chapter.ending_requirement(route)
			button.disabled = not reason.is_empty()
			if not reason.is_empty(): _paragraph(reason, 14)
		_paragraph("委托路线：先归还旧画，再按授权结清一件非店铺库存的茶器。成交¥1800，付原主¥1620，店铺服务费¥180。本章固定议定价，非随机拍卖收益。", 14)
	else:
		var ending: Dictionary = chapter.content["endings"][chapter.chapter_ending]
		_paragraph(ending["title"], 28)
		_paragraph(ending["text"])
		_paragraph("期末资金¥%d，库存%d件。人物关系、经历和账本可继续查阅。" % [chapter.money, chapter.inventory.size()])
		_modal_button("开发复盘 · 查看本章后台（含剧透）", func():
			_open_modal("开发复盘 · 非正常玩家信息")
			for row in chapter.design_review_rows(): _paragraph("%s\n%s\n%s" % [row["name"], row["truth"], row["outcome"]]))

func _settings_modal() -> void:
	_open_modal("设置")
	var sound := CheckButton.new()
	sound.text = "轻量操作音效"
	sound.button_pressed = sound_enabled
	sound.toggled.connect(func(value): sound_enabled = value)
	modal_body.add_child(sound)
	var motion := CheckButton.new()
	motion.text = "人物入场动效"
	motion.button_pressed = motion_enabled
	motion.toggled.connect(func(value): motion_enabled = value)
	modal_body.add_child(motion)
	_modal_button("返回API配置（保留当前进度）", func():
		retry_after_configuration = awaiting_llm or reply_needs_retry
		llm.cancel_pending()
		pending_mode = ""
		awaiting_llm = false
		reply_needs_retry = false
		returning_to_game = true
		modal.hide()
		game_view.hide()
		setup_view.show())
	_paragraph("生成速度不推进游戏时间。API Key不会写入存档。故障诊断位于本机游戏数据目录的llm_diagnostics.jsonl。", 14)

func _auto_save() -> Error:
	if is_test_mode: return OK
	if awaiting_llm: return ERR_BUSY
	chapter.ui_state = {"log": log_history, "history": conversation_history, "sound": sound_enabled, "motion": motion_enabled}
	var error := chapter.save_game()
	if error != OK: toast_label.text = "保存失败（%d），请检查磁盘空间或权限。" % error
	return error

func _save_progress() -> void:
	if awaiting_llm:
		toast_label.text = "当前对白尚未完成，请先完成或重试这一句再保存。"
		return
	if _auto_save() == OK: toast_label.text = "进度已保存。"

func _load_progress() -> void:
	if awaiting_llm:
		toast_label.text = "先完成当前回应再读取进度。"
		return
	var error := chapter.load_game()
	if error != OK:
		toast_label.text = "没有可读取的完整存档（%d）。" % error
		if chapter.current_index == -1:
			setup_view.show()
			game_view.hide()
			setup_status.text = "存档未能载入（%d），未覆盖原文件。可取消“继续已有章节”以重新开始。" % error
		return
	dialogue.clear()
	log_history.clear()
	conversation_history.clear()
	var ui: Dictionary = chapter.ui_state
	if ui.get("log", []) is Array:
		for entry in ui.get("log", []):
			if entry is Dictionary and entry.get("speaker") is String and entry.get("text") is String:
				_append_line(entry["speaker"], entry["text"])
	if ui.get("history", []) is Array:
		for entry in ui.get("history", []):
			if entry is String: conversation_history.append(entry)
	sound_enabled = ui.get("sound", true) == true
	motion_enabled = ui.get("motion", true) == true
	submitted_answer = false
	input_edit.clear()
	_refresh_all()
	continue_button.visible = chapter.current_guest.is_empty() or chapter.current_guest.get("completed", false)
	continue_button.text = "继续营业流程"
	toast_label.text = "已恢复到第%d日，资金、物件和人物记录已载入。" % chapter.day

func _build_sound() -> void:
	bell = AudioStreamPlayer.new()
	add_child(bell)
	var wave := AudioStreamWAV.new()
	wave.format = AudioStreamWAV.FORMAT_16_BITS
	wave.mix_rate = 22050
	var samples := PackedByteArray()
	samples.resize(6600 * 2)
	for i in range(6600):
		var t := float(i) / 22050.0
		var value := int(2600.0 * sin(TAU * 880.0 * t) * exp(-t * 18.0))
		samples.encode_s16(i * 2, value)
	wave.data = samples
	bell.stream = wave

func _chime() -> void:
	if sound_enabled and bell != null: bell.play()
