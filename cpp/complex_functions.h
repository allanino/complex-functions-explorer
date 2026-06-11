#ifndef COMPLEX_FUNCTIONS_H
#define COMPLEX_FUNCTIONS_H

#include <godot_cpp/classes/ref_counted.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/vector2.hpp>

namespace godot {

class ComplexFunctions : public RefCounted {
	GDCLASS(ComplexFunctions, RefCounted)

protected:
	static void _bind_methods();

public:
	ComplexFunctions();
	~ComplexFunctions();

	Vector2 lanczos_gamma(const Vector2 &z_orig);
};

} // namespace godot

#endif // COMPLEX_FUNCTIONS_H
