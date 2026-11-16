# This file is written by the release workflow of github.com/ndthuan/kipp
# (scripts/brew-formula.sh); a change made here is lost at the next release.
class Kipp < Formula
  desc "Job-first CI and scheduler in a single binary"
  homepage "https://github.com/ndthuan/kipp"
  license "MIT"
  version "1.4.0"

  on_macos do
    on_arm do
      url "https://github.com/ndthuan/kipp/releases/download/v1.4.0/kipp_1.4.0_darwin_arm64.tar.gz"
      sha256 "8b6066dbe51527480b721c848bbd658453ac0c06f90eda25528636ea6adcb497"
    end
    on_intel do
      url "https://github.com/ndthuan/kipp/releases/download/v1.4.0/kipp_1.4.0_darwin_amd64.tar.gz"
      sha256 "9612afa74f96a245d614e4eaec1cf6c214042ec8cd9dee80275dfeaf3ea3f15c"
    end
  end

  on_linux do
    on_arm do
      url "https://github.com/ndthuan/kipp/releases/download/v1.4.0/kipp_1.4.0_linux_arm64.tar.gz"
      sha256 "76643b2714273bf7d76261e30d54247e79a3120c112f6cfa528b93c41d94020b"
    end
    on_intel do
      url "https://github.com/ndthuan/kipp/releases/download/v1.4.0/kipp_1.4.0_linux_amd64.tar.gz"
      sha256 "45923d98ba7602be9fff85f15ed60baf54847943d3cad9d8d4269f55a3f01288"
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
