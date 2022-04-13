# Council of Kingz 2.0 SmartContract

Council of Kingz is the most innovative real estate acquisition project in the NFT and metaverse space.

Council of Kingz will develop each of the land plots we purchase with the intent to create gathering places, community centers, exclusive clubs, and specific districts that attract large amounts of foot traffic to create income through leasable spaces. Income that will further benefit the community in several capacities.

## Project installation

Clone down this repository. You will need `node` and `yarn`(or You can use `npm` instead of) installed globally on your machine.

### Get the code and dependencies:

    git clone https://github.com/wenbali-io/cok-blockchain-v2.git
    cd cok-blockchain-v2
    yarn

### Compile with:

    yarn compile

### Deploy the Contract to MainNet or TestNets with:

    yarn mainnet:deploy

The network prefix `mainnet` must match the hardhat configuration network settings (see `hardhat.config.ts`, `package.json`).

Just replace network prefix with your preferred network config name (for example `yarn rinkeby:deploy`)

### Verify the Contract with:

    yarn mainnet:verify

## Under the hood

- Solidity
- Hardhat
- TypeChain
- ethers
