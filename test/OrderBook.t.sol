// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/OrderBook.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Test, console} from "forge-std/Test.sol";

contract TokenA is ERC20 {
    constructor() ERC20("TokenA", "TKA") {
        _mint(msg.sender, 1000 ether);
    }
}

contract TokenB is ERC20 {
    constructor() ERC20("TokenB", "TKB") {
        _mint(msg.sender, 1000 ether);
    }
}

contract OrderBookTest is Test {
    TokenA tokenA;
    TokenB tokenB;
    OrderBook orderBook;

    address user1 = address(0x123);
    address user2 = address(0x456);
    address user3 = address(0x976);

    function setUp() public {
        tokenA = new TokenA();
        tokenB = new TokenB();
        orderBook = new OrderBook(address(tokenA), address(tokenB));

        vm.deal(user1, 100 ether);
        tokenA.transfer(user1, 100 ether);
        tokenB.transfer(user1, 100 ether);

        vm.deal(user2, 1 ether);
        tokenA.transfer(user2, 1 ether);
        tokenB.transfer(user2, 1 ether);

        vm.deal(user3, 100 wei);
        tokenA.transfer(user3, 1 wei);
        tokenB.transfer(user3, 1 wei);
    }

    function test_placeOrder_buyTokenA() public {
        // User 1 set order to buy 50 tokenA for 1 tokenB
        uint amountOfTokenAToBuy = 50 ether;
        uint targetPriceTokenB = 1 ether;

        vm.startPrank(user1);
        tokenB.approve(address(orderBook), targetPriceTokenB);
        orderBook.placeOrder(
            true,
            amountOfTokenAToBuy,
            targetPriceTokenB,
            true
        );
        vm.stopPrank();

        (
            address user,
            bool orderTokenA,
            uint256 amount,
            uint price,
            bool isBuy
        ) = orderBook.orders(0);

        assertEq(user, user1);
        assertEq(orderTokenA, true);
        assertEq(amount, amountOfTokenAToBuy);
        assertEq(price, targetPriceTokenB);
        assertEq(isBuy, true);
        assertEq(tokenA.balanceOf(user1), 100 ether);
        assertEq(tokenB.balanceOf(user1), 99 ether);
    }

    function test_placeOrder_buyTokenB() public {
        // User 1 set order to buy 1 tokenB for 50 tokenA
        uint amountOfTokenBToBuy = 1 ether;
        uint targetPriceTokenA = 50 ether;
        bool orderTokenA = false;

        vm.startPrank(user1);
        tokenA.approve(address(orderBook), targetPriceTokenA);
        // isBuy is false because user1 is buying tokenB (-> reverse logic)
        orderBook.placeOrder(
            orderTokenA,
            amountOfTokenBToBuy,
            targetPriceTokenA,
            true
        );
        vm.stopPrank();

        (address user, , uint256 amount, uint price, bool isBuy) = orderBook
            .orders(0);

        assertEq(user, user1);
        assertEq(amount, amountOfTokenBToBuy);
        assertEq(price, targetPriceTokenA);
        assertEq(isBuy, true);
        assertEq(tokenA.balanceOf(user1), 50 ether);
        assertEq(tokenB.balanceOf(user1), 100 ether);
    }

    function test_placeOrder_sellTokenA() public {
        // User 1 set order to sell 50 tokenA for 1 tokenB
        uint amountOfTokenAToSell = 50 ether;
        uint targetPriceTokenB = 1 ether;
        bool orderTokenA = true;

        vm.startPrank(user1);
        tokenA.approve(address(orderBook), amountOfTokenAToSell);
        orderBook.placeOrder(
            orderTokenA,
            amountOfTokenAToSell,
            targetPriceTokenB,
            false
        );
        vm.stopPrank();

        (address user, , uint256 amount, uint price, bool isBuy) = orderBook
            .orders(0);
        assertEq(user, user1);
        assertEq(amount, amountOfTokenAToSell);
        assertEq(price, targetPriceTokenB);
        assertEq(isBuy, false);
        assertEq(tokenA.balanceOf(user1), 50 ether);
        assertEq(tokenB.balanceOf(user1), 100 ether);
    }

    function test_placeOrder_sellTokenB() public {
        // User 1 set order to sell 1 tokenB for 50 tokenA
        uint amountOfTokenBToSell = 1 ether;
        uint targetPriceTokenA = 50 ether;
        bool orderTokenA = false;

        vm.startPrank(user1);
        tokenB.approve(address(orderBook), amountOfTokenBToSell);
        orderBook.placeOrder(
            orderTokenA,
            amountOfTokenBToSell,
            targetPriceTokenA,
            false
        );
        vm.stopPrank();

        (address user, , uint256 amount, uint price, bool isBuy) = orderBook
            .orders(0);
        assertEq(user, user1);
        assertEq(amount, amountOfTokenBToSell);
        assertEq(price, targetPriceTokenA);
        assertEq(isBuy, false);
        assertEq(tokenA.balanceOf(user1), 100 ether);
        assertEq(tokenB.balanceOf(user1), 99 ether);
    }

    function test_placeOrder_BuyTokenA_NotEnoughtToken() public {
        // User 2 set order to buy 100 tokenA for 2 tokenB
        uint amountOfTokenAToBuy = 100 ether;
        uint targetPriceTokenB = 2 ether;
        vm.startPrank(user2);
        tokenB.approve(address(orderBook), targetPriceTokenB);
        vm.expectRevert(
            abi.encodeWithSignature(
                "ERC20InsufficientBalance(address,uint256,uint256)",
                user2,
                1 ether,
                targetPriceTokenB
            )
        );
        orderBook.placeOrder(
            true,
            amountOfTokenAToBuy,
            targetPriceTokenB,
            true
        );
        vm.stopPrank();
    }

    function test_placeOrder_SellTokenA_NotEnoughtToken() public {
        // User 2 set order to sell 50 tokenA for 1 tokenB
        uint amountOfTokenAToSell = 50 ether;
        uint targetPriceTokenB = 1 ether;
        vm.startPrank(user2);
        tokenA.approve(address(orderBook), amountOfTokenAToSell);
        vm.expectRevert(
            abi.encodeWithSignature(
                "ERC20InsufficientBalance(address,uint256,uint256)",
                user2,
                targetPriceTokenB,
                amountOfTokenAToSell
            )
        );
        orderBook.placeOrder(
            true,
            amountOfTokenAToSell,
            targetPriceTokenB,
            false
        );
        vm.stopPrank();
    }

    function test_MatchOrder_BuyTokenB() public {
        // User 1 set order to buy 1 tokenB for 50 tokenA
        uint amountOfTokenBToBuy = 1 ether;
        uint targetPriceTokenA = 50 ether;
        vm.startPrank(user1);
        tokenA.approve(address(orderBook), targetPriceTokenA);
        orderBook.placeOrder(
            false,
            amountOfTokenBToBuy,
            targetPriceTokenA,
            true
        );
        vm.stopPrank();

        // User 2 set order to buy 50 tokenA for 1 tokenB
        vm.startPrank(user2);
        uint amountOfTokenAToBuy = 50 ether;
        uint targetPriceTokenB = 1 ether;
        tokenB.approve(address(orderBook), targetPriceTokenB);
        orderBook.placeOrder(
            true,
            amountOfTokenAToBuy,
            targetPriceTokenB,
            true
        );
        vm.stopPrank();

        //check balance of user1 and user2 according to their buy / sell
        assertEq(tokenA.balanceOf(user1), 50 ether);
        assertEq(tokenB.balanceOf(user1), 101 ether);

        assertEq(tokenA.balanceOf(user2), 51 ether);
        assertEq(tokenB.balanceOf(user2), 0 ether);
    }
}
