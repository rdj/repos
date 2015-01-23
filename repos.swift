#!/usr/bin/env xcrun swift

import AppKit

// The AXUIElement APIs are the assistive / accessibility APIs that do
// actually let you do stuff like move stuff around on the screen.
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

class RAXProcess {
    private let handle:AXUIElement
    private let maxWindows = 20
    let pid:Int
        
    init( _ pid:Int ) {
        self.pid = pid
        self.handle = AXUIElementCreateApplication( pid_t( self.pid ) ).takeRetainedValue()
    }

    lazy var windows:[RAXWindow] = {
        var out:Unmanaged<CFArray>? = nil
        var axerr = AXUIElementCopyAttributeValues(
            self.handle,
            RAXAttributeConstants.Windows,
            0,
            self.maxWindows,
            &out
        )
        if AXError(kAXErrorSuccess) != axerr || nil == out {
            return [RAXWindow]()
        }

        let handles:[AnyObject] = out!.takeRetainedValue()
        return handles.map{ RAXWindow( $0 as AXUIElement ) }
    }()
}

class RAXWindow {
    private let handle:AXUIElement
    
    init( _ handle:AXUIElement ) {
        self.handle = handle
    }

    var attributeNames:[String] {
        var out:Unmanaged<CFArray>? = nil
        var axerr = AXUIElementCopyAttributeNames(
            handle,
            &out
        )
        if AXError(kAXErrorSuccess) != axerr || nil == out {
            return [String]()
        }
        let names:[AnyObject] = out!.takeRetainedValue()
        return names.map{ $0 as String }
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
        var settable:Boolean = 0
        AXUIElementIsAttributeSettable( handle, attr, &settable )
        return 0 != settable
    }

    var position:CGPoint {
        get {
            var out:Unmanaged<AnyObject>? = nil
            let axerr = AXUIElementCopyAttributeValue( handle, RAXAttributeConstants.Position, &out )
            if AXError(kAXErrorSuccess) != axerr || nil == out {
                return CGPoint()
            }
            var value = out!.takeRetainedValue() as AXValue
            
            var pt = CGPoint()
            AXValueGetValue( value, kAXValueCGPointType, &pt )
            return pt
        }
        set {
            var pt = newValue
            var value:AXValue = AXValueCreate( kAXValueCGPointType, &pt ).takeRetainedValue()
            AXUIElementSetAttributeValue( handle, RAXAttributeConstants.Position, value )
        }
    }

    var size:CGSize {
        get {
            var out:Unmanaged<AnyObject>? = nil
            let axerr = AXUIElementCopyAttributeValue( handle, RAXAttributeConstants.Size, &out )
            if AXError(kAXErrorSuccess) != axerr || nil == out {
                return CGSize()
            }
            var value = out!.takeRetainedValue() as AXValue

            var size = CGSize()
            AXValueGetValue( value, kAXValueCGSizeType, &size )
            return size
        }
        set {
            var size = newValue
            var value:AXValue = AXValueCreate( kAXValueCGSizeType, &size ).takeRetainedValue()
            AXUIElementSetAttributeValue( handle, RAXAttributeConstants.Size, value )
        }
    }
    
    var title:String {
        var out:Unmanaged<AnyObject>? = nil
        let axerr = AXUIElementCopyAttributeValue( handle, RAXAttributeConstants.Title, &out )
        if AXError(kAXErrorSuccess) != axerr || nil == out {
            return ""
        }
        return out!.takeRetainedValue() as String
    }
}

var apps = NSWorkspace.sharedWorkspace().runningApplications

for app in apps {
    var printed = false

    var proc = RAXProcess( Int(app.processIdentifier) )
    for w in proc.windows.filter( { $0.canChange } ) {
        if !printed {
            println( "\(app.processIdentifier) \(app.localizedName!!)" )
        }

        println( " - (\(Int(w.position.x)), \(Int(w.position.y))) \(Int(w.size.width))x\(Int(w.size.height)) <\(w.title)>" )
        // if w.canChange {
        //     w.position = CGPointMake( 480, 99 )
        //     w.size = CGSizeMake( 1600, 1200 )
        // }
    }
}







