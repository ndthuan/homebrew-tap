# This file is written by the release workflow of github.com/ndthuan/kipp
# (scripts/brew-formula.sh); a change made here is lost at the next release.
class Kipp < Formula
  desc "Job-first CI and scheduler in a single binary"
  homepage "https://github.com/ndthuan/kipp"
  license "MIT"
  version "1.1.1"

  on_macos do
    on_arm do
      url "https://github.com/ndthuan/kipp/releases/download/v1.1.1/kipp_1.1.1_darwin_arm64.tar.gz"
      sha256 "a83839c1abb38103b69a229d072720720e1d926c5f86d378d3c6b6f209d16ccb"
    end
    on_intel do
      url "https://github.com/ndthuan/kipp/releases/download/v1.1.1/kipp_1.1.1_darwin_amd64.tar.gz"
      sha256 "666681caa40832768313fe8041e3044449bdcbc6aa03fa633ffcfb86a3f41548"
    end
  end

  on_linux do
    on_arm do
      url "https://github.com/ndthuan/kipp/releases/download/v1.1.1/kipp_1.1.1_linux_arm64.tar.gz"
      sha256 "15f813d8089e9dc3e3be9e845f74cee69cda0e9d848a8807aefdd6259c3871ce"
    end
    on_intel do
      url "https://github.com/ndthuan/kipp/releases/download/v1.1.1/kipp_1.1.1_linux_amd64.tar.gz"
      sha256 "64c2aef904c8bf1efd65c4be59d5058f2e6b59c18ebe87ed4c52a7bd7448e252"
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
                 "-o", "internal/agentbin/bin/kipp-agent_linux_#{arch}", "./cmd/kipp-agent"
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
