#===============================================================================
# Credit to Miles on discord
# How to use: 
#   Define encounter type in PField_Encounters
#   Make an event named WildPokemon
#   Define the (max 4) pokemon species in encounters.txt
#
#===============================================================================


def spawnpoke
  pokemon = 0
  level = 0
  enctype = EncounterTypes::StaticEncounter
  encounter = $PokemonEncounters.pbEncounteredPokemon(enctype)
    return false if !encounter
    $PokemonTemp.encounterType = enctype
    #(encounter[0],encounter[1]) are generated here?
    pokemon = encounter[0]
    level = encounter[1] 
    $PokemonTemp.encounterType = -1
  $game_variables[51] = pokemon
  $game_variables[52] = level
end

# custom spawn
def spawnpokeEvent
  pokemon = 0
  level = 0 
  enctype = EncounterTyoes::EventEncounter
  encounter = $PokemonEncounters.pbEncounteredPokemon(enctype)
    return false if !encounter
    $PokemonTemp.encounterType = enctype
    #(encounter[0],encounter[1]) are generated here?
    pokemon = encounter[0]
    level = encounter[1] 
    $PokemonTemp.encounterType = -1
  $game_variables[51] = pokemon
  $game_variables[52] = level
end

def resetecounters
    if $game_map
      for event in $game_map.events.values
        if event.name[/WildPokemon/]
          $game_self_switches[[$game_map.map_id,event.id,"A"]] = false
          $game_self_switches[[$game_map.map_id,event.id,"B"]] = false
          $game_self_switches[[$game_map.map_id,event.id,"C"]] = false
          $game_self_switches[[$game_map.map_id,event.id,"D"]] = false
        end
      end
      $game_map.need_refresh = true
    else
      #uhhhhh
    end
end