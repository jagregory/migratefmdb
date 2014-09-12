Pod::Spec.new do |s|
  s.name             = "migratefmdb"
  s.version          = "0.2.0"
  s.summary          = "Database migrations for FMDatabase"
  s.homepage         = "https://github.com/jagregory/migratefmdb"
  s.license          = 'MIT'
  s.author           = { "James Gregory" => "james@jagregory.com" }
  s.source           = { :git => "https://github.com/jagregory/migratefmdb.git", :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/jagregory'

  s.platform     = :ios, '7.0'
  s.requires_arc = true

  s.source_files = 'src'
end
