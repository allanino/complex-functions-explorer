print("Yes! `val_pure` is evaluated with `Config.iterations`, which is probably >10.")
print("And `res` is evaluated with `iters=10`.")
print("This explains why they are different and why res[0] is not 0 (it's -0.033).")
print("To fix this, we should pass `Config.iterations` instead of 10 to `zeta_continuation_with_derivatives` in the test!")
