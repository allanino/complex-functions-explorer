extends SceneTree

func _init():
    var slider = HSlider.new()
    slider.min_value = 0
    slider.max_value = 10000
    slider.value = 5000

    slider.value_changed.connect(func(v): print("value_changed emitted: ", v))

    print("Setting max_value to 20")
    slider.max_value = 20

    print("Slider value is now: ", slider.value)
    quit()
