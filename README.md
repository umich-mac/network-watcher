# NetworkWatcher

This utility monitors the Mac for networking changes, and when a change occurs, attempts
to connect to a given host and port. If that connection succeeds, it then launches a command. 
The utility continues to monitor and will re-run whenever the target host and port is reachable.

We recommend running this from a LaunchAgent, and the command to run also be a LaunchAgent,
triggered via `launchctl start`.

Due to how `SystemConfiguration` works, your command may get run more than once when the host becomes
reachable, so your command should be idempotent.

We run this to start up the PaperCut client only when PaperCut is reachable - e.g., on the VPN,
or on campus.
