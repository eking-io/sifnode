#/bin/bash -xe
read -p "Enter > A name of your cluster (exit to quit) : " myCluster
case $myCluster in
    [exit]* ) echo "Okay, quiting now"; exit;;
    * ) echo "Using ${myCluster} for cluster name"
esac

read -p "Enter > The moniker or name of your node  (exit to quit): " myMoniker
case $myMoniker in
    [exit]* ) echo "Okay, quiting now"; exit;;
    * ) echo "Using ${myMoniker} for myMoniker name"
esac

read -p "Enter > The namespace for the deployment  (exit to quit): " myNamespace
case $myNamespace in
    [exit]* ) echo "Okay, quiting now"; exit;;
    * ) echo "Using ${myNamespace} for namespace"
esac

myProvider="aws"
theSifChainID="merry-go-round"
theSifPeerAddress="169d512e28d142962f9e0aa51c1bd1f6b9d0bed8@35.160.89.251:26656"
theSifGenesisUrl="https://rpc-merry-go-round.sifchain.finance/genesis"
theSifImage="sifchain/sifnoded"
theSifImageTag="testnet-genesis"

echo "Variables to use in this installation :"
echo "  "
echo "  provider     = ${myProvider}"
echo "  cluster      = ${myCluster}"
echo "  moniker      = ${myMoniker}"
echo "  namespace    = ${myNamespace}"
echo "  chain_id     = ${theSifChainID}"
echo "  image        = ${theSifImage}"
echo "  image_tag    = ${theSifImageTag}"
echo "  peer_address = ${theSifPeerAddress}"
echo "  genesis_url  = ${theSifGenesisUrl}"
echo ""

while true; do
    read -p "Are you good with all these parameters? " yn
    case $yn in
        [Yy]* ) echo "Cool! Will continue"; break;;
        [Nn]* ) exit;;
        * ) echo "Please answer yes or no.";;
    esac
done

echo "Creating Teraform Scaffold scripts for ${myCluster}"
rake "cluster:scaffold[${myCluster},aws]"
echo "Teraform script completed and saved in sifnode/.live directory"

echo "Rake-Deploying cluster:${myCluster} to aws eks. This will take a while"
time rake "cluster:deploy[${myCluster},${myProvider}]"
echo "Rake-Deploying completed"
sleep 10
echo "Checking pods are deployed"
kubectl get pods --all-namespaces --kubeconfig ./.live/sifchain-aws-${myCluster}/kubeconfig_sifchain-aws-${myCluster}

while true; do
    read -p "Is the the get-pods result acceptable?" yn
    case $yn in
        [Yy]* ) echo "Cool! Will continue"; break;;
        [Nn]* ) exit;;
        * ) echo "Please answer yes or no.";;
    esac
done

echo "Rake-Generate sifchain mnemonic"
rake "keys:generate:mnemonic"
read -p "Copy and past the mnemonic here : " myMnemonic
echo "${myMnemonic}" > ~/myMnemonic.txt
echo "Rake-Generate completed and saved to variable ~/myMnemonic.txt"
echo "mnemonic is: ${myMnemonic}"


echo "Rake-Importing keys for ${myMoniker} ... you will create your passphrase"
rake "keys:import[${myMoniker}]"
echo "Rake-Importing completed"

echo "Double checking keyring for ${myMoniker} ... you will need your passphrase"
sifnodecli keys show ${myMoniker} --keyring-backend file


echo "Rake-Deploy peer:"
rake "cluster:sifnode:deploy:peer[${myCluster},${theSifChainID},${myProvider},${myNamespace},${theSifImage},${theSifImageTag},${myMoniker},'${myMnemonic}',${theSifPeerAddress},${theSifGenesisUrl}]"

echo "Rake-Public keys"
rake "validator:keys:public[${myCluster},${myProvider},${myNamespace}]"
echo ""
read -p "Copy and past the public key here : " myPublicKey
echo "${myPublicKey}" > ~/myPublicKey.txt
echo "Rake-Public keys completed and saved to variable ~/myPublicKey.txt"
echo "myPublicKey is: ${myPublicKey}"


while true; do
    read -p "Ready to STAKE! Did you get Rowans from the faucet yet? " yn
    case $yn in
        [Yy]* ) echo "Cool! Will continue"; break;;
        [Nn]* ) exit;;
        * ) echo "Please answer yes or no.";;
    esac
done

echo "Rake-Stake"
rake "validator:stake[${theSifChainID},${myMoniker},10000000rowan,0.5rowan,${myPublicKey},tcp://rpc-merry-go-round.sifchain.finance:80]"


echo "Use this command to check if we are in the validator network"
sifnodecli q tendermint-validator-set --node tcp://rpc-merry-go-round.sifchain.finance:80 --trust-node


#sifnodecli q staking validators  --node tcp://rpc-merry-go-round.sifchain.finance:80  --output json | jq -r '.[] | select(.status==2)' | grep moniker | wc -l
