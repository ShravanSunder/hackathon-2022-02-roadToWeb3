import { useEthersContext } from 'eth-hooks/context';
import { FC, useEffect } from 'react';
import { useNFTBalances } from 'react-moralis';

export const Borrow: FC = (props) => {
  const { getNFTBalances, data, error, isLoading, isFetching } = useNFTBalances();
  const ethersContext = useEthersContext();

  useEffect(() => {
    getNFTBalances({ params: { address: ethersContext.account ?? '', chain: 'mumbai' } }).then(
      () => {},
      () => {}
    );
  }, [ethersContext.account]);

  return (
    <>
      <div className="container mx-auto">
        <div className="grid gap-4 grid-flow-col auto-cols-4">
          {data?.result?.map((nft) => (
            <>
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
            </>
          ))}
        </div>
      </div>
    </>
  );
};
