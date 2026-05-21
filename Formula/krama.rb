# typed: false
# frozen_string_literal: true

# Homebrew formula for Krama — Agent-driven iOS development pipeline.
# Tap: kidzofy/harness
# REQ-0-SESSION_PLACEHOLDER

class Krama < Formula
  desc "Agent-driven iOS development pipeline - automated issue processing with AI agents"
  homepage "https://github.com/saurabhjainitbhu/AgentHarness"
  version "0.1.1"
  url "https://github.com/saurabhjainitbhu/homebrew-krama/releases/download/v#{version}/krama-#{version}.tar.gz"
  license "MIT"

  sha256 "ed1ea8f29b204ee538ae64511b49878c7f41632b8f1ccb0cced417b578cb7e15"

  depends_on "python@3.12"
  depends_on "gh"
  depends_on "opencode"
  depends_on "node"

  def install
    # Step 1: Create a venv and install all monorepo packages.
    python = "python3.12"
    system python, "-m", "venv", libexec/"venv"
    venv_pip = libexec/"venv/bin/pip"
    system venv_pip, "install", "pip", "--upgrade", "--quiet"
    system venv_pip, "install", *buildpath.glob("packages/*"), "--quiet"

    # Step 2: Copy all non-Python assets into libexec.
    %w[config .opencode Setup templates scripts tasks archive].each do |dir|
      src = buildpath/dir
      cp_r src, libexec/dir if src.exist?
    end

    # Step 3: Install the krama wrapper script.
    (libexec/"bin").mkpath
    (libexec/"bin/krama").write <<~SH
      #!/bin/bash
      exec "#{libexec}/venv/bin/python" -m krama.cli.app "$@"
    SH
    chmod 0755, libexec/"bin/krama"
    bin.install_symlink libexec/"bin/krama" => "krama"
  end

  def caveats
    <<~EOS
      To use Krama with a project:
        cd /path/to/your/project
        krama setup
        # Then edit .krama/Setup/user_config.yaml and KRAMA_config.yaml
        krama serve
    EOS
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/krama --help")
  end
end
