// SPDX-License-Identifier: GPL

pragma solidity ^0.8.12;

import "@openzeppelin/contracts/access/Ownable.sol";

import "../interfaces/IAccountList.sol";

contract StructSet {
    struct Account {
        address _account;
        bytes _pubkey;
    }

    mapping(bytes32 => Account) private _accountList;
    mapping(bytes32 => bool) private _exist;

    function _add(bytes32 digest, Account memory accList) internal {
        // require(!_exist[digest], "Account data exist.");
        _accountList[digest] = accList;
        _exist[digest] = true;
    }

    function _get(
        bytes32 _digest
    ) internal view returns (bool exists, address account) {
        account = _accountList[_digest]._account;
        exists = (account != address(0));
    }

    function _genDigest(
        Account memory accList
    ) internal pure returns (bytes32 digest) {
        return keccak256(accList._pubkey);
    }

    function _str2bytes(
        string memory str
    ) internal pure returns (bytes32 result) {
        assembly {
            result := mload(add(str, 32))
        }
    }

    function _bytes2str(
        bytes memory dat
    ) internal pure returns (string memory) {
        uint _len = dat.length;
        bytes memory _res = new bytes(_len);
        for (uint _i = 0; _i < _len; _i++) {
            _res[_i] = dat[_i];
        }
        return string(_res);
    }
}

contract AccountList is IAccountList, StructSet, Ownable {
    // contract info
    string private _name = "New Generated Account Contract List";
    string private _version = "1.0";

    address private _caller;

    function Name() external view returns (string memory) {
        return _name;
    }

    function Version() external view returns (string memory) {
        return _version;
    }

    function Caller() external view returns (address) {
        return _caller;
    }

    constructor(address caller) {
        _caller = caller;
        emit constructAccountList(_caller, address(this));
    }

    function SetCaller(address caller) external onlyOwner returns (bool) {
        _caller = caller;
        return true;
    }

    function Add(
        bytes memory FIDOPubkey,
        address accountAddress
    ) external returns (bool success) {
        require(
            msg.sender == _caller,
            "Only the specified entry point can  call Add()"
        );
        Account memory accList = Account({
            _account: accountAddress,
            _pubkey: FIDOPubkey
        });
        bytes32 _digest = _genDigest(accList);
        _add(_digest, accList);
        emit AddressAdded(_digest, accountAddress);
        success = true;
    }

    function Get(
        bytes memory FIDOPubkey
    ) external view returns (bool, address) {
        Account memory accList = Account({
            _account: address(0),
            _pubkey: FIDOPubkey
        });
        return _get(_genDigest(accList));
    }
}
