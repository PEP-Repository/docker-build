from conan import ConanFile
from conan.tools.cmake import CMake, CMakeDeps, CMakeToolchain, cmake_layout
from conan.tools.system.package_manager import Apt


class CompressorRecipe(ConanFile):
    name = 'pep'
    settings = 'os', 'compiler', 'build_type', 'arch'

    options = {
        'with_client': [True, False],
        'with_tests': [True, False],
        'with_benchmark': [True, False],
        'with_unwinder': [True, False],
        'shared_libs': [True, False],
        'custom_dependency_opts': [True, False],
        'custom_build_folder': [True, False],
        'use_system_qt': [True, False],
    }
    default_options = {
        'with_client': True,
        'with_tests': False,
        'with_benchmark': False,
        'with_unwinder': True,
        'shared_libs': False,
        'custom_dependency_opts': False,
        'custom_build_folder': False,
        'use_system_qt': False,
    }

    def config_options(self):
        if self.settings.os not in ['Linux', 'FreeBSD']:
            del self.options.with_unwinder

        if self.settings.os not in ['Windows', 'Darwin']:
            self.options.with_client = False
        if self.settings.os == 'Linux':
            self.options.use_system_qt = True

    def configure(self):
        if self.options.shared_libs:
            self.options['*'].shared = True

    def layout(self):
        if self.options.custom_build_folder:
            self.folders.build = './'
            self.folders.generators = './generators/'
        else:
            cmake_layout(self)
        self.cpp.source.includedirs = ['./cpp/']

    def generate(self):
        tc = CMakeDeps(self)
        tc.generate()

        tc = CMakeToolchain(self)
        tc.variables['CMAKE_POLICY_DEFAULT_CMP0057'] = 'NEW'  # XXX Workaround for issue with Boost via apt
        tc.cache_variables['WITH_TESTS'] = self.options.with_tests
        tc.cache_variables['WITH_BENCHMARK'] = self.options.with_benchmark
        tc.cache_variables['WITH_UNWINDER'] = self.options.get_safe('with_unwinder', False)
        tc.cache_variables['BUILD_CLIENT'] = self.options.with_client
        tc.generate()

    def build(self):
        cmake = CMake(self)
        cmake.configure()
        cmake.build()

    def requirements(self):
        def custom_opts(opts: dict) -> dict:
            return opts if self.options.custom_dependency_opts else {}

        if self.options.get_safe('with_unwinder', False) and self.settings.os != 'Windows':
            self.requires('libunwind/[^1.7]', options=custom_opts({
                'coredump': False,
                'ptrace': False,
                'setjmp': False,
                'minidebuginfo': False,
                'zlibdebuginfo': False,
            }))

        self.requires('libarchive/[^3.7]', options=custom_opts({
            'with_zlib': False,
            'with_iconv': False,
        }))
        self.requires('boost/[^1.83]', options=custom_opts({
            # Workaround for https://github.com/conan-io/conan-center-index/issues/22619
            'extra_b2_flags': ' '.join(f'define={d}' for d in self.conf.get('tools.build:defines', [])) or None,

            #TODO
            # 'asio_no_deprecated': True,
            # 'filesystem_no_deprecated': True,
            # 'system_no_deprecated': True,

            'numa': False,
            'zlib': False,
            'bzip2': False,
            #TODO? (Unsupported on Windows)
            # 'with_stacktrace_backtrace': False,

            # 'without_atomic': True,  # Transitive (required by other Boost components)
            # 'without_chrono': True,  # Transitive
            # 'without_container': True,  # Transitive
            'without_context': True,
            'without_contract': True,
            'without_coroutine': True,
            # 'without_date_time': True,
            # 'without_exception': True,  # Transitive
            'without_fiber': True,
            # 'without_filesystem': True,
            'without_graph': True,
            # 'without_iostreams': True,
            'without_json': True,
            'without_locale': True,
            # 'without_log': True,
            'without_math': True,
            'without_nowide': True,
            'without_program_options': True,
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
            'without_wave': True,
        }))
        self.requires('civetweb/[^1.16]', options=custom_opts({
            'with_caching': False,
            'with_cgi': False,
            'with_ssl': False,
            'with_static_files': False,
            'with_websockets': False,
        }))
        self.requires('date/[^3.0]')
        self.requires('mbedtls/[^2.28]', options=custom_opts({
            'with_zlib': False,
        }))
        self.requires('openssl/[^3.2]', options=custom_opts({
            # 'no_deprecated': True,  # Needed by Qt (otherwise linker error _SSL_CTX_use_RSAPrivateKey)
            'no_legacy': True,
            'no_md4': True,
            'no_rc2': True,
            'no_rc4': True,
            'no_ssl3': True,
        }))
        self.requires('prometheus-cpp/[^1.1]', options=custom_opts({
            'with_pull': False,
        }))
        self.requires('protobuf/[^3.21]')
        self.requires('sqlite_orm/[^1.8]')
        self.requires('xxhash/[^0.8.2]', options=custom_opts({
            'utility': False,
        }))

        if self.options.with_client and not self.options.use_system_qt:
            self.requires('qt/[^6.6]', options={**{
                'qtnetworkauth': True,
                'qtsvg': True,
                'qttranslations': True,
            }, **custom_opts({
                'with_sqlite3': False,
                'with_pq': False,
                'with_odbc': False,
                'with_brotli': False,
                'with_openal': False,
                'with_md4c': False,
            })})

        if self.options.with_tests:
            self.requires('gtest/[^1.14]')
        if self.options.with_benchmark:
            self.requires('benchmark/[^1.8]')

    def build_requirements(self):
        # Add these to PATH
        self.tool_requires('protobuf/<host_version>')  # protoc
        if self.options.with_client and not self.options.use_system_qt:
            self.tool_requires('qt/<host_version>', options={
                #XXX I feel like windeployqt is referencing the wrong DLLs;
                #  why would I need to list them here?
                #  See https://github.com/conan-io/conan-center-index/issues/22693
                'qtnetworkauth': True,
                'qtsvg': True,
                'qttranslations': True,
                'qttools': True,
            })  # e.g. windeployqt

    def system_requirements(self):
        apt = Apt(self)
        # if self.options.with_client and self.options.use_system_qt:
        #     apt.install([
        #         'qt6-base-dev',
        #         'qt6-tools-dev',
        #         'qt6-tools-dev-tools',
        #         'qt6-networkauth-dev',
        #         'qt6-svg-dev',
        #     ])
