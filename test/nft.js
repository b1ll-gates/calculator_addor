//const ERC20 = artifacts.require("./ERC20.sol");
const NFT = artifacts.require("./NFT.sol");
const Token = artifacts.require("NwBTC");
const Market = artifacts.require("Market");
const Staking = artifacts.require("Staking");

//*** Compile the contract 
//      `truffle compile --compile-all`
//*** Deploy the contracts
//      `truffle migrate`

const BODY_HEX = `0x1000061100061200061300060e01060f01071001081101081201081301081401061501060d02060e02080f020810020811020812020813020814020815020816023b0d03060e03080f03081003081103081203081303081403081503081603060c04060d04080e04080f04081004081104081204081304081404081504081604081704060c05060d05080e05080f05081005081105081205081305081405081505081605081705060c06060d06080e06080f06081006081106081206081306081406081506081606081706060c07060d07080e07080f07081007081107081207081307081407081507081607081707060c08060d08080e08080f08081008081108081208081308081408081508081608081708060c09060d09080e09080f09081009081109081209081309081409081509081609081709060d0a060e0a080f0a08100a08110a08120a08130a08140a08150a08160a060d0b060e0b080f0b08100b08110b08120b08130b08140b08150b08160b060e0c060f0c06100c08110c08120c08130c08140c08150c06100d06110d08120d08130d06140d06100e06110e06120e08130e08140e06100f06110f08120f08130f08140f060c10060d10060e10060f10061010061110081210081310081410060b11060c11080d11080e11080f11081011081111081211081311061411060a12060b12060c12080d12080e12080f12081012081112081212061312060213060313060413060513060a13060b13080c13080d13080e13060f13061013061113061213060114060214060314080414080514060614060714060914060a14060b14080c14080d14060015060315060415060715060815060915060a15080b15080c15060d15060016060116080416060516060616060716060816080916080a16070b16080c16060017060117080617060717060817060917080a17080b17060c1706`;

const MOUTHS = [
    `0x1009071109071209071309071409070f0a07110a07130a07150a07100b07110b07120b07130b07140b07`,
    `0x0e09071509070f0a07140a07100b07110b07120b07130b07`,
    `0x0f0a07140a07100b07110b07120b07130b07`,
    `0x150907140a07100b07110b07120b07130b07`,
    `0x100907110907120907130907140907150907110a07140a07100b07110b07120b07130b07`,
    `0x100907110907120907130907110a07130a07100b07110b07120b07`,
    `0x0f0a07100a07110a07120a07130a07140a07`,
    `0x0800090601090901090902090703090705090906090808090a0809090909090a090a0a1c0b0a130c0a130d0a130e0a1b0f0a13100a130a0b1d0b0b1c0c0b1b0d0b130e0b130f0b13`,
    `0x0f0a09110a09130a09100b09120b09140b09`
];

const EYES = [
    `0x0e05010f05011005011305011405011505010f0601100601140601150601`,
    `0x0e05010f0501100501130501140501150501100601150601`,
    `0x0f05011405010e0601100601130601150601`,
    `0x0e06010f0601100601130601140601150601`,
    `0x0b04010c04010d04010e04010f04011004011104011204011304011404011504011604011704010c05010d05080e05010f05011005011105011205011305081405011505011605010c06010d06010e06080f06011006011206011306011406081506011606010d07010e07010f0701130701140701150701`,
    `0x0d04010e04010f04011304011404011504010c05010d05080e05010f05081005011205011305081405011505081605010c06010d06010e06080f06081006011206011306011406081506081606010d07010e07010f0701130701140701150701`,
    `0x0c04010d04010e04010f04011004011104011204011304011404011504011604011704010c05010e05011005011205011405011605010c06010d06011006011206011306011606010d07010e07010f0701130701140701150701`,
    `0x0e05010f05011005011305011405011505010e0601100601130601150601`,
    `0x0e05060f053b10050613050614053b1505060e06060f0606100606130606140606150606`
];


var inst;
var tokenId;
var address;

var _token;
var _nft;
var _markerplace;

contract("NFT + Token + Marketplace", (accounts) => {
 //account #0 is the contract owner
 console.log("=========================================="); 
 console.log( `Accounts: ${JSON.stringify( accounts, null,2)}`);
 console.log("==========================================");

const testECR20 = it("should test the token", async (  ) => {
        let r;
        let tokenInst = await Token.deployed();
        assertAddress( tokenInst.address );
        console.log(`TOKEN instance@: ${ tokenInst.address }`);
        
        let nftInst = await NFT.deployed();
        console.log(`NFT instance@: ${ nftInst.address }`);
        assertAddress( nftInst.address );
            
        let marketInst = await Market.deployed();
        assertAddress( marketInst.address );
        console.log(`MARKET instance @: ${ marketInst.address }`);
     
        let stakeInst = await Staking.deployed();
        assertAddress( stakeInst.address );
        console.log(`STAKING instance @: ${ stakeInst.address }`);
        console.log("==========================================");

        console.log(`$ ECR20: totalSupply( ) ->`);
        r = await tokenInst.totalSupply();
        console.log(web3.utils.fromWei( r , "ether") );
        console.log("==========================================");

        console.log(`$ ECR20 : ballanceOf(${ accounts[0] }) ->`);
        let balance1 = await tokenInst.balanceOf.call( accounts[0] );
        console.log(web3.utils.fromWei( balance1 , "ether" ) );
        console.log("==========================================");
        
        console.log(`$ ECR20 : ballanceOf(${ accounts[1] }) ->`);
        let balance2 = await tokenInst.balanceOf.call( accounts[1] );
        console.log(web3.utils.fromWei( balance2 , "ether" ) );
        console.log("==========================================");

        console.log(`$ ECR20 (contract) : ballanceOf(${ tokenInst.address }) ->`);
        balance2 = await tokenInst.balanceOf.call( tokenInst.address );
        console.log(web3.utils.fromWei( balance2 , "ether" ) );
        console.log("==========================================");


        console.log(`$ ECR20 : faucet(${ accounts[1] }) ->`);
        r = await tokenInst.faucet( {from:accounts[1]} );
        console.log(JSON.stringify( r['receipt']['logs'][0]['args'], null , 2 ) );
        console.log("==========================================");

        console.log(`$ ECR20 : ballanceOf(${ accounts[1] }) ->`);
        balance2 = await tokenInst.balanceOf.call( accounts[1] );
        console.log(web3.utils.fromWei( balance2 , "ether" ) );
        console.log("==========================================");
        
        console.log(`$ ECR20 : faucet(${ accounts[1] }) ->`);
        r = await tokenInst.faucet( {from:accounts[1]} );
        console.log(JSON.stringify( r['receipt']['logs'][0]['args'], null , 2 ) );
        console.log("==========================================");

        console.log(`$ ECR20 : ballanceOf(${ accounts[1] }) ->`);
        balance2 = await tokenInst.balanceOf.call( accounts[1] );
        console.log(web3.utils.fromWei( balance2 , "ether" ) );
        console.log("==========================================");


        console.log(`$ ECR20 : transfer(${ accounts[1] } , ${ web3.utils.toWei("100.5","ether") }) ->`);
        r = await tokenInst.transfer( accounts[1] , web3.utils.toWei("1000.5","ether") ); //Works because default account is token owner
        console.log(JSON.stringify( r['receipt']['logs'][0]['args'], null , 2 ) );
        console.log("==========================================");
  
        console.log(`$ ECR20 : transfer(${ accounts[4] } , ${ web3.utils.toWei("5000.5","ether") }) ->`);
        r = await tokenInst.transfer( accounts[4] , web3.utils.toWei("5000.5","ether") ); //Works because default account is token owner
        console.log(JSON.stringify( r['receipt']['logs'][0]['args'], null , 2 ) );
        console.log("==========================================");

        console.log(`$ ECR20 : approve(${ accounts[0] } , ${ web3.utils.toWei("10.5","ether") } , {from:${accounts[1]}}) ->`);
        r = await tokenInst.approve( accounts[0] , web3.utils.toWei("10.5","ether") , {from:accounts[1]});
        console.log(JSON.stringify( r['receipt']['logs'][0]['args'], null , 2 ) );
        console.log("==========================================");
        console.log(`$ ECR20 : allowance(${ accounts[1] } , ${accounts[0]}) ->`);
        r = await tokenInst.allowance.call(accounts[1] , accounts[0] );
        console.log(web3.utils.fromWei( r , "ether" ) );
        console.log("==========================================");
        console.log(`$ ECR20 : transferFrom(${ accounts[1] } , ${accounts[0]}, ${ web3.utils.toWei("10.5","ether") }) ->`);
        r = await tokenInst.transferFrom( accounts[1] , accounts[2] , web3.utils.toWei("10.5","ether") , {from: accounts[0] } );
        console.log(JSON.stringify( r['receipt']['logs'][0]['args'], null , 2 ) );
        console.log("==========================================");
 
        console.log(`$ ECR20 : ballanceOf(${ accounts[0] }) ->`);
        r = await tokenInst.balanceOf.call( accounts[0] );
        console.log(web3.utils.fromWei( r , "ether" ) );
        console.log("==========================================");
        
        console.log(`$ ECR20 : ballanceOf(${ accounts[1] }) ->`);
        r = await tokenInst.balanceOf.call( accounts[1] );
        console.log(web3.utils.fromWei( r , "ether" ) );
        console.log("==========================================");
     
        console.log(`$ ECR20 : ballanceOf(${ accounts[2] }) ->`);
        r = await tokenInst.balanceOf.call( accounts[2] );
        console.log(web3.utils.fromWei( r , "ether" ) );
        
        console.log("==========================================");
        console.log("++++++++++++++++++++++++++++++++++++++++++");
        console.log("==========================================");
                 
        console.log("$ NFT: setArtWork( body, name, eye, mouth ) ->");
        r = await nftInst.setArtwork( BODY_HEX , "sperm" , EYES , MOUTHS , {from: accounts[0] })
        console.log(JSON.stringify( r, null , 2) );
        console.log("==========================================");
    
        console.log("$ NFT: _price ->");
        r = await nftInst._price.call( ); 
        console.log(JSON.stringify(  web3.utils.fromWei(r,"ether") , null , 2 ) );
        console.log("==========================================");
       
        console.log("$ NFT: setPrice( 6000000 ) ->");
        r = await nftInst.setPrice( web3.utils.toWei("0.1","ether" ) ,{ from: accounts[0] }); 
        console.log(JSON.stringify(  r, null , 2 ) );
        console.log("==========================================");
        
        console.log("$ NFT: _price ->");
        r = await nftInst._price.call( ); 
        console.log(JSON.stringify(  web3.utils.fromWei(r,"ether") , null , 2 ) );
        console.log("==========================================");

        console.log(`$ NFT: walletOfOwner( ${ accounts[0] } ) ->`);
        r = await nftInst.walletOfOwner.call( accounts[0] ); 
        console.log(JSON.stringify(  r, null , 2 ) );
        console.log("==========================================");

        console.log(`$ NFT: _stakeAddress ->`);
        r = await nftInst._stakeAddress.call(); 
        console.log(JSON.stringify(  r, null , 2 ) );
        console.log("==========================================");

        console.log(`$ NFT: setStakeAddress( ${ stakeInst.address } ) ->`);
        r = await nftInst.setStakeAddress( stakeInst.address , { from: accounts[0] } ); 
        console.log(JSON.stringify(  r, null , 2 ) );
        console.log("==========================================");

        console.log(`$ NFT: _stakeAddress ->`);
        r = await nftInst._stakeAddress.call(); 
        console.log(JSON.stringify(  r , null , 2 ) );
        console.log("==========================================");

        r = await tokenInst.approve( nftInst.address , web3.utils.toWei("100","ether") , {from:accounts[1]});
        console.log(JSON.stringify(  r['receipt']['logs'][0]['args'], null , 2 ) );
        r = await tokenInst.allowance.call(accounts[1] , nftInst.address );
        console.log(JSON.stringify( web3.utils.fromWei( r , "ether") , null , 2 ) );
        
        console.log(`$ NFT: mint() ->`);
        r = await nftInst.mint( { from: accounts[1], value: web3.utils.toWei("10","ether") } ); 
        console.log(JSON.stringify(  r['receipt']['logs'][0]['args'], null , 2 ) );
        console.log("==========================================");

        console.log(`$ NFT: mint() ->`);
        r = await nftInst.mint( { from: accounts[1], value: web3.utils.toWei("10","ether") } ); 
        console.log(JSON.stringify(  r['receipt']['logs'][0]['args'], null , 2 ) );
        console.log("==========================================");

        console.log(`$ NFT: mint() ->`);
        r = await nftInst.mint( { from: accounts[1], value: web3.utils.toWei("10","ether") } ); 
        console.log(JSON.stringify(  r['receipt']['logs'][0]['args'], null , 2 ) );
        console.log("==========================================");
    
        console.log(`$ NFT: mint() ->`);
        r = await nftInst.mint( { from: accounts[1], value: web3.utils.toWei("10","ether") } ); 
        console.log(JSON.stringify(  r['receipt']['logs'][0]['args'], null , 2 ) );
        console.log("==========================================");

        console.log(`$ NFT: mint() ->`);
        r = await nftInst.mint( { from: accounts[1], value: web3.utils.toWei("10","ether") } ); 
        console.log(JSON.stringify(  r['receipt']['logs'][0]['args'], null , 2 ) );
        console.log("==========================================");

        console.log(`$ ECR20 : ballanceOf(${ stakeInst.address }) ->`);
        r = await tokenInst.balanceOf.call( stakeInst.address );
        console.log(web3.utils.fromWei( r , "ether" ) );
        console.log("==========================================");
       
      /*  console.log(`$ NFT: tokenURI( 1 ) ->`);
        r = await nftInst.tokenURI.call( 1 ); 
        console.log(JSON.stringify(  r, null , 2 ) );
        console.log("==========================================");
      */
        console.log(`$ NFT: walletOfOwner( ${ accounts[1] } ) ->`);
        r = await nftInst.walletOfOwner.call( accounts[1] ); 
        console.log(JSON.stringify(  r, null , 2 ) );
        console.log("==========================================");

        console.log("==========================================");
        console.log("++++++++++++++++++++++++++++++++++++++++++");
        console.log("==========================================");
       
        console.log(`$ NFT: safeTransferFrom( ${ accounts[1]} , ${marketInst.address} , 1 ) ->`);
        r = await nftInst.safeTransferFrom( accounts[1] , marketInst.address , 1 , { from : accounts[1] }); 
        console.log(JSON.stringify(  r['receipt']['logs'][1]['args'], null , 2 ) );
        console.log("==========================================");
        
        console.log(`$ MARKET: setStakeLiquidity( ${ accounts[3] } ) ->`);
        r = await marketInst.setStakeLiquidity( accounts[3] ,{ from: accounts[0] } ); 
        console.log(JSON.stringify(  r, null , 2 ) );
        console.log("==========================================");

        console.log(`$ MARKET: auctionTimePeriod ->`);
        r = await marketInst.auctionTimePeriod.call( ); 
        console.log(JSON.stringify(  r, null , 2 ) );
        console.log("==========================================");

        console.log(`$ MARKET: getTokensOnSale( ${ accounts[1]} ) ->`);
        r = await marketInst.getTokensOnSale.call( accounts[1] ); 
        console.log(JSON.stringify(  r, null , 2 ) );
        console.log("==========================================");
        let _auctionID = r[0];
        console.log(`$ MARKET: getAllTokensOnSale( ${ nftInst.address } ) ->`);
        r = await marketInst.getAllTokensOnSale.call( nftInst.address ); 
        console.log(JSON.stringify(  r, null , 2 ) );
        console.log("==========================================");

        console.log(`$ MARKET: getAuction( ${ r[0] } ) ->`);
        r = await marketInst.getAuction.call( r[0] ); 
        console.log(JSON.stringify(  r, null , 2 ) );
        console.log("==========================================");

        console.log(`$ MARKET: setBuyNow( ${ _auctionID } , 0.1  ) ->`);
        r = await marketInst.setBuyNow( _auctionID , web3.utils.toWei("0.1","ether") , { from: accounts[1] } ); 
        console.log(JSON.stringify(  r, null , 2 ) );
        console.log("==========================================");

        console.log(`$ MARKET: getAuction( ${ _auctionID } ) ->`);
        r = await marketInst.getAuction.call( _auctionID ); 
        console.log(JSON.stringify(  r, null , 2 ) );
        console.log("==========================================");

        console.log(`$ ECR20 : approve(${ marketInst.address } , ${ web3.utils.toWei("0.1","ether") } , {from:${accounts[4]}}) ->`);
        r = await tokenInst.approve( marketInst.address , web3.utils.toWei("0.1","ether") , {from:accounts[4]});
        console.log(JSON.stringify( r['receipt']['logs'][0]['args'], null , 2 ) );
        console.log("==========================================");
        console.log(`$ ECR20 : allowance(${ accounts[4] } , ${ marketInst.address} ) ->`);
        r = await tokenInst.allowance.call(accounts[4] , marketInst.address);
        console.log(web3.utils.fromWei( r , "ether" ) );
        console.log("==========================================");
        
        console.log(`$ ECR20 : ballanceOf(${ accounts[1] }) ->`);
        r = await tokenInst.balanceOf.call( accounts[4] );
        console.log(web3.utils.fromWei( r , "ether" ) );
        console.log("==========================================");

        console.log(`$ MARKET: payNow( ${ _auctionID } ) ->`);
        r = await marketInst.payNow( _auctionID , {from: accounts[4]} ); 
        console.log(JSON.stringify(  r['receipt']['logs'][0]['args'], null , 2 ) );
        console.log("==========================================");

        console.log(`$ ECR20 : ballanceOf(${ accounts[1] }) ->`);
        r = await tokenInst.balanceOf.call( accounts[4] );
        console.log(web3.utils.fromWei( r , "ether" ) );
        console.log("==========================================");
     
        console.log(`$ NFT: walletOfOwner( ${ accounts[1] } ) ->`);
        r = await nftInst.walletOfOwner.call( accounts[4] ); 
        console.log(JSON.stringify(  r, null , 2 ) );
        console.log("==========================================");

        console.log(`$ NFT: safeTransferFrom( ${ accounts[4]} , ${marketInst.address} , 1 ) ->`);
        r = await nftInst.safeTransferFrom( accounts[4] , marketInst.address , 1 , { from : accounts[4] }); 
        console.log(JSON.stringify(  r['receipt']['logs'][1]['args'], null , 2 ) );
        console.log("==========================================");
        
        console.log(`$ MARKET: getAllTokensOnSale( ${ nftInst.address } ) ->`);
        r = await marketInst.getAllTokensOnSale.call( nftInst.address ); 
        console.log(JSON.stringify(  r, null , 2 ) );
        console.log("==========================================");
        _auctionID = r[0];
        
        console.log(`$ MARKET: maxBidChange ->`);
        r = await marketInst.maxBidChange.call(); 
        console.log(JSON.stringify(  web3.utils.fromWei( r,"ether") , null , 2 ) );
        console.log("==========================================");

        console.log(`$ MARKET: setBid( ${ _auctionID } ) ->`);
        r = await marketInst.setBid( _auctionID , web3.utils.toWei("0.2","ether") , {from: accounts[2]} ); 
        console.log(JSON.stringify(  r, null , 2 ) );
        console.log("==========================================");

        console.log(`$ MARKET: getAuction( ${ _auctionID } ) ->`);
        r = await marketInst.getAuction.call( _auctionID ); 
        console.log(JSON.stringify(  r, null , 2 ) );
        console.log("==========================================");
        
        console.log(`$ MARKET: reNewAuction( ${ _auctionID } ) ->`);
        r = await marketInst.reNewAuction( _auctionID, {from:accounts[4]} ); 
        console.log(JSON.stringify(  r, null , 2 ) );
        console.log("==========================================");
        
        console.log(`$ MARKET: getAuction( ${ _auctionID } ) ->`);
        r = await marketInst.getAuction.call( _auctionID ); 
        console.log(JSON.stringify(  r, null , 2 ) );
        console.log("==========================================");

        console.log(`$ MARKET: completeAuction( ${ _auctionID } ) ->`);
        r = await marketInst.completeAuction( _auctionID ); 
        console.log(JSON.stringify(  r, null , 2 ) );
        console.log("==========================================");

        console.log(`$ MARKET: getWonAuctions( ${ accounts[2]} ) ->`);
        r = await marketInst.getWonAuctions( accounts[2] ); 
        console.log(JSON.stringify(  r, null , 2 ) );
        console.log("==========================================");

         console.log(`$ ECR20 : approve(${ marketInst.address } , ${ web3.utils.toWei("2","ether") } , {from:${accounts[4]}}) ->`);
        r = await tokenInst.approve( marketInst.address , web3.utils.toWei("2","ether") , {from:accounts[2]});
        console.log(JSON.stringify( r['receipt']['logs'][0]['args'], null , 2 ) );
        console.log("==========================================");
        console.log(`$ ECR20 : allowance(${ accounts[2] } , ${ marketInst.address} ) ->`);
        r = await tokenInst.allowance.call(accounts[2] , marketInst.address);
        console.log(web3.utils.fromWei( r , "ether" ) );
        console.log("==========================================");

        console.log(`$ ECR20 : ballanceOf(${ accounts[1] }) ->`);
        r = await tokenInst.balanceOf.call( accounts[2] );
        console.log(web3.utils.fromWei( r , "ether" ) );
        console.log("==========================================");
 
        console.log(`$ MARKET: payForWonAuction( ${ _auctionID } ) ->`);
        r = await marketInst.payForWonAuction( _auctionID , {from: accounts[2]} ); 
        console.log(JSON.stringify(  r['receipt']['logs'][0]['args'], null , 2 ) );
        console.log("==========================================");

        console.log(`$ ECR20 : ballanceOf(${ accounts[1] }) ->`);
        r = await tokenInst.balanceOf.call( accounts[2] );
        console.log(web3.utils.fromWei( r , "ether" ) );
        console.log("==========================================");
 
        console.log(`$ NFT: walletOfOwner( ${ accounts[2] } ) ->`);
        r = await nftInst.walletOfOwner.call( accounts[2] ); 
        console.log(JSON.stringify(  r, null , 2 ) );
        console.log("==========================================");

        console.log(`$ NFT: safeTransferFrom( ${ accounts[2]} , ${marketInst.address} , 1 ) ->`);
        r = await nftInst.safeTransferFrom( accounts[2] , marketInst.address , 1 , { from : accounts[2] }); 
        console.log(JSON.stringify(  r['receipt']['logs'][1]['args'], null , 2 ) );
        console.log("==========================================");
 
        console.log(`$ MARKET: getAllTokensOnSale( ${ nftInst.address } ) ->`);
        r = await marketInst.getAllTokensOnSale.call( nftInst.address ); 
        console.log(JSON.stringify(  r, null , 2 ) );
        console.log("==========================================");
        _auctionID = r[0];
     
        console.log(`$ MARKET: withdrawAuction( ${ _auctionID } ) ->`);
        r = await marketInst.withdrawAuction( _auctionID , {from: accounts[2]} ); 
        console.log(JSON.stringify(  r['receipt']['logs'][0]['args'], null , 2 ) );
        console.log("==========================================");

        console.log("==========================================");
        console.log("++++++++++++++++++++++++++++++++++++++++++");
        console.log("==========================================");
             
        console.log(`$ NFT: safeTransferFrom( ${ accounts[2]} , ${stakeInst.address} , 1 ) ->`);
        r = await nftInst.safeTransferFrom( accounts[2] , stakeInst.address , 1 , { from : accounts[2] }); 
        console.log(JSON.stringify(  r['receipt']['logs'][1]['args'], null , 2 ) );
        console.log("==========================================");
      
        console.log(`$ STAKING: allStaked( ${ accounts[2] } ) ->`);
        r = await stakeInst.allStaked.call( accounts[2] ); 
        console.log(JSON.stringify(  r, null , 2 ) );
        console.log("==========================================");
        let stakeId = r[0];
        //can't test block.timestamp dependent code

        console.log(`$ STAKING: getStakeDetails( ${ stakeId } ) ->`);
        r = await stakeInst.getStakeDetails.call( stakeId ,{from:accounts[2]}); 
        console.log(JSON.stringify(  r, null , 2 ) );
        console.log("==========================================");
        
        console.log(`$ STAKING: stakeTokenRewards( ${ stakeId } ) ->`);
        r = await stakeInst.stakeTokenRewards.call( stakeId ,{from:accounts[2]}); 
        console.log(JSON.stringify(  r, null , 2 ) );
        console.log("==========================================");


        console.log(`$ STAKING: stakeClaimRewards( ${ stakeId } ) ->`);
        r = await stakeInst.stakeClaimRewards( stakeId , {from:accounts[2]} ); 
        console.log(JSON.stringify(  r, null , 2 ) );
        console.log("==========================================");

        console.log(`$ ECR20 : ballanceOf(${ accounts[2] }) ->`);
        r = await tokenInst.balanceOf.call( accounts[2] );
        console.log(web3.utils.fromWei( r , "ether" ) );
        console.log("==========================================");



    });
});


var sleep = (delay) => new Promise( (resolve) => setTimeout( resolve, delay));

var assertAddress = (address) => {
    assert.notEqual(address, 0x0);
    assert.notEqual(address, "");
    assert.notEqual(address, null);
    assert.notEqual(address, undefined);
};

var assertRevert = async (promise, message) => {
  let noFailureMessage;
  try {
    await promise;

    if (!message) { 
      noFailureMessage = 'Expected revert not received' 
    } else {
      noFailureMessage = message;
    }

    assert.fail();
  } catch (error) {
    if (noFailureMessage) {
      assert.fail(0, 1, message);
    }
    const revertFound = error.message.search('revert') >= 0;
    assert(revertFound, `Expected "revert", got ${error} instead`);
  }
};
