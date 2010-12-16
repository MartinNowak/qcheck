import os

path = ['D:\\Code\\D\\dmd_git\\install\\bin']

env = DefaultEnvironment(tools = ['dmd', 'link'], ENV={'PATH':path})

if ARGUMENTS.get('release', ''):
    _build_style='release'
    _dflags = ['-O', '-release', '-inline']
else:
    _build_style='debug'
    _dflags=['-debug', '-unittest', '-gc']

_version_flags=ARGUMENTS.get('version', '')
if _version_flags:
   for flag in _version_flags.split(','):
       _dflags.append('-version=' + flag)

if ARGUMENTS.get('profile', ''):
   _dflags.append('-profile')

if ARGUMENTS.get('cov', ''):
   _dflags.append('-cov')

env.Append(DFLAGS=_dflags)
env.Append(BUILD_STYLE=_build_style)

qcheck_lib = env.SConscript('src/quickcheck/SConscript', duplicate=0,
                          exports='env',
                          variant_dir='build/quickcheck/'+_build_style)

env.SConscript('test/SConscript', duplicate=0,
               exports='env qcheck_lib',
               variant_dir='build/test/'+_build_style)
