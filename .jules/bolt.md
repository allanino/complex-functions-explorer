## 2024-06-01 - [Object Pooling for Chunks]
**Learning:** Frequent instantiating and queue_freeing of nodes like terrain chunks cause GC pressure and frame stuttering.
**Action:** Use an Array as an Object Pool, setting process_mode = Node.PROCESS_MODE_DISABLED and visible = false when returning to the pool, and returning them to PROCESS_MODE_INHERIT when popped out. Cast to exact types like `as MeshInstance3D` to satisfy strict typing.
