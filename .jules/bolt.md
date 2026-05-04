## 2024-05-04 - Asynchronous File I/O in FastAPI
**Learning:** In FastAPI async endpoints, using synchronous Python file I/O operations (like `open()`, `json.load()`, `json.dump()`) can block the main thread and severely hinder throughput when under load.
**Action:** When handling I/O operations inside `async def` routes, we should always use non-blocking counterparts, such as `aiofiles` and combined with `await f.read()`/`await f.write()` instead of standard context managers.
