#!/usr/bin/env ruby
# Add native Swift modules to the Xcode project

require 'xcodeproj'
require 'fileutils'

project_path = 'ios/LxMusicMobile.xcodeproj'
project = Xcodeproj::Project.open(project_path)

target = project.targets.find { |t| t.name == 'LxMusicMobile' }
abort('Target LxMusicMobile not found') unless target

# Find the LxMusicMobile group by path
main_group = project.main_group.groups.find { |g| g.path == 'LxMusicMobile' }
abort('Group LxMusicMobile not found') unless main_group

puts "Found group: #{main_group.display_name} (path: #{main_group.path})"

# Only add files that actually exist on disk
swift_files = Dir.glob('ios/LxMusicMobile/*.swift').map { |f| File.basename(f) }
puts "Swift files found: #{swift_files.inspect}"

swift_files.each do |filename|
  # Check if already added (path relative to group = just filename)
  existing = main_group.files.find { |f| f.path == filename }
  if existing
    puts "  #{filename} already in project"
    next
  end

  file_ref = main_group.new_reference(filename)
  file_ref.last_known_file_type = 'sourcecode.swift'
  file_ref.path = filename
  file_ref.name = filename

  target.source_build_phase.add_file_reference(file_ref)
  puts "  Added #{filename}"
end

# Add bridging header if it exists on disk
bridging_header_path = 'ios/LxMusicMobile/LxMusicMobile-Bridging-Header.h'
if File.exist?(bridging_header_path)
  header_name = 'LxMusicMobile-Bridging-Header.h'
  existing_header = main_group.files.find { |f| f.path == header_name }
  unless existing_header
    file_ref = main_group.new_reference(header_name)
    file_ref.last_known_file_type = 'sourcecode.c.h'
    file_ref.path = header_name
    file_ref.name = header_name
    puts "  Added bridging header"
  end

  target.build_configurations.each do |config|
    config.build_settings['SWIFT_VERSION'] = '5.0'
    config.build_settings['SWIFT_OBJC_BRIDGING_HEADER'] = 'LxMusicMobile/LxMusicMobile-Bridging-Header.h'
    config.build_settings['ALWAYS_EMBED_SWIFT_STANDARD_LIBRARIES'] = 'YES'
  end
end

project.save
puts 'Project saved successfully'
