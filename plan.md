1. **Analyze Requirements:**
   - The user wants to replace the finite differences method with the exact analytical derivatives from the shader for the `zeta` and `eta` functions (and their variants) within `math/complex_field.gd`.
   - Specifically, we need to bring `zeta_with_derivatives`, `dirichlet_eta_with_derivatives`, and related continuation functions over to GDScript.
   - Use these analytic derivatives in `newton_step` when the function is `ZETA`, `ZETA_REFLECTION`, or `DIRICHLET_ETA` (assuming `input_function_type` is `IDENTITY`).

2. **File Modifications:**
   - Modify `math/complex_field.gd` to include the translated functions:
     - `dirichlet_eta_with_derivatives(x, y, iters)`
     - `zeta_with_derivatives(x, y, iters)`
     - `lanczos_log_gamma_with_derivatives(z)`
     - `complex_log_gamma_with_derivatives(x, y)`
     - `log_zeta_continuation_with_derivatives(x, y, iters)`
     - `zeta_continuation_with_derivatives(x, y, iters)`
   - Modify the `newton_step` method in `math/complex_field.gd` to detect if we can use the analytic derivatives (for the aforementioned functions when `input_function` is `IDENTITY`) and fall back to the finite differences method if not.
   - I have actually already done these modifications using Python scripts because the translation logic was somewhat repetitive and it was faster to replace inline.

3. **Verify:**
   - I will check the `math/complex_field.gd` code to ensure it's correct.
   - I will ensure there are no syntax errors in the GDScript logic.
   - I will verify that the methods are properly scoped and named.

4. **Pre-commit Steps:**
   - Run the provided `pre_commit_instructions` tool to perform required tests, verifications, reviews, and reflections before submitting the change.

5. **Submit:**
   - Commit and push to a new branch.
