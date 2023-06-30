pragma solidity ^0.8.12;
import "@openzeppelin/contracts/access/Ownable.sol";

contract GasPrice is Ownable {
    uint16 public chainID;
    uint256 public gasPrice;
    mapping(uint16 => uint256) public Gasprice;
    event GasPriceChanged(uint16 chainID, uint256 gasPrice);

    function setGasPrice(uint16 _chainID, uint256 _gasPrice) public onlyOwner {
        Gasprice[_chainID] = _gasPrice;
        emit GasPriceChanged(_chainID, _gasPrice);
    }

    function getGasPrice(uint16 _chainID) public view returns (uint256) {
        return Gasprice[_chainID];
    }
}
