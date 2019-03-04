
Pod::Spec.new do |s|

  s.name         = "GQLFetcher"
  s.version      = `git describe --abbrev=0 --tags`
  s.summary      = "Library for fetching GraphQL data"
  s.description  = "GraphQL fetching library"
  s.homepage     = "https://github.com/Lumyk/GQLFetcher"
  s.license      = { :type => "MIT", :file => "LICENSE" }
  s.author       = { "Evgeny Kalashnikov" => "lumyk@me.com" }

  #  When using multiple platforms
  s.ios.deployment_target = "10.0"
  # s.osx.deployment_target = "10.7"
  s.watchos.deployment_target = "3.0"
  # s.tvos.deployment_target = "9.0"

  s.source       = { :git => "https://github.com/Lumyk/GQLFetcher.git", :tag => "#{s.version}" }

  s.pod_target_xcconfig = { 'SWIFT_VERSION' => '4.2' }
  s.source_files  = "Sources/**/*"

  s.dependency "PromiseKit", "6.5.2"

end
