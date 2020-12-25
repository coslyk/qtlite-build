class QtLite < Formula
  desc "Cross-platform application and UI framework"
  homepage "https://www.qt.io/"
  url "https://download.qt.io/official_releases/qt/5.15/5.15.2/single/qt-everywhere-src-5.15.2.tar.xz"
  mirror "https://mirrors.dotsrc.org/qtproject/archive/qt/5.15/5.15.2/single/qt-everywhere-src-5.15.2.tar.xz"
  mirror "https://mirrors.ocf.berkeley.edu/qt/archive/qt/5.15/5.15.2/single/qt-everywhere-src-5.15.2.tar.xz"
  sha256 "3a530d1b243b5dec00bc54937455471aaa3e56849d2593edb8ded07228202240"
  license all_of: ["GFDL-1.3-only", "GPL-2.0-only", "GPL-3.0-only", "LGPL-2.1-only", "LGPL-3.0-only"]

  keg_only "Qt 5 has CMake issues when linked"

  depends_on "pkg-config" => :build
  depends_on xcode: :build
  depends_on macos: :sierra

  uses_from_macos "bison"
  uses_from_macos "flex"
  uses_from_macos "sqlite"

  def install
    args = %W[
      -prefix #{prefix}
      -release
      -opensource -confirm-license
      -system-zlib
      -qt-libpng
      -qt-libjpeg
      -qt-freetype
      -qt-pcre
      -nomake examples
      -nomake tests
      -no-rpath
      -pkg-config
      -skip qt3d
      -skip qtcharts
      -skip qtconnectivity
      -skip qtgamepad
      -skip qtgraphicaleffects
      -skip qtimageformats
      -skip qtlocation
      -skip qtmacextras
      -skip qtmultimedia
      -skip qtnetworkauth
      -skip qtquickcontrols
      -skip qtscript
      -skip qtscxml
      -skip qtsensors
      -skip qtserialbus
      -skip qtserialport
      -skip qtspeech
      -skip qtsvg
      -skip qttranslations
      -skip qtvirtualkeyboard
      -skip qtwebchannel
      -skip qtwebengine
      -skip qtwebsockets
      -skip qtwebview
      -skip qtxmlpatterns 
      -no-feature-concurrent
      -no-feature-dbus
      -no-feature-host-dbus
      -no-feature-libudev
      -no-feature-sql
      -no-feature-testlib
      -no-feature-widgets
      -no-feature-xml
      -no-feature-accessibility
      -no-feature-accessibility-atspi-bridge
      -no-feature-eglfs
      -no-feature-gif
      -no-feature-mtdev
      -no-feature-pdf
      -no-feature-textmarkdownreader
      -no-feature-textmarkdownwriter
      -no-feature-textodfwriter
      -no-feature-vnc
      -no-feature-whatsthis
      -no-feature-bearermanagement
      -no-feature-gssapi
      -no-feature-cups
      -no-feature-printer
      -no-feature-qml-debug
      -no-feature-qml-network
      -no-feature-qml-profiler
      -no-feature-qml-preview
      -no-feature-quick-canvas
      -no-feature-assistant
      -no-feature-designer
      -no-feature-qdbus
      -no-feature-qev
    ]

    system "./configure", *args

    # Remove reference to shims directory
    inreplace "qtbase/mkspecs/qmodule.pri",
              /^PKG_CONFIG_EXECUTABLE = .*$/,
              "PKG_CONFIG_EXECUTABLE = #{Formula["pkg-config"].opt_bin/"pkg-config"}"
    system "make"
    ENV.deparallelize
    system "make", "install"

    # Some config scripts will only find Qt in a "Frameworks" folder
    frameworks.install_symlink Dir["#{lib}/*.framework"]

    # The pkg-config files installed suggest that headers can be found in the
    # `include` directory. Make this so by creating symlinks from `include` to
    # the Frameworks' Headers folders.
    Pathname.glob("#{lib}/*.framework/Headers") do |path|
      include.install_symlink path => path.parent.basename(".framework")
    end

    # Move `*.app` bundles into `libexec` to expose them to `brew linkapps` and
    # because we don't like having them in `bin`.
    # (Note: This move breaks invocation of Assistant via the Help menu
    # of both Designer and Linguist as that relies on Assistant being in `bin`.)
    libexec.mkpath
    Pathname.glob("#{bin}/*.app") { |app| mv app, libexec }
  end

  def caveats
    <<~EOS
      We agreed to the Qt open source license for you.
      If this is unacceptable you should uninstall.
    EOS
  end

  test do
    (testpath/"hello.pro").write <<~EOS
      QT       += core
      QT       -= gui
      TARGET = hello
      CONFIG   += console
      CONFIG   -= app_bundle
      TEMPLATE = app
      SOURCES += main.cpp
    EOS

    (testpath/"main.cpp").write <<~EOS
      #include <QCoreApplication>
      #include <QDebug>
      int main(int argc, char *argv[])
      {
        QCoreApplication a(argc, argv);
        qDebug() << "Hello World!";
        return 0;
      }
    EOS

    system bin/"qmake", testpath/"hello.pro"
    system "make"
    assert_predicate testpath/"hello", :exist?
    assert_predicate testpath/"main.o", :exist?
    system "./hello"
  end
end