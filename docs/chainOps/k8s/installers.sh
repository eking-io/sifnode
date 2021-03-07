#!/bin/bash -x
function install_ruby() {
    ruby_version=$1
    echo "installing dev tools required"
    sudo yum -y install gcc-c++ patch readline readline-devel zlib zlib-devel libffi-devel \
    openssl-devel make bzip2 autoconf automake libtool bison sqlite-devel
    
    echo "installing rvm"
    curl -sSL https://rvm.io/mpapis.asc | gpg2 --import -
    curl -sSL https://rvm.io/pkuczynski.asc | gpg2 --import -
    curl -L get.rvm.io | bash -s stable
    
    echo "reloading rvm into environment"
    source /etc/profile.d/rvm.sh
    rvm reload
    rvm requirements run
    
    echo "installng ruby $ruby_version"
    rvm install $ruby_version
    rvm use $ruby_version --default
    
    ruby --version
}

function install_golang() {
    go_version=$1
    wget https://golang.org/dl/go${go_version}.linux-amd64.tar.gz
    sudo rm -rf /usr/local/go && sudo tar -C /usr/local -xzf go${go_version}.linux-amd64.tar.gz
    echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
    source ~/.bashrc
    go version
}

function install_aws_cli() {
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip awscliv2.zip
    sudo ./aws/install
}

function install_kubectl() {
    curl -o kubectl https://amazon-eks.s3.us-west-2.amazonaws.com/1.19.6/2021-01-05/bin/linux/amd64/kubectl
    chmod +x ./kubectl
    mkdir -p $HOME/bin && cp ./kubectl $HOME/bin/kubectl && export PATH=$PATH:$HOME/bin
    echo 'export PATH=$PATH:$HOME/bin' >> ~/.bashrc
    kubectl version --short --client
}

function install_helm() {
    wget https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3
    sh ./get-helm-3
}

function install_teraform() {
    echo "teraform should already be installed ;)"
}

install_ruby "2.7"
install_golang "1.16"
install_aws_cli
install_kubectl
install_helm
install_teraform

echo "Print version of all installed"
ruby --version
go version
aws --version
kubectl version
helm version
teraform version
echo "All done"
