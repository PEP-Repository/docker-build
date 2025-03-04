import os.path
from pathlib import Path

from conan import ConanFile
from conan.errors import ConanInvalidConfiguration
from conan.tools.cmake import CMake, CMakeDeps, CMakeToolchain, cmake_layout
from conan.tools.system.package_manager import Apt, Brew


class PepRecipe(ConanFile):
    name = 'pep'
    settings = 'os', 'compiler', 'build_type', 'arch'

    options = {
        # Build GUI (with Qt)
        'with_client': [True, False],
        'with_servers': [True, False],
        # Build pepPullCastor
        'with_castor': [True, False],
        'with_tests': [True, False],
        'with_benchmark': [True, False],
        'with_unwinder': [True, False],

        # Build dependencies as shared libraries
        'shared_libs': [True, False],
        # Setting this to False may increase the chance that prebuilt binaries are available
        'custom_dependency_opts': [True, False],
        # Setting this forces the built to be directly under --output-folder, instead of e.g. ./<output>/Debug
        'custom_build_folder': [True, False],
        'use_system_qt': [True, False],
        # e.g. use `-o subbuild_name=ppp` for separate ./build/ppp folder and ppp-debug presets and such
        'subbuild_name': ['ANY'],
        # Pass custom CMake cache variables to be put into the preset, separated with `;`
        'cmake_variables': ['ANY'],
    }
    default_options = {
        # Enable most functionality by default for a complete devbox
        'with_client': True,
        'with_servers': True,
        'with_castor': True,
        'with_tests': True,
        'with_benchmark': True,
        'with_unwinder': True,

        'shared_libs': False,
        'custom_dependency_opts': True,
        'custom_build_folder': False,
        'use_system_qt': False,
        'subbuild_name': '',
        'cmake_variables': '',
    }

    def config_options(self):
        if self.settings.os not in ['Linux', 'FreeBSD', 'Windows']:
            # See `validate` in https://github.com/conan-io/conan-center-index/blob/master/recipes/libunwind/all/conanfile.py
            del self.options.with_unwinder

        if self.settings.os == 'Linux':
            # Using Qt from Conan on Linux may give problems and is generally unnecessary
            self.options.use_system_qt = True

    def configure(self):
        if self.options.shared_libs:
            self.options['*'].shared = True

    def validate(self):
        if not self.settings.build_type:
            # See CMakeLists.txt in PEP FOSS repo for context
            raise ConanInvalidConfiguration(
                'We do not support multiconfig builds yet (see pep/core#499), '
                'please explicitly specify -s:a build_type=<...> to force consistent builds.')

    def layout(self):
        # If CMakeLists.txt is not besides conanfile.py, so we are called (without symlinks) in docker-build,
        # we use the parent directory of docker-build as project root, if a CMakeLists.txt is found there
        conanfile_dir = Path(__file__).parent
        if not conanfile_dir.joinpath('CMakeLists.txt').is_file():
            parts = conanfile_dir.parts
            if 'docker-build' in parts:
                docker_build_parent = Path(*parts[:len(parts) - list(reversed(parts)).index('docker-build') - 1])
                if docker_build_parent.joinpath('CMakeLists.txt').is_file():
                    self.folders.root = str(docker_build_parent)
                else:
                    self.output.warning(
                        "Didn't find CMakeLists.txt beside conanfile.py or in docker-build's parent dir")
            else:
                self.output.warning(
                    "Didn't find CMakeLists.txt beside conanfile.py, nor were we called in docker-build")

        subbuild = str(self.options.subbuild_name) or '.'

        if self.options.custom_build_folder:
            self.folders.build = subbuild
            self.folders.generators = os.path.join(self.folders.build, 'generators')
        else:
            cmake_layout(self, build_folder=os.path.join('build', subbuild))

        self.cpp.source.includedirs = ['cpp']

    def generate(self):
        tc = CMakeDeps(self)
        tc.generate()

        tc = CMakeToolchain(self)
        tc.variables['CMAKE_POLICY_DEFAULT_CMP0057'] = 'NEW'  # XXX Workaround for issue with Boost via apt
        # Force passing build type also in multiconfig case,
        #  see https://gitlab.pep.cs.ru.nl/pep/core/issues/499
        tc.cache_variables['CMAKE_BUILD_TYPE'] = str(self.settings.build_type)
        tc.cache_variables['BUILD_CLIENT'] = self.options.with_client
        tc.cache_variables['BUILD_SERVERS'] = self.options.with_servers
        tc.cache_variables['WITH_CASTOR'] = self.options.with_castor
        tc.cache_variables['WITH_TESTS'] = self.options.with_tests
        tc.cache_variables['WITH_BENCHMARK'] = self.options.with_benchmark
        tc.cache_variables['WITH_UNWINDER'] = self.options.get_safe('with_unwinder', False)
        for var_def in str(self.options.cmake_variables).split(';') if str(self.options.cmake_variables) else []:
            name, value = var_def.split('=')
            tc.cache_variables[name] = value
        if str(self.options.subbuild_name):
            tc.presets_prefix = str(self.options.subbuild_name)
        tc.generate()

    def build(self):
        cmake = CMake(self)
        cmake.configure()
        cmake.build()

    def requirements(self):
        if self.options.get_safe('with_unwinder', False) and self.settings.os != 'Windows':
            self.requires('libunwind/[^1.7]', options=self._optional_opts({
                'coredump': False,
                'ptrace': False,
                'setjmp': False,
                'minidebuginfo': False,
                'zlibdebuginfo': False,
            }))

        self.requires('libarchive/[^3.7]', options=self._optional_opts({
            'with_zlib': False,
            'with_iconv': False,
        }))
        self.requires('boost/[^1.83 <1.87]', options={
            # Instruct Boost that it can use std::filesystem
            'filesystem_use_std_fs': True,

            **self._optional_opts({
                'numa': False,
                'zlib': False,
                'bzip2': False,

                # 'without_atomic': True,  # Transitive (required by other Boost components)
                # 'without_chrono': True,  # Transitive
                'without_cobalt': True,
                # 'without_container': True,  # Transitive
                'without_context': True,
                'without_contract': True,
                'without_coroutine': True,
                # 'without_date_time': True,
                # 'without_exception': True,  # Transitive
                'without_fiber': True,
                # 'without_filesystem': True,  # Transitive
                'without_graph': True,
                'without_graph_parallel': True,
                # 'without_iostreams': True,
                'without_json': True,
                'without_locale': True,
                # 'without_log': True,
                'without_math': True,
                'without_mpi': True,
                'without_nowide': True,
                'without_program_options': True,
                'without_python': True,
                # 'without_random': True,
                # 'without_regex': True,  # Transitive
                'without_serialization': True,
                'without_stacktrace': True,
                # 'without_system': True,
                'without_test': True,
                # 'without_thread': True,  # Transitive
                'without_timer': True,
                'without_type_erasure': True,
                'without_url': True,
                'without_wave': True
            })})
        self.requires('civetweb/[^1.16]', options={
            'with_ssl': True,

            **self._optional_opts({
                'with_caching': False,
                'with_cgi': False,
                'with_static_files': False,
                'with_websockets': False,
            })})
        self.requires('inja/[^3.4]')
        self.requires('openssl/[^3.2]', options=self._optional_opts({
            # Deprecated features are needed by Qt (otherwise linker error _SSL_CTX_use_RSAPrivateKey)
            # 'no_deprecated': True,
            'no_legacy': True,
            'no_md4': True,
            'no_rc2': True,
            'no_rc4': True,
            'no_ssl3': True,
        }))
        self.requires('prometheus-cpp/[^1.1]', options=self._optional_opts({
            'with_pull': False,
        }))
        self.requires('protobuf/[^3.21]')
        self.requires('sqlite_orm/[~1.8 || ^1.9.1]') # Exclude 1.9, because of https://github.com/fnc12/sqlite_orm/issues/1346
        self.requires('xxhash/[^0.8.2]', options=self._optional_opts({
            'utility': False,
        }))

        if self.options.with_client and not self.options.use_system_qt:
            self.requires('qt/[^6.6]', options={
                'essential_modules': False,
                'qtsvg': True,
                'qttranslations': True,

                # Workaround for https://github.com/conan-io/conan-center-index/pull/21535
                **({'with_harfbuzz': False} if self.settings.os == 'Macos' else {}),
                **self._optional_opts({
                    'with_sqlite3': False,
                    'with_pq': False,
                    'with_odbc': False,
                    'with_brotli': False,
                    'with_openal': False,
                    'with_md4c': False,
                })})

        # XXX Remove when std timezones are widely supported
        if self.options.with_castor:
            # Use system timezone database where possible, auto-download to ~/Downloads on Windows
            self.requires('date/[^3.0]', options={} if self.settings.os == 'Windows' else {'use_system_tz_db': True})

        if self.options.with_tests:
            self.requires('gtest/[^1.14]')
        if self.options.with_benchmark:
            self.requires('benchmark/[^1.8]')

    def build_requirements(self):
        # Add these to PATH
        self.tool_requires('protobuf/<host_version>')  # protoc
        if self.options.with_client and not self.options.use_system_qt:
            # XXX windeployqt is referencing the wrong DLLs (build instead of runtime),
            #  so we list them here as well.
            #  See https://github.com/conan-io/conan-center-index/issues/22693
            # Also, for windeployqt we build shared via our conan_profile file
            self.tool_requires('qt/<host_version>', options={
                'essential_modules': False,
                'qtsvg': True,
                'qttranslations': True,

                'qttools': True,  # e.g. windeployqt

                **({'with_harfbuzz': False} if self.settings.os == 'Macos' else {}),
                **self._optional_opts({
                    'with_sqlite3': False,
                    'with_pq': False,
                    'with_odbc': False,
                    'with_brotli': False,
                    'with_openal': False,
                    'with_md4c': False,
                })})

    def system_requirements(self):
        apt = Apt(self)
        brew = Brew(self)

        if self.options.with_client and self.options.use_system_qt:
            apt.install([
                'qt6-base-dev',
                'qt6-tools-dev',
                'qt6-tools-dev-tools',
            ])
            apt.install_substitutes([
                # e.g. Ubuntu >=23
                'qt6-svg-dev',
            ], [
                # e.g. Ubuntu <23
                'libqt6svg6-dev',
                'qt6-l10n-tools',
            ])

            brew.install(['qt@6'])

    def _optional_opts(self, opts: dict) -> dict:
        """Options that are not required but strip down packages to our needs"""
        return opts if self.options.custom_dependency_opts else {}
