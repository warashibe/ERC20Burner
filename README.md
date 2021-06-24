# ERC20Burner

ERC20 with the burn address settable other than `address(0)`. 

The burn address cannot transfer any amount of its own balance.

Minted balance comes from the burn address if the burn address is set other than `address(0)`.

## Test

``` bash
yarn test
```
