# This file is written by the release workflow of github.com/ndthuan/kipp
# (scripts/brew-formula.sh); a change made here is lost at the next release.
class Kipp < Formula
  desc "Job-first CI and scheduler in a single binary"
  homepage "https://github.com/ndthuan/kipp"
  license "MIT"
  version "1.0.0"

  on_macos do
    on_arm do
      url "https://github.com/ndthuan/kipp/releases/download/v1.0.0/kipp_1.0.0_darwin_arm64.tar.gz"
      sha256 "015e4eb8f6b6249b8f913d8742e363d88698822d8293358436cd7dd38f439a69"
    end
    on_intel do
      url "https://github.com/ndthuan/kipp/releases/download/v1.0.0/kipp_1.0.0_darwin_amd64.tar.gz"
      sha256 "385c5b9df32394d69a4ea951f01087bab686c16bd8753047b2779df122ba7670"
    end
  end

  on_linux do
    on_arm do
      url "https://github.com/ndthuan/kipp/releases/download/v1.0.0/kipp_1.0.0_linux_arm64.tar.gz"
      sha256 "1996b48d495cab5d8edfc626f81231f7f715d0d4d22b5f3427bef5d9d59645f9"
    end
    on_intel do
      url "https://github.com/ndthuan/kipp/releases/download/v1.0.0/kipp_1.0.0_linux_amd64.tar.gz"
      sha256 "827c7e4575f69a599c5aa35dfaa8dd629b41d03e1abbf250c6250ab058d20aa6"
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
