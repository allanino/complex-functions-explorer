2025-02-24 - Extracting Repeated String Parsing Logic

Learning: Extracting repeated string parsing logic into unified helper functions improves maintainability and prevents duplication, particularly for UI input handling like rational expressions.

Action: Whenever identical string manipulation blocks exist across multiple UI callbacks, create a private helper function to encapsulate the logic and return the parsed data in an organized structure (like an Array or Dictionary).
2025-02-24 - Excessive defensive programming in UI scripts

Learning: Removing redundant `get_node_or_null` lookups and corresponding `if` conditions for statically defined scene nodes cleans up logic branches and improves clarity. Nodes cached via `@onready` or unique scene names (`%NodeName`) are guaranteed to exist, rendering runtime existence checks unnecessary.

Action: Always prefer `@onready var` to cache UI elements and remove defensive null checks for static nodes that are confirmed to exist within the scene hierarchy.
2025-02-25 - Removing defensive `if` node existence checks while preserving `get_node_or_null` for test injection

Learning: While defensive `if node:` existence checks can be safely removed for static nodes guaranteed to be ready, the initial `get_node_or_null` must sometimes be preserved (instead of `get_node` or `%`) if unit tests manually instantiate and inject these nodes into the scene tree out-of-order. This prevents strict paths from crashing during test execution.

Action: Remove redundant `if` checks for statically defined components before accessing their methods, but check test instantiation patterns before strictly enforcing `get_node()` over `get_node_or_null()`.

## 4 - [Extracting duplicated Callable variables into local closures]
Learning: Massive dictionaries config (like UI bindings) often repeat anonymous Lambda closures identically, leading to bloated files and harder updates.
Action: Extract identically defined `func(x): return ...` patterns into locally scoped `var` properties (e.g. `var to_pct = func(v): return v / 100.0`) and reference those variables instead to reduce size and improve consistency.
