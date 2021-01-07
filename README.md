# HackToken

An ERC721 NFT that includes a redeemable prize in Dai.

## Usage

Standard ERC721 Token functionality

Additional features for token holders:

    * `isWinner(uint256 tokenID)`
        * true if token ID is a winner

    * `isRedeemed(uint256 tokenID)`
        * true if token has been redeemed

    * `rewardAmount(uint256 tokenID)`
        * shows the amount of the reward (0 if none)

    * `redeem(uint256 token)`
        * The owner of a winning token may redeem it for a prize
        * The owner keeps the token, but cannot redeem it again

Authorized user configures prize parameters with:

    * `setWinnerParams(uint256 badge_code, uint256 wad)`
        * `badge_code` is a numeric code representing the prize category
        * `wad` is the amount of Dai to pay a winner

    * `mintWinner(address guy, uint256 badge_code, string memory uri)`
        * `guy` is the address of the recipient
        * `badge_code` is the code for the prize package
        * (optional) `uri` is a link to metadata uri

    * `defund()`
        * Return all unused Dai to the authorized user

