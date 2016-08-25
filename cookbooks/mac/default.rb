require 'open3'

def set_value(node_name, value)
  while i = STDIN.gets.chomp
    break node["#{node_name}"] = value if i.match(/^\s*$/)
    node["#{node_name}"] = i.strip
    break
  end
end

unless ENV['USER'] == 'root'
  p "sudoで実行してください"
  exit(1)
end

system("echo $LOGNAME")

puts <<EOS


\e[32m-------------------\e[0m
\e[31m（入力例）\e[0m
[Server1 のスペック]
CPUのコア数: 1
MEMORY(MB): 4096
private ip: 192.168.56.101 / 255.255.255.0

[Server2 のスペック]
CPUのコア数: 1
MEMORY(MB): 4096
private ip: 192.168.56.102 / 255.255.255.0

vagrantセットアップdir（Vagrantfile と bootstrapの保存場所）
"/Users/sion_cojp/vagrant"
-------------------\e[0m


EOS
1.upto(2).each do |i|
  puts "\n[Server#{i}のスペック設定]"
  puts "\nCPU数（入力しなければ \e[32m1\e[0m が設定されます）: "
  set_value("cpu#{i}", '1')

  puts "\nMEMORY(MB)（入力しなければ \e[32m4096MB\e[0m が設定されます）: "
  set_value("mem#{i}", '4096')

  puts "\nprivate ipを入力してください（内部用。特に指定がなければ、\e[32m192.168.56.10#{i}\e[0m が設定されます）: "
  set_value("private_ip#{i}", "192.168.56.10#{i}")
  puts "\n"
end

puts "\nユーザ名を入力してください: "
set_value("user_id", 'root')

puts "どこにvagrantディレクトリを作成しますか？（例 \e[32m/Users/sion_cojp/vagrant\e[0m ）"
set_value("vagrant_dir", "/tmp/vagrant")

puts <<EOS
******************************************
[Server1 のスペック]
CPUのコア数: \e[32m"#{node['cpu1']}"\e[0m
MEMORY(MB): \e[32m"#{node['mem1']}"\e[0m
private ip（内部用）: \e[32m"#{node['private_ip1']}" / 255.255.255.0\e[0m

[Server2 のスペック]
CPUのコア数: \e[32m"#{node['cpu2']}"\e[0m
MEMORY(MB): \e[32m"#{node['mem2']}"\e[0m
private ip（内部用）: \e[32m"#{node['private_ip2']}" / 255.255.255.0\e[0m

vagrantセットアップdir（Vagrantfile と bootstrapの保存場所）
\e[32m"#{node['vagrant_dir']}"\e[0m
******************************************


EOS

loop do
  puts 'この設定でvagrant環境をセットアップしますか？(y/n)'
  res = STDIN.gets.chomp
  case res
  when /[yY]/
    puts 'セットアップに数分かかります。終わるまでお待ちください。'

    ### NFSの設定と再起動
    remote_file '/etc/nfs.conf' do
      source 'files/nfs.conf'
      owner 'root'
      group 'wheel'
      mode '0644'
      not_if "grep 'nfs.server.async=1' /etc/nfs.conf"
      notifies :run, 'execute[restart nfsd]'
    end
    execute 'restart nfsd' do
      command 'nfsd restart'
    end

    ### visudoの設定
    execute 'setting visudo' do
      command <<-EOS
        echo "Cmnd_Alias VAGRANT_EXPORTS_ADD = /usr/bin/tee -a /etc/exports" >> /etc/sudoers
        echo "Cmnd_Alias VAGRANT_NFSD = /sbin/nfsd restart" >> /etc/sudoers
        echo "Cmnd_Alias VAGRANT_EXPORTS_REMOVE = /usr/bin/sed -E -e /*/ d -ibak /etc/exports" >> /etc/sudoers
        echo "%admin ALL=(root) NOPASSWD: VAGRANT_EXPORTS_ADD, VAGRANT_NFSD, VAGRANT_EXPORTS_REMOVE" >> /etc/sudoers
      EOS
      not_if "grep 'NOPASSWD: VAGRANT_EXPORTS_ADD, VAGRANT_NFSD, VAGRANT_EXPORTS_REMOVE' /etc/sudoers"
    end

    ### vagrant起動に必要なプラグインをインストール
    execute 'install vagrant plugin' do
      command 'vagrant plugin install vagrant-vbguest'
      not_if 'vagrant plugin list | grep "vagrant-vbguest"'
    end

    ### #{node['vagrant_dir']}の設置
    directory "#{node['vagrant_dir']}" do
      owner "#{node['user_id']}"
      mode '777'
    end

    ### vagrantfileの設置
    template "#{node['vagrant_dir']}/Vagrantfile" do
      source 'templates/Vagrantfile'
      owner "#{node['user_id']}"
      mode '777'
    end

    ### bootstrap.shの設置
    template "#{node['vagrant_dir']}/bootstrap.sh" do
      source "templates/bootstrap.sh"
      owner "#{node['user_id']}"
      mode '777'
    end

    1.upto(2).each do |i|
      ### server1, server2のディレクトリ設置
      directory "#{node['vagrant_dir']}/server#{i}" do
        mode '777'
        owner "#{node['user_id']}"
        not_if "test -d #{node['vagrant_dir']}/server#{i}"
      end
    end
    puts "\nセットアップが完了したら、 \e[32mvagrant box addコマンド\e[0m でboxを登録し、Vagrantfileの \e[32mserver.vm.box = \"\"\e[0m　を書き換えてください"
    break
  when /[nN]/
    puts '最初からやり直してください'
    exit(1)
    break
  end
end
