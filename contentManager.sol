pragma solidity ^0.4.19;

import "./catalog.sol";

contract BaseContentManager {
    
    /* data about the contract itself */
    address public owner; // address of who uploads
    address public content_address; // address of the contract
    address public catalog; // catalog where the content is published
    
    /* data about the content */
    bytes32 public title; // unique ID
    bytes32 public author; // name of the author
    bytes32 public genre; // indicates both the type {song, video, photo} and the genre
    uint32 public view_count; // number of views
    uint32 public views_already_payed; // number of viewsalready payed by the catalog
    
    /* data about the customers authorized to access the content */
    mapping (address => bool) private authorized_std;
    mapping (address => uint) private authorized_premium;
    
    uint32 private v = 100; // number of views required before payment


    /* events triggered */
    event content_created (address _content_address); // new content created
    event v_reached (uint32 _views_to_be_payed); // reached the number of views to request a payment
    event content_consumed (address _customer); // customer just consumed this content
    event content_destroyed (); // the content no longer can be accessed

    /* modifiers that enforce that some functions are called just by specif agents */
    modifier byOwner() {
        require(msg.sender == owner);
        _;
    }
    modifier byCatalog() {
        require(msg.sender == catalog);
        _;
    }
    modifier byAuthorized() {
        require(authorized_std[msg.sender] || authorized_premium[msg.sender] > block.number);
        _;
    }
    
    /* constructor function of the content manager */
    constructor (address _catalog, bytes32 _title, bytes32 _author, bytes32 _gen) public {
        owner = msg.sender;
        content_address = this;
        catalog = _catalog;
        title = _title;
        author = _author;
        genre = _gen;
        view_count = 0;
        views_already_payed = 0;
        emit content_created (content_address);
    }


    /* insert the customer address as authorized to access this content */
    function Authorize (address _customer) external byCatalog{
        authorized_std[_customer] = true;
    }
    
    /* insert the customer address as authorized to access this content */
    function AuthorizePremium (address _customer, uint _expiration_date) external byCatalog{
        authorized_premium[_customer] = _expiration_date;
    }
    
     /* called by the catalog to mark the views already payed */
    function Payed (uint32 _views_just_payed) external byCatalog {
        views_already_payed = views_already_payed + _views_just_payed; 
    }
    
    /* authorized customers can consume the content */
    function ConsumeContent () external byAuthorized {
        if (authorized_std[msg.sender]) {
            view_count ++;
            if (view_count % v == 0) {
                emit v_reached (view_count - views_already_payed);
            }
            delete authorized_std[msg.sender] ;
        } else {
            delete authorized_premium[msg.sender] ;
        }
        emit content_consumed (msg.sender);
    }
    
    /* the content can be destructed */
    function KillContent () external byOwner {
        emit content_destroyed ();
        selfdestruct(content_address);
    }
}