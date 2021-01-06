// SPDX-License-Identifier: GPL-3.0-or-later

/// Hacktoken.sol -- ERC721 implementation with redeemable prizes

// Copyright (C) 2020  Brian McMichael

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.
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
        bool    valid;           // True if token is a prize winner
        bool    redeemed;        // True if prize has been redeemed
        uint192 badge;           // The identifier for the prize
    }
    mapping (uint256 => Winner)  public winners;  // TokenID => Winner data

    mapping (uint256 => uint256) public rewards;  // badge_code => reward amount

    event PrizeAdded(uint256 badge_code, uint256 prize_amount);
    event Redeemed(uint256 tokenId);

    constructor(string memory name, string memory symbol) public DSDeed(name, symbol) {
        DAI = Dai(CL.getAddress("MCD_DAI"));
    }

    /**
        @dev Sets the reward amount for a badge code
        @param badge_code   A number representing the badge class
        @param wad          The amount of Dai to pay a winner (1 Dai = 10**18)
    */
    function setWinnerParams(uint256 badge_code, uint256 wad) public auth {
        require(badge_code < uint192(-1), "badge-code-max-exceeded");
        rewards[badge_code] = wad;
        emit PrizeAdded(badge_code, wad);
    }

    /**
        @dev Allows the owner of a token to redeem it for a prize
        @param token        The token id to redeem
    */
    function redeem(uint256 token) external {
        require(this.ownerOf(token) == msg.sender, "only-redeemable-by-owner");
        Winner memory prospect = winners[token];
        require(prospect.valid, "not-a-winner");
        require(!prospect.redeemed, "prize-has-been-redeemed");
        uint256 reward = rewards[prospect.badge];
        require(DAI.balanceOf(address(this)) >= reward, "insufficient-dai-balance-for-award");
        require(reward != 0, "no-dai-award");
        winners[token].redeemed = DAI.transferFrom(address(this), msg.sender, reward);
        emit Redeemed(token);
    }

    /**
        @dev Mint a winning token without a metadata URI. Requires auth on mint.
        @param guy          The address of the recipient
        @param badge_code   The prize code
    */
    function mintWinner(address guy, uint256 badge_code) external returns (uint256 id) {
        return mintWinner(guy, badge_code, "");
    }

    /**
        @dev Mint a winning token with a metadata URI. Requires auth on mint.
        @param guy          The address of the recipient
        @param badge_code   The prize code
        @param uri          A URL to provide a metadata url
    */
    function mintWinner(address guy, uint256 badge_code, string memory uri) public returns (uint256 id) {
        require(badge_code < uint192(-1), "badge-code-max-exceeded");
        id = mint(guy, uri);
        winners[id] = Winner(true, false, uint192(badge_code));
    }

    /**
        @dev Contract owner can withdraw unused funds.
    */
    function defund() public auth {
        DAI.transferFrom(address(this), msg.sender, DAI.balanceOf(address(this)));
    }
}
