begin
  require 'xcodeproj'
  project_path = 'Erasmus_App.xcodeproj'
  project = Xcodeproj::Project.open(project_path)
  target = project.targets.first
  
  # Find or create group
  group = project.main_group
  ['Sources', 'ErasmusApp', 'Services', 'Auth'].each do |folder|
    group = group.children.find { |c| c.display_name == folder || c.path == folder } || group.new_group(folder, folder)
  end
  
  # Add file reference
  file_path = 'Sources/ErasmusApp/Services/Auth/GoogleSignInHelper.swift'
  file_ref = group.new_file(file_path)
  
  # Add to compile sources
  target.source_build_phase.add_file_reference(file_ref, true)
  project.save
  puts "Successfully added GoogleSignInHelper to project!"
rescue => e
  puts "Error: #{e.message}"
end
