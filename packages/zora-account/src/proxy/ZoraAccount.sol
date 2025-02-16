// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {Magic} from "../../_imagine/Magic.sol";

contract ZoraAccount is Magic, ERC1967Proxy {
    constructor(address _logic, bytes memory _init) ERC1967Proxy(_logic, _init) {}
}
