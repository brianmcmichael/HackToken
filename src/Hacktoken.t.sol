// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.6.11;

import "ds-test/test.sol";

import "./Hacktoken.sol";

interface Hevm {
    function warp(uint) external;
    function store(address,bytes32,bytes32) external;
}

contract HacktokenTest is DSTest {

    Hevm hevm;
    // CHEAT_CODE = 0x7109709ECfa91a80626fF3989D68f67F5b1DD12D
    bytes20 constant CHEAT_CODE =
        bytes20(uint160(uint(keccak256('hevm cheat code'))));

    Hacktoken hacktoken;

    function setUp() public {
        hevm = Hevm(address(CHEAT_CODE));
        hacktoken = new Hacktoken("Hackathon Token", "HAKTOK");

        hacktoken.setWinnerParams(3, 1 * 10**18);

        hevm.store(
            address(hacktoken.DAI()),
            keccak256(abi.encode(address(this), uint(2))),
            bytes32(uint(9999 ether))
        );
        assertEq(hacktoken.DAI().balanceOf(address(this)), uint(9999 ether));
        hacktoken.DAI().transferFrom(address(this), address(hacktoken), 9999 ether);
    }

    function test_mint_winner() public {
        hacktoken.mintWinner(address(this), 3);

        assertTrue(hacktoken.isWinner(0));
        assertTrue(!hacktoken.isRedeemed(0));
    }

    function test_redeem_winner() public {
        hacktoken.mintWinner(address(this), 3);

        assertTrue(!hacktoken.isRedeemed(0));
        hacktoken.redeem(0);
        assertTrue(hacktoken.isRedeemed(0));

        assertEq(hacktoken.DAI().balanceOf(address(this)), uint(1 ether));
    }

    function testFail_redeem_winner_twice() public {
        hacktoken.mintWinner(address(this), 3);

        hacktoken.redeem(0);
        hacktoken.redeem(0);
    }

    function test_assign_winner() public {
        hacktoken.mint(address(this));

        hacktoken.assignWinner(0, 3);

        assertTrue(!hacktoken.isRedeemed(0));
        hacktoken.redeem(0);
        assertTrue(hacktoken.isRedeemed(0));

        assertEq(hacktoken.DAI().balanceOf(address(this)), uint(1 ether));
    }

    function test_rewardAmount() public {
        hacktoken.mint(address(this));

        assertEq(hacktoken.rewardAmount(0), 0);

        hacktoken.assignWinner(0, 3);

        assertEq(hacktoken.rewardAmount(0), 1 ether);

        hacktoken.redeem(0);

        assertEq(hacktoken.rewardAmount(0), 0);

        assertEq(hacktoken.DAI().balanceOf(address(this)), uint(1 ether));
    }

    function test_isWinner() public {
        hacktoken.mint(address(this));

        assertTrue(!hacktoken.isWinner(0));

        hacktoken.assignWinner(0, 3);

        assertTrue(hacktoken.isWinner(0));

        hacktoken.redeem(0);

        // Token is still a "winner" after redemption
        assertTrue(hacktoken.isWinner(0));


        hacktoken.mintWinner(address(this), 3);

        assertTrue(hacktoken.isWinner(1));
    }

    function test_isRedeemed() public {
        hacktoken.mint(address(this));

        assertTrue(!hacktoken.isRedeemed(0));

        hacktoken.assignWinner(0, 3);

        assertTrue(!hacktoken.isRedeemed(0));

        hacktoken.redeem(0);

        // Token is still a "winner" after redemption
        assertTrue(hacktoken.isRedeemed(0));


        hacktoken.mintWinner(address(this), 3);

        assertTrue(hacktoken.isWinner(1));
    }

    function test_defund() public {
        assertEq(hacktoken.DAI().balanceOf(address(this)), 0);
        hacktoken.defund();
        assertEq(hacktoken.DAI().balanceOf(address(this)), uint(9999 ether));
    }

}
