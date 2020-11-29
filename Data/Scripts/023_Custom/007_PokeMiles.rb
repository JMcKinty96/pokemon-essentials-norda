#===============================================================================
# By Screedle.
# Creates a method of tracking how many steps the player has taken and converts them
# to Poké Miles.
# "Poké Miles are a type of currency introduced in Pokémon X and Y. They can be earned in a variety of ways, such as by walking around the Kalos and Hoenn regions (1 Mile for every 1000 steps)." - Bulbapedia
# 
# This script requires two switches, set to 67 and 68 here
#===============================================================================
# Settings (You can edit these)
#===============================================================================
STEPS_PER_MILE 		= 100 # how many steps the player has to do to earn miles
MILES_PER_STEP 		= 1 # how many miles are given after walking the needed number of steps
MAX_MILES			= 1000000 # the max number of miles a player can hold
EARN_MILES_SWITCH 	= 67 # If this switch is ON, the player CAN'T earn miles.
# It is recommended you call this something like !CanEarnMiles?
SPEND_MILES_SWITCH 	= 68 # If this switch is ON, the player CAN'T lose miles.
# It is recommended you call this something like !CanSpendMiles?

#===============================================================================
# Methods for you to use:
#
# pbAddMiles(value,forcechange)
# pbLoseMiles(value,forcechange)
# pbSetMiles(value)
# pbGetMiles
# pbPokemonMilesMart(stock,speech=nil,cantsell=false)
#
# To create a Pokemiles Mart, you define it like a regular mart, e.g.:
# pbPokemonMilesMart([
# :POKEBALL,
# :POTION
# ])
#
# In a Pokemiles Mart, items are sold for the same as their $ value, but in PM
# If you don't want players to be able to sell things for PokeMiles, you'll want to
# make the shop a different way, e.g. through Text Choices
# 
# Send me a message on PokeCommunity discord if you have any issues
#
#===============================================================================

PluginManager.register({
  :name => "Poké Miles",
  :version => "1.0",
  :credits => "Screedle",
  :link => "https://www.pokecommunity.com/showthread.php?p=10234924#post10234924"
})

#===============================================================================
# Adds to the trainer class
#===============================================================================
class PokeBattle_Trainer
	attr_accessor :miles
	
	def miles=(value)
		@miles=[[value,MAX_MILES].min,0].max
	end
	
	def milesEarned # miles gained when trainer defeated
		# foo
		return 0
	end
	
	alias __new_initialize initialize
	def initialize(*args)
	   __new_initialize(*args)
	   # your code here
	   @miles = 0
	end
end

class PokemonGlobalMetadata
	attr_accessor :milesSteps
	
	alias __new_initialize initialize
	def initialize
	   __new_initialize
	   # your code here
	   @milesSteps	= 0
	end
end

#===============================================================================
# Gain miles when stepping
#===============================================================================
Events.onStepTaken += proc {
	$PokemonGlobal.milesSteps = 0 if !$PokemonGlobal.milesSteps
	$PokemonGlobal.milesSteps += 1
	if $PokemonGlobal.milesSteps >= STEPS_PER_MILE && $game_switches[EARN_MILES_SWITCH] != true
		$Trainer.miles += MILES_PER_STEP
		$PokemonGlobal.milesSteps = 0
	end
}

#===============================================================================
# Manually add miles
#===============================================================================
def pbGainMiles(value, forceChange=false)
	if $game_switches[EARN_MILES_SWITCH] != true || forceChange == true
		$Trainer.miles += value
	end
end

#===============================================================================
# Manually remove miles
#===============================================================================
def pbLoseMiles(value, forceChange=false)
	if $game_switches[SPEND_MILES_SWITCH] != true || forceChange == true
		$Trainer.miles -= value
	end
end

#===============================================================================
# Set Miles
#===============================================================================
def pbSetMiles(value)
	$Trainer.miles = value
end

#===============================================================================
# Get Miles
#===============================================================================
def pbGetMiles
	return $Trainer.miles
end

#===============================================================================
# Poke Miles Window
#===============================================================================
def pbGetMilesString
  milesString=""
  milesString=_INTL("{1} PM",$Trainer.miles.to_s_formatted)
  return milesString
end

$milesWindow = nil # I know I probably shouldnt use a global var for this, but hey, it works

def pbShowMiles(msgwindow = nil)
	milesString=pbGetMilesString
	
	$milesWindow=Window_AdvancedTextPokemon.new(_INTL("Poké Miles:\r\n<r>{1}",milesString))
	$milesWindow.setSkin("Graphics/Windows/goldskin")
	$milesWindow.resizeToFit($milesWindow.text,Graphics.width)
	$milesWindow.width=160 if $milesWindow.width<=160
	$milesWindow.y= 5 #Graphics.height-milesWindow.height
	$milesWindow.z= 999#msgwindow.z
	return $milesWindow	
end

def pbHideMiles
	$milesWindow.dispose if $milesWindow
	return
end

#===============================================================================
# PokeMiles Mart. A lot of this is copied/borrowed from PScreen_Mart,
# but it shouldn't override anything from there.
#===============================================================================
class PokemonMilesMartAdapter
	def getMiles
		return $Trainer.miles
	end
	
	def getMilesString
		return pbGetMilesString
	end
	
	def setMiles(value)
		pbSetMiles(value)
	end
	
	def getInventory
		return $PokemonBag
	end
	
	def getDisplayName(item)
		itemname = PBItems.getName(item)
		if pbIsMachine?(item)
			machine = pbGetMachine(item)
			itemname = _INTL("{1} {2}",itemname,PBMoves.getName(machine))
		end
    return itemname
  end
  
	def getName(item)
		return PBItems.getName(item)
	end

	def getDescription(item)
		return pbGetMessage(MessageTypes::ItemDescriptions,item)
	end

	def getItemIcon(item)
		return nil if !item
		return pbItemIconFile(item)
	end
	
	def getItemIconRect(_item)
		return Rect.new(0,0,48,48)
	end

	def getQuantity(item)
		return $PokemonBag.pbQuantity(item)
	end

	def showQuantity?(item)
		return !pbIsImportantItem?(item)
	end	
	
	def getPrice(item,selling=false)
		if $game_temp.mart_prices && $game_temp.mart_prices[item]
		  if selling
			return $game_temp.mart_prices[item][1] if $game_temp.mart_prices[item][1]>=0
		  else
			return $game_temp.mart_prices[item][0] if $game_temp.mart_prices[item][0]>0
		  end
		end
		return pbGetPrice(item)
	end

	def getDisplayPrice(item,selling=false)
		price = getPrice(item,selling).to_s_formatted
		return _INTL("{1} PM",price)
	end

	def canSell?(item)
		return (getPrice(item,true)>0 && !pbIsImportantItem?(item))
	end

	def addItem(item)
		return $PokemonBag.pbStoreItem(item)
	end

	def removeItem(item)
		return $PokemonBag.pbDeleteItem(item)
	end
end


class PokemonMilesMart_Scene
  def update
    pbUpdateSpriteHash(@sprites)
    @subscene.pbUpdate if @subscene
  end

  def pbRefreshX
    if @subscene
      @subscene.pbRefreshX
    else
      itemwindow=@sprites["itemwindow"]
      @sprites["icon"].item=itemwindow.item
      @sprites["itemtextwindow"].text=(itemwindow.item==0) ? _INTL("Quit shopping.") :
         @adapter.getDescription(itemwindow.item)
      itemwindow.refresh
    end
    @sprites["moneywindow"].text=_INTL("Poké Miles:\r\n<r>{1}",@adapter.getMilesString)
  end

  def pbStartBuyOrSellScene(buying,stock,adapter)
    # Scroll right before showing screen
    pbScrollMap(6,5,5)
    @viewport=Viewport.new(0,0,Graphics.width,Graphics.height)
    @viewport.z=99999
    @stock=stock
    @adapter=adapter
    @sprites={}
    @sprites["background"]=IconSprite.new(0,0,@viewport)
    @sprites["background"].setBitmap("Graphics/Pictures/martScreen")
    @sprites["icon"]=ItemIconSprite.new(36,Graphics.height-50,-1,@viewport)
    winAdapter=buying ? BuyAdapter.new(adapter) : SellAdapter.new(adapter)
    @sprites["itemwindow"]=Window_PokemonMart.new(stock,winAdapter,
       Graphics.width-316-16,12,330+16,Graphics.height-126)
    @sprites["itemwindow"].viewport=@viewport
    @sprites["itemwindow"].index=0
    @sprites["itemwindow"].refresh
    @sprites["itemtextwindow"]=Window_UnformattedTextPokemon.new("")
    pbPrepareWindow(@sprites["itemtextwindow"])
    @sprites["itemtextwindow"].x=64
    @sprites["itemtextwindow"].y=Graphics.height-96-16
    @sprites["itemtextwindow"].width=Graphics.width-64
    @sprites["itemtextwindow"].height=128
    @sprites["itemtextwindow"].baseColor=Color.new(248,248,248)
    @sprites["itemtextwindow"].shadowColor=Color.new(0,0,0)
    @sprites["itemtextwindow"].visible=true
    @sprites["itemtextwindow"].viewport=@viewport
    @sprites["itemtextwindow"].windowskin=nil
    @sprites["helpwindow"]=Window_AdvancedTextPokemon.new("")
    pbPrepareWindow(@sprites["helpwindow"])
    @sprites["helpwindow"].visible=false
    @sprites["helpwindow"].viewport=@viewport
    pbBottomLeftLines(@sprites["helpwindow"],1)
    @sprites["moneywindow"]=Window_AdvancedTextPokemon.new("")
    pbPrepareWindow(@sprites["moneywindow"])
    @sprites["moneywindow"].setSkin("Graphics/Windowskins/goldskin")
    @sprites["moneywindow"].visible=true
    @sprites["moneywindow"].viewport=@viewport
    @sprites["moneywindow"].x=0
    @sprites["moneywindow"].y=0
    @sprites["moneywindow"].width=190
    @sprites["moneywindow"].height=96
    @sprites["moneywindow"].baseColor=Color.new(88,88,80)
    @sprites["moneywindow"].shadowColor=Color.new(168,184,184)
    pbDeactivateWindows(@sprites)
    @buying=buying
    pbRefreshX
    Graphics.frame_reset
  end

  def pbStartBuyScenePM(stock,adapter)
    pbStartBuyOrSellScene(true,stock,adapter)
  end

  def pbStartSellScene(bag,adapter)
    if $PokemonBag
      pbStartSellScene2(bag,adapter)
    else
      pbStartBuyOrSellScene(false,bag,adapter)
    end
  end

  def pbStartSellScene2(bag,adapter)
    @subscene=PokemonBag_Scene.new
    @adapter=adapter
    @viewport2=Viewport.new(0,0,Graphics.width,Graphics.height)
    @viewport2.z=99999
    numFrames = Graphics.frame_rate*4/10
    alphaDiff = (255.0/numFrames).ceil
    for j in 0..numFrames
      col=Color.new(0,0,0,j*alphaDiff)
      @viewport2.color=col
      Graphics.update
      Input.update
    end
    @subscene.pbStartScene(bag)
    @viewport=Viewport.new(0,0,Graphics.width,Graphics.height)
    @viewport.z=99999
    @sprites={}
    @sprites["helpwindow"]=Window_AdvancedTextPokemon.new("")
    pbPrepareWindow(@sprites["helpwindow"])
    @sprites["helpwindow"].visible=false
    @sprites["helpwindow"].viewport=@viewport
    pbBottomLeftLines(@sprites["helpwindow"],1)
    @sprites["moneywindow"]=Window_AdvancedTextPokemon.new("")
    pbPrepareWindow(@sprites["moneywindow"])
    @sprites["moneywindow"].setSkin("Graphics/Windowskins/goldskin")
    @sprites["moneywindow"].visible=false
    @sprites["moneywindow"].viewport=@viewport
    @sprites["moneywindow"].x=0
    @sprites["moneywindow"].y=0
    @sprites["moneywindow"].width=186
    @sprites["moneywindow"].height=96
    @sprites["moneywindow"].baseColor=Color.new(88,88,80)
    @sprites["moneywindow"].shadowColor=Color.new(168,184,184)
    pbDeactivateWindows(@sprites)
    @buying=false
    pbRefreshX
  end

  def pbEndBuyScene
    pbDisposeSpriteHash(@sprites)
    @viewport.dispose
    # Scroll left after showing screen
    pbScrollMap(4,5,5)
  end

  def pbEndSellScene
    if @subscene
      @subscene.pbEndScene
    end
    pbDisposeSpriteHash(@sprites)
    if @viewport2
      numFrames = Graphics.frame_rate*4/10
      alphaDiff = (255.0/numFrames).ceil
      for j in 0..numFrames
        col=Color.new(0,0,0,(numFrames-j)*alphaDiff)
        @viewport2.color=col
        Graphics.update
        Input.update
      end
      @viewport2.dispose
    end
    @viewport.dispose
    if !@subscene
      pbScrollMap(4,5,5)
    end
  end

  def pbPrepareWindow(window)
    window.visible=true
    window.letterbyletter=false
  end

  def pbShowMoney
    pbRefreshX
    @sprites["moneywindow"].visible=true
  end

  def pbHideMoney
    pbRefreshX
    @sprites["moneywindow"].visible=false
  end

  def pbDisplay(msg,brief=false)
    cw=@sprites["helpwindow"]
    cw.letterbyletter=true
    cw.text=msg
    pbBottomLeftLines(cw,2)
    cw.visible=true
    i=0
    pbPlayDecisionSE()
    loop do
      Graphics.update
      Input.update
      self.update
      if !cw.busy?
        return if brief
        pbRefreshX if i==0
      end
      if Input.trigger?(Input::C) && cw.busy?
        cw.resume
      end
      return if i>=Graphics.frame_rate*3/2
      i+=1 if !cw.busy?
    end
  end

  def pbDisplayPaused(msg)
    cw=@sprites["helpwindow"]
    cw.letterbyletter=true
    cw.text=msg
    pbBottomLeftLines(cw,2)
    cw.visible=true
    yielded = false
    pbPlayDecisionSE()
    loop do
      Graphics.update
      Input.update
      wasbusy=cw.busy?
      self.update
      if !cw.busy? && !yielded
        yield if block_given?   # For playing SE as soon as the message is all shown
        yielded = true
      end
      pbRefreshX if !cw.busy? && wasbusy
      if Input.trigger?(Input::C) && cw.resume && !cw.busy?
        @sprites["helpwindow"].visible=false
        return
      end
    end
  end

  def pbConfirm(msg)
    dw=@sprites["helpwindow"]
    dw.letterbyletter=true
    dw.text=msg
    dw.visible=true
    pbBottomLeftLines(dw,2)
    commands=[_INTL("Yes"),_INTL("No")]
    cw = Window_CommandPokemon.new(commands)
    cw.viewport=@viewport
    pbBottomRight(cw)
    cw.y-=dw.height
    cw.index=0
    pbPlayDecisionSE()
    loop do
      cw.visible=!dw.busy?
      Graphics.update
      Input.update
      cw.update
      self.update
      if Input.trigger?(Input::B) && dw.resume && !dw.busy?
        cw.dispose
        @sprites["helpwindow"].visible=false
        return false
      end
      if Input.trigger?(Input::C) && dw.resume && !dw.busy?
        cw.dispose
        @sprites["helpwindow"].visible=false
        return (cw.index==0)?true:false
      end
    end
  end

  def pbChooseNumber(helptext,item,maximum)
    curnumber=1
    ret=0
    helpwindow=@sprites["helpwindow"]
    itemprice=@adapter.getPrice(item,!@buying)
    itemprice/=2 if !@buying
    pbDisplay(helptext,true)
    using(numwindow=Window_AdvancedTextPokemon.new("")) { # Showing number of items
      qty=@adapter.getQuantity(item)
      using(inbagwindow=Window_AdvancedTextPokemon.new("")) { # Showing quantity in bag
        pbPrepareWindow(numwindow)
        pbPrepareWindow(inbagwindow)
        numwindow.viewport=@viewport
        numwindow.width=224
        numwindow.height=64
        numwindow.baseColor=Color.new(88,88,80)
        numwindow.shadowColor=Color.new(168,184,184)
        inbagwindow.visible=@buying
        inbagwindow.viewport=@viewport
        inbagwindow.width=190
        inbagwindow.height=64
        inbagwindow.baseColor=Color.new(88,88,80)
        inbagwindow.shadowColor=Color.new(168,184,184)
        inbagwindow.text=_INTL("In Bag:<r>{1}  ",qty)
        numwindow.text=_INTL("x{1}<r>{2} PM",curnumber,(curnumber*itemprice).to_s_formatted)
        pbBottomRight(numwindow)
        numwindow.y-=helpwindow.height
        pbBottomLeft(inbagwindow)
        inbagwindow.y-=helpwindow.height
        loop do
          Graphics.update
          Input.update
          numwindow.update
          inbagwindow.update
          self.update
          if Input.repeat?(Input::LEFT)
            pbPlayCursorSE()
            curnumber-=10
            curnumber=1 if curnumber<1
            numwindow.text=_INTL("x{1}<r>{2} PM",curnumber,(curnumber*itemprice).to_s_formatted)
          elsif Input.repeat?(Input::RIGHT)
            pbPlayCursorSE()
            curnumber+=10
            curnumber=maximum if curnumber>maximum
            numwindow.text=_INTL("x{1}<r>{2} PM",curnumber,(curnumber*itemprice).to_s_formatted)
          elsif Input.repeat?(Input::UP)
            pbPlayCursorSE()
            curnumber+=1
            curnumber=1 if curnumber>maximum
            numwindow.text=_INTL("x{1}<r>{2} PM",curnumber,(curnumber*itemprice).to_s_formatted)
          elsif Input.repeat?(Input::DOWN)
            pbPlayCursorSE()
            curnumber-=1
            curnumber=maximum if curnumber<1
            numwindow.text=_INTL("x{1}<r>{2} PM",curnumber,(curnumber*itemprice).to_s_formatted)
          elsif Input.trigger?(Input::C)
            pbPlayDecisionSE()
            ret=curnumber
            break
          elsif Input.trigger?(Input::B)
            pbPlayCancelSE()
            ret=0
            break
          end
        end
      }
    }
    helpwindow.visible=false
    return ret
  end

  def pbChooseBuyItem
    itemwindow=@sprites["itemwindow"]
    @sprites["helpwindow"].visible=false
    pbActivateWindow(@sprites,"itemwindow") {
      pbRefreshX
      loop do
        Graphics.update
        Input.update
        olditem=itemwindow.item
        self.update
        if itemwindow.item!=olditem
          @sprites["icon"].item=itemwindow.item
          @sprites["itemtextwindow"].text=(itemwindow.item==0) ? _INTL("Quit shopping.") :
             @adapter.getDescription(itemwindow.item)
        end
        if Input.trigger?(Input::B)
          pbPlayCloseMenuSE
          return 0
        elsif Input.trigger?(Input::C)
          if itemwindow.index<@stock.length
            pbRefreshX
            return @stock[itemwindow.index]
          else
            return 0
          end
        end
      end
    }
  end

  def pbChooseSellItem
    if @subscene
      return @subscene.pbChooseItem
    else
      return pbChooseBuyItem
    end
  end
end


#######################################################

class PokemonMilesMartScreen
  def initialize(scene,stock)
    @scene=scene
    @stock=stock
    @adapter=$PokemonBag ? PokemonMilesMartAdapter.new : RpgxpMartAdapter.new
  end

  def pbConfirm(msg)
    return @scene.pbConfirm(msg)
  end

  def pbDisplay(msg)
    return @scene.pbDisplay(msg)
  end

  def pbDisplayPaused(msg,&block)
    return @scene.pbDisplayPaused(msg,&block)
  end

  def pbBuyScreenMiles
    @scene.pbStartBuyScenePM(@stock,@adapter)
    item=0
    loop do
      item=@scene.pbChooseBuyItem
      quantity=0
      break if item==0
      itemname=@adapter.getDisplayName(item)
      price=@adapter.getPrice(item)
      if @adapter.getMiles<price
        pbDisplayPaused(_INTL("You don't have enough Poké Miles."))
        next
      end
      if pbIsImportantItem?(item)
        if !pbConfirm(_INTL("Certainly. You want {1}.\nThat will be {2} PM. OK?",
           itemname,price.to_s_formatted))
          next
        end
        quantity=1
      else
        maxafford=(price<=0) ? BAG_MAX_PER_SLOT : @adapter.getMiles/price
        maxafford=BAG_MAX_PER_SLOT if maxafford>BAG_MAX_PER_SLOT
        quantity=@scene.pbChooseNumber(
           _INTL("{1}? Certainly. How many would you like?",itemname),item,maxafford)
        next if quantity==0
        price*=quantity
        if !pbConfirm(_INTL("{1}, and you want {2}. \nThat will be {3} PM. OK?",
           itemname,quantity,price.to_s_formatted))
          next
        end
      end
      if @adapter.getMiles<price
        pbDisplayPaused(_INTL("You don't have enough Poké Miles."))
        next
      end
      added=0
      quantity.times do
        if !@adapter.addItem(item)
          break
        end
        added+=1
      end
      if added!=quantity
        added.times do
          if !@adapter.removeItem(item)
            raise _INTL("Failed to delete stored items")
          end
        end
        pbDisplayPaused(_INTL("You have no more room in the Bag."))
      else
        @adapter.setMiles(@adapter.getMiles-price)
        for i in 0...@stock.length
          if pbIsImportantItem?(@stock[i]) && $PokemonBag.pbHasItem?(@stock[i])
            @stock[i]=nil
          end
        end
        @stock.compact!
        pbDisplayPaused(_INTL("Here you are! Thank you!")) { pbSEPlay("Mart buy item") }
        if $PokemonBag
          if quantity>=10 && pbIsPokeBall?(item) && hasConst?(PBItems,:PREMIERBALL)
            if @adapter.addItem(getConst(PBItems,:PREMIERBALL))
              pbDisplayPaused(_INTL("I'll throw in a Premier Ball, too."))
            end
          end
        end
      end
    end
    @scene.pbEndBuyScene
  end

  def pbSellScreen
    item=@scene.pbStartSellScene(@adapter.getInventory,@adapter)
    loop do
      item=@scene.pbChooseSellItem
      break if item==0
      itemname=@adapter.getDisplayName(item)
      price=@adapter.getPrice(item,true)
      if !@adapter.canSell?(item)
        pbDisplayPaused(_INTL("{1}? Oh, no. I can't buy that.",itemname))
        next
      end
      qty=@adapter.getQuantity(item)
      next if qty==0
      @scene.pbShowMoney
      if qty>1
        qty=@scene.pbChooseNumber(
           _INTL("{1}? How many would you like to sell?",itemname),item,qty)
      end
      if qty==0
        @scene.pbHideMoney
        next
      end
      price/=2
      price*=qty
      if pbConfirm(_INTL("I can pay {1} PM. Would that be OK?",price.to_s_formatted))
        @adapter.setMiles(@adapter.getMiles+price)
        qty.times do
          @adapter.removeItem(item)
        end
        pbDisplayPaused(_INTL("Turned over the {1} and received {2} PM.",itemname,price.to_s_formatted)) { pbSEPlay("Mart buy item") }
        @scene.pbRefreshX
      end
      @scene.pbHideMiles
    end
    @scene.pbEndSellScene
  end
end

def pbPokemonMilesMart(stock,speech=nil,cantsell=false)
  for i in 0...stock.length
    stock[i] = getID(PBItems,stock[i])
    if !stock[i] || stock[i]==0 ||
       (pbIsImportantItem?(stock[i]) && $PokemonBag.pbHasItem?(stock[i]))
      stock[i] = nil
    end
  end
  stock.compact!
  commands = []
  cmdBuy  = -1
  cmdSell = -1
  cmdQuit = -1
  commands[cmdBuy = commands.length]  = _INTL("Buy")
  commands[cmdSell = commands.length] = _INTL("Sell") if !cantsell
  commands[cmdQuit = commands.length] = _INTL("Quit")
  cmd = pbMessage(
     speech ? speech : _INTL("Welcome! How may I serve you?"),
     commands,cmdQuit+1)
  loop do
    if cmdBuy>=0 && cmd==cmdBuy
      scene = PokemonMilesMart_Scene.new
      screen = PokemonMilesMartScreen.new(scene,stock)
      screen.pbBuyScreenMiles
    elsif cmdSell>=0 && cmd==cmdSell
      scene = PokemonMilesMart_Scene.new
      screen = PokemonMilesMartScreen.new(scene,stock)
      screen.pbSellScreen
    else
      pbMessage(_INTL("Please come again!"))
      break
    end
    cmd = pbMessage(_INTL("Is there anything else I can help you with?"),
       commands,cmdQuit+1)
  end
  $game_temp.clear_mart_prices
end
