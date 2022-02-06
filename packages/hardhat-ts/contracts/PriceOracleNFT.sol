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

  struct Callback {
    address _callbackAddress;
    bytes4 _callbackFunctionSignature;
  }

  // the collection data used by state
  struct CollectionPrice {
    string collectionSlug;
    uint256 floorPrice;
    uint256 timestamp;
    bytes32 requestId;
  }

  // structure to keep track of current requests
  struct FloorPriceRequests {
    uint256 timestamp;
    string collectionSlug;
  }

  struct CollectionSlugRequest {
    string slug;
    bytes32 requestId;
  }

  // state variables
  /* map of floor price by collection name */
  mapping(string => CollectionPrice) public floorPriceMap;
  /* map of address to collection name */
  mapping(address => CollectionSlugRequest) public addressToCollectionSlugMap;
  mapping(bytes32 => address) public requestToAddressMap;
  /* map of requests by collection name */
  mapping(string => bytes32) public currentRequestsByName;
  /* map of requests by requestId */
  mapping(bytes32 => FloorPriceRequests) public currentRequestsById;

  uint256 private callId = 0;
  // oracle data
  address private oracle;
  bytes32 private jobId;
  uint256 private fee;

  // events
  event OpenSeaFloorPriceRequested(string collectionSlug, bytes32 requestId, string url, uint256 timestamp);
  event OpenSeaFloorPriceUpdated(string collectionSlug, bytes32 requestId, uint256 floorPrice, uint256 timestamp);
  event OpeaFloorSlugRequested(address collectionAddress, bytes32 requestId);
  event OpeaFloorSlugUpdated(address collectionAddress, string collectionSlug, bytes32 requestId);

  constructor() {
    setChainlinkToken(0x326C977E6efc84E512bB9C30f76E30c160eD06FB);
    oracle = 0x58BBDbfb6fca3129b91f0DBE372098123B38B5e9;
    jobId = "da20aae0e4c843f6949e5cb3f7cfe8c4";
    fee = 0.01 * 10**18;
  }

  function getFloorPrice(address _collectionAddress, Callback memory _callback) public returns (bytes20) {
    callId++;
    bytes20 guid = bytes20(keccak256(abi.encodePacked(callId)));
    requestOpenSeaCollectionSlug(_collectionAddress);

    return guid;
  }

  /**
   * This will call an api via chainlink to get the floor price of a collection
   * @param _collectionAddress address of contract
   */
  function requestOpenSeaCollectionSlug(address _collectionAddress) public returns (bytes32 requestId) {
    // check if there is already a result that's recent
    if (bytes(addressToCollectionSlugMap[_collectionAddress].slug).length == 0) {
      return addressToCollectionSlugMap[_collectionAddress].requestId;
    }

    // create a new request
    Chainlink.Request memory request = buildChainlinkRequest(jobId, address(this), this.fulfillCollectionSlug.selector);

    // Set the URL to perform the GET request on
    string memory url = getContractUrl(toString(_collectionAddress));
    request.add("get", url);
    request.add("path", "collection.slug");

    // send the request
    bytes32 result = sendChainlinkRequestTo(oracle, request, fee);

    requestToAddressMap[result] = _collectionAddress;

    // emit event and save id
    emit OpeaFloorSlugRequested(_collectionAddress, result);
    return result;
  }

  /**
   *  Callback function to retrieve the response from the Chainlink request.
   */
  function fulfillCollectionSlug(bytes32 _requestId, string memory _slug) public recordChainlinkFulfillment(_requestId) {
    string memory collectionSlug = _slug;

    emit OpeaFloorSlugUpdated(requestToAddressMap[_requestId], collectionSlug, _requestId);

    addressToCollectionSlugMap[requestToAddressMap[_requestId]].slug = _slug;
  }

  /**
   * This will call an api via chainlink to get the floor price of a collection
   * @param _collectionSlug the slug for the collection in openSea
   */
  function requestOpenSeaFloorPrice(string memory _collectionSlug) public returns (bytes32 requestId) {
    testStatus = "check recent";

    // check if there is already a result that's recent
    if (floorPriceMap[_collectionSlug].timestamp != 0) {
      if (block.timestamp - floorPriceMap[_collectionSlug].timestamp < updateFrequency) {
        return floorPriceMap[_collectionSlug].requestId;
      }
    }

    testStatus = "check requests";

    // check if a request is in progress that's valid
    if (currentRequestsByName[_collectionSlug] != 0 && currentRequestsById[currentRequestsByName[_collectionSlug]].timestamp != 0) {
      if (block.timestamp - currentRequestsById[currentRequestsByName[_collectionSlug]].timestamp < updateFrequency) {
        return currentRequestsByName[_collectionSlug];
      }

      // if there any current request and its too old, delete it and refetch
      delete currentRequestsById[currentRequestsByName[_collectionSlug]];
      delete currentRequestsByName[_collectionSlug];
    }

    testStatus = "create request";

    // create a new request
    Chainlink.Request memory request = buildChainlinkRequest(jobId, address(this), this.fulfillFloorPrice.selector);

    // Set the URL to perform the GET request on
    string memory url = getStatsUrl(_collectionSlug);
    request.add("get", url);
    request.add("path", "stats.floor_price");

    // multiple by 10^18 to remove decimal places
    int256 timesAmount = 10**18;
    request.addInt("times", timesAmount);

    testStatus = "requesting";
    // send the request
    bytes32 result = sendChainlinkRequestTo(oracle, request, fee);

    // save the request data
    currentRequestsById[result] = FloorPriceRequests(block.timestamp, _collectionSlug);
    currentRequestsByName[_collectionSlug] = result;

    // emit event and save id
    emit OpenSeaFloorPriceRequested(_collectionSlug, result, url, block.timestamp);
    return result;
  }

  /**
   *  Callback function to retrieve the response from the Chainlink request.
   */
  function fulfillFloorPrice(bytes32 _requestId, uint256 _price) public recordChainlinkFulfillment(_requestId) {
    testStatus = "saving";

    string memory collectionSlug = currentRequestsById[_requestId].collectionSlug;
    floorPriceMap[collectionSlug] = CollectionPrice(collectionSlug, _price, block.timestamp, _requestId);

    emit OpenSeaFloorPriceUpdated(collectionSlug, _requestId, _price, block.timestamp);

    // delete any current requests
    delete currentRequestsByName[collectionSlug];
    delete currentRequestsById[_requestId];
    testStatus = "done";
  }

  /**
   * Concatenate the URL to perform the GET request on
   */
  function getStatsUrl(string memory slug) private pure returns (string memory) {
    return string(abi.encodePacked("https://api.opensea.io/api/v1/collection/", slug, "/stats"));
  }

  /**
   * Concatenate the URL to perform the GET request on
   */
  function getContractUrl(string memory contractAddress) private pure returns (string memory) {
    return string(abi.encodePacked("https://api.opensea.io/api/v1/asset_contract/", contractAddress));
  }

  function toString(address account) public pure returns (string memory) {
    return toString(abi.encodePacked(account));
  }

  function toString(uint256 value) public pure returns (string memory) {
    return toString(abi.encodePacked(value));
  }

  function toString(bytes32 value) public pure returns (string memory) {
    return toString(abi.encodePacked(value));
  }

  function toString(bytes memory data) public pure returns (string memory) {
    bytes memory alphabet = "0123456789abcdef";

    bytes memory str = new bytes(2 + data.length * 2);
    str[0] = "0";
    str[1] = "x";
    for (uint256 i = 0; i < data.length; i++) {
      str[2 + i * 2] = alphabet[uint256(uint8(data[i] >> 4))];
      str[3 + i * 2] = alphabet[uint256(uint8(data[i] & 0x0f))];
    }
    return string(str);
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
