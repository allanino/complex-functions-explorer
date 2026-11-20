# Shared Riemann Sphere geometry and stereographic projection helpers for GDScript.
# Mirrors math/glsl/riemann_sphere.gdshaderinc.
class_name RiemannSphere

# Stereographic magnification thresholds (complex units per world unit) for height fading
# and per-pixel fragment evaluation.
const HEIGHT_FADE_START: float = 2.0
const HEIGHT_FADE_END: float = 6.0
const PER_PIXEL_THRESHOLD: float = 0.05
const PER_PIXEL_HYSTERESIS: float = 0.8
const MAX_HEIGHT_RATIO: float = 0.45

# Inverse stereographic projection (from the south pole): complex number -> unit vector.
# (0, 1, 0) -> z = 0, (0, -1, 0) -> z = infinity.
static func complex_to_unit(z: Vector2) -> Vector3:
	if not is_finite(z.x) or not is_finite(z.y):
		return Vector3(0.0, -1.0, 0.0)
	var r2 = z.length_squared()
	if not is_finite(r2):
		return Vector3(0.0, -1.0, 0.0)
	var den = 1.0 + r2
	return Vector3(2.0 * z.x / den, (1.0 - r2) / den, -2.0 * z.y / den)

# Stereographic projection: unit vector -> complex number.
static func unit_to_complex(u: Vector3) -> Vector2:
	var w = 1.0 + u.y
	if w <= 1e-12:
		return Vector2(INF, 0.0)
	return Vector2(u.x / w, -u.z / w)

# Constructs a local player-frame -> inertial-sphere-frame Basis at complex coordinate z,
# keeping "+Re -> +X" and "+Im -> -Z". Uses the exact closed-form stereographic tangent
# d/dx u(z) / |d/dx u(z)|, rescaled for |z| > 1 to avoid float overflow.
static func basis_at_complex(z: Vector2) -> Basis:
	var up = complex_to_unit(z)
	var r2 = z.length_squared()
	var east: Vector3
	if r2 <= 1.0:
		var den = 1.0 + r2
		east = Vector3(1.0 - z.x * z.x + z.y * z.y, -2.0 * z.x, 2.0 * z.x * z.y) / den
	else:
		var inv_r = 1.0 / sqrt(r2)
		var ux = z.x * inv_r
		var uy = z.y * inv_r
		var inv_r2 = inv_r * inv_r
		var den = 1.0 + inv_r2
		east = Vector3(inv_r2 - ux * ux + uy * uy, -2.0 * ux * inv_r, 2.0 * ux * uy) / den
	east = (east - up * east.dot(up)).normalized()
	var back = east.cross(up).normalized()
	return Basis(east, up, back)

# Rotates `basis` by walking a flat arc-length offset (world units) on a sphere of `radius`.
static func advance_basis(basis: Basis, offset: Vector2, radius: float) -> Basis:
	var dist = offset.length()
	if dist < 1e-9 or radius <= 0.0:
		return basis
	var dir = Vector3(offset.x, 0.0, offset.y) / dist
	var axis = Vector3.UP.cross(dir).normalized()
	return (basis * Basis(axis, dist / radius)).orthonormalized()

# Azimuthal-equidistant chart offset (world units relative to player) -> local unit direction.
static func chart_to_local_unit(offset: Vector2, radius: float) -> Vector3:
	var dist = offset.length()
	if dist < 1e-9:
		return Vector3.UP
	var d = minf(dist / maxf(radius, 1e-5), PI)
	var s = sin(d) / dist
	return Vector3(offset.x * s, cos(d), offset.y * s)

# Maps a world offset around the player to the complex coordinate on the Riemann Sphere.
static func world_to_complex(world_x: float, world_z: float, basis: Basis, radius: float) -> Vector2:
	var local_dir = chart_to_local_unit(Vector2(world_x, world_z), radius)
	return unit_to_complex(basis * local_dir)

# Inverse of world_to_complex.
static func complex_to_world(complex_x: float, complex_y: float, basis: Basis, radius: float) -> Vector2:
	var u = complex_to_unit(Vector2(complex_x, complex_y))
	var l = basis.transposed() * u
	var d = acos(clampf(l.y, -1.0, 1.0))
	var horiz = Vector2(l.x, l.z)
	var hl = horiz.length()
	if hl < 1e-9:
		return Vector2.ZERO
	return horiz / hl * d * radius

# Local stereographic magnification |dz|/ds in complex units per world unit.
static func magnification(z: Vector2, radius: float) -> float:
	if not is_finite(z.x) or not is_finite(z.y):
		return INF
	return (1.0 + z.length_squared()) / (2.0 * maxf(radius, 1e-5))

# Smoothly fades radial height displacement to 0 where vertices cannot resolve the terrain.
static func height_fade(z: Vector2, radius: float) -> float:
	var lam = magnification(z, radius)
	if not is_finite(lam) or lam >= HEIGHT_FADE_END:
		return 0.0
	return 1.0 - smoothstep(HEIGHT_FADE_START, HEIGHT_FADE_END, lam)

# Smoothly bounds radial displacement to (-h_max, +h_max) with h_max = MAX_HEIGHT_RATIO * R.
static func compress_height(h: float, radius: float) -> float:
	var h_max = maxf(MAX_HEIGHT_RATIO * radius, 1e-5)
	if is_nan(h):
		return h_max
	if is_inf(h):
		return h_max if h > 0.0 else -h_max
	return h_max * tanh(clampf(h / h_max, -20.0, 20.0))

# World-space Y height of the displaced sphere surface at chart offset (world_x, world_z).
static func surface_y(world_x: float, world_z: float, radial_h: float, basis: Basis, radius: float, apply_curvature: bool = true) -> float:
	var r_sphere = maxf(radius, 1e-5)
	var h = 0.0
	if radial_h != 0.0:
		var fade = height_fade(world_to_complex(world_x, world_z, basis, r_sphere), r_sphere)
		if fade > 0.0:
			h = compress_height(radial_h, r_sphere) * fade
	if not apply_curvature:
		return h
	var dist = Vector2(world_x, world_z).length()
	var d = minf(dist / r_sphere, PI)
	return (r_sphere + h) * cos(d) - r_sphere

# Projects the camera's local forward direction (yaw) through `basis` and the stereographic
# differential into 2D minimap screen space (+X = +Re, -Y = +Im).
static func project_forward_to_minimap(yaw: float, basis: Basis) -> Vector2:
	var f_local = Vector3(-sin(yaw), 0.0, -cos(yaw))
	var u = basis.y
	var du = basis * f_local
	var w = maxf(1.0 + u.y, 1e-5)
	var d_re = du.x * w - u.x * du.y
	var d_im = -du.z * w + u.z * du.y
	var v = Vector2(d_re, -d_im)
	return v.normalized() if v.length_squared() > 1e-12 else Vector2(-sin(yaw), -cos(yaw))

# Computes Vector2(min_lambda, max_lambda) across a chunk of angular half-radius `ang`
# (precomputed cos_ang, sin_ang) without calling acos/cos per chunk.
static func chunk_lambda_range(l_center: Vector3, pole_local: Vector3, radius: float, cos_ang: float, sin_ang: float) -> Vector2:
	var dot_p = clampf(l_center.dot(pole_local), -1.0, 1.0)
	var sin_theta = sqrt(maxf(0.0, 1.0 - dot_p * dot_p))
	var cos_t_min = 1.0 if dot_p >= cos_ang else minf(1.0, dot_p * cos_ang + sin_theta * sin_ang)
	var cos_t_max = -1.0 if dot_p <= -cos_ang else maxf(-1.0, dot_p * cos_ang - sin_theta * sin_ang)
	var r_safe = maxf(radius, 1e-5)
	var max_lam = 1.0 / (r_safe * maxf(1.0 - cos_t_min, 1e-5))
	var min_lam = 1.0 / (r_safe * maxf(1.0 - cos_t_max, 1e-5))
	return Vector2(min_lam, max_lam)

