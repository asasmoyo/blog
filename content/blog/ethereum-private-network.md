---
title: "Ethereum Private Network"
date: 2017-10-31T12:38:12+07:00
draft: true
---

One good way to understand Ethereum is by creating your own Ethereum private network. I have been trying understand Ethereum in the past few weeks and I learned a lot of things just by creating it. I'll now write down what I got from creating Ethereum private network. And I'll update this post as I learn new things... hopefully

First of all, Ethereum client works by connecting to a network specified by its `networkid`. The normal network where people usually connecting to is **public network**. The `networkid` value of Ethereum public network is `1` (you can see it [here](https://github.com/ethereum/go-ethereum/blob/master/eth/config.go#L42)). But it is not the only network you can connect to, you can also create your own Ethereum network.

Typical Ethereum network consists of:

1. Bootnode

You might be wondering how an Ethereum node can connects to other nodes and broadcast messages. It turns out they have special nodes called `bootnode`. Basically, they works as node discovery where you can join and ask for other nodes that you can connect to.

You can see the default bootnodes value [here](https://github.com/ethereum/go-ethereum/blob/master/params/bootnodes.go#L21).

2. Normal node

They just normal node people usually run.

3. Miner

They are brave miners who make money out of air.

Actually you can run a node which works as normal mode and miner at the same time. But in this post I'm going to run them separately so we can understand better what they are doing.

## Requirements

I'll use Golang version of Ethereum clients. I haven't tried other client versions but they should also work, maybe...

You can download pre-build binary here: [https://geth.ethereum.org/downloads/](https://geth.ethereum.org/downloads/), please download one with name: `Geth & Tools`. Unlike `Geth`, it contains `geth` binary and some other binaries we need for this post.

## asd
