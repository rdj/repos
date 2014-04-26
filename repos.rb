#!/usr/bin/env ruby -w

# MacRuby
framework 'AppKit'

options = { :query => false }

if ARGV.include? '-q'
  options[:query] = true
end

if ARGV.include? '-s'
  options[:script] = true
end

# require 'optparse'
# OptionParser.new do |opts|
#   opts.banner = 'Usage: repos.rb [options]'

#   opts.on( '-q', '--query', 'Query rather than set positioning' ) do |q|
#     options[:query] = q
#   end

#   opts.on( '-s', '--script', "Show the repositioning script but don't execute it" ) do |s|
#     options[:script] = s
#   end

#   opts.on_tail '-h', '--help', 'Show this message' do
#     puts opts
#     exit
#   end
# end.parse!

def first_window_of( s ) %Q{the first window of process "#{s}"} end
def all_windows_of( s ) %Q{windows of process "#{s}"} end
WindowsOfInterest = {
  :adium_chat     => first_window_of('Adium')   + ' whose name is not "Contacts"',
  :adium_contacts => first_window_of('Adium')   + ' whose name is "Contacts"',
  :chrome         => all_windows_of('Google Chrome'),
  :chromium       => first_window_of('Chromium'),
  :echofon        => first_window_of('EchofonLite'),
  :firefox        => first_window_of('Firefox') + ' whose name is not "Downloads"',
  :ical           => first_window_of('iCal'),
  :gitx           => all_windows_of( 'GitX' ),
  :googlecal      => first_window_of('Calendar'),
  :iphone_docs    => first_window_of('iPhone Pre-release Docs'),
  :iterm          => first_window_of('iTerm'),
  :itunes         => first_window_of('iTunes'),
  :jquery_api     => first_window_of('jQuery API'),
  :mail           => first_window_of('Mail'),
  :mailplane      => first_window_of('Mailplane 3'),
  :messages       => first_window_of('Messages'),
  :propane        => first_window_of('Propane'),
  :rails_api      => first_window_of('Rails API'),
  :safari         => first_window_of('Safari'),
  :terminal       => first_window_of('Terminal'),
  :tweetie        => first_window_of('Tweetie') + ' whose name is "Tweetie"',
  :xcode          => all_windows_of('Xcode'),
}

CommonConfiguration = {
  :standard    => { :position => [0, 0], :size => [1024, 768] }, # override this
  :chrome      => :standard,
  :chromium    => :standard,
  :firefox     => :standard,
  :gitx        => :standard,
  :googlecal   => :standard,
  :ical        => :standard,
  :iphone_docs => :standard,
  :iterm       => :terminal,
  :itunes      => :standard,
  :jquery_api  => :standard,
  :mail        => :standard,
  :mailplane   => :standard,
  :rails_api   => :standard,
  :safari      => :standard,
  :terminal    => :standard,
  :xcode       => :standard,
}

PropertiesOfInterest = [ :position, :size ]

MenuBarHeight = 22
DockHeight = 64

def center_horizontally( dw, ww )
  ( dw - ww ) / 2
end

def center_vertically( dh, wh )
  effective_display_height = dh - MenuBarHeight - DockHeight
  y_offset_from_menu = ( effective_display_height - wh ) / 2
  MenuBarHeight + y_offset_from_menu
end

def centered( dw, dh, ww, wh )
  wx, wy = center_horizontally( dw, ww ), center_vertically( dh, wh )
  { :position => [ wx, wy ], :size => [ ww, wh ] }
end

ConfigurationForWidth = {
  2560 => begin # 2560x1440
     dw, dh = 2560, 1440
    {
      :standard       => centered( dw, dh, 1600, 1200 ),

      :adium_chat     => { :position => [ dw - 501 , dh - 357 ],     :size => [ 501,  357 ] },
      :adium_contacts => { :position => [ dw - 200, MenuBarHeight],  :size => [ 200, 397] },
      :echofon        => centered( dw, dh, 489, 1080 ),
      :messages       => { :position => [ 996,      440 ],           :size => [  768,  512  ] },
      :propane        => { :position => [ 0,        MenuBarHeight ], :size => [  530, 1417  ] },

      :iterm          => { :position => [ dw - 554,  693 ], :size => [  554,  388  ] },

      :terminal       => { :position => [694, MenuBarHeight],    :size => [1202, 1341]   },
    }
  end,
  1920 => {
    :standard       => { :position => [  320,  72 ], :size => [ 1280, 1024  ] },

    :adium_chat     => { :position => [    0, 843 ], :size => [  501,  357  ] },
    :adium_contacts => { :position => [    0,  MenuBarHeight ], :size => [  137,  416  ] },
    :propane        => { :position => [ 1388, 836 ], :size => [  530,  362  ] },
    :echofon        => { :position => [ 1418, 293 ], :size => [  501,  550  ] },
    :terminal       => { :position => [  320,  72 ], :size => [ 1281, 1069  ] },
  },
  1680 => {
    :standard       => { :position => [  200,  MenuBarHeight ], :size => [ 1280, 950  ] },

    :adium_chat     => { :position => [ 1179, 645 ], :size => [  501, 357  ] },
    :adium_contacts => { :position => [ 1533,  MenuBarHeight ], :size => [  150, 378  ] },
    :propane        => { :position => [    0,  MenuBarHeight ], :size => [  530, 980  ] },
  },
  1440 => begin dw, dh = 1440, 900
  {
    :standard => begin ww = 1280
    {
      :position => [ center_horizontally( dw, ww ), MenuBarHeight ],
      :size     => [ ww, dh - MenuBarHeight - DockHeight ]
    } end,

    :adium_contacts => begin ww = 150
    {
      :position => [ dw - ww, MenuBarHeight ],
      :size => [ ww, dh - MenuBarHeight - DockHeight - 350 ],
    } end,

    :adium_chat => begin ww, wh = 500, 350
    {
      :position => [ dw - ww, dh - wh - DockHeight ],
      :size => [ ww, wh ]
    } end,

    :propane =>
    {
      :position => [ 0, MenuBarHeight ],
      :size => [ 500, dh - MenuBarHeight - DockHeight ],
    },

    :messages => centered( dw, dh, 768, 512 ),
    :echofon  => centered( dw, dh, 489, dh - MenuBarHeight - DockHeight ),

  } end,
  1280 => {
    :standard       => { :position => [0, MenuBarHeight],      :size => [1280, 694]    },

    :adium_chat     => { :position => [778, 380],   :size => [501, 357]     },
    :adium_contacts => { :position => [1166, MenuBarHeight],   :size => [114, 130]     },
    :echofon        => { :position => [780, MenuBarHeight],    :size => [500, 690]     },
  },
}

def do_apple_script(s)
  if result = NSAppleScript.alloc.initWithSource(s).executeAndReturnError(nil)
    # Return an array of the values (AppleScript uses 1-based indexing)
    (1..result.numberOfItems).map do |i|
      result.descriptorAtIndex( i ).int32Value
    end
  end
end



main_display_width = Integer( NSScreen.mainScreen.frame.size.width )
main_display_height = Integer( NSScreen.mainScreen.frame.size.height )

if config = ConfigurationForWidth[main_display_width]
  config = CommonConfiguration.merge config
end


AppIsRunningSnippet =  <<'END'
global processes
tell application "System Events" to get displayed name of every process
set processes to the result
on appIsRunning( appName )
  processes contains appName
end appIsRunning
END


if options[:query]

  window_properties = []

  WindowsOfInterest.keys.map{ |k| k.to_s }.sort.each do |ks|
    key = ks.to_sym
    spec = WindowsOfInterest[key]
    props = {}
    PropertiesOfInterest.each do |prop|
      proc_name = spec.match( /process[ ](".*?")/ )[1]
      prop_value = do_apple_script( AppIsRunningSnippet + <<"END" )
if appIsRunning( #{proc_name} )
  tell application "System Events" to get the #{prop} of #{spec}
end if
END
      props[prop] = prop_value unless prop_value.empty?
    end

    window_properties << [ key, props ] unless props.empty?
  end

  max_key_length = WindowsOfInterest.keys.map{ |k| k.to_s.length }.max
  max_pos_x = window_properties.map{ |a| a[1][:position][0].to_s.length }.max
  max_pos_y = window_properties.map{ |a| a[1][:position][1].to_s.length }.max
  max_size_x = window_properties.map{ |a| a[1][:size][0].to_s.length }.max
  max_size_y = window_properties.map{ |a| a[1][:size][1].to_s.length }.max

  if standard_props = config ? config[:standard] : nil
    window_properties.unshift [ :standard, standard_props ]
  end

  puts "  #{main_display_width} => {"
  print window_properties.map{ |pa|
    key, props = *pa
    [
      "    ",
        sprintf( ":%-#{max_key_length}s => ", key ),
        if key != :standard && props == standard_props
          [ ":standard" ]
        else
          props[:position] = [0,0] if props[:position].nil? || props[:position].count != 2
          props[:size] = [0,0] if props[:size].nil? || props[:size].count != 2
          [
            "{ ",
              sprintf( ":position => [ %#{max_pos_x}d, %#{max_pos_y}d ]", *( props[:position] || [ 0,0 ] ) ),
              ", ",
              sprintf( ":size => [ %#{max_size_x}d, %#{max_size_y}d  ]", *( props[:size] || [ 0,0 ] ) ),
            " }",
          ]
        end,
      ",\n",
    ]
  }.flatten.join
  puts "  }"

else

  script = AppIsRunningSnippet

  if config.nil?
    raise "No configuration for main display width #{main_display_width}"
  end

  config.each do |window,props|

    unless win_spec = WindowsOfInterest[window]
      warn "No such window #{window}" unless window == :standard
      next
    end

    proc_name = win_spec.match( /process[ ](".*?")/ )[1]

    # Allow shortcuts for "the same as"
    while props.is_a? Symbol
      props = config[props]
    end

    PropertiesOfInterest.each do |prop|
      value = '{' + props[prop].join(',') + '}'
      script += <<"END"
try
  if appIsRunning( #{proc_name} ) then
    tell application "System Events" to set the #{prop} of #{win_spec} to #{value}
  end if
end try
END
    end

  end

  if options[:script]
    puts script
  else
    do_apple_script script
    system %Q{/usr/local/bin/emacsclient -e '(rdj-smartsize-frame-for #{main_display_width} #{main_display_height})' > /dev/null}
  end
end
