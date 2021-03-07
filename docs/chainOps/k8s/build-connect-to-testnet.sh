#!/bin/bash -x

my_cluster=$1
my_moniker=$2
my_namespace=$3

while true; do
    echo "Installing with cluster:${my_cluster}, moniker(node name):${my_moniker}, namespace:${my_namespace}"
    read -p "Are you running this script from the sifnode root directory?" yn
    case $yn in
        [Yy]* ) echo "well done, next ;)"; break;;
        [Nn]* ) echo "please retry from sifnode root directory"; exit;;
        * ) echo "Please answer yes or no.";;
    esac
done

while true; do
    echo "Installing with cluster:${my_cluster}, moniker(node name):${my_moniker}, namespace:${my_namespace}"
    read -p "Do you wish to install this sifnode cluster with these values?" yn
    case $yn in
        [Yy]* ) echo "doing as you command ;)" break;;
        [Nn]* ) exit;;
        * ) echo "Please answer yes or no.";;
    esac
done

my_provider="aws"
my_chain_id="merry-go-round"
my_image="sifchain/sifnoded"
my_image_tag="testnet-genesis"
my_peer_address="f214ec6828b85793289fcb0b025bc260747983f0@100.20.201.226:26656"
my_genesis_url="http://100.20.201.226:26657/genesis"
my_mnemonic_file=$HOME/my_mnemonic.dat

echo "1. Switch to the root of the sifchain project"

echo "2. Scaffold a new cluster:"
rake "cluster:scaffold[${my_cluster},${my_provider}]"

echo "3. Once complete, you'll notice that several Terraform files/folders "
tree .live

echo "4. Deploy the cluster to AWS:"
rake "cluster:deploy[${my_cluster},${my_provider}]"

echo "5. Once complete, you should see your cluster on your AWS account."
kubectl get pods --all-namespaces --kubeconfig ./.live/sifchain-aws-${my_cluster}/kubeconfig_sifchain-aws-${my_cluster}

echo "6. Generate a new mnemonic key for your node"
rake "keys:generate:mnemonic" > ${my_mnemonic_file}
my_mnemonic_data=`cat ${my_mnemonic_file}`
echo ""
echo "7. Import your newly generated key"
cat ${my_mnemonic_file} |rake "keys:import[${my_moniker}]"

echo "8. Check that it's been imported accordingly:"
sifnodecli keys show ${my_moniker} --keyring-backend file

echo "9. Deploy a new node to your cluster and connect to an existing network:"
rake "cluster:sifnode:deploy:peer[${my_cluster},${my_chain_id},${my_provider},${my_namespace},${my_image},${my_image_tag},${my_moniker},${my_mnemonic_data},${my_peer_address},${my_genesis_url}]"
