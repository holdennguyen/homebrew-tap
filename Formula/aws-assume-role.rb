class AwsAssumeRole < Formula
  desc "Simple CLI tool to easily switch between AWS IAM roles across different accounts"
  homepage "https://github.com/holdennguyen/aws-assume-role"
  version "1.0.0"
  license "MIT"

  on_macos do
    on_intel do
      url "https://github.com/holdennguyen/aws-assume-role/releases/download/v1.0.0/aws-assume-role-macos-x86_64"
      sha256 "7ad0cdc3f34c71a8c81a53819dd8358148e16d8fea5e8e69b2e1b1cac132824a"
    end

    on_arm do
      url "https://github.com/holdennguyen/aws-assume-role/releases/download/v1.0.0/aws-assume-role-macos-arm64"
      sha256 "5adde2e4f3dd433202e0674753192da255496b4fe501c6477300b70aa5e9efa5"
    end
  end

  on_linux do
    on_intel do
      url "https://github.com/holdennguyen/aws-assume-role/releases/download/v1.0.0/aws-assume-role-linux-x86_64"
      sha256 "9e7b9bfa34e14af73fc3b98291eae2e3ec5caf5c9d5fcd94280379d6d8c7a840"
    end
  end

  depends_on "awscli"

  def install
    if OS.mac?
      if Hardware::CPU.intel?
        bin.install "aws-assume-role-macos-x86_64" => "aws-assume-role"
      else
        bin.install "aws-assume-role-macos-arm64" => "aws-assume-role"
      end
    else
      bin.install "aws-assume-role-linux-x86_64" => "aws-assume-role"
    end

    # Create wrapper script for easy shell integration
    (bin/"awsr").write <<~EOS
      #!/bin/bash
      # AWS Assume Role CLI wrapper for shell integration

      case "$1" in
          assume)
              if [ -z "$2" ]; then
                  echo "Usage: awsr assume <role-name>"
                  exit 1
              fi
              
              # Get credentials and export them
              eval $(aws-assume-role assume "$2" --format export)
              
              if [ $? -eq 0 ]; then
                  echo "✅ Successfully assumed role: $2"
                  echo "🔍 Current AWS identity:"
                  aws sts get-caller-identity --output table 2>/dev/null || echo "Run 'aws sts get-caller-identity' to verify"
              else
                  echo "❌ Failed to assume role: $2"
                  exit 1
              fi
              ;;
          *)
              # Pass through all other commands
              aws-assume-role "$@"
              ;;
      esac
    EOS

    # Create shell helper functions
    (share/"aws-assume-role"/"shell-helpers.sh").write <<~EOS
      #!/bin/bash
      # AWS Assume Role CLI shell helper functions

      # Clear AWS credentials from current shell
      clear_aws_creds() {
          unset AWS_ACCESS_KEY_ID
          unset AWS_SECRET_ACCESS_KEY
          unset AWS_SESSION_TOKEN
          echo "🧹 AWS credentials cleared from current shell"
      }

      # Show current AWS identity
      aws_whoami() {
          if command -v aws >/dev/null 2>&1; then
              aws sts get-caller-identity --output table 2>/dev/null || echo "❌ No AWS credentials found"
          else
              echo "❌ AWS CLI not found"
          fi
      }

      # Export functions
      export -f clear_aws_creds aws_whoami
    EOS

    chmod 0755, bin/"awsr"
    chmod 0755, share/"aws-assume-role"/"shell-helpers.sh"
  end

  def caveats
    <<~EOS
      AWS Assume Role CLI has been installed!

      Usage:
        awsr configure --name dev --role-arn arn:aws:iam::123:role/DevRole --account-id 123
        awsr assume dev
        awsr list

      For shell helper functions, add this to your ~/.bashrc or ~/.zshrc:
        source #{HOMEBREW_PREFIX}/share/aws-assume-role/shell-helpers.sh

      This will provide additional commands:
        clear_aws_creds  - Clear AWS credentials from current shell
        aws_whoami       - Show current AWS identity
    EOS
  end

  test do
    system "#{bin}/aws-assume-role", "--version"
    system "#{bin}/awsr", "--help"
  end
end
