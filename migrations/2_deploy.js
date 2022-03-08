const NFT_PXLs = artifacts.require("PXLs");
const NFT_KINGs = artifacts.require("KINGs");
const Token = artifacts.require("NwBTC");
const Market = artifacts.require("Market");
const Stake = artifacts.require("Staking");

module.exports = async function(deployer) {
  await deployer.deploy(Token);
  const token = await Token.deployed()
  console.log( "Token is deployed")
  await deployer.deploy(NFT_PXLs,token.address);
  const nft = await NFT_PXLs.deployed()
  console.log( "NFT PXLs is deployed" );
  await deployer.deploy(NFT_KINGs,token.address);
  const nft2 = await NFT_KINGs.deployed()
  console.log( "NFT KINGs is deployed" );
  await deployer.deploy(Market, nft.address);
  const market = await Market.deployed()
  await deployer.deploy( Stake , token.address , nft.address );
  const stake = await Stake.deployed()

  const contracts = { "token" : token.address, "PXLs" : nft.address, "KINGs" : nft2.address, "market" : market.address, "stake" : stake.address };

  console.log(`Contract addresses: ${ JSON.stringify( contracts , null ,2 ) }`);
};

