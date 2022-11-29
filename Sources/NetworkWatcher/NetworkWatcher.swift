import Cocoa
import SystemConfiguration
import ArgumentParser
import SwiftSocket

var gServer: String = ""
var gPort: Int32 = 443
var gCommand: String = ""
var gAdditionalArguments: [String] = []
var gCooldown: Date = Date.distantPast

func ipDidChange(store: SCDynamicStore, keys: CFArray, info: UnsafeMutableRawPointer?) {
    let client: TCPClient = TCPClient(address: gServer, port: gPort)
    
    if gCooldown > Date.init() {
        print("recently launched, passing for now...")
        return
    }
    
    print("testing reachability...")
    
    Task {
        // Try to connect 10 times
        var attempts = 0
        while attempts < 10 {
            let result = client.connect(timeout: 3)

            // Connected! launch utility
            if result.isSuccess {
                client.close()

                print("  success connecting to \(gServer):\(gPort), launching \(gCommand)")
                let task = Process()
                task.launchPath = gCommand
                task.arguments = gAdditionalArguments
                task.launch()
                
                // set cooldown
                gCooldown = Date.init() + 120 // seconds

                // Get out
                return
            }
            else {
                sleep(2) // seconds
            }

            attempts += 1
        }
        print("  couldn't connect to \(gServer):\(gPort) giving up")
    }
}

@main
struct NetworkWatcher: ParsableCommand {
    
    static var configuration = CommandConfiguration(
        abstract: "Network Watcher",
        discussion: "Monitors the network for changes, and calls (and will re-call) another command when a port becomes reachable.",
        version: "1.5.1"
    )
    
    @Argument(help: "IP or server name to test")
    var server: String
    
    @Argument(help: "Port number to test")
    var port: Int32 = 443
    
    @Argument(help: "Command to run when reachable")
    var command: String
    
    @Argument(help: "Any additional arguments, if any")
    var addtionalArguments: [String] = []
    
    public func run() throws {
        gServer = server
        gPort = port
        gCommand = command
        gAdditionalArguments = addtionalArguments
        
        if let store = SCDynamicStoreCreate(nil, "NetworkWatcher" as CFString, ipDidChange, nil) {
            let pattern = SCDynamicStoreKeyCreateNetworkServiceEntity(nil, kSCDynamicStoreDomainState, kSCCompAnyRegex, kSCEntNetIPv4)
            let patternList = [ pattern ] as CFArray

            SCDynamicStoreSetNotificationKeys(store, nil, patternList)
            let runLoopSource = SCDynamicStoreCreateRunLoopSource(nil, store, 0)

            CFRunLoopAddSource(RunLoop.current.getCFRunLoop(), runLoopSource, CFRunLoopMode.defaultMode)

            // Run one immediately
            ipDidChange(store: store, keys: [] as CFArray, info: nil)

            // Wait forever
            print("starting watcher...")
            RunLoop.current.run()
        }

        print("Couldn't join SCDynamicStore to watch for IP changes.")
        throw ExitCode(-1)
    }
}
