a = {
    "size": "(1920, 1080)",
    "scale": 1.0,
    "visibility": [True, True, True, False, False, False],
    "heights": [240, 300, 150, 0, 0, 0],
    "available_height": 1000
}
b = {
    "size": "(1920, 1080)",
    "scale": 1.0,
    "visibility": [True, True, True, False, False, False],
    "heights": [240, 300, 150, 0, 0, 0],
    "available_height": 1000
}

import json
print(hash(json.dumps(a, sort_keys=True)) == hash(json.dumps(b, sort_keys=True)))
