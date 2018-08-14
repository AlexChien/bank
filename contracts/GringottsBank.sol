pragma solidity ^0.4.23;

import "./BankBase.sol";
import 'openzeppelin-solidity/contracts/ownership/Ownable.sol';
import './BurnableERC20.sol';


contract  GringottsBank is Ownable,BankBase {

    /**
    * @dev Bank's constructor which set the token address and unitInterest_
    * @param _ring - address of ring
    * @param _kton - address of KTON
    */
    constructor (address _ring, address _kton) public {
        _setRING(_ring);
        _setKTON(_kton);
        _setUnitInterest(500000000000000);
        _setPenaltyMultiplier(3);
        _setInterestMultiplierUp(66);
        _setInterestMultiplierDown(65);
    }



    // for deposit ring
    function tokenFallback(address _from, uint256 _amount, bytes _data) public {
        // deposit entrance
        if(address(ring_) == msg.sender) {
            uint months = bytesToUint256(_data);
            _deposit(_from, _amount, months);
        }
        //  Early Redemption entrance
        if (address(kryptonite_) == msg.sender) {
            uint depositID = bytesToUint256(_data);
            require(_amount >= _computePenaltyWithID(_from, depositID));
            Deposit storage depositEntity = playerDepositInfo_[_from][depositID];
            uint value = depositEntity.value;
            _claimBack(_from, value, depositID);

            // burn the KTON transferred in
            BurnableERC20(kryptonite_).burn(_amount);
        }

    }


    // normal Redemption, withdraw at maturity
    function claimBack(uint _depositID) public {
        // palyer can only withdraw his/her own deposit
        Deposit storage depositEntity = playerDepositInfo_[msg.sender][_depositID];

        uint value = depositEntity.value;
        require(value > 0, "wrong depositID");
        uint months = depositEntity.months;
        uint startAt = depositEntity.startAt;
        uint duration = now - startAt;

        require (duration >= (months * MONTH));
        _claimBack(msg.sender, value, _depositID);
    }

    /// @notice This method can be used by the owner to extract mistakenly
    ///  sent tokens to this contract.
    /// @param _token The address of the token contract that you want to recover
    ///  set to 0 in case you want to extract ether.
    function claimTokens(address _token) public onlyOwner {
        if (_token == 0x0) {
            owner.transfer(address(this).balance);
            return;
        }
        ERC20 token = ERC20(_token);
        uint balance = token.balanceOf(address(this));
        token.transfer(owner, balance);

        emit ClaimedTokens(_token, owner, balance);
    }

    // query penalty of a specific deposit at the moment of invoking
    function getPenalty(address _depositor, uint _depositID) public returns (uint) {
        _computePenaltyWithID(_depositor, _depositID);
    }

    // @dev set UNIT_INTEREST;
    function setUnitInterest(uint _unitInterest) public onlyOwner {
        _setUnitInterest(_unitInterest);
    }

    // @dev set UNIT_INTEREST;
    function setPenaltyMultiplier(uint _penaltyMultiplier) public onlyOwner {
        _setPenaltyMultiplier(_penaltyMultiplier);
    }


    // @dev set ring_
    function setRING(address _ring) public onlyOwner {
        _setRING(_ring);
    }

    // @dev set KTON
    function setKTON(address _kton) public onlyOwner {
        _setKTON(_kton);
    }

    // @dev set interestMultiplierUp_
    function setInterestMultiplierUp(uint _up) public onlyOwner {
        _setInterestMultiplierUp(_up);
    }

    // @dev set interestMultiplierDown_
    function setInterestMultiplierDown(uint _down) public onlyOwner {
        _setInterestMultiplierDown(_down);
    }


}
