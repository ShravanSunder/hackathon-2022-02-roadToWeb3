pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT

import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";

/*
---------------------------------
CHAINLINK-POLYGON NETWORK DETAILS
---------------------------------
name: "mumbai",
linkToken: "0x326C977E6efc84E512bB9C30f76E30c160eD06FB",
ethUsdPriceFeed: "0x0715A7794a1dc8e42615F059dD6e406A6594651A",
keyHash:
    "0x6e75b569a01ef56d18cab6a8e71e6600d6ce853834d4a5748b720d06f878b3a4",
vrfCoordinator: "0x8C7382F9D8f56b33781fE506E897a4F1e2d17255",
oracle: "0x58bbdbfb6fca3129b91f0dbe372098123b38b5e9",
jobId: "da20aae0e4c843f6949e5cb3f7cfe8c4",

name: "polygon",
linkToken: "0xb0897686c545045afc77cf20ec7a532e3120e0f1",
ethUsdPriceFeed: "0xF9680D99D6C9589e2a93a78A04A279e509205945",
keyHash:
    "0xf86195cf7690c55907b2b611ebb7343a6f649bff128701cc542f0569e2c549da",
vrfCoordinator: "0x3d2341ADb2D31f1c5530cDC622016af293177AE0",
oracle: "0x0a31078cd57d23bf9e8e8f1ba78356ca2090569e",
jobId: "12b86114fa9e46bab3ca436f88e1a912",
*/

/**
 * Chainlink Oracle: Call opensea api and get floor price fo a collection
 */
contract PriceOracleNFT is ChainlinkClient {
  using Chainlink for Chainlink.Request;
  string public testStatus = "init";

  // 1 day
  uint256 updateFrequency = 60 * 60 * 24;

  struct CollectionPrice {
    string collectionName;
    uint256 floorPrice;
    uint256 timestamp;
    bytes32 requestId;
  }
  mapping(string => CollectionPrice) public floorPriceMapping;

  mapping(string => bytes32) private currentRequestsByName;

  struct CollectionRequests {
    uint256 timestamp;
    string collectionName;
  }
  mapping(bytes32 => CollectionRequests) private currentRequestsById;

  address private oracle;
  bytes32 private jobId;
  uint256 private fee;

  event OpenSeaFloorPriceRequested(bytes32 requestId, string url, uint256 timestamp);
  event OpenSeaFloorPriceUpdated(bytes32 requestId, uint256 floorPrice, uint256 timestamp);
  event OpenSeaFloorPriceRereived(bytes32 requestId, uint256 floorPrice, uint256 timestamp);

  constructor() {
    setChainlinkToken(0x326C977E6efc84E512bB9C30f76E30c160eD06FB);
    oracle = 0x58BBDbfb6fca3129b91f0DBE372098123B38B5e9;
    jobId = "da20aae0e4c843f6949e5cb3f7cfe8c4";
    fee = 0.01 * 10**18;
  }

  /**
   * Create a Chainlink request to retrieve API response, find the target price
   * data, then multiply by 10**18 (to remove decimal places from price).
   */
  function requestOpenSeaFloorPrice(string memory collectionName) public returns (bytes32 requestId) {
    testStatus = "check recent";

    // check if there is already a result that's recent
    if (floorPriceMapping[collectionName].timestamp != 0) {
      if (block.timestamp - floorPriceMapping[collectionName].timestamp < updateFrequency) {
        return floorPriceMapping[collectionName].requestId;
      }
    }

    testStatus = "check requests";

    // check if a request is in progress that's valid
    if (currentRequestsByName[collectionName] != 0 && currentRequestsById[currentRequestsByName[collectionName]].timestamp != 0) {
      if (block.timestamp - currentRequestsById[currentRequestsByName[collectionName]].timestamp < updateFrequency) {
        return currentRequestsByName[collectionName];
      }

      // if there any current request and its too old, delete it and refetch
      delete currentRequestsById[currentRequestsByName[collectionName]];
      delete currentRequestsByName[collectionName];
    }

    testStatus = "create request";

    // create a new request
    Chainlink.Request memory request = buildChainlinkRequest(jobId, address(this), this.fulfill.selector);

    // Set the URL to perform the GET request on
    string memory url = conactUrl(collectionName);
    request.add("get", url);
    request.add("path", "stats.floor_price");

    // multiple by 10^18 to remove decimal places
    int256 timesAmount = 10**18;
    request.addInt("times", timesAmount);

    testStatus = "requesting";
    // send the request
    bytes32 result = sendChainlinkRequestTo(oracle, request, fee);
    // save the request data
    currentRequestsById[result] = CollectionRequests(block.timestamp, collectionName);

    emit OpenSeaFloorPriceRequested(result, url, block.timestamp);
    return result;
  }

  /**
   *  Callback function to retrieve the response from the Chainlink request.
   */
  function fulfill(bytes32 _requestId, uint256 _price) public recordChainlinkFulfillment(_requestId) {
    testStatus = "saving";

    floorPriceMapping[currentRequestsById[_requestId].collectionName] = CollectionPrice(
      currentRequestsById[_requestId].collectionName,
      _price,
      block.timestamp,
      _requestId
    );

    emit OpenSeaFloorPriceUpdated(_requestId, _price, block.timestamp);

    // delete any current requests
    delete currentRequestsByName[currentRequestsById[_requestId].collectionName];
    delete currentRequestsById[_requestId];
    testStatus = "done";
  }

  /**
   * Concatenate the URL to perform the GET request on
   */
  function conactUrl(string memory slug) private pure returns (string memory) {
    return string(abi.encodePacked("https://api.opensea.io/api/v1/collection/", slug, "/stats"));
  }

  // maybe needed for polygon? not for mumbai and job id  https://github.com/smartcontractkit/documentation/issues/513
  //   function stringToBytes32(string memory source) public pure returns (bytes32 result) {
  //     bytes memory tempEmptyStringTest = bytes(source);
  //     if (tempEmptyStringTest.length == 0) {
  //       return 0x0;
  //     }

  //     assembly {
  //       // solhint-disable-line no-inline-assembly
  //       result := mload(add(source, 32))
  //     }
  //   }
}
