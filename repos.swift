#!/usr/bin/env xcrun swift

import AppKit

// The CGWindow APIs are the easiest way to enumerate current windows
// but sadly this is completely disconnected from the accessibility
// APIs that let you actually resize/move them. Disconnected to the
// point that there's no way to correlate the windows between the two
// lists, in fact.
class RWindow {
    class var windows:[RWindow] {
        let kCGNullWindowID = CGWindowID(0) // CGWindow.h uses a #define
    
        var windowsRaw:[AnyObject] = CGWindowListCopyWindowInfo(
                CGWindowListOption(
                    kCGWindowListOptionOnScreenOnly
                    | kCGWindowListExcludeDesktopElements
                ),
                kCGNullWindowID
            ).takeRetainedValue()
        
        return windowsRaw.map { RWindow( $0 as [NSObject: AnyObject] ) }.filter { $0.isVisible }
    }
    
    private let dict:[NSObject: AnyObject]
    
    init( _ d:[NSObject: AnyObject] ) {
        self.dict = d
    }

    var alpha:CGFloat {
        return self.dict[kCGWindowAlpha] as CGFloat
    }

    var bounds:CGRect {
        var boundsDict = self.dict[kCGWindowBounds] as [NSObject: AnyObject]
        var b = CGRect()
        CGRectMakeWithDictionaryRepresentation( boundsDict, &b )
        return b
    }
    
    var id:Int {
        return self.dict[kCGWindowNumber] as Int
    }

    var isVisible:Bool {
        return alpha > CGFloat(0)
    }

    var name:String {
        return ( self.dict[kCGWindowName] as? String ) ?? ""
    }

    var owner:String {
        return self.dict[kCGWindowOwnerName] as String
    }

    var pid:Int {
        return self.dict[kCGWindowOwnerPID] as Int
    }
}

// The AXUIElement APIs are the assistive / accessibility APIs that do
// actually let you do stuff like move stuff around on the screen.
// They are ancient and annoying CF APIs that lack modern annotation
// so are unwieldy to use from modern (ARC/Swift) code.
class RAXProcess {
    let pid:Int
    private let handle:AXUIElement
    
    init( _ pid:Int ) {
        self.pid = pid
        self.handle = AXUIElementCreateApplication( pid_t( self.pid ) ).takeRetainedValue()
    }

    lazy var windows:[RAXWindow] = self.fetchWindows()

    private func fetchWindows() -> [RAXWindow] {
        // AXAttributeConstants.h
        // #define kAXWindowsAttribute				CFSTR("AXWindows")
        let kAXWindowsAttribute = "AXWindows"
        let maxWindows = 20
        var out:Unmanaged<CFArray>? = nil
        var axerr = AXUIElementCopyAttributeValues(
            handle,
            kAXWindowsAttribute,
            0,
            maxWindows,
            &out
        );
        if AXError(kAXErrorSuccess) != axerr || nil == out {
            return [RAXWindow]()
        }

        let handles:[AnyObject] = out!.takeRetainedValue()
        return handles.map{ RAXWindow( $0 as AXUIElement ) }
    }
}

class RAXWindow {
    let handle:AXUIElement
    
    init( _ handle:AXUIElement ) {
        self.handle = handle
    }
}

var windows:[RWindow] = RWindow.windows

var pidsDone = [Int]()

for window in windows {
    println( "\(window.pid).\(window.id) \(window.owner) \"\(window.name)\" \(window.bounds)" )

    if contains( pidsDone, window.pid ) {
        continue
    }
    pidsDone.append( window.pid )

    var proc = RAXProcess( window.pid )
    for w in proc.windows {
        println( w.handle )
    }
    

    // var axapp = AXUIElementCreateApplication( pid_t(window.pid) ).takeRetainedValue()
    // var axwindowout: Unmanaged<AnyObject>? = nil
    // var axerr = AXUIElementCopyAttributeValue(
    //     axapp,
    //     "AXMainWindow",
    //     &axwindowout );
    // if axerr == AXError(kAXErrorSuccess) {
    //     if ( nil == axwindowout ) {
    //         continue;
    //     }
    //     let axwindow = axwindowout!.takeRetainedValue() as AXUIElement
    //     println( axwindow )
    // }
    
}







