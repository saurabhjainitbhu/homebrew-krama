# typed: false
# frozen_string_literal: true

# Homebrew formula for Krama — Agent-driven iOS development pipeline.
# Tap: kidzofy/harness
# REQ-0-SESSION_PLACEHOLDER

class Krama < Formula
  desc "Agent-driven iOS development pipeline - automated issue processing with AI agents"
  homepage "https://github.com/saurabhjainitbhu/AgentHarness"
  url "https://github.com/saurabhjainitbhu/AgentHarness/releases/download/v#{version}/krama-#{version}.tar.gz"
  license "MIT"

  # When a release is cut, replace this with the actual SHA256 of the tarball.
  sha256 "0000000000000000000000000000000000000000000000000000000000000000"

  depends_on "python@3.12"
  depends_on "gh"
  depends_on "opencode"
  depends_on "node"

  def install
    # Step 1: Create a virtualenv and install all monorepo packages.
    # pip resolves inter-package dependencies automatically.
    venv = virtualenv_create(libexec, "python3.12")
    venv.pip_install buildpath.glob("packages/*")

    # Step 2: Copy all non-Python assets into libexec.
    %w[config .opencode Setup templates scripts tasks archive].each do |dir|
      src = buildpath/dir
      cp_r src, libexec/dir if src.exist?
    end

    # Step 3: Write a self-contained entry script that uses the libexec layout.
    # This mirrors the dev-mode krama script but resolves paths from libexec.
    (libexec/"krama").write <<~PYTHON
      #!/usr/bin/env python3
      """Krama CLI entry point (Homebrew installed)."""
      import sys
      import os

      _base = os.path.dirname(os.path.abspath(__file__))
      _pkg_dirs = [
          "krama-cli", "krama-engine", "krama-config",
          "krama-git", "krama-adapters", "krama-db", "krama-providers",
      ]
      for name in _pkg_dirs:
          sys.path.insert(0, os.path.join(_base, "packages", name, "src"))

      try:
          from krama.cli.app import main
      except ImportError as e:
          print(
              f"Error: Could not import Krama CLI modules. "
              f"Ensure the formula was built correctly.\\n  {e}",
              file=sys.stderr,
          )
          sys.exit(1)

      main()
    PYTHON
    (libexec/"krama").chmod 0o755

    # Symlink into bin so __file__ resolves to the real libexec path.
    bin.install_symlink libexec/"krama" => "krama"
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
