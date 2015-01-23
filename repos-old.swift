#!/usr/bin/env xcrun swift

import AppKit

extension Dictionary {
    func merge( other:Dictionary ) -> Dictionary {
        var copy = self
        for (key, value) in other {
            copy[key] = value
        }
        return copy
    }
}

struct Options {
    var query  = false
    var script = false
}
let options = Options(
    query:  nil != find( Process.arguments, "-q" ),
    script: nil != find( Process.arguments, "-s" )
)

func firstWindowOf( s:NSString ) -> NSString { return "the first window of process \"\(s)\"" }
func allWindowsOf( s:NSString ) -> NSString  { return "windows of process \"\(s)\"" }

let windowsOfInterest = [ 
  "onepassword"    : firstWindowOf("1Password 4"),
  "adium-chat"     : firstWindowOf("Adium")   + " whose name is not \"Contacts\"",
  "adium-contacts" : firstWindowOf("Adium")   + " whose name is \"Contacts\"",
  "chrome"         : allWindowsOf("Google Chrome"),
  "chromium"       : firstWindowOf("Chromium"),
  "echofon"        : firstWindowOf("EchofonLite"),
  "firefox"        : firstWindowOf("Firefox") + " whose name is not \"Downloads\"",
  "ical"           : firstWindowOf("iCal"),
  "gitx"           : allWindowsOf( "GitX" ),
  "googlecal"      : firstWindowOf("Calendar"),
  "propane"        : firstWindowOf("HipChat"),
  "iterm"          : firstWindowOf("iTerm"),
  "itunes"         : firstWindowOf("iTunes"),
  "mail"           : firstWindowOf("Mail"),
  "mailplane"      : firstWindowOf("Mailplane 3"),
  "messages"       : firstWindowOf("Messages"),
  "safari"         : firstWindowOf("Safari"),
  "things"         : firstWindowOf("Things"),
  "terminal"       : firstWindowOf("Terminal"),
  "xcode"          : allWindowsOf("Xcode"),
]

// heterogenous dictionaries use NSDictionary by default
let commonConfiguration:[String: AnyObject?] = [
  "standard"    : [ "position": [0, 0], "size": [1024, 768] ],

  "onepassword" : "standard",
  "chrome"      : "standard",
  "chromium"    : "standard",
  "firefox"     : "standard",
  "gitx"        : "standard",
  "googlecal"   : "standard",
  "hipchat"     : "standard",
  "ical"        : "standard",
  "iterm"       : "terminal",
  "itunes"      : "standard",
  "mail"        : "standard",
  "mailplane"   : "standard",
  "safari"      : "standard",
  "terminal"    : "standard",
  "xcode"       : "standard",
]

let propertiesOfInterest = [ "position", "size" ]

let mainDisplayWidth  = Int( NSScreen.mainScreen()!.frame.size.width )
let mainDisplayHeight = Int( NSScreen.mainScreen()!.frame.size.height )
var config : [ String: AnyObject? ]
var widthConfig:[String: AnyObject?]? = [String:AnyObject?]()
if let wc = widthConfig {
    config = commonConfiguration.merge( wc )
}

let appIsRunningSnippet = [
  "global processes",
  "tell application \"System Events\" to get displayed name of every process",
  "set processes to the result",
  "on appIsRunning( appName )",
  "  processes contains appName",
  "end appIsRunning"
].componentsJoinedByString("\n")

func doAppleScript( script:NSString ) -> [Int]? {
    if let result = NSAppleScript( source: script )!.executeAndReturnError(nil) {
        var results:[Int] = []
        for i in 0..<result.numberOfItems {
            var desc = result.descriptorAtIndex( i + 1 )! // NSAppleEventDescriptor uses 1-based indices
            results.append( Int( desc.int32Value ) )
        }
        return results
    }
    return nil
}

func getProcessName( spec:NSString ) -> NSString {
    let re = NSRegularExpression( pattern: "process[ ](\".*?\")", options: nil, error: nil )!
    if let match = re.firstMatchInString( spec, options: nil, range: NSMakeRange( 0, spec.length ) ) {
        return spec.substringWithRange( match.rangeAtIndex(1) )
    }
    NSException(name: NSInternalInconsistencyException, reason: "Process name not found", userInfo: nil).raise()
    return "unreachable"
}

if options.query {
    var windowProperties = [String: [String: [Int]]]()

    for (key,spec) in windowsOfInterest {
        var props = [String: [Int]]()
        var procName = getProcessName( spec )
        for prop in propertiesOfInterest {
            var script = [
                appIsRunningSnippet,
                "if appIsRunning( \(procName) )",
                "  tell application \"System Events\" to get the \(prop) of \(spec)",
                "end if"
            ].componentsJoinedByString("\n")
            if let scriptResult = doAppleScript( script ) {
                if !scriptResult.isEmpty {
                    props[prop] = scriptResult
                }
            }
        }

        if !props.isEmpty {
            windowProperties[key] = props
        }
    }

    println( windowProperties )
}
else {
    var scriptLines = [ appIsRunningSnippet ]
    
}


// for (key,spec) in windowsOfInterest {
//     println( "\(key) \(spec)" )
// }
