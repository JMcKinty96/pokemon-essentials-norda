#--------------------------------------------------------------------------
  # * Turn Towards event
  # by lavendersiren 
  #------------- --- -- -  -
  # How to use:
  # Type "turn_towards_event(x)" in a script action in Move Event, 
  # with x being the desired Event ID for your selected event/player to look at.
  #------------- --- -- -  -
  # Use in anything you want, it's p much a basic edit.
  # Credit would be nice but not strictly necessary.
  #--------------------------------------------------------------------------

class Game_Character

 def turn_toward_event(id)
    #the subject's x minus the target's x, same with y
    sx = @x - $game_map.events[id].x
    sy = @y - $game_map.events[id].y
    # If coordinates are equal
    if sx == 0 and sy == 0
      return
    end
    # If horizontal distance is longer
    if sx.abs > sy.abs
      # Turn to the right or left towards event
      sx > 0 ? turn_left : turn_right
    # If vertical distance is longer
    else
      # Turn up or down towards event
      sy > 0 ? turn_up : turn_down
    end
  end   

end