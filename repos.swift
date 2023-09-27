#!/usr/bin/env xcrun swift

import AppKit

let screenSize = NSScreen.main!.frame.size

let procsOfInterest = [
    "1Password",
    "Calendar",
    "Chromium",
    "Firefox",
    "GitX",
    "Google Chrome Canary",
    "Google Chrome",
    "kitty",
    "Mail",
    "Mailplane",
    "Messages",
    "Safari",
    "Slack",
    "Terminal",
    "Things",
    "Xcode",
    "iTerm2",
];

let MENU_BAR_HEIGHT = 22
let DOCK_HEIGHT = 64

func center_horizontally( _ dw:Int, _ ww:Int ) -> Int {
    return ( dw - ww ) / 2
}

func maxheight( _ dh:Int ) -> Int {
    return dh - MENU_BAR_HEIGHT - DOCK_HEIGHT
}

func center_vertically( _ dh:Int, _ wh:Int ) -> Int {
    let effective_display_height = maxheight( dh )
    let y_offset_from_menu = ( effective_display_height - wh ) / 2
    return MENU_BAR_HEIGHT + y_offset_from_menu
}

func centered( _ dw:Int, _ dh:Int, _ ww:Int, _ wh:Int ) -> CGRect {
    let wx = center_horizontally( dw, ww )
    let wy = center_vertically( dh, wh )
    return CGRect( x:wx, y:wy, width:ww, height:wh )
}

var configurationForWidth:[CGFloat:[String:CGRect]] = [
    2560 : {
        let dw = 2560, dh = 1440
        return [
            "standard"    : centered( dw, dh, 1600, 1200 ),
            "Things"      : centered( dw, dh,  768,  512 ),
            "Slack"       : CGRect( x:0,        y:MENU_BAR_HEIGHT, width:834,  height:maxheight( dh ) ),
            "iTerm2"      : CGRect( x:dw - 554, y:693,             width:554,  height:388 ),
            "Messages"    : CGRect( x:996,      y:440,             width:768,  height:512 ),
            "Terminal"    : CGRect( x:694,      y:MENU_BAR_HEIGHT, width:1202, height:1341 ),
            "kitty"       : CGRect( x:694,      y:MENU_BAR_HEIGHT, width:1202, height:1341 ),
        ]
    }(),
    1792 : {
        let dw = 1792, dh = 1120
        return [
            "standard"    : centered( dw, dh, 1600, 1200 ),
            "Things"      : centered( dw, dh,  768,  512 ),
            "Slack"       : CGRect( x:0,        y:MENU_BAR_HEIGHT, width:834,  height:maxheight( dh ) ),
            "iTerm2"      : CGRect( x:dw - 554, y:693,             width:554,  height:388 ),
            "Messages"    : CGRect( x:996,      y:440,             width:768,  height:512 ),
            "Terminal"    : centered( dw, dh, 1202, 1341 ),
            "kitty"       : centered( dw, dh, 1202, 1341 ),
        ]
    }(),
    1680 : {
        let dw = 1680, dh = 1050
        return [
            "standard"    : CGRect( x:200, y:MENU_BAR_HEIGHT, width:1280, height:maxheight(dh) ),
            "Slack"     : CGRect( x:0,   y:MENU_BAR_HEIGHT, width:834,  height:maxheight(dh) ),
            "Terminal"  : CGRect( x:center_horizontally( dw, 1282 ), y:MENU_BAR_HEIGHT, width:1282, height:952 ),
            "kitty"     : CGRect( x:center_horizontally( dw, 1282 ), y:MENU_BAR_HEIGHT, width:1282, height:952 ),
        ]
    }(),
    1440 : {
        let dw = 1440, dh = 900
        return [
            "standard"    : CGRect( x:center_horizontally( dw, 1280 ), y:MENU_BAR_HEIGHT, width:1280, height:maxheight(dh) ),
            "Slack"     : CGRect( x:0,   y:MENU_BAR_HEIGHT, width:834,  height:maxheight(dh) ),
        ]
    }(),
];

// The AXUIElement APIs are the assistive / accessibility APIs that
// actually let you do stuff like move windows around on the screen.
//
// As of macOS 10.12 SDK they've properly annotated them for ARC so we
// don't have to manage the refcount ourselves anymore.
//
// They're still pretty unwieldy C APIs, so keeping the wrappers to do
// all the type coercion etc.

class RAXWrapper {
    let handle:AXUIElement

    init( handle:AXUIElement ) {
        self.handle = handle
    }

    var attributeNames:[String] {
        var out:CFArray? = nil
        let axerr = AXUIElementCopyAttributeNames(
            handle,
            &out
        )
        guard .success == axerr && nil != out else {
            return [String]()
        }
        let names = out as NSArray? as! [String]
        return names
    }
}

class RAXWindow: RAXWrapper {
    init( _ handle:AXUIElement ) {
        super.init( handle: handle )
    }

    var canChange:Bool {
        return self.canMove && self.canResize
    }

    var canMove:Bool {
        return getSettable( kAXPositionAttribute )
    }

    var canResize:Bool {
        return getSettable( kAXSizeAttribute )
    }

    func getSettable( _ attr:String ) -> Bool {
        var settable:DarwinBoolean = false
        AXUIElementIsAttributeSettable( self.handle, attr as NSString, &settable )
        return settable.boolValue
    }

    var position:CGPoint {
        get {
            var out:AnyObject? = nil
            let axerr = AXUIElementCopyAttributeValue( handle, kAXPositionAttribute as NSString, &out )
            guard .success == axerr && nil != out else {
                return CGPoint()
            }
            let value = out as! AXValue

            var pt = CGPoint()
            AXValueGetValue( value, AXValueType.cgPoint, &pt )
            return pt
        }
        set {
            var pt = newValue
            let value:AXValue = AXValueCreate( AXValueType.cgPoint, &pt )!
            AXUIElementSetAttributeValue( handle, kAXPositionAttribute as NSString, value )
        }
    }

    var size:CGSize {
        get {
            var out:AnyObject? = nil
            let axerr = AXUIElementCopyAttributeValue( handle, kAXSizeAttribute as NSString, &out )
            guard .success == axerr && nil != out else {
                return CGSize()
            }
            let value = out as! AXValue

            var size = CGSize()
            AXValueGetValue( value, AXValueType.cgSize, &size )
            return size
        }
        set {
            var size = newValue
            let value:AXValue = AXValueCreate( AXValueType.cgSize, &size )!
            AXUIElementSetAttributeValue( handle, kAXSizeAttribute as NSString, value )
        }
    }

    var title:String {
        var out:AnyObject? = nil
        let axerr = AXUIElementCopyAttributeValue( handle, kAXTitleAttribute as NSString, &out )
        guard .success == axerr && nil != out else {
            return ""
        }
        return out as! String
    }
}

class RAXProcess: RAXWrapper {
    let maxWindows = 20
    let pid:Int

    init( _ pid:Int ) {
        self.pid = pid
        super.init( handle: AXUIElementCreateApplication( pid_t( self.pid ) ) )
    }

    lazy var windows:[RAXWindow] = {
        var out:CFArray? = nil
        var axerr = AXUIElementCopyAttributeValues(
            self.handle,
            kAXWindowsAttribute as NSString,
            0,
            self.maxWindows,
            &out
        )
        guard .success == axerr && nil != out else {
            return [RAXWindow]()
        }

        let handles = out as NSArray? as! [AXUIElement]
        return handles.map{ RAXWindow( $0 ) }.filter{ $0.canChange }
    }()
}

class Repos {

    func apps() -> [ NSRunningApplication ] {
        let apps = NSWorkspace.shared.runningApplications
        return apps.filter { procsOfInterest.contains(($0.localizedName!) ) }
    }

    func query() {
        var qconf = [String:CGRect]()
        for app in apps() {
            let proc = RAXProcess( Int(app.processIdentifier) )
            if proc.windows.count > 0 {
                let w = proc.windows[0]
                qconf[app.localizedName!] = CGRect(
                        x:w.position.x, y:w.position.y,
                        width:w.size.width, height:w.size.height
                                                )
            }
        }

        var conf = [CGFloat:[String:CGRect]]()
        conf[screenSize.width] = qconf
        print( conf )
    }

    func doPositioning() {
        guard let conf = configurationForWidth[screenSize.width] else {
            return
        }
        for app in apps() {
            let rect = conf[app.localizedName!] ?? conf["standard"]!
            let proc = RAXProcess( Int(app.processIdentifier) )
            for w in proc.windows {
                w.position = rect.origin
                w.size = rect.size
            }
        }
    }

    func fixEmacs() {
        let task = Process()
        task.launchPath = "/usr/local/bin/emacsclient"
        task.arguments = [
            "-e",
            "(rdj-smartsize-frame-for \(Int(screenSize.width)) \(Int(screenSize.height)))"
        ]
        task.launch()
    }

    func main( _ argv:[String] ) {
        if argv.contains("-q" ) {
            query()
        }
        else {
            doPositioning()
            fixEmacs()
        }
    }
}

Repos().main( CommandLine.arguments )
