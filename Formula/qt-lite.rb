class QtLite < Formula

  desc "Cross-platform application and UI framework"
  homepage "https://www.qt.io/"
  url "https://download.qt.io/official_releases/qt/6.2/6.2.4/single/qt-everywhere-src-6.2.4.tar.xz"
  sha256 "cfe41905b6bde3712c65b102ea3d46fc80a44c9d1487669f14e4a6ee82ebb8fd"
  license all_of: ["GFDL-1.3-only", "GPL-2.0-only", "GPL-3.0-only", "LGPL-2.1-only", "LGPL-3.0-only"]
  head "https://code.qt.io/qt/qt5.git", branch: "dev", shallow: false

  bottle do
    rebuild 1
    root_url "https://github.com/coslyk/homebrew-qtlite/releases/download/continuous"
    sha256 cellar: :any, big_sur: "44988a33ffcbba21d75f8db4e404189fb236e8737fc787d0fd9633868b8cd8d0"
    sha256 cellar: :any, catalina: "becf1c043364a9dba8144bc2dd12a1c62d32e27027aabc7b73f76c8399e01fc1"
  end

  keg_only "This Qt build is only used for my projects"
   
  depends_on "cmake" => [:build, :test]
  depends_on "ninja" => :build
  depends_on "pkg-config" => :build
  depends_on xcode: :build

  depends_on "brotli"
  depends_on "double-conversion"
  depends_on "freetype"
  depends_on "icu4c"
  depends_on "jpeg"
  depends_on "libb2"
  depends_on "libproxy"
  depends_on "pcre2"
  depends_on "python@3.9"
  depends_on "zstd"

  uses_from_macos "bison" => :build
  uses_from_macos "flex"  => :build
  uses_from_macos "gperf" => :build
  uses_from_macos "perl"  => :build

  uses_from_macos "krb5"
  uses_from_macos "perl"
  uses_from_macos "sqlite"
  uses_from_macos "zlib"
  
  # Remove symlink check causing build to bail out and fail.
  # https://gitlab.kitware.com/cmake/cmake/-/issues/23251
  patch do
    url "https://raw.githubusercontent.com/Homebrew/formula-patches/c363f0edf9e90598d54bc3f4f1bacf95abbda282/qt/qt_internal_check_if_path_has_symlinks.patch"
    sha256 "1afd8bf3299949b2717265228ca953d8d9e4201ddb547f43ed84ac0d7da7a135"
    directory "qtbase"
  end
  
  def install
    inreplace "qtdeclarative/src/CMakeLists.txt", "add_subdirectory(quickcontrolstestutils)", ""
    inreplace "qtdeclarative/src/CMakeLists.txt", "add_subdirectory(qmltest)", ""
    inreplace "qtdeclarative/src/CMakeLists.txt", "add_subdirectory(quicktestutils)", ""
    
    config_args = %W[
      -release

      -prefix #{HOMEBREW_PREFIX}
      -extprefix #{prefix}
      -libexecdir bin

      -skip qt3d
      -skip qt5compat
      -skip qtactiveqt
      -skip qtcharts
      -skip qtcoap
      -skip qtconnectivity
      -skip qtdatavis3d
      -skip qtdoc
      -skip qtlottie
      -skip qtmultimedia
      -skip qtmqtt
      -skip qtnetworkauth
      -skip qtopcua
      -skip qtpositioning
      -skip qtquick3d
      -skip qtquicktimeline
      -skip qtremoteobjects
      -skip qtscxml
      -skip qtsensors
      -skip qtserialbus
      -skip qtserialport
      -skip qtvirtualkeyboard
      -skip qtwayland
      -skip qtwebchannel
      -skip qtwebengine
      -skip qtwebsockets
      -skip qtwebview

      -libproxy
      -no-dbus
      -no-directfb
      -no-cups
      -no-eglfs
      -no-evdev
      -no-eventfd
      -no-journald
      -no-glib
      -no-gtk
      -no-inotify
      -no-mtdev
      -no-pch
      -no-sctp
      -no-securetransport
      -no-syslog
      -no-tslib
      -no-widgets
      -no-feature-rpath
      -no-feature-relocatable
      -no-feature-concurrent
      -no-feature-libudev
      -no-feature-sql
      -no-feature-eglfs
      -no-feature-pdf
      -no-feature-textodfwriter
      -no-feature-vnc
      -no-feature-whatsthis
      -no-feature-gssapi
      -no-feature-printer
      -no-feature-qml-network
      -no-feature-qml-preview
      -no-feature-quick-animatedimage
      -no-feature-quick-canvas
      -no-feature-quick-designer
      -no-feature-distancefieldgenerator
      -no-feature-kmap2qmap
      -no-feature-pixeltool
      -no-feature-qdbus
      -no-feature-qev
      -no-feature-qtattributionsscanner
      -no-feature-qtdiag
      -no-gif
      -no-ico
      -qt-libpng
      -system-sqlite
      -nomake examples
      -nomake tests
    ]

    config_args << "-sysroot" << MacOS.sdk_path.to_s if OS.mac?

    cmake_args = std_cmake_args(install_prefix: HOMEBREW_PREFIX, find_framework: "FIRST") + %W[
      -DCMAKE_OSX_DEPLOYMENT_TARGET=#{MacOS.version}
      -DINSTALL_MKSPECSDIR=share/qt/mkspecs
      -DFEATURE_pkg_config=ON
      -DQT_FEATURE_avx2=OFF
    ]


    system "./configure", *config_args, "--", *cmake_args
    system "cmake", "--build", "."
    system "cmake", "--install", "."

    rm bin/"qt-cmake-private-install.cmake"

    inreplace lib/"cmake/Qt6/qt.toolchain.cmake", Superenv.shims_path, ""

    # The pkg-config files installed suggest that headers can be found in the
    # `include` directory. Make this so by creating symlinks from `include` to
    # the Frameworks' Headers folders.
    # Tracking issues:
    # https://bugreports.qt.io/browse/QTBUG-86080
    # https://gitlab.kitware.com/cmake/cmake/-/merge_requests/6363
    lib.glob("*.framework") do |f|
      # Some config scripts will only find Qt in a "Frameworks" folder
      frameworks.install_symlink f
      include.install_symlink f/"Headers" => f.stem
    end

    if OS.mac?
      bin.glob("*.app") do |app|
        libexec.install app
        bin.write_exec_script libexec/app.basename/"Contents/MacOS"/app.stem
      end
    end
  end
end
