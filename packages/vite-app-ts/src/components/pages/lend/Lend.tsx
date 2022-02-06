import { transactor } from 'eth-components/functions';
import { EthComponentsSettingsContext } from 'eth-components/models';
import { useGasPrice } from 'eth-hooks';
import { useEthersContext } from 'eth-hooks/context';
import { utils } from 'ethers';
import { FC, useContext, useState } from 'react';

import { useAppContracts } from '~~/config/contractContext';

export const Lend: FC = (props) => {
  const ethersContext = useEthersContext();
  const deNFT = useAppContracts('DeNFT', ethersContext.chainId);

  const ethComponentsSettings = useContext(EthComponentsSettingsContext);
  const [gasPrice] = useGasPrice(ethersContext.chainId, 'fast');
  const tx = transactor(ethComponentsSettings, ethersContext?.signer, gasPrice);

  const [amount, setAmount] = useState(0);
  const [duration, setDuration] = useState(0);
  const [collateralRatio, setCollateralRatio] = useState(0);

  return (
    <>
      <div className="p-10 card">
        <div className="form-control">
          <label className="label">
            <span className="label-text">Amount</span>
          </label>
          <input
            type="text"
            placeholder="Amount"
            className="input"
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
            className="input"
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
            className="input"
            onChange={(e): void => {
              setCollateralRatio(Number(e.target.value));
            }}
          />
        </div>
        <button
          className="btn btn-primary"
          onClick={async (): Promise<void> => {
            console.log('click');
            const result = await tx?.(
              deNFT?.depositLoanCapital(
                utils.parseEther(amount.toString()),
                duration.toString(),
                collateralRatio.toString()
              )
            );

            console.log(result);
          }}>
          Deposit
        </button>
      </div>
    </>
  );
};
