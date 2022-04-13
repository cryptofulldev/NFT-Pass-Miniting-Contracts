import { ethers } from "hardhat";
import { BigNumber } from "ethers";

// Defaults to e18 using amount * 10^18
export const getBigNumber = (amount: number, decimals = 18) => {
  return BigNumber.from(amount).mul(BigNumber.from(10).pow(decimals));
};

export const getNumber = (amount: number, decimals = 18) => {
  return BigNumber.from(amount)
    .div(BigNumber.from(10).pow(decimals))
    .toNumber();
};

export const getPaddedHexStrFromBN = (bn: BigNumber) => {
  const hexStr = ethers.utils.hexlify(bn);
  return ethers.utils.hexZeroPad(hexStr, 32);
};

export const getHexStrFromStr = (str: string) => {
  const strBytes = ethers.utils.toUtf8Bytes(str);
  return ethers.utils.hexlify(strBytes);
};

export const advanceBlock = () => {
  return ethers.provider.send("evm_mine", []);
};

export const advanceBlockTo = async (blockNumber: number) => {
  for (let i = await ethers.provider.getBlockNumber(); i < blockNumber; i++) {
    await advanceBlock();
  }
};

export const getChainId = async () => {
  console.log(await hre.config.networks.hardhat.chainId);
  return await hre.config.networks.hardhat.chainId;
};

export const getSignatureParameters = (signature: string) => {
  if (!ethers.utils.isHexString(signature)) {
    throw new Error(
      'Given value "'.concat(signature, '" is not a valid hex string.')
    );
  }
  var r = signature.slice(0, 66);
  var s = "0x".concat(signature.slice(66, 130));
  var v = "0x".concat(signature.slice(130, 132));
  v = ethers.BigNumber.from(v).toNumber();
  if (![27, 28].includes(v)) v += 27;
  return {
    r: r,
    s: s,
    v: v,
  };
};

export const constructMetaTransactionMessage = (
  nonce,
  salt,
  functionSignature,
  contractAddress
) => {
  return abi.soliditySHA3(
    ["uint256", "address", "uint256", "bytes"],
    [nonce, contractAddress, salt, toBuffer(functionSignature)]
  );
};
