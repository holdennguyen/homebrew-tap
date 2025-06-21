class AwsAssumeRole < Formula
  desc "Simple CLI tool to easily switch between AWS IAM roles across different accounts"
  homepage "https://github.com/holdennguyen/aws-assume-role"
  version "1.2.0"

  on_macos do
    if Hardware::CPU.arm?
      url "https://github.com/holdennguyen/aws-assume-role/releases/download/v#{version}/aws-assume-role-macos-arm64"
      sha256 "PLACEHOLDER_ARM64_SHA256" # arm64
    else
      url "https://github.com/holdennguyen/aws-assume-role/releases/download/v#{version}/aws-assume-role-macos-x86_64"
      sha256 "d34d5da80bbaab3720b37ea77ab1979e1b76221da466972532c4aeb8365a996d" # macos
    end
  end

  on_linux do
    url "https://github.com/holdennguyen/aws-assume-role/releases/download/v#{version}/aws-assume-role-linux-x86_64"
    sha256 "ee2f987ab0e7fa15faf5c8f2fbc4fd15dd3148797698316b2b8c4623da011b8f" # linux
  end

  depends_on "awscli"

  def install
    if OS.mac?
      if Hardware::CPU.arm?
        bin.install "aws-assume-role-macos-arm64" => "aws-assume-role"
      else
        bin.install "aws-assume-role-macos-x86_64" => "aws-assume-role"
      end
    elsif OS.linux?
      bin.install "aws-assume-role-linux-x86_64" => "aws-assume-role"
    end

    # Install shell completions
    generate_completions_from_executable(bin/"aws-assume-role", "completion")
    
    # Create wrapper script for shell integration
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
          eval $(#{bin}/aws-assume-role assume "$2" --format export)
          
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
          #{bin}/aws-assume-role "$@"
          ;;
      esac
    EOS
    
    chmod 0755, bin/"awsr"
  end

  def caveats
    <<~EOS
      AWS Assume Role CLI has been installed!
      
      Quick Start:
        awsr configure --name dev --role-arn arn:aws:iam::123456789012:role/DevRole --account-id 123456789012
        awsr assume dev
        awsr list
      
      The 'awsr assume' command will set AWS credentials in your current shell.
      
      For more information: aws-assume-role --help
    EOS
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/aws-assume-role --version")
    assert_match "AWS Assume Role CLI", shell_output("#{bin}/aws-assume-role --help")
  end
end 