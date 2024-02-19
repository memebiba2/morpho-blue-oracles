// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "./helpers/Constants.sol";
import "../lib/forge-std/src/Test.sol";
import {MorphoChainlinkOracleV2} from "../src/morpho-chainlink/MorphoChainlinkOracleV2.sol";
import "../src/wsteth-exchange-rate-adapter/WstEthEthExchangeRateChainlinkAdapter.sol";

contract WstEthEthExchangeRateChainlinkAdapterTest is Test {
    IWstEth internal constant WST_ETH = IWstEth(0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0);

    WstEthEthExchangeRateChainlinkAdapter internal adapter;
    MorphoChainlinkOracleV2 internal morphoOracle;

    function setUp() public {
        vm.createSelectFork(vm.envString("ETH_RPC_URL"));
        adapter = new WstEthEthExchangeRateChainlinkAdapter(address(WST_ETH));
        morphoOracle = new MorphoChainlinkOracleV2(
            vaultZero, 1, AggregatorV3Interface(address(adapter)), feedZero, 18, vaultZero, 1, feedZero, feedZero, 18
        );
    }

    function testDecimals() public {
        assertEq(adapter.decimals(), uint8(18));
    }

    function testDescription() public {
        assertEq(adapter.description(), "wstETH/ETH exchange rate");
    }

    function testDeployZeroAddress() public {
        vm.expectRevert(bytes(ErrorsLib.ZERO_ADDRESS));
        new WstEthEthExchangeRateChainlinkAdapter(address(0));
    }

    function testLatestRoundData() public {
        (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound) =
            adapter.latestRoundData();
        assertEq(roundId, 0);
        assertEq(uint256(answer), WST_ETH.stEthPerToken());
        assertEq(startedAt, 0);
        assertEq(updatedAt, 0);
        assertEq(answeredInRound, 0);
    }

    function testLatestRoundDataBounds() public {
        (, int256 answer,,,) = adapter.latestRoundData();
        assertGe(uint256(answer), 1154690031824824994); // Exchange rate queried at block 19070943
        assertLe(uint256(answer), 1.5e18); // Max bounds of the exchange rate. Should work for a long enough time.
    }

    function testOracleWstEthEthExchangeRate() public {
        (, int256 expectedPrice,,,) = adapter.latestRoundData();
        assertEq(morphoOracle.price(), uint256(expectedPrice) * 10 ** (36 + 18 - 18 - 18));
    }
}
