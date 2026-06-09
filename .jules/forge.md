2025-02-24 - Extracting Repeated String Parsing Logic

Learning: Extracting repeated string parsing logic into unified helper functions improves maintainability and prevents duplication, particularly for UI input handling like rational expressions.

Action: Whenever identical string manipulation blocks exist across multiple UI callbacks, create a private helper function to encapsulate the logic and return the parsed data in an organized structure (like an Array or Dictionary).
