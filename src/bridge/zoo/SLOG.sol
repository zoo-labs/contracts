// SPDX-License-Identifier: BSD-3-Clause
// Copyright (c) 2025 Lux Industries Inc.
pragma solidity ^0.8.31;

/**
    ███████╗██╗      ██████╗  ██████╗ 
    ██╔════╝██║     ██╔═══██╗██╔════╝ 
    ███████╗██║     ██║   ██║██║  ███╗
    ╚════██║██║     ██║   ██║██║   ██║
    ███████║███████╗╚██████╔╝╚██████╔╝
    ╚══════╝╚══════╝ ╚═════╝  ╚═════╝ 
 */

import "@luxfi/bridge/LRC20B.sol";

contract SLOG is LRC20B {
    constructor() LRC20B("Slog", "SLOG") {
         _mint(msg.sender, 1000000000 * 10 ** decimals());
    }

    function decimals() public view virtual override returns (uint8) {
        return 6;
    }

    function mint(address account, uint256 amount) public onlyAdmin {
        _mint(account, amount);
    }

    function burn(address account, uint256 amount) public onlyAdmin {
        _burn(account, amount);
    }
}
