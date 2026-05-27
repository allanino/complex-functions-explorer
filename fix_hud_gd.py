from pathlib import Path

content = Path("scripts/hud.gd").read_text()
# Add back the connection for ExitDetachButton if it was missing?
# Wait, it was missing!
# exit_detach_button.pressed.connect(_on_exit_detach_pressed)
if 'exit_detach_button.pressed.connect(' not in content:
    content = content.replace("	detach_slider.value_changed.connect(_on_detach_slider_changed)", "	detach_slider.value_changed.connect(_on_detach_slider_changed)\n\texit_detach_button.pressed.connect(_on_exit_detach_pressed)")

# And what about the ones we removed?
# The PR says "Because the agent did not update the [connection] definitions at the bottom of the hud.tscn file, nor did it connect the signals programmatically in hud.gd's _ready() function, all signal connections for the settings menu are broken."
# If I didn't connect them programmatically?
# In `fix_all_bugs.py` I REPLACED the `@onready var` logic but DID I DELETE the programmatic connects?
# Let's check `grep "\.connect(" scripts/hud.gd`
