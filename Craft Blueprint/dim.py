# SPDX-License-Identifier: BSD-2-Clause
# SPDX-FileCopyrightText: 2024 Your Name <your.email@example.com>

import info
from Package.CMakePackageBase import *


class subinfo(info.infoclass):
    def setTargets(self):
        # Set the git URL to your application's repository
        self.svnTargets["master"] = "https://github.com/Darevox/DGestdesktop.git|main"
        self.displayName = "DIM"
        self.description = "DIM inventory management and point of sale software"
        self.defaultTarget = "master"

    def setDependencies(self):
        self.runtimeDependencies["libs/qt/qtbase"] = None
        self.runtimeDependencies["libs/qt/qtdeclarative"] = None
        self.runtimeDependencies["kde/frameworks/tier1/prison"] = None
        self.runtimeDependencies["kde/frameworks/tier1/kirigami"] = None
        self.runtimeDependencies["kde/frameworks/tier1/kquickcharts"] = None
        self.runtimeDependencies["kde/frameworks/tier1/kcoreaddons"] = None
        self.runtimeDependencies["kde/frameworks/tier1/ki18n"] = None
        self.runtimeDependencies["kde/frameworks/tier2/kstatusnotifieritem"] = None
        self.runtimeDependencies["kde/libs/kquickimageeditor"] = None
        self.runtimeDependencies["kde/frameworks/tier2/kcolorscheme"] = None
        self.runtimeDependencies["kde/unreleased/kirigami-addons"] = None
        self.runtimeDependencies["kde/frameworks/tier3/kiconthemes"] = None
        self.runtimeDependencies["qt-libs/poppler"] = None
        if not CraftCore.compiler.isAndroid:
            self.runtimeDependencies["kde/frameworks/tier1/breeze-icons"] = None
            self.runtimeDependencies["kde/frameworks/tier3/qqc2-desktop-style"] = None
            self.runtimeDependencies["kde/plasma/breeze"] = None
        else:
            self.runtimeDependencies["kde/plasma/qqc2-breeze-style"] = None



class Package(CraftPackageObject.get("kde").pattern):
    def __init__(self, **kwargs):
        super().__init__(**kwargs)

    def createPackage(self):
        # Set the executable name for your application
        self.defines["executable"] = r"bin\DGestapp.exe"
        # Add filters to exclude unnecessary executables
        self.addExecutableFilter(r"(bin|libexec)/(?!(DGestapp|update-mime-database)).*")
        # Ignore unnecessary packages
        self.ignoredPackages.append("binary/mysql")
        if not CraftCore.compiler.isLinux:
            self.ignoredPackages.append("libs/dbus")
        return super().createPackage()
