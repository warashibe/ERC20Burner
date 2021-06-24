//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../ERC20Burner.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import {ERC20Permit} from "./ERC20Permit.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/interfaces/IERC3156.sol";

contract DOGGOD is Ownable, ERC20Permit, AccessControlEnumerable, IERC3156FlashLender {
  bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
  bytes32 private constant _RETURN_VALUE = keccak256("ERC3156FlashBorrower.onFlashLoan");
  string public url;
  
  constructor(string memory _name, string memory _sym, uint _supply, address _burn_address) ERC20Burner(_name, _sym) ERC20Permit(_name) {
    _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    _setupRole(MINTER_ROLE, _msgSender());
    _mint(msg.sender, _supply);
    _setBurnAddress(_burn_address);
  }

  /**
   * @dev Returns the maximum amount of tokens available for loan.
   * @param token The address of the token that is requested.
   * @return The amont of token that can be loaned.
   */
  function maxFlashLoan(address token) public view override returns (uint256) {
    return token == address(this) ? IERC20(token).balanceOf(burn_address) : 0;
  }

  /**
   * @dev Returns the fee applied when doing flash loans. By default this
   * implementation has 0 fees. This function can be overloaded to make
   * the flash loan mechanism deflationary.
   * @param token The token to be flash loaned.
   * @param amount The amount of tokens to be loaned.
   * @return The fees applied to the corresponding flash loan.
   */
  function flashFee(address token, uint256 amount) public view virtual override returns (uint256) {
    require(token == address(this), "ERC20FlashMint: wrong token");
    // silence warning about unused variable without the addition of bytecode.
    amount;
    return 0;
  }

  /**
   * @dev Performs a flash loan. New tokens are minted and sent to the
   * `receiver`, who is required to implement the {IERC3156FlashBorrower}
   * interface. By the end of the flash loan, the receiver is expected to own
   * amount + fee tokens and have them approved back to the token contract itself so
   * they can be burned.
   * @param receiver The receiver of the flash loan. Should implement the
   * {IERC3156FlashBorrower.onFlashLoan} interface.
   * @param token The token to be flash loaned. Only `address(this)` is
   * supported.
   * @param amount The amount of tokens to be loaned.
   * @param data An arbitrary datafield that is passed to the receiver.
   * @return `true` is the flash loan was successfull.
   */
  function flashLoan(IERC3156FlashBorrower receiver, address token, uint256 amount, bytes calldata data) public virtual override returns (bool) {
    uint256 fee = flashFee(token, amount);
    _mint(address(receiver), amount);
    require(receiver.onFlashLoan(msg.sender, token, amount, fee, data) == _RETURN_VALUE, "ERC20FlashMint: invalid return value" );
    uint256 currentAllowance = allowance(address(receiver), address(this));
    require(currentAllowance >= amount + fee, "ERC20FlashMint: allowance does not allow refund");
    _approve(address(receiver), address(this), currentAllowance - amount - fee);
    _burn(address(receiver), amount + fee);
    return true;
  }
  
  function mint (address _to, uint _amount) public {
    require(hasRole(MINTER_ROLE, _msgSender()), "ERC20PresetMinterPauser: must have minter role to mint");
    _mint(_to, _amount);
  }
  
  function burn(uint256 amount) public virtual {
    _burn(_msgSender(), amount);
  }

  function burnFrom(address account, uint256 amount) public virtual {
    uint256 currentAllowance = allowance(account, _msgSender());
    require(currentAllowance >= amount, "ERC20: burn amount exceeds allowance");
    _approve(account, _msgSender(), currentAllowance - amount);
    _burn(account, amount);
  }

  function addBlock() public {}
  
}
