# ayufan-taps

My personal repository with Homebrew Taps.

## Install `qemu-guest-agent`

```bash
brew install ayufan/taps/qemu-guest-agent
sudo brew services start ayufan/taps/qemu-guest-agent
```

### Verify service

```bash
brew services
Name             Status  User Plist
qemu-guest-agent started root /Library/LaunchDaemons/homebrew.mxcl.qemu-guest-agent.plist
```

```bash
sudo launchctl list homebrew.mxcl.qemu-guest-agent
{
	"LimitLoadToSessionType" = "System";
	"Label" = "homebrew.mxcl.qemu-guest-agent";
	"OnDemand" = false;
	"LastExitStatus" = 0;
	"PID" = 91;
	"Program" = "/usr/local/opt/qemu-guest-agent/bin/qemu-ga";
	"ProgramArguments" = (
		"/usr/local/opt/qemu-guest-agent/bin/qemu-ga";
		"-p";
		"/dev/tty.serial1";
		"-t";
		"/var/run";
		"-m";
		"isa-serial";
	);
};
```

### Proxmox VE VM to use Qemu Guest Agent

Configure Proxmox VE VM:

1. Go to `Options`
1. Go to `QEMU Guest Agent`
1. Enable `Use QEMU Guest Agent`
1. Enable `Advanced`
1. Select: `Type: ISA`
