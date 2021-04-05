# frozen_string_literal: true

def set_file
  name = ARGV[2] || fetch(:stage)
  "log/#{name}.log"
end

namespace :log do
  msg = '<stage>.log is selected if filename are not received'
  desc "Download log/<filename>.log, #{msg}"
  task :download do
    on roles(:all) do
      within current_path do
        file = set_file
        info "Downloading #{file} to log/ dir"
        download! file, 'log'
      end
    end
  end

  desc "Monitor log/<filename>.log, #{msg}"
  task :monitor do
    on roles(:all) do
      within current_path do
        file = set_file
        info "Monitoring #{file}"
        execute :tail, '-f', file, '-n', 100
      end
    end
  end
end

%i[INT TERM].each { |signal| trap(signal) { exit } }
