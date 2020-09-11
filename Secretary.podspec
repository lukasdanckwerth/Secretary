#
#  Be sure to run `pod spec lint Secretary.podspec' to ensure this is a
#  valid spec and to remove all comments including this before submitting the spec.
#
#  To learn more about Podspec attributes see https://guides.cocoapods.org/syntax/podspec.html
#  To see working Podspecs in the CocoaPods repo see https://github.com/CocoaPods/Specs/
#

Pod::Spec.new do |spec|
   
    spec.name         = "Secretary"
    spec.version      = "1.1.3"
    spec.summary      = "A Logging Framework for Swift"
    spec.description  = <<-DESC
    A Logging Framework for Swift.  Supports logging to standard output, error output and file.
    DESC
    
    spec.homepage       = "https://github.com/lukasdanckwerth/Secretary"
    spec.author         = { "Lukas Danckwerth" => "lukas.danckwerth@gmx.de" }
    spec.license        = "MIT"
    
    spec.source         = { :git => "https://github.com/lukasdanckwerth/Secretary.git", :tag => "#{spec.version}" }
    spec.source_files   = "Secretary/Sources/**/*.swift"
    spec.requires_arc   = true
    spec.frameworks     = 'Foundation'
    
    spec.swift_versions = "4.2"
    spec.ios.deployment_target = "10.0"
    spec.osx.deployment_target = "10.12"
    
end
