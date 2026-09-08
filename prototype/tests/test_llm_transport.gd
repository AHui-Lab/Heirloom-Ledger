extends SceneTree

const LLMClientScript = preload("res://scripts/llm_client.gd")

var finished := false

func _initialize() -> void:
	call_deferred("_run_transport_test")

func _run_transport_test() -> void:
	var chat_fixture := {"choices": [{"message": {"content": "连接成功"}}]}
	if LLMClientScript.extract_chat_completion_text(chat_fixture) != "连接成功":
		push_error("FAIL: Chat Completions response parser did not extract message content")
		quit(1)
		return
	var client = LLMClientScript.new()
	root.add_child(client)
	await process_frame
	client.response_ready.connect(_on_response)
	client.configure("sk-invalid-heirloom-ledger-connectivity-test", "gpt-5-mini")
	var error = client.test_connection()
	if error != OK:
		push_error("FAIL: could not start HTTPS request (%d)" % error)
		quit(1)
		return
	var timer := create_timer(50.0)
	timer.timeout.connect(_on_timeout)

func _on_response(ok: bool, _text: String, error_message: String) -> void:
	if finished:
		return
	finished = true
	if ok:
		push_error("FAIL: intentionally invalid key unexpectedly succeeded")
		quit(1)
		return
	if not error_message.contains("HTTP 401"):
		push_error("FAIL: endpoint was reached but expected authenticated rejection, got: %s" % error_message)
		quit(1)
		return
	print("PASS: Godot HTTPS transport reached OpenAI Responses API and handled HTTP 401")
	quit(0)

func _on_timeout() -> void:
	if finished:
		return
	finished = true
	push_error("FAIL: OpenAI transport test timed out")
	quit(1)
