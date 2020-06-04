class SshWithGpg < Formula
  desc "a GnuPG/PIV configuration for SSH"

  url "file:///dev/null"
  sha256 "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"
  version "0.2.1"
  depends_on "gnupg2"
  depends_on "pinentry-mac"

  def install
    (prefix/"bin/ssh-with-gpg").write ssh_with_gpg
    (prefix/"bin/sshpiv").write ssh_with_piv
  end

  def caveats
    <<~EOS
      Add the following line to your bash/zsh profile (e.g. ~/.bashrc, ~/.profile, ~/.bash_profile or ~/.zshrc)

        gpgconf --launch gpg-agent
        ln -sf $HOME/.gnupg/S.gpg-agent.ssh $SSH_AUTH_SOCK

      Then:

        1. Start service `brew services start ayufan/taps/ssh-with-gpg`
        2. Run `ssh-with-gpg verify` to verify
        3. Start new terminal session
        4. Insert `Yubikey` and run `ssh-add -L`
        5. (optionally) Install `brew cask install yubico-yubikey-manager`
    EOS
  end

  def plist; <<~EOS
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
      <dict>
        <key>Label</key>
        <string>#{plist_name}</string>
        <key>ProgramArguments</key>
        <array>
          <string>#{opt_bin}/ssh-with-gpg</string>
          <string>run</string>
        </array>
        <key>RunAtLoad</key>
        <true/>
        <key>KeepAlive</key>
        <true/>
      </dict>
    </plist>
  EOS
  end

  def ssh_with_gpg
    <<~EOS
    #!/bin/bash

    realpath() {
        [[ $1 = /* ]] && echo "$1" || echo "$PWD/${1#./}"
    }

    DETECT=${DETECT:-notify}
    GPG_AGENT_CONF=~/.gnupg/gpg-agent.conf
    GPG_AGENT_LOG_FILE=~/.gnupg/gpg-agent.log
    SELF=$(realpath $0)

    write() {
      if [[ -f "$GPG_AGENT_CONF" ]]; then
        echo "The $GPG_AGENT_CONF already exists"
        return 0
      fi

      mkdir -p ~/.gnupg

      cat <<EOF > "$GPG_AGENT_CONF"
    enable-ssh-support
    pinentry-program /usr/local/bin/pinentry-mac
    log-file $GPG_AGENT_LOG_FILE
    verbose
    EOF
    }

    verify() {
      echo "Verifying gpg-agent config..."

      if ! grep -q "^verbose" "$GPG_AGENT_CONF"; then
        echo "Missing 'verbose' in '$GPG_AGENT_CONF'"
        exit 1
      fi

      if ! grep -q "^log-file $GPG_AGENT_LOG_FILE" "$GPG_AGENT_CONF"; then
        echo "Missing 'log-file $GPG_AGENT_LOG_FILE' in '$GPG_AGENT_CONF'"
        exit 1
      fi
    }

    ssh_notify() {
      osascript -e 'display notification "Sign requested by SSH" with title "GPG Agent" sound name "Submarine"'
    }

    gpg_notify() {
      osascript -e 'display notification "Your yubikey is waiting for touch!" with title "Yubikey" sound name "Submarine"'
    }

    ssh_sign_request_gpg_detect() {
      gpg --card-status &
      PID=$!

      # notify after 1s
      ( sleep 0.25s && gpg_notify ) &
      SLEEP_PID=$!

      # kill after 10s
      ( sleep 10s && kill "$PID" ) &
      KILL_PID=$!

      # wait for GPG, first
      wait "$PID"
      kill "$PID" "$SLEEP_PID" "$KILL_PID"
    }

    ssh_sign_request_notify() {
      ssh_notify
    }

    run() {
      echo "Starting gpg-agent"
      gpgconf --launch gpg-agent
      ln -sf "$HOME/.gnupg/S.gpg-agent.ssh" "$SSH_AUTH_SOCK"

      echo "Running $0..."
      tail -n 0 -F "$GPG_AGENT_LOG_FILE" | while read LINE; do
        case "$LINE" in
          *ssh*sign_request*started*)
            ssh_sign_request_$DETECT
            ;;
        esac
      done
    }

    case "$1" in
      write)
        write
        ;;

      verify)
        verify
        ;;

      run)
        write
        verify
        run
        ;;

      *)
        echo "usage: $0 <verify|write|run>"
        exit 1
        ;;
    esac
    EOS
  end

  def ssh_with_piv
    <<~EOS
    #!/bin/bash

    exec ssh -I /usr/local/lib/libykcs11.dylib "$@"
    EOS
  end
end
