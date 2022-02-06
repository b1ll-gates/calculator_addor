const NFT = artifacts.require("NFT");
const Token = artifacts.require("NwBTC");
const Market = artifacts.require("Market");
const Stake = artifacts.require("Staking");

const nwBTC = `0x619F35DaE59cD6750e75B1FAE90C1543e03b6968`;


const nftAdrr= `0xad9027dCD44C093c5035965932B5EaD2E4C9d8b7`;
const tokenAddr = `0xF1F7F8D1546D291B5AC3DB9e9e9a10343e6af6a8`;

module.exports = async function(deployer) {
  //await deployer.deploy(Token);
  //const token = await Token.deployed()
  //await deployer.deploy(NFT,token.address);
  //const nft = await NFT.deployed()
  //await deployer.deploy(Market,token.address , nft.address);
  //const market = await Market.deployed()
  //await deployer.deploy(Stake,token.address , nft.address);
  await deployer.deploy(Stake,tokenAddr , nftAdrr);
  const stake = await Stake.deployed()

  //const contracts = { "token" : token.address, "nft" : nft.address, "market" : market.address, "stake" : stake.address };
  const contracts = { "stake" : stake.address };

  console.log(`Contract addresses: ${ JSON.stringify( contracts , null ,2 ) }`);
};

/*
module.exports = async function(deployer) {
  await deployer.deploy(NFT,nwBTC);
  const nft = await NFT.deployed()
  await deployer.deploy(Market, nwBTC , nft.address);
  const market = await Market.deployed()
  await deployer.deploy(Stake, nwBTC , nft.address);
  const stake = await Stake.deployed()

  const contracts = { "token" : nwBTC, "nft" : nft.address, "market" : market.address, "stake" : stake.address };

  console.log(`Contract addresses: ${ JSON.stringify( contracts , null ,2 ) }`);
};*/
