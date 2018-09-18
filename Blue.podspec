
Pod::Spec.new do |s|



  s.name         = "Blue"
  s.version      = "0.0.3"
  s.summary      = "The easiest way to use Bluetooth."
  s.homepage     = "https://github.com/Fidetro/Blue"
  s.license      = { :type => "MIT", :file => "LICENSE" }
  s.author             = { "fidetro" => "zykzzzz@hotmail.com" }
  s.platform     = :ios, "8.0"
  s.source       = { :git => "https://github.com/Fidetro/Blue.git", :tag => "0.0.3" }
  s.source_files  = "Sources", "Sources/*.{swift}"


end
