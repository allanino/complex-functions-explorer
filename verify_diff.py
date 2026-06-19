def check_arcsin():
    import cmath
    # Simulating what happens in get_field_with_derivatives for arcsin(z)
    def arcsin(z):
        # 1 - z^2
        one_minus_z2 = 1 - z**2

        # sqrt(1-z^2)
        r = abs(one_minus_z2)
        theta = cmath.phase(one_minus_z2)
        sqrt_val = cmath.rect(r**(0.5), theta/2)

        iz = complex(-z.imag, z.real)
        return -1j * cmath.log(iz + sqrt_val)

    def arcsin_branch1_terrain(x, z):
        # terrain passing branch_offset 0
        z_terrain = complex(x, -z)
        z_math = z_terrain
        # B = current_branch + branch_offset = 1 + 0 = 1
        return arcsin(z_math)

    # ... Wait, if terrain evaluates current_branch + branch_offset and minimap passes 0, it works!
check_arcsin()
