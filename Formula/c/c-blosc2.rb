class CBlosc2 < Formula
  desc "Fast, compressed, persistent binary data store library for C"
  homepage "https://www.blosc.org"
  url "https://github.com/Blosc/c-blosc2/archive/refs/tags/v2.21.0.tar.gz"
  sha256 "de69eedd87a8301cdb665f3dab61e7c2b7e4b326a496f9ec88213fc8788d54d5"
  license "BSD-3-Clause"
  head "https://github.com/Blosc/c-blosc2.git", branch: "main"

  bottle do
    sha256 cellar: :any,                 arm64_sequoia: "05853eee61fce98a4bf78ed962262eea2e1d921c75dc52ddb2f4ff2d399d7ccf"
    sha256 cellar: :any,                 arm64_sonoma:  "f627bb3abd4235d767143aa6bfca09175bba5decaa9cee010c8a2d5cd2ecbee1"
    sha256 cellar: :any,                 arm64_ventura: "4e9e5d34155d02b030e1f2bf46e43082bf1fff9c2343dac7a9652c98a08fc858"
    sha256 cellar: :any,                 sonoma:        "e8cb81d2916090166d055c2bb1616b9cf8b2277db12584c66027fbd060c122a6"
    sha256 cellar: :any,                 ventura:       "f271438d9600e1e88db8a2442dbebbbb6127690f6b0fa296c1039e43460e72bd"
    sha256 cellar: :any_skip_relocation, arm64_linux:   "3b709f0796472624d3aa4c9c6faa1c3e8eaeb5b87ce8cce34c948ec945417e01"
    sha256 cellar: :any_skip_relocation, x86_64_linux:  "f4a8540a28fb7b6e5f9c3f677c34ab42cbc6791126c3c43ed5578ffb44155fd2"
  end

  depends_on "cmake" => :build
  depends_on "lz4"
  depends_on "zstd"

  uses_from_macos "zlib"

  on_macos do
    depends_on "llvm" => :build if DevelopmentTools.clang_build_version <= 1400
  end

  # Apply open PR to fix lz4 detection: https://github.com/Blosc/c-blosc2/pull/690
  patch do
    url "https://github.com/Blosc/c-blosc2/commit/365fc46afd585880d4726cac49cefdfcaa75be3b.patch?full_index=1"
    sha256 "0473f56cb712479ef9df11d5453e77f2a50c2e17f27fb2f3010f616bc00cdbf7"
  end
  patch do
    url "https://github.com/Blosc/c-blosc2/commit/df525d2fe0a519a4999483e81807621b407c07a7.patch?full_index=1"
    sha256 "0df6b619f62a9e845fe7fc31c3e12704dcd92c98dcb86bd53026758f67a13f21"
  end

  def install
    ENV.llvm_clang if OS.mac? && DevelopmentTools.clang_build_version <= 1400

    internal_complibs = buildpath.glob("internal-complibs/{lz4,zlib,zstd}-*")
    odie "Failed to find vendored sources for removal!" if internal_complibs.count != 3
    rm_r internal_complibs

    args = %w[
      -DBUILD_TESTS=OFF
      -DBUILD_FUZZERS=OFF
      -DBUILD_BENCHMARKS=OFF
      -DBUILD_EXAMPLES=OFF
      -DPREFER_EXTERNAL_LZ4=ON
      -DPREFER_EXTERNAL_ZLIB=ON
      -DPREFER_EXTERNAL_ZSTD=ON
    ]

    system "cmake", "-S", ".", "-B", "build", *args, *std_cmake_args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"

    pkgshare.install "examples/simple.c"
  end

  test do
    system ENV.cc, pkgshare/"simple.c", "-I#{include}", "-L#{lib}", "-lblosc2", "-o", "test"
    assert_match "Successful roundtrip!", shell_output(testpath/"test")
  end
end
