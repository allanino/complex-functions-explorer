#ifndef COMPLEX_FUNCTIONS_H
#define COMPLEX_FUNCTIONS_H

#include <godot_cpp/classes/ref_counted.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/vector2.hpp>
#include <godot_cpp/variant/array.hpp>

namespace godot {

class ComplexFunctions : public RefCounted {
	GDCLASS(ComplexFunctions, RefCounted)

protected:
	static void _bind_methods();

public:
	ComplexFunctions();
	~ComplexFunctions();

	Vector2 lanczos_gamma(const Vector2 &z_orig);

	Array dirichlet_eta_with_derivatives(float x, float y, int iters);
	Array zeta_with_derivatives(float x, float y, int iters);
	Array lanczos_log_gamma_with_derivatives(const Vector2 &z_orig);
	Array complex_log_gamma_with_derivatives(float x, float y);
	Array log_zeta_continuation_with_derivatives(float x, float y, int iters);
	Array zeta_continuation_with_derivatives(float x, float y, int iters);

};

} // namespace godot

#endif // COMPLEX_FUNCTIONS_H
