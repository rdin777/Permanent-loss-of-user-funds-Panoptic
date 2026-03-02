// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";

contract PoC_Inflation is Test {
    function testLossOfPrecision() public {
        uint256 assetsToPay = 100 ether;
        uint256 totalSupply = 1; // Атакующий владеет 1 wei
        uint256 totalAssets = 1000 ether + 1; // Пул раздут

        // Имитируем Math.mulDiv(assetsToPay, totalSupply, totalAssets)
        uint256 sharesToMint = (assetsToPay * totalSupply) / totalAssets;

        console.log("Assets to settle:", assetsToPay);
        console.log("Shares minted:", sharesToMint);
        
        assertEq(sharesToMint, 0, "Exploit: User got 0 shares for 100 ETH!");
    }
}
