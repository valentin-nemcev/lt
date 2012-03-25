namespace :unicorn do

  ##
  # Tasks

  desc "Start unicorn"
  task(:start) {
    config = "config/unicorn.rb"
    sh "unicorn --daemonize --config-file #{config}"
  }

  desc "Stop unicorn"
  task(:stop) { unicorn_signal :QUIT }

  desc "Restart unicorn with USR2"
  task(:restart) { unicorn_signal :USR2 }

  desc "Hard restart unicorn by stopping it and starting it again"
  task (:hard_restart) {
    Rake::Task['unicorn:stop'].invoke
    Rake::Task['unicorn:start'].invoke
  }

  desc "Increment number of worker processes"
  task(:increment) { unicorn_signal :TTIN }

  desc "Decrement number of worker processes"
  task(:decrement) { unicorn_signal :TTOU }

  desc "Unicorn pstree (depends on pstree command)"
  task(:pstree) do
    sh "pstree '#{unicorn_pid}'"
  end

  ##
  # Helpers

  def unicorn_signal signal
    Process.kill signal, unicorn_pid
  end

  def unicorn_pid
    begin
      File.read("tmp/pids/unicorn.pid").to_i
    rescue Errno::ENOENT
      raise "Unicorn doesn't seem to be running"
    end
  end

end
