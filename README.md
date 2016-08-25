# 概要

* itamaeでVagrant環境をSetupします。

<br><br><br>
# vagrantの使い方

### vagrantの立ち上げ
```bash
$ sudo gem install itamae
$ git clone git@github.com:sioncojp/vagrant-itamae.git
$ cd vagrant-itamae
$ sudo itamae local setup_mac.rb -l warn

# boxの登録（下記、centos6.7の登録例）
$ vagrant box add centos6-7 https://github.com/CommanderK5/packer-centos-template/releases/download/0.6.7/vagrant-centos-6.7.box
$ vim Vagrantfile
server.vm.box = "centos6-7"

# あとは下記で起動なり、削除するなりしてください
$ cd $PATH/vagrant
起動する : $ vagrant up server1 --provision
停止する : $ vagrant halt server1
削除する : $ vagrant destroy server1

# 今何を実行してるか見たい場合は、下記でログが見れます。
$ tail -f /tmp/setup_vagrant.log
```
