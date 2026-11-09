# This file is written by the release workflow of github.com/ndthuan/kipp
# (scripts/brew-formula.sh); a change made here is lost at the next release.
class Kipp < Formula
  desc "Job-first CI and scheduler in a single binary"
  homepage "https://github.com/ndthuan/kipp"
  license "MIT"
  version "1.2.0"

  on_macos do
    on_arm do
      url "https://github.com/ndthuan/kipp/releases/download/v1.2.0/kipp_1.2.0_darwin_arm64.tar.gz"
      sha256 "d6f2342b3705fdbe3d80c0cd6164a539a8ecc8734546643cec4926c3cdf6f898"
    end
    on_intel do
      url "https://github.com/ndthuan/kipp/releases/download/v1.2.0/kipp_1.2.0_darwin_amd64.tar.gz"
      sha256 "d90bdd6822dc1909a8170ea1c18779932390947d7291d1688f593ea9177f0401"
    end
  end

  on_linux do
    on_arm do
      url "https://github.com/ndthuan/kipp/releases/download/v1.2.0/kipp_1.2.0_linux_arm64.tar.gz"
      sha256 "046f79b065f5b3371e52fd6cacf61f8b1aad2f681d5f28827bc30c5833817f94"
    end
    on_intel do
      url "https://github.com/ndthuan/kipp/releases/download/v1.2.0/kipp_1.2.0_linux_amd64.tar.gz"
      sha256 "a5e8024ee19cbe5a3935c9547ec391fa4023737a4d9da48af85a1ed204c1b280"
    end
  end

  head do
    url "https://github.com/ndthuan/kipp.git", branch: "main"
    depends_on "go" => :build
  end

  def install
    if build.head?
      ldflags = "-s -w -buildid= -X github.com/ndthuan/kipp/internal/version.Version=#{version}"
      %w[amd64 arm64].each do |arch|
        with_env(CGO_ENABLED: "0", GOOS: "linux", GOARCH: arch) do
          system "go", "build", "-trimpath", "-buildvcs=false", "-ldflags", ldflags,
                 "-o", "internal/runnerbin/bin/kipp-runner_linux_#{arch}", "./cmd/kipp-runner"
        end
      end
      with_env(CGO_ENABLED: "0") do
        system "go", "build", "-trimpath", "-buildvcs=false", "-ldflags", ldflags, "-o", bin/"kipp", "./cmd/kipp"
      end
    else
      bin.install "kipp"
    end
  end

  def post_install
    (var/"kipp").mkpath
    (etc/"kipp").mkpath
  end

  service do
    run [opt_bin/"kipp", "serve", "--data", var/"kipp", "--jobs", etc/"kipp", "--listen", "127.0.0.1:8085"]
    keep_alive true
    working_dir var/"kipp"
    log_path var/"log/kipp.log"
    error_log_path var/"log/kipp.log"
  end

  def caveats
    <<~EOS
      Job files go in #{etc}/kipp, the data directory is #{var}/kipp.
      Make the first admin before the first login:
        kipp user add admin --admin --data #{var}/kipp
    EOS
  end

  test do
    (testpath/"jobs/hello.yml").write "name: hello\nstages:\n  greet: {run: echo hello}\n"
    system bin/"kipp", "check", testpath/"jobs"
    assert_match "kipp", shell_output("#{bin}/kipp version")
  end
end
