import os
from conan import ConanFile
from conan.errors import ConanInvalidConfiguration
from conan.tools.apple import to_apple_arch
from conan.tools.files import get, copy


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
        # Cant use XcodeBuild as it unconditionally adds -alltargets which conflicts with -scheme.
        # So we use self.run() directly; to_apple_arch()
        arch = to_apple_arch(self)
        cmd = (f"xcodebuild -project Sparkle.xcodeproj"
               f" -scheme sparkle-cli"
               f" -configuration {self._configuration}"
               f" -arch {arch}"
               f" SYMROOT={self.build_folder}")
        self.run(cmd, cwd=self.source_folder)

    def package(self):
        products_dir = os.path.join(self.build_folder, self._configuration)
        copy(self, "Sparkle.framework/**", src=products_dir, dst=self.package_folder)
        copy(self, "sparkle.app/**", src=products_dir, dst=self.package_folder)

    def package_info(self):
        self.cpp_info.set_property("cmake_file_name", "Sparkle")
        self.cpp_info.set_property("cmake_target_name", "Sparkle::Sparkle")
        self.cpp_info.set_property("cmake_find_mode", "config")
        self.cpp_info.includedirs = []  # headers live inside Sparkle.framework, not a separate include/
        self.cpp_info.libdirs = []
        self.cpp_info.bindirs = []
        self.cpp_info.frameworkdirs = [self.package_folder]
        self.cpp_info.frameworks = ["Sparkle"]
