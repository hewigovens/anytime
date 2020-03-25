platform :ios, '13'

inhibit_all_warnings!
install! 'cocoapods', :generate_multiple_pod_projects => true

target 'AnyTime' do
  use_frameworks! :linkage => :static

  pod 'Colours'
  pod 'SnapKit'
  pod 'Reusable'
  pod 'SwiftyUserDefaults'
  pod 'FontAwesomeKit/IonIcons'
  pod 'NotificationBannerSwift'
#  pod 'FluentDarkModeKit'

  pod 'SwiftLint'
  pod 'Crashlytics'
  pod 'Fabric'

  target 'AnyTimeTests' do
    inherit! :search_paths
    # Pods for testing
  end
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
   if target.name == "Pods-AnyTime"
     puts "Updating #{target.name} to exclude Crashlytics/Fabric/Firebase for Mac Catalyst"
     target.build_configurations.each do |config|
       xcconfig_path = config.base_configuration_reference.real_path
       xcconfig = File.read(xcconfig_path)
       fws = ["Crashlytics", "Fabric"]
       new_line = "$(inherited)"
       for fw in fws
        xcconfig.sub!("-framework \"#{fw}\"", "")
        new_line += " -framework \"#{fw}\""
       end
       new_xcconfig = xcconfig + "OTHER_LDFLAGS[sdk=iphone*] =#{new_line}"
       File.open(xcconfig_path, "w") { |file| file << new_xcconfig }
     end
   end
  end
end
