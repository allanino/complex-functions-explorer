#include "complex_functions.h"

#include <complex>

namespace godot {

void ComplexFunctions::_bind_methods() {
	ClassDB::bind_static_method("ComplexFunctions", D_METHOD("lanczos_gamma", "z_orig"), &ComplexFunctions::lanczos_gamma);
}

ComplexFunctions::ComplexFunctions() {
}

ComplexFunctions::~ComplexFunctions() {
}

const float LANCZOS_P[9] = {
	0.99999999999980993f,
	676.5203681218851f,
	-1259.1392167224028f,
	771.32342877765313f,
	-176.61502916214059f,
	12.507343278686905f,
	-0.13857109526572012f,
	9.9843695780195716e-6f,
	1.5056327351493116e-7f
};

const float SQRT_2PI = 2.5066282746310005f;

Vector2 ComplexFunctions::lanczos_gamma(const Vector2 &z_orig) {
	std::complex<float> z(z_orig.x - 1.0f, z_orig.y);
	std::complex<float> x(LANCZOS_P[0], 0.0f);

	for (int i = 1; i < 9; i++) {
		std::complex<float> num(LANCZOS_P[i], 0.0f);
		std::complex<float> denom = z + std::complex<float>((float)i, 0.0f);
		x += num / denom;
	}

	std::complex<float> tmp = z + std::complex<float>(7.5f, 0.0f);
	std::complex<float> p = std::pow(tmp, z + std::complex<float>(0.5f, 0.0f));
	std::complex<float> etmp = std::exp(-tmp);

	std::complex<float> result = std::complex<float>(SQRT_2PI, 0.0f) * p * etmp * x;

	return Vector2(result.real(), result.imag());
}

} // namespace godot
