import { parseEther } from '@ethersproject/units';
import { Button } from 'antd';
import { useEthersContext } from 'eth-hooks/context';
import { FC } from 'react';

import { useAppContracts } from '~~/config/contractContext';

export const Check: FC = (props) => {
  const ethersContext = useEthersContext();
  const veNFT = useAppContracts('veNFTCollateral', ethersContext.chainId);

  console.log('veNFT', veNFT);

  const increaseAllowance = async (): Promise<void> => {
    await veNFT?.increaseAllowance('0xc035ea520cf981368ac9d9f585b150cecf9e2dfb', parseEther('1'));
  };

  return (
    <>
      <Button onClick={increaseAllowance}>Increase allowance</Button>
    </>
  );
};
