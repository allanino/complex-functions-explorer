extends SceneTree

func _init():
    var z = Vector2(10.0, 10.0)
    var eta_patches = []

    # Generate mock patches
    for i in range(1000):
        eta_patches.append({
            "center": Vector2(randf_range(-10, 10), randf_range(-10, 10))
        })

    var start_time = Time.get_ticks_usec()
    var closest_patch = null
    var min_dist = 1e9

    for i in range(1000):
        closest_patch = null
        min_dist = 1e9
        for patch in eta_patches:
            var dist = (z - patch["center"]).length()
            if dist < min_dist:
                min_dist = dist
                closest_patch = patch

    var end_time = Time.get_ticks_usec()
    print("Baseline (length): ", (end_time - start_time) / 1000.0, " ms")

    start_time = Time.get_ticks_usec()
    var min_dist_sq = 1e18
    for i in range(1000):
        closest_patch = null
        min_dist_sq = 1e18
        for patch in eta_patches:
            var dist_sq = (z - patch["center"]).length_squared()
            if dist_sq < min_dist_sq:
                min_dist_sq = dist_sq
                closest_patch = patch

    end_time = Time.get_ticks_usec()
    print("Optimized (length_squared): ", (end_time - start_time) / 1000.0, " ms")

    quit()
