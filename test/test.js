const { expect, assert } = require("chai")
const { to18, from18, UINT_MAX, deploy, a, isErr } = require("./utils")
const { ethers } = require("hardhat")
const { utils } = ethers

describe("Freigeld", () => {
  let owner, burner, ac
  beforeEach(async () => {
    ac = await ethers.getSigners()
    ;[owner, burner] = ac
  })
  it("should set burn address", async () => {
    const token = await deploy("DOGGOD", "DOGGOD", "DOGGOD", 100, a(burner))
    expect(await token.balanceOf(a(owner))).to.equal(100)
    await token.burn(50)
    expect(await token.balanceOf(a(owner))).to.equal(50)
    expect(await token.balanceOf(a(burner))).to.equal(50)
    await token.mint(a(owner), 10)
    expect(await token.balanceOf(a(owner))).to.equal(60)
    expect(await token.balanceOf(a(burner))).to.equal(40)
    await isErr(token.connect(burner).transfer(a(owner), 10))
  })
})
