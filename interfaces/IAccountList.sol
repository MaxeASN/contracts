// SPDX-License-Identifier: GPL
pragma solidity ^0.8.12;

interface IAccountList {
    /**
     * IAccountList is an interface that store new generated accounts
     */

    event AddressAdded(bytes32 indexed pubkeyHash, address account);
    event constructAccountList(address caller, address list);

    /**
     * @dev note
     * @param FIDOPubkey account's off-chain's public key
     * @param accountAddress the address of the account contract
     */
    function Add(
        bytes memory FIDOPubkey,
        address accountAddress
    ) external returns (bool success);

    /**
     * @dev note
     * @param FIDOPubkey account's off-chain's public key
     */
    function Get(bytes memory FIDOPubkey) external view returns (bool, address);

    /**
     * @dev note
     * @param caller account's caller
     */
    function SetCaller(address caller) external returns (bool success);

    // some functions
    function Name() external view returns (string memory);

    function Version() external view returns (string memory);

    function Caller() external view returns (address);
}
