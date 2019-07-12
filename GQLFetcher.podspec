
Pod::Spec.new do |s|

  s.name         = "GQLFetcher"
  s.version      = "1.0.5"
  s.summary      = "Library for fetching GraphQL data"
  s.description  = "GraphQL fetching library, can be used only with GQL Schema library for describing requests"
  s.homepage     = "https://github.com/Lumyk/GQLFetcher"
  s.license      = { :type => "MIT", :file => "LICENSE" }
  s.author       = { "Evgeny Kalashnikov" => "lumyk@me.com" }

  #  When using multiple platforms
  s.ios.deployment_target = "10.0"
  # s.osx.deployment_target = "10.7"
  s.watchos.deployment_target = "3.0"
  # s.tvos.deployment_target = "9.0"

  s.source       = { :git => "https://github.com/Lumyk/GQLFetcher.git", :tag => "#{s.version}" }

  s.swift_version = '5.0'
  s.source_files  = "Sources/**/*"

  s.dependency "PromiseKit", "6.8.4"
  s.dependency "GQLSchema", "1.1.1"


end
