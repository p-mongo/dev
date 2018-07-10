require 'hashie/mash'
require 'fileutils'
require 'childprocess'

class Manager
  def vagrant_template(config)
    config = Hashie::Mash.new(config)
    <<-T
Vagrant.configure(2) do |config|
  config.vm.box = "#{config.box}"
  config.vm.synced_folder "#{share_path}", "/share"
end
T
  end

  DISTROS = {
    'debian92' => "bento/debian-9.2",
    'ubuntu1404' => "bento/ubuntu-14.04",
    'ubuntu1604' => "bento/ubuntu-16.04",
  }

  private def resolve(which)
    which = which.gsub(%r,/*,, '')
    distro = DISTROS[which]
    if distro.nil?
      raise "Don't know what #{which} is"
    end
    distro
  end

  def up(which)
    distro = resolve(which)

    FileUtils.mkdir_p(which)

    File.open("#{which}/Vagrantfile", 'w') do |f|
      f << vagrant_template(box: distro)
    end

    run(which, %w(vagrant up))
    run(which, %w(vagrant ssh))
  end

  def ssh(which)
    distro = resolve(which)
    run(which, %w(vagrant ssh))
  end

  private def run(which, cmd)
    puts "Run #{cmd.join(' ')} in #{which}"
    p = ChildProcess.build(*cmd)
    p.cwd = which
    p.io.inherit!
    p.start
    p.wait
  end

  def halt(which=nil)
    if which
      distro = resolve(which)
      run(which, %w(vagrant halt))
    else
      DISTROS.each do |which, distro|
        run(which, %w(vagrant halt))
      end
    end
  end

  private def share_path
    File.expand_path(File.join(File.dirname(__FILE__), '..', 'share'))
  end
end
