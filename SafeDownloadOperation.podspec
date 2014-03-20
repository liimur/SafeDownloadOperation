Pod::Spec.new do |s|
  s.name         = "SafeDownloadOperation"
  s.version      = "1.0"
  s.summary      = "Helpful utilities for Wholeapp"
  s.description  = "Helpful utilities for Wholeapp"
  s.homepage     = "https://github.com/timburks/NuHTTPHelpers"
  s.author       = "Valerii Lider"
  s.source       = { :git => "https://github.com/liimur/SafeDownloadOperation.git" }
  s.source_files = "*.h,m"
  s.platform	 = :ios, "4.0"
  s.requires_arc = true
  s.license	 = {
	:type => "Custom",
	:text => <<-LICENSEINFO  
Copyright (C) 2014  All Rights Reserved.
LICENSEINFO
}
end
