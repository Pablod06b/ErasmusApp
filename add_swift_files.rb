require 'xcodeproj'

project_path = 'Erasmus_App.xcodeproj'
project = Xcodeproj::Project.open(project_path)
target = project.targets.find { |t| t.name == 'Erasmus_App' }

added_count = 0

Dir.glob('Sources/ErasmusApp/**/*.swift').each do |file_path|
  filename = File.basename(file_path)
  
  already_added = target.source_build_phase.files.any? do |f|
    f.file_ref && f.file_ref.path && f.file_ref.path.end_with?(filename)
  end
  
  unless already_added
    puts "Adding: #{file_path}"
    file_ref = project.main_group.new_reference(file_path)
    target.source_build_phase.add_file_reference(file_ref, true)
    added_count += 1
  end
end

if added_count > 0
  project.save
  puts "Successfully added #{added_count} files to the target."
else
  puts "No new files to add."
end
