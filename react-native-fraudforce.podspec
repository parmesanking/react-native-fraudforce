require "json"

package = JSON.parse(File.read(File.join(__dir__, "package.json")))

Pod::Spec.new do |s|
  s.name         = "react-native-fraudforce"
  s.version      = package["version"]
  s.summary      = package["description"]
  s.homepage     = package["homepage"]
  s.license      = package["license"]
  s.authors      = package["author"]

  s.platforms    = { :ios => "10.0" }
  s.source       = { :git => "https://github.com/parmesanking/react-native-fraudforce.git", :tag => "#{s.version}" }


  s.static_framework = true
  
  s.dependency "React-Core"
  s.dependency "PerimeterX", "= 3.0.3"
  
  if Gem::Version.new(Pod::VERSION) >= Gem::Version.new('1.10.0')
    s.source_files = "ios/**/*.{h,m,mm,swift}"
    s.vendored_frameworks = '**/Prebuilt Frameworks/FraudForce.xcframework'
    s.ios.vendored_frameworks = '**/Prebuilt Frameworks/FraudForce.xcframework'
  else
    s.source_files = "ios/**/*.{h,m,mm,swift}"
  end
  
end
