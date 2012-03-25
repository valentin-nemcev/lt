require 'pathname'

# Configurator::DEFAULTS[:logger].formatter = Logger::Formatter.new

lgr = Logger.new($stderr)
logger lgr

app_path = Pathname.new(__FILE__).expand_path.dirname.parent

apps_folder, this_app_name = app_path.split
current_release = apps_folder.join('../current')
is_cap_release = current_release.exist? && this_app_name.to_s.match(/\d{14}/)
is_current = is_cap_release && current_release.realpath == app_path.realpath

current_path = is_current ? current_release : app_path

lgr.info "Current path is #{current_path}"

working_directory current_path.to_s

before_exec do |server|
  ENV["BUNDLE_GEMFILE"] = current_path.join('Gemfile').to_s
end

worker_processes 2

listen      File.join(current_path, 'tmp/sockets/unicorn.sock')
pid         File.join(current_path, 'tmp/pids/unicorn.pid')
stderr_path File.join(current_path, 'log/unicorn.stderr.log')
stdout_path File.join(current_path, 'log/unicorn.stdout.log')

preload_app true

before_fork do |server, worker|
  ##
  # When sent a USR2, Unicorn will suffix its pidfile with .oldbin and
  # immediately start loading up a new version of itself (loaded with a new
  # version of our app). When this new Unicorn is completely loaded
  # it will begin spawning workers. The first worker spawned will check to
  # see if an .oldbin pidfile exists. If so, this means we've just booted up
  # a new Unicorn and need to tell the old one that it can now die. To do so
  # we send it a QUIT.
  #
  # Using this method we get 0 downtime deploys.

  old_pid = File.join(current_path, 'tmp/pids/unicorn.pid.oldbin')
  if File.exists?(old_pid) && server.pid != old_pid
    begin
      Process.kill("QUIT", File.read(old_pid).to_i)
    rescue Errno::ENOENT, Errno::ESRCH
      # someone else did our job for us
    end
  end
end

after_fork do |server, worker|
  ##
  # Unicorn master loads the app then forks off workers - because of the way
  # Unix forking works, we need to make sure we aren't using any of the parent's
  # sockets, e.g. db connection

  ActiveRecord::Base.establish_connection

end

