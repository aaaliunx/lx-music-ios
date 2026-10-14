#!/usr/bin/env ruby
# Add native Swift modules to the Xcode project

require 'xcodeproj'
require 'fileutils'

project_path = 'ios/LxMusicMobile.xcodeproj'
project = Xcodeproj::Project.open(project_path)

target = project.targets.find { |t| t.name == 'LxMusicMobile' }
abort('Target LxMusicMobile not found') unless target

main_group = project.main_group.find_subpath('LxMusicMobile', false)
abort('Group LxMusicMobile not found') unless main_group

# Only add files that actually exist on disk
swift_files = Dir.glob('ios/LxMusicMobile/*.swift').map { |f| File.basename(f) }

swift_files.each do |filename|
  filepath = "LxMusicMobile/#{filename}"
  existing = main_group.files.find { |f| f.path == filepath }
  if existing
    puts "  #{filename} already in project"
    next
  end

  file_ref = main_group.new_reference(filename)
  file_ref.last_known_file_type = 'sourcecode.swift'
  target.source_build_phase.add_file_reference(file_ref)
  puts "  Added #{filename}"
end

# Add bridging header if it exists on disk
bridging_header_path = 'ios/LxMusicMobile/LxMusicMobile-Bridging-Header.h'
if File.exist?(bridging_header_path)
  bridging_header = 'LxMusicMobile/LxMusicMobile-Bridging-Header.h'
  existing_header = main_group.files.find { |f| f.path == bridging_header }
  unless existing_header
    file_ref = main_group.new_reference('LxMusicMobile-Bridging-Header.h')
    file_ref.last_known_file_type = 'sourcecode.c.h'
    puts "  Added bridging header"
  end

  target.build_configurations.each do |config|
    config.build_settings['SWIFT_VERSION'] = '5.0'
    config.build_settings['SWIFT_OBJC_BRIDGING_HEADER'] = bridging_header
    config.build_settings['ALWAYS_EMBED_SWIFT_STANDARD_LIBRARIES'] = 'YES'
  end
end

project.save
puts 'Project saved successfully'
