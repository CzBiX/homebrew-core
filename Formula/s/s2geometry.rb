class S2geometry < Formula
  desc "Computational geometry and spatial indexing on the sphere"
  homepage "https://github.com/google/s2geometry"
  url "https://github.com/google/s2geometry/archive/refs/tags/v0.12.0.tar.gz"
  sha256 "c09ec751c3043965a0d441e046a73c456c995e6063439a72290f661c1054d611"
  license "Apache-2.0"
  revision 3

  livecheck do
    url :homepage
    regex(/^v?(\d+(?:\.\d+)+)$/i)
  end

  bottle do
    sha256 cellar: :any,                 arm64_sequoia: "0742327f9b20ef0f0b00822483b440a7d3e40aab753891e777ea7faedc2e2a13"
    sha256 cellar: :any,                 arm64_sonoma:  "fd6dc381c55830ae374727279f594787d68b5239b94a068abf98f39d474fed29"
    sha256 cellar: :any,                 arm64_ventura: "0fbbd17fcc7643a3cb35e4ea1a2b0986c4f1d4bca3550b6546341ee47fe70ca9"
    sha256 cellar: :any,                 sonoma:        "b8fd3630afa3065721cf0a8e2eaa95b3db4b676a86167c8d69fa01a6052b30ae"
    sha256 cellar: :any,                 ventura:       "74b28f26380b22ce7d4d939d7f8e524f9a952e295295cf529ca7b7858a2d8652"
    sha256 cellar: :any_skip_relocation, arm64_linux:   "533a61a9645ee6ea9bb01a225a265748a50744176230de0cda5f4af401aea256"
    sha256 cellar: :any_skip_relocation, x86_64_linux:  "7a6a4eaa4024d2feb9a44a6c22d91e84829b1b0042fbf41b05a8341ade13e11f"
  end

  depends_on "cmake" => [:build, :test]
  depends_on "abseil"
  depends_on "glog"
  depends_on "openssl@3"

  # Backport support for Abseil >= 20250814.0 from
  # https://github.com/google/s2geometry/commit/9bdfdc0db978fb9d6753a880042a65ed5e83eabe
  patch :DATA

  def install
    args = %W[
      -DOPENSSL_ROOT_DIR=#{Formula["openssl@3"].opt_prefix}
      -DBUILD_TESTS=OFF
      -DWITH_GFLAGS=1
      -DWITH_GLOG=1
      -DCMAKE_CXX_STANDARD=17
      -DCMAKE_CXX_STANDARD_REQUIRED=TRUE
    ]

    system "cmake", "-S", ".", "-B", "build/shared", *args, *std_cmake_args
    system "cmake", "--build", "build/shared"
    system "cmake", "--install", "build/shared"

    system "cmake", "-S", ".", "-B", "build/static", *args,
                    "-DBUILD_SHARED_LIBS=OFF",
                    "-DOPENSSL_USE_STATIC_LIBS=TRUE",
                    *std_cmake_args
    system "cmake", "--build", "build/static"
    lib.install "build/static/libs2.a"
  end

  test do
    (testpath/"test.cpp").write <<~CPP
      #include "s2/s2loop.h"
      #include "s2/s2polygon.h"
      #include "s2/s2latlng.h"

      #include <vector>
      #include <iostream>

      int main() {
          // Define the vertices of a polygon around a block near the Googleplex.
          std::vector<S2LatLng> lat_lngs = {
              S2LatLng::FromDegrees(37.422076, -122.084518),
              S2LatLng::FromDegrees(37.422003, -122.083984),
              S2LatLng::FromDegrees(37.421964, -122.084028),
              S2LatLng::FromDegrees(37.421847, -122.083171),
              S2LatLng::FromDegrees(37.422140, -122.083167),
              S2LatLng::FromDegrees(37.422076, -122.084518) // Last point equals the first one
          };

          std::vector<S2Point> points;
          for (const auto& ll : lat_lngs) {
              points.push_back(ll.ToPoint());
          }
          std::unique_ptr<S2Loop> loop = std::make_unique<S2Loop>(points);

          S2Polygon polygon(std::move(loop));

          S2LatLng test_point = S2LatLng::FromDegrees(37.422, -122.084);
          if (polygon.Contains(test_point.ToPoint())) {
              std::cout << "The point is inside the polygon." << std::endl;
          } else {
              std::cout << "The point is outside the polygon." << std::endl;
          }

          return 0;
      }
    CPP

    system ENV.cxx, "-std=c++17", "test.cpp", "-o", "test",
      "-L#{lib}", "-ls2", "-L#{Formula["abseil"].lib}", "-labsl_log_internal_message"
    system "./test"
  end
end

__END__
diff --git a/src/s2/s2density_tree.cc b/src/s2/s2density_tree.cc
index b1892be380d15c55866630619405fd3b619a8ac5..c40964740cc49a72e613c1f0023c4a6400f66a8a 100644
--- a/src/s2/s2density_tree.cc
+++ b/src/s2/s2density_tree.cc
@@ -911,7 +911,7 @@ const S2DensityTree::Cell* S2DensityTree::DecodedPath::LoadCell(
   return cell;
 }
 
-S2DensityTree S2DensityTree::Normalize(absl::Nonnull<S2Error*> error) const {
+S2DensityTree S2DensityTree::Normalize(S2Error* absl_nonnull error) const {
   *error = S2Error::Ok();
 
   DecodedPath path(this);
@@ -950,7 +950,7 @@ S2DensityTree S2DensityTree::Normalize(absl::Nonnull<S2Error*> error) const {
   return tree;
 }
 
-S2CellUnion S2DensityTree::Leaves(absl::Nonnull<S2Error*> error) const {
+S2CellUnion S2DensityTree::Leaves(S2Error* absl_nonnull error) const {
   std::vector<S2CellId> leaves;
 
   VisitCells(
diff --git a/src/s2/s2density_tree.h b/src/s2/s2density_tree.h
index a6b7a48d8a1b549d16e7d2597ccb207b2e1038bf..249438e00fc6edae01d103885cf8f0068cb03649 100644
--- a/src/s2/s2density_tree.h
+++ b/src/s2/s2density_tree.h
@@ -272,11 +273,11 @@ class S2DensityTree {
   // weight is scaled by (its parent's weight / the sum of weights of the node
   // and its siblings). This makes the weight of a parent equal to the sum of
   // its children.
-  S2DensityTree Normalize(absl::Nonnull<S2Error*> error) const;
+  S2DensityTree Normalize(S2Error* absl_nonnull error) const;
 
   // Returns an S2CellUnion containing the leaves of this tree.  The cell union
   // is not necessarily normalized.
-  S2CellUnion Leaves(absl::Nonnull<S2Error*> error) const;
+  S2CellUnion Leaves(S2Error* absl_nonnull error) const;
 
   // The decoded weight and offsets of encoded cells.
   class Cell {
diff --git a/src/s2/s2edge_tessellator.h b/src/s2/s2edge_tessellator.h
index 513afbdc52eb621aa42d8d30b8383950da455dd4..b55d1028c1fff298816e4af94f68590eed2e4a46 100644
--- a/src/s2/s2edge_tessellator.h
+++ b/src/s2/s2edge_tessellator.h
@@ -44,7 +45,7 @@ class S2EdgeTessellator {
   // ------------------|------------------------|-----------------------
   // AppendProjected   | S2 geodesics           | Planar projected edges
   // AppendUnprojected | Planar projected edges | S2 geodesics
-  S2EdgeTessellator(absl::Nonnull<const S2::Projection*> projection,
+  S2EdgeTessellator(const S2::Projection* absl_nonnull projection,
                     S1Angle tolerance);
 
   // Converts the spherical geodesic edge AB to a chain of planar edges in the
@@ -95,7 +96,7 @@ class S2EdgeTessellator {
                        const R2Point& pb, const S2Point& b,
                        std::vector<R2Point>* vertices) const;
 
-  absl::Nonnull<const S2::Projection*> proj_;
+  const S2::Projection* absl_nonnull proj_;
 
   // The given tolerance scaled by a constant fraction so that it can be
   // compared against the result returned by EstimateMaxError().
