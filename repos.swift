#!/usr/bin/env xcrun swift

import AppKit

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
        )
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

    private func getSettable( attr:String ) -> Bool {
        var settable:Boolean = 0
        AXUIElementIsAttributeSettable( handle, attr, &settable )
        return 0 != settable
    }

    var canChange:Bool {
        return self.canMove && self.canResize
    }
    
    // #define kAXPositionAttribute				CFSTR("AXPosition")
    private let kAXPositionAttribute = "AXPosition"

    var canMove:Bool {
        return getSettable( kAXPositionAttribute )
    }

    var position:CGPoint {
        get {
            var pt = CGPoint()
            var out:Unmanaged<AnyObject>? = nil
            let axerr = AXUIElementCopyAttributeValue( handle, kAXPositionAttribute, &out )
            if AXError(kAXErrorSuccess) != axerr || nil == out {
                return pt
            }
            var value = out!.takeRetainedValue() as AXValue
            AXValueGetValue( value, kAXValueCGPointType, &pt )
            return pt
        }
        set {
            var pt = newValue
            var value:AXValue = AXValueCreate( kAXValueCGPointType, &pt ).takeRetainedValue()
            AXUIElementSetAttributeValue( handle, kAXPositionAttribute, value )
        }
    }

    // #define kAXSizeAttribute				CFSTR("AXSize")
    private let kAXSizeAttribute = "AXSize"

    var canResize:Bool {
        return getSettable( kAXSizeAttribute )
    }

    var size:CGSize {
        get {
            var size = CGSize()
            var out:Unmanaged<AnyObject>? = nil
            let axerr = AXUIElementCopyAttributeValue( handle, kAXSizeAttribute, &out )
            if AXError(kAXErrorSuccess) != axerr || nil == out {
                return size
            }
            var value = out!.takeRetainedValue() as AXValue
            AXValueGetValue( value, kAXValueCGSizeType, &size )
            return size
        }
        set {
            var size = newValue
            var value:AXValue = AXValueCreate( kAXValueCGSizeType, &size ).takeRetainedValue()
            AXUIElementSetAttributeValue( handle, kAXSizeAttribute, value )
        }
    }
    
    // #define kAXTitleAttribute				CFSTR("AXTitle")
    private let kAXTitleAttribute = "AXTitle"
    var title:String {
        var out:Unmanaged<AnyObject>? = nil
        let axerr = AXUIElementCopyAttributeValue( handle, kAXTitleAttribute, &out )
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







