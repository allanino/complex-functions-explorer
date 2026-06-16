extends SceneTree

func _init():
    var Gut = load("res://addons/gut/gut.gd")
    var gut = Gut.new()
    gut.add_directory("res://tests/")
    gut.test_scripts()

    if gut.get_fail_count() > 0:
        print("Tests failed!")
        quit(1)
    else:
        print("Tests passed!")
        quit(0)
