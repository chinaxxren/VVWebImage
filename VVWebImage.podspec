Pod::Spec.new do |s|
  s.name         = 'VVWebImage'
  s.version      = '1.0.0'
  s.summary      = 'A Swift version of SDWebimage'

  s.description  = <<-DESC
                    A Swift version of SDWebimage
                   DESC

  s.homepage     = 'https://github.com/chinaxxren/VVWebImage'

  s.license      = { :type => 'MIT', :file => 'LICENSE' }

  s.author       = { 'chinaxxren' => 'jiangmingz@qq.com' }

  s.platform     = :ios, '13.0'

  s.swift_version = '5.0'

  s.source       = { :git => 'https://github.com/chinaxxren/VVWebImage.git', :tag => s.version }

  s.requires_arc = true

  s.default_subspec = 'Core'

  s.subspec 'Core' do |core|
    core.source_files = 'VVWebImage/VVWebImage/VVWebImage.h', 'VVWebImage/VVWebImage/**/*.swift'
    core.exclude_files = 'VVWebImage/VVWebImage/Extensions/MKAnnotationView+VVWebCache.swift', 'VVWebImage/VVWebImage/Filter/*'
  end

  s.subspec 'MapKit' do |mk|
    mk.source_files = 'VVWebImage/VVWebImage/Extensions/MKAnnotationView+VVWebCache.swift'
    mk.dependency 'VVWebImage/Core'
  end

  s.subspec 'Filter' do |filter|
    filter.source_files = 'VVWebImage/VVWebImage/Filter'
    filter.resources = 'VVWebImage/VVWebImage/**/*.cikernel'
    filter.dependency 'VVWebImage/Core'
  end 

end
