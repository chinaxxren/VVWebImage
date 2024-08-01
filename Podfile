use_frameworks!

platform :ios, '13.0'

target 'VVWebImageDemo' do
	pod 'VVWebImage/Core', :path => './'
  pod 'VVWebImage/MapKit', :path => './'
  pod 'VVWebImage/Filter', :path => './'
  pod 'VVWebImage/WebP', :path => './'
end

post_install do |installer_representation|
    installer_representation.pods_project.targets.each do |target|
        target.build_configurations.each do |config|
            config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '13.0'
            config.build_settings['ONLY_ACTIVE_ARCH'] = 'NO'
            config.build_settings['BUILD_LIBRARY_FOR_DISTRIBUTION'] = 'YES'
        end
    end
end

