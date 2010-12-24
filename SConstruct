import os

env = DefaultEnvironment(tools=['dmd', 'link', 'gcc', 'ar'])

if ARGUMENTS.get('release', ''):
    _build_style='release'
    _dflags = ['-O', '-release', '-inline', '-gc']
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

_d_link_flags=['-lphobos2', '-lpthread', '-lm']

if ARGUMENTS.get('m64', ''):
   _dflags.append('-m64')
   _link_flags = ['-m64']
else:
   _dflags.append('-m32')
   _link_flags = ['-m32']

env.Append(DFLAGS=_dflags, LINKFLAGS=_link_flags,
           DLINKFLAGS=_d_link_flags, BUILD_STYLE=_build_style)

qcheck_lib = env.SConscript('src/quickcheck/SConscript', duplicate=0,
                          exports='env',
                          variant_dir='build/quickcheck/'+_build_style)

env.SConscript('test/SConscript', duplicate=0,
               exports='env qcheck_lib',
               variant_dir='build/test/'+_build_style)
