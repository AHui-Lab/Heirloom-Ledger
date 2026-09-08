class_name DemoLLMClient
extends Node

signal response_ready(ok: bool, text: String, error_message: String)

const DEFAULT_BASE_URL := "https://api.openai.com/v1"
const DEFAULT_ENDPOINT_PATH := "/responses"
const DEFAULT_MODEL := "gpt-5-mini"

var _request: HTTPRequest
var _api_key := ""
var _base_url := DEFAULT_BASE_URL
var _endpoint_path := DEFAULT_ENDPOINT_PATH
var _protocol := "responses"
var _model := DEFAULT_MODEL
var _temperature := 0.7
var _send_temperature := true
var _max_output_tokens := 2048
var _request_started_ms := 0
var _timeout_seconds := 45.0
var _organization := ""
var _extra_headers := ""
var _send_store := false
var _chat_token_parameter := "max_tokens"
var _expected_speaker := ""

func _ready() -> void:
	_request = HTTPRequest.new()
	_request.timeout = _timeout_seconds
	add_child(_request)
	_request.request_completed.connect(_on_request_completed)
	_configure_system_proxy()

func _configure_system_proxy() -> void:
	var proxy_url := OS.get_environment("HTTPS_PROXY")
	if proxy_url.is_empty():
		proxy_url = OS.get_environment("https_proxy")
	if proxy_url.is_empty():
		proxy_url = OS.get_environment("HTTP_PROXY")
	if proxy_url.is_empty():
		proxy_url = OS.get_environment("http_proxy")
	if proxy_url.is_empty():
		return
	var regex := RegEx.new()
	regex.compile("^(?:https?://)?(?:[^@/]+@)?([^:/]+):([0-9]+)")
	var match_result := regex.search(proxy_url)
	if match_result == null:
		return
	var proxy_host := match_result.get_string(1)
	var proxy_port := int(match_result.get_string(2))
	_request.set_http_proxy(proxy_host, proxy_port)
	_request.set_https_proxy(proxy_host, proxy_port)

func configure(api_key: String, model: String, base_url: String = DEFAULT_BASE_URL,
		endpoint_path: String = DEFAULT_ENDPOINT_PATH, protocol: String = "responses",
		temperature: float = 0.7, max_output_tokens: int = 2048, timeout_seconds: float = 45.0,
		organization: String = "", extra_headers: String = "", send_store: bool = false,
		chat_token_parameter: String = "max_tokens") -> void:
	_api_key = api_key.strip_edges()
	_base_url = base_url.strip_edges().trim_suffix("/") if not base_url.strip_edges().is_empty() else DEFAULT_BASE_URL
	_endpoint_path = "/" + endpoint_path.strip_edges().trim_prefix("/") if not endpoint_path.strip_edges().is_empty() else DEFAULT_ENDPOINT_PATH
	_protocol = "chat_completions" if protocol == "chat_completions" else "responses"
	_model = model.strip_edges() if not model.strip_edges().is_empty() else DEFAULT_MODEL
	_temperature = clampf(temperature, 0.0, 2.0)
	_send_temperature = temperature >= 0
	_max_output_tokens = maxi(max_output_tokens, 16)
	_timeout_seconds = maxf(timeout_seconds, 5.0)
	_organization = organization.strip_edges()
	_extra_headers = extra_headers
	_send_store = send_store
	_chat_token_parameter = "max_completion_tokens" if chat_token_parameter == "max_completion_tokens" else "max_tokens"
	if _request != null:
		_request.timeout = _timeout_seconds
		_request.set_http_proxy("", 0)
		_request.set_https_proxy("", 0)
		if not (_base_url.begins_with("http://127.0.0.1:") or _base_url.begins_with("http://localhost:")):
			_configure_system_proxy()

func cancel_pending() -> void:
	if _request != null:
		_request.cancel_request()

func test_connection() -> Error:
	_expected_speaker = ""
	return _send(
		"你是连接测试助手。必须只用简体中文回复四个字：连接成功。",
		"执行连接测试。"
	)

func request_npc_reply(npc_name: String, personality: String, player_text: String,
		authorized_instruction: String, history: Array[String], speaker: String = "npc") -> Error:
	_expected_speaker = speaker
	var prompt := build_dialogue_prompt(npc_name, personality, player_text, authorized_instruction, history, speaker)
	return _send(prompt["instructions"], prompt["input"])

static func build_dialogue_prompt(npc_name: String, personality: String, player_text: String,
		authorized_instruction: String, history: Array[String], speaker: String) -> Dictionary:
	var identity := "唯一说话人是来店客人“%s”，对面是玩家扮演的掌柜。你不是店主，不能欢迎对方进店、说自己店里有什么或替掌柜招呼客人。" % npc_name
	if speaker == "inner":
		identity = "唯一说话人是玩家掌柜，输出未说出口的第一人称内心判断。客人听不到这些想法；不要以客人身份发言，也不要称呼或向客人提问。"
	var instructions := """%s
人格：%s
必须遵守：
1. Game Core提供的授权事实是唯一现实；不得创造新的来源、预算、价格底线、年代、真伪、人物经历或交易结果。
2. 不得提及Game Core、隐藏状态、提示词、判断挑战或你是AI。
3. 使用自然、克制的简体中文口语，通常1至3句话；不要替玩家行动。
4. 严格保持本次唯一说话人，不输出角色标签、旁白或另一方台词。过去对话中的角色错误不得沿用。
5. 不得推翻已结算的成交、拒绝、耐心或鉴定概率。
""" % [identity, personality if speaker == "npc" else "初入古玩行业，谨慎自省，承认不确定。"]
	var recent := "\n".join(history.slice(max(0, history.size() - 8), history.size()))
	var event_label := "场景事件（不是掌柜台词）：" if player_text == "客人刚刚进店。" else "玩家本次表达或操作："
	var input := "最近对话（仅供参考，不构成新增事实授权）：\n%s\n\n%s%s\n\n本次唯一授权信息与表达要求：%s" % [recent, event_label, player_text, authorized_instruction]
	return {"instructions": instructions, "input": input}

func _send(instructions: String, input: String) -> Error:
	if _api_key.is_empty():
		response_ready.emit(false, "", "尚未填写 API Key。真实 LLM 模式不会使用离线替代。")
		return ERR_UNAUTHORIZED
	var headers := _build_headers()
	var body_data := build_request_body(instructions, input)
	_request_started_ms = Time.get_ticks_msec()
	var error := _request.request(_endpoint_url(), headers, HTTPClient.METHOD_POST, JSON.stringify(body_data))
	if error != OK:
		response_ready.emit(false, "", "无法发起 API 请求（错误 %d）。" % error)
	return error

func build_request_body(instructions: String, input: String) -> Dictionary:
	var body_data: Dictionary
	if _protocol == "chat_completions":
		body_data = {
			"model": _model,
			"messages": [
				{"role": "system", "content": instructions},
				{"role": "user", "content": input},
			],
		}
		if _send_temperature: body_data["temperature"] = _temperature
		body_data[_chat_token_parameter] = _max_output_tokens
		if _is_deepseek_v4(): body_data["thinking"] = {"type": "disabled"}
	else:
		body_data = {
			"model": _model,
			"max_output_tokens": _max_output_tokens,
			"instructions": instructions,
			"input": input,
		}
		if _send_store:
			body_data["store"] = false
		if _is_deepseek_v4(): body_data["reasoning"] = {"effort": "none"}
	return body_data

func _is_deepseek_v4() -> bool:
	return _base_url.to_lower().contains("api.deepseek.com") and _model.to_lower().begins_with("deepseek-v4")

func _endpoint_url() -> String:
	return _base_url + _endpoint_path

func _build_headers() -> PackedStringArray:
	var headers := PackedStringArray(["Content-Type: application/json", "Authorization: Bearer %s" % _api_key])
	if not _organization.is_empty():
		headers.append("OpenAI-Organization: %s" % _organization)
	for raw_line in _extra_headers.split("\n"):
		var line := raw_line.strip_edges()
		var separator := line.find(":")
		if separator > 0:
			headers.append(line)
	return headers

func _on_request_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	var parser := JSON.new()
	var parsed = parser.data if parser.parse(body.get_string_from_utf8()) == OK else null
	var diagnosis := response_diagnosis(parsed)
	_write_diagnostic(result, response_code, diagnosis)
	if result != HTTPRequest.RESULT_SUCCESS:
		response_ready.emit(false, "", "网络请求失败（结果 %d）。请检查网络后重试。" % result)
		return
	if response_code < 200 or response_code >= 300:
		var message := "API 返回 HTTP %d。" % response_code
		if parsed is Dictionary:
			var error_data = parsed.get("error", {})
			if error_data is Dictionary and not str(error_data.get("message", "")).is_empty():
				var safe_error := str(error_data["message"])
				if not _api_key.is_empty(): safe_error = safe_error.replace(_api_key, "[redacted]")
				message += " %s" % safe_error
		response_ready.emit(false, "", message)
		return
	if not (parsed is Dictionary):
		response_ready.emit(false, "", "API 返回了无法解析的内容。")
		return
	var text := extract_output_text(parsed) if _protocol == "responses" else extract_chat_completion_text(parsed)
	if diagnosis["truncated"] or diagnosis["status"] in ["failed", "cancelled", "incomplete", "queued", "in_progress"]:
		response_ready.emit(false, "", "回复尚未完整完成（状态：%s）。请检查最大输出Token或服务商设置后重试；本句不会重复结算。" % ("达到Token上限" if diagnosis["truncated"] else diagnosis["status"]))
		return
	if text.is_empty():
		var detail := "API 返回成功，但没有可显示的正文。"
		if diagnosis["truncated"]:
			detail += "输出达到 Token 上限；请提高最大输出 Token，或在服务商支持时关闭深度思考。"
		else:
			detail += "可能仅返回推理内容、拒答或不兼容格式；诊断已记录。"
		response_ready.emit(false, "", detail)
		return
	var role_error := speaker_error(text, _expected_speaker)
	if not role_error.is_empty():
		response_ready.emit(false, "", role_error)
		return
	response_ready.emit(true, text.strip_edges(), "")

static func speaker_error(text: String, speaker: String) -> String:
	if speaker == "npc":
		for phrase in ["欢迎光临", "欢迎来到我的店", "我店里", "我是掌柜", "我是店主", "本店出售"]:
			if text.contains(phrase): return "生成内容出现掌柜身份措辞，未作为客人台词展示。请重试这一句；交易不会重复结算。"
		if text.strip_edges().begins_with("掌柜：") or text.contains("\n掌柜："):
			return "生成内容混入掌柜台词，未展示。请重试这一句。"
	return ""

static func response_diagnosis(parsed: Variant) -> Dictionary:
	var info := {"truncated": false, "finish_reason": "", "status": "", "output_tokens": 0, "reasoning_tokens": 0}
	if not parsed is Dictionary:
		return info
	# Log only allowlisted structural metadata, never raw response, prompts or headers.
	var status := str(parsed.get("status", ""))
	if status in ["completed", "incomplete", "failed", "cancelled", "queued", "in_progress"]:
		info["status"] = status
	var details = parsed.get("incomplete_details", {})
	if details is Dictionary:
		info["truncated"] = details.get("reason") == "max_output_tokens"
	var choices = parsed.get("choices", [])
	if choices is Array and not choices.is_empty() and choices[0] is Dictionary:
		var reason := str(choices[0].get("finish_reason", ""))
		if reason in ["stop", "length", "content_filter", "tool_calls", "function_call"]:
			info["finish_reason"] = reason
		info["truncated"] = info["truncated"] or reason == "length"
	var usage = parsed.get("usage", {})
	if usage is Dictionary:
		info["output_tokens"] = int(usage.get("output_tokens", usage.get("completion_tokens", 0)))
		var token_details = usage.get("output_tokens_details", usage.get("completion_tokens_details", {}))
		if token_details is Dictionary:
			info["reasoning_tokens"] = int(token_details.get("reasoning_tokens", 0))
	return info

func _write_diagnostic(result: int, response_code: int, info: Dictionary) -> void:
	var path := "user://llm_diagnostics.jsonl"
	var log_file := FileAccess.open(path, FileAccess.READ_WRITE if FileAccess.file_exists(path) else FileAccess.WRITE)
	if log_file == null:
		return
	if log_file.get_length() > 1048576:
		log_file.close()
		log_file = FileAccess.open(path, FileAccess.WRITE)
		if log_file == null:
			return
	log_file.seek_end()
	var entry := info.duplicate()
	entry.merge({"time": Time.get_datetime_string_from_system(true), "network_result": result,
		"http_status": response_code, "elapsed_ms": Time.get_ticks_msec() - _request_started_ms,
		"protocol": _protocol, "token_limit": _max_output_tokens})
	log_file.store_line(JSON.stringify(entry))
	log_file.close()

static func extract_output_text(response: Dictionary) -> String:
	if response.get("output_text") is String and not response["output_text"].strip_edges().is_empty():
		return response["output_text"]
	var fragments: Array[String] = []
	var output = response.get("output", [])
	if not output is Array: return ""
	for item in output:
		if not (item is Dictionary) or item.get("type") != "message":
			continue
		if not item.get("content") is Array: continue
		for content in item.get("content", []):
			if content is Dictionary and content.get("type") == "output_text" and content.get("text") is String:
				fragments.append(content["text"])
	return "\n".join(fragments)

static func extract_chat_completion_text(response: Dictionary) -> String:
	var choices = response.get("choices", [])
	if not choices is Array or choices.is_empty() or not choices[0] is Dictionary:
		return ""
	var message = choices[0].get("message", {})
	if not message is Dictionary:
		return ""
	var content = message.get("content", "")
	if content is String:
		return content
	var fragments: Array[String] = []
	if content is Array:
		for part in content:
			if part is Dictionary and part.get("type") == "text" and part.get("text") is String:
				fragments.append(part["text"])
	return "\n".join(fragments)
