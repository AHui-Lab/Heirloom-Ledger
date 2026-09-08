extends "res://scripts/chapter_main.gd"

const WorldScript = preload("res://scripts/immersive_core.gd")
const Profiles = preload("res://scripts/profile_settings.gd")
const Hotspot = preload("res://scripts/scene_hotspot.gd")
const MARKET = preload("res://assets/market-v3.png")
const TEAHOUSE = preload("res://assets/teahouse-v3.png")
const AUCTION_HALL = preload("res://assets/auction-hall-v1.png")
const OLD_PHOTO = preload("res://assets/old-photo-v3.png")
var world: ImmersiveCore
var chat_scroll: ScrollContainer
var chat_cards: VBoxContainer
var private_card: PanelContainer
var private_label: Label
var private_timer: Timer
var judgment_button: Button
var judgment_badge: Label
var judgment_unread: Dictionary = {}
var scene_panel: VBoxContainer
var scene_scroll: ScrollContainer
var scene_canvas: Control
var action_hint: Label
var story_page := 0
var prologue_pending := false
var confirming_button: Button
var cancel_trade_button: Button
var help_toggle: Button
var current_chat_actor := ""
var conversation_panel: Control
var stock_grid: GridContainer
var chat_toggle: Button
var scene_hint_popup: PanelContainer
var scene_hint_label: Label
var meeting_panel: PopupPanel
var meeting_summary_label: Label
var meeting_status_label: Label
var meeting_toggle: Button
var history_toggle: Button
var suggestion_panel: PopupPanel
var suggestion_scroll: ScrollContainer
var suggestion_toggle: Button
var trade_row: HBoxContainer
var confirm_row: HBoxContainer
var scene_back_button: Button
var scene_back_destination := "shop"
var thinking_card: Control
var dialogue_collapsed := false
var meeting_details_visible := false
var history_visible := true
var suggestion_visible := false
var bargaining_visible := false
var last_topic_status := "尚未执行操作"
var shop_hotspots: Array = []

func _create_chapter_core() -> ChapterCore:
	world = WorldScript.new()
	return world

func _ready() -> void:
	super._ready()
	get_window().title = "Heirloom Ledger — 旧账未清 · 场景与交谈"
	for label in setup_view.find_children("*", "Label", true, false):
		if "API Key仅存内存" in label.text: label.text = "首次填写后可加密保存配置；以后开门不必重复输入。"
	Profiles.add_controls(self)
	_profile_privacy_labels()
	modal.visibility_changed.connect(func():
		if prologue_pending and not modal.visible: _finish_prologue())

func _profile_privacy_labels() -> void:
	for label in setup_view.find_children("*", "Label", true, false):
		if "API Key（仅保存在本次运行内存中）" == label.text: label.text = "API Key（可选择本机加密保存）"

func _build_game_view() -> Control:
	var view := super._build_game_view()
	# chapter_main builds a small navigation row followed by the scene columns.
	# The room itself is the primary play space; the inherited nav is replaced by
	# discoverable hotspots and the gear button below.
	var nav: Control = view.get_child(0)
	nav.hide()
	var columns: HBoxContainer = view.get_child(1)
	# Chapter progression belongs beside the day/period display instead of a
	# detached full-width bar at the bottom of the painted room.
	continue_button.reparent(header_phase.get_parent())
	continue_button.custom_minimum_size = Vector2(150, 38)
	header_phase.get_parent().move_child(continue_button, header_phase.get_index() + 1)
	stage.custom_minimum_size.x = 720
	stage.clip_contents = true
	# Establish explicit scene layers.  Hotspots are interaction geometry, not
	# foreground artwork; portraits, objects and their captions must always win
	# the visual stack even when a hotspot polygon crosses them.
	stage.get_child(0).z_index = 0
	stage.get_child(1).z_index = 1
	portrait_art.z_index = 10
	object_art.z_index = 10
	character_caption.z_index = 11
	object_caption.z_index = 11
	conversation_panel = columns.get_child(1)
	conversation_panel.custom_minimum_size.x = 430
	# A single corner gear replaces the toolbar. Story/inventory navigation lives in the scene.
	var gear := _make_button("⚙", false)
	gear.tooltip_text = "设置 · 保存与读取 · API接入"
	gear.custom_minimum_size = Vector2(44, 40)
	gear.pressed.connect(_settings_modal)
	header_growth.get_parent().add_child(gear)
	for child in stage.get_children():
		if child is Button: child.hide()
	# These regions sit over the corresponding furniture already painted into the
	# shop background.  They provide discoverability without pasted-on labels.
	shop_hotspots = [
		_art_hotspot("货架 · 库存", [Vector2(.22,.045), Vector2(.36,.045), Vector2(.36,.72), Vector2(.22,.72)], _inventory_modal, SHOP.get_size()),
		_art_hotspot("货架 · 库存", [Vector2(.62,.045), Vector2(.76,.045), Vector2(.76,.55), Vector2(.62,.55)], _inventory_modal, SHOP.get_size()),
		_art_hotspot("出门 · 城中往来", [Vector2(.81,.07), Vector2(.965,.005), Vector2(.965,.65), Vector2(.87,.75), Vector2(.81,.73)], _travel_scene, SHOP.get_size()),
		_art_hotspot("账本 · 交易记录", [Vector2(.07,.835), Vector2(.14,.746), Vector2(.20,.74), Vector2(.22,.77), Vector2(.316,.77), Vector2(.324,.815), Vector2(.30,.90), Vector2(.155,.898)], _ledger_modal, SHOP.get_size()),
		_art_hotspot("笔记 · 剧情线索", [Vector2(.85,.846), Vector2(.94,.797), Vector2(1,.80), Vector2(1,.97), Vector2(.917,.97)], _notebook_modal, SHOP.get_size())
	]
	# A single tray-sized region on the counter replaces the old oversized block
	# that swallowed the visitor and the ledger.
	var table := _make_scene_hotspot("台面托盘 · 查看当前物件", Rect2(0.55, 0.63, 0.42, 0.27), func(): _item_modal(_active_item()))
	table.set_meta("shop_only", true)
	shop_hotspots.append(table)
	# Hotspot frames sit on the lowest layer, right above the background wash, so
	# their outlines never cross the visitor's portrait, captions or counter item.
	var layer := 2
	for hotspot in shop_hotspots:
		hotspot.z_index = 2
		hotspot.draw_frame = false
		stage.move_child(hotspot, layer)
		layer += 1
	_shop_scene_marker("库存", Rect2(.25, .09, .09, .05), _inventory_modal)
	_shop_scene_marker("出门", Rect2(.86, .10, .09, .05), _travel_scene)
	_shop_scene_marker("账本", Rect2(.10, .78, .10, .05), _ledger_modal)
	_shop_scene_marker("笔记", Rect2(.86, .79, .09, .05), _notebook_modal)
	chat_toggle = _make_button("‹ 收起交谈", false)
	chat_toggle.custom_minimum_size = Vector2(150, 38)
	chat_toggle.pressed.connect(_toggle_dialogue_panel)
	_place(chat_toggle, stage, Rect2(0.78, 0.035, 0.20, 0.065))

	dialogue.hide()
	var chat_parent := dialogue.get_parent()
	# Keep only identity and lightweight shortcuts above the conversation.
	var title_index := dialogue_title.get_index()
	chat_parent.remove_child(dialogue_title)
	var conversation_header := HBoxContainer.new()
	conversation_header.add_theme_constant_override("separation", 6)
	chat_parent.add_child(conversation_header)
	chat_parent.move_child(conversation_header, title_index)
	dialogue_title.size_flags_horizontal = SIZE_EXPAND_FILL
	conversation_header.add_child(dialogue_title)
	meeting_toggle = _make_button("资料", false)
	meeting_toggle.tooltip_text = "查看本次会面中已经公开的信息"
	meeting_toggle.custom_minimum_size = Vector2(58, 32)
	meeting_toggle.pressed.connect(_toggle_meeting_summary)
	conversation_header.add_child(meeting_toggle)
	history_toggle = _make_button("回到最新", false)
	history_toggle.tooltip_text = "回到本次交谈的最新一句"
	history_toggle.custom_minimum_size = Vector2(82, 32)
	history_toggle.pressed.connect(_toggle_history)
	conversation_header.add_child(history_toggle)
	var judgment_slot := Control.new()
	judgment_slot.custom_minimum_size = Vector2(66, 32)
	conversation_header.add_child(judgment_slot)
	judgment_button = _make_button("判断", false)
	judgment_button.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	judgment_button.tooltip_text = "查看当前物件的私人判断"
	judgment_button.pressed.connect(_open_current_judgment)
	judgment_slot.add_child(judgment_button)
	judgment_badge = Label.new()
	judgment_badge.text = "●"
	judgment_badge.mouse_filter = MOUSE_FILTER_IGNORE
	judgment_badge.add_theme_font_size_override("font_size", 15)
	judgment_badge.add_theme_color_override("font_color", Color("#e35d4f"))
	judgment_badge.z_index = 5
	judgment_badge.position = Vector2(49, -8)
	judgment_slot.add_child(judgment_badge)
	judgment_badge.hide()

	# Supporting information is a popup, not a vertical sibling of the chat.
	meeting_panel = PopupPanel.new()
	meeting_panel.min_size = Vector2i(500, 245)
	meeting_panel.max_size = Vector2i(500, 245)
	meeting_panel.add_theme_stylebox_override("panel", _panel_style(Color("#211f1ae8"), Color("#746042"), 1, 9))
	var meeting_box := VBoxContainer.new()
	meeting_box.add_theme_constant_override("separation", 5)
	meeting_box.custom_minimum_size.x = 470
	meeting_panel.add_child(meeting_box)
	var meeting_heading := Label.new()
	meeting_heading.text = "本次会面"
	meeting_heading.add_theme_font_size_override("font_size", 18)
	meeting_heading.add_theme_color_override("font_color", GOLD_LIGHT)
	meeting_box.add_child(meeting_heading)
	meeting_summary_label = Label.new()
	meeting_summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	meeting_summary_label.custom_minimum_size.x = 450
	meeting_summary_label.add_theme_font_size_override("font_size", 14)
	meeting_summary_label.add_theme_color_override("font_color", PAPER_DARK)
	meeting_summary_label.hide()
	meeting_box.add_child(meeting_summary_label)
	meeting_status_label = Label.new()
	meeting_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	meeting_status_label.add_theme_font_size_override("font_size", 13)
	meeting_status_label.add_theme_color_override("font_color", GOLD_LIGHT)
	meeting_box.add_child(meeting_status_label)
	var meeting_close := _make_button("收起资料", false)
	meeting_close.pressed.connect(func(): meeting_panel.hide())
	meeting_box.add_child(meeting_close)
	add_child(meeting_panel)
	meeting_panel.popup_hide.connect(func():
		meeting_details_visible = false
		meeting_summary_label.hide())
	chat_scroll = ScrollContainer.new()
	chat_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	chat_scroll.size_flags_vertical = SIZE_EXPAND_FILL
	chat_scroll.custom_minimum_size.y = 320
	chat_parent.add_child(chat_scroll)
	chat_parent.move_child(chat_scroll, title_index + 1)
	chat_cards = VBoxContainer.new()
	chat_cards.size_flags_horizontal = SIZE_EXPAND_FILL
	chat_cards.add_theme_constant_override("separation", 8)
	chat_scroll.add_child(chat_cards)
	# Newcomer guidance opens as a temporary palette above the composer. It never
	# changes chat height or scroll position.
	var suggestion_parent := suggestion_row.get_parent()
	suggestion_parent.remove_child(suggestion_row)
	var input_row := input_edit.get_parent()
	suggestion_toggle = _make_button("提问提示", false)
	suggestion_toggle.tooltip_text = "看看此刻可以怎样自然地开口"
	suggestion_toggle.custom_minimum_size = Vector2(86, 42)
	suggestion_toggle.pressed.connect(_toggle_suggestions)
	input_row.add_child(suggestion_toggle)
	input_row.move_child(suggestion_toggle, 0)
	suggestion_panel = PopupPanel.new()
	suggestion_panel.min_size = Vector2i(540, 280)
	suggestion_panel.max_size = Vector2i(540, 280)
	suggestion_panel.add_theme_stylebox_override("panel", _panel_style(Color("#211f1af7"), Color("#746042"), 1, 9))
	suggestion_scroll = ScrollContainer.new()
	suggestion_scroll.name = "SuggestionScroll"
	suggestion_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	suggestion_scroll.custom_minimum_size = Vector2(510, 230)
	suggestion_scroll.size_flags_vertical = SIZE_EXPAND_FILL
	suggestion_scroll.size_flags_horizontal = SIZE_EXPAND_FILL
	suggestion_panel.add_child(suggestion_scroll)
	suggestion_row.size_flags_horizontal = SIZE_EXPAND_FILL
	suggestion_scroll.add_child(suggestion_row)
	add_child(suggestion_panel)
	suggestion_scroll.hide()
	suggestion_panel.popup_hide.connect(func():
		suggestion_visible = false
		suggestion_scroll.hide()
		if suggestion_toggle != null: suggestion_toggle.text = "提问提示")
	private_card = PanelContainer.new()
	private_card.add_theme_stylebox_override("panel", _panel_style(Color("#29332e"), JADE, 1, 9))
	var private_box := VBoxContainer.new()
	private_box.add_theme_constant_override("separation", 2)
	private_card.add_child(private_box)
	private_label = Label.new()
	private_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	private_label.add_theme_font_size_override("font_size", 14)
	private_label.add_theme_color_override("font_color", PAPER)
	private_box.add_child(private_label)
	var private_hint := Label.new()
	private_hint.text = "判断详情 · 点击器物查看"
	private_hint.add_theme_font_size_override("font_size", 11)
	private_hint.add_theme_color_override("font_color", PAPER_DARK)
	private_box.add_child(private_hint)
	# Show the new thought briefly above the counter object. The full judgement
	# remains attached to the item and an unread dot stays in the header.
	private_card.z_index = 30
	private_card.clip_contents = true
	_place(private_card, stage, Rect2(0.56, 0.41, 0.40, 0.15))
	private_card.mouse_filter = MOUSE_FILTER_IGNORE
	private_card.hide()
	private_timer = Timer.new()
	private_timer.one_shot = true
	private_timer.wait_time = 4.5
	private_timer.timeout.connect(func(): private_card.hide())
	add_child(private_timer)
	action_hint = Label.new()
	action_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	action_hint.add_theme_font_size_override("font_size", 12)
	action_hint.text = ""
	chat_parent.add_child(action_hint)
	action_hint.hide()
	trade_row = price_spin.get_parent()
	trade_row.hide()
	end_button.hide()
	confirming_button = _make_button("确认钱货交割", true)
	confirming_button.pressed.connect(func(): _perform_action("confirm_trade", {}, "按刚才谈好的价格，咱们钱货交清。"))
	cancel_trade_button = _make_button("先不交割", false)
	cancel_trade_button.pressed.connect(func(): _perform_action("cancel_trade", {}, "这笔先不交割，我再考虑一下。"))
	confirm_row = HBoxContainer.new()
	confirm_row.add_theme_constant_override("separation", 8)
	confirm_row.add_child(confirming_button)
	confirm_row.add_child(cancel_trade_button)
	chat_parent.add_child(confirm_row)
	confirming_button.hide()
	cancel_trade_button.hide()
	price_spin.step = 1
	end_button.text = "结束会面"
	# External scenes use a compact lower action dock instead of a full-height
	# stack of buttons over the artwork.
	scene_canvas = Control.new()
	scene_canvas.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	scene_canvas.mouse_filter = MOUSE_FILTER_IGNORE
	stage.add_child(scene_canvas)
	scene_scroll = ScrollContainer.new()
	scene_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_place(scene_scroll, scene_canvas, Rect2(0.04, 0.66, 0.92, 0.29))
	scene_panel = VBoxContainer.new()
	scene_panel.size_flags_horizontal = SIZE_EXPAND_FILL
	scene_panel.add_theme_constant_override("separation", 6)
	scene_scroll.add_child(scene_panel)
	scene_canvas.hide()
	scene_back_button = _make_button("↩ 返回店铺", false)
	scene_back_button.custom_minimum_size = Vector2(150, 36)
	scene_back_button.z_index = 30
	scene_back_button.pressed.connect(func(): _go(scene_back_destination))
	_place(scene_back_button, scene_canvas, Rect2(.78, .025, .20, .06))
	scene_hint_popup = PanelContainer.new()
	scene_hint_popup.mouse_filter = MOUSE_FILTER_IGNORE
	scene_hint_popup.z_index = 40
	scene_hint_popup.add_theme_stylebox_override("panel", _panel_style(Color("#211f1af5"), GOLD_LIGHT, 1, 6))
	scene_hint_label = Label.new()
	scene_hint_label.add_theme_font_size_override("font_size", 14)
	scene_hint_label.add_theme_color_override("font_color", PAPER)
	scene_hint_popup.add_child(scene_hint_label)
	stage.add_child(scene_hint_popup)
	scene_hint_popup.hide()
	return view

func _shop_scene_marker(words: String, rect: Rect2, callback: Callable) -> void:
	var marker := _make_button(words, false)
	marker.set_meta("shop_only", true)
	marker.z_index = 3
	marker.add_theme_font_size_override("font_size", 14)
	marker.pressed.connect(callback)
	_place(marker, stage, rect)

func _toggle_suggestions() -> void:
	if suggestion_panel.visible:
		suggestion_panel.hide()
		return
	if meeting_panel != null and meeting_panel.visible: meeting_panel.hide()
	suggestion_visible = true
	suggestion_scroll.show()
	suggestion_toggle.text = "收起提示"
	_popup_near(suggestion_panel, input_edit, Vector2i(540, 280), true)

func _toggle_bargaining() -> void:
	bargaining_visible = not bargaining_visible
	if suggestion_panel != null and suggestion_panel.visible: suggestion_panel.hide()
	_refresh_all()
	if bargaining_visible: price_spin.get_line_edit().grab_focus()

func _apply_suggestion_visibility() -> void:
	if suggestion_panel == null or suggestion_scroll == null or suggestion_toggle == null: return
	var has_actions := suggestion_row != null and suggestion_row.get_child_count() > 0
	suggestion_toggle.visible = has_actions
	if not has_actions and suggestion_panel.visible: suggestion_panel.hide()
	if quick_actions != null: quick_actions.visible = quick_actions.get_child_count() > 0
	suggestion_toggle.text = "收起提示" if suggestion_panel.visible else "提问提示"

func _toggle_meeting_summary() -> void:
	if meeting_panel.visible:
		meeting_panel.hide()
		return
	if suggestion_panel != null and suggestion_panel.visible: suggestion_panel.hide()
	meeting_details_visible = true
	meeting_summary_label.show()
	_popup_near(meeting_panel, meeting_toggle, Vector2i(500, 245), false)

func _apply_meeting_summary_visibility() -> void:
	if meeting_panel == null or meeting_summary_label == null: return
	meeting_summary_label.visible = meeting_panel.visible

func _popup_near(popup: PopupPanel, anchor: Control, requested_size: Vector2i, above: bool) -> void:
	var viewport_size := Vector2i(get_viewport_rect().size)
	var width := mini(requested_size.x, viewport_size.x - 24)
	var height := mini(requested_size.y, viewport_size.y - 24)
	var anchor_pos := Vector2i(anchor.global_position)
	var x := clampi(anchor_pos.x + int(anchor.size.x) - width, 12, maxi(12, viewport_size.x - width - 12))
	var y := anchor_pos.y - height - 6 if above else anchor_pos.y + int(anchor.size.y) + 6
	y = clampi(y, 12, maxi(12, viewport_size.y - height - 12))
	popup.popup(Rect2i(x, y, width, height))

func _item_modal(item: Dictionary) -> void:
	_clear_judgment_unread(item)
	# The inherited panel reads current_guest while external meetings live in visit.
	var saved := world.current_guest
	world.current_guest = world.active_actor()
	super._item_modal(item)
	world.current_guest = saved
	if world.location.begins_with("merchant:") and not item.is_empty() and item.get("location") == "unseen":
		var price_hint := _paragraph("店家要价：¥%d。先鉴定，再出价；谈妥后确认交割。" % int(item["ask"]), 16)
		var quote := SpinBox.new()
		quote.min_value = 1
		quote.max_value = 999999
		quote.step = 1
		quote.value = int(item["ask"])
		quote.prefix = "¥ "
		modal_body.add_child(quote)
		var bid := _modal_button("向店家出价 / 还价", func():
			quote.apply()
			var amount := int(quote.value)
			modal.hide()
			dialogue_collapsed = false
			_perform_action("offer", {"amount": amount}, "这件我出%d元，您看可以吗？" % amount), true)
		bid.disabled = awaiting_llm or not item.get("appraised", false)
		# Keep purchase controls above the scrollable evidence, including after appraisal.
		modal_body.move_child(price_hint, 0)
		modal_body.move_child(quote, 1)
		modal_body.move_child(bid, 2)
		for child in modal_body.get_children():
			if child is Button and child.text == "查看物品 · 形成私人判断":
				modal_body.move_child(child, 3)
			if child is TextureRect: child.custom_minimum_size.y = 140
	if not world.visit.is_empty() and world.visit.get("role") == "social" and not item.is_empty():
		_modal_button("拿给对方一起看", func():
			world.select_item(item["id"])
			modal.hide()
			_perform_action("show_item", {"item_id": item["id"]}, "请您一起看看这件《%s》。" % item["title"]))

func _open_current_judgment() -> void:
	var item := _active_item()
	if item.is_empty():
		toast_label.text = "当前还没有正在查看的物件。"
		return
	_clear_judgment_unread(item)
	_item_modal(item)

func _judgment_key(item: Dictionary) -> String:
	return str(item.get("id", item.get("title", "")))

func _clear_judgment_unread(item: Dictionary) -> void:
	if item.is_empty(): return
	judgment_unread.erase(_judgment_key(item))
	_update_judgment_badge()

func _update_judgment_badge() -> void:
	if judgment_badge == null or judgment_button == null: return
	var item := _active_item()
	judgment_button.disabled = item.is_empty()
	judgment_badge.visible = not item.is_empty() and bool(judgment_unread.get(_judgment_key(item), false))

func _show_judgment_notice(words: String) -> void:
	var item := _active_item()
	if item.is_empty(): return
	judgment_unread[_judgment_key(item)] = true
	var brief := words.replace("\n", " ").strip_edges()
	if brief.length() > 92: brief = brief.left(92) + "……"
	private_label.text = "心里有了新的判断\n" + brief
	private_card.show()
	private_timer.start()
	_update_judgment_badge()

func _stock_card(title: String, detail: String, items: Array, callback: Callable) -> void:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _panel_style(Color("#29271feb"), Color("#756449"), 1, 10))
	if stock_grid != null: stock_grid.add_child(panel)
	else: scene_panel.add_child(panel)
	panel.size_flags_horizontal = SIZE_EXPAND_FILL
	var stack := VBoxContainer.new()
	panel.add_child(stack)
	var heading := _make_button(title, false)
	heading.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	heading.add_theme_font_size_override("font_size", 16)
	heading.alignment = HORIZONTAL_ALIGNMENT_LEFT
	heading.pressed.connect(callback)
	stack.add_child(heading)
	var note := Label.new()
	note.text = detail
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note.add_theme_font_size_override("font_size", 14)
	stack.add_child(note)
	var row := HBoxContainer.new()
	stack.add_child(row)
	for item in items.slice(0, 3):
		var tile := VBoxContainer.new()
		tile.size_flags_horizontal = SIZE_EXPAND_FILL
		row.add_child(tile)
		var art := TextureRect.new()
		art.texture = _atlas(OBJECTS, int(item["art"]), 6, 4)
		art.custom_minimum_size = Vector2(90, 92)
		art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tile.add_child(art)
		var label := Label.new()
		label.text = item["title"]
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.add_theme_font_size_override("font_size", 13)
		tile.add_child(label)

func _begin_day() -> void:
	if returning_to_game or loading_save or (resume_check != null and resume_check.button_pressed):
		super._begin_day()
		_render_location()
		_restore_chat()
		return
	if is_test_mode:
		super._begin_day()
		return
	setup_view.hide()
	game_view.show()
	world.reset()
	dialogue_collapsed = false
	history_visible = true
	last_topic_status = "等待客人说明来意"
	prologue_pending = true
	story_page = 0
	_show_prologue()

func _show_prologue() -> void:
	_open_modal("序章 · 可以慢慢读，也可以跳过")
	var page: Dictionary = world.revision_content["prologue"][story_page]
	_paragraph(page["title"], 28)
	_document_art(page)
	_paragraph(page["text"], 19)
	_modal_button("翻到下一页" if story_page < 3 else "把门打开，开始今天", func():
		if story_page < 3:
			story_page += 1
			_show_prologue()
		else: _finish_prologue(), true)
	_modal_button("先开始营业，资料保留在笔记里", _finish_prologue)

func _finish_prologue() -> void:
	prologue_pending = false
	modal.hide()
	super._begin_day()
	world.prologue_seen = true

func _start_next_guest() -> void:
	world.location = "shop"
	world.visit = {}
	dialogue_collapsed = false
	suggestion_visible = false
	bargaining_visible = false
	history_visible = true
	last_topic_status = "等待客人说明来意"
	private_card.hide()
	if meeting_panel != null: meeting_panel.hide()
	if suggestion_panel != null: suggestion_panel.hide()
	_clear_cards()
	super._start_next_guest()
	current_chat_actor = str(world.current_guest.get("id", ""))
	_render_location()

func _active_item() -> Dictionary:
	return world.active_item() if world != null else {}

func _process(_delta: float) -> void:
	if scene_hint_popup == null or not scene_hint_popup.visible or stage == null:
		return
	var cursor := stage.get_local_mouse_position() + Vector2(16, 16)
	var max_x := maxf(8.0, stage.size.x - scene_hint_popup.size.x - 8.0)
	var max_y := maxf(8.0, stage.size.y - scene_hint_popup.size.y - 8.0)
	scene_hint_popup.position = Vector2(clampf(cursor.x, 8.0, max_x), clampf(cursor.y, 8.0, max_y))

func _make_scene_hotspot(label: String, rect: Rect2, callback: Callable) -> Hotspot:
	var hotspot := Hotspot.new()
	hotspot.tooltip_text = label
	hotspot.mouse_entered.connect(func():
		var lines: Array[String] = []
		for paragraph in label.split("\n"):
			for start in range(0, maxi(1, paragraph.length()), 26):
				lines.append(paragraph.substr(start, 26))
		scene_hint_label.text = "\n".join(lines)
		scene_hint_label.custom_minimum_size = Vector2.ZERO
		scene_hint_label.autowrap_mode = TextServer.AUTOWRAP_OFF
		scene_hint_popup.reset_size()
		scene_hint_popup.show()
		scene_hint_popup.call_deferred("reset_size"))
	hotspot.mouse_exited.connect(func(): scene_hint_popup.hide())
	hotspot.pressed.connect(callback)
	_place(hotspot, stage, rect)
	return hotspot

func _art_hotspot(label: String, vertices: Array, callback: Callable, texture_size: Vector2) -> Hotspot:
	var hotspot := _make_scene_hotspot(label, Rect2(0, 0, 1, 1), callback)
	hotspot.outline = PackedVector2Array(vertices)
	hotspot.source_size = texture_size
	for state in ["normal", "hover", "focus", "pressed"]:
		hotspot.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	hotspot.queue_redraw()
	return hotspot

func _toggle_dialogue_panel() -> void:
	dialogue_collapsed = not dialogue_collapsed
	_apply_dialogue_visibility()

func _apply_dialogue_visibility() -> void:
	var actor := world.active_actor() if world != null else {}
	var available := not actor.is_empty()
	conversation_panel.visible = available and not dialogue_collapsed
	if stage != null and stage.get_child_count() > 1 and stage.get_child(1) is ColorRect:
		stage.get_child(1).color = Color(0.06, 0.05, 0.03, 0.42 if conversation_panel.visible else 0.22)
	if chat_toggle != null:
		chat_toggle.visible = available
		chat_toggle.text = "‹ 展开交谈" if dialogue_collapsed else "› 收起交谈"
	_update_hotspot_visibility()

func _update_hotspot_visibility() -> void:
	if stage == null or world == null or conversation_panel == null: return
	# Frames only exist in the shop with the conversation panel closed. While a
	# dialogue is open the scene is pure backdrop for the visitor and the item;
	# closing the panel brings every clickable region back.
	var show_frames := world.location == "shop" and not conversation_panel.visible
	for child in stage.get_children():
		if child.has_meta("market_dynamic"): continue
		if child is Hotspot or child.has_meta("shop_only"):
			child.visible = show_frames

func _toggle_history() -> void:
	# Conversation history is evidence in this game. Never hide it; this shortcut
	# simply returns the player to the newest exchange.
	history_visible = true
	_apply_history_visibility()
	_scroll_chat_to_bottom()

func _apply_history_visibility() -> void:
	if chat_cards == null:
		return
	for card in chat_cards.get_children(): card.visible = true
	if history_toggle != null:
		history_toggle.text = "回到最新"

func _meeting_summary(actor: Dictionary) -> String:
	if actor.is_empty():
		return "当前没有正在进行的会面。"
	var lines: Array[String] = []
	var id := str(actor.get("id", ""))
	var role := str(actor.get("role", "social"))
	var role_label := "卖货客人" if role == "seller" else ("买货客人" if role == "buyer" else "剧情往来")
	lines.append("对方：%s · %s" % [str(actor.get("name", "对方")), role_label])
	lines.append("关系：%s" % world.relationship(id))
	if role == "seller":
		var item: Dictionary = actor.get("item", {})
		if not item.is_empty():
			lines.append("正在谈：%s · %s" % [str(item.get("title", "未命名")), str(item.get("category", "未知"))])
			lines.append("对方开价：¥%d" % int(actor.get("ask_price", 0)))
	elif role == "buyer":
		var revealed: Dictionary = actor.get("revealed", {})
		var need: Dictionary = actor.get("need", {})
		lines.append("公开需求：%s · 预算：%s" % [str(need.get("category", "尚待交谈")) if revealed.has("need") else "尚待交谈", str(need.get("public_budget", "尚不明确")) if revealed.has("budget") else "尚不明确"])
		if not str(actor.get("recommended_item_id", "")).is_empty():
			var recommended := world.get_inventory_item(str(actor["recommended_item_id"]))
			if not recommended.is_empty(): lines.append("已推荐：%s（%s）" % [recommended["title"], recommended["category"]])
	else:
		lines.append("正在聊：已经发生的往来与手头线索")
	var topics: Array[String] = []
	var topic_names := {"source": "来历", "repair": "修补/品相", "price": "心理价", "motive": "来意", "need": "类别需求", "purpose": "用途", "budget": "预算", "era": "年代偏好", "story": "剧情线索", "trade": "过往交易", "method": "鉴定方法"}
	for topic in actor.get("revealed", {}).keys():
		topics.append(str(topic_names.get(str(topic), topic)))
	if not topics.is_empty(): lines.append("已经谈到：" + "、".join(topics))
	else: lines.append("目前还没有问到具体情况。")
	return "\n".join(lines)

func _set_topic_status(action: String, result: Dictionary) -> void:
	if action == "offer": bargaining_visible = true
	var labels := {"source": "来历", "repair": "修补/品相", "price": "心理价", "motive": "来意", "need": "类别需求", "purpose": "用途", "budget": "预算", "era": "年代偏好", "inspect": "表面观察", "appraise": "正式鉴定", "appraise_inventory": "库存复核", "recommend": "推荐物件", "respond": "回答买家", "story_prompt": "剧情线索", "social": "剧情交流", "offer": "交易报价", "confirm_trade": "钱货交割", "decline": "结束会面"}
	var label := str(labels.get(action, "本轮交流"))
	if result.get("trade_pending", false):
		last_topic_status = "交易报价 · 双方价格已谈妥，等待明确确认交割"
	elif bool(result.get("completed", false)) and action in ["offer", "confirm_trade"]:
		last_topic_status = "交易报价 · 已完成钱货交割"
	elif action in ["appraise", "appraise_inventory", "inspect"]:
		last_topic_status = "%s · 已记在当前物件中" % label
	elif action in ["source", "repair", "price", "motive", "need", "purpose", "budget", "era", "story_prompt", "social"]:
		last_topic_status = "%s · 这是对方的说法，还要结合线索判断" % label
	else:
		last_topic_status = label

func _refresh_all() -> void:
	super._refresh_all()
	if world == null or chat_cards == null: return
	var actor := world.active_actor()
	_apply_dialogue_visibility()
	portrait_art.visible = not actor.is_empty()
	if not actor.is_empty():
		portrait_art.texture = _atlas(PORTRAITS, int(actor["portrait_index"]), 4, 2)
		character_caption.text = str(actor["name"])
		var active_item := world.active_item()
		var item_context := " · %s" % str(active_item.get("title", "")) if not active_item.is_empty() else ""
		dialogue_title.text = "%s · %s%s" % [actor["name"], world.relationship(actor["id"]), item_context]
	else:
		dialogue_title.text = "尚未开始交谈"
		character_caption.text = "柜台暂歇"
	if meeting_summary_label != null:
		meeting_summary_label.text = _meeting_summary(actor)
		meeting_status_label.text = "本轮状态：" + last_topic_status
	_apply_meeting_summary_visibility()
	if action_hint != null:
		if actor.get("role", "") == "social" and world.location.begins_with("night:") and not world.story_nodes_for(str(actor.get("id", ""))).is_empty():
			action_hint.text = "剧情推进请点击“正事”选项；下方输入保留给闲聊和回顾，不需要猜该说什么。"
		elif world.location.begins_with("merchant:") and actor.get("role", "") == "seller":
			var focus_item := world.active_item()
			var focus_text := "当前物件：《%s》。" % str(focus_item.get("title", "尚未指定")) if not focus_item.is_empty() else "当前还没有指定物件。"
			action_hint.text = focus_text + "先点击商品卡片指定目标；下面的问题按钮可直接使用，也可以自行输入。"
		else:
			action_hint.text = "自由交谈不受限制；相关资料、剧情提示和交易状态会集中显示。"
	confirming_button.visible = not world.pending_trade.is_empty() and not awaiting_llm
	cancel_trade_button.visible = confirming_button.visible
	confirm_row.visible = confirming_button.visible
	_set_game_controls(not awaiting_llm and not actor.is_empty() and not actor.get("completed", false) and world.pending_trade.is_empty())
	confirming_button.disabled = awaiting_llm
	cancel_trade_button.disabled = awaiting_llm
	var trade_visible: bool = not actor.is_empty() and str(actor.get("role", "social")) in ["seller", "buyer"] and bool(actor.get("role_revealed", false)) and not bool(actor.get("completed", false))
	trade_row.visible = trade_visible and bargaining_visible and world.pending_trade.is_empty()
	price_spin.visible = trade_row.visible
	offer_button.visible = trade_row.visible
	end_button.hide()
	_update_judgment_badge()
	if not world.pending_trade.is_empty():
		confirming_button.text = "确认交割 · ¥%d" % int(world.pending_trade["amount"])
	if not world.visit.is_empty(): continue_button.hide()
	if world.location != "shop":
		if world.location == "market":
			scene_heading.text = "槐安古玩市场"
			scene_subtitle.text = "老店沿街，散摊在廊下。先看各家主营与主打品，再进去慢慢看货。"
		elif world.location.begins_with("merchant:"):
			scene_heading.text = world.merchants[world.visit_subject]["name"]
			scene_subtitle.text = world.merchants[world.visit_subject]["description"]
		elif world.location == "auction":
			var sale := world.auction_preview()
			if sale.get("phase", "preview") == "preview":
				scene_heading.text = "槐安小拍 · 预展"
				scene_subtitle.text = "先翻图录、看实物并标记关注。"
			elif sale.get("phase", "") == "bidding":
				var lot := world.current_auction_lot()
				scene_heading.text = "槐安小拍 · %02d号拍品" % int(lot.get("lot_number", 0))
				scene_subtitle.text = "逐件竞价；可以举牌、放弃本件或提前离场。"
			else:
				scene_heading.text = "槐安小拍 · 散场"
				scene_subtitle.text = str(sale.get("outcome", "本场竞价已经结束。"))
		elif world.location == "tea":
			scene_heading.text = "听雨茶馆"
			scene_subtitle.text = "今晚谁在馆里要看缘分；不在馆里的人，得登门去拜访。"
		elif world.location == "visits":
			scene_heading.text = "登门拜访"
			scene_subtitle.text = "不在茶馆的人要单独登门。与旧账相关的正事优先。"
		elif world.location.begins_with("night:"):
			scene_heading.text = "夜间往来"
			scene_subtitle.text = "今晚不急着买卖，可以坐下来聊聊，也可以拿件旧物共同看货。"
		continue_button.hide()
		object_art.hide()
		portrait_art.hide()
		character_caption.hide()
		object_caption.hide()
		if world.location.begins_with("night:") and not actor.is_empty():
			portrait_art.show()
	else:
		character_caption.visible = not actor.is_empty()
		object_caption.show()
		if actor.is_empty() and world.phase in ["noon", "closing"]:
			continue_button.text = "进入下午营业" if world.phase == "noon" else ("第一章 · 整理旧账" if world.day == 10 else "休息 · 开始下一日")
			continue_button.show()
	_apply_history_visibility()

func _build_quick_actions() -> void:
	if world == null: return
	for container in [quick_actions, suggestion_row]:
		for child in container.get_children():
			container.remove_child(child)
			child.queue_free()
	var actor := world.active_actor()
	if actor.is_empty(): return
	var options: Array = []
	if actor["role"] == "seller":
		options = [["查看物品", "inspect"], ["形成判断", "appraise"]]
	elif actor["role"] == "buyer":
		options = [["拿一件库存给对方看", "select"]]
	else:
		options = [["回顾已发生往来", "social", {"topic": "trade"}], ["聊聊鉴定方法", "social", {"topic": "method"}], ["拿库存一起看", "select"]]
	for option in options:
		var action := str(option[1])
		var option_payload: Dictionary = option[2] if option.size() > 2 and option[2] is Dictionary else {}
		var option_text := str(option[0])
		var button := _make_button(option[0], false)
		button.pressed.connect(func():
			if action == "select": _inventory_modal()
			else: _perform_action(action, option_payload, option_text))
		quick_actions.add_child(button)
	if str(actor.get("role", "social")) in ["seller", "buyer"] and bool(actor.get("role_revealed", false)):
		var bargain_button := _make_button("收起议价" if bargaining_visible else "开始议价", false)
		bargain_button.pressed.connect(_toggle_bargaining)
		quick_actions.add_child(bargain_button)
		var leave_button := _make_button("结束会面", false)
		leave_button.tooltip_text = "不成交并结束这次会面"
		leave_button.pressed.connect(func(): _perform_action("decline", {}, "今天先不成交了。"))
		quick_actions.add_child(leave_button)
	# Newcomer guidance: ready-made questions that send a full sentence with one
	# click, so nobody has to guess what can be typed.
	var chips: Array = []
	if actor["role"] == "seller" and not actor.get("item", {}).is_empty():
		chips = [
			["这件东西您是怎么得来的？", "source", "这件东西您是怎么得来的？手里还留着什么凭据吗？"],
			["上手前有人修过吗？", "repair", "这件东西以前磕碰过没有？上手前有人修过吗？"],
			["您想按什么价出？", "price", "您这次想按什么价出？我也好心里有个数。"],
			["怎么突然想着出手？", "motive", "这东西留了些时候吧，怎么突然想着出手了？"]]
	elif actor["role"] == "buyer":
		chips = [
			["您今天想看哪一类？", "need", "您今天主要想看哪一类东西？我先替您挑几件合适的。"],
			["是自用还是送人？", "purpose", "这件是准备自己留着，还是另有用处？"],
			["价钱大概看到哪里？", "budget", "价钱上您大概看到哪里？我按这个范围给您找。"],
			["年代上有什么讲究？", "era", "年代上您有没有什么讲究，还是东西合眼就行？"]]
	if not chips.is_empty():
		var chips_title := Label.new()
		chips_title.text = "不知道怎么开口时，可以顺着这些话往下问"
		chips_title.add_theme_font_size_override("font_size", 12)
		chips_title.add_theme_color_override("font_color", GOLD_LIGHT)
		suggestion_row.add_child(chips_title)
		for chip in chips:
			var chip_action := str(chip[1])
			var chip_text := str(chip[2])
			var chip_button := _make_button(str(chip[0]), false)
			chip_button.custom_minimum_size.y = 28
			chip_button.tooltip_text = chip_text
			chip_button.pressed.connect(func():
				input_edit.text = chip_text
				input_edit.caret_column = input_edit.text.length()
				input_edit.grab_focus()
				suggestion_panel.hide())
			suggestion_row.add_child(chip_button)
	# Story people advance the old-ledger plot with click choices, not typing;
	# free conversation stays available for small talk and reviewing past deals.
	if actor["role"] == "social":
		var actor_id := str(actor.get("id", ""))
		var story_nodes: Array = world.story_nodes_for(actor_id)
		if not story_nodes.is_empty():
			var choice_title := Label.new()
			choice_title.text = "正事 · 点击选择即推进，不用打字"
			choice_title.add_theme_font_size_override("font_size", 12)
			choice_title.add_theme_color_override("font_color", GOLD_LIGHT)
			suggestion_row.add_child(choice_title)
			for node in story_nodes:
				var node_id := str(node.get("id", ""))
				var node_title := str(node.get("title", ""))
				var node_text := str(node.get("text", ""))
				for choice in node.get("choices", []):
					var choice_id := str(choice.get("id", ""))
					var choice_label := str(choice.get("label", ""))
					var choice_button := _make_button("%s：%s" % [node_title, choice_label], false)
					choice_button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
					choice_button.add_theme_font_size_override("font_size", 13)
					choice_button.pressed.connect(func():
						if world.choose_story(node_id, choice_id):
							_append_system("【%s】%s\n你的选择：%s" % [node_title, node_text, choice_label])
							_refresh_all()
							_auto_save())
					suggestion_row.add_child(choice_button)
	var prompts: Array = world.story_prompt_actions(str(actor.get("id", "")))
	if not prompts.is_empty():
		var prompt_title := Label.new()
		prompt_title.text = "剧情提问 · 可选，不影响自由交谈"
		prompt_title.add_theme_font_size_override("font_size", 12)
		prompt_title.add_theme_color_override("font_color", GOLD_LIGHT)
		suggestion_row.add_child(prompt_title)
		for prompt in prompts:
			var prompt_label := str(prompt.get("label", "谈谈当前线索"))
			var prompt_text := str(prompt.get("text", "我想问问这件事。"))
			var story_button := _make_button(prompt_label, false)
			story_button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			story_button.add_theme_font_size_override("font_size", 13)
			story_button.tooltip_text = prompt_text
			story_button.pressed.connect(func(): _perform_action("story_prompt", {"prompt": prompt_text, "node_id": prompt.get("node_id", "")}, prompt_text))
			suggestion_row.add_child(story_button)
	if actor["role"] == "buyer" and actor.has("recommended_item_id"):
		for draft in world.contextual_answers():
			var value := str(draft)
			var button := _make_button(value, false)
			button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			button.add_theme_font_size_override("font_size", 14)
			button.pressed.connect(func():
				submitted_answer = true
				input_edit.text = value
				input_edit.grab_focus())
			suggestion_row.add_child(button)
	_apply_suggestion_visibility()

func _perform_action(action: String, payload: Dictionary, player_text: String) -> void:
	if awaiting_llm: return
	if world.location.begins_with("merchant:") or world.location.begins_with("night:"):
		dialogue_collapsed = false
	var actor := world.active_actor()
	if actor.is_empty() or actor.get("completed", false): return
	if action not in ["inspect", "appraise", "appraise_inventory"]: _append_player(player_text)
	var result := world.dispatch(action, payload)
	_set_topic_status(action, result)
	if not str(result.get("system_text", "")).is_empty(): _append_system(result["system_text"])
	_refresh_all()
	if result.get("speaker") == "system": return
	_request_llm(player_text, result["llm_instruction"], result.get("completed", false), result.get("speaker", "npc"))

func _send_free_text() -> void:
	if awaiting_llm: return
	var words := input_edit.text.strip_edges()
	if words.is_empty(): return
	input_edit.clear()
	var actor := world.active_actor()
	if actor.is_empty(): return
	# Naming another piece on the counter switches what both sides are looking
	# at, so the keeper never answers about the wrong object.
	if world.location.begins_with("merchant:") and actor.get("role") == "seller":
		var named_items: Array[Dictionary] = []
		for stock_item in world.merchant_stock(world.visit_subject):
			var candidate_title := str(stock_item["title"])
			if candidate_title.length() >= 2 and words.contains(candidate_title): named_items.append(stock_item)
		if named_items.size() > 1:
			var names: Array[String] = []
			for named_item in named_items: names.append("《%s》" % str(named_item["title"]))
			_append_system("你同时提到了%s。请先点击其中一个商品卡片，再继续提问；这样双方都会明确正在看哪一件。" % "、".join(names))
			return
		for stock_item in world.merchant_stock(world.visit_subject):
			var title := str(stock_item["title"])
			if title.length() < 2 or not words.contains(title): continue
			if str(world.active_item().get("id", "")) == str(stock_item["id"]): continue
			if world.view_merchant_item(str(stock_item["id"])):
				_append_system("你把《%s》拿到近处，话题转到这件上。" % title)
				_refresh_all()
			break
	var interpreted := world.interpret_utterance(words, submitted_answer)
	submitted_answer = false
	_perform_action(interpreted["action"], interpreted, words)

func _request_llm(player_text: String, instruction: String, completed: bool, speaker := "npc") -> void:
	var actor := world.active_actor()
	if actor.is_empty(): return
	pending_mode = "npc"
	pending_player_text = player_text
	pending_instruction = instruction
	pending_completed = completed
	pending_speaker = speaker
	awaiting_llm = true
	reply_needs_retry = false
	_set_game_controls(false)
	toast_label.text = "正在想一想……" if speaker == "inner" else "对方正在回应……"
	_show_thinking(speaker)
	var history: Array[String] = []
	var voice := str(actor.get("personality", ""))
	if not world.person(actor["id"]).is_empty(): voice = str(world.person(actor["id"])["voice"])
	# Always pin which object is physically in front of both sides; naming a
	# different piece must be clarified instead of silently conflated.
	var item := world.active_item()
	var item_line := ""
	if not item.is_empty():
		item_line = "\n当前拿到近处、正在看的物件：《%s》（确定类别：%s）。若掌柜提到别的物件名称，先确认他说的是哪一件，不要把两件不同的东西混为一件。" % [str(item.get("title", "")), str(item.get("category", ""))]
	llm.request_npc_reply(actor["name"], voice, player_text, instruction + item_line + "\n当前场所：" + world.location + "\n连续交谈记录：\n" + world.dialogue_context(), history, speaker)

func _on_llm_response(ok: bool, words: String, error: String) -> void:
	if pending_mode in ["test", "start_test"]:
		super._on_llm_response(ok, words, error)
		return
	if pending_mode != "npc": return
	pending_mode = ""
	_hide_thinking()
	if not ok:
		awaiting_llm = true
		reply_needs_retry = true
		toast_label.text = error
		continue_button.text = "重试未完成的回应"
		continue_button.show()
		return
	awaiting_llm = false
	reply_needs_retry = false
	if pending_speaker == "inner": _append_inner(words)
	else: _append_npc(words)
	if pending_player_text == "客人刚刚进店。": world.reveal_opening()
	_refresh_all()
	toast_label.text = ""
	if pending_completed:
		if world.visit.is_empty():
			continue_button.text = "送别客人"
			continue_button.show()
		else:
			_render_location()
	_auto_save()

func _append_player(words: String) -> void:
	world.remember_line("player", words)
	log_history.append({"speaker": "你 · 掌柜", "text": words})
	_add_chat_card("你 · 掌柜", words, true, true)

func _append_npc(words: String) -> void:
	var actor := world.active_actor()
	world.remember_line("npc", words)
	log_history.append({"speaker": str(actor.get("name", "客人")), "text": words})
	_add_chat_card(str(actor.get("name", "客人")), words, false, true)

func _append_inner(words: String) -> void:
	world.private_notes.append({"day": world.day, "item": str(_active_item().get("title", "")), "text": words})
	_show_judgment_notice(words)

func _append_system(words: String) -> void:
	if words.is_empty(): return
	world.notices.append({"day": world.day, "text": words})
	if toast_label != null: toast_label.text = words
	if words.contains("判定为假") or words.contains("真品可能性"):
		_show_judgment_notice(words)

func _append_line(speaker: String, words: String) -> void:
	# Compatibility with base save loading: records are never rendered as speech.
	if speaker in ["记事", "心中判断 · 未说出口"]: return
	_add_chat_card(speaker, words, speaker == "你 · 掌柜")

func _clear_cards() -> void:
	for child in chat_cards.get_children():
		chat_cards.remove_child(child)
		child.queue_free()

func _restore_chat() -> void:
	_clear_cards()
	var actor := world.active_actor()
	if actor.is_empty(): return
	for entry in world.dialogue_memory.get(actor["id"], []).slice(-30):
		_add_chat_card("你 · 掌柜" if entry["role"] == "player" else actor["name"], entry["text"], entry["role"] == "player", false)

func _add_chat_card(speaker: String, words: String, player: bool, animate := false) -> Label:
	if chat_cards == null: return null
	var row := HBoxContainer.new()
	row.size_flags_horizontal = SIZE_EXPAND_FILL
	chat_cards.add_child(row)
	var spacer := Control.new()
	spacer.custom_minimum_size.x = 28
	if player: row.add_child(spacer)
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = SIZE_EXPAND_FILL
	var style := _panel_style(Color("#293c35") if player else Color("#363028"), JADE if player else Color("#746042"), 1, 12)
	style.content_margin_left = 11
	style.content_margin_right = 11
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	panel.add_theme_stylebox_override("panel", style)
	row.add_child(panel)
	var stack := VBoxContainer.new()
	panel.add_child(stack)
	var head := HBoxContainer.new()
	stack.add_child(head)
	var avatar := TextureRect.new()
	avatar.custom_minimum_size = Vector2(24, 24)
	avatar.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	avatar.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if not player:
		avatar.texture = _atlas(PORTRAITS, int(world.active_actor().get("portrait_index", 0)), 4, 2)
	else: avatar.texture = _atlas(OBJECTS, 0, 6, 4)
	head.add_child(avatar)
	var title := Label.new()
	title.text = speaker
	title.add_theme_font_size_override("font_size", 13)
	title.add_theme_color_override("font_color", Color("#adcbbc") if player else GOLD_LIGHT)
	head.add_child(title)
	var body := Label.new()
	body.text = words
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_theme_font_size_override("font_size", 16)
	body.add_theme_color_override("font_color", PAPER)
	stack.add_child(body)
	if not player: row.add_child(spacer)
	if animate and not is_test_mode:
		body.visible_characters = 0
		var duration := clampf(float(words.length()) * (0.012 if player else 0.026), 0.16, 2.4)
		var tween := create_tween()
		tween.tween_method(func(value: float):
			if is_instance_valid(body): body.visible_characters = int(value)
			_scroll_chat_to_bottom(), 0.0, float(words.length()), duration)
	_scroll_chat_to_bottom()
	_apply_history_visibility()
	return body

func _scroll_chat_to_bottom() -> void:
	if chat_scroll != null: chat_scroll.set_deferred("scroll_vertical", 999999)

func _show_thinking(speaker: String) -> void:
	_hide_thinking()
	if speaker == "inner": return
	var actor := world.active_actor()
	_add_chat_card(str(actor.get("name", "客人")), "正在思考…", false, false)
	thinking_card = chat_cards.get_child(chat_cards.get_child_count() - 1)
	thinking_card.modulate = Color(1, 1, 1, 0.68)

func _hide_thinking() -> void:
	if thinking_card != null and is_instance_valid(thinking_card):
		if thinking_card.get_parent() != null: thinking_card.get_parent().remove_child(thinking_card)
		thinking_card.queue_free()
	thinking_card = null

func _destination_card(title: String, detail: String, texture: Texture2D, region_fraction: Rect2, callback: Callable, primary := false) -> void:
	# Travel options are painted cards: a crop of the scene artwork carries the
	# mood, a short caption names the destination. Swap in dedicated generated
	# art later by pointing texture/region at new files.
	var size := texture.get_size()
	var atlas := AtlasTexture.new()
	atlas.atlas = texture
	atlas.region = Rect2(region_fraction.position * size, region_fraction.size * size)
	var card := Button.new()
	card.text = ""
	card.clip_contents = true
	card.custom_minimum_size = Vector2(640, 104)
	card.size_flags_horizontal = SIZE_EXPAND_FILL
	card.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var art := TextureRect.new()
	art.texture = atlas
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	art.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	art.mouse_filter = MOUSE_FILTER_IGNORE
	card.add_child(art)
	var veil := ColorRect.new()
	veil.color = Color(0.05, 0.04, 0.02, 0.5)
	veil.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	veil.mouse_filter = MOUSE_FILTER_IGNORE
	card.add_child(veil)
	var caption := Label.new()
	caption.text = "%s\n%s" % [title, detail]
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	caption.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	caption.add_theme_font_size_override("font_size", 20)
	caption.add_theme_color_override("font_color", PAPER)
	caption.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	caption.add_theme_constant_override("shadow_offset_x", 1)
	caption.add_theme_constant_override("shadow_offset_y", 1)
	caption.mouse_filter = MOUSE_FILTER_IGNORE
	card.add_child(caption)
	var border_color := GOLD_LIGHT if primary else GOLD
	for state in ["normal", "hover", "focus", "pressed", "disabled"]:
		var width := 2 if state in ["hover", "focus"] else 1
		card.add_theme_stylebox_override(state, _panel_style(Color(0, 0, 0, 0), border_color, width, 8))
	card.pressed.connect(callback)
	modal_body.add_child(card)

func _travel_scene() -> void:
	if awaiting_llm: return
	_open_modal("推门之后 · 城中往来")
	if not world.can_go_out():
		_paragraph("先接待完这段营业的客人。午间和闭店后，你可以推门出发。")
		return
	_destination_card("去古玩市场", "老店沿街 · 散摊看货", MARKET, Rect2(0.03, 0.15, 0.55, 0.35), func(): _go("market"), true)
	_destination_card("去拍卖预展", "先看货 · 想好价再举牌", MARKET, Rect2(0.60, 0.25, 0.38, 0.40), func(): _go("auction"))
	if world.phase == "closing":
		_destination_card("去听雨茶馆坐坐", "今晚谁在馆里 · 或有传闻", TEAHOUSE, Rect2(0.08, 0.15, 0.60, 0.45), func(): _go("tea"))
		_destination_card("拜访熟人或修护师", "不在馆里的人 · 登门去", SHOP, Rect2(0.78, 0.05, 0.22, 0.65), func(): _go("visits"))

func _go(destination: String) -> void:
	if awaiting_llm: return
	if not world.travel(destination):
		toast_label.text = "先完成或取消当前交割，再继续走动。"
		return
	modal.hide()
	private_card.hide()
	dialogue_collapsed = true
	last_topic_status = "尚未执行操作"
	_clear_cards()
	_render_location()
	_refresh_all()
	_auto_save()

func _scene_text(words: String, size: int = 18) -> void:
	var label := Label.new()
	label.text = words
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", PAPER)
	scene_panel.add_child(label)

func _scene_button(words: String, callback: Callable) -> void:
	var button := _make_button(words, false)
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button.custom_minimum_size.y = 34
	button.add_theme_font_size_override("font_size", 14)
	button.pressed.connect(callback)
	scene_panel.add_child(button)

func _set_scene_back(destination: String, caption: String) -> void:
	scene_back_destination = destination
	scene_back_button.text = "↩ " + caption
	scene_back_button.show()

func _night_meet_button(actor: Dictionary, origin: String) -> void:
	var id := str(actor["id"])
	var caption := "%s · %s" % [actor["name"], world.relationship(id)]
	caption += "\n有旧账相关的事可谈 · 点击选择推进" if world.has_story_for(id) else "\n坐下聊聊，也可以拿件库存共同看货"
	_scene_button(caption, func():
		if awaiting_llm: return
		if world.meet_at_night(id, origin):
			dialogue_collapsed = false
			suggestion_visible = false
			_restore_chat()
			_render_location()
			_refresh_all()
			_request_llm("晚上好，方便聊几句吗？", "夜间见面，回应问候。延续既有往来，不假装第一次见面，不提前透露未取得的家族线索。", false))

func _casual_visit_button(actor: Dictionary) -> void:
	# People without a storyline get one fixed exchange and the visit ends;
	# there is no empty free-form chat to struggle through.
	var id := str(actor["id"])
	_scene_button("%s · %s\n登门寒暄，不谈正事" % [actor["name"], world.relationship(id)], func():
		if awaiting_llm: return
		if world.meet_at_night(id, "visits"):
			var line := world.casual_visit_line(id)
			_open_modal("拜访 · %s" % actor["name"])
			_paragraph("这次没有与旧账相关的剧情节点。", 14)
			_paragraph(line, 20)
			_modal_button("告辞，返回拜访列表", func():
				modal.hide()
				world.travel("visits")
				dialogue_collapsed = true
				_render_location()
				_refresh_all()
				_auto_save()))

func _render_location() -> void:
	if scene_panel == null: return
	for child in stage.get_children():
		if child.has_meta("market_dynamic"):
			stage.remove_child(child)
			child.queue_free()
	scene_hint_popup.hide()
	scene_scroll.anchor_top = 0.22 if world.location.begins_with("merchant:") else 0.66
	scene_scroll.anchor_bottom = 0.96
	scene_scroll.anchor_left = .04
	scene_scroll.anchor_right = .96
	stock_grid = null
	for child in scene_panel.get_children():
		scene_panel.remove_child(child)
		child.queue_free()
	scene_canvas.visible = world.location != "shop"
	stage.get_child(0).texture = SHOP if world.location == "shop" else MARKET
	if world.location == "tea" or world.location.begins_with("night:"):
		stage.get_child(0).texture = TEAHOUSE
	elif world.location == "auction":
		stage.get_child(0).texture = AUCTION_HALL
	_update_hotspot_visibility()
	if world.location == "shop":
		_refresh_all()
		return
	portrait_art.hide()
	object_art.hide()
	private_card.hide()
	_set_scene_back("shop", "回到自己的店铺")
	if world.location == "market":
		scene_scroll.anchor_top = .025
		scene_scroll.anchor_bottom = .105
		scene_scroll.anchor_left = .79
		scene_scroll.anchor_right = .98
		scene_heading.text = "槐安古玩市场"
		scene_subtitle.text = "点击金字店招进店或看摊；悬停可先查看主营与推荐货品。"
		_build_market_hotspots()
	elif world.location.begins_with("merchant:"):
		var merchant: Dictionary = world.merchants[world.visit_subject]
		scene_heading.text = merchant["name"]
		scene_subtitle.text = merchant["description"]
		_set_scene_back("market", "回到市场街面")
		stock_grid = GridContainer.new()
		stock_grid.columns = 3
		stock_grid.size_flags_horizontal = SIZE_EXPAND_FILL
		stock_grid.add_theme_constant_override("h_separation", 12)
		stock_grid.add_theme_constant_override("v_separation", 12)
		scene_panel.add_child(stock_grid)
		for item in world.merchant_stock(world.visit_subject):
			var id := str(item["id"])
			_stock_card("%s · 要价¥%d" % [item["title"], int(item["ask"])], "点击名称拿到近处看货 · " + item["category"], [item], func():
				if awaiting_llm: return
				if world.view_merchant_item(id):
					_refresh_all()
					_item_modal(world.active_item()))
	elif world.location == "tea":
		scene_heading.text = "听雨茶馆"
		scene_subtitle.text = "打烊后常有人来坐。今晚谁在馆里要看缘分；不在馆里的人，得登门去拜访。"
		var event_text := world.teahouse_event()
		if not event_text.is_empty(): _scene_text("茶座传闻 · " + event_text)
		for actor in world.teahouse_people():
			_night_meet_button(actor, "tea")
		if world.teahouse_people().is_empty(): _scene_text("今晚馆里冷清，没有相熟的人。想找人说话，得登门拜访。")
	elif world.location == "visits":
		scene_heading.text = "登门拜访"
		scene_subtitle.text = "不在茶馆的人要单独登门。与旧账相关的正事优先；其余熟人，寒暄几句便告辞。"
		_scene_button("许闻溪工作室 · 复核库存（费用与范围）", _expert_modal)
		for actor in world.visit_people():
			var id := str(actor["id"])
			if world.has_story_for(id): _night_meet_button(actor, "visits")
			else: _casual_visit_button(actor)
		if world.visit_people().is_empty(): _scene_text("相熟的人今晚都在茶馆，或还没有建立起往来。")
	elif world.location.begins_with("night:"):
		var host := world.active_actor()
		scene_heading.text = "夜间往来 · " + str(host.get("name", ""))
		scene_subtitle.text = "不急着做买卖。正事用对话区里的按钮推进；闲聊与回顾仍可自由交谈。"
		_set_scene_back("visits" if world.visit_origin.is_empty() else world.visit_origin, "告辞返回")
		if world.visit_subject == "xu":
			_scene_button("请许闻溪复核库存 · 查看费用与范围", _expert_modal)
	elif world.location == "auction":
		_render_auction_scene()

func _render_auction_scene() -> void:
	var sale := world.auction_preview()
	if sale.is_empty():
		scene_heading.text = "槐安小拍 · 尚未开放"
		scene_subtitle.text = "第三日起开放预展。"
		_scene_text("今天没有开放的拍卖场次。")
		return
	scene_scroll.anchor_top = .20
	scene_scroll.anchor_bottom = .96
	scene_scroll.anchor_left = .04
	scene_scroll.anchor_right = .96
	if sale.get("phase", "preview") == "preview":
		scene_heading.text = "槐安小拍 · 预展"
		scene_subtitle.text = "先翻图录、看实物并标记关注；开拍后逐件进行，不相关的拍品可以直接跳过。"
		_scene_text("本场图录 · %d件拍品 · 成交另收5%%费用" % sale.get("lots", []).size(), 16)
		stock_grid = GridContainer.new()
		stock_grid.columns = 3
		stock_grid.size_flags_horizontal = SIZE_EXPAND_FILL
		stock_grid.add_theme_constant_override("h_separation", 10)
		stock_grid.add_theme_constant_override("v_separation", 10)
		scene_panel.add_child(stock_grid)
		for lot in sale.get("lots", []):
			var item: Dictionary = world.all_items[lot["item_id"]]
			var marker := "★ 已关注" if lot.get("marked", false) else "☆ 未标记"
			_stock_card("%02d号 · %s" % [int(lot["lot_number"]), item["title"]], "%s · 起拍¥%d · %s\n点击查看图录与实物" % [item["category"], int(lot["price"]), marker], [item], func(): _auction_lot_modal(lot))
		_scene_button("入场 · 开始逐件竞价", func():
			if world.start_auction():
				_render_location()
				_auto_save())
	else:
		var lot := world.current_auction_lot()
		if lot.is_empty():
			scene_heading.text = "槐安小拍 · 散场"
			scene_subtitle.text = str(sale.get("outcome", "本场竞价已经结束。"))
			var won := 0
			for result_lot in sale.get("lots", []):
				if result_lot.get("status") == "won": won += 1
			_scene_text("本场共看过%d件拍品，你拍得%d件。未成交的拍品不会自动进入库存。" % [sale.get("lots", []).size(), won], 19)
			return
		var item: Dictionary = world.all_items[lot["item_id"]]
		scene_heading.text = "槐安小拍 · %02d号拍品" % int(lot["lot_number"])
		scene_subtitle.text = "拍卖师正在介绍《%s》。当前价¥%d；你不需要对每一件都举牌。" % [item["title"], int(lot["price"])]
		_stock_card("台上拍品 · %s" % item["title"], "%s\n图录说明：%s" % [item["category"], item["source_claim"]], [item], func(): _auction_lot_modal(lot))
		var rivals: Array = lot.get("rivals", [])
		if not rivals.is_empty():
			var rival_lines: Array[String] = []
			for rival in rivals: rival_lines.append("%s：%s" % [rival.get("name", "竞买人"), rival.get("style", "神情看不分明")])
			_scene_text("场内竞买人（只显示可观察到的表现）\n" + "\n".join(rival_lines), 14)
		if not str(lot.get("outcome", "")).is_empty() and lot.get("outcome") != "尚未开拍": _scene_text("拍卖师：" + str(lot["outcome"]), 16)
		var amount := SpinBox.new()
		amount.min_value = int(lot["price"]) + 1
		amount.max_value = 999999
		amount.step = 1
		amount.value = int(lot["price"]) + 100
		amount.prefix = "举牌 ¥"
		scene_panel.add_child(amount)
		_scene_button("确认举牌", func():
			amount.apply()
			var result := world.bid(int(amount.value))
			world.notices.append({"day": world.day, "text": result})
			_render_location()
			_auto_save())
		_scene_button("放弃本件 · 等下一件", func():
			world.skip_auction_lot()
			_render_location()
			_auto_save())
		_scene_button("提前离场 · 跳过余下拍品", func():
			world.finish_auction_early()
			_render_location()
			_auto_save())

func _auction_lot_modal(lot: Dictionary) -> void:
	var item: Dictionary = world.all_items.get(lot.get("item_id", ""), {})
	_open_modal("%02d号拍品 · 图录与实物" % int(lot.get("lot_number", 0)))
	if item.is_empty():
		_paragraph("这件拍品资料已经失效。")
		return
	_modal_art(OBJECTS, int(item["art"]), 6, 4, 190)
	_paragraph("《%s》 · 确定类别：%s · 当前价¥%d" % [item["title"], item["category"], int(lot["price"])], 22)
	_paragraph("图录说明：%s" % item["source_claim"], 15)
	if item.get("appraised", false):
		_paragraph("我的当前判断：%s" % ("判定为假" if item.get("judged_fake", false) else "%d%%真品可能性，仍有不确定性" % int(item.get("probability", 0))), 16)
	else:
		_modal_button("预展查看物品 · 形成私人判断", func():
			var result := world.inspect_outside(str(item["id"]))
			if not result.is_empty(): world.private_notes.append({"day": world.day, "item": item["title"], "text": result.get("system_text", "")})
			_auto_save()
			_auction_lot_modal(lot))
	if world.auction.get("phase", "") == "preview":
		_modal_button("取消关注" if lot.get("marked", false) else "标记为关注", func():
			world.mark_auction_lot(str(item["id"]))
			_auto_save()
			_auction_lot_modal(lot))

func _enter_market_merchant(id: String) -> void:
	if awaiting_llm or not world.enter_merchant(id): return
	dialogue_collapsed = true
	suggestion_visible = false
	_restore_chat()
	_render_location()
	_refresh_all()
	_auto_save()

func _build_market_hotspots() -> void:
	var locations: Array = [
		[Vector2(.025,.20), Vector2(.32,.19), Vector2(.33,.63), Vector2(.035,.65)],
		[Vector2(.47,.17), Vector2(.69,.19), Vector2(.70,.53), Vector2(.47,.49)],
		[Vector2(.78,.29), Vector2(.995,.28), Vector2(.995,.71), Vector2(.79,.65)],
		[Vector2(.365,.25), Vector2(.466,.235), Vector2(.463,.414), Vector2(.365,.435)],
		[Vector2(.004,.73), Vector2(.11,.65), Vector2(.25,.72), Vector2(.24,.96), Vector2(.01,.96)],
		[Vector2(.68,.80), Vector2(.83,.88), Vector2(.83,.99), Vector2(.61,.99), Vector2(.58,.94)],
		[Vector2(.66,.54), Vector2(.76,.58), Vector2(.765,.76), Vector2(.65,.73)],
		[Vector2(.31,.44), Vector2(.40,.455), Vector2(.40,.60), Vector2(.325,.63)],
		[Vector2(.72,.48), Vector2(.78,.465), Vector2(.795,.63), Vector2(.735,.63)]
	]
	var merchants := world.market_merchants()
	var sign_positions := [Rect2(.109,.363,.128,.05), Rect2(.562,.31,.072,.046), Rect2(.815,.405,.141,.06), Rect2(.382,.294,.072,.05)]
	for index in range(merchants.size()):
		var merchant: Dictionary = merchants[index]
		var id := str(merchant["id"])
		var stock := world.merchant_stock(id)
		var titles: Array[String] = []
		for item in stock.slice(0, 3): titles.append(str(item["title"]))
		var hint := "%s · 主营%s\n%s\n推荐：%s\n在售%d件 · 点击进店看货" % [merchant["name"], merchant["category"], merchant["description"], "、".join(titles), stock.size()]
		var hotspot := _art_hotspot(hint, locations[index], func(): _enter_market_merchant(id), MARKET.get_size())
		# No more gold fences around the buildings: the plaque alone is the
		# button; the polygon only defines where a click still counts.
		hotspot.draw_frame = false
		hotspot.set_meta("market_dynamic", true)
		hotspot.set_meta("merchant_id", id)
		var sign := Label.new()
		sign.text = "%s\n%s" % [merchant["name"], merchant["category"]]
		sign.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		sign.add_theme_font_size_override("font_size", 15 if index < 3 else 12)
		sign.add_theme_color_override("font_color", GOLD_LIGHT)
		var sign_normal := _panel_style(Color("#231c12e8"), GOLD, 1, 3)
		var sign_hover := _panel_style(Color("#3a2f1ce8"), GOLD_LIGHT, 2, 3)
		sign.add_theme_stylebox_override("normal", sign_normal)
		sign.mouse_filter = MOUSE_FILTER_IGNORE
		sign.set_meta("market_dynamic", true)
		hotspot.mouse_entered.connect(func(): sign.add_theme_stylebox_override("normal", sign_hover))
		hotspot.mouse_exited.connect(func(): sign.add_theme_stylebox_override("normal", sign_normal))
		var first: Vector2 = locations[index][0]
		var sign_rect: Rect2 = sign_positions[index] if index < 4 else Rect2(first.x + .005, first.y + .07, .10, .065)
		_place(sign, stage, sign_rect)
	# Tooltip must stay above dynamically inserted scene controls.
	stage.move_child(scene_hint_popup, -1)

func _note_label(parent: Control, value: String, size := 16, color := PAPER) -> Label:
	var label := Label.new()
	label.text = value
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	parent.add_child(label)
	return label

func _notebook_tab(tab_name: String) -> VBoxContainer:
	var scroll := ScrollContainer.new()
	scroll.name = tab_name
	scroll.size_flags_horizontal = SIZE_EXPAND_FILL
	scroll.size_flags_vertical = SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var box := VBoxContainer.new()
	box.size_flags_horizontal = SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 9)
	scroll.add_child(box)
	var tabs := modal_body.get_child(-1)
	if tabs is TabContainer: tabs.add_child(scroll)
	return box

func _story_node_status(node: Dictionary) -> String:
	if world.resolved_nodes.has(node.get("id", "")): return "已完成"
	for available in world.available_story():
		if available.get("id", "") == node.get("id", ""): return "当前可调查"
	if int(node.get("day", 1)) > world.day: return "尚未到达"
	return "等待前置线索"

func _story_node_card(node: Dictionary, status: String) -> PanelContainer:
	var card := PanelContainer.new()
	var card_color := Color("#26352f") if status == "当前可调查" else (Color("#2b2923") if status == "已完成" else Color("#211f1be8"))
	card.add_theme_stylebox_override("panel", _panel_style(card_color, JADE if status == "当前可调查" else Color("#625741"), 1, 8))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 3)
	card.add_child(box)
	_note_label(box, "%s  ·  %s" % [str(node.get("title", "未命名线索")), status], 19, GOLD_LIGHT)
	_note_label(box, "关联人物：%s" % str(world.person(str(node.get("actor", ""))).get("name", "未标注")), 12, PAPER_DARK)
	if status in ["当前可调查", "已完成"]:
		_note_label(box, str(node.get("text", "")), 14, PAPER)
		if status == "当前可调查":
			var choices: Array[String] = []
			for choice in node.get("choices", []): choices.append(str(choice.get("label", "")))
			_note_label(box, "下一步：" + " / ".join(choices), 13, PAPER_DARK)
	else:
		_note_label(box, "这条线索暂未进入可处理状态；先完成前置记录，不提前补全故事。", 14, MUTED)
	return card

func _notebook_modal() -> void:
	_open_modal("随身笔记 · 经营与剧情分开")
	var tabs := TabContainer.new()
	tabs.custom_minimum_size = Vector2(680, 430)
	tabs.size_flags_horizontal = SIZE_EXPAND_FILL
	modal_body.add_child(tabs)
	var business := _notebook_tab("经营记录")
	_note_label(business, "今天的营业与交易", 21, GOLD_LIGHT)
	_note_label(business, "只记录资金、物权和客人结果；剧情调查不会混在这里。", 13, PAPER_DARK)
	for entry in world.notices.slice(-12): _note_label(business, "第%d日 · %s" % [int(entry.get("day", world.day)), str(entry.get("text", ""))], 14)
	if world.notices.is_empty(): _note_label(business, "尚无经营记录。", 14, MUTED)
	var story := _notebook_tab("剧情调查")
	_note_label(story, "主线：爷爷留下的寄存旧账", 21, GOLD_LIGHT)
	_note_label(story, "流程状态：%d / %d 条线索已处理" % [world.resolved_nodes.size(), world.content.get("story_nodes", []).size()], 14, PAPER_DARK)
	for node in world.content.get("story_nodes", []): story.add_child(_story_node_card(node, _story_node_status(node)))
	var people := _notebook_tab("人物往来")
	_note_label(people, "每个人只保留自己实际听到的往来。", 14, PAPER_DARK)
	for actor in world.content.get("people", []):
		var contact: Dictionary = world.contacts.get(actor["id"], {})
		if not contact.get("met", false): continue
		_note_label(people, "%s · %s · %s" % [actor["name"], actor["identity"], world.relationship(actor["id"])], 18, GOLD_LIGHT)
		for memory in contact.get("memories", []).slice(-3): _note_label(people, "· " + str(memory), 14)
	# “器物与判断”时间线已移除：私人判断直接归在每件器物的详情里查看。
	_modal_button("翻阅信件、照片与开场记录", _documents_modal)
	_modal_button("进入剧情处理与选择", _story_modal, true)
	_modal_button("查看知识与鉴定笔记", _knowledge_modal)

func _story_modal() -> void:
	_open_modal("剧情调查 · 线索流程")
	_paragraph("主线：爷爷留下的寄存旧账。每张卡说明发生了什么、关联谁、当前能否处理；已知事实不会被自由对话自动改写。", 15)
	for node in world.content.get("story_nodes", []):
		var node_id := str(node.get("id", ""))
		var status := _story_node_status(node)
		modal_body.add_child(_story_node_card(node, status))
		if status == "当前可调查" and world.can_go_out():
			for choice in node.get("choices", []):
				var choice_id := str(choice.get("id", ""))
				var choice_label := str(choice.get("label", ""))
				_modal_button(choice_label, func():
					world.choose_story(node_id, choice_id)
					_auto_save()
					_story_modal())
	if not world.consequences.is_empty():
		_paragraph("售后反馈 · 已发生的后果", 21)
		for event in world.consequences:
			var event_id := str(event.get("id", ""))
			var stage_names := ["个人关系圈", "行业圈", "公众/市场圈"]
			var stage := clampi(int(event.get("stage", 0)), 0, stage_names.size() - 1)
			_paragraph("%s · %s\n%s" % [stage_names[stage], "已控制" if event.get("contained", false) else "仍在发酵", event.get("text", "")], 15)
			if world.can_go_out() and not event.get("contained", false):
				for method in [["联系买家解释", "explain"], ["补充已有鉴定记录", "evidence"]]:
					var key := str(method[1])
					_modal_button(method[0], func():
						var result := world.intervene(event_id, key)
						_refresh_all()
						_auto_save()
						_story_modal()
						_paragraph(result))

func _documents_modal() -> void:
	_open_modal("夹在笔记里的资料")
	for page in world.revision_content["prologue"]:
		_paragraph(page["title"], 23)
		_document_art(page)
		_paragraph(page["text"], 17)

func _document_art(page: Dictionary) -> void:
	if page.get("document") != "photo": return
	var photo := TextureRect.new()
	photo.texture = OLD_PHOTO
	photo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	photo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	photo.custom_minimum_size = Vector2(300, 260)
	modal_body.add_child(photo)

func _settings_modal() -> void:
	super._settings_modal()
	Profiles.add_switcher(self)
	_modal_button("保存当前进度", func():
		_save_progress()
		_paragraph(toast_label.text))
	_modal_button("读取上次进度", func():
		_load_progress()
		_render_location()
		_restore_chat()
		modal.hide())
	_modal_button("操作提示：货架 / 门 / 两本书 / 台面", func():
		_paragraph("货架看库存，门口出发，账本看收支，笔记看人物与疑问。可点击位置只在交谈收起时亮起；打开交谈时场景只作背景。"))

func _ledger_modal() -> void:
	super._ledger_modal()
	_modal_button("翻到爷爷的旧账页", _story_modal)
	_paragraph("最近的经营记录", 22)
	for entry in world.notices.slice(-12): _paragraph("第%d日 · %s" % [int(entry["day"]), entry["text"]], 15)
