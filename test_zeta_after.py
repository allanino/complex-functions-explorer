import subprocess
import re

with open("tests/test_complex_field.gd", "r") as f:
    content = f.read()

# Since we don't have godot tests natively running, I will write a python harness to run the GDScript snippet we care about
harness = """
extends SceneTree
func _init():
    var res = ComplexFieldScript.zeta_continuation_power_series_with_derivatives(-2.0, 0.0, 2000)
    print("RES_X: ", res[0].x, " RES_Y: ", res[0].y)
    quit()
"""
with open("test_harness.gd", "w") as f:
    f.write(harness)

# Wait we cannot run godot! So I will verify using syntax checks.
