print("Yes, because `log_zeta_continuation_with_derivatives` is still called by other things maybe?")
print("Wait, is it called by anything else? Only by `zeta_continuation_with_derivatives` right now, but it's good to have it algebraic and stable where possible.")
print("The test should now pass because it avoids the exp(log()) round-trip at the zero.")
