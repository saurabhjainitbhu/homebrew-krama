# typed: false
# frozen_string_literal: true

# Homebrew formula for Krama Dev — continuous development build.
# Auto-updated on every push to main branch of AgentHarness.
# Tap: kidzofy/harness

class KramaDev < Formula
  desc "Krama development build - agent-driven iOS development pipeline (auto-updated)"
  homepage "https://github.com/saurabhjainitbhu/AgentHarness"
  version "0.1.0.dev.816deea"
  url "https://github.com/saurabhjainitbhu/homebrew-krama/releases/download/dev/krama-#{version}.tar.gz"
  license "MIT"

  sha256 "2adebc5f8cc7a835d402c40a74271385244ac1987ad147c545c1d4e77e2bef12"

  depends_on "python@3.12"
  depends_on "gh"
  depends_on "opencode"
  depends_on "node"

  def install
    python = "python3.12"
    system python, "-m", "venv", libexec/"venv"
    venv_pip = libexec/"venv/bin/pip"
    system venv_pip, "install", "pip", "setuptools", "wheel", "--upgrade", "--quiet"
    system venv_pip, "install", *buildpath.glob("packages/*")

    %w[config .opencode Setup templates scripts tasks archive].each do |dir|
      src = buildpath/dir
      cp_r src, libexec/dir if src.exist?
    end

    (libexec/"bin").mkpath
    (libexec/"bin/krama-dev").write <<~SH
      #!/bin/bash
      export KRAMA_ASSETS="#{libexec}"
      exec "#{libexec}/venv/bin/python" -c "
      import sys, os
      p = '#{libexec}'
      for d in ['krama-cli','krama-engine','krama-config','krama-git','krama-adapters','krama-db','krama-providers']:
          sys.path.insert(0, os.path.join(p, 'packages', d, 'src'))
      os.environ.setdefault('KRAMA_ASSETS', p)
      from krama.cli.app import main
      main()
      " "$@"
    SH
    chmod 0755, libexec/"bin/krama-dev"
    bin.install_symlink libexec/"bin/krama-dev" => "krama-dev"
  end

  def caveats
    <<~EOS
      Krama Dev is a continuous development build, updated on every push to main.
      It is installed as `krama-dev` and can coexist with the stable `krama` formula.

      To use with a project:
        cd /path/to/your/project
        krama-dev setup
        krama-dev serve
    EOS
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/krama-dev --help")
  end
end
