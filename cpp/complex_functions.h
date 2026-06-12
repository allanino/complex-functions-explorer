#ifndef COMPLEX_FUNCTIONS_H
#define COMPLEX_FUNCTIONS_H

#include <godot_cpp/classes/ref_counted.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/packed_float64_array.hpp>

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
	PackedFloat64Array zeta_with_derivatives(double x, double y, int iters);
	PackedFloat64Array lanczos_log_gamma_with_derivatives(double x, double y);
	PackedFloat64Array complex_log_gamma_with_derivatives(double x, double y);
	PackedFloat64Array log_zeta_continuation_with_derivatives(double x, double y, int iters);
	PackedFloat64Array zeta_continuation_with_derivatives(double x, double y, int iters);

	PackedFloat64Array complex_mul(double ax, double ay, double bx, double by);
	PackedFloat64Array complex_div(double ax, double ay, double bx, double by);
	PackedFloat64Array complex_exp(double x, double y);
	PackedFloat64Array complex_log(double x, double y);
	PackedFloat64Array complex_sin(double x, double y);
	PackedFloat64Array complex_cot(double x, double y);
	PackedFloat64Array complex_log_sin(double x, double y);

};

} // namespace godot

#endif // COMPLEX_FUNCTIONS_H
