import os
from conan import ConanFile
from conan.errors import ConanInvalidConfiguration
from conan.tools.apple import XcodeBuild
from conan.tools.files import get, copy


class SchemeXcodeBuild(XcodeBuild):
    """XcodeBuild hack that passes -scheme alongside -target.

    A bare -target build does not resolve the target's dependencies, so we want
    -scheme too. But xcodebuild rejects a -scheme that follows a KEY=VALUE
    build-setting token ("You cannot specify both a scheme and targets"). -target
    and -scheme together are fine. The base build() hard-appends
    MACOSX_DEPLOYMENT_TARGET=... before cli_args, so a -scheme routed through cli_args
    always lands after that token and fails. Instead we fold -scheme into the target
    value: the base wraps it as `-target '{}'`, which expands to
    `-target 'X' -scheme 'X'`, placing the scheme before the deployment-target
    override while reusing all of super()'s command assembly.
    """

    def build(self, xcodeproj, target=None, configuration=None, cli_args=None):
        scheme_target = "{0}' -scheme '{0}".format(target)
        return super().build(xcodeproj, target=scheme_target,
                             configuration=configuration, cli_args=cli_args)


class SparkleConan(ConanFile):
    name = "sparkle"
    user = "local"
    description = "Sparkle is a software update framework for macOS applications."
    license = "MIT"
    url = "https://sparkle-project.org/"
    homepage = "https://github.com/sparkle-project/Sparkle"
    topics = ("macos", "autoupdate", "framework")
    package_type = "shared-library"

    settings = "os", "arch", "build_type"

    @property
    def _configuration(self):
        # Sparkle's Xcode project only provides Debug and Release configurations,
        # so map any other build type like RelWithDebInfo to Release.
        return "Debug" if self.settings.build_type == "Debug" else "Release"

    def validate(self):
        if self.settings.os != "Macos":
            raise ConanInvalidConfiguration("Sparkle is only available on macOS")

    def source(self):
        get(self,
            **self.conan_data["sources"][self.version],
            destination=self.source_folder,
            strip_root=True)

    def build(self):
        # sparkle-cli produces Sparkle.framework + sparkle.app. generate_appcast is a separate standalone tool.
        xcodebuild = SchemeXcodeBuild(self)
        xcodeproj = os.path.join(self.source_folder, "Sparkle.xcodeproj")
        for target in ("sparkle-cli", "generate_appcast"):
            xcodebuild.build(xcodeproj, target=target,
                             configuration=self._configuration,
                             cli_args=[f"SYMROOT={self.build_folder}"])

    def package(self):
        products_dir = os.path.join(self.build_folder, self._configuration)
        copy(self, "Sparkle.framework/**", src=products_dir, dst=self.package_folder)
        copy(self, "sparkle.app/**", src=products_dir, dst=self.package_folder)
        # generate_appcast is a standalone CI tool; place it under bin/ to match the
        # conventional Sparkle distribution layout ($SPARKLE_DIR/bin/generate_appcast).
        copy(self, "generate_appcast", src=products_dir,
             dst=os.path.join(self.package_folder, "bin"))

    def package_info(self):
        self.cpp_info.set_property("cmake_file_name", "Sparkle")
        self.cpp_info.set_property("cmake_target_name", "Sparkle::Sparkle")
        self.cpp_info.set_property("cmake_find_mode", "config")
        self.cpp_info.includedirs = []  # headers live inside Sparkle.framework, not a separate include/
        self.cpp_info.libdirs = []
        self.cpp_info.bindirs = ["bin"]  # exposes generate_appcast on the run environment PATH
        self.cpp_info.frameworkdirs = [self.package_folder]
        self.cpp_info.frameworks = ["Sparkle"]
