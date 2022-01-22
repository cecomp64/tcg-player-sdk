require 'yard'

YARD::Rake::YardocTask.new do |t|
  t.files   = ['tcg_player_api.rb']
  t.options = ['-o', 'docs']
  t.stats_options = ['--list-undoc']
end

desc "Generate project documentation."
task document: [:yard]