// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.6.11;

import "ds-deed/deed.sol";

interface ChainLog {
    function getAddress(bytes32) external view returns (address);
}

interface Dai {
    function balanceOf(address) external view returns (uint256);
    function transferFrom(address, address, uint256) external returns (bool);
}

contract Hacktoken is DSDeed {

    ChainLog public constant  CL = ChainLog(0xdA0Ab1e0017DEbCd72Be8599041a2aa3bA7e740F);
    Dai      public immutable DAI;

    struct Winner {
        bool    valid;
        bool    redeemed;
        uint192 badge;
    }
    mapping (uint256 => Winner)  public winners;  // TokenID => Winner data

    mapping (uint256 => uint256) public rewards;  // badge_code => reward amount

    event Redeemed(uint256 tokenId);

    constructor(string memory name, string memory symbol) public DSDeed(name, symbol) {
        DAI = Dai(CL.getAddress("MCD_DAI"));
    }

    /**
        @dev Sets the reward amount for a badge code
        @param badge_code   A number representing the badge class
        @param wad          The amount of Dai to pay a winner
    */
    function setWinnerParams(uint256 badge_code, uint256 wad) public auth {
        require(badge_code < uint192(-1), "badge-code-max-exceeded");
        rewards[badge_code] = wad;
    }

    function redeem(uint256 token) external {
        require(this.ownerOf(token) == msg.sender, "only-redeemable-by-owner");
        Winner memory prospect = winners[token];
        require(prospect.valid, "not-a-winner");
        require(!prospect.redeemed, "prize-has-been-redeemed");
        uint256 reward = rewards[prospect.badge];
        require(DAI.balanceOf(address(this)) >= reward, "insufficient-dai-for-award");
        require(reward != 0, "no-dai-award");
        winners[token].redeemed = DAI.transferFrom(address(this), msg.sender, reward);
        emit Redeemed(token);
    }

    function mintWinner(address guy, uint256 badge_code) external returns (uint256 id) {
        return mintWinner(guy, badge_code, "");
    }

    function mintWinner(address guy, uint256 badge_code, string memory uri) public returns (uint256 id) {
        require(badge_code < uint192(-1), "badge-code-max-exceeded");
        id = mint(guy, uri);
        winners[id] = Winner(true, false, uint192(badge_code));
    }
}
