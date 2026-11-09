# Creature-Collector-Simulation

An ambitious Godot 4.7 project to attempt to replicate the themings of element-based creatures (i.e. Pokemon, Cassette Beasts, Coromon, Etc.) inside of a nature simulator

## Controls
- Use scroll wheel to zoom the camera
- Hold middle mouse and move to pan the camera

## How does it work?
Creatures, or "Agents", have a list of ambiguous body parts that correlates to stats. Everytime a creature reproduces, it will mutate the stats a little bit, or potentially do more drastic things, such as changing diet types, adding new limbs, and more.

While more unique behavior for creatures are planned, it currently consists of basic food finding, prey fleeing from predators, mating, and battling.

### More on battling
When a carnivore or omnivore wishes to hunt another creature, it will initate a battle. This functions as a simple turn-based system, where each creature exchanges hits based on their moveset and stats. However, unlike the inspired materials, moves do not have "Base Power", only having its damage type (Physical or Special) and elemental typing. This is to avoid powercreep!!

## The final goal
Once the simulation part of the project is well rounded, I wish to expand this into a survival-focused creature collector. One where you can release a creature into the ecosystem, and use a device to skip 1 year into the future, and see how the ecosystem changes.

## How to use / Play
- Download the latest .EXE from [Github Releases](https://github.com/Kaplin86/Creature-Collector-Simulation/releases/tag/Major-Release)
- Run the exe file
- If windows defender pops up, press "Run Anyway"
### Non-windows versions
- For the time being, since I don't have a proper way to test and verify the other exports, there will not be exports for non-windows OS.

## Development
- Engine used is Godot 4.7
- Clone the repo, and hit Import in Godot, and select the project.godot file inside the repo

## License

Distributed under MIT license. See `LICENSE` for more information.

## Extra Comments
Made for hack club's terra program, alongside out of my own curiosity for what a project like this would look like.
This project was NOT made by an ecologist, so please don't go looking for real-world accuracy!
