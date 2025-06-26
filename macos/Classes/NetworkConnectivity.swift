// macos/Classes/NetworkMonitor.swift

import Foundation
import SystemConfiguration
import FlutterMacOS
struct AppNativeEvent {
    enum EventType: String {
        case internet
        case deeplink
    }

    let type: EventType
    let value: Any?

    func toJson() -> [String: Any?] {
        return [
            "type": type.rawValue,
            "value": value
        ]
    }
}	

class NetworkMonitor {
  private var reachabilityRef: SCNetworkReachability?
  private var eventSink: FlutterEventSink?

func dispose() {
      if let ref = reachabilityRef {
        SCNetworkReachabilityUnscheduleFromRunLoop(
          ref,
          CFRunLoopGetMain(),
          CFRunLoopMode.commonModes.rawValue
        )
      }
      reachabilityRef = nil
      eventSink = nil
    }
  init(eventSink: @escaping FlutterEventSink) {
    self.eventSink = eventSink
    setupReachability()
  }

    private func setupReachability() {
        reachabilityRef = SCNetworkReachabilityCreateWithName(nil, "www.google.com")
        
        guard let reachabilityRef = reachabilityRef else { return }

        var context = SCNetworkReachabilityContext(
            version: 0,
            info: UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque()),
            retain: nil,
            release: nil,
            copyDescription: nil
        )

        SCNetworkReachabilitySetCallback(reachabilityRef, { (_, flags, info) in
            if let info = info {
                let plugin = Unmanaged<NetworkMonitor>.fromOpaque(info).takeUnretainedValue()
                plugin.handleReachabilityChange(flags)
            }
        }, &context)

        SCNetworkReachabilityScheduleWithRunLoop(reachabilityRef, CFRunLoopGetCurrent(), CFRunLoopMode.defaultMode.rawValue)

        var flags = SCNetworkReachabilityFlags()
        if SCNetworkReachabilityGetFlags(reachabilityRef, &flags) {
            handleReachabilityChange(flags)
        }
    }


    private func handleReachabilityChange(_ flags: SCNetworkReachabilityFlags) {
        guard let sink = eventSink else { return }
           let isConnected = flags.contains(.reachable) && !flags.contains(.connectionRequired)
           sink(AppNativeEvent(type: .internet, value: isConnected).toJson())
    }
  
}
