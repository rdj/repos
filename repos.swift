#!/usr/bin/env xcrun swift

import AppKit

let screenSize = NSScreen.mainScreen()!.frame.size

let procsOfInterest = [
    "1Password 4",
    "Google Chrome",
    "Chromium",
    "EchofonLite",
    "iCal",
    "GitX",
    "Calendar",
    "HipChat",
    "iTerm",
    "iTunes",
    "Mail",
    "Mailplane 3",
    "Messages",
    "Safari",
    "Things",
    "Terminal",
    "Xcode",
];

let MENU_BAR_HEIGHT = 22
let DOCK_HEIGHT = 64

func center_horizontally( dw:Int, _ ww:Int ) -> Int {
    return ( dw - ww ) / 2
}

func maxheight( dh:Int ) -> Int {
    return dh - MENU_BAR_HEIGHT - DOCK_HEIGHT
}

func center_vertically( dh:Int, _ wh:Int ) -> Int {
    let effective_display_height = maxheight( dh )
    let y_offset_from_menu = ( effective_display_height - wh ) / 2
    return MENU_BAR_HEIGHT + y_offset_from_menu
}

func centered( dw:Int, _ dh:Int, _ ww:Int, _ wh:Int ) -> CGRect {
    let wx = center_horizontally( dw, ww )
    let wy = center_vertically( dh, wh )
    return CGRect( x:wx, y:wy, width:ww, height:wh )
}

var configurationForWidth:[CGFloat:[String:CGRect]] = [
    2560 : {
        let dw = 2560, dh = 1440
        return [
            "standard"    : centered( dw, dh, 1600, 1200 ),
            "EchofonLite" : centered( dw, dh,  489, 1080 ),
            "Things"      : centered( dw, dh,  768,  512 ),
            "HipChat"     : CGRect( x:0,        y:MENU_BAR_HEIGHT, width:768,  height:maxheight( dh ) ),
            "iTerm"       : CGRect( x:dw - 554, y:693,             width:554,  height:388 ),
            "Messages"    : CGRect( x:996,      y:440,             width:768,  height:512 ),
            "Terminal"    : CGRect( x:694,      y:MENU_BAR_HEIGHT, width:1202, height:1341 ),
        ]
    }(),
    1680 : {
        let dw = 1680, dh = 1050
        return [
            "standard"    : CGRect( x:200, y:MENU_BAR_HEIGHT, width:1280, height:maxheight(dh) ),
            "EchofonLite" : CGRect( x:center_horizontally( dw, 489 ), y:MENU_BAR_HEIGHT, width:498, height:maxheight(dh) ),
            "HipChat"     : CGRect( x:0,   y:MENU_BAR_HEIGHT, width:530,  height:maxheight(dh) ),
        ]
    }(),
    1440 : {
        let dw = 1440, dh = 900
        return [
            "standard"    : CGRect( x:center_horizontally( dw, 1280 ), y:MENU_BAR_HEIGHT, width:1280, height:maxheight(dh) ),
            "EchofonLite" : centered( dw, dh, 489, maxheight( dh ) ),
            "HipChat"     : CGRect( x:0,   y:MENU_BAR_HEIGHT, width:500,  height:maxheight(dh) ),
        ]
    }(),
];

// RJTODO - In 10.11, they rewrote the AXValue.h header so that you
// can do things like
//   AXValueType.CGPoint
// instead of
//   AXValueType(rawValue:kAXValueCGPointType )!
//
// In XCode 7b5 it appears that to get from CFArray to a Swift array,
// you have to cast through NSArray.

// The AXUIElement APIs are the assistive / accessibility APIs that
// actually let you do stuff like move windows around on the screen.
// They are ancient and annoying CF APIs that lack modern annotation
// so are unwieldy to use from modern (ARC/Swift) code.
//
// RAX prefix for wrapping AXUIElement and associated stuff, which are
// ancient CF APIs that don't even have ARC annotations, so they're a
// bit unwieldy to use from Swift. Quick review:
//
// takeRetainedValue = Create/Copy Rule =
//                     You called an API that returned a live object
//                     that hasn't been autoreleased, so it's your job
//                     to release it.
//
// takeUnretainedValue = Get Rule =
//                       You called an API that returned a live object
//                       that has been autoreleased, so you don't need
//                       to worry about it unless it needs to live
//                       past this runloop, in which case you'll have
//                       to retain it.
//

// AXAttributeConstants.h uses #defines instead of real constants ...
struct RAXAttributeConstants {
    // #define kAXPositionAttribute				CFSTR("AXPosition")
    static let Position = "AXPosition"
    // #define kAXSizeAttribute				CFSTR("AXSize")
    static let Size = "AXSize"
    // #define kAXTitleAttribute				CFSTR("AXTitle")
    static let Title = "AXTitle"
    // #define kAXWindowsAttribute				CFSTR("AXWindows")
    static let Windows = "AXWindows"
}

class RAXWrapper {
    private let handle:AXUIElement

    private init( handle:AXUIElement ) {
        self.handle = handle
    }

    var attributeNames:[String] {
        var out:CFArray? = nil
        let axerr = AXUIElementCopyAttributeNames(
            handle,
            &out
        )
        if AXError.Success != axerr || nil == out {
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
        return getSettable( RAXAttributeConstants.Position )
    }

    var canResize:Bool {
        return getSettable( RAXAttributeConstants.Size )
    }

    private func getSettable( attr:String ) -> Bool {
        var settable:DarwinBoolean = false
        AXUIElementIsAttributeSettable( handle, attr, &settable )
        return Bool(settable)
    }

    var position:CGPoint {
        get {
            var out:AnyObject? = nil
            let axerr = AXUIElementCopyAttributeValue( handle, RAXAttributeConstants.Position, &out )
            if AXError.Success != axerr || nil == out {
                return CGPoint()
            }
            let value = out as! AXValue
            
            var pt = CGPoint()
            AXValueGetValue( value, AXValueType( rawValue:kAXValueCGPointType )!, &pt )
            return pt
        }
        set {
            var pt = newValue
            let value:AXValue = AXValueCreate( AXValueType( rawValue:kAXValueCGPointType )!, &pt )!.takeRetainedValue()
            AXUIElementSetAttributeValue( handle, RAXAttributeConstants.Position, value )
        }
    }

    var size:CGSize {
        get {
            var out:AnyObject? = nil
            let axerr = AXUIElementCopyAttributeValue( handle, RAXAttributeConstants.Size, &out )
            if AXError.Success != axerr || nil == out {
                return CGSize()
            }
            let value = out as! AXValue

            var size = CGSize()
            AXValueGetValue( value, AXValueType( rawValue:kAXValueCGSizeType )!, &size )
            return size
        }
        set {
            var size = newValue
            let value:AXValue = AXValueCreate( AXValueType( rawValue:kAXValueCGSizeType )!, &size )!.takeRetainedValue()
            AXUIElementSetAttributeValue( handle, RAXAttributeConstants.Size, value )
        }
    }
    
    var title:String {
        var out:AnyObject? = nil
        let axerr = AXUIElementCopyAttributeValue( handle, RAXAttributeConstants.Title, &out )
        if AXError.Success != axerr || nil == out {
            return ""
        }
        return out as! String
    }
}

class RAXProcess: RAXWrapper {
    private let maxWindows = 20
    let pid:Int
        
    init( _ pid:Int ) {
        self.pid = pid
        super.init( handle: AXUIElementCreateApplication( pid_t( self.pid ) ).takeRetainedValue() )
    }

    lazy var windows:[RAXWindow] = {
        var out:CFArray? = nil
        var axerr = AXUIElementCopyAttributeValues(
            self.handle,
            RAXAttributeConstants.Windows,
            0,
            self.maxWindows,
            &out
        )
        if AXError.Success != axerr || nil == out {
            return [RAXWindow]()
        }

        let handles = out as NSArray? as! [AXUIElement]
        return handles.map{ RAXWindow( $0 ) }.filter{ $0.canChange }
    }()
}

func apps() -> [ NSRunningApplication ] {
    let apps = NSWorkspace.sharedWorkspace().runningApplications 
    return apps.filter { procsOfInterest.contains(($0.localizedName!) ) }
}

func query() {
    var qconf = [String:CGRect]()
    for app in apps() {
        let proc = RAXProcess( Int(app.processIdentifier) )
        if proc.windows.count > 0 {
            let w = proc.windows[0]
            qconf[app.localizedName!] = CGRectMake(
                w.position.x, w.position.y,
                w.size.width, w.size.height
            )
        }
    }

    var conf = [CGFloat:[String:CGRect]]()
    conf[screenSize.width] = qconf
    print( conf )
}

func doPositioning() {
    let conf = configurationForWidth[screenSize.width]!
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
    let task = NSTask()
    task.launchPath = "/usr/local/bin/emacsclient"
    task.arguments = [
        "-e",
        "(rdj-smartsize-frame-for \(Int(screenSize.width)) \(Int(screenSize.height)))"
    ]
    task.launch()
}

func main( argv:[String] ) {
    if argv.contains("-q" ) {
        query()
    }
    else {
        doPositioning()
        fixEmacs()
    }
}

main( Process.arguments )
