import { Balance } from 'eth-components/ant';
import { transactor } from 'eth-components/functions';
import { EthComponentsSettingsContext } from 'eth-components/models';
import { useContractReader, useGasPrice } from 'eth-hooks';
import { useEthersContext } from 'eth-hooks/context';
import { utils } from 'ethers';
import { FC, useContext, useState } from 'react';

import { useAppContracts } from '~~/config/contractContext';

export const Lend: FC = (props) => {
  const ethersContext = useEthersContext();
  const deNFT = useAppContracts('DeNFT', ethersContext.chainId);
  const token = useAppContracts('MockERC20', ethersContext.chainId);

  const ethComponentsSettings = useContext(EthComponentsSettingsContext);
  const [gasPrice] = useGasPrice(ethersContext.chainId, 'fast');
  const tx = transactor(ethComponentsSettings, ethersContext?.signer, gasPrice);

  const [balance] = useContractReader(token, token?.balanceOf, [ethersContext.account ?? '']);

  const [amount, setAmount] = useState(0);
  const [duration, setDuration] = useState(0);
  const [collateralRatio, setCollateralRatio] = useState(0);

  return (
    <>
      <h3>Token Balance:</h3>
      <Balance balance={balance} address={ethersContext.account} />
      <div className="container mx-auto">
        <div className="p-10 card">
          <div className="form-control">
            <label className="label">
              <span className="label-text">Amount</span>
            </label>
            <input
              type="text"
              placeholder="Amount"
              className="input input-bordered"
              onChange={(e): void => {
                setAmount(Number(e.target.value));
              }}
            />
          </div>
          <div className="form-control">
            <label className="label">
              <span className="label-text">Duration</span>
            </label>
            <input
              type="text"
              placeholder="Duration"
              className="input input-bordered"
              onChange={(e): void => {
                setDuration(Number(e.target.value));
              }}
            />
          </div>
          <div className="form-control">
            <label className="label">
              <span className="label-text">CollateralRatio</span>
            </label>
            <input
              type="text"
              placeholder="Collateral Ratio"
              className="input input-bordered"
              onChange={(e): void => {
                setCollateralRatio(Number(e.target.value));
              }}
            />
          </div>
          <button
            className="my-4 btn btn-primary"
            onClick={async (): Promise<void> => {
              const principal = utils.parseEther(amount.toString());
              await tx?.(token?.approve(deNFT?.address ?? '', principal));
              await tx?.(deNFT?.depositLoanCapital(principal, duration.toString(), collateralRatio.toString()));
            }}>
            Deposit
          </button>
        </div>
      </div>
    </>
  );
};
