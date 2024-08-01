Pod::Spec.new do |s|
  s.name         = 'VVWebImage'
  s.version      = '1.0.0'
  s.summary      = 'A Swift version of SDWebimage'

  s.description  = <<-DESC
                    A Swift version of SDWebimage
                   DESC

  s.homepage     = 'https://github.com/chinaxxren/VVWebImage'

  s.author       = { 'chinaxxren' => 'jiangmingz@qq.com' }

  s.platform     = :ios, '13.0'

  s.swift_version = '5.0'

  s.source       = { :git => 'https://github.com/chinaxxren/VVWebImage.git', :tag => s.version }

  s.requires_arc = true

  s.default_subspec = 'Core'

  s.subspec 'Core' do |core|
    core.source_files = 'VVWebImage/VVWebImage.h', 'VVWebImage/Base/*.swift', 'VVWebImage/Extensions/*.swift'
  end

  s.subspec 'MapKit' do |mk|
    mk.source_files = 'VVWebImage/MapKit/MKAnnotationView+VVWebCache.swift'
    mk.dependency 'VVWebImage/Core'
  end

  s.subspec 'Filter' do |filter|
    filter.source_files = 'VVWebImage/Filter/*.swift'
    filter.resources = 'VVWebImage/Filter/*.cikernel'
    filter.dependency 'VVWebImage/Core'
  end
  
  s.subspec 'WebP' do |webp|
    webp.source_files = 'VVWebImage/WebP/*.{h,m,swift}'
    webp.xcconfig = {
      'USER_HEADER_SEARCH_PATHS' => '$(inherited) $(SRCROOT)/libwebp/src'
    }
    webp.dependency 'VVWebImage/Core'
    webp.dependency 'libwebp'
  end
end
