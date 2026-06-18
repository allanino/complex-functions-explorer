1. **Add `_is_close_to_zero_core` and corresponding wrapper functions to `ComplexFunctions` in C++**:
   - Declare `_is_close_to_zero_core`, `eta_is_close_to_zero`, `zeta_is_close_to_zero`, and `beta_is_close_to_zero` in `math/cpp/complex_functions.h`.
   - Implement them in `math/cpp/complex_functions.cpp`.
   - Bind the methods to Godot in `_bind_methods` so they can be accessed from GDScript.

2. **Update GDScript `is_close_to_zero` in `math/complex_field.gd` to use the C++ methods**:
   - Check if C++ backend exists and the function is supported.
   - If so, call the corresponding `is_close_to_zero` method and return `[is_close, z_mid]`.

3. **Complete pre-commit steps**:
   - Build Godot C++ extension.
   - Test if the project runs fine.
   - Run tests if applicable.

4. **Submit the changes**.
