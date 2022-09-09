// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/** @title A fun solidity contract for Nottingham Markets if they were on chain
 * @author Jamal'TheAtlantean
 * @dev the contract includes the 3 methods of safely sending ETH
 */

contract MediMarket {
    uint256 public constant MINIMUM_DONATION = 50 * 1e18;
    uint256 public constant TAX_FEE = 25 * 1e18; // tax for the sheriff 
    address immutable taxAccount; // acct of the sheriff
    uint8 totalSupply = 0; // set total supply of weapons to 0

    // Events
    // logs out sales record
    event Sale(
        uint8 id,
        address indexed buyer,
        address indexed seller,
        uint cost,
        uint256 timestamp
        );

    // logs out weapon created
    event Created(
        uint8 id,
        address indexed seller,
        uint256 timestamp
    );

    constructor() {
        taxAccount = msg.sender; // i'm the sherriff lol
    }

    struct WeaponStruct {
        uint8 id;
        address seller;
        string weaponName;
        string description;
        string blacksmith;
        uint256 cost;
        uint256 timestamp;
    }

    WeaponStruct[] public weapons;
    mapping(address => WeaponStruct[]) public weaponsOf;
    mapping(uint8 => address) public sellerOf;
    mapping(uint8 => bool) weaponExists;

    function createWeapon(uint8 cost, 
        string memory blacksmith, 
        string memory weaponName, 
        string memory description
    ) public returns (bool) {
        require(bytes(blacksmith).length > 0, "invalid blacksmith name");
        require(bytes(weaponName).length > 0,"invalid weapon name");              
        require(bytes(description).length > 0,"invalid description name");
        require(cost > 0 ether, "no cost, no taxes");

        // add weapon to market
        weapons.push(
            WeaponStruct(
                totalSupply++,
                msg.sender,
                weaponName,
                description,
                blacksmith,
                cost,
                block.timestamp
            )
        ); 

        // save to record: the blacksmith, and the weapon
        sellerOf[totalSupply] = msg.sender;
        weaponExists[totalSupply] = true;

        emit Created(totalSupply++, msg.sender, block.timestamp);
        return true;
    }

    function payForWeapon(uint8 id) public payable returns (bool) {
        require(weaponExists[id], "weapon does not exist, go to another market"); // using require, not revert
        require(msg.value >= weapons[id - 1].cost, "not enough gold peasant, lol");

        // tally payment
        address seller = sellerOf[id];
        uint256 tax = (msg.value / 100) * TAX_FEE;
        uint256 payment = msg.value - tax;

        // bill the buyer, nothing is cheap in Nottingham
        payTo(seller, payment);
        payTo(taxAccount, tax); // the sheriff needs his quota

        // hand over the purchased weapon
        // thank you for stopping by!
        weaponsOf[msg.sender].push(weapons[id - 1]);

        emit Sale(id, 
            msg.sender, 
            seller, 
            payment, 
            block.timestamp);

        return true;
    }

    // The various method of transfer
    // transfer, send, and call
    // the call method has been confirmed to be the safest, and best against 
    // notorious block-chain bandits that'll attempt to lock up the funds

    function transferTo(address to, uint256 amount) internal returns (bool)
    {
        payable(to).transfer(amount);
        return true;
    }

    // the sendTo function
    function sendTo(address to, uint256 amount) internal returns (bool)
    {
        require(payable(to).send(amount), "transfer failed");
        return true;
    }

    // the call function
    function payTo(address to, uint256 amount) internal returns (bool)
    {
        (bool success, ) = payable(to).call{value: amount}("");
        require(success, "payment failed");
        return true;
    }

    // view weapons in personal artillery
    function myWeapons(address buyer) public view returns (WeaponStruct[] memory)
    {
        return weaponsOf[buyer];
    }

    // view weapons in Nottingham artillery
    function getWeapons() public view returns (WeaponStruct[] memory)
    {
        return weapons;
    }

    // searching for something in particular?
    function search(uint8 id) public view returns (WeaponStruct memory) {
        return weapons[id - 1];
    }
}
