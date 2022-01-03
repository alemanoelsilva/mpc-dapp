pragma solidity >=0.4.24 <0.7.0;

contract MPC {
    address payable public sender;
    address payable public recipient;

    // it is called when the contract is deployed
    // payable allow to send ether to the contract through:
    //   msg.sender (address) 
    //   msg.value (uint) ether, wei, gwei, etc.
    constructor (
        address payable _reciever
    ) public payable {
        sender = msg.sender;
        recipient = _reciever;
    }

    // public -> function can be called
    // memory -> it does not store the value in the blockchain, 
    //   if you want to store it, you need to use storage
    function claimPayment(
        uint256 _amount, 
        bytes memory _signedMessage
    ) public {
        require(msg.sender == recipient,'Not a recipient'); // sender is the worker
        require(_isValidSignedMessage(_amount, _signedMessage),'Signed message Unmatch');
        require(address(this).balance > _amount,'Insufficient Funds');
        recipient.transfer(_amount);
        selfdestruct(sender);
    }

    // internal -> function is used only in this contract
    // view -> function use state variable but does not update it
    // returns a bool
    function _isValidSignedMessage(
        uint256 _amount, 
        bytes memory _signedMessage
    ) internal view returns (bool) {
        bytes32 message = _prefixed(keccak256(abi.encodePacked(this, _amount)));
        return _recoverSigner(message, _signedMessage) == sender;
    }

    // internal -> function is used only in this contract
    // pure -> function does not use any state variable
    // returns an unit8, byte32 and byte32
    function _splitSignedMessage(
        bytes memory _sig
    ) internal pure returns (uint8 v, bytes32 r, bytes32 s) {
        require(_sig.length == 65,'Signed message length');
        assembly{
            r := mload(add(_sig, 32))
            s := mload(add(_sig, 64))
            v := byte(0, mload(add(_sig, 96)))
        }
        return (v, r, s);
    }

    // internal -> function is used only in this contract
    // pure -> function does not use any state variable
    // returns an address
    function _recoverSigner(
        bytes32 _message, 
        bytes memory _sig
    ) internal pure returns (address) {
        (uint8 v, bytes32 r, bytes32 s) = _splitSignedMessage(_sig);
        return ecrecover(_message, v, r, s);
    }

    // internal -> function is used only in this contract
    // pure -> function does not use any state variable
    // returns a byte32
    function _prefixed(
        bytes32 _hash
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _hash));
    }
}