# This file is written by the release workflow of github.com/ndthuan/kipp
# (scripts/brew-formula.sh); a change made here is lost at the next release.
class Kipp < Formula
  desc "Job-first CI and scheduler in a single binary"
  homepage "https://github.com/ndthuan/kipp"
  license "MIT"
  version "1.1.0"

  on_macos do
    on_arm do
      url "https://github.com/ndthuan/kipp/releases/download/v1.1.0/kipp_1.1.0_darwin_arm64.tar.gz"
      sha256 "9a5e904c7e388ae064c2033edc690eba454412e36241e07fac67dc4991b9af97"
    end
    on_intel do
      url "https://github.com/ndthuan/kipp/releases/download/v1.1.0/kipp_1.1.0_darwin_amd64.tar.gz"
      sha256 "bafaa390879653697ed274aad83756b0e61ced519723d6c9a1731d76c135cca8"
    end
  end

  on_linux do
    on_arm do
      url "https://github.com/ndthuan/kipp/releases/download/v1.1.0/kipp_1.1.0_linux_arm64.tar.gz"
      sha256 "0b3844beda06aa5f8cb8e8c75f4c29c139dafdf761f273063e85b2e9670975bb"
    end
    on_intel do
      url "https://github.com/ndthuan/kipp/releases/download/v1.1.0/kipp_1.1.0_linux_amd64.tar.gz"
      sha256 "1cc1ae6d0213b3eedb0c3727f1b115f16005fda8c18902ca307b270901be9daf"
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
