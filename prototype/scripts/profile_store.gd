class_name ProtectedProfileStore
extends RefCounted

const FILE_NAME := "api_profile.dpapi"

static func exists(testing := false) -> bool:
	return FileAccess.file_exists("user://" + ("test_api_profile.dpapi" if testing else FILE_NAME))

static func operate(operation: String, profile: Dictionary = {}, testing := false) -> Dictionary:
	if OS.get_name() != "Windows": return {"ok": false, "error": "此版本的受保护凭据保存仅支持Windows，不会回退为明文。"}
	var script := ProjectSettings.globalize_path("res://tools/protected_profile.ps1")
	var process := OS.execute_with_pipe("powershell.exe", ["-NoProfile", "-NonInteractive", "-WindowStyle", "Hidden", "-File", script], false)
	if process.is_empty(): return {"ok": false, "error": "无法启动本机凭据保护组件。"}
	var pipe: FileAccess = process["stdio"]
	pipe.store_line(JSON.stringify({"op": operation, "root": ProjectSettings.globalize_path("user://").trim_suffix("/"), "name": "test_api_profile.dpapi" if testing else FILE_NAME, "profile": profile}))
	pipe.flush()
	var response := PackedByteArray()
	var deadline := Time.get_ticks_msec() + 10000
	while Time.get_ticks_msec() < deadline:
		var chunk := pipe.get_buffer(4096)
		if not chunk.is_empty():
			response.append_array(chunk)
			if response.has(10): break
		if not OS.is_process_running(int(process["pid"])) and chunk.is_empty(): break
		OS.delay_msec(10)
	if OS.is_process_running(int(process["pid"])): OS.kill(int(process["pid"]))
	pipe.close()
	process["stderr"].close()
	var parser := JSON.new()
	if parser.parse(response.get_string_from_utf8().strip_edges()) != OK or not parser.data is Dictionary:
		return {"ok": false, "error": "凭据组件未正常返回；未保存明文。"}
	return parser.data
