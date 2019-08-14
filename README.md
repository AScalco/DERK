# DERK
DERK - A NetLogo model of individual diet emergence starting from the knowledge of pairing foods.

## General information
- DERK runs on Netlogo 5.3.1.
- The model has been recently developed (March 2019) and it started as a pure exercise to understand how lists and lists of lists in
Netlogo work.

## Abstract
DERK creates one or more individuals each one endowed with a set of recipes (meaning, what foods can be paired). At each time step, an
agent decides to consume a meal corresponding to a random recipe. Accordingly, it checks if all the ingredients required for the recipe are
available: when they are available it consumes immediately the meal, otherwise it must first shop for the food it needs and then consume
the meal. Food availability is checked after each consumed meals and food shopping.
