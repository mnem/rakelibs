# Helpful tasks for using git subtrees.

class SubtreeRake
  include Rake::DSL

  CONFIG_EXAMPLE = <<-END_CONFIG_EXAMPLE.gsub(/^ {4}/, '')
    :subtrees:
      'subtrees/project-bob':
        # REQUIRED: the remote repository for the subtree
        :remote: 'git://github.com/mnem/project-bob.git'
        # OPTIONAL: the branch to use. Defaults to master
        :branch: 'funkotron'
        # OPTIONAL: Defaults to the repo name (project-bob in this example).
        # Useful if the repo name has spaces or something crazy like that
        :name: 'bob'
  END_CONFIG_EXAMPLE

  def config_block_exists
    defined?(RAKE_CONFIG) and RAKE_CONFIG.has_key? :subtrees
  end

  def ensure_config
    unless config_block_exists
      fail "subtree.rake: Config block missing from rakeconfig.yml.\nExample config block:\n\n#{CONFIG_EXAMPLE}\n"
    end
  end

  def ensure_remote(remote_name, remote)
    remotes = `git remote -v`
    unless /^#{remote_name}/ =~ remotes
      puts "Adding new remote: #{remote_name}"
      sh "git remote add -f '#{remote_name}' '#{remote}'"
    end
  end

  def repositiory_name(remote_path)
    name = remote_path.split("/").last
    name[0...-4] if name.end_with? '.git'
  end

  def generate_subtree_tasks(path, config)
    remote = config[:remote]

    if config.has_key? :branch
      branch = config[:branch]
    else
      branch = 'master'
    end

    if config.has_key? :name
      name = config[:name]
    else
      name = repositiory_name remote
    end

    remote_name = "subtree-#{name}"

    add_task_name = "add-#{name}"
    desc "Adds #{name} as a new subtree in #{path}"
    task add_task_name do
      ensure_remote remote_name, remote
      sh "git subtree add --prefix #{path} #{remote_name}/#{branch} --squash"
    end

    pull_task_name = "pull-#{name}"
    desc "Merges the latest upstream code into #{name}"
    task pull_task_name do
      ensure_remote remote_name, remote
      sh "git fetch #{remote_name} #{branch}"
      sh "git subtree pull --prefix #{path} #{remote_name} #{branch}"
    end

    return add_task_name, pull_task_name
  end

  def generate_tasks
    ensure_config

    all_add_task_names = []
    all_pull_task_names = []

    RAKE_CONFIG[:subtrees].each do |path, config|
      add_task_name, pull_task_name = generate_subtree_tasks path, config
      all_add_task_names << add_task_name
      all_pull_task_names << pull_task_name
    end

    desc "Add all subtrees"
    task "add-all" => [*all_add_task_names]

    desc "Update all subtrees"
    task "pull-all" => [*all_pull_task_names]
  end
end

namespace :subtree do
  SubtreeRake.new.generate_tasks
end
