Pod::Spec.new do |s|
  s.name         = "KTPullToRefresh"
  s.version      = "0.1.0"
  s.summary      = "KTPullToRefresh"
  s.description  = "A simple iPhone TableViewController for adding pull-to-refresh functionality"
  s.homepage     = "https://github.com/MessageDream/KTPullToRefresh"
  s.screenshots  = ""

  # ―――  Spec License  ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  s.license      = { :type => "MIT", :file => "LICENSE" }

  # ――― Author Metadata  ――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  s.author             = { "jayden" => "jaydenzhao@outlook.com" }
  # ――― Platform Specifics ――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  s.platform     = :ios, "6.0"
  # ――― Source Location ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  s.source       = { :git => "https://github.com/MessageDream/KTPullToRefresh.git", :tag => "0.1.0" }
  # ――― Source Code ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  s.source_files  = "classes/*.{h,m}"
  # ――― Project Settings ――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  s.requires_arc = true
end