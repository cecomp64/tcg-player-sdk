require 'yard'

YARD::Rake::YardocTask.new do |t|
  t.files   = ['tcg_player_api.rb']
  t.options = ['-o', 'docs']
  t.stats_options = ['--list-undoc']
end

desc "Build gem  Easy Peasy."
task :build_gem, [] do |task, args|
  result = `gem build tcg-player-api`
  puts result
end

desc "Install gem, using any .gem file found in the project root directory"
task :install_gem, [] do |task, args|
  # Maybe one day get fancy, and pass in the version as an argument
  gem = Dir.glob('./*.gem').first
  result = `gem install #{gem}`
  puts result
end

desc "Uninstall any existing tcg-player-api gems"
task :uninstall_gem, [] do |task, args|
  puts `gem uninstall tcg-player-api`
end