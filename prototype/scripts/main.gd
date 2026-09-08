extends Control

const GameCoreScript = preload("res://scripts/game_core.gd")
const LLMClientScript = preload("res://scripts/llm_client.gd")

const INK := Color("#171510")
const PAPER := Color("#e8dfca")
const PAPER_DARK := Color("#cfc1a3")
const GOLD := Color("#b99352")
const GOLD_LIGHT := Color("#d8be83")
const RED := Color("#873d35")
const JADE := Color("#607968")
const MUTED := Color("#8e8778")
const PANEL := Color("#24211b")
const PANEL_ALT := Color("#2d2922")

var core: DemoGameCore
var llm: DemoLLMClient
var root_stack: VBoxContainer
var setup_view: Control
var game_view: Control
var review_view: Control
var api_key_edit: LineEdit
var model_edit: LineEdit
var base_url_edit: LineEdit
var endpoint_edit: LineEdit
var protocol_option: OptionButton
var temperature_edit: LineEdit
var max_tokens_edit: LineEdit
var timeout_edit: LineEdit
var organization_edit: LineEdit
var extra_headers_edit: TextEdit
var store_check: CheckButton
var chat_token_option: OptionButton
var provider_option: OptionButton
var setup_status: Label
var connect_button: Button
var start_button: Button
var header_phase: Label
var header_money: Label
var header_inventory: Label
var header_growth: Label
var portrait_label: Label
var guest_name_label: Label
var guest_subtitle_label: Label
var guest_role_label: Label
var attitude_label: Label
var object_title_label: Label
var object_info_label: RichTextLabel
var dialogue: RichTextLabel
var input_edit: LineEdit
var send_button: Button
var quick_actions: HFlowContainer
var price_spin: SpinBox
var offer_button: Button
var end_button: Button
var inventory_list: VBoxContainer
var inventory_detail: RichTextLabel
var recommend_button: Button
var appraise_inventory_button: Button
var notes_label: RichTextLabel
var ledger_label: RichTextLabel
var continue_button: Button
var toast_label: Label
var pending_mode := ""
var pending_player_text := ""
var pending_instruction := ""
var pending_completed := false
var pending_speaker := "npc"
var conversation_history: Array[String] = []
var awaiting_llm := false
var reply_needs_retry := false
var item_record_dialog: AcceptDialog
var item_record_text: RichTextLabel
var at_noon := false

func _ready() -> void:
	core = GameCoreScript.new()
	llm = LLMClientScript.new()
	add_child(llm)
	llm.response_ready.connect(_on_llm_response)
	_build_theme()
	_build_layout()
	_build_item_record_dialog()
	_show_setup()

func _build_item_record_dialog() -> void:
	item_record_dialog = AcceptDialog.new()
	item_record_dialog.title = "物件资料 · 随时查阅，不消耗耐心"
	item_record_dialog.ok_button_text = "返回柜台"
	item_record_dialog.min_size = Vector2i(560, 400)
	add_child(item_record_dialog)
	item_record_text = RichTextLabel.new()
	item_record_text.bbcode_enabled = false
	item_record_text.custom_minimum_size = Vector2(540, 350)
	item_record_text.add_theme_font_size_override("normal_font_size", 18)
	item_record_dialog.add_child(item_record_text)

func _show_item_record(use_inventory: bool = false) -> void:
	var item_id := core.selected_item_id
	if not use_inventory and core.current_guest.get("role") == "seller":
		if not core.current_guest.get("role_revealed", false):
			item_id = ""
		else:
			item_id = str(core.current_guest["item"]["id"])
	elif not use_inventory and core.current_guest.get("role") == "buyer":
		item_id = str(core.current_guest.get("recommended_item_id", core.selected_item_id))
	var record := core.visible_item_record(item_id)
	if record.is_empty():
		item_record_text.text = "当前没有可查阅的物件。卖家说明来意后可查看来货；买家交谈中请先选择或推荐库存。"
	else:
		var lines: Array[String] = [str(record["title"]), "确定类别：%s" % record["category"], "", "来历记录"]
		lines.append(str(record["provenance"]) if not str(record["provenance"]).is_empty() else "尚无已知来源记录。可以向卖家询问；不能用猜测补全来历。")
		lines.append("\n已观察到的线索")
		if record["clues"].is_empty():
			lines.append("尚无已记录线索。查看资料本身不会自动鉴定或解锁线索。")
		for clue in record["clues"]:
			lines.append("• %s" % clue)
		lines.append("\n鉴定记录（当时判断，不是真伪保证）")
		if record["appraisals"].is_empty():
			lines.append("尚未鉴定。")
		for entry in record["appraisals"]:
			lines.append("%s：真品可能性 %d%%" % [entry["context"], entry["probability"]])
		lines.append("\n回答提醒：区分已有记录、原卖家说法和自己的判断；没有凭据的部分可以直接说明尚不清楚。")
		item_record_text.text = "\n".join(lines)
	item_record_dialog.popup_centered(Vector2i(660, 550))

func _build_theme() -> void:
	var app_theme := Theme.new()
	var system_font := SystemFont.new()
	system_font.font_names = PackedStringArray(["Microsoft YaHei UI", "Microsoft YaHei", "Noto Sans CJK SC", "Arial"])
	system_font.font_weight = 500
	app_theme.default_font = system_font
	app_theme.default_font_size = 17
	theme = app_theme

func _build_layout() -> void:
	var bg := ColorRect.new()
	bg.color = INK
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var edge := MarginContainer.new()
	edge.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	edge.add_theme_constant_override("margin_left", 24)
	edge.add_theme_constant_override("margin_right", 24)
	edge.add_theme_constant_override("margin_top", 18)
	edge.add_theme_constant_override("margin_bottom", 18)
	add_child(edge)

	root_stack = VBoxContainer.new()
	root_stack.add_theme_constant_override("separation", 12)
	edge.add_child(root_stack)
	_build_header()
	setup_view = _build_setup_view()
	root_stack.add_child(setup_view)
	game_view = _build_game_view()
	root_stack.add_child(game_view)
	review_view = _build_review_view()
	root_stack.add_child(review_view)

func _build_header() -> void:
	var header := PanelContainer.new()
	header.custom_minimum_size.y = 76
	header.add_theme_stylebox_override("panel", _panel_style(Color("#201d18"), GOLD, 1, 8))
	root_stack.add_child(header)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	header.add_child(margin)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 22)
	margin.add_child(row)
	var title_box := VBoxContainer.new()
	title_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(title_box)
	var title := Label.new()
	title.text = "HEIRLOOM LEDGER  ·  藏珍账"
	title.add_theme_font_size_override("font_size", 25)
	title.add_theme_color_override("font_color", GOLD_LIGHT)
	title_box.add_child(title)
	var subtitle := Label.new()
	subtitle.text = "一日试营业 · 对话判断玩法原型"
	subtitle.add_theme_font_size_override("font_size", 13)
	subtitle.add_theme_color_override("font_color", MUTED)
	title_box.add_child(subtitle)
	header_phase = _header_stat("尚未营业")
	header_money = _header_stat("资金  ¥3,600")
	header_inventory = _header_stat("库存  3 件")
	header_growth = _header_stat("知识 42  ·  经验 18")
	row.add_child(header_phase)
	row.add_child(header_money)
	row.add_child(header_inventory)
	row.add_child(header_growth)

func _header_stat(text_value: String) -> Label:
	var label := Label.new()
	label.text = text_value
	label.add_theme_color_override("font_color", PAPER_DARK)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	return label

func _build_setup_view() -> Control:
	var center := CenterContainer.new()
	center.custom_minimum_size = Vector2(820, 720)
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(820, 720)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	center.add_child(scroll)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(820, 720)
	panel.add_theme_stylebox_override("panel", _panel_style(PANEL, GOLD, 1, 14))
	scroll.add_child(panel)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 44)
	margin.add_theme_constant_override("margin_right", 44)
	margin.add_theme_constant_override("margin_top", 34)
	margin.add_theme_constant_override("margin_bottom", 34)
	panel.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	margin.add_child(box)
	var heading := Label.new()
	heading.text = "开门前 · 连接真实 LLM"
	heading.add_theme_font_size_override("font_size", 28)
	heading.add_theme_color_override("font_color", GOLD_LIGHT)
	box.add_child(heading)
	var explanation := Label.new()
	explanation.text = "填写任意 OpenAI-compatible 服务。协议、地址、模型和请求参数都可调整；\n资金、库存、真伪、预算、耐心与成交结果始终由本地 Game Core 决定。"
	explanation.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	explanation.add_theme_color_override("font_color", PAPER_DARK)
	box.add_child(explanation)
	box.add_child(_field_label("服务预设（只会填充下方字段，仍可继续修改）"))
	provider_option = OptionButton.new()
	provider_option.add_item("自定义 OpenAI-compatible")
	provider_option.add_item("OpenAI")
	provider_option.add_item("DeepSeek")
	provider_option.custom_minimum_size.y = 40
	provider_option.item_selected.connect(_apply_provider_preset)
	box.add_child(provider_option)
	box.add_child(_field_label("API Base URL"))
	base_url_edit = LineEdit.new()
	base_url_edit.text = "https://api.openai.com/v1"
	base_url_edit.placeholder_text = "例如 https://api.example.com/v1"
	base_url_edit.custom_minimum_size.y = 40
	_style_line_edit(base_url_edit)
	box.add_child(base_url_edit)
	box.add_child(_field_label("Endpoint Path（相对 Base URL）"))
	endpoint_edit = LineEdit.new()
	endpoint_edit.text = "/responses"
	endpoint_edit.placeholder_text = "/responses 或 /chat/completions"
	endpoint_edit.custom_minimum_size.y = 40
	_style_line_edit(endpoint_edit)
	box.add_child(endpoint_edit)
	box.add_child(_field_label("协议"))
	protocol_option = OptionButton.new()
	protocol_option.add_item("Responses API")
	protocol_option.add_item("Chat Completions")
	protocol_option.custom_minimum_size.y = 40
	protocol_option.item_selected.connect(_on_protocol_selected)
	box.add_child(protocol_option)
	box.add_child(_field_label("API Key（仅保存在本次运行内存中）"))
	api_key_edit = LineEdit.new()
	api_key_edit.secret = true
	api_key_edit.placeholder_text = "输入服务商 API Key"
	api_key_edit.custom_minimum_size.y = 40
	_style_line_edit(api_key_edit)
	box.add_child(api_key_edit)
	box.add_child(_field_label("模型"))
	model_edit = LineEdit.new()
	model_edit.text = "gpt-5-mini"
	model_edit.custom_minimum_size.y = 40
	_style_line_edit(model_edit)
	box.add_child(model_edit)
	box.add_child(_field_label("Temperature（仅Chat协议，留空不发送；0～2）"))
	temperature_edit = LineEdit.new()
	temperature_edit.text = ""
	temperature_edit.placeholder_text = "留空采用模型默认值；支持时可填0.7"
	temperature_edit.custom_minimum_size.y = 40
	_style_line_edit(temperature_edit)
	box.add_child(temperature_edit)
	box.add_child(_field_label("最大输出 Token 数"))
	max_tokens_edit = LineEdit.new()
	max_tokens_edit.text = "2048"
	max_tokens_edit.custom_minimum_size.y = 40
	_style_line_edit(max_tokens_edit)
	box.add_child(max_tokens_edit)
	box.add_child(_field_label("请求超时（秒）"))
	timeout_edit = LineEdit.new()
	timeout_edit.text = "45"
	timeout_edit.custom_minimum_size.y = 40
	_style_line_edit(timeout_edit)
	box.add_child(timeout_edit)
	box.add_child(_field_label("可选：Organization Header"))
	organization_edit = LineEdit.new()
	organization_edit.placeholder_text = "通常留空"
	organization_edit.custom_minimum_size.y = 40
	_style_line_edit(organization_edit)
	box.add_child(organization_edit)
	box.add_child(_field_label("可选：额外请求 Headers（每行 Header: value）"))
	extra_headers_edit = TextEdit.new()
	extra_headers_edit.placeholder_text = "例如 X-Custom-Header: value"
	extra_headers_edit.custom_minimum_size.y = 58
	extra_headers_edit.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	_style_text_edit(extra_headers_edit)
	box.add_child(extra_headers_edit)
	chat_token_option = OptionButton.new()
	chat_token_option.add_item("Chat Completions 使用 max_tokens")
	chat_token_option.add_item("Chat Completions 使用 max_completion_tokens")
	chat_token_option.custom_minimum_size.y = 40
	box.add_child(chat_token_option)
	store_check = CheckButton.new()
	store_check.text = "Responses API 发送 store=false 参数（默认关闭，兼容性更高）"
	store_check.button_pressed = false
	box.add_child(store_check)
	var privacy := Label.new()
	privacy.text = "隐私与费用提示：对话内容会发送至所配置的 API，并产生相应调用费用。Key 不写入项目文件或存档。"
	privacy.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	privacy.add_theme_font_size_override("font_size", 14)
	privacy.add_theme_color_override("font_color", MUTED)
	box.add_child(privacy)
	setup_status = Label.new()
	setup_status.text = "等待连接"
	setup_status.add_theme_color_override("font_color", MUTED)
	box.add_child(setup_status)
	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 12)
	box.add_child(buttons)
	connect_button = _make_button("测试连接", false)
	connect_button.pressed.connect(_test_connection)
	buttons.add_child(connect_button)
	start_button = _make_button("连接并开始营业", true)
	start_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	start_button.pressed.connect(_start_with_connection)
	buttons.add_child(start_button)
	return center

func _apply_provider_preset(index: int) -> void:
	if index == 1:
		base_url_edit.text = "https://api.openai.com/v1"
		endpoint_edit.text = "/responses"
		protocol_option.select(0)
		model_edit.text = "gpt-5-mini"
	elif index == 2:
		base_url_edit.text = "https://api.deepseek.com"
		endpoint_edit.text = "/responses"
		protocol_option.select(0)
		model_edit.text = "deepseek-v4-flash"

func _on_protocol_selected(index: int) -> void:
	if index == 1 and endpoint_edit.text.strip_edges() == "/responses":
		endpoint_edit.text = "/chat/completions"
	elif index == 0 and endpoint_edit.text.strip_edges() == "/chat/completions":
		endpoint_edit.text = "/responses"

func _field_label(text_value: String) -> Label:
	var label := Label.new()
	label.text = text_value
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", GOLD_LIGHT)
	return label

func _build_game_view() -> Control:
	var view := VBoxContainer.new()
	view.size_flags_vertical = Control.SIZE_EXPAND_FILL
	view.add_theme_constant_override("separation", 10)
	var columns := HBoxContainer.new()
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	columns.add_theme_constant_override("separation", 12)
	view.add_child(columns)
	columns.add_child(_build_guest_panel())
	columns.add_child(_build_dialogue_panel())
	columns.add_child(_build_ledger_panel())
	continue_button = _make_button("处理完成后继续", true)
	continue_button.visible = false
	continue_button.pressed.connect(_continue_flow)
	view.add_child(continue_button)
	toast_label = Label.new()
	toast_label.text = ""
	toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast_label.add_theme_font_size_override("font_size", 14)
	toast_label.add_theme_color_override("font_color", GOLD_LIGHT)
	view.add_child(toast_label)
	return view

func _build_guest_panel() -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size.x = 285
	panel.add_theme_stylebox_override("panel", _panel_style(PANEL, Color("#4d493f"), 1, 10))
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	panel.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	margin.add_child(box)
	var portrait_frame := PanelContainer.new()
	portrait_frame.custom_minimum_size = Vector2(170, 170)
	portrait_frame.add_theme_stylebox_override("panel", _panel_style(Color("#353028"), GOLD, 2, 85))
	box.add_child(portrait_frame)
	portrait_label = Label.new()
	portrait_label.text = "客"
	portrait_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	portrait_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	portrait_label.add_theme_font_size_override("font_size", 70)
	portrait_label.add_theme_color_override("font_color", GOLD_LIGHT)
	portrait_frame.add_child(portrait_label)
	guest_name_label = Label.new()
	guest_name_label.text = "尚无来客"
	guest_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	guest_name_label.add_theme_font_size_override("font_size", 25)
	guest_name_label.add_theme_color_override("font_color", PAPER)
	box.add_child(guest_name_label)
	guest_subtitle_label = Label.new()
	guest_subtitle_label.text = ""
	guest_subtitle_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	guest_subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	guest_subtitle_label.add_theme_font_size_override("font_size", 14)
	guest_subtitle_label.add_theme_color_override("font_color", MUTED)
	box.add_child(guest_subtitle_label)
	guest_role_label = _meta_label("来意：尚未说明")
	attitude_label = _meta_label("态度：—")
	box.add_child(guest_role_label)
	box.add_child(attitude_label)
	var divider := HSeparator.new()
	divider.add_theme_color_override("separator", Color("#514a3d"))
	box.add_child(divider)
	object_title_label = Label.new()
	object_title_label.text = "柜台"
	object_title_label.add_theme_font_size_override("font_size", 18)
	object_title_label.add_theme_color_override("font_color", GOLD_LIGHT)
	box.add_child(object_title_label)
	object_info_label = RichTextLabel.new()
	object_info_label.bbcode_enabled = true
	object_info_label.fit_content = true
	object_info_label.custom_minimum_size.y = 160
	object_info_label.add_theme_color_override("default_color", PAPER_DARK)
	object_info_label.add_theme_font_size_override("normal_font_size", 15)
	box.add_child(object_info_label)
	return panel

func _meta_label(text_value: String) -> Label:
	var label := Label.new()
	label.text = text_value
	label.add_theme_color_override("font_color", PAPER_DARK)
	label.add_theme_font_size_override("font_size", 15)
	return label

func _build_dialogue_panel() -> Control:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", _panel_style(Color("#eee5d2"), PAPER_DARK, 1, 10))
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 22)
	margin.add_theme_constant_override("margin_right", 22)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_bottom", 18)
	panel.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	margin.add_child(box)
	var title := Label.new()
	title.text = "柜台交谈"
	title.add_theme_font_size_override("font_size", 19)
	title.add_theme_color_override("font_color", Color("#4b3927"))
	box.add_child(title)
	dialogue = RichTextLabel.new()
	dialogue.bbcode_enabled = true
	dialogue.scroll_active = true
	dialogue.scroll_following = true
	dialogue.size_flags_vertical = Control.SIZE_EXPAND_FILL
	dialogue.add_theme_color_override("default_color", Color("#27231e"))
	dialogue.add_theme_font_size_override("normal_font_size", 17)
	box.add_child(dialogue)
	var facts_button := _make_button("查看当前物件资料 · 来历 / 线索 / 鉴定记录", false)
	facts_button.pressed.connect(_show_item_record)
	box.add_child(facts_button)
	quick_actions = HFlowContainer.new()
	quick_actions.add_theme_constant_override("h_separation", 7)
	quick_actions.add_theme_constant_override("v_separation", 7)
	box.add_child(quick_actions)
	var input_row := HBoxContainer.new()
	input_row.add_theme_constant_override("separation", 8)
	box.add_child(input_row)
	input_edit = LineEdit.new()
	input_edit.placeholder_text = "输入你想说的话……"
	input_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	input_edit.custom_minimum_size.y = 46
	_style_line_edit(input_edit, true)
	input_edit.text_submitted.connect(func(_text): _send_free_text())
	input_row.add_child(input_edit)
	send_button = _make_button("发送", true)
	send_button.pressed.connect(_send_free_text)
	input_row.add_child(send_button)
	var deal_row := HBoxContainer.new()
	deal_row.add_theme_constant_override("separation", 8)
	box.add_child(deal_row)
	price_spin = SpinBox.new()
	price_spin.min_value = 0
	price_spin.max_value = 99999
	price_spin.step = 10
	price_spin.value = 800
	price_spin.prefix = "¥ "
	price_spin.custom_minimum_size = Vector2(170, 44)
	deal_row.add_child(price_spin)
	offer_button = _make_button("提出报价", true)
	offer_button.pressed.connect(func(): _perform_action("offer", {"amount": int(price_spin.value)}, "我提出报价 ¥%d。" % int(price_spin.value)))
	deal_row.add_child(offer_button)
	end_button = _make_button("放弃本次交易", false)
	end_button.pressed.connect(func(): _perform_action("decline", {}, "这次就算了。"))
	deal_row.add_child(end_button)
	return panel

func _build_ledger_panel() -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size.x = 340
	panel.add_theme_stylebox_override("panel", _panel_style(PANEL_ALT, Color("#4d493f"), 1, 10))
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	panel.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	margin.add_child(box)
	var tabs := TabContainer.new()
	tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tabs.add_theme_color_override("font_selected_color", GOLD_LIGHT)
	box.add_child(tabs)
	var inventory_tab := VBoxContainer.new()
	inventory_tab.name = "库存"
	inventory_tab.add_theme_constant_override("separation", 8)
	tabs.add_child(inventory_tab)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size.y = 210
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	inventory_tab.add_child(scroll)
	inventory_list = VBoxContainer.new()
	inventory_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inventory_list.add_theme_constant_override("separation", 6)
	scroll.add_child(inventory_list)
	inventory_detail = RichTextLabel.new()
	inventory_detail.bbcode_enabled = true
	inventory_detail.custom_minimum_size.y = 150
	inventory_detail.add_theme_color_override("default_color", PAPER_DARK)
	inventory_detail.add_theme_font_size_override("normal_font_size", 14)
	inventory_tab.add_child(inventory_detail)
	var inventory_facts := _make_button("查看所选库存的完整记录", false)
	inventory_facts.pressed.connect(func(): _show_item_record(true))
	inventory_tab.add_child(inventory_facts)
	var inv_actions := HBoxContainer.new()
	inventory_tab.add_child(inv_actions)
	recommend_button = _make_button("推荐给客人", true)
	recommend_button.pressed.connect(func(): _perform_action("recommend", {}, "我想向你推荐这件物品。"))
	inv_actions.add_child(recommend_button)
	appraise_inventory_button = _make_button("重新鉴定", false)
	appraise_inventory_button.pressed.connect(func(): _perform_action("appraise_inventory", {}, "我再仔细鉴定一下这件库存物品。"))
	inv_actions.add_child(appraise_inventory_button)
	var notes_tab := VBoxContainer.new()
	notes_tab.name = "线索"
	tabs.add_child(notes_tab)
	notes_label = RichTextLabel.new()
	notes_label.bbcode_enabled = true
	notes_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	notes_label.add_theme_color_override("default_color", PAPER_DARK)
	notes_label.add_theme_font_size_override("normal_font_size", 15)
	notes_tab.add_child(notes_label)
	var ledger_tab := VBoxContainer.new()
	ledger_tab.name = "账本"
	tabs.add_child(ledger_tab)
	ledger_label = RichTextLabel.new()
	ledger_label.bbcode_enabled = true
	ledger_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	ledger_label.add_theme_color_override("default_color", PAPER_DARK)
	ledger_label.add_theme_font_size_override("normal_font_size", 15)
	ledger_tab.add_child(ledger_label)
	return panel

func _build_review_view() -> Control:
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", _panel_style(PANEL, GOLD, 1, 12))
	scroll.add_child(panel)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 34)
	margin.add_theme_constant_override("margin_right", 34)
	margin.add_theme_constant_override("margin_top", 28)
	margin.add_theme_constant_override("margin_bottom", 28)
	panel.add_child(margin)
	var box := VBoxContainer.new()
	box.name = "ReviewContent"
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 16)
	margin.add_child(box)
	return scroll

func _panel_style(color: Color, border_color: Color, width: int, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = border_color
	style.set_border_width_all(width)
	style.set_corner_radius_all(radius)
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	return style

func _make_button(text_value: String, primary: bool) -> Button:
	var button := Button.new()
	button.text = text_value
	button.custom_minimum_size.y = 42
	button.add_theme_color_override("font_color", INK if primary else PAPER_DARK)
	button.add_theme_color_override("font_hover_color", INK if primary else PAPER)
	button.add_theme_stylebox_override("normal", _panel_style(GOLD if primary else Color("#38332b"), GOLD if primary else Color("#615a4e"), 1, 6))
	button.add_theme_stylebox_override("hover", _panel_style(GOLD_LIGHT if primary else Color("#484138"), GOLD_LIGHT, 1, 6))
	button.add_theme_stylebox_override("pressed", _panel_style(Color("#9f7c42") if primary else Color("#302c26"), GOLD, 1, 6))
	return button

func _style_line_edit(line: LineEdit, light := false) -> void:
	line.add_theme_color_override("font_color", INK if light else PAPER)
	line.add_theme_color_override("font_placeholder_color", Color("#766f62"))
	line.add_theme_stylebox_override("normal", _panel_style(Color("#f5ecd9") if light else Color("#191713"), Color("#9b865f"), 1, 6))
	line.add_theme_stylebox_override("focus", _panel_style(Color("#fff8e8") if light else Color("#191713"), GOLD_LIGHT, 2, 6))

func _style_text_edit(edit: TextEdit) -> void:
	edit.add_theme_color_override("font_color", PAPER)
	edit.add_theme_color_override("font_placeholder_color", Color("#766f62"))
	edit.add_theme_stylebox_override("normal", _panel_style(Color("#191713"), Color("#9b865f"), 1, 6))
	edit.add_theme_stylebox_override("focus", _panel_style(Color("#191713"), GOLD_LIGHT, 2, 6))

func _show_setup() -> void:
	setup_view.visible = true
	game_view.visible = false
	review_view.visible = false
	header_phase.text = "尚未营业"

func _test_connection() -> void:
	if api_key_edit.text.strip_edges().is_empty():
		setup_status.text = "请先填写 API Key。"
		setup_status.add_theme_color_override("font_color", RED)
		return
	_set_setup_busy(true)
	pending_mode = "test"
	_configure_llm()
	var error := llm.test_connection()
	if error != OK:
		_set_setup_busy(false)

func _start_with_connection() -> void:
	if api_key_edit.text.strip_edges().is_empty():
		setup_status.text = "真实 LLM 模式需要 API Key，不能跳过。"
		setup_status.add_theme_color_override("font_color", RED)
		return
	_set_setup_busy(true)
	pending_mode = "start_test"
	_configure_llm()
	var error := llm.test_connection()
	if error != OK:
		_set_setup_busy(false)

func _set_setup_busy(value: bool) -> void:
	connect_button.disabled = value
	start_button.disabled = value
	api_key_edit.editable = not value
	model_edit.editable = not value
	base_url_edit.editable = not value
	endpoint_edit.editable = not value
	temperature_edit.editable = not value
	max_tokens_edit.editable = not value
	timeout_edit.editable = not value
	organization_edit.editable = not value
	extra_headers_edit.editable = not value
	provider_option.disabled = value
	protocol_option.disabled = value
	chat_token_option.disabled = value
	store_check.disabled = value
	setup_status.text = "正在连接真实 LLM……" if value else setup_status.text
	setup_status.add_theme_color_override("font_color", GOLD_LIGHT if value else MUTED)

func _configure_llm() -> void:
	var temperature := -1.0 if temperature_edit.text.strip_edges().is_empty() else clampf(float(temperature_edit.text.strip_edges()), 0.0, 2.0)
	var max_tokens := maxi(int(max_tokens_edit.text.strip_edges()), 16)
	var timeout_seconds := maxf(float(timeout_edit.text.strip_edges()), 5.0)
	var protocol := "chat_completions" if protocol_option.selected == 1 else "responses"
	var token_parameter := "max_completion_tokens" if chat_token_option.selected == 1 else "max_tokens"
	llm.configure(api_key_edit.text, model_edit.text, base_url_edit.text, endpoint_edit.text,
		protocol, temperature, max_tokens, timeout_seconds, organization_edit.text,
		extra_headers_edit.text, store_check.button_pressed, token_parameter)

func _begin_day() -> void:
	core.reset()
	setup_view.visible = false
	game_view.visible = true
	review_view.visible = false
	header_phase.text = "第一日 · 上午"
	dialogue.clear()
	conversation_history.clear()
	_append_system("今日经营主题：旧宅清理。城里最近有几户人家在整理老宅，来路各异的旧物开始流入市场。")
	_refresh_all()
	_start_next_guest()

func _start_next_guest() -> void:
	var guest := core.next_guest()
	if guest.is_empty():
		_show_closing()
		return
	at_noon = false
	continue_button.visible = false
	dialogue.clear()
	conversation_history.clear()
	_refresh_all()
	_append_system("%s，第 %d 位客人走进店里。来意需要通过交谈确认。" % [guest["period"], core.current_index + 1])
	_request_llm("客人刚刚进店。", str(guest["opening_fact"]), false)

func _refresh_all() -> void:
	header_money.text = "资金  ¥%s" % _format_number(core.money)
	header_inventory.text = "库存  %d 件" % core.inventory.size()
	header_growth.text = "知识 %d  ·  经验 %d" % [core.knowledge, core.experience]
	if not core.current_guest.is_empty():
		header_phase.text = "第一日 · %s" % core.current_period()
		portrait_label.text = str(core.current_guest["portrait"])
		guest_name_label.text = str(core.current_guest["name"])
		guest_subtitle_label.text = str(core.current_guest["subtitle"])
		guest_role_label.text = "来意：%s" % core.visible_guest_role()
		attitude_label.text = "态度：%s" % core.patience_label()
		if not core.current_guest.get("role_revealed", false):
			object_title_label.text = "柜台"
			object_info_label.text = "[color=#8e8778]客人还没有说明来意。先听听对方怎么说。[/color]"
		elif core.current_guest["role"] == "seller":
			var item: Dictionary = core.current_guest["item"]
			object_title_label.text = str(item["title"])
			object_info_label.text = "[color=#8e8778]确定类别[/color]  %s\n[color=#8e8778]卖家开价[/color]  ¥%s\n[color=#8e8778]已发现线索[/color]  %d 条" % [item["category"], _format_number(int(core.current_guest["ask_price"])), item["revealed_clues"].size()]
		else:
			object_title_label.text = "买家需求"
			var revealed: Dictionary = core.current_guest["revealed"]
			object_info_label.text = "[color=#8e8778]公开方向[/color]  %s\n[color=#8e8778]用途[/color]  %s\n[color=#8e8778]预算[/color]  %s" % [str(core.current_guest["need"]["category"]) if revealed.has("need") else "尚待交谈", "已了解" if revealed.has("purpose") else "尚不明确", str(core.current_guest["need"]["public_budget"]) if revealed.has("budget") else "尚不明确"]
	_build_quick_actions()
	_refresh_inventory()
	_refresh_notes()
	_refresh_ledger()

func _build_quick_actions() -> void:
	for child in quick_actions.get_children():
		child.queue_free()
	if core.current_guest.is_empty():
		return
	if not core.current_guest.get("role_revealed", false):
		offer_button.text = "等待客人说明来意"
		recommend_button.visible = false
		return
	var actions: Array
	if core.current_guest["role"] == "seller":
		actions = [["问来历", "source"], ["问修补", "repair"], ["问心理价", "price"], ["观察器物", "inspect"], ["正式鉴定", "appraise"]]
		offer_button.text = "提出收购价"
		recommend_button.visible = false
	else:
		actions = [["问具体需求", "need"], ["问真实用途", "purpose"], ["问预算", "budget"], ["问年代偏好", "era"]]
		offer_button.text = "提出售价"
		recommend_button.visible = true
	for pair in actions:
		var button := _make_button(str(pair[0]), false)
		button.custom_minimum_size.y = 34
		var action := str(pair[1])
		button.pressed.connect(func(): _perform_action(action, {}, "我想%s。" % str(pair[0])))
		quick_actions.add_child(button)

func _refresh_inventory() -> void:
	for child in inventory_list.get_children():
		child.queue_free()
	for item in core.inventory:
		var label := "%s  ·  %s" % [item["title"], item["category"]]
		if not core.current_guest.is_empty() and core.current_guest.get("role") == "buyer" and core.current_guest["revealed"].has("need"):
			var match_level := core.get_match_level(item, core.current_guest)
			if match_level == "exact": label = "◆ " + label
			elif match_level == "weak": label = "◇ " + label
		var button := _make_button(label, false)
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		var item_id := str(item["id"])
		button.pressed.connect(func(): _select_inventory(item_id))
		inventory_list.add_child(button)
	if core.selected_item_id.is_empty() and not core.inventory.is_empty():
		_select_inventory(str(core.inventory[0]["id"]))
	elif not core.selected_item_id.is_empty():
		_update_inventory_detail(core.get_inventory_item(core.selected_item_id))

func _select_inventory(item_id: String) -> void:
	core.select_item(item_id)
	_update_inventory_detail(core.get_inventory_item(item_id))

func _update_inventory_detail(item: Dictionary) -> void:
	if item.is_empty():
		inventory_detail.text = "库存为空。"
		return
	var status := "已鉴定 · %d%%" % int(item["probability"]) if item.get("appraised", false) else "尚未重新鉴定"
	inventory_detail.text = "[color=#d8be83][font_size=17]%s[/font_size][/color]\n类别：%s\n账面成本：¥%s\n判断：%s\n%s" % [item["title"], item["category"], _format_number(int(item["cost"])), status, item.get("public_provenance", "尚无来源记录")]

func _refresh_notes() -> void:
	if core.day_notes.is_empty():
		notes_label.text = "[color=#8e8778]尚未记录线索。观察、询问与鉴定会在这里留下记录。[/color]"
		return
	var lines: Array[String] = []
	for note in core.day_notes:
		lines.append("• %s" % note)
	notes_label.text = "\n\n".join(lines)

func _refresh_ledger() -> void:
	var lines: Array[String] = ["期初资金  ¥3,600"]
	for entry in core.ledger:
		var amount := int(entry["amount"])
		lines.append("%s  %s\n%s¥%s · %s" % [entry["type"], entry["item"], "+" if amount >= 0 else "−", _format_number(abs(amount)), entry["guest"]])
	lines.append("[color=#d8be83]当前资金  ¥%s[/color]" % _format_number(core.money))
	ledger_label.text = "\n\n".join(lines)

func _send_free_text() -> void:
	var text_value := input_edit.text.strip_edges()
	if text_value.is_empty() or awaiting_llm:
		return
	input_edit.clear()
	var classified := core.classify_free_text(text_value)
	_perform_action(str(classified["action"]), classified, text_value)

func _perform_action(action: String, payload: Dictionary, player_text: String) -> void:
	if awaiting_llm or core.current_guest.is_empty() or core.current_guest.get("completed", false):
		return
	_append_player(player_text)
	var result := core.process_action(action, payload)
	_append_system(str(result["system_text"]))
	_refresh_all()
	var speaker := str(result.get("speaker", "inner" if result.get("appraisal", false) else "npc"))
	_request_llm(player_text, str(result["llm_instruction"]), bool(result.get("completed", false)), speaker)

func _request_llm(player_text: String, instruction: String, completed: bool, speaker := "npc") -> void:
	pending_mode = "npc"
	pending_player_text = player_text
	pending_instruction = instruction
	pending_completed = completed
	pending_speaker = speaker
	awaiting_llm = true
	_set_game_controls(false)
	toast_label.text = "正在整理心中判断……" if speaker == "inner" else "客人正在回应……"
	var guest := core.current_guest
	llm.request_npc_reply(str(guest["name"]), str(guest["personality"]), player_text, instruction, conversation_history, speaker)

func _on_llm_response(ok: bool, text_value: String, error_message: String) -> void:
	if pending_mode == "test" or pending_mode == "start_test":
		var should_start := pending_mode == "start_test"
		pending_mode = ""
		_set_setup_busy(false)
		if ok:
			setup_status.text = "连接成功 · %s" % model_edit.text
			setup_status.add_theme_color_override("font_color", JADE)
			if should_start:
				_begin_day()
		else:
			setup_status.text = error_message
			setup_status.add_theme_color_override("font_color", RED)
		return
	awaiting_llm = not ok
	reply_needs_retry = not ok
	if ok:
		if pending_speaker == "inner":
			_append_inner(text_value)
		else:
			_append_npc(text_value)
		if pending_player_text == "客人刚刚进店。":
			core.current_guest["role_revealed"] = true
			for topic in core.current_guest.get("opening_reveals", []):
				core.current_guest["revealed"][topic] = true
			_refresh_all()
		toast_label.text = "真实 LLM 已回应"
		if pending_completed:
			_set_game_controls(false)
			continue_button.visible = true
			continue_button.text = "进入午间过场" if core.current_index == 1 else ("结束营业" if core.current_index == 3 else "接待下一位客人")
		else:
			_set_game_controls(true)
	else:
		toast_label.text = "LLM 连接失败：%s" % error_message
		_set_game_controls(false)
		_append_system("对白生成失败：%s\n重试只补全当前回应，已经结算的交易和调查不会重复执行。" % error_message)
		continue_button.visible = true
		continue_button.text = "重试 LLM 回应"
	pending_mode = ""

func _retry_llm() -> void:
	continue_button.visible = false
	reply_needs_retry = false
	_request_llm(pending_player_text, pending_instruction, pending_completed, pending_speaker)

func _set_game_controls(enabled: bool) -> void:
	input_edit.editable = enabled
	send_button.disabled = not enabled
	price_spin.editable = enabled
	offer_button.disabled = not enabled
	end_button.disabled = not enabled
	recommend_button.disabled = not enabled
	appraise_inventory_button.disabled = not enabled
	for child in quick_actions.get_children():
		if child is Button:
			child.disabled = not enabled

func _continue_flow() -> void:
	if reply_needs_retry:
		_retry_llm()
		return
	if awaiting_llm:
		return
	continue_button.visible = false
	if core.current_index == 1 and not at_noon:
		at_noon = true
		header_phase.text = "第一日 · 午间"
		dialogue.clear()
		_append_system("午间过场。上午的客人已经离店。你可以查看库存、线索和账本；准备好后进入下午营业。")
		continue_button.text = "进入下午营业"
		continue_button.visible = true
		return
	if at_noon:
		at_noon = false
	_start_next_guest()

func _show_closing() -> void:
	game_view.visible = false
	review_view.visible = true
	header_phase.text = "第一日 · 闭店"
	var content := review_view.find_child("ReviewContent", true, false) as VBoxContainer
	for child in content.get_children():
		child.queue_free()
	var title := Label.new()
	title.text = "闭店结算"
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", GOLD_LIGHT)
	content.add_child(title)
	var summary := core.closing_summary()
	var stats := Label.new()
	stats.text = "期末资金  ¥%s    今日收入  ¥%s    今日支出  ¥%s    净现金变化  %s¥%s\n期末库存  %d 件    完成鉴定  %d 次    全局信誉  %s" % [_format_number(summary["money"]), _format_number(summary["earned"]), _format_number(summary["spent"]), "+" if summary["net"] >= 0 else "−", _format_number(abs(summary["net"])), summary["inventory_count"], summary["appraisals"], core.global_trust]
	stats.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	stats.add_theme_font_size_override("font_size", 18)
	stats.add_theme_color_override("font_color", PAPER)
	content.add_child(stats)
	var divider := HSeparator.new()
	content.add_child(divider)
	var review_title := Label.new()
	review_title.text = "设计复盘 · 以下内容包含后台真相"
	review_title.add_theme_font_size_override("font_size", 25)
	review_title.add_theme_color_override("font_color", Color("#d78b79"))
	content.add_child(review_title)
	var intro := Label.new()
	intro.text = "该页面只用于验收，不属于玩家正常信息。它对照 Game Core 的权威状态，显示每名客人的隐藏意图、器物真相、可错过线索与实际结果。"
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	intro.add_theme_color_override("font_color", PAPER_DARK)
	content.add_child(intro)
	for row in core.design_review_rows():
		var card := PanelContainer.new()
		card.add_theme_stylebox_override("panel", _panel_style(PANEL_ALT, Color("#514a3d"), 1, 8))
		content.add_child(card)
		var margin := MarginContainer.new()
		margin.add_theme_constant_override("margin_left", 18)
		margin.add_theme_constant_override("margin_right", 18)
		margin.add_theme_constant_override("margin_top", 14)
		margin.add_theme_constant_override("margin_bottom", 14)
		card.add_child(margin)
		var text_label := RichTextLabel.new()
		text_label.bbcode_enabled = true
		text_label.fit_content = true
		text_label.custom_minimum_size.y = 130
		text_label.add_theme_color_override("default_color", PAPER_DARK)
		text_label.text = "[color=#d8be83][font_size=20]%s[/font_size][/color]  ·  %s\n[color=#8e8778]后台真相[/color]  %s\n[color=#8e8778]可判断线索[/color]  %s\n[color=#8e8778]本次结果[/color]  %s" % [row["name"], row["role"], row["truth"], row["missable"], row["outcome"]]
		margin.add_child(text_label)
	var restart := _make_button("重新开始这一天", true)
	restart.pressed.connect(_restart_demo)
	content.add_child(restart)

func _restart_demo() -> void:
	review_view.visible = false
	setup_view.visible = true
	header_phase.text = "尚未营业"
	setup_status.text = "Key 仍只保存在当前运行内存中。点击连接并开始营业。"

func _append_player(text_value: String) -> void:
	dialogue.append_text("[color=#6c4b2f][b]你[/b][/color]\n%s\n\n" % text_value)
	conversation_history.append("玩家：%s" % text_value)

func _append_npc(text_value: String) -> void:
	var name_value := str(core.current_guest.get("name", "客人"))
	dialogue.append_text("[color=#873d35][b]%s[/b][/color]\n%s\n\n" % [name_value, text_value])
	conversation_history.append("%s：%s" % [name_value, text_value])

func _append_inner(text_value: String) -> void:
	dialogue.append_text("[color=#607968][b]心中判断[/b][/color]\n[i]%s[/i]\n\n" % text_value)
	conversation_history.append("玩家内心判断：%s" % text_value)

func _append_system(text_value: String) -> void:
	dialogue.append_text("[color=#777064][font_size=14]◆ %s[/font_size][/color]\n\n" % text_value)

func _format_number(value: int) -> String:
	var raw := str(value)
	var result := ""
	var count := 0
	for i in range(raw.length() - 1, -1, -1):
		if count > 0 and count % 3 == 0:
			result = "," + result
		result = raw[i] + result
		count += 1
	return result
