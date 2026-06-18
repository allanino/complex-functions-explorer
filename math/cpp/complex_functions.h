#ifndef COMPLEX_FUNCTIONS_H
#define COMPLEX_FUNCTIONS_H

#include <godot_cpp/classes/ref_counted.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/packed_float64_array.hpp>
#include <map>
#include <vector>
#include <mutex>

namespace godot {

class ComplexFunctions : public RefCounted {
	GDCLASS(ComplexFunctions, RefCounted)

protected:
	static void _bind_methods();

public:
	ComplexFunctions();
	~ComplexFunctions();

	PackedFloat64Array lanczos_gamma(double x, double y);

	PackedFloat64Array dirichlet_eta_with_derivatives(double x, double y, int iters);
	PackedFloat64Array dirichlet_beta_with_derivatives(double x, double y, int iters);
	PackedFloat64Array zeta_with_derivatives(double x, double y, int iters);
	PackedFloat64Array eta_find_zero(double x, double y, int iters, double step_mult, double step_max, bool debug);
	PackedFloat64Array zeta_find_zero(double x, double y, int iters, double step_mult, double step_max, bool debug);
	PackedFloat64Array beta_find_zero(double x, double y, int iters, double step_mult, double step_max, bool debug);

	PackedFloat64Array eta_is_close_to_zero(double x, double y, int iters);
	PackedFloat64Array zeta_is_close_to_zero(double x, double y, int iters);
	PackedFloat64Array beta_is_close_to_zero(double x, double y, int iters);

	PackedFloat64Array eta_borwein_with_derivatives(double x, double y, int order);
	PackedFloat64Array zeta_borwein_with_derivatives(double x, double y, int order);
	PackedFloat64Array lanczos_log_gamma_with_derivatives(double x, double y);
	PackedFloat64Array complex_log_gamma_with_derivatives(double x, double y);
	PackedFloat64Array log_zeta_continuation_with_derivatives(double x, double y, int iters);
	PackedFloat64Array zeta_continuation_with_derivatives(double x, double y, int iters);
	PackedFloat64Array log_eta_continuation_with_derivatives(double x, double y, int iters);
	PackedFloat64Array eta_continuation_with_derivatives(double x, double y, int iters);
	PackedFloat64Array log_beta_continuation_with_derivatives(double x, double y, int iters);
	PackedFloat64Array beta_continuation_with_derivatives(double x, double y, int iters);

	PackedFloat64Array complex_mul(double ax, double ay, double bx, double by);
	PackedFloat64Array complex_div(double ax, double ay, double bx, double by);
	PackedFloat64Array complex_exp(double x, double y);
	PackedFloat64Array complex_log(double x, double y);
	PackedFloat64Array complex_sin(double x, double y);
	PackedFloat64Array complex_cot(double x, double y);
	PackedFloat64Array complex_log_sin(double x, double y);

private:
	std::map<int, std::vector<double>> _borwein_cache;
	std::mutex _borwein_mutex;

	std::vector<double> _get_borwein_weights(int order);

	using DerivativeFunc = PackedFloat64Array (ComplexFunctions::*)(double, double, int);
	PackedFloat64Array _find_zero_core(double x, double y, int iters, double step_mult, double step_max, bool debug, DerivativeFunc func);
	PackedFloat64Array _is_close_to_zero_core(double x, double y, int iters, DerivativeFunc func);

};

} // namespace godot

#endif // COMPLEX_FUNCTIONS_H
