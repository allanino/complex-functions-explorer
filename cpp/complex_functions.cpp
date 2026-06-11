#include "complex_functions.h"

#include <complex>

namespace godot {

void ComplexFunctions::_bind_methods() {
	ClassDB::bind_method(D_METHOD("lanczos_gamma", "z_orig"), &ComplexFunctions::lanczos_gamma);

	ClassDB::bind_method(D_METHOD("dirichlet_eta_with_derivatives", "x", "y", "iters"), &ComplexFunctions::dirichlet_eta_with_derivatives);
	ClassDB::bind_method(D_METHOD("zeta_with_derivatives", "x", "y", "iters"), &ComplexFunctions::zeta_with_derivatives);
	ClassDB::bind_method(D_METHOD("lanczos_log_gamma_with_derivatives", "z_orig"), &ComplexFunctions::lanczos_log_gamma_with_derivatives);
	ClassDB::bind_method(D_METHOD("complex_log_gamma_with_derivatives", "x", "y"), &ComplexFunctions::complex_log_gamma_with_derivatives);
	ClassDB::bind_method(D_METHOD("log_zeta_continuation_with_derivatives", "x", "y", "iters"), &ComplexFunctions::log_zeta_continuation_with_derivatives);
	ClassDB::bind_method(D_METHOD("zeta_continuation_with_derivatives", "x", "y", "iters"), &ComplexFunctions::zeta_continuation_with_derivatives);

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



const float LOG_2 = 0.6931471805599453f;
const float PI = 3.141592653589793f;
const float LOG_PI = 1.1447298858494002f;

Array ComplexFunctions::dirichlet_eta_with_derivatives(float x, float y, int iters) {
	Array result;
	if (x < -1.0f) {
		result.push_back(Vector2(NAN, NAN));
		result.push_back(Vector2(NAN, NAN));
		result.push_back(Vector2(NAN, NAN));
		return result;
	}

	std::complex<float> eta(0.0f, 0.0f);
	std::complex<float> deta_dx(0.0f, 0.0f);
	std::complex<float> d2eta_dx2(0.0f, 0.0f);
	int actual_iters = 0;

	for (int n = 1; n <= iters; n += 2) {
		float nf = (float)n;
		float amp = std::pow(nf, -x);
		float log_n = std::log(nf);
		float theta = -y * log_n;
		std::complex<float> term = std::complex<float>(amp * std::cos(theta), amp * std::sin(theta));
		eta += term;
		deta_dx -= log_n * term;
		d2eta_dx2 += (log_n * log_n) * term;

		float nf2 = (float)(n + 1);
		float amp2 = std::pow(nf2, -x);
		float log_n2 = std::log(nf2);
		float theta2 = -y * log_n2;
		std::complex<float> term2 = std::complex<float>(amp2 * std::cos(theta2), amp2 * std::sin(theta2));
		eta -= term2;
		deta_dx += log_n2 * term2;
		d2eta_dx2 -= (log_n2 * log_n2) * term2;

		actual_iters = n + 1;

		if (amp < 1e-4f || amp2 < 1e-4f || amp > 1e4f || amp2 > 1e4f) {
			break;
		}
	}

	if (actual_iters > 0 && x >= 0.5f) {
		float next_n = (float)(actual_iters + 1);
		float rem_amp = 0.5f * std::pow(next_n, -x);
		float rem_log_n = std::log(next_n);
		float rem_theta = -y * rem_log_n;
		float rem_sign = 1.0f;
		std::complex<float> rem_term = rem_sign * rem_amp * std::complex<float>(std::cos(rem_theta), std::sin(rem_theta));

		eta += rem_term;
		deta_dx -= rem_log_n * rem_term;
		d2eta_dx2 += (rem_log_n * rem_log_n) * rem_term;
	}

	result.push_back(Vector2(eta.real(), eta.imag()));
	result.push_back(Vector2(deta_dx.real(), deta_dx.imag()));
	result.push_back(Vector2(d2eta_dx2.real(), d2eta_dx2.imag()));

	return result;
}

Array ComplexFunctions::zeta_with_derivatives(float x, float y, int iters) {
	Array eta_data = dirichlet_eta_with_derivatives(x, y, iters);

	Vector2 eta_v = eta_data[0];
	Vector2 deta_dx_v = eta_data[1];
	Vector2 d2eta_dx2_v = eta_data[2];

	std::complex<float> eta(eta_v.x, eta_v.y);
	std::complex<float> deta_dx(deta_dx_v.x, deta_dx_v.y);
	std::complex<float> d2eta_dx2(d2eta_dx2_v.x, d2eta_dx2_v.y);

	float amp2 = std::pow(2.0f, 1.0f - x);
	float theta2 = -y * LOG_2;
	std::complex<float> two_term = amp2 * std::complex<float>(std::cos(theta2), std::sin(theta2));
	std::complex<float> denom = std::complex<float>(1.0f, 0.0f) - two_term;
	std::complex<float> ddenom_dx = LOG_2 * two_term;
	std::complex<float> d2denom_dx2 = -(LOG_2 * LOG_2) * two_term;

	std::complex<float> val = eta / denom;
	std::complex<float> denom_sqr = denom * denom;
	std::complex<float> num_x = deta_dx * denom - eta * ddenom_dx;
	std::complex<float> dx = num_x / denom_sqr;

	std::complex<float> term1 = d2eta_dx2 * denom - eta * d2denom_dx2;
	std::complex<float> term2 = std::complex<float>(2.0f, 0.0f) * ddenom_dx * num_x;
	std::complex<float> term2_scaled = term2 / denom;
	std::complex<float> d2x = (term1 - term2_scaled) / denom_sqr;

	Array result;
	result.push_back(Vector2(val.real(), val.imag()));
	result.push_back(Vector2(dx.real(), dx.imag()));
	result.push_back(Vector2(d2x.real(), d2x.imag()));
	return result;
}

Array ComplexFunctions::lanczos_log_gamma_with_derivatives(const Vector2 &z_orig) {
	std::complex<float> z(z_orig.x, z_orig.y);
	std::complex<float> z_m1 = z - std::complex<float>(1.0f, 0.0f);
	std::complex<float> x(LANCZOS_P[0], 0.0f);
	std::complex<float> dx_val(0.0f, 0.0f);
	std::complex<float> d2x_val(0.0f, 0.0f);

	for (int i = 1; i < 9; i++) {
		std::complex<float> denom = z_m1 + std::complex<float>((float)i, 0.0f);
		std::complex<float> denom2 = denom * denom;
		std::complex<float> denom3 = denom2 * denom;
		std::complex<float> p_i(LANCZOS_P[i], 0.0f);

		x += p_i / denom;
		dx_val -= p_i / denom2;
		d2x_val += std::complex<float>(2.0f, 0.0f) * (p_i / denom3);
	}

	std::complex<float> tmp = z_m1 + std::complex<float>(7.5f, 0.0f);
	std::complex<float> log_tmp = std::log(tmp);

	std::complex<float> val = std::complex<float>(std::log(SQRT_2PI), 0.0f) +
		(z - std::complex<float>(0.5f, 0.0f)) * log_tmp - tmp + std::log(x);

	std::complex<float> psi = log_tmp + (z - std::complex<float>(0.5f, 0.0f)) / tmp -
		std::complex<float>(1.0f, 0.0f) + dx_val / x;

	std::complex<float> term1_d2 = std::complex<float>(1.0f, 0.0f) / tmp;
	std::complex<float> term2_d2 = (z - std::complex<float>(0.5f, 0.0f)) / (tmp * tmp);
	std::complex<float> term3_num = d2x_val * x - dx_val * dx_val;
	std::complex<float> term3_d2 = term3_num / (x * x);
	std::complex<float> dpsi = term1_d2 - term2_d2 + term3_d2;

	Array result;
	result.push_back(Vector2(val.real(), val.imag()));
	result.push_back(Vector2(psi.real(), psi.imag()));
	result.push_back(Vector2(dpsi.real(), dpsi.imag()));
	return result;
}

Array ComplexFunctions::complex_log_gamma_with_derivatives(float x, float y) {
	if (x < 0.5f) {
		std::complex<float> pi_z(PI * x, PI * y);
		Array lg1z_data = lanczos_log_gamma_with_derivatives(Vector2(1.0f - x, -y));

		Vector2 lg1z_v0 = lg1z_data[0];
		Vector2 lg1z_v1 = lg1z_data[1];
		Vector2 lg1z_v2 = lg1z_data[2];

		std::complex<float> lg1z_0(lg1z_v0.x, lg1z_v0.y);
		std::complex<float> lg1z_1(lg1z_v1.x, lg1z_v1.y);
		std::complex<float> lg1z_2(lg1z_v2.x, lg1z_v2.y);

		std::complex<float> log_sin_pi_z = std::log(std::sin(pi_z));

		std::complex<float> val = std::complex<float>(LOG_PI, 0.0f) - log_sin_pi_z - lg1z_0;
		std::complex<float> cot_pi_z = std::cos(pi_z) / std::sin(pi_z);
		std::complex<float> dx = -PI * cot_pi_z + lg1z_1;

		std::complex<float> cot2 = cot_pi_z * cot_pi_z;
		std::complex<float> csc2 = std::complex<float>(1.0f, 0.0f) + cot2;
		std::complex<float> d2x = std::complex<float>(PI * PI, 0.0f) * csc2 - lg1z_2;

		Array result;
		result.push_back(Vector2(val.real(), val.imag()));
		result.push_back(Vector2(dx.real(), dx.imag()));
		result.push_back(Vector2(d2x.real(), d2x.imag()));
		return result;
	} else {
		return lanczos_log_gamma_with_derivatives(Vector2(x, y));
	}
}

Array ComplexFunctions::log_zeta_continuation_with_derivatives(float x, float y, int iters) {
	if (x >= 0.5f) {
		Array zeta_data = zeta_with_derivatives(x, y, iters);
		Vector2 z_val_v = zeta_data[0];
		Vector2 z_dx_v = zeta_data[1];
		Vector2 z_d2x_v = zeta_data[2];

		std::complex<float> z_val(z_val_v.x, z_val_v.y);
		std::complex<float> z_dx(z_dx_v.x, z_dx_v.y);
		std::complex<float> z_d2x(z_d2x_v.x, z_d2x_v.y);

		std::complex<float> val = std::log(z_val);
		std::complex<float> dx = z_dx / z_val;
		std::complex<float> dx2 = (z_d2x * z_val - z_dx * z_dx) / (z_val * z_val);

		Array result;
		result.push_back(Vector2(val.real(), val.imag()));
		result.push_back(Vector2(dx.real(), dx.imag()));
		result.push_back(Vector2(dx2.real(), dx2.imag()));
		return result;
	}

	std::complex<float> s(x, y);
	std::complex<float> s1(1.0f - x, -y);

	std::complex<float> log_sum = s * std::complex<float>(LOG_2, 0.0f) + (s - std::complex<float>(1.0f, 0.0f)) * std::complex<float>(LOG_PI, 0.0f);
	std::complex<float> ratio(LOG_2 + LOG_PI, 0.0f);
	std::complex<float> d2_ratio(0.0f, 0.0f);

	std::complex<float> pi_s_2 = (float)(PI * 0.5f) * s;

	log_sum += std::log(std::sin(pi_s_2));
	std::complex<float> cot_pi_s_2 = std::cos(pi_s_2) / std::sin(pi_s_2);
	ratio += (float)(PI * 0.5f) * cot_pi_s_2;

	std::complex<float> cot_pi_s_2_sq = cot_pi_s_2 * cot_pi_s_2;
	std::complex<float> csc_pi_s_2_sq = std::complex<float>(1.0f, 0.0f) + cot_pi_s_2_sq;
	d2_ratio -= (float)(PI * PI * 0.25f) * csc_pi_s_2_sq;

	Array lg_data = complex_log_gamma_with_derivatives(s1.real(), s1.imag());
	Vector2 lg_data_0 = lg_data[0];
	Vector2 lg_data_1 = lg_data[1];
	Vector2 lg_data_2 = lg_data[2];

	log_sum += std::complex<float>(lg_data_0.x, lg_data_0.y);
	ratio -= std::complex<float>(lg_data_1.x, lg_data_1.y);
	d2_ratio += std::complex<float>(lg_data_2.x, lg_data_2.y);

	Array reflected_zeta_data = zeta_with_derivatives(s1.real(), s1.imag(), iters);
	Vector2 r_val_v = reflected_zeta_data[0];
	Vector2 r_dx_v = reflected_zeta_data[1];
	Vector2 r_d2x_v = reflected_zeta_data[2];

	std::complex<float> reflected_val(r_val_v.x, r_val_v.y);
	std::complex<float> reflected_dx(r_dx_v.x, r_dx_v.y);
	std::complex<float> reflected_d2x(r_d2x_v.x, r_d2x_v.y);

	log_sum += std::log(reflected_val);
	std::complex<float> z_ratio = reflected_dx / reflected_val;
	ratio -= z_ratio;
	d2_ratio += (reflected_d2x * reflected_val - reflected_dx * reflected_dx) / (reflected_val * reflected_val);

	Array result;
	result.push_back(Vector2(log_sum.real(), log_sum.imag()));
	result.push_back(Vector2(ratio.real(), ratio.imag()));
	result.push_back(Vector2(d2_ratio.real(), d2_ratio.imag()));
	return result;
}

Array ComplexFunctions::zeta_continuation_with_derivatives(float x, float y, int iters) {
	if (x >= 0.5f) {
		return zeta_with_derivatives(x, y, iters);
	}

	Array log_z_data = log_zeta_continuation_with_derivatives(x, y, iters);
	Vector2 l_0 = log_z_data[0];
	Vector2 l_1 = log_z_data[1];
	Vector2 l_2 = log_z_data[2];

	std::complex<float> log_z_0(l_0.x, l_0.y);
	std::complex<float> log_z_1(l_1.x, l_1.y);
	std::complex<float> log_z_2(l_2.x, l_2.y);

	std::complex<float> val = std::exp(log_z_0);
	std::complex<float> dx = val * log_z_1;
	std::complex<float> d2x = val * (log_z_2 + log_z_1 * log_z_1);

	Array result;
	result.push_back(Vector2(val.real(), val.imag()));
	result.push_back(Vector2(dx.real(), dx.imag()));
	result.push_back(Vector2(d2x.real(), d2x.imag()));
	return result;
}

} // namespace godot
