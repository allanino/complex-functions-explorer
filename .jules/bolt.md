## 2024-05-29 - [Optimize Node Lookups in Hot Paths]
**Learning:** Redundant string-based node lookups (`get_node_or_null()`, `$NodeName`) inside high-frequency engine callbacks like `_process` and `_physics_process` create unnecessary CPU overhead.
**Action:** Always cache these node references using `@onready` variables or cache them upon initialization to eliminate per-frame string-based node search overhead.
