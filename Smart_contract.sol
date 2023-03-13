// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/IAccessControl.sol";



contract test is Ownable, AccessControl {

////////////////////// State variables declaration ////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////
    struct access_permission {
        address Subject_public_ky;
        string Resource_hash_of_data;
        string Action;
        bool Permission_value;
    }
    
    //@ desc the Ethereum address IoT device wwner, e.g., 0xb2F71faa69c459C1311D9E925F97859Afe0DC2cB
    address iotdeviceowner;       

    // @desc Everything about Data User/Data consumder 
    struct IoTDataUsers{
        // Ethereum address of the data user
        address data_user_address;   
        // Data user desired data 
        string desired_data;    
    }
    struct File {
        uint256 fileId;
        string IPFSHash;
        uint256 timestamp;
        string description; 
        address payable uploader;
        int DataQuality;
    }
    
    // @desc the variable shows the current state of the contact
    enum contractState {created, advertisedForSale, biddingInProgress, someoneIsBiddingNow, biddingEnded, paymentReceivedByWinner, newOwner }
    contractState public state;

    // @desc Maximum proposed amount of bid by a customer 
    uint256 currentMaxBid;

    address biddingWinner;
    uint256 CurremttimeStamp;
    uint256 endBiddingTime;
    uint256 biddingDuration;

    // @ desc this mapping acts as a catalog of files uploaded to the storage
    mapping(uint256 => File) public files;

 
    // Hash/CID of the data on IPFS
    string IPFSHash;
    // timestamp of the storing time on IPFS
    uint256 timestamp;  
    // A description of the data (e.g., size, type, etc)
    string description;     

    // @desc The list of users who are interested in IoT data is registered in this mapping 
    mapping(address => bool) public RegisteredDataUsers;
    
    // @desc IoT Device Metadata. The metadata include information on the IoT device's IP address,
    //IoT device type, and location, such as latitude and longitude
    mapping (address => access_permission) permission;

    // @desc Links a boolean value with the device's MAC address(string)./
    // If it is true, it means that the given device is available and/
    // registered beforehand. 
    mapping (string => bool) deviceExists;

    // @desc Links the device's MAC address(string) with the owner's address(address).
    mapping (address => string) devicesList;

    // @desc Define new roles for access control purposes
    bytes32 public constant USER_ROLE = keccak256("USER");
    bytes32 public constant GUEST_USER_ROLE = keccak256("GUEST_USER");
    bytes32 public constant DATA_USER = keccak256("DATA_USER");
    bytes32 public constant DATA_SELLER = keccak256("DATA_SELLER");

    //  @desc A variable to count the number of stored meta-data on the blockchain
    uint256 public fileCount = 0;


    // @desc Create the community role, with `root` as a member.
    constructor (address root) {
        _setupRole(DEFAULT_ADMIN_ROLE, root);
        iotdeviceowner =  msg.sender;
        // @desc Metadata => IPaddress, latitude and logitude, domainname, description. This is used to save on Ether
        // @desc Emits an event to notify all participating entities that the IoT device
        // smart contract has been created using the initialized variables.
        emit IoTDeviceSCcreated(root);

   }
////////////////////// Event declarations /////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////

   event IoTDeviceSCcreated(address IoTdeviceowner);
   event NewDeviceRegisteration(address Sender, string macAddress);
   event ExistingDeviceDeletion(address Sender, string macAddress);
   event NewDataUserRegisteration(address datauser, string desireddata);
   event ExistingDataUserDeletion(address datauser);
   event NewIoTDataPushed (uint256 fileId, string Hash_IPFS, uint256 Hash_timestamp, string Data_desciption, address payable uploader);
   event UpdateDataDharingPolicies(address Subject);
   event RecievedDataRanked(uint256 fileid, string ipfshash, int filerank);
   event NewBidOffered(uint256 fileId, string Hash_IPFS, string Data_desciption, uint bid);
   event BiddingCommenced(uint256 filecount, string ipfshash, string description, uint256 currenttimeStamp, uint dur, uint minBid);
   event BiddingEndedAnnounceOwner();
   event PaymentReceivedFromNewOwner(address winner);
   event NewOwnerAnnounced(address winner);
   event RevokingRoles(bytes32 role, address account, address sender);
   event GrantingRoles(bytes32 role, address account, address sender);
   event OwnershipTransferring(address previousOwner, address newOwner);

////////////////////// Modifier declarations //////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////
   modifier costs(){
       assert(msg.value == (currentMaxBid * 1 ether));//must be in ether
       _;
   }   
   modifier OnlyBiddingWinner{
       require(msg.sender == biddingWinner);
       _;
   }
////////////////////// IoT Device Owner/vendor  functionalities ////////////////////
///////////////////////////////////////////////////////////////////////////////////////
    
    // @desc Function to register a new device (user) 
    function Register_a_new_device (address Sender, string memory macAddress) public onlyOwner {
        // @desc Before adding a new device, it first checks its existence in the device exist list
        require(!deviceExists[macAddress]);
        devicesList[Sender] = macAddress;
        deviceExists[macAddress] = true;
        emit NewDeviceRegisteration(Sender, macAddress);
    }

    // @desc Function to delete an existing device 
    function Delete_an_existing_device (address Sender, string memory macAddress) public onlyOwner {
        // @desc Before deleting a device, it first checks its existence in the device exist list
        require(deviceExists[macAddress]);
        // @desc Before deleting a device, it first checks that 
        // the given sender is the owner of the device or not (the device belongs to Sender who
        // wants to delete the device)
        require(keccak256(abi.encodePacked(devicesList[Sender])) == keccak256(abi.encodePacked(macAddress)));
        deviceExists[macAddress] = false;
        emit ExistingDeviceDeletion(Sender, macAddress);
    }

    // @desc Function to register a new data user/participant 
    function RegisterDataUser(address _NewDataUser, string memory _desireddata) public onlyOwner{
        // @desc Before adding a new data user, it first checks that the given user does not exit in the system 
        require(!RegisteredDataUsers[_NewDataUser]);
        RegisteredDataUsers[_NewDataUser] = true;
        emit NewDataUserRegisteration(_NewDataUser,_desireddata);
    }

   // @desc Function to delete an existing data user 
    function Delete_an_existing_data_user (address _ExistingDataUser) public onlyOwner {
        // @desc Before deleting a data user, it first checks
        // its existence in the data user list
        require(RegisteredDataUsers[_ExistingDataUser]);
        emit ExistingDataUserDeletion(_ExistingDataUser);
    }
 
    // @desc Function to push IoT meta_data to blockchain(on-chain storage)
    // and emit an event that new data is published for sale. Indeed, this function
    // plays the role of data offering system that let providers to publish their data offering
    // on the blockchain that are publicly visible, and buyers could search to find relevant information.
    // The providers provide some information about the data, such as hash, decription,
    // and count index. The data could be coming from sets of sensor devices that
    // measuring anything from air quality to building occupancy
    function IoTMetaDataUpload (string memory _ipfsHash, uint256 _timestamp,
    string memory _description) public onlyOwner returns (bool _success)
    {
        require(bytes(_ipfsHash).length == 46);
        require(bytes(_description).length > 0);
        _success = true;
        // A way to count the number of files uploaded (meta-data). Then we
        // can use it as an ID for the given meta-data
        fileCount++;
        files[fileCount] = File(
            fileCount,
            _ipfsHash,
            _timestamp,
            _description,
            payable(msg.sender),
            8 //This is the quality of the data provided by the provider. The quality must determines by data user
        );
        emit NewIoTDataPushed (fileCount, _ipfsHash, _timestamp, _description, payable(msg.sender));
        return _success;
    }

        // @desc Function to start a bid for selling IoT data. 
    function StartBidding (uint256 _fileCount, string memory _ipfsHash, string memory _description,
    uint _duration, uint _minBid) onlyOwner public{
        require(state == contractState.advertisedForSale);
        //the bidders will have only till the time timeStampLimit to bid .. bidding stops after that
        currentMaxBid = _minBid;//initialize device current price
        biddingWinner = msg.sender;//current owner
        biddingDuration = _duration;
        CurremttimeStamp = block.timestamp; 
        state = contractState.biddingInProgress;
        emit BiddingCommenced(_fileCount, _ipfsHash, _description,CurremttimeStamp, _duration, _minBid);
    }

    // @desc Function to end the bid 
    function EndBidding() onlyOwner public
    {
        require(state == contractState.biddingInProgress);
        require(block.timestamp <= (CurremttimeStamp + (biddingDuration * 1 minutes)));
        endBiddingTime = block.timestamp;
        state = contractState.biddingEnded;
        emit BiddingEndedAnnounceOwner();
    }
    
    // @desc Function to change the owner of the device/data transfer. Also,
    // the function calls an ACCESS CONTROL function to grant the role of
    // DATA_USER to the given bidding winner
     function ChangeOwnership() onlyOwner public
    {
        require(state == contractState.paymentReceivedByWinner);
        payable(msg.sender).transfer(currentMaxBid);//tranfer the ether to old owner (seller)
        iotdeviceowner = biddingWinner;    //change owner
        emit NewOwnerAnnounced(biddingWinner);
        state = contractState.newOwner;
        Granting_Roles(biddingWinner);
    }

////////////////////// Data user/IoT data consumer/buyer  functionalities ///////////////////
///////////////////////////////////////////////////////////////////////////////////////
    
    // @desc Function to query desired IoT data
    function QueryData() public onlyOwner
    {
    //Listen to the emitted event, i.e., NewIoTDataPushed, in order to
    // find the appropriate data they looking for.
    // It returns the list of the related potential metadata.
    // NewIoTDataPushed (uint256 fileId, Hash_IPFS, Hash_timestamp, Data_desciption, address uploader) 
    }
    
    // @desc Function to make a bid to buy the desired IoT data
     function MakeaBid(uint256 _fileCount, string memory _ipfsHash, string memory _description, uint bidAmount) public
    {
        require(RegisteredDataUsers[msg.sender] && (state > contractState.advertisedForSale && state < contractState.biddingEnded)
        && (state != contractState.someoneIsBiddingNow));//anyone can try to bid as long as the device is still onsale
        require(block.timestamp < (CurremttimeStamp + (biddingDuration * 1 minutes)));
        state = contractState.someoneIsBiddingNow;//when we are inside the state changes
        if(bidAmount > currentMaxBid)
        {
            currentMaxBid = bidAmount;
            biddingWinner = msg.sender;
            emit NewBidOffered(_fileCount, _ipfsHash, _description, currentMaxBid);
        }
        state = contractState.biddingInProgress;//back to previous state to allow others to bid
    }
 
    // @desc Function to pay the fee of the winned bid 
    function MakePayment(address _IoTDeviceOwner_reciever) costs OnlyBiddingWinner payable public
    {
        require(state == contractState.biddingEnded);
        // Before the paying the cost of data, the buyer can check if
        // the given data seller is a real seller throgh checking
        // her/his role
        require(Has_Role(DATA_SELLER, _IoTDeviceOwner_reciever));
        emit PaymentReceivedFromNewOwner(msg.sender);
        state = contractState.paymentReceivedByWinner;
    }

    // @desc Function to pull Metadata on the desired IoT data
    function IoTDataPullMetadata(address _IoTDeviceOwner, uint _IoT_device_type)
    public onlyOwner
    {
     // It returns the address of the metadata stored on the blockchain
    }

    // @desc Function to request desired IoT data from IPFS. The function
    // returns the payload data from the IPFS. 
    function RequestForData(bytes32 Metadata) public onlyOwner
    {
    }

    // @desc Function to rank the recieved data from the provider
    function RankData(uint256 _fileId, string memory _ipfsHash, int _rank) public onlyOwner
    {
     // It determines the qulity of the recieved pieces of data.
     // The rank can be between 1(for lowest qulity) and 10(highest quality)
     files[_fileId].DataQuality = _rank;
     emit RecievedDataRanked(_fileId, _ipfsHash, _rank );


    }

////////////////////// Role-based accecc Control functionalities /////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////
  
    // @desc Function do Revoking Roles from an account
    // The seller may want to restrict who can buy data. So, the seller revoke
    // the role of buyer from the given buyer 
    function Revoking_Roles(bytes32 _USER_ROLE, address _remote_user) public onlyOwner  {
        require(hasRole(_USER_ROLE, _remote_user));
        revokeRole (_USER_ROLE, _remote_user); 
        emit RevokingRoles(_USER_ROLE, _remote_user, msg.sender);
        
    }
    // @desc Function do Granting Roles to an account
    function Granting_Roles(address _remote_user) public onlyOwner  {
        // @desc Only account(s) with the admin role will be able to grant or revoke other roles
        require(!hasRole(DEFAULT_ADMIN_ROLE, msg.sender));
        grantRole(DATA_USER, _remote_user);
        emit GrantingRoles(DATA_USER, _remote_user, msg.sender);
    }

    // @desc Function to check the granted role(s) to a account OR
    // return `true` if the `account` belongs to our community
    function Has_Role(bytes32 _USER_ROLE, address _remote_user) view public onlyOwner returns(bool)  {
        // @desc Will returns true if account has been granted USER_ROLE role
        return hasRole(_USER_ROLE, _remote_user);
    }
    // @desc Function to transfer ownership of the contract to a new account 
    function Transfer_Ownership(address newOwner) public onlyOwner{
        address previousowner = address(msg.sender);
        emit OwnershipTransferring(previousowner, newOwner );

        }

////////////////////// Data Sharing functionalities //////////////////////
////////////////////////////////////////////////////////////////////////////

 // @desc Function do create new the pilicies for a remote user
    function create_data_sharing_policies() public onlyOwner  {
    }
    // @desc Function do update (adding) the pilicies for a data user/remote user./
    // The function takes in parameters, the user address for whom the permission/
    // will be accorded, the read and write permissions, and the hash information.
    function update_data_sharing_policies(address _Subject_public_ky,
    string memory _Resource_hash_of_data,
    string memory _Action,
    bool _Permission) public onlyOwner  {
        // @desc check the ownerhsip
        // require(msg.sender == owner);
        // update the permission access for the given data user, i.e., _Subject_public_ky
        permission[msg.sender].Subject_public_ky = _Subject_public_ky;
        permission[msg.sender].Resource_hash_of_data = _Resource_hash_of_data;
        permission[msg.sender].Action = _Action; // such as read and write
        permission[msg.sender].Permission_value = _Permission;
        emit UpdateDataDharingPolicies (msg.sender);
    }

}