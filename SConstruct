#!/usr/bin/env python

from SCons.Script import *

env = SConscript("godot-cpp/SConstruct")

env.Append(CPPPATH=["math/cpp"])

sources = Glob("math/cpp/*.cpp")

if env["platform"] == "macos":
    library = env.SharedLibrary(
        "bin/libcomplex_functions{}.framework/libcomplex_functions{}".format(
            env["suffix"],
            env["suffix"],
        ),
        source=sources,
    )
else:
    library = env.SharedLibrary(
        "bin/libcomplex_functions{}{}".format(
            env["suffix"],
            env["SHLIBSUFFIX"],
        ),
        source=sources,
    )

Default(library)