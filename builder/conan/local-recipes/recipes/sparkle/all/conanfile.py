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

    # build_type and compiler are irrelevant — xcodebuild uses its own Release config.
    # The package hash varies only by architecture, so one build serves Debug and Release.
    settings = "os", "arch"

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
        # Products land at ${SYMROOT}/Release/ (EFFECTIVE_PLATFORM_NAME is empty on macOS).
        arch = to_apple_arch(self)
        cmd = (f"xcodebuild -project Sparkle.xcodeproj"
               f" -scheme sparkle-cli"
               f" -configuration Release"
               f" -arch {arch}"
               f" SYMROOT={self.build_folder}")
        self.run(cmd, cwd=self.source_folder)

    def package(self):
        products_dir = os.path.join(self.build_folder, "Release")
        # Sparkle.framework and sparkle.app land as siblings in products_dir.
        # cli/CMakeLists.txt expects both as siblings in the same directory.
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
        # -F is needed at compile time (not just link time) for #import <Sparkle/Sparkle.h>
        self.cpp_info.cxxflags = [f"-F{self.package_folder}"]
        self.cpp_info.cflags = [f"-F{self.package_folder}"]
