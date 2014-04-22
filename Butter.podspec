Pod::Spec.new do |spec|
  spec.name         = "Butter"
  spec.version      = "0.2.0"
  spec.summary      = "A big shot of epicness for AppKit. It's time to put a jetpack on your tricycle."
  spec.homepage     = "https://github.com/ButterKit/Butter"
  spec.authors      = { "Indragie Karunaratne" => "indragiek",
                        "Jonathan Willing" => "jwilling" }
  spec.source       = { :git => "https://github.com/ButterKit/Butter.git", :tag => "#{spec.version}" }
  spec.license      = { :type => "MIT", :file => "LICENSE.md" }
  spec.description  = "Butter is a framework for OS X that seeks to provide a set of commonly used controls which are full replacements for their cell-based AppKit counterparts."

  spec.platform     = :osx
  spec.frameworks   = 'Cocoa', 'QuartzCore'
  spec.requires_arc = true

  spec.osx.deployment_target = '10.8'

  spec.source_files = "Butter/**/*.{h,m}"
  spec.exclude_files = "Butter/en.lproj"
  spec.private_header_files = "Butter/Private/*.h"
end
