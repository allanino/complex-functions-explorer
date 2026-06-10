import subprocess
import re

def main():
    try:
        # Run tests directly in headless mode
        result = subprocess.run(
            ["godot", "--headless", "-s", "addons/gut/gut_cmdln.gd", "-gdir=res://tests", "-ginclude_subdirs", "-gexit"],
            capture_output=True,
            text=True
        )
        print("STDOUT:")
        print(result.stdout)
        print("STDERR:")
        print(result.stderr)
    except FileNotFoundError:
        print("godot command not found")

if __name__ == '__main__':
    main()
