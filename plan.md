1. **Create `DoubleVector2` class**: I already created `math/double_vector2.gd` with basic operations and complex operations matching those needed for the calculations in `math/complex_field.gd` that truncation occurs. I'll make sure it has the required methods.
2. **Update `eta_borwein_with_derivatives`**: Change it to return an array of `DoubleVector2` instead of `Vector2`. Inside the function, the sums are accumulated as scalar floats, which are 64-bit doubles in GDScript. We will wrap the final sums using `DoubleVector2.new(sum_val_x, sum_val_y)` etc instead of `Vector2`.
3. **Update `zeta_borwein_with_derivatives`**: Use `DoubleVector2` for all calculations instead of `Vector2`. Convert `two_term`, `denom`, `ddenom_dx`, `d2denom_dx2` to use `DoubleVector2`, and do `complex_mul`/`complex_div` using the `DoubleVector2` class methods.
4. **Update `newton_step` in `math/complex_field.gd`**:
   - The method takes `z: Vector2`, we'll keep `z: Vector2` or we might convert to `DoubleVector2` locally or change signature to `z: DoubleVector2`. The prompt asks to "Make the newton_step whole pipeline work with double", so `newton_step` should probably accept `DoubleVector2` or take `Vector2` and turn it into `DoubleVector2`. The user mentions "The idea is that each Newton step refined z will be a pair of double float numbers", implying we probably should change the type of `z` to `DoubleVector2` or at least return an Array of `DoubleVector2`. I will accept `z: Variant` or `z: DoubleVector2` but in GDScript, it's safer to just let it take `Variant` and check, or change it directly in `player_controller.gd`. I'll update it to take `Variant` (to support `Vector2` or `DoubleVector2`) and return `[DoubleVector2, DoubleVector2]`.
   - Update internal `f_val`, `f_prime`, `f_second` to be `DoubleVector2`.
   - Update calculations inside `newton_step` to use `DoubleVector2` operations.
   - For `zeta_with_derivatives`, `dirichlet_eta_with_derivatives` which still return `Vector2` array, convert them to `DoubleVector2` when accessed in `newton_step`.
5. **Update `player/player_controller.gd`**:
   - Update variables storing `z` to handle `DoubleVector2` instead of `Vector2`.
   - Make sure `distance_to` and `.x` / `.y` are correctly called.
   - Ensure `path.append()` which expects `Vector2` gets `.to_vector2()`.
6. **Pre-commit checks**: Run `pre_commit_instructions` and format the code.
