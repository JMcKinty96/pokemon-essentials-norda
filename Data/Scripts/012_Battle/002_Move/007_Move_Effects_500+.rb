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
# 
# 
#===============================================================================