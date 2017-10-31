---
title: "Ethereum Private Network"
date: 2017-10-31T12:38:12+07:00
draft: false
---

One good way to understand Ethereum is by creating your own Ethereum private network. I have been trying to understand Ethereum in the past few weeks and I learned a lot of things just by creating it. I'll now write down what I got from creating Ethereum private network. And I'll update this post as I learn new things... hopefully

First of all, Ethereum client works by connecting to a network specified by its `networkid`. The normal network where people usually connecting to is public network with `networkid=1` (you can see it [here](https://github.com/ethereum/go-ethereum/blob/b0ca1b67ce6e297fe02281d01a486225bbf385f8/eth/config.go#L42)). But it is not the only network you can connect to, you can also create your own Ethereum network.

Typical Ethereum network consists of:

1. Bootnode

    You might be wondering how an Ethereum node can connects to other nodes and broadcast messages. It turns out they have special nodes called bootnode. Basically, they works as node discovery where you can join and ask for other nodes address that you can connect to.

    You can see the default bootnodes value [here](https://github.com/ethereum/go-ethereum/blob/b0ca1b67ce6e297fe02281d01a486225bbf385f8/params/bootnodes.go#L21).

2. Normal node

    They are just normal node people usually run.

3. Miner

    They are strong miners who make money out of thin air.

Actually you can run a node as normal node and miner at the same time. But in this post I'm going to run them separately so we can understand better what they are doing.

## Requirements

I'll use Golang version of Ethereum clients. I haven't tried other client implementations but they should also work, maybe...

You can download pre-build binary here: [https://geth.ethereum.org/downloads/](https://geth.ethereum.org/downloads/), please download the latest one with name: `Geth & Tools`. Unlike `Geth`, it contains `geth` and `bootnode` binaries needed for this post.

Please download and add the binaries to your `PATH`, in this post I assume all of those binary are already included in `PATH`.

## Create accounts

Ethereum doesn't need you to register in order to join the network. What you need to do is just create an account which consists of a private key and a public key, with a password for security, then you can just use the address. If you use `geth` to generate an account, both private and public key will be hidden in a weird looking `json` file.

Creating account in Ethereum is simple, you can use `geth` to create some:

``` bash
geth --datadir=accounts account new
```

You will then asked to type password. The created account will be saved in `accounts/keystore/UTC--{year}-{month}--{account}`.

> Make sure to **SAVE THE PASSWORD SECURELY**, because there is no way to retrieve your password once you lost it

Example account:

``` json
{
    "address": "07eafaabd1e6dce571f1931092fc1586b55f896e",
    "crypto": {
        "cipher": "aes-128-ctr",
        "ciphertext": "b5f65c754374915d7c02a156d7d4328dcb612a4ac6287fee5dd90dd6a074b808",
        "cipherparams": {
            "iv": "0ae623176cdfda61136f576244cd91df"
        },
        "kdf": "scrypt",
        "kdfparams": {
            "dklen": 32,
            "n": 262144,
            "p": 1,
            "r": 8,
            "salt": "ca4847545a4a0fa9a75dd2c98c83ddd9cce18578b8b8153d0c81ef49195fb690"
        },
        "mac": "398c2fe085315d8b497d09d88866e35f6b2d038023c86f4c346ff86dbd841d17"
    },
    "id": "b0272829-d924-48d4-97fb-1ec3329f3d80",
    "version": 3
}
```

The important part is `address`, as its name implies it is the address of the account. To understand better what's stored in there you can read [this](https://ethereum.stackexchange.com/a/15606).

## Create genesis block

If you are not familiar with blockchain, basically blockchain consists of many blocks and each block has the hash of previous block in it. But wait, what about the very first block in the blockchain? Which block should it refers to?

The first block in a blockchain is a special block, called genesis block. Unlike other blocks, it doesn't need the hash of the previous block (well, there is no block before it). It sets the hash of the previous block with `0`. It also can give some balance to some addresses.

> You can see Ethereum genesis block here: https://etherscan.io/block/0. Notice it has `Parent Hash=0`.

Genesis block in Ethereum is just an `json` file:

``` json
{
    "config": {
        "chainId": 9999,
        "homesteadBlock": 0,
        "eip155Block": 0,
        "eip158Block": 0
    },
    "alloc": {
        "07eafaabd1e6dce571f1931092fc1586b55f896e": {
            "balance": "100"
        }
    },
    "difficulty": "100000",
    "gasLimit": "999999"
}
```

Short explanation about above genesis file:

1. `config.chainId` I am not really sure about this. But it is used for preventing replay attack accross Ethereum networks. I also see most private network examples set this to the `networkid` of the private network. We will use 9999 as our `networkid` in this post.

2. `config.homesteadBlock`, `eip155Block` and `eip158Block` do not really matter in a private network

3. `alloc` specifies initial balance for some addresses

4. `difficulty` specifies how difficult mining should be

Create file `genesis.json` containing above json snippet (please change the address in the `alloc` to be your own account address). We'll back to this later when we are creating nodes.

## Setup bootnode

As I said before, bootnode works as a node discovery. Nodes would need bootnode to join and discover other nodes in the network so they can do whatever they want, e.g: syncing blockchain, create transaction, mining etc.

Setting up a bootnode is easy. First you need to create a nodekey. Essentially nodekey is an address where the bootnode run.

``` bash
bootnode --genkey=boot.key
```

> You should save your bootnode's nodekey. If the value is changed, you will have to update your other nodes to point to the new bootnode's address.

> Technically, nodekey is not the real address of the bootnode. Nodekey is just a public key and it needs to be hashed first to get the real address. See [this](https://ethereum.stackexchange.com/questions/3542/how-are-ethereum-addresses-generated) for further explanation.

It will create a nodekey and save it to `boot.key`.

You will also need the real address of bootnode so other nodes can use it as their bootnode. You can get it by:

``` bash
bootnode --nodekey=boot.key --writeaddress
```

## Setup nodes

Now we need to setup Ethereum nodes. Since we are going to use our own private network we will need to initialize our nodes with our genesis block.

> You have to do this for all nodes in our private network

You can initalize a node by:

``` bash
geth --datadir=nodeX init genesis.json
```

Please replace `nodeX` with a path where the node will save its data. Let's create a node and a miner, so run the above command with `--datadir=node` and `--datadir=miner`. It will initialize the nodes using our own genesis block definition in `genesis.json`.

> We don't need to specify genesis block when initalizing nodes in main network. Because genesis block for the main network is already hard coded in `geth`, see [here](https://github.com/ethereum/go-ethereum/blob/6d6a5a93370371a33fb815d7ae47b60c7021c86a/core/genesis.go#L310).

> We need to initialize all of our nodes with our genesis block because if they use the default genesis block they will not be able to sync to our private networks' blocks.

## Running all together

Let's put everything together. First we run the bootnode:

``` bash
bootnode --nodekey=boot.key --verbosity=9
```

I added `--verbosity=9` so we can easily see if the bootnode is working and other nodes are able to connect to bootnode. If it runs ok it should output something like:

```
INFO [10-31|21:26:21] UDP listener up                          self=enode://157e68e800266d39015a125f3c20a499cd190940e2a665854e0fb80f62f7c00734acc6eb277c06f0b5cb5840436b0ab3980761e7c58a27bfa052c10560db2bc7@[::]:30301
```

`enode://...` is the bootnode's address and `@[::]:30301` means that it runs on all interfaces at port 30301.

Next we run the node. We can run it by:

``` bash
geth --networkid=9999 \
    --port=9001 \
    --bootnodes=enode://157e68e800266d39015a125f3c20a499cd190940e2a665854e0fb80f62f7c00734acc6eb277c06f0b5cb5840436b0ab3980761e7c58a27bfa052c10560db2bc7@127.0.0.1:30301 \
    --datadir=node
```

Please make sure to adjust the bootnode address from bootnode's logs. I added `--port=9001` so that we can run multiple nodes in a host, they will run on different ports. If it runs ok the bootnode will output something like:

```
TRACE[10-31|21:40:08] >> PONG/v4                               addr=127.0.0.1:9001 err=nil
TRACE[10-31|21:40:08] << PING/v4                               addr=127.0.0.1:9001 err=nil
TRACE[10-31|21:40:08] Starting bonding ping/pong               id=4b2c152d338bdff6 known=false failcount=0 age=419294h40m8.013456s
TRACE[10-31|21:40:08] >> PING/v4                               addr=127.0.0.1:9001 err=nil
TRACE[10-31|21:40:08] << PONG/v4                               addr=127.0.0.1:9001 err=nil
TRACE[10-31|21:40:08] >> NEIGHBORS/v4                          addr=127.0.0.1:9001 err=nil
TRACE[10-31|21:40:08] << FINDNODE/v4                           addr=127.0.0.1:9001 err=nil
```

Last, let's run the miner node:

``` bash
geth --networkid=9999 \
    --port=9002 \
    --bootnodes=enode://157e68e800266d39015a125f3c20a499cd190940e2a665854e0fb80f62f7c00734acc6eb277c06f0b5cb5840436b0ab3980761e7c58a27bfa052c10560db2bc7@127.0.0.1:30301 \
    --datadir=miner \
    --mine \
    --minerthreads=1 \
    --etherbase=07eafaabd1e6dce571f1931092fc1586b55f896e
```

`--miner` makes the node to start mining after it is ready, `--minerthreads` sets how many threads will be used for mining and `--etherbase` will store the reward of mining to the specified address. If it runs ok it should have output like:

```
INFO [10-31|21:48:48] Starting mining operation
INFO [10-31|21:48:48] Commit new mining work                   number=1 txs=0 uncles=0 elapsed=164.218µs
INFO [10-31|21:48:49] Successfully sealed new block            number=1 hash=d13118…8fadfb
INFO [10-31|21:48:49] 🔨 mined potential block                  number=1 hash=d13118…8fadfb
INFO [10-31|21:48:49] Commit new mining work                   number=2 txs=0 uncles=0 elapsed=115.035µs
INFO [10-31|21:48:57] Successfully sealed new block            number=2 hash=8c7c30…f6871b
INFO [10-31|21:48:57] 🔨 mined potential block                  number=2 hash=8c7c30…f6871b
INFO [10-31|21:48:57] Commit new mining work                   number=3 txs=0 uncles=0 elapsed=194.539µs
INFO [10-31|21:48:59] Successfully sealed new block            number=3 hash=f688ba…303090
```

Great! Our private network is now working well. We can see our current balance using console:

``` bash
geth attach node/geth.ipc
```

Now we can check balance of the address used for mining:

``` bash
> eth.getBalance('07eafaabd1e6dce571f1931092fc1586b55f896e')
245000000000000000100 # this one is in 'wei' unit, see http://ethdocs.org/en/latest/ether.html#denominations. Of couse we can convert it to 'ether' unit
> web3.fromWei(eth.getBalance("07eafaabd1e6dce571f1931092fc1586b55f896e"), 'ether')
290.0000000000000001 # ez money :p
```

> Check this to learn about what you can do in the console: https://github.com/ethereum/wiki/wiki/JavaScript-API

Okay that's all for this post. I hope now you understand, at least, how to setup your own Ethereum private network. I'll cover more topics later about creating more secure private network and transfering ether... probably
