// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

/* solhint-disable avoid-low-level-calls */
/* solhint-disable no-inline-assembly */
/* solhint-disable reason-string */

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";

import "../core/BaseAccount.sol";
import "./callback/TokenCallbackHandler.sol";
import "../interfaces/UserOperation.sol";
import "../core/TxState.sol";
import "../interfaces/DIDLibrary.sol";

/**
 * minimal account.
 *  this is sample minimal account.
 *  has execute, eth handling methods
 *  has a single signer that can send requests through the entryPoint.
 */
contract SimpleAccount is
    BaseAccount,
    TokenCallbackHandler,
    UUPSUpgradeable,
    Initializable
{
    using ECDSA for bytes32;
    using UserOperationLib for UserOperation;
    using DIDLib for DID_Document;
    bytes32 public owner;

    IEntryPoint private immutable _entryPoint;
    TxState public immutable _txState;

    event SimpleAccountInitialized(
        IEntryPoint indexed entryPoint,
        bytes32 indexed owner
    );
    enum State {
        GENERATED,
        SENT,
        PENDING,
        SUCCESSFUL,
        FAILED
    }
    /**
     * TransactionInfo struct
     * @param chainId L1 Chain ID.
     * @param from L1 transaction initiation address.
     * @param seqNum from account transaction sequence number
     * @param receiver L1 transaction receiving address
     * @param amount The size of the transaction amount.
     * @param state Transaction status
     * @param data Contract call data carried by transactions.
     * @param l1TxHash L1 transaction hash
     */

    struct TransactionInfo {
        uint64 chainId;
        address from;
        uint64 seqNum;
        address receiver;
        uint256 amount;
        State state;
        bytes data;
        bytes l1TxHash;
    }

    //Transaction information corresponding to the number of transactions
    mapping(address => mapping(uint64 => TransactionInfo)) public TxsInfo;
    //SeqNum corresponding to L1 address
    mapping(address => uint64) public SequenceNumber;
    //DID document corresponding to DID
    mapping(string => DID_Document) public DID_Documents;
    modifier onlyItself() {
        _onlyItself();
        _;
    }
    modifier onlyTxState() {
        _onlyTxState();
        _;
    }

    /// @inheritdoc BaseAccount
    function entryPoint() public view virtual override returns (IEntryPoint) {
        return _entryPoint;
    }

    // solhint-disable-next-line no-empty-blocks
    receive() external payable {}

    constructor(IEntryPoint anEntryPoint, TxState anTxState) {
        _entryPoint = anEntryPoint;
        _txState = anTxState;
        _disableInitializers();
    }

    function _onlyItself() internal view {
        //directly from EOA owner, or through the account itself (which gets redirected through execute())
        require(msg.sender == address(this), "only contact itself can call");
    }

    function _onlyTxState() internal view {
        //directly from EOA owner, or through the account itself (which gets redirected through execute())
        require(
            msg.sender == address(_txState),
            "only contact TxState can call"
        );
    }

    /**
     * execute a transaction (called directly from owner, or by entryPoint)
     */
    function execute(
        address dest,
        uint256 value,
        bytes calldata func
    ) external {
        _requireFromEntryPoint();
        _call(dest, value, func);
    }

    /**
     * execute a sequence of transactions
     */
    function executeBatch(
        address[] calldata dest,
        bytes[] calldata func
    ) external {
        _requireFromEntryPoint();
        require(dest.length == func.length, "wrong array lengths");
        for (uint256 i = 0; i < dest.length; i++) {
            _call(dest[i], 0, func[i]);
        }
    }

    /**
     * @dev The _entryPoint member is immutable, to reduce gas consumption.  To upgrade EntryPoint,
     * a new implementation of SimpleAccount must be deployed with the new EntryPoint address, then upgrading
     * the implementation by calling `upgradeTo()`
     */
    function initialize(bytes32 anOwner) public virtual initializer {
        _initialize(anOwner);
    }

    function _initialize(bytes32 anOwner) internal virtual {
        owner = anOwner;
        emit SimpleAccountInitialized(_entryPoint, owner);
    }

    // Require the function call went through EntryPoint or owner
    // function _requireFromEntryPoint() internal view {
    //     require(msg.sender == address(entryPoint()) , "account: not  EntryPoint");
    // }

    /// implement template method of BaseAccount
    function _validateSignature(
        UserOperation calldata userOp,
        bytes32 userOpHash
    ) internal virtual override returns (uint256 validationData) {
        require(
            userOpHash ==
                keccak256(
                    abi.encode(
                        userOp.hash(),
                        address(entryPoint()),
                        block.chainid
                    )
                ),
            "userOp verify failed"
        );
        bytes32 ownerhash = keccak256(userOp.fidoPubKey);
        if (owner == ownerhash) return 0;

        return SIG_VALIDATION_FAILED;
    }

    function _call(address target, uint256 value, bytes memory data) internal {
        (bool success, bytes memory result) = target.call{value: value}(data);
        if (!success) {
            assembly {
                revert(add(result, 32), mload(result))
            }
        }
    }

    /**
     * check current account deposit in the entryPoint
     */
    function getDeposit() public view returns (uint256) {
        return entryPoint().balanceOf(address(this));
    }

    /**
     * deposit more funds for this account in the entryPoint
     */
    function addDeposit() public payable {
        entryPoint().depositTo{value: msg.value}(address(this));
    }

    /**
     * withdraw value from the account's deposit
     * @param withdrawAddress target to send to
     * @param amount to withdraw
     */
    function withdrawDepositTo(
        address payable withdrawAddress,
        uint256 amount
    ) public onlyItself {
        entryPoint().withdrawTo(withdrawAddress, amount);
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal view override {
        (newImplementation);
        _onlyItself();
    }

    function addL1txInfo(
        uint64 _chainId,
        address _from,
        address _receiver,
        uint256 _value,
        bytes memory data
    ) external returns (uint64) {
        _requireFromEntryPoint();
        SequenceNumber[_from]++;
        uint64 seqNum = SequenceNumber[_from];
        TxsInfo[_from][seqNum] = TransactionInfo(
            _chainId,
            _from,
            seqNum,
            _receiver,
            _value,
            State.GENERATED,
            data,
            "0x23010919"
        );
        return seqNum;
    }

    function updateTxState(
        address _from,
        uint64 _seqNum,
        uint _state,
        bytes memory _txHash
    ) external onlyTxState {
        if (_state == 1) {
            TxsInfo[_from][_seqNum].state = State.SENT;
        } else if (_state == 2) {
            TxsInfo[_from][_seqNum].state = State.PENDING;
        } else if (_state == 3) {
            TxsInfo[_from][_seqNum].state = State.SUCCESSFUL;
        } else if (_state == 4) {
            TxsInfo[_from][_seqNum].state = State.FAILED;
        } else {
            revert("wrong state");
        }
        TxsInfo[_from][_seqNum].l1TxHash = _txHash;
    }

    function getL1Txhash(
        address _from,
        uint64 _seqNum
    ) public view returns (bytes memory) {
        return TxsInfo[_from][_seqNum].l1TxHash;
    }

    function modifyDIDDocument(DID_Document calldata _didDocument) public {
        _requireFromEntryPoint();
        DID_Documents[_didDocument.id] = _didDocument;
    }

    function getDIDDocument(
        string calldata _did
    ) public view returns (DID_Document memory) {
        return DID_Documents[_did];
    }
}
