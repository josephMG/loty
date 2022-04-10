import { ethers } from "hardhat";
import Abi from "../artifacts/contracts/LotyMembership.sol/LotyMembership.json";

const RINKEBY_CONTRACT_ADDRESS = '0x6Ab2E18D13082176a8BCc89e14E802F5CB2359f9'

describe("LotyMembership", function () {
  it("Text on rinkeby", async function () {

    const provider = new ethers.providers.EtherscanProvider('rinkeby', process.env.ETHERSCAN_API_KEY)

    const wallet = await new ethers.Wallet(process.env.PRIVATE_KEY || '')
    const walletSigner = wallet.connect(provider)
    const contract = await new ethers.Contract(RINKEBY_CONTRACT_ADDRESS, Abi.abi, provider)

    const contractAttached = await contract.attach(RINKEBY_CONTRACT_ADDRESS)
    const contractConnected = await contractAttached.connect(walletSigner)

    const mint = await contractConnected.mint({ value: ethers.utils.parseEther('0.03') })
    const result = await mint.wait()

    console.log(result)
  });
});
