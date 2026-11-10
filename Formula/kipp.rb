# This file is written by the release workflow of github.com/ndthuan/kipp
# (scripts/brew-formula.sh); a change made here is lost at the next release.
class Kipp < Formula
  desc "Job-first CI and scheduler in a single binary"
  homepage "https://github.com/ndthuan/kipp"
  license "MIT"
  version "1.3.0"

  on_macos do
    on_arm do
      url "https://github.com/ndthuan/kipp/releases/download/v1.3.0/kipp_1.3.0_darwin_arm64.tar.gz"
      sha256 "9672b1893f648d4ecfcf6975d49530af0e4926ec15cfbac385a9b4d0ea4f197d"
    end
    on_intel do
      url "https://github.com/ndthuan/kipp/releases/download/v1.3.0/kipp_1.3.0_darwin_amd64.tar.gz"
      sha256 "763b605315f4082099cfbd487098b14b2680af6dc6783cd5dd794afc8f2728a7"
    end
  end

  on_linux do
    on_arm do
      url "https://github.com/ndthuan/kipp/releases/download/v1.3.0/kipp_1.3.0_linux_arm64.tar.gz"
      sha256 "fd819af65735ce0c073a839a76918694fc9041b48b718c11e3e0cc6b4e6f994c"
    end
    on_intel do
      url "https://github.com/ndthuan/kipp/releases/download/v1.3.0/kipp_1.3.0_linux_amd64.tar.gz"
      sha256 "26fb9143160a78d28dcd390d67774f40031ed029b16de99dd13f26d3b21fd184"
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
