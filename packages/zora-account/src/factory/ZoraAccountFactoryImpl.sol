// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Create2} from "@openzeppelin/contracts/utils/Create2.sol";
import {UUPSUpgradeable, ERC1967Utils} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {Ownable2StepUpgradeable} from "@openzeppelin/contracts-upgradeable/access/Ownable2StepUpgradeable.sol";
import {IEntryPoint} from "account-abstraction/contracts/interfaces/IEntryPoint.sol";

import {IZoraAccountFactory} from "../interfaces/IZoraAccountFactory.sol";
import {ZoraAccountImpl} from "../account/ZoraAccountImpl.sol";
import {ZoraAccount} from "../proxy/ZoraAccount.sol";

contract ZoraAccountFactoryImpl is UUPSUpgradeable, Ownable2StepUpgradeable, IZoraAccountFactory {
    ZoraAccountImpl public immutable zoraAccountImpl;

    constructor(IEntryPoint _entryPoint, address upgradeGate) initializer {
        zoraAccountImpl = new ZoraAccountImpl(_entryPoint, upgradeGate);
    }

    function initialize(address _initialOwner) public initializer {
        __Ownable_init(_initialOwner);
        __UUPSUpgradeable_init();

        emit ZoraAccountFactoryInitialized(_initialOwner, msg.sender);
    }

    /**
     * @notice Create an account, and return its address.
     * Returns the address even if the account is already deployed.
     * @dev During UserOperation execution, this method is called only if the account is not deployed.
     * This method returns an existing account address so that entryPoint.getSenderAddress() would work even after account creation.
     * @param owner The owner of the account to be created
     * @param salt A salt, which can be changed to create multiple accounts with the same owner
     * @return ret The address of either the newly deployed account or an existing account with this owner and salt
     */
    function createAccount(address owner, bytes32 salt) public returns (ZoraAccount ret) {
        address addr = getAddress(owner, salt);
        uint256 codeSize = addr.code.length;
        if (codeSize > 0) {
            return ZoraAccount(payable(addr));
        }
        ret = ZoraAccount(payable(new ZoraAccount{salt: salt}(address(zoraAccountImpl), abi.encodeCall(ZoraAccountImpl.initialize, (owner)))));
    }

    /**
     * @notice Calculate the counterfactual address of this account as it would be returned by createAccount()
     * @param owner The owner of the account to be created
     * @param salt A salt, which can be changed to create multiple accounts with the same owner
     * @return The address of the account that would be created with createAccount()
     */
    function getAddress(address owner, bytes32 salt) public view returns (address) {
        return
            Create2.computeAddress(
                salt,
                keccak256(
                    abi.encodePacked(type(ZoraAccount).creationCode, abi.encode(address(zoraAccountImpl), abi.encodeCall(ZoraAccountImpl.initialize, (owner))))
                )
            );
    }

    function implementation() external view returns (address) {
        return ERC1967Utils.getImplementation();
    }

    function _authorizeUpgrade(address newImpl) internal override onlyOwner {}
}
