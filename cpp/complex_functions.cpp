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

	ClassDB::bind_method(D_METHOD("complex_mul", "a", "b"), &ComplexFunctions::complex_mul);
	ClassDB::bind_method(D_METHOD("complex_div", "a", "b"), &ComplexFunctions::complex_div);
	ClassDB::bind_method(D_METHOD("complex_exp", "x", "y"), &ComplexFunctions::complex_exp);
	ClassDB::bind_method(D_METHOD("complex_log", "x", "y"), &ComplexFunctions::complex_log);
	ClassDB::bind_method(D_METHOD("complex_sin", "x", "y"), &ComplexFunctions::complex_sin);
	ClassDB::bind_method(D_METHOD("complex_cot", "x", "y"), &ComplexFunctions::complex_cot);
	ClassDB::bind_method(D_METHOD("complex_log_sin", "x", "y"), &ComplexFunctions::complex_log_sin);

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

Vector2 ComplexFunctions::complex_mul(const Vector2 &a, const Vector2 &b) {
	return Vector2(
		a.x * b.x - a.y * b.y,
		a.x * b.y + a.y * b.x
	);
}

Vector2 ComplexFunctions::complex_div(const Vector2 &a, const Vector2 &b) {
	float denom = b.x * b.x + b.y * b.y + 1e-24f;
	return Vector2(
		(a.x * b.x + a.y * b.y) / denom,
		(a.y * b.x - a.x * b.y) / denom
	);
}

Vector2 ComplexFunctions::complex_exp(float x, float y) {
	float amp = std::exp(x);
	return Vector2(amp * std::cos(y), amp * std::sin(y));
}

Vector2 ComplexFunctions::complex_log(float x, float y) {
	float mag_sq = x * x + y * y;
	if (mag_sq < 1e-37f) return Vector2(-60.0f, 0.0f);
	return Vector2(0.5f * std::log(mag_sq), std::atan2(y, x));
}

Vector2 ComplexFunctions::complex_sin(float x, float y) {
	return Vector2(std::sin(x) * std::cosh(y), std::cos(x) * std::sinh(y));
}

Vector2 ComplexFunctions::complex_cot(float x, float y) {
	float abs_2y = 2.0f * std::abs(y);
	float exp_neg = std::exp(-abs_2y);
	float scaled_cosh = 0.5f * (1.0f + exp_neg * exp_neg);
	float scaled_sinh = 0.5f * (1.0f - exp_neg * exp_neg) * (y >= 0.0f ? 1.0f : -1.0f);
	float scaled_sin_2x = std::sin(2.0f * x) * exp_neg;
	float scaled_cos_2x = std::cos(2.0f * x) * exp_neg;
	float denom = scaled_cosh - scaled_cos_2x;
	return Vector2(scaled_sin_2x / denom, -scaled_sinh / denom);
}

Vector2 ComplexFunctions::complex_log_sin(float x, float y) {
	float abs_y = std::abs(y);
	float log_scale = abs_y - LOG_2;
	float e_neg2 = std::exp(-2.0f * abs_y);
	Vector2 internal_z = Vector2(
		std::sin(x) * (1.0f + e_neg2),
		(y >= 0.0f ? 1.0f : -1.0f) * std::cos(x) * (1.0f - e_neg2)
	);
	Vector2 log_internal = complex_log(internal_z.x, internal_z.y);
	return Vector2(log_scale + log_internal.x, log_internal.y);
}


Array ComplexFunctions::dirichlet_eta_with_derivatives(float x, float y, int iters) {
	Array result;
	if (x < -1.0f) {
		result.push_back(Vector2(NAN, NAN));
		result.push_back(Vector2(NAN, NAN));
		result.push_back(Vector2(NAN, NAN));
		return result;
	}

	float eta_x = 0.0f, eta_y = 0.0f;
	float deta_dx_x = 0.0f, deta_dx_y = 0.0f;
	float d2eta_dx2_x = 0.0f, d2eta_dx2_y = 0.0f;
	int actual_iters = 0;

	for (int n = 1; n <= iters; n += 2) {
		float nf = (float)n;
		float amp = std::pow(nf, -x);
		float log_n = std::log(nf);
		float theta = -y * log_n;
		float term_x = amp * std::cos(theta);
		float term_y = amp * std::sin(theta);

		eta_x += term_x; eta_y += term_y;
		deta_dx_x -= log_n * term_x; deta_dx_y -= log_n * term_y;
		d2eta_dx2_x += (log_n * log_n) * term_x; d2eta_dx2_y += (log_n * log_n) * term_y;

		float nf2 = (float)(n + 1);
		float amp2 = std::pow(nf2, -x);
		float log_n2 = std::log(nf2);
		float theta2 = -y * log_n2;
		float term2_x = amp2 * std::cos(theta2);
		float term2_y = amp2 * std::sin(theta2);

		eta_x -= term2_x; eta_y -= term2_y;
		deta_dx_x += log_n2 * term2_x; deta_dx_y += log_n2 * term2_y;
		d2eta_dx2_x -= (log_n2 * log_n2) * term2_x; d2eta_dx2_y -= (log_n2 * log_n2) * term2_y;

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
		float rem_term_x = rem_amp * std::cos(rem_theta);
		float rem_term_y = rem_amp * std::sin(rem_theta);

		eta_x += rem_term_x; eta_y += rem_term_y;
		deta_dx_x -= rem_log_n * rem_term_x; deta_dx_y -= rem_log_n * rem_term_y;
		d2eta_dx2_x += (rem_log_n * rem_log_n) * rem_term_x; d2eta_dx2_y += (rem_log_n * rem_log_n) * rem_term_y;
	}

	result.push_back(Vector2(eta_x, eta_y));
	result.push_back(Vector2(deta_dx_x, deta_dx_y));
	result.push_back(Vector2(d2eta_dx2_x, d2eta_dx2_y));

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
	std::complex<float> two_term(amp2 * std::cos(theta2), amp2 * std::sin(theta2));
	std::complex<float> denom(1.0f - two_term.real(), -two_term.imag());
	std::complex<float> ddenom_dx(LOG_2 * two_term.real(), LOG_2 * two_term.imag());
	std::complex<float> d2denom_dx2(-(LOG_2 * LOG_2) * two_term.real(), -(LOG_2 * LOG_2) * two_term.imag());

	std::complex<float> val = eta / denom;
	std::complex<float> denom_sqr = denom * denom;

	std::complex<float> num_x = deta_dx * denom - eta * ddenom_dx;
	std::complex<float> dx = num_x / denom_sqr;

	std::complex<float> term1 = d2eta_dx2 * denom - eta * d2denom_dx2;
	std::complex<float> term2 = 2.0f * ddenom_dx * num_x;
	std::complex<float> term2_scaled = term2 / denom;

	std::complex<float> d2x = (term1 - term2_scaled) / denom_sqr;

	Array result;
	result.push_back(Vector2(val.real(), val.imag()));
	result.push_back(Vector2(dx.real(), dx.imag()));
	result.push_back(Vector2(d2x.real(), d2x.imag()));
	return result;
}

Array ComplexFunctions::lanczos_log_gamma_with_derivatives(const Vector2 &z_orig) {
	Vector2 z = z_orig;
	Vector2 z_m1 = Vector2(z.x - 1.0f, z.y);
	Vector2 x_val = Vector2(LANCZOS_P[0], 0.0f);
	Vector2 dx_val = Vector2(0.0f, 0.0f);
	Vector2 d2x_val = Vector2(0.0f, 0.0f);

	for (int i = 1; i < 9; i++) {
		Vector2 denom = Vector2(z_m1.x + (float)i, z_m1.y);
		Vector2 denom2 = complex_mul(denom, denom);
		Vector2 denom3 = complex_mul(denom2, denom);
		Vector2 p_i = Vector2(LANCZOS_P[i], 0.0f);

		Vector2 x_add = complex_div(p_i, denom);
		x_val.x += x_add.x; x_val.y += x_add.y;

		Vector2 dx_sub = complex_div(p_i, denom2);
		dx_val.x -= dx_sub.x; dx_val.y -= dx_sub.y;

		Vector2 d2x_add = complex_mul(Vector2(2.0f, 0.0f), complex_div(p_i, denom3));
		d2x_val.x += d2x_add.x; d2x_val.y += d2x_add.y;
	}

	Vector2 tmp = Vector2(z_m1.x + 7.5f, z_m1.y);
	Vector2 log_tmp = complex_log(tmp.x, tmp.y);

	Vector2 z_m_05 = Vector2(z.x - 0.5f, z.y);
	Vector2 p1 = complex_mul(z_m_05, log_tmp);
	Vector2 p2 = complex_log(x_val.x, x_val.y);

	Vector2 val = Vector2(std::log(SQRT_2PI) + p1.x - tmp.x + p2.x, p1.y - tmp.y + p2.y);

	Vector2 psi_p1 = complex_div(z_m_05, tmp);
	Vector2 psi_p2 = complex_div(dx_val, x_val);
	Vector2 psi = Vector2(log_tmp.x + psi_p1.x - 1.0f + psi_p2.x, log_tmp.y + psi_p1.y + psi_p2.y);

	Vector2 term1_d2 = complex_div(Vector2(1.0f, 0.0f), tmp);
	Vector2 term2_d2 = complex_div(z_m_05, complex_mul(tmp, tmp));
	Vector2 term3_num_p1 = complex_mul(d2x_val, x_val);
	Vector2 term3_num_p2 = complex_mul(dx_val, dx_val);
	Vector2 term3_num = Vector2(term3_num_p1.x - term3_num_p2.x, term3_num_p1.y - term3_num_p2.y);
	Vector2 term3_d2 = complex_div(term3_num, complex_mul(x_val, x_val));

	Vector2 dpsi = Vector2(term1_d2.x - term2_d2.x + term3_d2.x, term1_d2.y - term2_d2.y + term3_d2.y);

	Array result;
	result.push_back(val);
	result.push_back(psi);
	result.push_back(dpsi);
	return result;
}

Array ComplexFunctions::complex_log_gamma_with_derivatives(float x, float y) {
	if (x < 0.5f) {
		Vector2 pi_z = Vector2(PI * x, PI * y);
		Array lg1z_data = lanczos_log_gamma_with_derivatives(Vector2(1.0f - x, -y));

		Vector2 lg1z_0 = lg1z_data[0];
		Vector2 lg1z_1 = lg1z_data[1];
		Vector2 lg1z_2 = lg1z_data[2];

		Vector2 log_sin_pi_z = complex_log_sin(pi_z.x, pi_z.y);

		Vector2 val = Vector2(LOG_PI - log_sin_pi_z.x - lg1z_0.x, -log_sin_pi_z.y - lg1z_0.y);
		Vector2 cot_pi_z = complex_cot(pi_z.x, pi_z.y);
		Vector2 dx = Vector2(-PI * cot_pi_z.x + lg1z_1.x, -PI * cot_pi_z.y + lg1z_1.y);

		Vector2 cot2 = complex_mul(cot_pi_z, cot_pi_z);
		Vector2 csc2 = Vector2(1.0f + cot2.x, cot2.y);
		Vector2 d2x_p1 = complex_mul(Vector2(PI * PI, 0.0f), csc2);
		Vector2 d2x = Vector2(d2x_p1.x - lg1z_2.x, d2x_p1.y - lg1z_2.y);

		Array result;
		result.push_back(val);
		result.push_back(dx);
		result.push_back(d2x);
		return result;
	} else {
		return lanczos_log_gamma_with_derivatives(Vector2(x, y));
	}
}

Array ComplexFunctions::log_zeta_continuation_with_derivatives(float x, float y, int iters) {
	if (x >= 0.5f) {
		Array zeta_data = zeta_with_derivatives(x, y, iters);
		Vector2 z_val = zeta_data[0];
		Vector2 z_dx = zeta_data[1];
		Vector2 z_d2x = zeta_data[2];

		Vector2 val = complex_log(z_val.x, z_val.y);
		Vector2 dx = complex_div(z_dx, z_val);

		Vector2 dx2_num_p1 = complex_mul(z_d2x, z_val);
		Vector2 dx2_num_p2 = complex_mul(z_dx, z_dx);
		Vector2 dx2_num = Vector2(dx2_num_p1.x - dx2_num_p2.x, dx2_num_p1.y - dx2_num_p2.y);
		Vector2 dx2_den = complex_mul(z_val, z_val);
		Vector2 dx2 = complex_div(dx2_num, dx2_den);

		Array result;
		result.push_back(val);
		result.push_back(dx);
		result.push_back(dx2);
		return result;
	}

	Vector2 s(x, y);
	Vector2 s1(1.0f - x, -y);

	Vector2 log_sum_p1 = complex_mul(s, Vector2(LOG_2, 0.0f));
	Vector2 log_sum_p2 = complex_mul(Vector2(s.x - 1.0f, s.y), Vector2(LOG_PI, 0.0f));
	Vector2 log_sum = Vector2(log_sum_p1.x + log_sum_p2.x, log_sum_p1.y + log_sum_p2.y);

	Vector2 ratio(LOG_2 + LOG_PI, 0.0f);
	Vector2 d2_ratio(0.0f, 0.0f);

	Vector2 pi_s_2 = Vector2((PI * 0.5f) * s.x, (PI * 0.5f) * s.y);

	Vector2 cls = complex_log_sin(pi_s_2.x, pi_s_2.y);
	log_sum.x += cls.x; log_sum.y += cls.y;

	Vector2 cot_pi_s_2 = complex_cot(pi_s_2.x, pi_s_2.y);
	ratio.x += (PI * 0.5f) * cot_pi_s_2.x; ratio.y += (PI * 0.5f) * cot_pi_s_2.y;

	Vector2 cot_pi_s_2_sq = complex_mul(cot_pi_s_2, cot_pi_s_2);
	Vector2 csc_pi_s_2_sq = Vector2(1.0f + cot_pi_s_2_sq.x, cot_pi_s_2_sq.y);

	d2_ratio.x -= (PI * PI * 0.25f) * csc_pi_s_2_sq.x; d2_ratio.y -= (PI * PI * 0.25f) * csc_pi_s_2_sq.y;

	Array lg_data = complex_log_gamma_with_derivatives(s1.x, s1.y);
	Vector2 lg_data_0 = lg_data[0];
	Vector2 lg_data_1 = lg_data[1];
	Vector2 lg_data_2 = lg_data[2];

	log_sum.x += lg_data_0.x; log_sum.y += lg_data_0.y;
	ratio.x -= lg_data_1.x; ratio.y -= lg_data_1.y;
	d2_ratio.x += lg_data_2.x; d2_ratio.y += lg_data_2.y;

	Array reflected_zeta_data = zeta_with_derivatives(s1.x, s1.y, iters);
	Vector2 reflected_val = reflected_zeta_data[0];
	Vector2 reflected_dx = reflected_zeta_data[1];
	Vector2 reflected_d2x = reflected_zeta_data[2];

	Vector2 clog = complex_log(reflected_val.x, reflected_val.y);
	log_sum.x += clog.x; log_sum.y += clog.y;

	Vector2 z_ratio = complex_div(reflected_dx, reflected_val);
	ratio.x -= z_ratio.x; ratio.y -= z_ratio.y;

	Vector2 d2_num_p1 = complex_mul(reflected_d2x, reflected_val);
	Vector2 d2_num_p2 = complex_mul(reflected_dx, reflected_dx);
	Vector2 d2_num = Vector2(d2_num_p1.x - d2_num_p2.x, d2_num_p1.y - d2_num_p2.y);
	Vector2 d2_den = complex_mul(reflected_val, reflected_val);
	Vector2 d2_add = complex_div(d2_num, d2_den);

	d2_ratio.x += d2_add.x; d2_ratio.y += d2_add.y;

	Array result;
	result.push_back(log_sum);
	result.push_back(ratio);
	result.push_back(d2_ratio);
	return result;
}

Array ComplexFunctions::zeta_continuation_with_derivatives(float x, float y, int iters) {
	if (x >= 0.5f) {
		return zeta_with_derivatives(x, y, iters);
	}

	Array log_z_data = log_zeta_continuation_with_derivatives(x, y, iters);
	Vector2 log_z_0 = log_z_data[0];
	Vector2 log_z_1 = log_z_data[1];
	Vector2 log_z_2 = log_z_data[2];

	Vector2 val = complex_exp(log_z_0.x, log_z_0.y);
	Vector2 dx = complex_mul(val, log_z_1);
	Vector2 d2_inner_p1 = complex_mul(log_z_1, log_z_1);
	Vector2 d2_inner = Vector2(log_z_2.x + d2_inner_p1.x, log_z_2.y + d2_inner_p1.y);
	Vector2 d2x = complex_mul(val, d2_inner);

	Array result;
	result.push_back(val);
	result.push_back(dx);
	result.push_back(d2x);
	return result;
}

} // namespace godot
