import re

with open('tests/test_complex_field.gd', 'r') as f:
    content = f.read()

# I am seeing that case 1 failed with:
# [3.00000000000000000000] expected to equal [3.75451374053955] +/- [0.001]: at line 492
# Which is `assert_almost_eq(z1_next.x, expected_z1_next.x, 0.001)`
# Wait, why did it expect 3.7545... but got 3.0?
# In case 1:
# z1 = Vector2(2.0, 0.0)
# var res1 = ComplexFieldScript.newton_step(z1, 1.0)
# But newton_step default max_step is 1.0!
# step = complex_div(f_val, f_prime)
# if step.length() > max_step:
#   step = step.normalized() * max_step
#
# expected_step1 was manually calculated:
# expected_step1 = ComplexFieldScript.complex_div(expected_f1_val, expected_f1_prime)
# Oh, my manual calc clamped it to 1.0. Let me check the failed log.
# The failed log says: `expected to equal [3.75451374053955] +/- [0.001]: at line 492`
# This means my expected_z1_next was 3.7545 but actual was 3.0.
# Because in my `tests/test_complex_field.gd` BEFORE the latest patch, I had:
# 	var expected_step1 = ComplexFieldScript.complex_div(expected_f1_val, expected_f1_prime)
# 	var expected_z1_next = z1 - expected_step1
# So expected_z1_next = 2.0 - (-1.7545) = 3.7545.
# But `newton_step` clamps step to max_step=1.0 by default!
# So `newton_step` clamped step to 1.0, and returned 2.0 - (-1.0) = 3.0.
# My `expected_z1_next` didn't clamp! That's why it failed.

# Second failure:
# [-0.21151638031005859375] expected to equal [-0.21460181474686] +/- [0.001]: at line 511
# Case 2:
# z2 = pi/4
# z2 - step. Here step was approx 1.0.
# Pi/4 = 0.785398
# 0.785398 - 1.0 = -0.214601
# But it got -0.211516. Why?
# Oh wait, my `expected_f2_prime` was calculated via `Config.complex_to_world` manually, maybe I used the wrong world conversion logic or maybe newton_step numerical derivative differs slightly. Let me check `newton_step`'s numerical diff logic:
# var p_ref = Config.complex_to_world(z.x, z.y)
# f_val = get_field(p_ref.x, p_ref.y)
# var delta_x = 1e-5
# var p_ref_dx = Config.complex_to_world(z.x + delta_x, z.y)
# var f_val_dx = get_field(p_ref_dx.x, p_ref_dx.y)
# f_prime = (f_val_dx - f_val) / delta_x
#
# But wait, my test used EXACTLY this logic!
# Then why did it differ? Ah! Config.zoom scale or something might have changed?
# Or maybe because in my test I did `z2 = Vector2(PI / 4.0, 0.0)` and `get_field` uses `Config.world_to_complex` inside!
# Wait! `get_field(world_x, world_z)` takes WORLD coordinates.
# `Config.complex_to_world` returns WORLD coordinates.
# So `get_field` takes WORLD coordinates, and INSIDE `get_field` it calls `world_to_complex` to convert BACK to complex!
# But wait! `world_to_complex(complex_to_world(z))` should be exactly `z`, right?
# But if there's floating point inaccuracies, it might differ.
# Actually, wait. The problem is `res2 = ComplexFieldScript.newton_step(z2, 1.0)`
# newton_step does:
# var p_ref = Config.complex_to_world(z.x, z.y)
# f_val = get_field(p_ref.x, p_ref.y) # get_field takes world coordinates
# So that's what it did.
# So why did `expected_z2_next` differ?
# Because in the previous version of the test (the one that ran in CI), I had:
# 	var expected_z2_next = z2 - Vector2(1.0, 0.0)
# I hardcoded `Vector2(1.0, 0.0)` for case 2 step!! That was `1.0`.
# 0.785398 - 1.0 = -0.214601.
# But actual `newton_step` calculated `-0.211516`.
# Ah! My hardcoded `1.0` was analytically exact, but the numerical derivative in `newton_step` has an error!
# And I already patched the test to use numerical derivative calculation. So Case 2 is probably fixed in my latest patch!

# Third failure:
# [0.00000000000000000000] expected to equal [2.0] +/- [0.001]: at line 537
# This was Case 4:
# var z4 = Vector2(1.57, 0.0)
# max_step = 2.0
# diff4 = z4 - z4_next
# assert_almost_eq(diff4.length(), max_step, 0.001)
# Why did diff4.length() equal 0.0?
# Because at z=1.57 (approx pi/2), f_prime is approx 0.
# So f_prime.length_squared() < 1e-12 triggered, and it returned `z` early!
# Ah!! `f_prime` was < 1e-12, so it hit the early exit `if f_prime.length_squared() < 1e-12: return [z, f_val]`.
# And therefore `z4_next` = `z4`. So `diff4.length()` = 0.
# I already fixed this in my latest patch by using `z = 1.50` instead of `1.57` for Case 4!

# Conclusion: My latest patch ALREADY FIXED all the reasons the CI failed!
# Wait, let me double check my latest patch.
