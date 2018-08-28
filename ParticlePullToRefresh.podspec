Pod::Spec.new do |s|
  s.name         = "ParticlePullToRefresh"
  s.version      = "0.1"
  s.summary      = "Custom pull-to-refresh with animated particle system"
  s.homepage     = "https://github.com/10clouds/ParticlePullToRefresh-iOS"
  s.license      = { :type => "MIT", :file => "LICENSE" }
  s.author             = { "Alex Demchenko" => "alexdemchenko@yahoo.com" }
  s.social_media_url   = "https://twitter.com/10clouds"
  s.ios.deployment_target = "11.0"
  s.swift_version = "4.1"
  s.source       = { :git => "https://github.com/10clouds/ParticlePullToRefresh-iOS.git", :tag => s.version.to_s }
  s.source_files  = "Sources/**/*"
  s.frameworks  = "Foundation"
end
