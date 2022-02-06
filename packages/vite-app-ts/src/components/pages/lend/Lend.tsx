import { transactor } from 'eth-components/functions';
import { EthComponentsSettingsContext } from 'eth-components/models';
import { useGasPrice } from 'eth-hooks';
import { useEthersContext } from 'eth-hooks/context';
import { FC, useContext, useState } from 'react';

import { useAppContracts } from '~~/config/contractContext';
import { NETWORKS } from '~~/models/constants/networks';

export const Lend: FC = (props) => {
  const ethersContext = useEthersContext();
  const veNFT = useAppContracts('veNFTCollateral', NETWORKS.mumbai.chainId);

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
        <button className="btn btn-primary">Deposit</button>
      </div>
    </>
  );
};
