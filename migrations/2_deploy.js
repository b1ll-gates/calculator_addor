const NFT = artifacts.require("NFT");
const Token = artifacts.require("NwBTC");
const Market = artifacts.require("Market");
const Stake = artifacts.require("Staking");

module.exports = async function(deployer) {
  await deployer.deploy(Token);
  const token = await Token.deployed()
  await deployer.deploy(NFT,token.address);
  const nft = await NFT.deployed()
  await deployer.deploy(Market,token.address , nft.address);
  const market = await Market.deployed()
  await deployer.deploy( Stake , token.address , nft.address );
  const stake = await Stake.deployed()

  const contracts = { "token" : token.address, "nft" : nft.address, "market" : market.address, "stake" : stake.address };

  console.log(`Contract addresses: ${ JSON.stringify( contracts , null ,2 ) }`);
};

