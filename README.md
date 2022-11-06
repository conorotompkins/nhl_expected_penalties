# nhl_expected_penalties

A repo for analyzing why penalties are drawn in the NHL at 5v5.

## Levels

### Player-Season

At the player-season level, what player characteristics are associated with drawing more penalties at 5v5?

My theory is that the variables used to calculate xG are the same ones that help players draw penalties. If that is true, NHL players think there is value in xG.

* Box score stats (all 5v5)
  * Goals
  * Primary assists
  * Secondary assists
  * Shots (corsi)
  * Shots blocked by player
  * Penalties taken by player
  * Hits given by player
  * Hits received by player
  
* Advanced stats (all 5v5)
  * Median shot distance
  * Average shot angle (absolute from 0, 0 being direct at goal)
  * Median xG per shot
  * Game pace
    * xGF per 60
    * xGF per 60
    * CF per 60
    * CA per 60
  * % of shifts started in the offensive zone
* Player attributes
  * Age
  * Height
  * Weight
  * Handedness
  * Draft number
  * Games played in career
  
  
### Shift

For any given shift, what variables lead to a team drawing a penalty at 5v5?

* Game state (all stats from perspective of home team)
 * Score differential
 * Time remaining in period
 * Time remaining in game
 * Penalty differential
* Zone the shift started in
* Some measure of the quality of the players on the ice
* Did the previous play end in an icing?
