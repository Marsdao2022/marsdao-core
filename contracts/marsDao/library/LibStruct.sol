pragma solidity >=0.6.2 <0.8.0;

library LibStruct {
    struct Fee {
        address payable recipient;
        uint256 value;
    }

    // struct Part {
    //     address payable account;
    //     uint96 value;
    // }

    // struct Mint721Data {
    //     uint256 tokenId;
    //     string tokenURI;
    //     Part[] creators;
    //     Part[] royalties;
    //     bytes[] signatures;
    // }
}
