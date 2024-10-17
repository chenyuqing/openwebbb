// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import {IERC721, IERC721Receiver, IERC165} from "./IERC721.sol";

contract ERC721 is IERC721 {
    event Transfer(
        address indexed src, address indexed dst, uint256 indexed id
    );
    event Approval(
        address indexed owner, address indexed spender, uint256 indexed id
    );
    event ApprovalForAll(
        address indexed owner, address indexed operator, bool approved
    );

    // Mapping from token ID to owner address
    mapping(uint256 => address) internal _ownerOf;
    // Mapping owner address to token count
    mapping(address => uint256) internal _balanceOf;
    // Mapping from token ID to approved address
    mapping(uint256 => address) internal _approvals;
    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) public override isApprovedForAll;

    function supportsInterface(bytes4 interfaceId)
        external
        pure
        override
        returns (bool)
    {
        return interfaceId == type(IERC721).interfaceId
            || interfaceId == type(IERC165).interfaceId;
    }

    function ownerOf(uint256 id) external view override returns (address owner) {
        owner = _ownerOf[id];
        require(owner != address(0), "token doesn't exist");
    }

    function balanceOf(address owner) external view override returns (uint256) {
        require(owner != address(0), "owner = zero address");
        return _balanceOf[owner];
    }

    function setApprovalForAll(address operator, bool approved) external override {
        isApprovedForAll[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function getApproved(uint256 id) external view override returns (address) {
        require(_ownerOf[id] != address(0), "token doesn't exist");
        return _approvals[id];
    }

    function approve(address spender, uint256 id) external override {
        address owner = _ownerOf[id];
        require(
            msg.sender == owner || isApprovedForAll[owner][msg.sender],
            "not authorized"
        );
        _approvals[id] = spender;
        emit Approval(owner, spender, id);
    }

    function _isApprovedOrOwner(address owner, address spender, uint256 id)
        internal
        view
        returns (bool)
    {
        return (
            spender == owner || isApprovedForAll[owner][spender]
                || spender == _approvals[id]
        );
    }

    function transferFrom(address src, address dst, uint256 id) public override {
        require(src == _ownerOf[id], "src != owner");
        require(dst != address(0), "transfer dst zero address");

        require(_isApprovedOrOwner(src, msg.sender, id), "not authorized");

        _balanceOf[src]--;
        _balanceOf[dst]++;
        _ownerOf[id] = dst;

        delete _approvals[id];

        emit Transfer(src, dst, id);
    }

    function safeTransferFrom(address src, address dst, uint256 id) external override {
        transferFrom(src, dst, id);

        require(
            dst.code.length == 0
                || IERC721Receiver(dst).onERC721Received(msg.sender, src, id, "")
                    == IERC721Receiver.onERC721Received.selector,
            "unsafe recipient"
        );
    }

    function safeTransferFrom(
        address src,
        address dst,
        uint256 id,
        bytes calldata data
    ) external override {
        transferFrom(src, dst, id);

        require(
            dst.code.length == 0
                || IERC721Receiver(dst).onERC721Received(msg.sender, src, id, data)
                    == IERC721Receiver.onERC721Received.selector,
            "unsafe recipient"
        );
    }

    function mint(address dst, uint256 id) external {
        require(dst != address(0), "mint dst zero address");
        require(_ownerOf[id] == address(0), "already minted");

        _balanceOf[dst]++;
        _ownerOf[id] = dst;

        emit Transfer(address(0), dst, id);
    }

    function burn(uint256 id) external {
        require(msg.sender == _ownerOf[id], "not owner");

        _balanceOf[msg.sender] -= 1;

        delete _ownerOf[id];
        delete _approvals[id];

        emit Transfer(msg.sender, address(0), id);
    }
}
