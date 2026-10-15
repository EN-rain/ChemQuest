extends RefCounted

## Small release-safe logging boundary for routine diagnostics.
## Errors and warnings should continue to use push_error/push_warning at the call site.
static var enabled: bool = OS.is_debug_build()

static func info(message: String) -> void:
	if enabled:
		print("[debug] %s" % message)
