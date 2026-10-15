# Release-safe logging policy

Routine diagnostics use `games/global/ReleaseLog.gd`. `ReleaseLog.info()` emits only in a debug build (`OS.is_debug_build()`); release exports do not print per-input or per-suggestion traces. Actionable failures remain `push_error()`/`push_warning()` calls and are not suppressed.

The first bounded migration covers the glossary search/CanvasLayer flow in `games/glossary/main.gd`, which previously emitted 23 direct prints including mouse and text-change events. No gameplay branch depends on logging side effects. Additional feature migrations can follow the same preload-and-boundary pattern after the architecture checkpoint.
