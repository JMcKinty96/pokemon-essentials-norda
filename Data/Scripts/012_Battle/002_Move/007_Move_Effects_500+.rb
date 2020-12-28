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
    @battle.pbDisplay(_INTL("A trap covered in opaque snow is set around {1}!",
       user.pbOpposingTeam(true)))
  end
end
#===============================================================================
# 
# 
#===============================================================================