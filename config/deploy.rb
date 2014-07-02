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
  # Prevent errors when chmod isn't allowed by server
  task :setup, :except => { :no_release => true } do
    dirs = [deploy_to, releases_path, shared_path]
    dirs += shared_children.map { |d| File.join(shared_path, d) }
    run "mkdir -p #{dirs.join(' ')} && (chmod g+w #{dirs.join(' ')} || true)"
  end

  task :start do ; end
  task :stop do ; end
  task :restart, :roles => :app, :except => { :no_release => true } do
    # run "#{try_sudo} touch #{File.join(current_path,'tmp','restart.txt')}"
  end
end
