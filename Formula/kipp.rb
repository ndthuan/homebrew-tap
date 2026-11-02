# This file is written by the release workflow of github.com/ndthuan/kipp
# (scripts/brew-formula.sh); a change made here is lost at the next release.
class Kipp < Formula
  desc "Job-first CI and scheduler in a single binary"
  homepage "https://github.com/ndthuan/kipp"
  license "MIT"

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
