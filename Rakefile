require 'rake/testtask'

################################################################################

# Default test task.
Rake::TestTask.new do |t|
  t.libs << 'tests'
  t.test_files = FileList['tests/test*.rb']
  t.verbose = true
end

################################################################################

# Run some sample dungeons to make sure that all works.
task :full, [:num] => [:test] do |t, args|
  gen_count = !args[:num].nil? ? args[:num].to_i : 10

  # Pass as an environment variable, as we're going accross files.
  ENV['gen_count'] = gen_count.to_s
  Dir[File.dirname(__FILE__) + '/tests/task_full.rb'].each do |f|
    require f
  end
end

################################################################################
