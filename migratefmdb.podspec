Pod::Spec.new do |s|
  s.name             = "migratefmdb"
  s.version          = "0.1.0"
  s.summary          = "A short description of migratefmdb."
  s.description      = <<-DESC
                       An optional longer description of migratefmdb

                       * Markdown format.
                       * Don't worry about the indent, we strip it!
                       DESC
  s.homepage         = "https://github.com/jagregory/migratefmdb"
  s.license          = 'MIT'
  s.author           = { "James Gregory" => "james@jagregory.com" }
  s.source           = { :git => "https://github.com/jagregory/migratefmdb.git", :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/jagregory'

  s.platform     = :ios, '7.0'
  s.requires_arc = true

  s.source_files = 'Pod/Classes'

  # s.public_header_files = 'Pod/Classes/**/*.h'
end
