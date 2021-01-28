curl https://get.docker.com | sh

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
install_path=/usr/local/bin/docker-compose
sudo curl -L "https://github.com/docker/compose/releases/download/1.27.3/docker-compose-$(uname -s)-$(uname -m)" -o ${install_path}
chmod +x ${install_path}
