#!/usr/bin/env ruby
# Add native Swift modules to the Xcode project

require 'xcodeproj'
require 'fileutils'

project_path = 'ios/LxMusicMobile.xcodeproj'
project = Xcodeproj::Project.open(project_path)

target = project.targets.find { |t| t.name == 'LxMusicMobile' }
abort('Target LxMusicMobile not found') unless target

# Find the LxMusicMobile group by searching all groups
main_group = nil
project.main_group.recursive_children.each do |child|
  if child.is_a?(Xcodeproj::Project::Object::PBXGroup) && child.display_name == 'LxMusicMobile'
    main_group = child
    break
  end
end
abort('Group LxMusicMobile not found') unless main_group

puts "Found group: #{main_group.display_name} (path: #{main_group.path})"

# Only add files that actually exist on disk
swift_files = Dir.glob('ios/LxMusicMobile/*.swift').map { |f| File.basename(f) }
puts "Swift files found: #{swift_files.inspect}"

swift_files.each do |filename|
  full_path = "LxMusicMobile/#{filename}"
  existing = main_group.files.find { |f| f.path == full_path || f.path == filename }
  if existing
    puts "  #{filename} already in project"
    next
  end

  # Create file reference - use full path like existing files (e.g. LxMusicMobile/AppDelegate.h)
  file_ref = main_group.new_reference(full_path)
  file_ref.last_known_file_type = 'sourcecode.swift'
  file_ref.path = full_path
  file_ref.name = filename
  file_ref.source_tree = '<group>'

  target.source_build_phase.add_file_reference(file_ref)
  puts "  Added #{filename} -> path: #{file_ref.path}"
end

# Add bridging header if it exists on disk
bridging_header_path = 'ios/LxMusicMobile/LxMusicMobile-Bridging-Header.h'
if File.exist?(bridging_header_path)
  header_name = 'LxMusicMobile-Bridging-Header.h'
  header_full_path = "LxMusicMobile/#{header_name}"
  existing_header = main_group.files.find { |f| f.path == header_full_path || f.path == header_name }
  unless existing_header
    file_ref = main_group.new_reference(header_full_path)
    file_ref.last_known_file_type = 'sourcecode.c.h'
    file_ref.path = header_full_path
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
