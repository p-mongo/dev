require 'yaml'
require 'childprocess'
require 'active_support/core_ext/class/attribute'
require 'fileutils'
require 'pathname'

class DocsBuilder
  class_attribute :work_path
  class_attribute :docs_repo_url
  class_attribute :build_root
  class_attribute :web_root
  class_attribute :output_subdir
  class_attribute :version

  self.build_root = Pathname.new(File.expand_path('~/tmp/docs-build'))
  self.web_root = Pathname.new(File.expand_path('~/tmp/docs-web'))

  def setup
    FileUtils.mkdir_p(self.class.build_root)
    FileUtils.mkdir_p(self.class.web_root)
  end

  def build
    setup
    build_tutorial
    build_yardocs
  end

  def build_tutorial
    bn = self.class.work_path.basename

    dr_work_path = self.class.build_root.join(bn)
    if File.exist?(dr_work_path)
      check_call(['sh', '-c', <<S], cwd: dr_work_path)
        git checkout master &&
        git fetch origin &&
        git reset --hard origin/master
S
    else
      check_call(%w(git clone) + [self.class.docs_repo_url, dr_work_path])
    end

    cr_work_path = self.class.build_root.join('repo')
    if File.exist?(cr_work_path)
      check_call(['sh', '-c', <<S], cwd: cr_work_path)
        git checkout master &&
        git fetch origin &&
        git reset --hard origin/master
S
    else
      check_call(%w(git clone) + [self.class.work_path, cr_work_path])
    end

    check_call(['sh', '-c', <<S], cwd: cr_work_path)
        (git checkout build || git checkout -b build) &&
        git reset --hard master
S
    check_call(['rsync', '-av', '--delete', '--exclude', '.git',
      self.class.work_path.to_s + '/', cr_work_path])
    check_call(['sh', '-c', <<S], cwd: cr_work_path)
        git add . &&
        if ! git status |grep -q 'nothing to commit'; then
          git commit -amBuild
        fi
S

    contents = File.read(dr_work_path.join('config', 'build_conf.yaml'))
    config = YAML.load(contents)
    config['assets'].each do |asset|
      if asset['repository'] =~ /ruby-driver|mongoid/
        asset['repository'] = cr_work_path.to_s
        asset['branch'] = 'build'
        break
      end
    end

    File.open(dr_work_path.join('config', 'build_conf.yaml'), 'w') do |f|
      f << YAML.dump(config)
    end

    check_call(['sh', '-c', <<S], cwd: dr_work_path)
        make clean html
S
    FileUtils.mkdir_p(web_root.join(output_subdir))
    check_call(['rsync', '-av', '--delete', dr_work_path.join('build', 'master', 'html').to_s + '/',
      web_root.join(output_subdir, 'tutorial')])
  end

  def build_yardocs
    check_call(%w(rake docs), cwd: work_path)
    FileUtils.mkdir_p(web_root.join(output_subdir))
    check_call(['rsync', '-av', '--delete', work_path.join('yard-docs', version).to_s + '/',
      web_root.join(output_subdir, 'api')])
  end

  def check_call(cmd, env: nil, cwd: nil)
    process = ChildProcess.new(*cmd.map { |p| p.to_s })
    process.io.inherit!
    if env
      env.each do |k, v|
        process.environment[k.to_s] = v
      end
    end
    if cwd
      process.cwd = cwd
    end
    process.start
    process.wait
    unless process.exit_code == 0
      raise "Failed to execute: #{cmd}"
    end
  end
end

class DriverDocsBuilder < DocsBuilder
  self.work_path = Pathname.new(File.expand_path('~/apps/ruby-driver'))
  self.docs_repo_url = 'https://github.com/mongodb/docs-ruby'
  self.output_subdir = 'driver'
  self.version = '2.6.1'
end

class MongoidDocsBuilder < DocsBuilder
  self.work_path = Pathname.new(File.expand_path('~/apps/mongoid'))
  self.docs_repo_url = 'https://github.com/mongodb/docs-mongoid'
  self.output_subdir = 'mongoid'
  self.version = '7.1.0'
end
