#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint onchain_bridge.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'onchain_bridge'
  s.version          = '0.0.1'
  s.summary          = 'platform-specific native methods required for key functionalities within the OnChain ecosystem.'
  s.description      = <<-DESC
platform-specific native methods required for key functionalities within the OnChain ecosystem.
                       DESC
  s.homepage         = 'https://github.com/mrtnetwork'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'mrhaydari.t@gmail.com' }

  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*'
  s.dependency 'FlutterMacOS'

  s.platform = :osx, '10.11'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
  s.swift_version = '5.0'
end
