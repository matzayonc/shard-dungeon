<picture>
  <source media="(prefers-color-scheme: dark)" srcset=".github/mark-dark.svg">
  <img alt="Dojo logo" align="right" width="120" src=".github/mark-light.svg">
</picture>

<a href="https://twitter.com/dojostarknet">
<img src="https://img.shields.io/twitter/follow/dojostarknet?style=social"/>
</a>
<a href="https://github.com/dojoengine/dojo">
<img src="https://img.shields.io/github/stars/dojoengine/dojo?style=social"/>
</a>

[![discord](https://img.shields.io/badge/join-dojo-green?logo=discord&logoColor=white)](https://discord.gg/PwDa2mKhR4)
[![Telegram Chat][tg-badge]][tg-url]

[tg-badge]: https://img.shields.io/endpoint?color=neon&logo=telegram&label=chat&style=flat-square&url=https%3A%2F%2Ftg.sumanjay.workers.dev%2Fdojoengine
[tg-url]: https://t.me/dojoengine

# Shard Dungeon

An example of a Dojo game that is a simple dungeon crawler using Saya for settlement and Katana sharding execution.

## Quick start

```bash
# Build the project.
sozo build

# The world's address may change if dojo-core is modified. Please check the Scarb.toml
# and replace as necessary. If you don't know yet the world's address, comment it.
sozo migrate apply

# Register a player:
sozo execute shard_dungeon::systems::metagame::metagame register_player -c str:player1

# Run the dungeon:
sozo execute shard_dungeon::systems::hazard_hall::hazard_hall fate_strike
```

## Architecture

The idea of the demonstration is to have a metagame on Starknet, where players can register and then start a dungeon. For now, the dungeon is single player.

The shard execution must start the dungeon run, the player has to interact with the shard to effectively finish beat the dungeon's boss.

Once the dungeon is over, Saya must have all the necessary info to update the world state on the base layer.

### Managing conflicts

Due to the assumption that multiple app-chains (katanas) can run at the same time, the former commitment might be overwritten by the latter.

Requirement of creating a `Starknet` transaction by user, to create a structure similar to a `Mutex`, before forking app-chain is limiting in practice.

#### Overwriting problem

For example a player can earn 5 gold in one dungeon and lose 3 in another. Depending on the order of settlement the change would be +5 or -3, but never the correct +2.

#### Diffs

To solve the problem over overwriting changes we can commit only the difference in the important values. So in the example above we would get 2 diffs, that can be processed in any order.

Two possible ways of committing these, without causing a conflict on its own, are:

- **Storing artifacts** - each app-chain commitment would leave its diffs in the contracts storage. These would then be claimable. There could be an limit of only one active dungeon per chain or each would have stored at a different key, to avoid overwriting. The final claiming transaction is a limitation but it could be claimed by saya itself.
- **Sending message to starknet** - event containing diffs is emitted after reaching the dungeon exit. Is is then extracted by saya, and then committed on a dedicated entrypoint.

#### Value limits

There are cases values can't be negative (like gold) or non positive (like health).
If a given diff would take the value below the limit, the dungeon will be blocked from commitment.

Taking this a step further, it might be the case that a player barely survived a dungeon, but would not do so if started at the state of commitment.

For example a Player could start with 2 health, then dropped to 1, and healed back to 10. But before commitment, in another dungeon it just dropped to 1. If forked at this point, the player would not survive.

To cover this case we would need to pass `minimum_required` together with diffs.

#### Instance limit

One of the goals is to ensure that multiple instances can run at the same time.

Because no communication between running app-chains is possible, or at least considered they can be thought of as a continuous time between the chain's fork (read) and commitment (write).

Limit of a single active dungeon is trivial to enforce at the contract level.
When applying changes with saya,
