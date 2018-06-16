pragma solidity ^0.4.19;

import "./baseContentManager.sol";

contract Catalog{
    
    /* data about the contract itself */
    address private owner; // address of who uploads
    address private catalog_address; // address of the contract
    
    /* data about the catalog */
    BaseContentManager [] private contents_list; 
    mapping (bytes32 => uint) private position_content;
    mapping (address => uint) private premium_customers; // address of customer to expiration date as block height
    
    /* utilities variables */
    uint private time_premium = 40000; // premium lasts approximately one week
    uint private cost_content = 0.002 ether; // each content costs  about 80 cents
    uint private cost_premium = 0.03 ether; // premium costs about 12 euro
    uint16 private v = 100; // number of views required before payment
    
    /* events triggered */
    event catalog_created (address _catalog_address);
    event new_publication (bytes32 _title, bytes32 _author, bytes32 _genre);
    event content_acquired (bytes32 _title, address _customer, BaseContentManager _content);
    event premium_acquired (address _customer, uint _expiration);
    event author_payed (bytes32 _t, uint _tot_money);
    event catalog_destroyed ();

    /* modifiers that enforce that some functions are called just by specif agents */
    modifier byOwner() {
        require(msg.sender == owner);
        _;
    }

    /* constructor function of the catalog */
    constructor () public {
       owner = msg.sender;
       catalog_address = this;
       emit catalog_created(catalog_address);
    }
    
    
    
    /* Functions which do not change the state of the contract */
    
    /* returns the author of a content */
    function GetAuthor(bytes32 _t) public view returns (bytes32) {
        uint i = position_content[_t];
        if (i != 0) {
            return contents_list[i-1].author();
        }
    }
    
    /* returns the author of a content */
    function GetGenre(bytes32 _t) public view returns (bytes32) {
        uint i = position_content[_t];
        if (i != 0) {
            return contents_list[i-1].genre();
        }
    }
    
    /* returns the address of a content */
    function GetAddress (bytes32 _t) public view returns (address) {
        uint i = position_content[_t];
        if (i != 0) {
            return contents_list[i-1].content_address();
        }
    }
    
    
    /* returns the number of views for each content */
    function GetStatistics () public view returns (bytes32[], uint32[]){
        uint l_length = contents_list.length;
        bytes32 [] memory titles_list = new bytes32[](l_length);
        uint32 [] memory views_list = new uint32[](l_length);
        for (uint i = 0; i < l_length; i++) {
            titles_list[i] = contents_list[i].title();
            views_list[i] = contents_list[i].view_count();
        }
        return (titles_list, views_list);
    }
    
    /* returns the list of contents without the number of views */
    function GetContentList() public view returns (bytes32[]) {
        uint l_length = contents_list.length;
        bytes32 [] memory titles_list = new bytes32[](l_length);
        for (uint i = 0; i < l_length; i++) {
            titles_list[i] = contents_list[i].title();
        }
        return titles_list;
    }
    
    /* returns the list of x newest contents */
    function GetNewContentsList (uint x) public view returns (bytes32[]) {
        uint l_length = contents_list.length;
        bytes32 [] memory titles_list = new bytes32[](x);
        if (l_length > 0 && x != 0) {
            require(x <= l_length);
            for (uint i = l_length - 1; i>= l_length-x; i--) {
                titles_list[l_length - 1 - i] = contents_list[i].title();
                if (i == 0) {
                    return titles_list;
                }
            }
        }
        return titles_list;
    }
    
    /* returns the most recent content with genre _g */
    function GetLatestByGenre(bytes32 _g) public view returns (bytes32) {
        uint l_length = contents_list.length;
        if (l_length > 0) {
            for (uint i = l_length - 1; i >= 0; i--) {
                if (contents_list[i].genre() == _g) {
                    return contents_list[i].title();
                }
                if (i == 0) {
                    return 0x0;
                }
            }
        }
    }
    
    /* returns the content with genre _g with max views */
    function GetMostPopularByGenre (bytes32 _g) public view returns (bytes32) {
        bytes32 most_popular = 0;
        uint32 most_views = 0;
        for (uint i = 0; i < contents_list.length; i++) {
            if (contents_list[i].genre() == _g && contents_list[i].view_count() > most_views) {
                most_popular = contents_list[i].title();
                most_views = contents_list[i].view_count();
            }
        }
        return most_popular;
    }
    
    /* returns the most recent content of the author _a */
    function GetLatestByAuthor (bytes32 _a) public view returns (bytes32) {
        uint l_length = contents_list.length;
        if (l_length > 0) {
            for (uint i = l_length - 1; i >= 0; i--) {
                if (contents_list[i].author() == _a) {
                    return contents_list[i].title();
                }
                if (i == 0) {
                    return 0x0;
                }
            }
        }
    }
    
    /* returns the content with most views of the author _a */
    function GetMostPopularByAuthor (bytes32 _a) public view returns (bytes32){
        bytes32 most_popular = 0;
        uint32 most_views = 0;
        for (uint i = 0; i < contents_list.length; i++) {
            if (contents_list[i].author() == _a && contents_list[i].view_count() > most_views) {
                most_popular = contents_list[i].title();
                most_views = contents_list[i].view_count();
            }
        }
        return most_popular;
    }
    
    /* returns true if _c is a valid premium account */
    function isPremium (address _c) public view returns(bool) {
        return premium_customers[_c] > block.number;
    }
    
    
    
    /* Functions which modify the state of the contract */
    
    /* submits a new content _c to the catalog */
    function AddContent (BaseContentManager _c) external {
        BaseContentManager cm = _c;
        require (cm.owner() == msg.sender && cm.catalog() == catalog_address);
        contents_list.push(cm);
        position_content[cm.title()] = contents_list.length;
        emit new_publication (cm.title(), cm.author(), cm.genre());
    }
    
    /* pays to access content _t */
    function GetContent (bytes32 _t) external payable {
        require(msg.value == cost_content);
        uint i = position_content[_t];
        if (i != 0) {
            contents_list[i-1].Authorize(msg.sender);
            emit content_acquired (_t, msg.sender, contents_list[i-1]);
        }
    }
    
    /* premium accounts can requests access to content _t without paying */
    function GetContentPremium (bytes32 _t) external {
        require(isPremium(msg.sender));
        uint i = position_content[_t];
        if (i != 0) {
            contents_list[i-1].AuthorizePremium(msg.sender, premium_customers[msg.sender]);
            emit content_acquired (_t, msg.sender, contents_list[i-1]);
        }
    }
    
    /* pays for granting access to content _t to the user _u */
    function GiftContent  (bytes32 _t, address _u) external payable {
        require(msg.value == cost_content); 
        uint i = position_content[_t];
        if (i != 0) {
            contents_list[i-1].Authorize(_u);
            emit content_acquired (_t, _u, contents_list[i-1]);
        }
    }
    
    /* pays for granting a premium account to the user _u */
    function GiftPremium  (address _u) external payable {
        require(msg.value == cost_premium); 
        premium_customers[_u] = block.number + time_premium;
        emit premium_acquired (_u, premium_customers[_u]);
    }
    
    /* buys a new premium subscription */
    function BuyPremium () external payable {
        require(msg.value == cost_premium); 
        premium_customers[msg.sender] = block.number + time_premium;
        emit premium_acquired (msg.sender, premium_customers[msg.sender]);
    }
    
    /* pay an author a multiple of v views*/
    function PayAuthor (bytes32 _t) external {
        uint i = position_content[_t];
         if (i != 0) {
            uint32 tot_views = contents_list[i-1].view_count();
            uint32 to_pay = tot_views - contents_list[i-1].views_already_payed();
            if (to_pay >= v) {
                contents_list[i-1].owner().transfer(to_pay * cost_content);
                contents_list[i-1].Payed(to_pay);
                emit author_payed (_t, to_pay * cost_content);
            }
        }
    }
    
    /* returns the total number of views and the total number of views that has to payed */
    function GetTotalViews () private view returns (uint, uint) {
        uint l_length = contents_list.length; 
        uint tot_views = 0;
        uint tot_already_payed = 0;
        for (uint i = 0; i < l_length; i++) {
            tot_views = tot_views + contents_list[i].view_count();
            tot_already_payed = tot_already_payed + contents_list[i].views_already_payed();
        }
        return (tot_views, tot_already_payed);
    }
    
    /* the catalog can be destructed */
    function KillCatalog () external byOwner {
        uint tot_views;
        uint tot_already_payed;
        (tot_views, tot_already_payed) = GetTotalViews();
        uint money_remaining_views = (tot_views - tot_already_payed) * cost_content; 
        uint money_per_view = (catalog_address.balance - money_remaining_views) / tot_views;
        for (uint i = 0; i < contents_list.length; i++) {
            uint remaining_money = (contents_list[i].view_count() - contents_list[i].views_already_payed()) * cost_content;
            uint proportional_money = contents_list[i].view_count() * money_per_view;
            uint tot_money = remaining_money + proportional_money;
            contents_list[i].owner().transfer(tot_money);
            emit author_payed (contents_list[i].title(), tot_money);
        }
        emit catalog_destroyed ();
        selfdestruct(catalog_address);
    }
}