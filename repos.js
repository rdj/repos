#!/usr/bin/env osascript -l JavaScript

// Sadly, the automation bridge for javascript seems to be super buggy
// in Yosemite. This script works most of the time, but sometimes the
// system just decides it's going to fail all the automation calls. If
// you then access automation from something other than osascript, the
// system unconfuses itself and this script will start working again.
// Pretty infuriating, cause this was pretty much exactly what I
// wanted.

"use strict";

var scripting = Application.currentApplication();
scripting.includeStandardAdditions = true;

var sys = Application('System Events');

ObjC.import('Cocoa');
var screenSize = $.NSScreen.mainScreen.frame.size;

// Objects are for future per-proc config
var procsOfInterest = {
    "1Password 4"   : {},
    "Google Chrome" : {},
    "Chromium"      : {},
    "EchofonLite"   : {},
    "iCal"          : {},
    "GitX"          : {},
    "Calendar"      : {},
    "HipChat"       : {},
    "iTerm"         : {},
    "iTunes"        : {},
    "Mail"          : {},
    "Mailplane 3"   : {},
    "Messages"      : {},
    "Safari"        : {},
    "Things"        : {},
    "Terminal"      : {},
    "Xcode"         : {},
};

var MENU_BAR_HEIGHT = 22,
    DOCK_HEIGHT = 64;

function center_horizontally( dw, ww ) {
    return ( dw - ww ) / 2;
}

function maxheight( dh ) {
    return dh - MENU_BAR_HEIGHT - DOCK_HEIGHT;
}

function center_vertically( dh, wh ) {
    var effective_display_height = maxheight( dh );
    var y_offset_from_menu = ( effective_display_height - wh ) / 2;
    return MENU_BAR_HEIGHT + y_offset_from_menu;
}

function centered( dw, dh, ww, wh ) {
    var wx = center_horizontally( dw, ww ),
        wy = center_vertically( dh, wh );
    return { position: [ wx, wy ], size: [ ww, wh ] };
}

var configurationForWidth = {
    "2560" : ( function () {
        var dw = 2560, dh = 1440;
        return {
            "standard"    : centered( dw, dh, 1600, 1200 ),
            "EchofonLite" : centered( dw, dh, 489, 1080 ),
            "HipChat"     : { position: [   0, MENU_BAR_HEIGHT ], size: [  768, maxheight( dh ) ] },
            "Messages"    : { position: [ 996, 440 ],             size: [  768,  512 ] },
            "iTerm"       : { position: [ dw - 554,  693 ],       size: [  554,  388 ] },
            "Terminal"    : { position: [ 694, MENU_BAR_HEIGHT ], size: [ 1202, 1341 ] },
            "Things"      : centered( dw, dh, 768, 512 ),
        };
    } )(),
};

function sysProc( proc ) {
    return sys.processes.whose( { name: proc } );
}

function isRunning( proc ) {
    return sysProc(proc).length > 0;
}

function getSize( proc ) {
    return sysProc(proc)[0].windows[0].size();
}

function getPosition( proc ) {
    return sysProc(proc)[0].windows[0].position();
}

function query() {
    var props = {};

    Object.keys( procsOfInterest ).forEach( function ( proc ) {
        if ( isRunning( proc ) ) {
            props[proc] = {
                size: getSize( proc ),
                position: getPosition( proc ),
            };
        }
    } );

    var config = {};
    config[String(screenSize.width)] = props;

    console.log( JSON.stringify( config ) );
}

function doPositioning() {
    var config = configurationForWidth[ String( screenSize.width ) ];
    if ( !config ) {
        throw new Error( "No configuration for width " + screenSize.width );
    }

    Object.keys( procsOfInterest ).forEach( function ( proc ) {
        var spec = config[proc];
        if ( !spec ) {
            spec = config["standard"];
        }
        if ( isRunning( proc ) ) {
            var windows = sysProc(proc)[0].windows;
            for ( var i = 0; i < windows.length; i++ ) {
                var wnd = windows[i];
                wnd.position = spec.position;
                wnd.size = spec.size;
            }
        }
    } );
}

function run(argv) {
    var querying = ( -1 != argv.indexOf( '-q' ) );

    if ( querying ) {
        query();
    }
    else {
        doPositioning();
        scripting.doShellScript( "/usr/local/bin/emacsclient -e '(rdj-smartsize-frame-for " + screenSize.width + " " + screenSize.height + ")' > /dev/null" );
    }
}
