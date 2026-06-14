#include "complex_functions.h"

#include <complex>
#include <godot_cpp/variant/utility_functions.hpp>

namespace godot {

void ComplexFunctions::_bind_methods() {
	ClassDB::bind_method(D_METHOD("lanczos_gamma", "x", "y"), &ComplexFunctions::lanczos_gamma);

	ClassDB::bind_method(D_METHOD("dirichlet_eta_with_derivatives", "x", "y", "iters"), &ComplexFunctions::dirichlet_eta_with_derivatives);
	ClassDB::bind_method(D_METHOD("eta_find_zero", "x", "y", "iters", "step_mult", "step_max", "debug"), &ComplexFunctions::eta_find_zero);
	ClassDB::bind_method(D_METHOD("zeta_find_zero", "x", "y", "iters", "step_mult", "step_max", "debug"), &ComplexFunctions::zeta_find_zero);
	ClassDB::bind_method(D_METHOD("zeta_with_derivatives", "x", "y", "iters"), &ComplexFunctions::zeta_with_derivatives);
	ClassDB::bind_method(D_METHOD("eta_borwein_with_derivatives", "x", "y", "order"), &ComplexFunctions::eta_borwein_with_derivatives);
	ClassDB::bind_method(D_METHOD("zeta_borwein_with_derivatives", "x", "y", "order"), &ComplexFunctions::zeta_borwein_with_derivatives);
	ClassDB::bind_method(D_METHOD("lanczos_log_gamma_with_derivatives", "z_orig"), &ComplexFunctions::lanczos_log_gamma_with_derivatives);
	ClassDB::bind_method(D_METHOD("complex_log_gamma_with_derivatives", "x", "y"), &ComplexFunctions::complex_log_gamma_with_derivatives);
	ClassDB::bind_method(D_METHOD("log_zeta_continuation_with_derivatives", "x", "y", "iters"), &ComplexFunctions::log_zeta_continuation_with_derivatives);
	ClassDB::bind_method(D_METHOD("zeta_continuation_with_derivatives", "x", "y", "iters"), &ComplexFunctions::zeta_continuation_with_derivatives);
	ClassDB::bind_method(D_METHOD("log_eta_continuation_with_derivatives", "x", "y", "iters"), &ComplexFunctions::log_eta_continuation_with_derivatives);
	ClassDB::bind_method(D_METHOD("eta_continuation_with_derivatives", "x", "y", "iters"), &ComplexFunctions::eta_continuation_with_derivatives);
	ClassDB::bind_method(D_METHOD("log_beta_continuation_with_derivatives", "x", "y", "iters"), &ComplexFunctions::log_beta_continuation_with_derivatives);
	ClassDB::bind_method(D_METHOD("beta_continuation_with_derivatives", "x", "y", "iters"), &ComplexFunctions::beta_continuation_with_derivatives);
	ClassDB::bind_method(D_METHOD("beta_find_zero", "x", "y", "iters", "step_mult", "step_max", "debug"), &ComplexFunctions::beta_find_zero);

	ClassDB::bind_method(D_METHOD("complex_mul", "ax", "ay", "bx", "by"), &ComplexFunctions::complex_mul);
	ClassDB::bind_method(D_METHOD("complex_div", "ax", "ay", "bx", "by"), &ComplexFunctions::complex_div);
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

std::vector<double> ComplexFunctions::_get_borwein_weights(int order) {
	if (order <= 0) return {};

	{
		std::lock_guard<std::mutex> lock(_borwein_mutex);
		if (_borwein_cache.find(order) != _borwein_cache.end()) {
			return _borwein_cache[order];
		}
	}

	double n = (double)order;
	std::vector<double> T(order + 1, 0.0);

	for (int l = 1; l <= order; l++) {
		double fl = (double)l;
		T[l] = T[l - 1] + std::log(n - fl + 1.0) + std::log(n + fl - 1.0) - std::log(2.0 * fl - 1.0) - std::log(2.0 * fl) + std::log(4.0);
	}

	std::vector<double> log_d(order + 1, 0.0);
	double current_max = T[0];
	double current_sum_exp = 0.0;

	for (int k = 0; k <= order; k++) {
		if (T[k] > current_max) {
			double diff = current_max - T[k];
			current_sum_exp = current_sum_exp * std::exp(diff) + 1.0;
			current_max = T[k];
		} else {
			current_sum_exp += std::exp(T[k] - current_max);
		}
		log_d[k] = current_max + std::log(current_sum_exp);
	}

	double log_d_n = log_d[order];
	std::vector<double> w(order, 0.0);
	for (int k = 0; k < order; k++) {
		w[k] = - std::expm1(log_d[k] - log_d_n);
	}

	{
		std::lock_guard<std::mutex> lock(_borwein_mutex);
		_borwein_cache[order] = w;
	}

	return w;
}

const double LANCZOS_P[9] = {
	0.99999999999980993,
	676.5203681218851,
	-1259.1392167224028,
	771.32342877765313,
	-176.61502916214059,
	12.507343278686905,
	-0.13857109526572012,
	9.9843695780195716e-6,
	1.5056327351493116e-7
};

const double SQRT_2PI = 2.5066282746310005;
const double PI = 3.141592653589793;
const double LOG_2 = 0.6931471805599453;
const double LOG_PI = 1.1447298858494002;

PackedFloat64Array ComplexFunctions::lanczos_gamma(double x, double y) {
	std::complex<double> z(x, y);
	PackedFloat64Array result; result.resize(2);
	if (z.real() < 0.5) {
		std::complex<double> pi_z = PI * z;
		std::complex<double> sin_pi_z = std::sin(pi_z);
		std::complex<double> denom = sin_pi_z;

		std::complex<double> z_ref(1.0 - z.real(), -z.imag());
		std::complex<double> x_val(LANCZOS_P[0], 0.0);
		for (int i = 1; i < 9; i++) {
			x_val += (LANCZOS_P[i] / (z_ref + (double)i));
		}
		std::complex<double> t = z_ref + 7.5;
		std::complex<double> res_gamma = SQRT_2PI * std::pow(t, z_ref - 0.5) * std::exp(-t) * x_val;
		std::complex<double> res = PI / (denom * res_gamma);
		result[0] = res.real(); result[1] = res.imag();
		return result;
	} else {
		std::complex<double> z_m1 = z - 1.0;
		std::complex<double> x_val(LANCZOS_P[0], 0.0);
		for (int i = 1; i < 9; i++) {
			x_val += (LANCZOS_P[i] / (z_m1 + (double)i));
		}
		std::complex<double> t = z_m1 + 7.5;
		std::complex<double> res = SQRT_2PI * std::pow(t, z_m1 + 0.5) * std::exp(-t) * x_val;
		result[0] = res.real(); result[1] = res.imag();
		return result;
	}
}




PackedFloat64Array ComplexFunctions::complex_mul(double ax, double ay, double bx, double by) {
	std::complex<double> a(ax, ay);
	std::complex<double> b(bx, by);
	std::complex<double> res = a * b;
	PackedFloat64Array arr; arr.resize(2); arr[0] = res.real(); arr[1] = res.imag(); return arr;
}

PackedFloat64Array ComplexFunctions::complex_div(double ax, double ay, double bx, double by) {
	std::complex<double> a(ax, ay);
	std::complex<double> b(bx, by);
	std::complex<double> res = a / b;
	PackedFloat64Array arr; arr.resize(2); arr[0] = res.real(); arr[1] = res.imag(); return arr;
}

PackedFloat64Array ComplexFunctions::complex_exp(double x, double y) {
	std::complex<double> z(x, y);
	std::complex<double> res = std::exp(z);
	PackedFloat64Array arr; arr.resize(2); arr[0] = res.real(); arr[1] = res.imag(); return arr;
}

PackedFloat64Array ComplexFunctions::complex_log(double x, double y) {
	double mag_sq = x * x + y * y;
	PackedFloat64Array arr; arr.resize(2);
	if (mag_sq < 1e-48) { arr[0] = -60.0; arr[1] = 0.0; return arr; }
	arr[0] = 0.5 * std::log(mag_sq); arr[1] = std::atan2(y, x); return arr;
}

PackedFloat64Array ComplexFunctions::complex_sin(double x, double y) {
	PackedFloat64Array arr; arr.resize(2);
	arr[0] = std::sin(x) * std::cosh(y);
	arr[1] = std::cos(x) * std::sinh(y);
	return arr;
}

PackedFloat64Array ComplexFunctions::complex_cot(double x, double y) {
	double abs_2y = 2.0 * std::abs(y);
	double exp_neg = std::exp(-abs_2y);
	double scaled_cosh = 0.5 * (1.0 + exp_neg * exp_neg);
	double scaled_sinh = 0.5 * (1.0 - exp_neg * exp_neg) * (y >= 0.0 ? 1.0 : -1.0);
	double scaled_sin_2x = std::sin(2.0 * x) * exp_neg;
	double scaled_cos_2x = std::cos(2.0 * x) * exp_neg;
	double denom = scaled_cosh - scaled_cos_2x;
	PackedFloat64Array arr; arr.resize(2);
	if (denom < 1e-14) { arr[0] = 1e14; arr[1] = 0.0; return arr; }
	arr[0] = scaled_sin_2x / denom;
	arr[1] = -scaled_sinh / denom;
	return arr;
}

PackedFloat64Array ComplexFunctions::complex_log_sin(double x, double y) {
	double abs_y = std::abs(y);
	double log_scale = abs_y - LOG_2;
	double e_neg2 = std::exp(-2.0 * abs_y);

	double ix = std::sin(x) * (1.0 + e_neg2);
	double iy = (y >= 0.0 ? 1.0 : -1.0) * std::cos(x) * (1.0 - e_neg2);

	PackedFloat64Array log_internal = complex_log(ix, iy);
	PackedFloat64Array arr; arr.resize(2);
	arr[0] = log_scale + log_internal[0];
	arr[1] = log_internal[1];
	return arr;
}


PackedFloat64Array ComplexFunctions::dirichlet_eta_with_derivatives(double x, double y, int iters) {
	PackedFloat64Array result;

	// Safety allocation size: 3 complex numbers * 2 components (Real, Imag) = 6 slots
	result.resize(6);

	if (x <= 1e-3) {
		result[0] = NAN; result[1] = NAN; // eta
		result[2] = NAN; result[3] = NAN; // deta_dx
		result[4] = NAN; result[5] = NAN; // d2eta_dx2
		return result;
	}

	// Accumulators explicitly typed as 64-bit IEEE 754 doubles
	double eta_x = 0.0, eta_y = 0.0;
	double deta_dx_x = 0.0, deta_dx_y = 0.0;
	double d2eta_dx2_x = 0.0, d2eta_dx2_y = 0.0;
	int actual_iters = 0;

	for (int n = 1; n <= iters; n += 2) {
		// --- Odd Term Accumulation ---
		double nf = (double)n;
		double amp = std::pow(nf, -x);
		double log_n = std::log(nf);
		double theta = -y * log_n;
		double term_x = amp * std::cos(theta);
		double term_y = amp * std::sin(theta);

		eta_x += term_x;
		eta_y += term_y;

		deta_dx_x -= log_n * term_x;
		deta_dx_y -= log_n * term_y;

		d2eta_dx2_x += (log_n * log_n) * term_x;
		d2eta_dx2_y += (log_n * log_n) * term_y;

		// --- Even Term Accumulation ---
		double nf2 = (double)(n + 1);
		double amp2 = std::pow(nf2, -x);
		double log_n2 = std::log(nf2);
		double theta2 = -y * log_n2;
		double term2_x = amp2 * std::cos(theta2);
		double term2_y = amp2 * std::sin(theta2);

		eta_x -= term2_x;
		eta_y -= term2_y;

		deta_dx_x += log_n2 * term2_x;
		deta_dx_y += log_n2 * term2_y;

		d2eta_dx2_x -= (log_n2 * log_n2) * term2_x;
		d2eta_dx2_y -= (log_n2 * log_n2) * term2_y;

		actual_iters = n + 1;

	   if (amp < 1e-4 || amp2 < 1e-4) {
			break;
		}
	}

	if (actual_iters > 0 && x >= 0.5) {
		double next_n = (double)(actual_iters + 1);
		double rem_amp = 0.5 * std::pow(next_n, -x);
		double rem_log_n = std::log(next_n);
		double rem_theta = -y * rem_log_n;
		double rem_term_x = rem_amp * std::cos(rem_theta);
		double rem_term_y = rem_amp * std::sin(rem_theta);

		eta_x += rem_term_x;
		eta_y += rem_term_y;

		deta_dx_x -= rem_log_n * rem_term_x;
		deta_dx_y -= rem_log_n * rem_term_y;

		d2eta_dx2_x += (rem_log_n * rem_log_n) * rem_term_x;
		d2eta_dx2_y += (rem_log_n * rem_log_n) * rem_term_y;
	}

	// Pack double data sequentially without casting or downscaling to float
	result[0] = eta_x;       result[1] = eta_y;       // [0, 1] -> Complex Value
	result[2] = deta_dx_x;   result[3] = deta_dx_y;   // [2, 3] -> First Derivative
	result[4] = d2eta_dx2_x; result[5] = d2eta_dx2_y; // [4, 5] -> Second Derivative

	return result;
}

PackedFloat64Array ComplexFunctions::eta_borwein_with_derivatives(double x, double y, int order) {
	PackedFloat64Array result;
	result.resize(6);

	if (order <= 0) {
		for (int i = 0; i < 6; i++) result[i] = 0.0;
		return result;
	}

	std::vector<double> w = _get_borwein_weights(order);

	double sum_val_x = 0.0, sum_val_y = 0.0;
	double sum_dx_x = 0.0, sum_dx_y = 0.0;
	double sum_d2x_x = 0.0, sum_d2x_y = 0.0;

	const double TWO_PI = 2.0 * PI;

	for (int k = 0; k < order; k++) {
		double w_k = w[k];
		double k_plus_1 = (double)(k + 1);
		double logk = std::log(k_plus_1);
		double amp = std::exp(-x * logk);

		double raw_theta = -y * logk;
		double safe_theta = std::fmod(raw_theta, TWO_PI);
		if (safe_theta < 0) {
			safe_theta += TWO_PI;
		}

		double pow_term_x = amp * std::cos(safe_theta);
		double pow_term_y = amp * std::sin(safe_theta);

		if (k & 1) { // if k is odd
			pow_term_x = -pow_term_x;
			pow_term_y = -pow_term_y;
		}

		double term_x = w_k * pow_term_x;
		double term_y = w_k * pow_term_y;

		double term_dx_x = -logk * term_x;
		double term_dx_y = -logk * term_y;

		double term_d2x_x = logk * logk * term_x;
		double term_d2x_y = logk * logk * term_y;

		sum_val_x += term_x;
		sum_val_y += term_y;

		sum_dx_x += term_dx_x;
		sum_dx_y += term_dx_y;

		sum_d2x_x += term_d2x_x;
		sum_d2x_y += term_d2x_y;
	}

	result[0] = sum_val_x; result[1] = sum_val_y;
	result[2] = sum_dx_x; result[3] = sum_dx_y;
	result[4] = sum_d2x_x; result[5] = sum_d2x_y;

	return result;
}

PackedFloat64Array ComplexFunctions::zeta_borwein_with_derivatives(double x, double y, int order) {
	PackedFloat64Array eta_data = eta_borwein_with_derivatives(x, y, order);

	std::complex<double> eta(eta_data[0], eta_data[1]);
	std::complex<double> deta_dx(eta_data[2], eta_data[3]);
	std::complex<double> d2eta_dx2(eta_data[4], eta_data[5]);

	double amp2 = std::pow(2.0, 1.0 - x);
	double theta2 = -y * LOG_2;
	std::complex<double> two_term(amp2 * std::cos(theta2), amp2 * std::sin(theta2));
	std::complex<double> denom(1.0 - two_term.real(), -two_term.imag());
	std::complex<double> ddenom_dx(LOG_2 * two_term.real(), LOG_2 * two_term.imag());
	std::complex<double> d2denom_dx2(-(LOG_2 * LOG_2) * two_term.real(), -(LOG_2 * LOG_2) * two_term.imag());

	std::complex<double> val = eta / denom;
	std::complex<double> denom_sqr = denom * denom;

	std::complex<double> num_x = deta_dx * denom - eta * ddenom_dx;
	std::complex<double> dx = num_x / denom_sqr;

	std::complex<double> term1 = d2eta_dx2 * denom - eta * d2denom_dx2;
	std::complex<double> term2 = 2.0 * ddenom_dx * num_x;
	std::complex<double> term2_scaled = term2 / denom;

	std::complex<double> d2x = (term1 - term2_scaled) / denom_sqr;

	PackedFloat64Array result; result.resize(6);
	result[0] = val.real(); result[1] = val.imag();
	result[2] = dx.real(); result[3] = dx.imag();
	result[4] = d2x.real(); result[5] = d2x.imag();
	return result;
}

PackedFloat64Array ComplexFunctions::zeta_with_derivatives(double x, double y, int iters) {
	PackedFloat64Array eta_data = dirichlet_eta_with_derivatives(x, y, iters);

	std::complex<double> eta(eta_data[0], eta_data[1]);
	std::complex<double> deta_dx(eta_data[2], eta_data[3]);
	std::complex<double> d2eta_dx2(eta_data[4], eta_data[5]);

	double amp2 = std::pow(2.0, 1.0 - x);
	double theta2 = -y * LOG_2;
	std::complex<double> two_term(amp2 * std::cos(theta2), amp2 * std::sin(theta2));
	std::complex<double> denom(1.0 - two_term.real(), -two_term.imag());
	std::complex<double> ddenom_dx(LOG_2 * two_term.real(), LOG_2 * two_term.imag());
	std::complex<double> d2denom_dx2(-(LOG_2 * LOG_2) * two_term.real(), -(LOG_2 * LOG_2) * two_term.imag());

	std::complex<double> val = eta / denom;
	std::complex<double> denom_sqr = denom * denom;

	std::complex<double> num_x = deta_dx * denom - eta * ddenom_dx;
	std::complex<double> dx = num_x / denom_sqr;

	std::complex<double> term1 = d2eta_dx2 * denom - eta * d2denom_dx2;
	std::complex<double> term2 = 2.0 * ddenom_dx * num_x;
	std::complex<double> term2_scaled = term2 / denom;

	std::complex<double> d2x = (term1 - term2_scaled) / denom_sqr;

	PackedFloat64Array result; result.resize(6);
	result[0] = val.real(); result[1] = val.imag();
	result[2] = dx.real(); result[3] = dx.imag();
	result[4] = d2x.real(); result[5] = d2x.imag();
	return result;
}

PackedFloat64Array ComplexFunctions::lanczos_log_gamma_with_derivatives(double x, double y) {
	std::complex<double> z(x, y);
	std::complex<double> z_m1 = z - 1.0;
	std::complex<double> x_val(LANCZOS_P[0], 0.0);
	std::complex<double> dx_val(0.0, 0.0);
	std::complex<double> d2x_val(0.0, 0.0);

	for (int i = 1; i < 9; i++) {
		std::complex<double> denom = z_m1 + (double)i;
		std::complex<double> denom2 = denom * denom;
		std::complex<double> denom3 = denom2 * denom;
		std::complex<double> p_i(LANCZOS_P[i], 0.0);

		x_val += p_i / denom;
		dx_val -= p_i / denom2;
		d2x_val += 2.0 * (p_i / denom3);
	}

	std::complex<double> tmp = z_m1 + 7.5;
	std::complex<double> log_tmp = std::log(tmp);
	std::complex<double> z_m_05 = z - 0.5;

	std::complex<double> val = std::log(SQRT_2PI) + z_m_05 * log_tmp - tmp + std::log(x_val);
	std::complex<double> psi = log_tmp + (z_m_05 / tmp) - 1.0 + (dx_val / x_val);
	std::complex<double> dpsi = (1.0 / tmp) - (z_m_05 / (tmp * tmp)) + ((d2x_val * x_val - dx_val * dx_val) / (x_val * x_val));

	PackedFloat64Array result; result.resize(6);
	result[0] = val.real(); result[1] = val.imag();
	result[2] = psi.real(); result[3] = psi.imag();
	result[4] = dpsi.real(); result[5] = dpsi.imag();
	return result;
}

PackedFloat64Array ComplexFunctions::complex_log_gamma_with_derivatives(double x, double y) {
	if (x < 0.5) {
		PackedFloat64Array lg1z_data = lanczos_log_gamma_with_derivatives(1.0 - x, -y);

		std::complex<double> lg1z_0(lg1z_data[0], lg1z_data[1]);
		std::complex<double> lg1z_1(lg1z_data[2], lg1z_data[3]);
		std::complex<double> lg1z_2(lg1z_data[4], lg1z_data[5]);

		PackedFloat64Array log_sin_pi_z_data = complex_log_sin(PI * x, PI * y);
		std::complex<double> log_sin_pi_z(log_sin_pi_z_data[0], log_sin_pi_z_data[1]);

		std::complex<double> val = LOG_PI - log_sin_pi_z - lg1z_0;

		PackedFloat64Array cot_pi_z_data = complex_cot(PI * x, PI * y);
		std::complex<double> cot_pi_z(cot_pi_z_data[0], cot_pi_z_data[1]);

		std::complex<double> dx = -PI * cot_pi_z + lg1z_1;

		std::complex<double> csc2 = 1.0 + cot_pi_z * cot_pi_z;
		std::complex<double> d2x = (PI * PI) * csc2 - lg1z_2;

		PackedFloat64Array result; result.resize(6);
		result[0] = val.real(); result[1] = val.imag();
		result[2] = dx.real(); result[3] = dx.imag();
		result[4] = d2x.real(); result[5] = d2x.imag();
		return result;
	} else {
		return lanczos_log_gamma_with_derivatives(x, y);
	}
}

PackedFloat64Array ComplexFunctions::log_zeta_continuation_with_derivatives(double x, double y, int iters) {
	if (x >= 0.5) {
		PackedFloat64Array zeta_data = zeta_with_derivatives(x, y, iters);
		std::complex<double> z_val(zeta_data[0], zeta_data[1]);
		std::complex<double> z_dx(zeta_data[2], zeta_data[3]);
		std::complex<double> z_d2x(zeta_data[4], zeta_data[5]);

		std::complex<double> val = std::log(z_val);
		std::complex<double> dx = z_dx / z_val;
		std::complex<double> dx2 = (z_d2x * z_val - z_dx * z_dx) / (z_val * z_val);

		PackedFloat64Array result; result.resize(6);
		result[0] = val.real(); result[1] = val.imag();
		result[2] = dx.real(); result[3] = dx.imag();
		result[4] = dx2.real(); result[5] = dx2.imag();
		return result;
	}

	std::complex<double> s(x, y);

	std::complex<double> log_sum = s * LOG_2 + (s - 1.0) * LOG_PI;
	std::complex<double> ratio(LOG_2 + LOG_PI, 0.0);
	std::complex<double> d2_ratio(0.0, 0.0);

	PackedFloat64Array cls_data = complex_log_sin((PI * 0.5) * x, (PI * 0.5) * y);
	std::complex<double> cls(cls_data[0], cls_data[1]);
	log_sum += cls;

	PackedFloat64Array cot_pi_s_2_data = complex_cot((PI * 0.5) * x, (PI * 0.5) * y);
	std::complex<double> cot_pi_s_2(cot_pi_s_2_data[0], cot_pi_s_2_data[1]);

	ratio += (PI * 0.5) * cot_pi_s_2;

	std::complex<double> csc_pi_s_2_sq = 1.0 + cot_pi_s_2 * cot_pi_s_2;
	d2_ratio -= (PI * PI * 0.25) * csc_pi_s_2_sq;

	PackedFloat64Array lg_data = complex_log_gamma_with_derivatives(1.0 - x, -y);
	std::complex<double> lg_data_0(lg_data[0], lg_data[1]);
	std::complex<double> lg_data_1(lg_data[2], lg_data[3]);
	std::complex<double> lg_data_2(lg_data[4], lg_data[5]);

	log_sum += lg_data_0;
	ratio -= lg_data_1;
	d2_ratio += lg_data_2;

	PackedFloat64Array reflected_zeta_data = zeta_with_derivatives(1.0 - x, -y, iters);
	std::complex<double> reflected_val(reflected_zeta_data[0], reflected_zeta_data[1]);
	std::complex<double> reflected_dx(reflected_zeta_data[2], reflected_zeta_data[3]);
	std::complex<double> reflected_d2x(reflected_zeta_data[4], reflected_zeta_data[5]);

	std::complex<double> clog = std::log(reflected_val);
	log_sum += clog;

	ratio -= reflected_dx / reflected_val;
	d2_ratio += (reflected_d2x * reflected_val - reflected_dx * reflected_dx) / (reflected_val * reflected_val);

	PackedFloat64Array result; result.resize(6);
	result[0] = log_sum.real(); result[1] = log_sum.imag();
	result[2] = ratio.real(); result[3] = ratio.imag();
	result[4] = d2_ratio.real(); result[5] = d2_ratio.imag();
	return result;
}

PackedFloat64Array ComplexFunctions::zeta_continuation_with_derivatives(double x, double y, int iters) {
	if (x >= 0.5) {
		return zeta_with_derivatives(x, y, iters);
	}

	PackedFloat64Array log_z_data = log_zeta_continuation_with_derivatives(x, y, iters);
	std::complex<double> log_z_0(log_z_data[0], log_z_data[1]);
	std::complex<double> log_z_1(log_z_data[2], log_z_data[3]);
	std::complex<double> log_z_2(log_z_data[4], log_z_data[5]);

	std::complex<double> val = std::exp(log_z_0);
	std::complex<double> dx = val * log_z_1;
	std::complex<double> d2x = val * (log_z_2 + log_z_1 * log_z_1);

	PackedFloat64Array result; result.resize(6);
	result[0] = val.real(); result[1] = val.imag();
	result[2] = dx.real(); result[3] = dx.imag();
	result[4] = d2x.real(); result[5] = d2x.imag();
	return result;
}


PackedFloat64Array ComplexFunctions::log_eta_continuation_with_derivatives(double x, double y, int iters) {
	if (x >= 0.5) {
		PackedFloat64Array e_data = dirichlet_eta_with_derivatives(x, y, iters);
		std::complex<double> e_val(e_data[0], e_data[1]);
		std::complex<double> e_dx(e_data[2], e_data[3]);
		std::complex<double> e_d2x(e_data[4], e_data[5]);

		std::complex<double> val = std::log(e_val);
		std::complex<double> dx = e_dx / e_val;
		std::complex<double> dx2 = (e_d2x * e_val - e_dx * e_dx) / (e_val * e_val);

		PackedFloat64Array result; result.resize(6);
		result[0] = val.real(); result[1] = val.imag();
		result[2] = dx.real(); result[3] = dx.imag();
		result[4] = dx2.real(); result[5] = dx2.imag();
		return result;
	}

	std::complex<double> s(x, y);

	std::complex<double> log_sum = s * LOG_2 + (s - 1.0) * LOG_PI;
	std::complex<double> ratio(LOG_2 + LOG_PI, 0.0);
	std::complex<double> d2_ratio(0.0, 0.0);

	PackedFloat64Array cls_data = complex_log_sin((PI * 0.5) * x, (PI * 0.5) * y);
	std::complex<double> cls(cls_data[0], cls_data[1]);
	log_sum += cls;

	PackedFloat64Array cot_pi_s_2_data = complex_cot((PI * 0.5) * x, (PI * 0.5) * y);
	std::complex<double> cot_pi_s_2(cot_pi_s_2_data[0], cot_pi_s_2_data[1]);

	ratio += (PI * 0.5) * cot_pi_s_2;

	std::complex<double> cot_pi_s_2_sq = cot_pi_s_2 * cot_pi_s_2;
	std::complex<double> csc_pi_s_2_sq = 1.0 + cot_pi_s_2_sq;
	d2_ratio -= (PI * PI * 0.25) * csc_pi_s_2_sq;

	PackedFloat64Array lg_data = complex_log_gamma_with_derivatives(1.0 - x, -y);
	std::complex<double> lg_val(lg_data[0], lg_data[1]);
	std::complex<double> lg_dx(lg_data[2], lg_data[3]);
	std::complex<double> lg_d2x(lg_data[4], lg_data[5]);
	log_sum += lg_val;
	ratio -= lg_dx;
	d2_ratio += lg_d2x;

	PackedFloat64Array ref_data = dirichlet_eta_with_derivatives(1.0 - x, -y, iters);
	std::complex<double> ref_val(ref_data[0], ref_data[1]);
	std::complex<double> ref_dx(ref_data[2], ref_data[3]);
	std::complex<double> ref_d2x(ref_data[4], ref_data[5]);

	log_sum += std::log(ref_val);
	std::complex<double> e_ratio = ref_dx / ref_val;
	ratio -= e_ratio;
	d2_ratio += (ref_d2x * ref_val - ref_dx * ref_dx) / (ref_val * ref_val);

	double amp1 = std::pow(2.0, x);
	double theta1 = y * LOG_2;
	std::complex<double> term1(amp1 * std::cos(theta1), amp1 * std::sin(theta1));
	std::complex<double> denom1 = 1.0 - term1;
	std::complex<double> ddenom1_dx = -LOG_2 * term1;
	std::complex<double> d2denom1_dx2 = -(LOG_2 * LOG_2) * term1;
	std::complex<double> ratio_denom1 = ddenom1_dx / denom1;

	double amp2 = std::pow(2.0, 1.0 - x);
	double theta2 = -y * LOG_2;
	std::complex<double> term2(amp2 * std::cos(theta2), amp2 * std::sin(theta2));
	std::complex<double> denom2 = 1.0 - term2;
	std::complex<double> ddenom2_dx = LOG_2 * term2;
	std::complex<double> d2denom2_dx2 = -(LOG_2 * LOG_2) * term2;
	std::complex<double> ratio_denom2 = ddenom2_dx / denom2;

	log_sum += std::log(denom2) - std::log(denom1);
	ratio += ratio_denom2 - ratio_denom1;
	d2_ratio += (d2denom2_dx2 * denom2 - ddenom2_dx * ddenom2_dx) / (denom2 * denom2);
	d2_ratio -= (d2denom1_dx2 * denom1 - ddenom1_dx * ddenom1_dx) / (denom1 * denom1);

	PackedFloat64Array result; result.resize(6);
	result[0] = log_sum.real(); result[1] = log_sum.imag();
	result[2] = ratio.real(); result[3] = ratio.imag();
	result[4] = d2_ratio.real(); result[5] = d2_ratio.imag();
	return result;
}

PackedFloat64Array ComplexFunctions::eta_continuation_with_derivatives(double x, double y, int iters) {
	if (x >= 0.5) {
		return dirichlet_eta_with_derivatives(x, y, iters);
	}

	PackedFloat64Array log_e_data = log_eta_continuation_with_derivatives(x, y, iters);
	std::complex<double> log_e_0(log_e_data[0], log_e_data[1]);
	std::complex<double> log_e_1(log_e_data[2], log_e_data[3]);
	std::complex<double> log_e_2(log_e_data[4], log_e_data[5]);

	std::complex<double> val = std::exp(log_e_0);
	std::complex<double> dx = val * log_e_1;
	std::complex<double> d2x = val * (log_e_2 + log_e_1 * log_e_1);

	PackedFloat64Array result; result.resize(6);
	result[0] = val.real(); result[1] = val.imag();
	result[2] = dx.real(); result[3] = dx.imag();
	result[4] = d2x.real(); result[5] = d2x.imag();
	return result;
}

PackedFloat64Array ComplexFunctions::_find_zero_core(double x, double y, int iters, double step_mult, double step_max, bool debug, DerivativeFunc func) {
	auto res = (this->*func)(x, y, iters * 2);
	double f_val_x = res[0]; double f_val_y = res[1];
	double f_prime_x = res[2]; double f_prime_y = res[3];
	double f_second_x = res[4]; double f_second_y = res[5];

	// Complex multiplication of f_val and f_second
	double num_x = f_val_x * f_second_x - f_val_y * f_second_y;
	double num_y = f_val_x * f_second_y + f_val_y * f_second_x;
	double num_len = std::hypot(num_x, num_y);

	double f_prime_len_sq = f_prime_x * f_prime_x + f_prime_y * f_prime_y;
	double den_kappa = std::max(f_prime_len_sq, 1e-12);

	if (num_len / den_kappa >= 1.0) {
		return PackedFloat64Array();
	}

	bool converged = false;
	double refined_x = x;
	double refined_y = y;
	double current_step_mult = step_mult;

	double cur_f_x = f_val_x;
	double cur_f_y = f_val_y;
	double f_mag = std::hypot(f_val_x, f_val_y);

	if (debug) {
		godot::UtilityFunctions::print(godot::vformat("\nStart C++ | z (%9.6f, %9.6f) | f (%9.6f, %9.6f) | len %10.6f | mult %6.2f", refined_x, refined_y, cur_f_x, cur_f_y, f_mag, current_step_mult));
	}

	for (int step_idx = 0; step_idx < 15; step_idx++) {
		auto n_res = (this->*func)(refined_x, refined_y, iters * 2);
		cur_f_x = n_res[0]; cur_f_y = n_res[1];
		double cur_fp_x = n_res[2]; double cur_fp_y = n_res[3];
		double cur_fpp_x = n_res[4]; double cur_fpp_y = n_res[5];

		f_mag = std::hypot(cur_f_x, cur_f_y);

		if (debug) {
			godot::UtilityFunctions::print(godot::vformat("Step %4d | z (%9.6f, %9.6f) | f (%9.6f, %9.6f) | len %10.6f | mult %6.2f", step_idx, refined_x, refined_y, cur_f_x, cur_f_y, f_mag, current_step_mult));
		}

		double fp_len_sq = cur_fp_x * cur_fp_x + cur_fp_y * cur_fp_y;
		if (fp_len_sq < 1e-12) {
			// Early exit if derivative is zero
			break;
		}

		// fp * fp
		double fp2_x = cur_fp_x * cur_fp_x - cur_fp_y * cur_fp_y;
		double fp2_y = 2.0 * cur_fp_x * cur_fp_y;
		// 2 * fp * fp
		double term1_x = 2.0 * fp2_x;
		double term1_y = 2.0 * fp2_y;

		// f * fpp
		double term2_x = cur_f_x * cur_fpp_x - cur_f_y * cur_fpp_y;
		double term2_y = cur_f_x * cur_fpp_y + cur_f_y * cur_fpp_x;

		// den = term1 - term2
		double den_x = term1_x - term2_x;
		double den_y = term1_y - term2_y;

		double step_x = 0.0;
		double step_y = 0.0;

		if (std::hypot(den_x, den_y) < 1e-12) {
			// step = f_val / f_prime
			double d = cur_fp_x * cur_fp_x + cur_fp_y * cur_fp_y;
			if (d > 0.0) {
				step_x = (cur_f_x * cur_fp_x + cur_f_y * cur_fp_y) / d;
				step_y = (cur_f_y * cur_fp_x - cur_f_x * cur_fp_y) / d;
			}
		} else {
			// num = 2.0 * f * fp
			double f_fp_x = cur_f_x * cur_fp_x - cur_f_y * cur_fp_y;
			double f_fp_y = cur_f_x * cur_fp_y + cur_f_y * cur_fp_x;
			double num_x = 2.0 * f_fp_x;
			double num_y = 2.0 * f_fp_y;

			// step = num / den
			double d = den_x * den_x + den_y * den_y;
			step_x = (num_x * den_x + num_y * den_y) / d;
			step_y = (num_y * den_x - num_x * den_y) / d;
		}

		double step_len = std::hypot(step_x, step_y);
		if (step_len > step_max) {
			step_x = (step_x / step_len) * step_max;
			step_y = (step_y / step_len) * step_max;
		}

		double next_x = refined_x - step_x * current_step_mult;
		double next_y = refined_y - step_y * current_step_mult;

		double z_dist = std::hypot(next_x - refined_x, next_y - refined_y);

		if (f_mag < 1e-5 || z_dist < 1e-4) {
			refined_x = next_x;
			refined_y = next_y;
			converged = true;
			break;
		}

		if (f_mag < 0.001) {
			current_step_mult *= 0.9;
		} else if (f_mag < 0.01) {
			current_step_mult *= 0.99;
		}

		refined_x = next_x;
		refined_y = next_y;
	}

	if (debug) {
		godot::UtilityFunctions::print(godot::vformat("End       | z (%9.6f, %9.6f) | f (%9.6f, %9.6f) | len %10.6f | mult %6.2f | converged %s", refined_x, refined_y, cur_f_x, cur_f_y, f_mag, current_step_mult, converged ? "true" : "false"));
	}

	if (converged || f_mag < 1e-2) {
		PackedFloat64Array ret;
		ret.push_back(refined_x);
		ret.push_back(refined_y);
		return ret;
	}

	return PackedFloat64Array();
}

PackedFloat64Array ComplexFunctions::eta_find_zero(double x, double y, int iters, double step_mult, double step_max, bool debug) {
	if (x < 0.0) {
		return _find_zero_core(x, y, iters, step_mult, step_max, debug, &ComplexFunctions::eta_continuation_with_derivatives);
	} else {
		return _find_zero_core(x, y, iters, step_mult, step_max, debug, &ComplexFunctions::eta_borwein_with_derivatives);
	}
}

PackedFloat64Array ComplexFunctions::dirichlet_beta_with_derivatives(double x, double y, int iters) {
	PackedFloat64Array result;
	result.resize(6);

	if (x <= 1e-3) {
		result[0] = NAN; result[1] = NAN;
		result[2] = NAN; result[3] = NAN;
		result[4] = NAN; result[5] = NAN;
		return result;
	}

	double beta_x = 0.0, beta_y = 0.0;
	double dbeta_dx_x = 0.0, dbeta_dx_y = 0.0;
	double d2beta_dx2_x = 0.0, d2beta_dx2_y = 0.0;

	for (int n = 0; n < iters; n += 2) {
		double kf = 2.0 * (double)n + 1.0;
		double amp = std::pow(kf, -x);
		double log_k = std::log(kf);
		double theta = -y * log_k;
		double term_x = amp * std::cos(theta);
		double term_y = amp * std::sin(theta);

		beta_x += term_x;
		beta_y += term_y;

		dbeta_dx_x -= log_k * term_x;
		dbeta_dx_y -= log_k * term_y;

		d2beta_dx2_x += (log_k * log_k) * term_x;
		d2beta_dx2_y += (log_k * log_k) * term_y;

		double kf2 = 2.0 * (double)(n + 1) + 1.0;
		double amp2 = std::pow(kf2, -x);
		double log_k2 = std::log(kf2);
		double theta2 = -y * log_k2;
		double term2_x = amp2 * std::cos(theta2);
		double term2_y = amp2 * std::sin(theta2);

		beta_x -= term2_x;
		beta_y -= term2_y;

		dbeta_dx_x += log_k2 * term2_x;
		dbeta_dx_y += log_k2 * term2_y;

		d2beta_dx2_x -= (log_k2 * log_k2) * term2_x;
		d2beta_dx2_y -= (log_k2 * log_k2) * term2_y;

		if (amp < 1e-4 || amp2 < 1e-4) break;
	}

	result[0] = beta_x; result[1] = beta_y;
	result[2] = dbeta_dx_x; result[3] = dbeta_dx_y;
	result[4] = d2beta_dx2_x; result[5] = d2beta_dx2_y;
	return result;
}


PackedFloat64Array ComplexFunctions::log_beta_continuation_with_derivatives(double x, double y, int iters) {
	if (x >= 0.5) {
		PackedFloat64Array b_data = dirichlet_beta_with_derivatives(x, y, iters);
		std::complex<double> b_val(b_data[0], b_data[1]);
		std::complex<double> b_dx(b_data[2], b_data[3]);
		std::complex<double> b_d2x(b_data[4], b_data[5]);

		std::complex<double> val = std::log(b_val);
		std::complex<double> dx = b_dx / b_val;
		std::complex<double> dx2 = (b_d2x * b_val - b_dx * b_dx) / (b_val * b_val);

		PackedFloat64Array result; result.resize(6);
		result[0] = val.real(); result[1] = val.imag();
		result[2] = dx.real(); result[3] = dx.imag();
		result[4] = dx2.real(); result[5] = dx2.imag();
		return result;
	}

	std::complex<double> s(x, y);

	// log_sum = (s-1) * log(pi/2) + log(cos(pi/2 * s)) + log Gamma(1-s) + log beta(1-s)
	// For log(cos(pi/2 * s)):
	// cos(z) = sin(pi/2 - z)
	// pi/2 - pi/2 * s = pi/2 * (1 - s)
	// So log(cos(pi/2 * s)) = log(sin(pi/2 * (1 - s)))
	// We can reuse complex_log_sin.

	double log_pi_2 = std::log(PI / 2.0);
	std::complex<double> log_sum = (s - 1.0) * log_pi_2;
	std::complex<double> ratio(log_pi_2, 0.0);
	std::complex<double> d2_ratio(0.0, 0.0);

	PackedFloat64Array cls_data = complex_log_sin((PI * 0.5) * (1.0 - x), -(PI * 0.5) * y);
	std::complex<double> cls(cls_data[0], cls_data[1]);
	log_sum += cls;

	// d/ds log(cos(pi/2 * s)) = -pi/2 * tan(pi/2 * s)
	// Wait, d/ds [ log(sin(pi/2 * (1 - s))) ] = log_sin_prime(pi/2 * (1 - s)) * (-pi/2)
	// Since log_sin_prime(z) = cot(z), this is -pi/2 * cot(pi/2 * (1 - s)) = -pi/2 * tan(pi/2 * s)
	PackedFloat64Array cot_pi_s1_2_data = complex_cot((PI * 0.5) * (1.0 - x), -(PI * 0.5) * y);
	std::complex<double> cot_pi_s1_2(cot_pi_s1_2_data[0], cot_pi_s1_2_data[1]);
	ratio -= (PI * 0.5) * cot_pi_s1_2;

	// d2/ds2 log(cos(pi/2 * s)) = d/ds [ -pi/2 * cot(pi/2 * (1 - s)) ] = -pi/2 * (-csc^2(pi/2 * (1 - s))) * (-pi/2) = -(pi/2)^2 * csc^2(pi/2 * (1 - s))
	std::complex<double> cot_pi_s1_2_sq = cot_pi_s1_2 * cot_pi_s1_2;
	std::complex<double> csc_pi_s1_2_sq = 1.0 + cot_pi_s1_2_sq;
	d2_ratio -= (PI * PI * 0.25) * csc_pi_s1_2_sq;

	PackedFloat64Array lg_data = complex_log_gamma_with_derivatives(1.0 - x, -y);
	std::complex<double> lg_val(lg_data[0], lg_data[1]);
	std::complex<double> lg_dx(lg_data[2], lg_data[3]);
	std::complex<double> lg_d2x(lg_data[4], lg_data[5]);
	log_sum += lg_val;
	ratio -= lg_dx;
	d2_ratio += lg_d2x;

	PackedFloat64Array ref_data = dirichlet_beta_with_derivatives(1.0 - x, -y, iters);
	std::complex<double> ref_val(ref_data[0], ref_data[1]);
	std::complex<double> ref_dx(ref_data[2], ref_data[3]);
	std::complex<double> ref_d2x(ref_data[4], ref_data[5]);

	log_sum += std::log(ref_val);
	std::complex<double> b_ratio = ref_dx / ref_val;
	ratio -= b_ratio;
	d2_ratio += (ref_d2x * ref_val - ref_dx * ref_dx) / (ref_val * ref_val);

	PackedFloat64Array result; result.resize(6);
	result[0] = log_sum.real(); result[1] = log_sum.imag();
	result[2] = ratio.real(); result[3] = ratio.imag();
	result[4] = d2_ratio.real(); result[5] = d2_ratio.imag();
	return result;
}

PackedFloat64Array ComplexFunctions::beta_continuation_with_derivatives(double x, double y, int iters) {
	if (x >= 0.5) {
		return dirichlet_beta_with_derivatives(x, y, iters);
	}

	PackedFloat64Array log_b_data = log_beta_continuation_with_derivatives(x, y, iters);
	std::complex<double> log_b_0(log_b_data[0], log_b_data[1]);
	std::complex<double> log_b_1(log_b_data[2], log_b_data[3]);
	std::complex<double> log_b_2(log_b_data[4], log_b_data[5]);

	std::complex<double> val = std::exp(log_b_0);
	std::complex<double> dx = val * log_b_1;
	std::complex<double> d2x = val * (log_b_2 + log_b_1 * log_b_1);

	PackedFloat64Array result; result.resize(6);
	result[0] = val.real(); result[1] = val.imag();
	result[2] = dx.real(); result[3] = dx.imag();
	result[4] = d2x.real(); result[5] = d2x.imag();
	return result;
}

PackedFloat64Array ComplexFunctions::beta_find_zero(double x, double y, int iters, double step_mult, double step_max, bool debug) {
	return _find_zero_core(x, y, iters, step_mult, step_max, debug, &ComplexFunctions::beta_continuation_with_derivatives);
}


PackedFloat64Array ComplexFunctions::zeta_find_zero(double x, double y, int iters, double step_mult, double step_max, bool debug) {
	if (x < 0.0) {
		return _find_zero_core(x, y, iters, step_mult, step_max, debug, &ComplexFunctions::zeta_continuation_with_derivatives);
	} else {
		return _find_zero_core(x, y, iters, step_mult, step_max, debug, &ComplexFunctions::zeta_borwein_with_derivatives);
	}
}

} // namespace godot
