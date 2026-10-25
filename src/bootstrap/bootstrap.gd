extends Control
## E01 startup fixture only. This is not the approved final title screen.

func _ready() -> void:
	if "--bootstrap-smoke" in OS.get_cmdline_user_args():
		if $Title.text != "Roguewood":
			push_error("Bootstrap title missing")
			get_tree().quit(1)
			return
		print("ROGUEWOOD_BOOT_OK")
		get_tree().quit(0)
