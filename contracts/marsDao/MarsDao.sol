// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;
pragma abicoder v2;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "./interface/IERC721.sol";
import "./library/LibTransfer.sol";

contract MarsDao {
    event Enter(address user, uint256 dankAmount, uint256 shares);
    /// @notice The standard EIP-20 transfer event
    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed src, address indexed guy, uint256 wad);

    using SafeMath for uint256;
    using LibTransfer for address;

    mapping(address => mapping(address => uint256)) public allowance;
    mapping(address => uint256) public balances;

    string public name = "Mars Dao";
    string public symbol = "mDAO";
    uint8 public constant decimals = 18;
    uint256 public totalSupply;

    uint256 public startTime = 0;
    uint256 public epochDuration = 604800; //  7 * 24 * 60 * 60
    uint256 public numberOfEpochs = 30;
    mapping(address => uint256) public balanceETH;

    address payable internal managerAddress =
        0x0000000000000000000000000000000000000000; // Manage wallets
    address payable internal operationAddress =
        0x0000000000000000000000000000000000000001; // operating wallet
    address internal erc721Address = 0x15f6c5932477908D47740bC56210D79E04f1Ffcd; // Minting contract logic contract

    constructor() {}

    function enter(string memory _tokenURI)
        public
        payable
        returns (uint256 sharesToMint)
    {
        // set start time
        if (startTime == 0) {
            startTime = block.timestamp;
        }

        // Here the casting is performed according to Rarible's lazy casting contract
        uint256 _tokenId =
            IERC721(erc721Address).mint(new LibStruct.Fee[](0), _tokenURI);
        IERC721(erc721Address).transferFrom(
            address(this),
            msg.sender,
            _tokenId
        );

        if (block.timestamp <= _endTimeOfEpoch(numberOfEpochs)) {
            uint256 rate = getExchangeRate();
            sharesToMint = msg.value.mul(rate).div(100); // The precision is 2, so do the processing here
            _mint(msg.sender, sharesToMint.mul(9500).div(10000)); // 95 % md crowdfunder
            _mint(operationAddress, sharesToMint.mul(500).div(10000)); // 5 % md project party
        }
        address(managerAddress).transferEth(msg.value.mul(9000).div(10000)); // 90% Manage wallets
        address(operationAddress).transferEth(msg.value.mul(1000).div(10000)); // 10% operating wallet
        balanceETH[msg.sender] = balanceETH[msg.sender].add(msg.value);
        emit Enter(msg.sender, msg.value, sharesToMint.mul(95).div(100));
    }

    /**
     * @notice Get the number of tokens held by the `account`
     * @param account The address of the account to get the balance of
     * @return The number of tokens held
     */
    function balanceOf(address account) external view returns (uint256) {
        return balances[account];
    }

    function balanceOfETH(address account) external view returns (uint256) {
        return balanceETH[account];
    }

    // 1-indexed
    function _getCurrentEpochId() internal view returns (uint256) {
        return _epochOfTimestamp(block.timestamp);
    }

    function _epochOfTimestamp(uint256 t) internal view returns (uint256) {
        if (t < startTime) return 0;
        return (t.sub(startTime)).div(epochDuration).add(1);
    }

    function _endTimeOfEpoch(uint256 t) internal view returns (uint256) {
        // epoch id starting from 1
        return startTime.add(t.mul(epochDuration));
    }

    /**
     * calc rate
     */
    function getExchangeRate() public view returns (uint256 rate) {
        uint256 curEpoch = _getCurrentEpochId();
        // 10000 / (1+(period-1)**(2)*0.05)
        uint256 addVal = (curEpoch - 1)**2;
        // The numerator and denominator are 100 times larger at the same time
        uint256 forVal = uint256(100).add(addVal.mul(uint256(5)));
        // decmial 2
        rate = uint256(10000000000).div(forVal);
    }

    // --- Token ---
    function transfer(address dst, uint256 wad) external returns (bool) {
        return transferFrom(msg.sender, dst, wad);
    }

    function transferFrom(
        address src,
        address dst,
        uint256 wad
    ) public returns (bool) {
        require(balances[src] >= wad, "mDAO/insufficient-balance");
        if (src != msg.sender && allowance[src][msg.sender] != uint256(-1)) {
            require(
                allowance[src][msg.sender] >= wad,
                "mDAO/insufficient-allowance"
            );
            allowance[src][msg.sender] = allowance[src][msg.sender].sub(wad);
        }
        balances[src] = balances[src].sub(wad);
        balances[dst] = balances[dst].add(wad);
        emit Transfer(src, dst, wad);
        return true;
    }

    function approve(address usr, uint256 wad) external returns (bool) {
        allowance[msg.sender][usr] = wad;
        emit Approval(msg.sender, usr, wad);
        return true;
    }

    function _mint(address user, uint256 amount) internal {
        balances[user] = balances[user].add(amount);
        totalSupply = totalSupply.add(amount);
        /// @notice The standard EIP-20 transfer event
        emit Transfer(address(0), user, amount);
    }
}
