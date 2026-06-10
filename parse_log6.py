import re

print("Look at the test_zeta_continuation_with_derivatives")
print("x=0.5, y=14.134725")
print("This goes into the x >= 0.5 branch!")
print("Which is:")
print("""	if x >= 0.5:
		var z_data = zeta_with_derivatives(x, y, iters)
		var z_val = z_data[0]
		var z_dx = z_data[1]
		var val = complex_log(z_val.x, z_val.y)
		var dx = complex_div(z_dx, z_val)
		return [val, dx]""")
print("Wait... log_zeta_continuation_with_derivatives returns the derivative of log(zeta)!")
print("Then zeta_continuation_with_derivatives does:")
print("""	var log_z = log_zeta_continuation_with_derivatives(x, y, iters)
	var val = complex_exp(log_z[0].x, log_z[0].y)
	var dx = complex_mul(val, log_z[1])
	return [val, dx]""")
print("If x >= 0.5, zeta_continuation_with_derivatives does:")
print("log_z = [log(zeta), zeta'/zeta]")
print("val = exp(log(zeta)) = zeta")
print("dx = val * log_z[1] = zeta * (zeta'/zeta) = zeta'")
print("This seems perfectly correct algebraically.")
print("But why does it fail the test?")
