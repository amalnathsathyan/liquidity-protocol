// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./libraries/UniERC20.sol";
import "./interfaces/IMooniFactory.sol";
import "./Mooniswap.sol";


contract MooniFactory is IMooniFactory, Ownable {
    using UniERC20 for IERC20;

    event Deployed(
        address indexed mooniswap,
        address indexed token1,
        address indexed token2
    );

    uint256 public constant MAX_FEE = 0.003e18; // 0.3%

    uint256 public override fee;
    Mooniswap[] public allPools;
    mapping(Mooniswap => bool) public isPool;
    mapping(IERC20 => mapping(IERC20 => Mooniswap)) public pools;

    function getAllPools() external view returns(Mooniswap[] memory) {
        return allPools;
    }

    function setFee(uint256 newFee) external onlyOwner {
        require(newFee <= MAX_FEE, "Factory: fee should be <= 0.3%");
        fee = newFee;
    }

    function deploy(IERC20 tokenA, IERC20 tokenB) public returns(Mooniswap pool) {
        require(tokenA != tokenB, "Factory: not support same tokens");
        require(pools[tokenA][tokenB] == Mooniswap(0), "Factory: pool already exists");

        (IERC20 token1, IERC20 token2) = sortTokens(tokenA, tokenB);

        string memory symbol1 = token1.uniSymbol();
        string memory symbol2 = token2.uniSymbol();

        pool = new Mooniswap(
            token1,
            token2,
            string(abi.encodePacked("Mooniswap V1 (", symbol1, "-", symbol2, ")")),
            string(abi.encodePacked("MOON-V1-", symbol1, "-", symbol2))
        );

        pool.transferOwnership(owner());
        pools[token1][token2] = pool;
        pools[token2][token1] = pool;
        allPools.push(pool);
        isPool[pool] = true;

        emit Deployed(
            address(pool),
            address(token1),
            address(token2)
        );
    }

    function sortTokens(IERC20 tokenA, IERC20 tokenB) public pure returns(IERC20, IERC20) {
        if (tokenA < tokenB) {
            return (tokenA, tokenB);
        }
        return (tokenB, tokenA);
    }
}
