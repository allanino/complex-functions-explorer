#ifndef COMPLEX_FUNCTIONS_H
#define COMPLEX_FUNCTIONS_H

#include <godot_cpp/classes/object.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/vector2.hpp>

namespace godot {

class ComplexFunctions : public Object {
	GDCLASS(ComplexFunctions, Object)

protected:
	static void _bind_methods();

public:
	ComplexFunctions();
	~ComplexFunctions();

	static Vector2 lanczos_gamma(const Vector2 &z_orig);
};

} // namespace godot

#endif // COMPLEX_FUNCTIONS_H
