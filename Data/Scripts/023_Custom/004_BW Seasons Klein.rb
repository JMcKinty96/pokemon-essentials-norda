#===============================================================================
# € BW Seasons by KleinStudio
#===============================================================================

#===============================================================================
# € Months and seasons
#===============================================================================
#===============================================================================
# * Variable number for fake season
# * Enable or disable seasons
# * Tilesets for seasons
#    [Original tileset id, [Summer, Autumn, Winter, Spring]]
#===============================================================================
FAKESEASONVAR=26
SEASONS=true

# Tilesets go Winter-Spring-Summer-Autumn NOPE
SEASONSTILESETS = [
[25, [25,25,25,25]] # Tileset id 1
]
JANUARY=1
FEBRUARY=2
MARCH=3
APRIL=4
MAY=5
JUNE=6
JULY=7
AUGUST=8
SEPTEMBER=9
OCTOBER=10
NOVEMBER=11
DECEMBER=12

WINTER=1
SPRING=2
SUMMER=3
AUTUMN=4

#===============================================================================
# € Get current season
#===============================================================================
# def pbGetSeason
  # if $game_variables[FAKESEASONVAR]!=0
    # @season=$game_variables[FAKESEASONVAR]
  # else
   # if Time.now.mon==DECEMBER or Time.now.mon==JANUARY or Time.now.mon==FEBRUARY
    # return WINTER
   # elsif Time.now.mon==MARCH or Time.now.mon==APRIL or Time.now.mon==MAY
    # return SPRING
   # elsif Time.now.mon==JUNE or Time.now.mon==JULY or Time.now.mon==AUGUST
    # return SUMMER
   # elsif Time.now.mon==SEPTEMBER or Time.now.mon==OCTOBER or Time.now.mon==NOVEMBER
    # return AUTUMN
   # end 
  # end
# end

#===============================================================================
# € Add season info to PokemonGlobal
#===============================================================================
class PokemonGlobalMetadata
  attr_accessor :disablesplash
  attr_accessor :season
  attr_accessor :lastindoor
  attr_accessor :lastseason
  
  def refreshSeason
    oldseason=@season
    @season=pbGetSeason
  end
   
  def getSeason
    @season=pbGetSeason if !@season
    @lastseason=@season if @lastseason==nil
    return @season if @season
  end
  
  def getLastSeason
    @lastseason=pbGetSeason if !@lastseason
    return @lastseason if @lastseason
  end
  
  def lastindoor?
    return @lastindoor if @lastindoor
  end

end

#===============================================================================
# € Edit game_map
#===============================================================================
class Game_Map
  
  def setup(map_id)
    @map_id = map_id
    @map=load_data(sprintf("Data/Map%03d.%s", map_id,$RPGVX ? "rvdata" : "rxdata"))
    pbRefreshSeason # Refresh actual season if needed
    $lastmap=@map_id
    
    if SEASONS; for i in 0...SEASONSTILESETS.length
      if SEASONSTILESETS[i][0]==@map.tileset_id
       seasonsets=SEASONSTILESETS[i][1]
       actualseason=$PokemonGlobal.getLastSeason
       actualseason=$PokemonGlobal.getSeason if $PokemonGlobal.lastindoor?
       actualseason=pbGetSeason if actualseason<1
       echo("#{pbGetSeasonName(actualseason)}\n#{actualseason}")

       @map.tileset_id=seasonsets[actualseason-1]
      end
    end; end
  
    tileset = $data_tilesets[@map.tileset_id]
    @tileset_name = tileset.tileset_name
    
    @autotile_names = tileset.autotile_names
    @panorama_name = tileset.panorama_name
    @panorama_hue = tileset.panorama_hue
    @fog_name = tileset.fog_name
    @fog_hue = tileset.fog_hue
    @fog_opacity = tileset.fog_opacity
    @fog_blend_type = tileset.fog_blend_type
    @fog_zoom = tileset.fog_zoom
    @fog_sx = tileset.fog_sx
    @fog_sy = tileset.fog_sy
    @battleback_name = tileset.battleback_name
    @passages = tileset.passages
    @priorities = tileset.priorities
    @terrain_tags = tileset.terrain_tags
    self.display_x = 0
    self.display_y = 0
    @need_refresh = false
    Events.onMapCreate.trigger(self,map_id, @map, tileset)
    @events = {}
    for i in @map.events.keys
      @events[i] = Game_Event.new(@map_id, @map.events[i],self)
    end
    @common_events = {}
    for i in 1...$data_common_events.size
      @common_events[i] = Game_CommonEvent.new(i)
    end
    @fog_ox = 0
    @fog_oy = 0
    @fog_tone = Tone.new(0, 0, 0, 0)
    @fog_tone_target = Tone.new(0, 0, 0, 0)
    @fog_tone_duration = 0
    @fog_opacity_duration = 0
    @fog_opacity_target = 0
    @scroll_direction = 2
    @scroll_rest = 0
    @scroll_speed = 4
    

  end
end

#===============================================================================
# € Internal functions
#===============================================================================

   def pbShowSeasonSplash
     return if !$Trainer or !$PokemonGlobal
     return if $PokemonGlobal.disablesplash || !SEASONS
     return if !$PokemonGlobal.lastindoor
     return if $PokemonGlobal.lastseason==$PokemonGlobal.getSeason
     # current=pbGetSeasonName($PokemonGlobal.getSeason)
	 # pbGetMonthName(pbGetTimeNow.mon)
	 current=pbGetSeasonName(pbGetSeason)
     @black = Sprite.new
     @black.bitmap = RPG::Cache.picture("blackscreen")
     @black.z=9999999
     @black.zoom_y=2.5
     @season = Sprite.new
     @season.bitmap = RPG::Cache.picture("season_"+ current)
     @season.opacity = 0
     @season.z=9999999
     Graphics.transition
     20.times do
     Graphics.update
     @season.opacity+=25.5/2
     end
     Graphics.wait(60)
     20.times do
     Graphics.update
     @season.opacity-=25.5/2
     @black.opacity-=25.5/2
     end
     @black.dispose
     @season.dispose
     $PokemonGlobal.lastseason=$PokemonGlobal.getSeason
     $PokemonGlobal.lastindoor=false
   end
   
   # def pbGetSeasonName(season)
     # case season
     # when 1
     # return "winter"
     # when 2
     # return "spring"
     # when 3
     # return "summer"
     # when 4
     # return "autumn"
     # end
   # end

   
   def pbRefreshSeason # Only refresh when it's indoor
     mapid=$lastmap ? $lastmap : $game_map.map_id
     isoutdoor=pbGetMetadata(mapid,MetadataOutdoor)
     if $game_map && (!isoutdoor or isoutdoor==false)
       $PokemonGlobal.refreshSeason
       $PokemonGlobal.lastindoor=true
     end
   end

#===============================================================================
# € User functions
#===============================================================================

   def pbDisableSeasonSplash # Disable season splash
     $PokemonGlobal.disablesplash=true
   end
   
   def pbEnableSeasonSplash # Enable seasons splash if disabled
     $PokemonGlobal.disablesplash=false
   end
   
   def makeWinter # Make winter
     $game_variables[FAKESEASONVAR]=WINTER
     $PokemonGlobal.refreshSeason
   end
   
   def makeSpring # Make spring
     $game_variables[FAKESEASONVAR]=SPRING
     $PokemonGlobal.refreshSeason
   end
   
   def makeSummer # Make summer
     $game_variables[FAKESEASONVAR]=SUMMER
     $PokemonGlobal.refreshSeason
   end
   
   def makeAutumn # Make autumn
     $game_variables[FAKESEASONVAR]=AUTUMN
     $PokemonGlobal.refreshSeason
   end
   
   def realSeason # Back to real season
     $game_variables[FAKESEASONVAR]=0
     $PokemonGlobal.refreshSeason
   end