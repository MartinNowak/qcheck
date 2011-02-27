#! /usr/bin/env python
# encoding: utf-8

VERSION='0.1'
APPNAME='qcheck'

top = '.'
out = 'build'


def options(opt):
	opt.load('compiler_d')

def configure(conf):
        conf.setenv('debug')
        conf.env.DFLAGS = ['-debug', '-gc', '-unittest', '-m64']
	conf.load('compiler_d')
	conf.env.LINKFLAGS = ['-m64']
        conf.check(features='d dprogram', fragment='void main() {}', compile_filename='test.d')


        conf.setenv('release')
        conf.env.DFLAGS = ['-release', '-O', '-inline', '-nofloat', '-m64']
	conf.load('compiler_d')
	conf.env.LINKFLAGS = ['-m64']
        conf.check(features='d dprogram', fragment='void main() {}', compile_filename='test.d')

def build(bld):
        if not bld.variant:
                bld.fatal('call "waf build_debug" or "waf build_release", and try "waf --help"')

        bld.stlib(
                source = bld.path.ant_glob('src/qcheck/**/*d'),
                target = 'qcheck',
                includes = 'src',
                generate_headers=True)

        if bld.variant == 'debug':
                bld.program(
                        source = bld.path.ant_glob('test/**/*d'),
                        target = 'testqcheck',
                        use = 'qcheck',
                        includes = 'src')

from waflib.Build import BuildContext, CleanContext, \
        InstallContext, UninstallContext

for x in 'debug release'.split():
        for y in (BuildContext, CleanContext, InstallContext, UninstallContext):
                name = y.__name__.replace('Context','').lower()
                class tmp(y):
                        cmd = name + '_' + x
                        variant = x
