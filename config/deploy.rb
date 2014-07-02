set :application, "metalive"
set :scm, "git"
set :repository, "git://projects.tryphon.priv/metalive-server"

set :deploy_to, "/var/www/metalive"

set :keep_releases, 5
after "deploy:update", "deploy:cleanup"
set :use_sudo, false
default_run_options[:pty] = true

# server "sandbox", :app, :web, :db, :primary => true
server "radio.dbx1.tryphon.priv", :app, :web, :db, :primary => true

# if you want to clean up old releases on each deploy uncomment this:
# after "deploy:restart", "deploy:cleanup"

namespace :deploy do
  task :start do ; end
  task :stop do ; end
  task :restart, :roles => :app, :except => { :no_release => true } do
    # run "#{try_sudo} touch #{File.join(current_path,'tmp','restart.txt')}"
  end
end
