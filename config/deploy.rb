require 'capistrano_colors'

$:.unshift(File.expand_path('./lib', ENV['rvm_path']))
require "rvm/capistrano"
# set :rvm_ruby_string, `rvm current`
set :rvm_ruby_string, 'ruby-1.9.3-p0'
set :rvm_type, :user


require 'bundler/capistrano'
set :bundle_flags, '--deployment --binstubs'

set :application, 'lt'

set :scm, :git
set :repository,  'git@vds:lt.git'
set :deploy_via, :remote_cache

server 'vds', :app, :web, :db, :primary => true
set :use_sudo, false
set :deploy_to, "/home/valentin/webapps/#{application}"
set :shared_symlinks, {
  'config/database.yml' => 'config/database.yml',
  'sockets' => 'tmp/sockets'
}

namespace :deploy do
  desc 'Delete all releases'
  task :cleanup_all do
    set :keep_releases, 0
    cleanup
  end

  after 'deploy:update_code', 'deploy:symlink_shared'
  task :symlink_shared do
    shared_symlinks.map do |from, to|
      run "ln -nfs #{shared_path}/#{from} #{latest_release}/#{to}"
    end
  end

end
load 'deploy/assets'


def run_rake(*args)
  run "cd #{current_path} && RAILS_ENV=production #{fetch :rake} " + args.join(' ')
end

namespace :deploy do
  task :start, :roles => :app do
    run_rake 'unicorn:start'
  end
  task :stop, :roles => :app do
    run_rake 'unicorn:stop'
  end
  task :restart, :roles => :app do
    run_rake 'unicorn:restart'
  end
end
