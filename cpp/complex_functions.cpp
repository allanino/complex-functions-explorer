#include "complex_functions.h"

#include <complex>

namespace godot {

void ComplexFunctions::_bind_methods() {
	ClassDB::bind_method(D_METHOD("lanczos_gamma", "x", "y"), &ComplexFunctions::lanczos_gamma);

	ClassDB::bind_method(D_METHOD("dirichlet_eta_with_derivatives", "x", "y", "iters"), &ComplexFunctions::dirichlet_eta_with_derivatives);
	ClassDB::bind_method(D_METHOD("zeta_with_derivatives", "x", "y", "iters"), &ComplexFunctions::zeta_with_derivatives);
	ClassDB::bind_method(D_METHOD("lanczos_log_gamma_with_derivatives", "z_orig"), &ComplexFunctions::lanczos_log_gamma_with_derivatives);
	ClassDB::bind_method(D_METHOD("complex_log_gamma_with_derivatives", "x", "y"), &ComplexFunctions::complex_log_gamma_with_derivatives);
	ClassDB::bind_method(D_METHOD("log_zeta_continuation_with_derivatives", "x", "y", "iters"), &ComplexFunctions::log_zeta_continuation_with_derivatives);
	ClassDB::bind_method(D_METHOD("zeta_continuation_with_derivatives", "x", "y", "iters"), &ComplexFunctions::zeta_continuation_with_derivatives);

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

	if (x < -1.0) {
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

	   if (amp < 1e-4 || amp2 < 1e-4 || amp > 1e4 || amp2 > 1e4) {
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

} // namespace godot
