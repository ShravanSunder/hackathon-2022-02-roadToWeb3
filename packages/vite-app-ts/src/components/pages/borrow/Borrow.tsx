import { StaticJsonRpcProvider } from '@ethersproject/providers';
import { Address } from 'eth-components/ant';
import { useContractReader } from 'eth-hooks';
import { useEthersContext } from 'eth-hooks/context';
import { BigNumber, utils } from 'ethers';
import { FC, useEffect, useState } from 'react';
import { useNFTBalances } from 'react-moralis';

import { useAppContracts } from '~~/config/contractContext';

interface Loan {
  id: number | undefined;
  duration?: number;
  collateralRatio?: number;
  lender?: string;
  amount?: BigNumber;
}

export interface IBorrowProps {
  mainnetProvider: StaticJsonRpcProvider | undefined;
}

export const Borrow: FC<IBorrowProps> = (props) => {
  const { mainnetProvider } = props;
  const { getNFTBalances, data, error, isLoading, isFetching } = useNFTBalances();
  const ethersContext = useEthersContext();
  const deNFT = useAppContracts('DeNFT', ethersContext.chainId);

  const [numberOfLoans] = useContractReader(deNFT, deNFT?.totalNumLoans);
  const [loans, setLoans] = useState<Loan[]>([]);
  useEffect(() => {
    const getLoans = async (): Promise<void> => {
      const loans: Loan[] = [];
      if (!numberOfLoans) return;
      for (let i = 0; i < numberOfLoans.toNumber(); i++) {
        const loan = await deNFT?.loanIdToLoan(i);
        if (!loan) continue;

        const [loanId, loanPrincipalAmount, collateralRatio] = loan;
        console.log('loan', loan);
        loans.push({
          id: loanId.toNumber(),
          amount: loanPrincipalAmount,
          collateralRatio: collateralRatio.toNumber(),
          lender: loan.lender,
        });
      }
      setLoans(loans);
    };
    // ugghh linter
    getLoans().then(
      () => {},
      () => {}
    );
  }, [ethersContext.account]);

  useEffect(() => {
    getNFTBalances({ params: { address: ethersContext.account ?? '', chain: 'mumbai' } }).then(
      () => {},
      () => {}
    );
  }, [numberOfLoans]);

  useEffect(() => {});
  return (
    <>
      <div className="container mx-auto">
        <div className="my-4 shadow-md card card-bordered">
          {loans?.map((loan) => (
            <div key={loan.id} className="flex items-center justify-around m-1">
              <div>id: {loan.id}</div>
              <div>Amount: {utils.formatEther(loan.amount ?? '')}</div>
              <div className="flex items-center">
                Lender: <Address address={loan.lender} ensProvider={mainnetProvider} fontSize={16} />
              </div>
              <button className="btn btn-secondary btn-sm">Borrow</button>
            </div>
          ))}
        </div>
        <div className="grid gap-4 grid-flow-col auto-cols-4">
          {data?.result?.map((nft) => (
            <div key={nft.token_id}>
              <div className="shadow-md card card-bordered">
                <figure>
                  <img src={nft.metadata.image} />
                </figure>
                <div className="card-body">
                  <h2 className="card-title">{nft.name}</h2>
                  <p className="overflow-y-auto max-h-20 text-clip ...">{nft.metadata.description}</p>
                  <div className="justify-end card-actions">
                    <button className="btn btn-secondary">Borrow</button>
                  </div>
                </div>
              </div>
            </div>
          ))}
        </div>
      </div>
    </>
  );
};
