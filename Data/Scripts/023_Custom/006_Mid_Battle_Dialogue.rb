#==============================================================================#
#\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\#
#==============================================================================#
#                                                                              #
#                          Mid Battle Dialogue and Script                      #
#                                       v1.0                                   #
#                                 By Golisopod User                            #
#                                                                              #
#==============================================================================#
#\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\#
#==============================================================================#
#                                                                              #
# Implements Functionality for easily setting up dialogue in between trainer   #
# battles. The dialogue can be called at many different instances, including   #
# but not limited to, a specific turn number, on each individual Pokemon being #
# sent out by the player or opponent, usage of items, when A Pokémon is less   #
# than 1/2th or 1/4th of its HP and much more. It works with both Trainer and  #
# Wild Battles so you can bring some extra spice to your Boss Battles and Gym  #
#  Battles. It allows you to create battles with varying intensity and with    #
# story and character, right in the battle. It allows directly manipulating    #
# the battle and the battle scene which allows you to interact with battles    #
# like never before. The only limit is your imagination.                       #
#                                                                              #
# This Script is meant for the default Essentials battle system. The upcoming  #
# EBDX already has very similar functionality inbuilt.                         #
#                                                                              #
#==============================================================================#
#                              INSTRUCTIONS                                    #
#------------------------------------------------------------------------------#
# 1. Place the script.txt from the ZIP in a new section above Main             #
#                                                                              #
# 2. Start a new save (Not nescessary, but just to be on the safe side)        #
#------------------------------------------------------------------------------#
#        INFO ABOUT THE PARAMETERS AND METHODS FOR TRAINER DIALOGUE            #
#------------------------------------------------------------------------------#
#                                                                              #
# All the info has been mentioned clearly in the Main Post. Please read all of #
# it thoroughly and don't skip any parts. 90% of errors you'll get while       #
# starting a battle are gonna be Syntax Errors you get when you don't use the  #
# commands properly.                                                           #
#                                                                              #
#------------------------------------------------------------------------------#
#                          CUSTOMIZABLE OPTIONS                                #
#==============================================================================#

class PokeBattle_DamageState
  attr_accessor :bigDamage   # For Big DMG Dialogue
  attr_accessor :smlDamage   # For Small Dmg Dialogue
  attr_accessor :lowHP   # For Small Dmg Dialogue
  attr_accessor :halfHP   # For Small Dmg Dialogue
  attr_accessor :firstAttack # For Attack Dialogue
  attr_accessor :superEff   # For Big DMG Dialogue
  attr_accessor :notEff   # For Small Dmg Dialogue

  def reset
    @initialHP    = 0
    @typeMod      = 0
    @unaffected   = false
    @protected    = false
    @magicCoat    = false
    @magicBounce  = false
    @totalHPLost  = 0
    @fainted      = false
    @bigDamage    = 0
    @smlDamage    = 0
    @halfHP       = false
    @lowHP        = false
    @firstAttack  = false
    @superEff     = 0
    @notEff       = 0
    resetPerHit
  end
end

class PokeBattle_Battle
# For Turn Based Messages
  def pbBattleLoop
    @turnCount = 0
    loop do   # Now begin the battle loop
      PBDebug.log("")
      PBDebug.log("***Round #{@turnCount+1}***")
      if @debug && @turnCount>=100
        @decision = pbDecisionOnTime
        PBDebug.log("")
        PBDebug.log("***Undecided after 100 rounds, aborting***")
        pbAbort
        break
      end
      TrainerDialogue.display("turnStart#{@turnCount}",self,@scene)
      break if @decision>0
      PBDebug.log("")
      # Command phase
      PBDebug.logonerr { pbCommandPhase }
      break if @decision>0
      # Attack phase
      PBDebug.logonerr { pbAttackPhase }
      break if @decision>0
      # End of round phase
      PBDebug.logonerr { pbEndOfRoundPhase }
      break if @decision>0
      TrainerDialogue.display("turnEnd#{@turnCount}",self,@scene)
      break if @decision>0
      @turnCount += 1
      TrainerDialogue.setFinal
    end
    pbEndOfBattle
    TrainerDialogue.resetAll
  end
# For Start Battle Messages
#  def pbStartBattleSendOut(sendOuts) # needs editing if you want the friendship etc messages
  def pbStartBattleSendOutEX(sendOuts)
    # "Want to battle" messages
    if wildBattle?
      foeParty = pbParty(1)
      case foeParty.length
      when 1
		if foeParty[0].level >= (maxLevel + 15)
			pbDisplayPaused(_INTL("A very strong-looking wild {1} appeared!",foeParty[0].name))
		else
			pbDisplayPaused(_INTL("Oh! A wild {1} appeared!",foeParty[0].name))
		end
      when 2
        pbDisplayPaused(_INTL("Oh! A wild {1} and {2} appeared!",foeParty[0].name,
           foeParty[1].name))
      when 3
        pbDisplayPaused(_INTL("Oh! A wild {1}, {2} and {3} appeared!",foeParty[0].name,
           foeParty[1].name,foeParty[2].name))
      end
    else   # Trainer battle
      case @opponent.length
      when 1
        # Edited
        case TrainerDialogue.eval("battleStart")
        when -1
          pbDisplayPaused(_INTL("You are challenged by {1}!",@opponent[0].fullname))
        when 0
          battleStart= TrainerDialogue.get("battleStart")
          pbDisplayPaused(_INTL(battleStart,@opponent[0].fullname))
        when 1
          battleStart= TrainerDialogue.get("battleStart")
          pbBGMPlay(battleStart["bgm"])
          pbDisplayPaused(_INTL(battleStart["text"],@opponent[0].fullname))
        when 2
          battleStart= TrainerDialogue.get("battleStart")
          battleStart.call(self)
        end
      when 2
        case TrainerDialogue.eval("battleStart")
        when -1
          pbDisplayPaused(_INTL("You are challenged by {1} and {2}!",@opponent[0].fullname,@opponent[1].fullname))
        when 0
          battleStart= TrainerDialogue.get("battleStart")
          pbDisplayPaused(_INTL(battleStart,@opponent[0].fullname,@opponent[1].fullname))
        when 1
          battleStart= TrainerDialogue.get("battleStart")
          pbBGMPlay(battleStart["bgm"])
          pbDisplayPaused(_INTL(battleStart["text"],@opponent[0].fullname,@opponent[1].fullname))
        when 2
          battleStart= TrainerDialogue.get("battleStart")
          battleStart.call(self)
        end
      when 3
        case TrainerDialogue.eval("battleStart")
        when -1
          pbDisplayPaused(_INTL("You are challenged by {1}, {2} and {3}!",
           @opponent[0].fullname,@opponent[1].fullname,@opponent[2].fullname))
        when 0
          battleStart= TrainerDialogue.get("battleStart")
          pbDisplayPaused(_INTL(battleStart,@opponent[0].fullname,@opponent[1].fullname,@opponent[2].fullname))
        when 1
          battleStart= TrainerDialogue.get("battleStart")
          pbBGMPlay(battleStart["bgm"])
          pbDisplayPaused(_INTL(battleStart,@opponent[0].fullname,@opponent[1].fullname,@opponent[2].fullname))
        when 2
          battleStart= TrainerDialogue.get("battleStart")
          battleStart.call(self)
        end
      end
    end
    # Send out Pokémon (opposing trainers first)
    for side in [1,0]
      next if side==1 && wildBattle?
      msg = ""
      toSendOut = []
      trainers = (side==0) ? @player : @opponent
      # Opposing trainers and partner trainers's messages about sending out Pokémon
      trainers.each_with_index do |t,i|
        next if side==0 && i==0   # The player's message is shown last
        msg += "\r\n" if msg.length>0
        sent = sendOuts[side][i]
        case sent.length
        when 1
          msg += _INTL("{1} sent out {2}!",t.fullname,@battlers[sent[0]].name)
        when 2
          msg += _INTL("{1} sent out {2} and {3}!",t.fullname,
             @battlers[sent[0]].name,@battlers[sent[1]].name)
        when 3
          msg += _INTL("{1} sent out {2}, {3} and {4}!",t.fullname,
             @battlers[sent[0]].name,@battlers[sent[1]].name,@battlers[sent[2]].name)
        end
        toSendOut.concat(sent)
      end
      # The player's message about sending out Pokémon
      if side==0
        msg += "\r\n" if msg.length>0
        sent = sendOuts[side][0]
        case sent.length
        when 1
#          msg += _INTL("Go! {1}!",@battlers[sent[0]].name)
		# new - friendship message sending out solo pokemon
			if @battlers[sent[0]].happiness >= 200
				msg += _INTL("Go on, {1}, I know you can do it!",@battlers[sent[0]].name)
			else
				msg += _INTL("Go! {1}!",@battlers[sent[0]].name)
			end
        when 2
          msg += _INTL("Go! {1} and {2}!",@battlers[sent[0]].name,@battlers[sent[1]].name)
        when 3
          msg += _INTL("Go! {1}, {2} and {3}!",@battlers[sent[0]].name,
             @battlers[sent[1]].name,@battlers[sent[2]].name)
        end
        toSendOut.concat(sent)
      end
      pbDisplayBrief(msg) if msg.length>0
      # The actual sending out of Pokémon
      animSendOuts = []
      toSendOut.each do |idxBattler|
        animSendOuts.push([idxBattler,@battlers[idxBattler].pokemon])
      end
      pbSendOut(animSendOuts,true)
    end
  end
# Item Usage Dialogue
  def pbUseItemOnPokemon(item,idxParty,userBattler)
    trainerName = pbGetOwnerName(userBattler.index)
    pbUseItemMessage(item,trainerName)
    pkmn = pbParty(userBattler.index)[idxParty]
    battler = pbFindBattler(idxParty,userBattler.index)
    ch = @choices[userBattler.index]
    if ItemHandlers.triggerCanUseInBattle(item,pkmn,battler,ch[3],true,self,@scene,false)
      ItemHandlers.triggerBattleUseOnPokemon(item,pkmn,battler,ch,@scene)
      ch[1] = 0   # Delete item from choice
      if (battler && battler.opposes?) || userBattler.index == 0
        TrainerDialogue.display("item",self,@scene)
      else
        TrainerDialogue.display("itemOpp",self,@scene)
      end
      return
    end
    pbDisplay(_INTL("But it had no effect!"))
    # Return unused item to Bag
    pbReturnUnusedItemToBag(item,userBattler.index)
  end
# Item Usage Dialogue
  def pbUseItemOnBattler(item,idxBattler,userBattler)
    trainerName = pbGetOwnerName(userBattler.index)
    pbUseItemMessage(item,trainerName)
    idxBattler = userBattler.index if idxBattler<0
    battler = @battlers[idxBattler]
    ch = @choices[userBattler.index]
    if ItemHandlers.triggerCanUseInBattle(item,battler.pokemon,battler,ch[3],true,self,@scene,false)
      ItemHandlers.triggerBattleUseOnBattler(item,battler,@scene)
      ch[1] = 0
      if !battler.opposes?
        TrainerDialogue.display("item",self,@scene)
      else
        TrainerDialogue.display("itemOpp",self,@scene)
      end# Delete item from choice
      return
    end
    pbDisplay(_INTL("But it's not where this item can be used!"))
    # Return unused item to Bag
    pbReturnUnusedItemToBag(item,userBattler.index)
  end
# Item Usage Dialogue
  def pbUseItemInBattle(item,idxBattler,userBattler)
    trainerName = pbGetOwnerName(userBattler.index)
    pbUseItemMessage(item,trainerName)
    battler = (idxBattler<0) ? userBattler : @battlers[idxBattler]
    pkmn = battler.pokemon
    ch = @choices[userBattler.index]
    if ItemHandlers.triggerCanUseInBattle(item,pkmn,battler,ch[3],true,self,@scene,false)
      ItemHandlers.triggerUseInBattle(item,battler,self)
      if !battler.opposes?
        TrainerDialogue.display("item",self,@scene)
      else
        TrainerDialogue.display("itemOpp",self,@scene)
      end
      ch[1] = 0   # Delete item from choice
      return
    end
    pbDisplay(_INTL("But it had no effect!"))
    # Return unused item to Bag
    pbReturnUnusedItemToBag(item,userBattler.index)
  end
# Mega Evolution Dialogue
  def pbMegaEvolve(idxBattler)
    battler = @battlers[idxBattler]
    return if !battler || !battler.pokemon
    return if !battler.hasMega? || battler.mega?
    trainerName = pbGetOwnerName(idxBattler)
    # Break Illusion
    if battler.hasActiveAbility?(:ILLUSION)
      BattleHandlers.triggerTargetAbilityOnHit(battler.ability,nil,battler,nil,self)
    end
    if !battler.opposes?
      TrainerDialogue.display("mega",self,@scene)
    else
      TrainerDialogue.display("megaOpp",self,@scene)
    end
    # Mega Evolve
    case battler.pokemon.megaMessage
    when 1   # Rayquaza
      pbDisplay(_INTL("{1}'s fervent wish has reached {2}!",trainerName,battler.pbThis))
    else
      pbDisplay(_INTL("{1}'s {2} is reacting to {3}'s {4}!",
         battler.pbThis,battler.itemName,trainerName,pbGetMegaRingName(idxBattler)))
    end
    pbCommonAnimation("MegaEvolution",battler)
    battler.pokemon.makeMega
    battler.form = battler.pokemon.form
    battler.pbUpdate(true)
    @scene.pbChangePokemon(battler,battler.pokemon)
    @scene.pbRefreshOne(idxBattler)
    pbCommonAnimation("MegaEvolution2",battler)
    megaName = battler.pokemon.megaName
    if !megaName || megaName==""
      megaName = _INTL("Mega {1}",PBSpecies.getName(battler.pokemon.species))
    end
    pbDisplay(_INTL("{1} has Mega Evolved into {2}!",battler.pbThis,megaName))
    side  = battler.idxOwnSide
    owner = pbGetOwnerIndexFromBattlerIndex(idxBattler)
    @megaEvolution[side][owner] = -2
    if battler.isSpecies?(:GENGAR) && battler.mega?
      battler.effects[PBEffects::Telekinesis] = 0
    end
    pbCalculatePriority(false,[idxBattler]) if NEWEST_BATTLE_MECHANICS
    # Trigger ability
    battler.pbEffectsOnSwitchIn
  end
# Switch in Dialogue
  def pbPartyScreen(idxBattler,checkLaxOnly=false,canCancel=false,shouldRegister=false)
    ret = -1
    @scene.pbPartyScreen(idxBattler,canCancel) { |idxParty,partyScene|
      if checkLaxOnly
        next false if !pbCanSwitchLax?(idxBattler,idxParty,partyScene)
      else
        next false if !pbCanSwitch?(idxBattler,idxParty,partyScene)
      end
      if shouldRegister
        next false if idxParty<0 || !pbRegisterSwitch(idxBattler,idxParty)
      end
      ret = idxParty
      next true
    }
    if ret != -1 && !$ShiftSwitch
      if !@battlers[idxBattler].opposes?
        TrainerDialogue.display("recall",self,@scene)
      else
        TrainerDialogue.display("recallOpp",self,@scene)
      end
    end
    $ShiftSwitch=false
    return ret
  end

# Switch in Dialogue Fix
  def pbEORSwitch(favorDraws=false)
    return if @decision>0 && !favorDraws
    return if @decision==5 && favorDraws
    pbJudge
    return if @decision>0
    # Check through each fainted battler to see if that spot can be filled.
    switched = []
    loop do
      switched.clear
      @battlers.each do |b|
        next if !b || !b.fainted?
        idxBattler = b.index
        next if !pbCanChooseNonActive?(idxBattler)
        if !pbOwnedByPlayer?(idxBattler)   # Opponent/ally is switching in
          next if wildBattle? && opposes?(idxBattler)   # Wild Pokémon can't switch
          idxPartyNew = pbSwitchInBetween(idxBattler)
          opponent = pbGetOwnerFromBattlerIndex(idxBattler)
          # NOTE: The player is only offered the chance to switch their own
          #       Pokémon when an opponent replaces a fainted Pokémon in single
          #       battles. In double battles, etc. there is no such offer.
          if @internalBattle && @switchStyle && trainerBattle? && pbSideSize(0)==1 &&
             opposes?(idxBattler) && !@battlers[0].fainted? && pbCanChooseNonActive?(0) &&
             @battlers[0].effects[PBEffects::Outrage]==0
            idxPartyForName = idxPartyNew
            enemyParty = pbParty(idxBattler)
            if isConst?(enemyParty[idxPartyNew].ability,PBAbilities,:ILLUSION)
              idxPartyForName = pbGetLastPokeInTeam(idxBattler)
            end
            if pbDisplayConfirm(_INTL("{1} is about to send in {2}. Will you switch your Pokémon?",
               opponent.fullname,enemyParty[idxPartyForName].name))
               $ShiftSwitch=false
              idxPlayerPartyNew = pbSwitchInBetween(0,false,true)
              if idxPlayerPartyNew>=0
                pbMessageOnRecall(@battlers[0])
                pbRecallAndReplace(0,idxPlayerPartyNew)
                switched.push(0)
              end
            end
          end
          pbRecallAndReplace(idxBattler,idxPartyNew)
          switched.push(idxBattler)
        elsif trainerBattle?   # Player switches in in a trainer battle
          $ShiftSwitch=true
          idxPlayerPartyNew = pbGetReplacementPokemonIndex(idxBattler)   # Owner chooses
          pbRecallAndReplace(idxBattler,idxPlayerPartyNew)
          switched.push(idxBattler)
        else   # Player's Pokémon has fainted in a wild battle
          switch = false
          if !pbDisplayConfirm(_INTL("Use next Pokémon?"))
            switch = (pbRun(idxBattler,true)<=0)
          else
            switch = true
          end
          if switch
            $ShiftSwitch=true
            idxPlayerPartyNew = pbGetReplacementPokemonIndex(idxBattler)   # Owner chooses
            pbRecallAndReplace(idxBattler,idxPlayerPartyNew)
            switched.push(idxBattler)
          end
        end
      end
      break if switched.length==0
      pbPriority(true).each do |b|
        b.pbEffectsOnSwitchIn(true) if switched.include?(b.index)
      end
      $ShiftSwitch=false
    end
  end
# Loss and Win Dialogue
  def pbEndOfBattle
    oldDecision = @decision
    @decision = 4 if @decision==1 && wildBattle? && @caughtPokemon.length>0
    case oldDecision
    ##### WIN #####
    when 1
      PBDebug.log("")
      PBDebug.log("***Player won***")
      if trainerBattle?
        @scene.pbTrainerBattleSuccess
        case @opponent.length
        when 1
          pbDisplayPaused(_INTL("You defeated {1}!",@opponent[0].fullname))
        when 2
          pbDisplayPaused(_INTL("You defeated {1} and {2}!",@opponent[0].fullname,
             @opponent[1].fullname))
        when 3
          pbDisplayPaused(_INTL("You defeated {1}, {2} and {3}!",@opponent[0].fullname,
             @opponent[1].fullname,@opponent[2].fullname))
        end
        ret = TrainerDialogue.eval("endspeech")
        if ret == -1
          @opponent.each_with_index do |_t,i|
            @scene.pbShowOpponent(i)
            msg = (@endSpeeches[i] && @endSpeeches[i]!="") ? @endSpeeches[i] : "..."
            pbDisplayPaused(msg.gsub(/\\[Pp][Nn]/,pbPlayer.name))
          end
        else
          TrainerDialogue.display("endspeech",self,@scene)
        end
      end
      # Gain money from winning a trainer battle, and from Pay Day
      pbGainMoney if @decision!=4
      # Hide remaining trainer
      @scene.pbShowOpponent(@opponent.length) if trainerBattle? && @caughtPokemon.length>0
    ##### LOSE, DRAW #####
    when 2, 5
      PBDebug.log("")
      PBDebug.log("***Player lost***") if @decision==2
      PBDebug.log("***Player drew with opponent***") if @decision==5
      if @internalBattle
        pbDisplayPaused(_INTL("You have no more Pokémon that can fight!"))
        if trainerBattle?
          case @opponent.length
          when 1
            pbDisplayPaused(_INTL("You lost against {1}!",@opponent[0].fullname))
          when 2
            pbDisplayPaused(_INTL("You lost against {1} and {2}!",
               @opponent[0].fullname,@opponent[1].fullname))
          when 3
            pbDisplayPaused(_INTL("You lost against {1}, {2} and {3}!",
               @opponent[0].fullname,@opponent[1].fullname,@opponent[2].fullname))
          end
        end
        # Lose money from losing a battle
        pbLoseMoney
        pbDisplayPaused(_INTL("You blacked out!")) if !@canLose
      elsif @decision==2
        if @opponent
          ret = TrainerDialogue.eval("loss")
          if ret == -1
            @opponent.each_with_index do |_t,i|
              @scene.pbShowOpponent(i)
              msg = (@endSpeechesWin[i] && @endSpeechesWin[i]!="") ? @endSpeechesWin[i] : "..."
              pbDisplayPaused(msg.gsub(/\\[Pp][Nn]/,pbPlayer.name))
            end
          else
            TrainerDialogue.display("loss",self,@scene)
          end
        end
      end
    ##### CAUGHT WILD POKÉMON #####
    when 4
      @scene.pbWildBattleSuccess if !GAIN_EXP_FOR_CAPTURE
    end
    # Register captured Pokémon in the Pokédex, and store them
    pbRecordAndStoreCaughtPokemon
    # Collect Pay Day money in a wild battle that ended in a capture
    pbGainMoney if @decision==4
    # Pass on Pokérus within the party
    if @internalBattle
      infected = []
      $Trainer.party.each_with_index do |pkmn,i|
        infected.push(i) if pkmn.pokerusStage==1
      end
      infected.each do |idxParty|
        strain = $Trainer.party[idxParty].pokerusStrain
        if idxParty>0 && $Trainer.party[idxParty-1].pokerusStage==0
          $Trainer.party[idxParty-1].givePokerus(strain) if rand(3)==0   # 33%
        end
        if idxParty<$Trainer.party.length-1 && $Trainer.party[idxParty+1].pokerusStage==0
          $Trainer.party[idxParty+1].givePokerus(strain) if rand(3)==0   # 33%
        end
      end
    end
    # Clean up battle stuff
    @scene.pbEndBattle(@decision)
    @battlers.each do |b|
      next if !b
      pbCancelChoice(b.index)   # Restore unused items to Bag
      BattleHandlers.triggerAbilityOnSwitchOut(b.ability,b,true) if b.abilityActive?
    end
    pbParty(0).each_with_index do |pkmn,i|
      next if !pkmn
      @peer.pbOnLeavingBattle(self,pkmn,@usedInBattle[0][i],true)   # Reset form
      pkmn.setItem(@initialItems[0][i] || 0)
    end
    return @decision
  end
end

class PokeBattle_Battler
# Faint Dialogue
  def pbFaint(showMessage=true)
    if !fainted?
      PBDebug.log("!!!***Can't faint with HP greater than 0")
      return
    end
    return if @fainted   # Has already fainted properly
    @battle.pbDisplayBrief(_INTL("{1} fainted!",pbThis)) if showMessage
    PBDebug.log("[Pokémon fainted] #{pbThis} (#{@index})") if !showMessage
    @battle.scene.pbFaintBattler(self)
    pbInitEffects(false)
    # Reset status
    self.status      = PBStatuses::NONE
    self.statusCount = 0
    # Lose happiness
    if @pokemon && @battle.internalBattle
      badLoss = false
      @battle.eachOtherSideBattler(@index) do |b|
        badLoss = true if b.level>=self.level+30
      end
      @pokemon.changeHappiness((badLoss) ? "faintbad" : "faint")
    end
    # Reset form
    @battle.peer.pbOnLeavingBattle(@battle,@pokemon,@battle.usedInBattle[idxOwnSide][@index/2])
    @pokemon.makeUnmega if mega?
    @pokemon.makeUnprimal if primal?
    # Do other things
    @battle.pbClearChoice(@index)   # Reset choice
    pbOwnSide.effects[PBEffects::LastRoundFainted] = @battle.turnCount
    # Check other battlers' abilities that trigger upon a battler fainting
    pbAbilitiesOnFainting
    # Check for end of primordial weather
    @battle.pbEndPrimordialWeather
    if !opposes?
      TrainerDialogue.display("fainted",@battle,@battle.scene)
    else
      TrainerDialogue.display("faintedOpp",@battle,@battle.scene)
    end
  end
# HP Reduction Dialogue
  def pbReduceHP(amt,anim=true,registerDamage=true,anyAnim=true)
    amt = amt.round
    amt = @hp if amt>@hp
    amt = 1 if amt<1 && !fainted?
    oldHP = @hp
    self.hp -= amt
    PBDebug.log("[HP change] #{pbThis} lost #{amt} HP (#{oldHP}=>#{@hp})") if amt>0
    raise _INTL("HP less than 0") if @hp<0
    raise _INTL("HP greater than total HP") if @hp>@totalhp
    @battle.scene.pbHPChanged(self,oldHP,anim) if anyAnim && amt>0
    @tookDamage = true if amt>0 && registerDamage
    if self.hp < (self.totalhp*0.25).floor && !self.damageState.lowHP && self.hp>0
      self.damageState.lowHP = true
      self.damageState.halfHP = true
      if !opposes?
        TrainerDialogue.display("lowHP",@battle,@battle.scene)
      else
        TrainerDialogue.display("lowHPOpp",@battle,@battle.scene)
      end
    elsif self.hp < (self.totalhp*0.5).floor && self.hp > (self.totalhp*0.25).floor && !self.damageState.halfHP
      self.damageState.halfHP = true
      if !opposes?
        TrainerDialogue.display("halfHP",@battle,@battle.scene)
      else
        TrainerDialogue.display("halfHPOpp",@battle,@battle.scene)
      end
    end
    return amt
  end
=begin
  def pbRaiseStatStageBasic(stat,increment,ignoreContrary=false)
    if !@battle.moldBreaker
      # Contrary
      if hasActiveAbility?(:CONTRARY) && !ignoreContrary
        return pbLowerStatStageBasic(stat,increment,true)
      end
      # Simple
      increment *= 2 if hasActiveAbility?(:SIMPLE)
    end
    # Change the stat stage
    increment = [increment,6-@stages[stat]].min
    if increment>0
      s = PBStats.getName(stat); new = @stages[stat]+increment
      PBDebug.log("[Stat change] #{pbThis}'s #{s}: #{@stages[stat]} -> #{new} (+#{increment})")
      @stages[stat] += increment
    end
    if !opposes?
      TrainerDialogue.display("raiseStat",@battle,@battle.scene)
    else
      TrainerDialogue.display("raiseStatOpp",@battle,@battle.scene)
    end
    return increment
  end

  def pbLowerStatStageBasic(stat,increment,ignoreContrary=false)
    if !@battle.moldBreaker
      # Contrary
      if hasActiveAbility?(:CONTRARY) && !ignoreContrary
        return pbRaiseStatStageBasic(stat,increment,true)
      end
      # Simple
      increment *= 2 if hasActiveAbility?(:SIMPLE)
    end
    # Change the stat stage
    increment = [increment,6+@stages[stat]].min
    if increment>0
      s = PBStats.getName(stat); new = @stages[stat]-increment
      PBDebug.log("[Stat change] #{pbThis}'s #{s}: #{@stages[stat]} -> #{new} (-#{increment})")
      @stages[stat] -= increment
    end
    if !opposes?
      TrainerDialogue.display("lowerStat",@battle,@battle.scene)
    else
      TrainerDialogue.display("lowerStatOpp",@battle,@battle.scene)
    end
    return increment
  end
=end
end

class PokeBattle_Move
# Attack Dialogue
  def pbDisplayUseMessage(user)
    if !user.damageState.firstAttack
      user.damageState.firstAttack = true
      if !user.opposes?
        TrainerDialogue.display("attack",@battle,@battle.scene)
      else
        TrainerDialogue.display("attackOpp",@battle,@battle.scene)
      end
    end
    @battle.pbDisplayBrief(_INTL("{1} used {2}!",user.pbThis,@name))
  end
# Super Effective Dialogue
  def pbEffectivenessMessage(user,target,numTargets=1)
    return if target.damageState.disguise
    if PBTypes.superEffective?(target.damageState.typeMod)
      if numTargets>1
        @battle.pbDisplay(_INTL("It's super effective on {1}!",target.pbThis(true)))
      else
        @battle.pbDisplay(_INTL("It's super effective!"))
      end
      target.damageState.superEff = 1 if target.damageState.superEff==0
    elsif PBTypes.notVeryEffective?(target.damageState.typeMod)
      if numTargets>1
        @battle.pbDisplay(_INTL("It's not very effective on {1}...",target.pbThis(true)))
      else
        @battle.pbDisplay(_INTL("It's not very effective..."))
      end
      target.damageState.notEff = 1 if target.damageState.notEff==0
    end
    if target.damageState.superEff == 1
      if !target.opposes?
        TrainerDialogue.display("superEff",@battle,@battle.scene)
      else
        TrainerDialogue.display("superEffOpp",@battle,@battle.scene)
      end
      target.damageState.superEff = 2
    elsif target.damageState.notEff == 1
      if !target.opposes?
        TrainerDialogue.display("notEff",@battle,@battle.scene)
      else
        TrainerDialogue.display("notEffOpp",@battle,@battle.scene)
      end
      target.damageState.notEff = 2
    end
  end
# Setting Damage Data
  def pbReduceDamage(user,target)
    damage = target.damageState.calcDamage
    # Substitute takes the damage
    if target.damageState.substitute
      damage = target.effects[PBEffects::Substitute] if damage>target.effects[PBEffects::Substitute]
      target.damageState.hpLost       = damage
      target.damageState.totalHPLost += damage
      return
    end
    # Disguise takes the damage
    return if target.damageState.disguise
    # Target takes the damage
    if damage>=target.hp
      damage = target.hp
      # Survive a lethal hit with 1 HP effects
      if nonLethal?(user,target)
        damage -= 1
	# friendship lets them hang on with 1 hp, can happen multiple times, but can't be asleep
	  elsif target.happiness >= 200 && target.status!=PBStatuses::SLEEP && @battle.pbRandom(100)<10
		  target.damageState.friendshipEndured = true
		  damage -= 1
      elsif target.effects[PBEffects::Endure]
        target.damageState.endured = true
        damage -= 1
      elsif damage==target.totalhp
        if target.hasActiveAbility?(:STURDY) && !@battle.moldBreaker
          target.damageState.sturdy = true
          damage -= 1
        elsif target.hasActiveItem?(:FOCUSSASH) && target.hp==target.totalhp
          target.damageState.focusSash = true
          damage -= 1
        elsif target.hasActiveItem?(:FOCUSBAND) && @battle.pbRandom(100)<10
          target.damageState.focusBand = true
          damage -= 1
        end
      end
    end
    damage = 0 if damage<0
    if damage > (target.totalhp*0.6).floor &&  damage != target.hp
      target.damageState.bigDamage = 1
      target.damageState.smlDamage = 1
    elsif damage < (target.totalhp*0.4).floor &&  damage != target.hp
      target.damageState.smlDamage = 1
    end
    target.damageState.hpLost       = damage
    target.damageState.totalHPLost += damage
  end

# Big,Small and Low, Mid HP Dialogue Dialogue
  def pbEndureKOMessage(target)
    if target.damageState.disguise
      @battle.pbShowAbilitySplash(target)
      if PokeBattle_SceneConstants::USE_ABILITY_SPLASH
        @battle.pbDisplay(_INTL("Its disguise served it as a decoy!"))
      else
        @battle.pbDisplay(_INTL("{1}'s disguise served it as a decoy!",target.pbThis))
      end
      @battle.pbHideAbilitySplash(target)
      target.pbChangeForm(1,_INTL("{1}'s disguise was busted!",target.pbThis))
    elsif target.damageState.endured
      @battle.pbDisplay(_INTL("{1} endured the hit!",target.pbThis))
	# friendship message
	elsif target.damageState.friendshipEndured
      @battle.pbDisplay(_INTL("{1} endured the hit to make you proud!",target.pbThis))
	#
    elsif target.damageState.sturdy
      @battle.pbShowAbilitySplash(target)
      if PokeBattle_SceneConstants::USE_ABILITY_SPLASH
        @battle.pbDisplay(_INTL("{1} endured the hit!",target.pbThis))
      else
        @battle.pbDisplay(_INTL("{1} hung on with Sturdy!",target.pbThis))
      end
      @battle.pbHideAbilitySplash(target)
    elsif target.damageState.focusSash
      @battle.pbCommonAnimation("UseItem",target)
      @battle.pbDisplay(_INTL("{1} hung on using its Focus Sash!",target.pbThis))
      target.pbConsumeItem
    elsif target.damageState.focusBand
      @battle.pbCommonAnimation("UseItem",target)
      @battle.pbDisplay(_INTL("{1} hung on using its Focus Band!",target.pbThis))
    end
    if target.damageState.bigDamage==1
      target.damageState.bigDamage = -1
      target.damageState.smlDamage = -1
      target.damageState.halfHP = true
      if !target.opposes?
        TrainerDialogue.display("bigDamage",@battle,@battle.scene)
      else
        TrainerDialogue.display("bigDamageOpp",@battle,@battle.scene)
      end
    elsif target.damageState.smlDamage==1
      if !target.opposes?
        TrainerDialogue.display("smlDamage",@battle,@battle.scene)
      else
        TrainerDialogue.display("smlDamageOpp",@battle,@battle.scene)
      end
      target.damageState.smlDamage=-1
    end
    if target.hp < (target.totalhp*0.25).floor && target.hp>0
      if !target.damageState.lowHP
        target.damageState.lowHP = true
        target.damageState.halfHP = true
        if !target.opposes?
          TrainerDialogue.display("lowHP",@battle,@battle.scene)
        else
          TrainerDialogue.display("lowHPOpp",@battle,@battle.scene)
        end
      end
    elsif target.hp < (target.totalhp*0.5).floor && target.hp>0
      if !target.damageState.halfHP
        target.damageState.halfHP = true
        if !target.opposes?
          TrainerDialogue.display("halfHP",@battle,@battle.scene)
        else
          TrainerDialogue.display("halfHPOpp",@battle,@battle.scene)
        end
      end
    end
  end
end

class PokeBattle_Scene
# Sendout Dialogue
  def pbSendOutBattlers(sendOuts,startBattle=false)
    return if sendOuts.length==0
    # If party balls are still appearing, wait for them to finish showing up, as
    # the FadeAnimation will make them disappear.
    while inPartyAnimation?; pbUpdate; end
    @briefMessage = false
    # Make all trainers and party lineups disappear (player-side trainers may
    # animate throwing a Poké Ball)
    if @battle.opposes?(sendOuts[0][0])
      fadeAnim = TrainerFadeAnimation.new(@sprites,@viewport,startBattle)
    else
      fadeAnim = PlayerFadeAnimation.new(@sprites,@viewport,startBattle)
    end
    # For each battler being sent out, set the battler's sprite and create two
    # animations (the Poké Ball moving and battler appearing from it, and its
    # data box appearing)
    sendOutAnims = []
    sendOuts.each_with_index do |b,i|
      pkmn = @battle.battlers[b[0]].effects[PBEffects::Illusion] || b[1]
      pbChangePokemon(b[0],pkmn)
      pbRefresh
      if @battle.opposes?(b[0])
        sendOutAnim = PokeballTrainerSendOutAnimation.new(@sprites,@viewport,
           @battle.pbGetOwnerIndexFromBattlerIndex(b[0])+1,
           @battle.battlers[b[0]],startBattle,i)
      else
        sendOutAnim = PokeballPlayerSendOutAnimation.new(@sprites,@viewport,
           @battle.pbGetOwnerIndexFromBattlerIndex(b[0])+1,
           @battle.battlers[b[0]],startBattle,i)
      end
      dataBoxAnim = DataBoxAppearAnimation.new(@sprites,@viewport,b[0])
      sendOutAnims.push([sendOutAnim,dataBoxAnim,false])
    end
    # Play all animations
    loop do
      fadeAnim.update
      sendOutAnims.each do |a|
        next if a[2]
        a[0].update
        a[1].update if a[0].animDone?
        a[2] = true if a[1].animDone?
      end
      pbUpdate
      if !inPartyAnimation?
        break if !sendOutAnims.any? { |a| !a[2] }
      end
    end
    fadeAnim.dispose
    sendOutAnims.each { |a| a[0].dispose; a[1].dispose }
    # Play shininess animations for shiny Pokémon
    sendOuts.each do |b|
      next if !@battle.showAnims || !@battle.battlers[b[0]].shiny?
      pbCommonAnimation("Shiny",@battle.battlers[b[0]])
    end
    sendOuts.each do |b|
      len =  @battle.pbAbleCount(b[0])
      len1 = (@battle.pbParty(b[0]).length > 6) ? 7 : (@battle.pbParty(b[0]).length + 1)
      len2 = len1 - len
      side=["","Opp"]
      if len2>1
        TrainerDialogue.forceSet("lowHP#{side[b[0]]},#{len2-1}")
        TrainerDialogue.forceSet("halfHP#{side[b[0]]},#{len2-1}")
        TrainerDialogue.forceSet("attack#{side[b[0]]},#{len2-1}")
        TrainerDialogue.forceSet("bigDamage#{side[b[0]]},#{len2-1}")
        TrainerDialogue.forceSet("smlDamage#{side[b[0]]},#{len2-1}")
        TrainerDialogue.forceSet("superEff#{side[b[0]]},#{len2-1}")
        TrainerDialogue.forceSet("notEff#{side[b[0]]},#{len2-1}")
      end
      next if @battle.pbAbleCount(b[0]) == 1
      TrainerDialogue.display("sendout#{len2}#{side[b[0]]}",@battle,self)
    end
    if !startBattle
      if @battle.pbAbleCount(1)==1 #&& @battle.pbParty(1).length !=
        TrainerDialogue.display("lastOpp",@battle,self)
      end
      if @battle.pbAbleCount(0)==1# && ((@battle.pbParty(0) && @battle.pbParty(0).length !=1) || ($Trainer.party.length != 1))
        TrainerDialogue.display("last",@battle,self)
      end
    end
  end
end

module TrainerDialogue

  def self.set(param,data)
 #   BossBattleData.resetAll
    $DialogueData[:DIAL]=true
    $DialogueData[param]=data
    $DialogueDone[param]=2
    parCheck=param.split(",")
    int=parCheck[1].to_i
    int=1 if !int || !int.is_a?(Numeric)
    $DialogueInstances[parCheck[0]] = 1# if !$DialogueInstances[parCheck[0]]  || ($DialogueInstances[parCheck[0]] && $DialogueInstances[parCheck[0]]<int)
  end

  def self.copy(param,toCopy)
    $DialogueData[:DIAL]=true
    $DialogueData[param]=$DialogueData[toCopy]
    $DialogueDone[param]=2
    parCheck=param.split(",")
    int=parCheck[1].to_i
    int=1 if !int || !int.is_a?(Numeric)
    $DialogueInstances[parCheck[0]] = 1# if !$DialogueInstances[parCheck[0]]  || ($DialogueInstances[parCheck[0]] && $DialogueInstances[parCheck[0]]<int)
  end

  def self.resetAll
    $DialogueData={:DIAL=>false}
    $DialogueDone={}
    $DialogueInstances={}
  end

  def self.hasData?
    return $DialogueData[:DIAL]
  end

  def self.setDone(param)
    $DialogueDone[param]=1
  end

  def self.setFinal
    for key in $DialogueDone.keys
      if $DialogueDone[key]==1
        $DialogueDone[key]=0
        $DialogueData[key]=nil
      end
    end
  end

  def self.get(param)
    return false if !self.hasData?
    return $DialogueData[param]
  end

  def self.forceSet(parameter)
    $DialogueDone[parameter]=1
    param=parameter.split(",")
    $DialogueInstances[param[0]] = (param[1].to_i + 1)
  end



  def self.eval(parameter,noPri=false)
    param=parameter
    return -1 if !self.hasData?
    return -1 if !$DialogueDone[param]
    return -1 if $DialogueDone[param] && ($DialogueDone[param]==0 || $DialogueDone[param]==1)
    if $DialogueData[param].is_a?(String)
      return 0
    end
    if $DialogueData[param].is_a?(Hash)
      return 1
    end
    if $DialogueData[param].is_a?(Proc)
      return 2
    end
    if $DialogueData[param].is_a?(Array)
      return 3
    end
  end

  def self.display(parameter,battle=nil,scene=nil,noPri=false)
    if $DialogueInstances[parameter].is_a?(Numeric) && $DialogueInstances[parameter]>1
      param="#{parameter},#{$DialogueInstances[parameter]}"
    else
      param=parameter
    end
    case TrainerDialogue.eval(param,noPri)
    when 0
      turnStart= TrainerDialogue.get(param)
      scene.pbShowOpponent(0) if !battle.wildBattle?
      scene.disappearDatabox
      scene.sprites["messageWindow"].text = ""
      Kernel.pbMessage(_INTL(turnStart))
      if !battle.wildBattle?
        for i in 1..battle.opponent.length
          scene.pbHideOpponent(i)
        end
      end
      scene.appearDatabox
      TrainerDialogue.setDone(param)
      TrainerDialogue.setInstance(parameter)
      return true
    when 1
      turnStart= TrainerDialogue.get(param)
      pbBGMPlay(turnStart["bgm"]) if turnStart["bgm"].is_a?(String)
      scene.disappearDatabox if !turnStart["bar"]
      scene.appearBar if turnStart["bar"]
      scene.sprites["messageWindow"].text = ""
      if turnStart["opp"].is_a?(Numeric) && !battle.wildBattle?
        while turnStart["opp"] >= battle.opponent.length && turnStart["opp"] >= 0
          turnStart["opp"]-=1
        end
        scene.pbShowOpponent(turnStart["opp"])
        turnStart["opp"]=0 if turnStart["opp"] < 0
        if turnStart["text"].is_a?(Array)
          for i in 0...turnStart["text"].length
            Kernel.pbMessage(_INTL(turnStart["text"][i]))
          end
        else
          Kernel.pbMessage(_INTL(turnStart["text"]))
        end
      else
        TrainerDialogue.changeTrainerSprite(turnStart["opp"],scene) if turnStart["opp"].is_a?(String)
        scene.pbShowOpponent(0) if !battle.wildBattle? || (battle.wildBattle? && turnStart["opp"].is_a?(String))
        if turnStart["text"].is_a?(Array)
          for i in 0...turnStart["text"].length
            Kernel.pbMessage(_INTL(turnStart["text"][i]))
          end
        else
          Kernel.pbMessage(_INTL(turnStart["text"]))
        end
      end
      if battle.opponent.is_a?(Array)
        for i in 1..battle.opponent.length
          scene.pbHideOpponent(battle.opponent.length) if !battle.wildBattle? || (battle.wildBattle? && turnStart["opp"].is_a?(String))
        end
      else
        scene.pbHideOpponent if !battle.wildBattle? || (battle.wildBattle? && turnStart["opp"].is_a?(String))
      end
      scene.sprites["trainer_1"].setBitmap(pbTrainerSpriteFile(battle.opponent[0].trainertype)) if !battle.wildBattle?
      scene.disappearBar if turnStart["bar"]
      scene.appearDatabox if !turnStart["bar"]
      TrainerDialogue.setDone(param)
      TrainerDialogue.setInstance(parameter)
      return true
    when 2
      turnStart= TrainerDialogue.get(param)
      scene.sprites["messageWindow"].text = ""
      turnStart.call(battle)
      TrainerDialogue.setDone(param)
      TrainerDialogue.setInstance(parameter)
      return true
    when 3
      turnStart= TrainerDialogue.get(param)
      scene.pbShowOpponent(0) if !battle.wildBattle?
      scene.disappearDatabox
      scene.sprites["messageWindow"].text = ""
      for i in 0...turnStart.length
        Kernel.pbMessage(_INTL(turnStart[i]))
      end
      if !battle.wildBattle?
        for i in 1..battle.opponent.length
          scene.pbHideOpponent(i)
        end
      end
      scene.appearDatabox
      TrainerDialogue.setDone(param)
      TrainerDialogue.setInstance(parameter)
      return true
    end
    return false
  end

  def self.changeTrainerSprite(name,scene,delay=2)
    if name.is_a?(String)
      scene.sprites["trainer_1"].setBitmap("Graphics/Trainers/#{name}")
    elsif name.is_a?(Array)
      for i in 0...name.length
        Graphics.update
        pbWait(delay-1)
        scene.sprites["trainer_1"].setBitmap("Graphics/Trainers/#{name[i]}")
      end
    end
  end

  def self.setInstance(parameter)
    $DialogueInstances[parameter] += 1 if !["lowHP","lowHPOpp","halfHP","halfHPOpp",
        	                                 "bigDamage","bigDamageOpp","smlDamage",
                                           "smlDamageOpp","attack","attackOpp",
                                           "superEff","superEffOpp","notEff","notEffOpp"].include?(parameter)
  end
end


class PokeBattle_Scene
  def pbInitSprites
    @sprites = {}
    # The background image and each side's base graphic
    pbCreateBackdropSprites
    # Create message box graphic
    messageBox = pbAddSprite("messageBox",0,Graphics.height-96,
       "Graphics/Pictures/Battle/overlay_message",@viewport)
    messageBox.z = 195
    # Create message window (displays the message)
    msgWindow = Window_AdvancedTextPokemon.newWithSize("",
       16,Graphics.height-96+2,Graphics.width-32,96,@viewport)
    msgWindow.z              = 200
    msgWindow.opacity        = 0
    msgWindow.baseColor      = PokeBattle_SceneConstants::MESSAGE_BASE_COLOR
    msgWindow.shadowColor    = PokeBattle_SceneConstants::MESSAGE_SHADOW_COLOR
    msgWindow.letterbyletter = true
    @sprites["messageWindow"] = msgWindow
    # Create command window
    @sprites["commandWindow"] = CommandMenuDisplay.new(@viewport,200)
    # Create fight window
    @sprites["fightWindow"] = FightMenuDisplay.new(@viewport,200)
    # Create targeting window
    @sprites["targetWindow"] = TargetMenuDisplay.new(@viewport,200,@battle.sideSizes)
    pbShowWindow(MESSAGE_BOX)
    # The party lineup graphics (bar and balls) for both sides
    for side in 0...2
      partyBar = pbAddSprite("partyBar_#{side}",0,0,
         "Graphics/Pictures/Battle/overlay_lineup",@viewport)
      partyBar.z       = 120
      partyBar.mirror  = true if side==0   # Player's lineup bar only
      partyBar.visible = false
      for i in 0...PokeBattle_SceneConstants::NUM_BALLS
        ball = pbAddSprite("partyBall_#{side}_#{i}",0,0,nil,@viewport)
        ball.z       = 121
        ball.visible = false
      end
      # Ability splash bars
      if PokeBattle_SceneConstants::USE_ABILITY_SPLASH
        @sprites["abilityBar_#{side}"] = AbilitySplashBar.new(side,@viewport)
      end
    end
    # Player's and partner trainer's back sprite
    @battle.player.each_with_index do |p,i|
      pbCreateTrainerBackSprite(i,p.trainertype,@battle.player.length)
    end
    # Opposing trainer(s) sprites
    if @battle.trainerBattle?
      @battle.opponent.each_with_index do |p,i|
        pbCreateTrainerFrontSprite(i,p.trainertype,@battle.opponent.length)
      end
    else
      trainerfile = "Graphics/Trainers/trainer000"
      spriteX, spriteY = PokeBattle_SceneConstants.pbTrainerPosition(1,1,1)
      trainer = pbAddSprite("trainer_1",spriteX,spriteY,trainerfile,@viewport)
      trainer.visible=false
      return if !trainer.bitmap
      # Alter position of sprite
      trainer.z  = 7
      trainer.ox = trainer.src_rect.width/2
      trainer.oy = trainer.bitmap.height
    end
    # Data boxes and Pokémon sprites
    @battle.battlers.each_with_index do |b,i|
      next if !b
      @sprites["dataBox_#{i}"] = PokemonDataBox.new(b,@battle.pbSideSize(i),@viewport)
      pbCreatePokemonSprite(i)
    end
    # Wild battle, so set up the Pokémon sprite(s) accordingly
    if @battle.wildBattle?
      @battle.pbParty(1).each_with_index do |pkmn,i|
        index = i*2+1
        pbChangePokemon(index,pkmn)
        pkmnSprite = @sprites["pokemon_#{index}"]
        pkmnSprite.tone    = Tone.new(-80,-80,-80)
        pkmnSprite.visible = true
      end
    end
  end

  def pbHideOpponent(idxTrainer=1,filename=nil)
    # Set up trainer appearing animation
    disappearAnim = TrainerDisappearAnimation.new(@sprites,@viewport,idxTrainer,filename)
    @animations.push(disappearAnim)
    # Play the animation
    while inPartyAnimation?; pbUpdate; end
  end

  def disappearDatabox
    unfadeAnim = DataboxFadeAnimation.new(@sprites,@viewport,@battle.battlers.length)
    @animations.push(unfadeAnim)
    loop do
      unfadeAnim.update
      pbUpdate
      break if unfadeAnim.animDone?
    end
    unfadeAnim.dispose
  end

  def appearDatabox
    unfadeAnim = DataboxUnfadeAnimation.new(@sprites,@viewport,@battle.battlers.length)
    @animations.push(unfadeAnim)
    loop do
      unfadeAnim.update
      pbUpdate
      break if unfadeAnim.animDone?
    end
    unfadeAnim.dispose
  end

  def appearBar
    pbAddSprite("topBar",512,0,"Graphics/Battle animations/blackbar_top",@viewport) if !@sprites["topBar"]
    pbAddSprite("bottomBar",0,384,"Graphics/Battle animations/blackbar_bottom",@viewport) if !@sprites["bottomBar"]
    unfadeAnim = BlackBarAppearAnimation.new(@sprites,@viewport,@battle.battlers.length)
    @animations.push(unfadeAnim)
    loop do
      unfadeAnim.update
      pbUpdate
      break if unfadeAnim.animDone?
    end
    unfadeAnim.dispose
  end

  def disappearBar
    unfadeAnim = BlackBarDisappearAnimation.new(@sprites,@viewport,@battle.battlers.length)
    @animations.push(unfadeAnim)
    loop do
      unfadeAnim.update
      pbUpdate
      break if unfadeAnim.animDone?
    end
    unfadeAnim.dispose
  end
end

class TrainerDisappearAnimation < PokeBattle_Animation
  def initialize(sprites,viewport,idxTrainer,filename)
    @idxTrainer = idxTrainer
    super(sprites,viewport)
  end

  def createProcesses
    delay = 0
    # Make old trainer sprite move off-screen first if necessary
    if @sprites["trainer_#{@idxTrainer}"].visible
      oldTrainer = addSprite(@sprites["trainer_#{@idxTrainer}"],PictureOrigin::Bottom)
      oldTrainer.moveDelta(delay,8,Graphics.width/4,0)
      oldTrainer.setVisible(delay+8,false)
      delay = oldTrainer.totalDuration
    end
  end
end

class DataboxFadeAnimation < PokeBattle_Animation
  def initialize(sprites,viewport,battlers,delay=nil)
    @battlers = battlers
    @delay= delay
    super(sprites,viewport)
  end

  def createProcesses
    delay = 0
    boxes = []
    for i in 0...@battlers
      boxes[i]= addSprite(@sprites["dataBox_#{i}"])
      boxes[i].moveOpacity(delay,3,0)
    end
  end
end

class DataboxUnfadeAnimation < PokeBattle_Animation
  def initialize(sprites,viewport,battlers,delay=nil)
    @battlers = battlers
    @delay= delay
    super(sprites,viewport)
  end

  def createProcesses
    delay = (@delay.is_a?(Numeric))? @delay : 0
    boxes = []
    for i in 0...@battlers
      boxes[i]= addSprite(@sprites["dataBox_#{i}"])
      boxes[i].setOpacity(delay,0)
      boxes[i].moveOpacity(delay,3,255)
    end
  end
end

class BlackBarAppearAnimation < PokeBattle_Animation
  def initialize(sprites,viewport,battlers)
    @battlers = battlers
    super(sprites,viewport)
  end

  def createProcesses
    delay = 10
    boxes = []
    topBar = addSprite(@sprites["topBar"],PictureOrigin::TopLeft)
    topBar.setZ(0,200)
    bottomBar = addSprite(@sprites["bottomBar"],PictureOrigin::BottomRight)
    bottomBar.setZ(0,200)
    topBar.setOpacity(0,255)
    bottomBar.setOpacity(0,255)
    topBar.setXY(0,512,0)
    bottomBar.setXY(0,0,384)
    topBar.moveXY(delay,8,0,0)
    bottomBar.moveXY(delay,8,512,384)
    for i in 0...@battlers
      boxes[i]= addSprite(@sprites["dataBox_#{i}"])
      boxes[i].moveOpacity(delay,3,0)
    end
  end
end

class BlackBarDisappearAnimation < PokeBattle_Animation
  def initialize(sprites,viewport,battlers)
    @battlers = battlers
    super(sprites,viewport)
  end

  def createProcesses
    delay = 10
    boxes = []
    topBar = addSprite(@sprites["topBar"],PictureOrigin::TopLeft)
    topBar.setZ(0,200)
    bottomBar = addSprite(@sprites["bottomBar"],PictureOrigin::BottomRight)
    bottomBar.setZ(0,200)
    topBar.moveOpacity(delay,8,0)
    bottomBar.moveOpacity(delay,8,0)
    for i in 0...@battlers
      boxes[i]= addSprite(@sprites["dataBox_#{i}"])
      boxes[i].setOpacity(0,0)
      boxes[i].moveOpacity(delay,5,255)
    end
    topBar.setXY(delay+5,512,0)
    bottomBar.setXY(delay+5,0,384)
  end
end


$DialogueData={:DIAL=>false}
$DialogueDone={}
$DialogueInstances={}

$ShiftSwitch=false

PluginManager.register({
  :name => "Mid Battle Dialogue",
  :version => "1.0",
  :credits => "Golisopod User, Luka SJ"
})
