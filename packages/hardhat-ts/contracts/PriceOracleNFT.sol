pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT

import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";
import "hardhat/console.sol";

contract PriceOracleNFT is ChainlinkClient {
  using Chainlink for Chainlink.Request;
  uint256 public price;
  string public test = "failed";

  address private oracle;
  bytes32 private jobId;
  uint256 private fee;

  /**
   * Network: Polygon Mumbai Testnet
   * Oracle: 0x58bbdbfb6fca3129b91f0dbe372098123b38b5e9
   * Job ID: da20aae0e4c843f6949e5cb3f7cfe8c4
   * LINK address: 0x326C977E6efc84E512bB9C30f76E30c160eD06FB
   * Fee: 0.01 LINK
   */
  constructor() public {
    setChainlinkToken(0x326C977E6efc84E512bB9C30f76E30c160eD06FB);
    oracle = 0xb33D8A4e62236eA91F3a8fD7ab15A95B9B7eEc7D;
    jobId = stringToBytes32("d5270d1c311941d0b08bead21fea7747");
    fee = 0.1 * 10**18;
  }

  /**
   * Create a Chainlink request to retrieve API response, find the target price
   * data, then multiply by 100 (to remove decimal places from price).
   */
  function requestBTCUSDPrice() public returns (bytes32 requestId) {
    Chainlink.Request memory request = buildChainlinkRequest(jobId, address(this), this.fulfill.selector);

    // Set the URL to perform the GET request on
    request.add("get", "https://min-api.cryptocompare.com/data/pricemultifull?fsyms=ETH&tsyms=USD");

    // Set the path to find the desired data in the API response, where the response format is:
    // {"RAW":
    //   {"ETH":
    //    {"USD":
    //     {
    //      "VOLUME24HOUR": xxx.xxx,
    //     }
    //    }
    //   }
    //  }
    request.add("path", "RAW.ETH.USD.PRICE");

    // // Multiply the result by 1000000000000000000 to remove decimals
    // int256 timesAmount = 10**18;
    // request.addInt("times", timesAmount);

    // Sends the request
    return sendChainlinkRequestTo(oracle, request, fee);
  }

  function fulfill(bytes32 _requestId, uint256 _price) public recordChainlinkFulfillment(_requestId) {
    price = _price;
    test = "test";
  }

  function stringToBytes32(string memory source) public pure returns (bytes32 result) {
    bytes memory tempEmptyStringTest = bytes(source);
    if (tempEmptyStringTest.length == 0) {
      return 0x0;
    }

    assembly {
      // solhint-disable-line no-inline-assembly
      result := mload(add(source, 32))
    }
  }
}
