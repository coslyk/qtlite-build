class QtLite < Formula
  desc "Cross-platform application and UI framework"
  homepage "https://www.qt.io/"
  url "https://download.qt.io/official_releases/qt/6.0/6.0.2/single/qt-everywhere-src-6.0.2.tar.xz"
  sha256 "67a076640647783b95a907d2231e4f34cec69be5ed338c1c1b33124cadf10bdf"
  license all_of: ["GFDL-1.3-only", "GPL-2.0-only", "GPL-3.0-only", "LGPL-2.1-only", "LGPL-3.0-only"]
  head "https://code.qt.io/qt/qt5.git", branch: "dev", shallow: false

  keg_only "This Qt build is only used for my projects"

  depends_on "cmake" => [:build, :test]
  depends_on "ninja" => :build
  depends_on "pkg-config" => :build
  depends_on xcode: :build

  depends_on "double-conversion"
  depends_on "freetype"
  depends_on "glib"
  depends_on "icu4c"
  depends_on "jasper"
  depends_on "jpeg"
  depends_on "libb2"
  depends_on "libpng"
  depends_on "libproxy"
  depends_on "libtiff"
  depends_on "pcre2"
  depends_on "python@3.9"
  depends_on "webp"
  depends_on "zstd"

  uses_from_macos "krb5"
  uses_from_macos "perl"
  uses_from_macos "sqlite"
  uses_from_macos "zlib"

  resource "qtimageformats" do
    url "https://download.qt.io/official_releases/additional_libraries/6.0/6.0.2/qtimageformats-everywhere-src-6.0.2.tar.xz"
    sha256 "b0379ba6bbefbc48ed3ef8a1d8812531bd671362f74e0cffa6adf67bb1139206"
  end

  def install
    resources.each { |addition| addition.stage buildpath/addition.name }

    config_args = %W[
      -release

      -prefix #{HOMEBREW_PREFIX}
      -extprefix #{prefix}

      -libexecdir share/qt/libexec
      -plugindir share/qt/plugins
      -qmldir share/qt/qml
      -docdir share/doc/qt
      -translationdir share/qt/translations
      -examplesdir share/qt/examples
      -testsdir share/qt/tests

      -skip qt5compat
      -skip qtdoc
      -skip qtquick3d
      -skip qtquicktimeline
      -skip qtshadertools
      -skip qtsvg

      -libproxy
      -no-feature-relocatable
      -no-feature-concurrent
      -no-feature-dbus
      -no-feature-libudev
      -no-feature-sql
      -no-feature-testlib
      -no-feature-widgets
      -no-feature-xml
      -no-feature-accessibility
      -no-feature-eglfs
      -no-feature-gif
      -no-feature-mtdev
      -no-feature-pdf
      -no-feature-textmarkdownreader
      -no-feature-textmarkdownwriter
      -no-feature-textodfwriter
      -no-feature-vnc
      -no-feature-whatsthis
      -no-feature-gssapi
      -no-feature-cups
      -no-feature-printer
      -no-feature-qml-network
      -no-feature-qml-debug
      -no-feature-qml-profiler
      -no-feature-qml-preview
      -no-feature-quick-canvas
      -no-feature-quick-designer
      -no-feature-assistant
      -no-feature-designer
      -no-feature-distancefieldgenerator
      -no-feature-kmap2qmap
      -no-feature-pixeltool
      -no-feature-qdbus
      -no-feature-qtattributionsscanner
      -no-feature-qtdiag
      -system-sqlite
    ]

    cmake_args = std_cmake_args.reject { |s| s["CMAKE_INSTALL_PREFIX"]||s["CMAKE_FIND_FRAMEWORK"] } + %W[
      -DICU_ROOT=#{Formula["icu4c"].opt_prefix}

      -DCMAKE_OSX_DEPLOYMENT_TARGET=#{MacOS.version}
      -DCMAKE_FIND_FRAMEWORK=FIRST

      -DINSTALL_MKSPECSDIR=share/qt/mkspecs
      -DINSTALL_DESCRIPTIONSDIR=share/qt/modules

      -DFEATURE_pkg_config=ON
    ]

    system "./configure", *config_args, "--", *cmake_args
    system "ninja"
    system "ninja", "install"

    rm bin/"qt-cmake-private-install.cmake"

    # Some config scripts will only find Qt in a "Frameworks" folder
    frameworks.install_symlink Dir["#{lib}/*.framework"]

    inreplace lib/"cmake/Qt6/qt.toolchain.cmake", /.*set.__qt_initial_.*/, ""

    # The pkg-config files installed suggest that headers can be found in the
    # `include` directory. Make this so by creating symlinks from `include` to
    # the Frameworks' Headers folders.
    Pathname.glob("#{lib}/*.framework/Headers") do |path|
      include.install_symlink path => path.parent.basename(".framework")
    end

    mkdir libexec
    Pathname.glob("#{bin}/*.app") do |app|
      mv app, libexec
      bin.write_exec_script "#{libexec/app.stem}.app/Contents/MacOS/#{app.stem}"
    end
  end
end
