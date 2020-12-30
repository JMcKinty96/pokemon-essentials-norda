#===============================================================================
# Type effectiveness is multiplied by the Fairy-type's effectiveness against
# the target. (Mythic Blast)
#===============================================================================
class PokeBattle_Move_1F4 < PokeBattle_Move # 500
  def pbCalcTypeModSingle(moveType,defType,user,target)
    ret = super
    if hasConst?(PBTypes,:FAIRY)
      fairyEff = PBTypes.getEffectiveness(getConst(PBTypes,:FAIRY),defType)
      ret *= fairyEff.to_f/PBTypeEffectiveness::NORMAL_EFFECTIVE_ONE
    end
    return ret
  end
end

#===============================================================================
# Entry hazard. Sets up a snowy trap on the opposing side. (Snow Trap)
#===============================================================================
class PokeBattle_Move_1F5 < PokeBattle_Move
  def pbMoveFailed?(user,targets)
    if user.pbOpposingSide.effects[PBEffects::SnowTrap]
      @battle.pbDisplay(_INTL("But it failed!"))
      return true
    end
    return false
  end

  def pbEffectGeneral(user)
    user.pbOpposingSide.effects[PBEffects::SnowTrap] = true
    @battle.pbDisplay(_INTL("Jagged ice has been concealed around {1}!",
       user.pbOpposingTeam(true)))
	# for balance purposes, get rid of all layers of Spikes too
	if user.pbOpposingSide.effects[PBEffects::Spikes] > 0
      user.pbOpposingSide.effects[PBEffects::Spikes] = 0 if NEWEST_BATTLE_MECHANICS
      @battle.pbDisplay(_INTL("{1} got rid of the Spikes around {2}!",user.pbThis,user.pbOpposingTeam(true)))
    end
  end
end
#===============================================================================
# 
# 
#===============================================================================