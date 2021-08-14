#===============================================================================
# * Advanced Pok�dex - by FL (Credits will be apreciated)
#===============================================================================
#
# This script is for Pok�mon Essentials. When a switch is ON, it displays at 
# pok�dex the pok�mon PBS data for a caught pok�mon like: base exp, egg steps
# to hatch, abilities, wild hold item, evolution, the moves that pok�mon can 
# learn by level/breeding/machines/tutors, among others.
#
#===============================================================================
#
# To this script works, put it above main, put a 512x384 background named 
# "bg_advanced" for this screen in "Graphics/Pictures/Pokedex/". At same folder,
# put three 512x32 images for the top pok�dex selection named
# "advancedInfoBar", "advancedAreaBar" and "advancedFormsBar".
#
# -In PScreen_PokedexEntry script section, change both lines (use Ctrl+F to find
# it) '@page = 3 if @page>3' into '@page=@maxPage if @page>@maxPage'.
#
# -Right after first line 'if Input.trigger?(Input::A)' add:
#
# if @page == 4
#   @subPage-=1
#   @subPage=@totalSubPages if @subPage<1
#   displaySubPage
# end
#
# -Right after second line 'elsif Input.trigger?(Input::C)' add:
#
# if @page == 4
#   @subPage+=1
#   @subPage=1 if @subPage>@totalSubPages
#   displaySubPage
# end
#
#===============================================================================

class PokemonPokedexInfo_Scene
  # Switch number that toggle this script ON/OFF
  SWITCH=70
  
  # When true always shows the egg moves of the first evolution stage
  EGGMOVESFISTSTAGE = true
  
  # When false shows different messages for each of custom evolutions,
  # change the messages to ones that fills to your method
  HIDECUSTOMEVOLUTION = true
  
  # When true displays TMs/HMs/Tutors moves
  SHOWMACHINETUTORMOVES = true
  
  # When true picks the number for TMs and the first digit after a H for 
  # HMs (like H8) when showing machine moves.
  FORMATMACHINEMOVES = true
  
  # When false doesn't displays moves in tm.txt PBS that aren't in
  # any TM/HM item
  SHOWTUTORMOVES = true
  
  # The division between tutor and machine (TM/HMs) moves is made by 
  # the TM data in items.txt PBS
  
  alias :pbStartSceneOldFL :pbStartScene
  def pbStartScene(dexlist,index,region)
    @maxPage = $game_switches[SWITCH] ? 4 : 3
    pbStartSceneOldFL(dexlist,index,region)
    @sprites["advanceicon"]=PokemonSpeciesIconSprite.new(@species,@viewport)
    @sprites["advanceicon"].x=52
    @sprites["advanceicon"].y=290
    @sprites["advanceicon"].visible = false
  end
  
  alias :drawPageOldFL :drawPage
  def drawPage(page)
    drawPageOldFL(page)
    return if @brief
    dexbarVisible = $game_switches[SWITCH] && @page<=3
    @sprites["dexbar"] = IconSprite.new(0,0,@viewport) if !@sprites["dexbar"]
    @sprites["dexbar"].visible = dexbarVisible
    if dexbarVisible
      barBitmapPath = [
        nil,
        _INTL("Graphics/Pictures/Pokedex/advancedInfoBar"),
        _INTL("Graphics/Pictures/Pokedex/advancedAreaBar"),
        _INTL("Graphics/Pictures/Pokedex/advancedFormsBar")
      ]
      @sprites["dexbar"].setBitmap(barBitmapPath[@page])
    end
    @sprites["advanceicon"].visible = page==4 if @sprites["advanceicon"]
    drawPageAdvanced if page==4
  end
  
  alias :pbUpdateDummyPokemonOldFL :pbUpdateDummyPokemon
  def pbUpdateDummyPokemon
    pbUpdateDummyPokemonOldFL
    if @sprites["advanceicon"]
      @sprites["advanceicon"].pbSetParams(@species,@gender,@form)
    end
  end
  
  BASECOLOR = Color.new(88,88,80)
  SHADOWCOLOR = Color.new(168,184,184)
  BASE_X = 32
  EXTRA_X = 224
  BASE_Y = 64
  EXTRA_Y = 32
  
  def drawPageAdvanced
    @sprites["background"].setBitmap(
      _INTL("Graphics/Pictures/Pokedex/bg_advanced"))
    @type1=nil
    @type2=nil
    @subPage=1
    @totalSubPages=0
    if $Trainer.owned[@species]
      @infoPages=3
      @infoArray=getInfo
      @levelMovesArray=getLevelMoves
      @eggMovesArray=getEggMoves
      @machineMovesArray=getMachineMoves if SHOWMACHINETUTORMOVES
      @levelMovesPages = (@levelMovesArray.size+9)/10
      @eggMovesPages = (@eggMovesArray.size+9)/10
      @machineMovesPages=(@machineMovesArray.size+9)/10 if SHOWMACHINETUTORMOVES
      @totalSubPages = @infoPages+@levelMovesPages+@eggMovesPages
      @totalSubPages+=@machineMovesPages if SHOWMACHINETUTORMOVES
    end
    displaySubPage
  end
  
  def displaySubPage
    overlay = @sprites["overlay"].bitmap
    overlay.clear
    height = Graphics.height-54
    
    # Bottom text  
    textpos = [[PBSpecies.getName(@species),(Graphics.width+72)/2,height-32,
      2,BASECOLOR,SHADOWCOLOR]]
    if $Trainer.owned[@species]
      textpos.push([_INTL("{1}/{2}",@subPage,@totalSubPages),
        Graphics.width-52,height,1,BASECOLOR,SHADOWCOLOR])
    end
    pbDrawTextPositions(@sprites["overlay"].bitmap, textpos)
    
    # Type icon
    if !@type1 # Only checks for not owned pok�mon
      dexdata=pbOpenDexData
      pbDexDataOffset(dexdata,@species,8)
      @type1=dexdata.fgetb
      @type2=dexdata.fgetb
      dexdata.close
    end
    type1rect = Rect.new(0,@type1*32,96,32)
    type2rect = Rect.new(0,@type2*32,96,32)
    if(@type1==@type2)
      overlay.blt((Graphics.width+16-36)/2,height,@typebitmap.bitmap,type1rect)
    else  
      overlay.blt((Graphics.width+16-144)/2,height,@typebitmap.bitmap,type1rect)
      overlay.blt((Graphics.width+16+72)/2,height,
        @typebitmap.bitmap,type2rect) if @type1!=@type2
    end
    
    return if !$Trainer.owned[@species]
    
    # Page content
    if(@subPage<=@infoPages)
      subPageInfo(@subPage)
    elsif(@subPage<=@infoPages+@levelMovesPages)
      subPageMoves(@levelMovesArray,_INTL("LEVEL UP MOVES:"),@subPage-@infoPages)
    elsif(@subPage<=@infoPages+@levelMovesPages+@eggMovesPages)
      subPageMoves(@eggMovesArray,_INTL("EGG MOVES:"),
          @subPage-@infoPages-@levelMovesPages)
    elsif(SHOWMACHINETUTORMOVES && @subPage <= 
        @infoPages+@levelMovesPages+@eggMovesPages+@machineMovesPages)
      subPageMoves(@machineMovesArray,_INTL("MACHINE MOVES:"),
          @subPage-@infoPages-@levelMovesPages-@eggMovesPages)
    end
  end
  
  def subPageInfo(subPage)
    textpos = []
    for i in (12*(subPage-1))...(12*subPage)
      line = i%6
      column = i/6
      next if !@infoArray[column][line]
      x = BASE_X+EXTRA_X*(column%2)
      y = BASE_Y+EXTRA_Y*line
      textpos.push([@infoArray[column][line],x,y,false,BASECOLOR,SHADOWCOLOR])
    end
    pbDrawTextPositions(@sprites["overlay"].bitmap, textpos)
  end  
    
  def subPageMoves(movesArray,label,subPage)
    textpos = [[label,BASE_X,BASE_Y,false,BASECOLOR,SHADOWCOLOR]]
      for i in (10*(subPage-1))...(10*subPage)
      break if i>=movesArray.size
      line = i%5
      column = i/5
      x = BASE_X+EXTRA_X*(column%2)
      y = BASE_Y+EXTRA_Y*(line+1)
      textpos.push([movesArray[i],x,y,false,BASECOLOR,SHADOWCOLOR])
    end
    pbDrawTextPositions(@sprites["overlay"].bitmap,textpos)
  end  
  
  def getInfo
    ret = []
    for i in 0...2*4
      ret[i]=[]
      for j in 0...6
        ret[i][j]=nil
      end
    end  
    dexdata=pbOpenDexData
    # Type
    pbDexDataOffset(dexdata,@species,8)
    @type1=dexdata.fgetb
    @type2=dexdata.fgetb
    # Base Exp
    pbDexDataOffset(dexdata,@species,38)
    ret[0][0]=_INTL("BASE EXP: {1}",dexdata.fgetw)
    # Catch Rate
    pbDexDataOffset(dexdata,@species,16)
    ret[1][0]=_INTL("CATCH RARENESS: {1}",dexdata.fgetb)
    # Happiness base
    pbDexDataOffset(dexdata,@species,19)
    ret[0][1]=_INTL("HAPPINESS BASE: {1}",dexdata.fgetb)
    # Color
    pbDexDataOffset(dexdata,@species,6)
    colorName=[
        _INTL("Red"),_INTL("Blue"),_INTL("Yellow"),
        _INTL("Green"),_INTL("Black"),_INTL("Brown"),
        _INTL("Purple"),_INTL("Gray"),_INTL("White"),_INTL("Pink")
    ][dexdata.fgetb]
    ret[1][1]=_INTL("COLOR: {1}",colorName)
    # Egg Steps to Hatch
    pbDexDataOffset(dexdata,@species,21)
    stepsToHatch = dexdata.fgetw
    ret[0][2]=_INTL("EGG STEPS TO HATCH: {1} ({2} cycles)",
        stepsToHatch,stepsToHatch/255)
    # Growth Rate
    pbDexDataOffset(dexdata,@species,20) 
    growthRate=dexdata.fgetb
    growthRateString = [_INTL("Medium"),_INTL("Erratic"),_INTL("Fluctuating"),
        _INTL("Parabolic"),_INTL("Fast"),_INTL("Slow")][growthRate]
    ret[0][3]=_INTL("GROWTH RATE: {1} ({2})",
        growthRateString,PBExperience.pbGetMaxExperience(growthRate))
    # Gender Rate
    pbDexDataOffset(dexdata,@species,18)
    genderbyte=dexdata.fgetb
    genderPercent= 100-((genderbyte+1)*100/256.0)
    genderString = case genderbyte
      when 0;   _INTL("Always male")
      when 254; _INTL("Always female")
      when 255; _INTL("Genderless")
      else;     _INTL("Male {1}%",genderPercent)
    end
    ret[0][4]=_INTL("GENDER RATE: {1}",genderString)
    # Breed Group
    pbDexDataOffset(dexdata,@species,31)
    compat10=dexdata.fgetb
    compat11=dexdata.fgetb
    eggGroupArray=[
        nil,_INTL("Monster"),_INTL("Water1"),_INTL("Bug"),_INTL("Flying"),
        _INTL("Ground"),_INTL("Fairy"),_INTL("Plant"),_INTL("Humanshape"),
        _INTL("Water3"),_INTL("Mineral"),_INTL("Indeterminate"),
        _INTL("Water2"),_INTL("Ditto"),_INTL("Dragon"),_INTL("No Eggs")
    ]
    eggGroups = compat10==compat11 ? eggGroupArray[compat10] : 
        _INTL("{1}, {2}",eggGroupArray[compat10],eggGroupArray[compat11])
    ret[0][5]=_INTL("BREED GROUP: {1}",eggGroups)
    # Base Stats
    pbDexDataOffset(dexdata,@species,10)
    baseStats=[
        dexdata.fgetb, # HP
        dexdata.fgetb, # Attack
        dexdata.fgetb, # Defense
        dexdata.fgetb, # Speed
        dexdata.fgetb, # Special Attack
        dexdata.fgetb  # Special Defense
    ]
    baseStatsTot=0
    for i in 0...baseStats.size
      baseStatsTot+=baseStats[i]
    end
    baseStats.push(baseStatsTot)
    ret[2][0]=_ISPRINTF(
        "                             HP ATK DEF SPD SATK SDEF")
    ret[2][1]=_ISPRINTF(
        "BASE STATS:       {1:03d} {2:03d} {3:03d} {4:03d} {5:03d} {6:03d} {7:03d}",
        baseStats[0],baseStats[1],baseStats[2],
        baseStats[3],baseStats[4],baseStats[5],baseStats[6])
    # Effort Points
    pbDexDataOffset(dexdata,@species,23)
    effortPoints=[
        dexdata.fgetb, # HP
        dexdata.fgetb, # Attack
        dexdata.fgetb, # Defense
        dexdata.fgetb, # Speed
        dexdata.fgetb, # Special Attack
        dexdata.fgetb  # Special Defense
    ]
    effortPointsTot=0
    for i in 0...effortPoints.size
      effortPoints[i]=0 if  !effortPoints[i]
      effortPointsTot+=effortPoints[i]
    end
    effortPoints.push(effortPointsTot)
    ret[2][2]=_ISPRINTF(
        "EFFORT POINTS: {1:03d} {2:03d} {3:03d} {4:03d} {5:03d} {6:03d} {7:03d}",
        effortPoints[0],effortPoints[1],effortPoints[2],
        effortPoints[3],effortPoints[4],effortPoints[5],effortPoints[6])
    # Abilities
    pbDexDataOffset(dexdata,@species,2)
    ability1=dexdata.fgetw
    ability2=dexdata.fgetw
    abilityString=(ability1==ability2 || ability2==0) ? 
        PBAbilities.getName(ability1) : _INTL("{1}, {2}",
        PBAbilities.getName(ability1), PBAbilities.getName(ability2))
    ret[2][3]=_INTL("ABILITIES: {1}",abilityString)
    # Hidden Abilities
    pbDexDataOffset(dexdata,@species,40)
    hiddenAbility1=dexdata.fgetb
    hiddenAbility2=dexdata.fgetb
    hiddenAbility3=dexdata.fgetb
    hiddenAbility4=dexdata.fgetb
    if hiddenAbility1!=0
      abilityString=""
      if(hiddenAbility3!=0) 
        abilityString = _INTL("{1}, {2},",PBAbilities.getName(hiddenAbility1), 
            PBAbilities.getName(hiddenAbility2))
      elsif(hiddenAbility2!=0)
        abilityString = _INTL("{1}, {2}",PBAbilities.getName(hiddenAbility1),
            PBAbilities.getName(hiddenAbility2))
      else
        abilityString = PBAbilities.getName(hiddenAbility1)
      end  
      ret[2][4]=_INTL("HIDDEN ABILITIES: {1}",abilityString)
      if(hiddenAbility3!=0) 
        ret[2][5] = (hiddenAbility4==0) ? PBAbilities.getName(hiddenAbility3) : 
            _INTL("{1}, {2}",PBAbilities.getName(hiddenAbility3),
            PBAbilities.getName(hiddenAbility4))
      end  
    end
    # Wild hold item 
    pbDexDataOffset(dexdata,@species,48)
    holdItems=[dexdata.fgetw,dexdata.fgetw,dexdata.fgetw]
    holdItemsStrings=[]
    if(holdItems[0]!=0 && holdItems[0]==holdItems[1] && 
        holdItems[0]==holdItems[2])
      holdItemsStrings.push(_INTL("{1} (always)",
          PBItems.getName(holdItems[0])))
    else
      holdItemsStrings.push(_INTL("{1} (common)", 
          PBItems.getName(holdItems[0]))) if holdItems[0]>0
      holdItemsStrings.push(_INTL("{1} (uncommon)",
          PBItems.getName(holdItems[1]))) if holdItems[1]>0
      holdItemsStrings.push(_INTL("{1} (rare)", 
          PBItems.getName(holdItems[2]))) if holdItems[2]>0
    end
    ret[4][0] = _INTL("HOLD ITEMS: {1}",holdItemsStrings.empty? ? 
        "" : holdItemsStrings[0])
    ret[4][1] = holdItemsStrings[1] if holdItemsStrings.size>1
    ret[4][2] = holdItemsStrings[2] if holdItemsStrings.size>2
    # Evolutions
    evolutionsStrings = []
    lastEvolutionSpecies = -1
    for evolution in pbGetEvolvedFormData(@species)
      # The below "if" it's to won't list the same evolution species more than
      # one time. Only the last is displayed.
      evolutionsStrings.pop if lastEvolutionSpecies==evolution[2]
      evolutionsStrings.push(getEvolutionMessage(evolution))
      lastEvolutionSpecies=evolution[2]
    end
    line=3
    column=4
    ret[column][line] = _INTL("EVO: {1}",evolutionsStrings.empty? ? 
        "" : evolutionsStrings[0])
    evolutionsStrings.shift
    line+=1
      for string in evolutionsStrings
      if(line>5) # For when the pok�mon has more than 3 evolutions (AKA Eevee) 
        line=0
          column+=2
        @infoPages+=1 # Creates a new page
      end
        ret[column][line] = string
      line+=1
      end
      # End
      dexdata.close
    return ret
    end  
    
  # Gets the evolution array and return evolution message
  def getEvolutionMessage(evolution)
    evoPokemon = PBSpecies.getName(evolution[2])
    evoMethod = evolution[0]
    evoItem = evolution[1] # Sometimes it's level
    ret = case evoMethod
      when 1; _INTL("{1} when happy",evoPokemon)
      when 2; _INTL("{1} when happy at day",evoPokemon)
      when 3; _INTL("{1} when happy at night",evoPokemon)
      when 4, 13;_INTL("{1} at level {2}",
          evoPokemon,evoItem) # Pok�mon that evolve by level AND Ninjask
      when 5; _INTL("{1} trading",evoPokemon)
      when 6; _INTL("{1} trading holding {2}",
          evoPokemon,PBItems.getName(evoItem))
      when 7; _INTL("{1} using {2}",evoPokemon,PBItems.getName(evoItem))
      when 8; _INTL("{1} at level {2} and ATK > DEF",
          evoPokemon,evoItem) # Hitmonlee
      when 9; _INTL("{1} at level {2} and ATK = DEF",
          evoPokemon,evoItem) # Hitmontop
      when 10;_INTL("{1} at level {2} and DEF < ATK",
          evoPokemon,evoItem) # Hitmonchan 
      when 11,12; _INTL("{1} at level {2} with personalID",
          evoPokemon,evoItem) # Silcoon/Cascoon
      when 14;_INTL("{1} at level {2} with empty space",
          evoPokemon,evoItem) # Shedinja
      when 15;_INTL("{1} when beauty is greater than {2}",
          evoPokemon,evoItem) # Milotic 
      when 16;_INTL("{1} using {2} and it's male",
          evoPokemon,PBItems.getName(evoItem))
      when 17;_INTL("{1} using {2} and it's female",
          evoPokemon,PBItems.getName(evoItem))
      when 18;_INTL("{1} holding {2} at day",
          evoPokemon,PBItems.getName(evoItem))
      when 19;_INTL("{1} holding {2} at night",
          evoPokemon,PBItems.getName(evoItem))
      when 20;_INTL("{1} when has move {2}",
          evoPokemon,PBMoves.getName(evoItem))
      when 21;_INTL("{1} when has {2} at party",
          evoPokemon,PBSpecies.getName(evoItem))
      when 22;_INTL("{1} at level {2} and it's male",
          evoPokemon,evoItem)
      when 23;_INTL("{1} at level {2} and it's female",
          evoPokemon,evoItem)
      when 24;_INTL("{1} at {2}",
          evoPokemon, pbGetMapNameFromId(evoItem)) # Evolves on a certain map
      when 25;_INTL("{1} trading by {2}",
          evoPokemon,PBSpecies.getName(evoItem)) # Escavalier/Accelgor
      # When HIDECUSTOMEVOLUTION = false the below 7 messages will be displayed
      when 26;_INTL("{1} custom1 with {2}", evoPokemon,evoItem) 
      when 27;_INTL("{1} custom2 with {2}", evoPokemon,evoItem) 
      when 28;_INTL("{1} custom3 with {2}", evoPokemon,evoItem) 
      when 29;_INTL("{1} custom4 with {2}", evoPokemon,evoItem) 
      when 30;_INTL("{1} custom5 with {2}", evoPokemon,evoItem) 
      when 31;_INTL("{1} custom6 with {2}", evoPokemon,evoItem)
      when 32;_INTL("{1} custom7 with {2}", evoPokemon,evoItem)
      else; ""  
    end  
      ret = _INTL("{1} by an unknown way", evoPokemon) if(ret.empty? ||
        (evoMethod>=26 && HIDECUSTOMEVOLUTION))
    return ret    
  end
    
  def getLevelMoves
    ret=[]
      atkdata=pbRgssOpen("Data/attacksRS.dat","rb")
    offset=atkdata.getOffset(@species-1)
    length=atkdata.getLength(@species-1)>>1
    atkdata.pos=offset
    for k in 0..length-1
      level=atkdata.fgetw
      move=PBMoves.getName(atkdata.fgetw)
      ret.push(_ISPRINTF("{1:02d} {2:s}",level,move))
    end
      atkdata.close
    return ret
    end  
    
  def getEggMoves
    ret=[]  
      eggMoveSpecies = @species
    eggMoveSpecies = pbGetBabySpecies(eggMoveSpecies) if EGGMOVESFISTSTAGE
    pbRgssOpen("Data/eggEmerald.dat","rb"){|f|
      f.pos=(eggMoveSpecies-1)*8
      offset=f.fgetdw
      length=f.fgetdw
      if length>0
        f.pos=offset
        i=0; loop do break unless i<length
          move=PBMoves.getName(f.fgetw)
          ret.push(_ISPRINTF("     {1:s}",move))
          i+=1
          end
        end
      }
    ret.sort!
    return ret
  end  
    
  def getMachineMoves
    ret=[]
    movesArray=[]
    machineMoves=[]
    tmData=load_data("Data/tm.dat")
    for move in 1...tmData.size
      next if !tmData[move]
      movesArray.push(move) if tmData[move].any?{ |item| item==@species }
    end
      for item in 1..PBItems.maxValue
      if pbIsMachine?(item)
        move = $ItemData[item][ITEMMACHINE]
        if movesArray.include?(move)
          if FORMATMACHINEMOVES
            machineLabel = PBItems.getName(item)
            machineLabel = machineLabel[2,machineLabel.size-2] 
            machineLabel = "H"+machineLabel[1,1] if pbIsHiddenMachine?(item)
            ret.push(_ISPRINTF("{1:s} {2:s}",
                machineLabel,PBMoves.getName(move)))
            movesArray.delete(move)
          else
              machineMoves.push(move)
          end  
        end
      end  
    end
    # The above line removes the tutors moves. The movesArray will be 
    # empty if the machines are already in the ret array.
    movesArray = machineMoves if !SHOWTUTORMOVES
    unnumeredMoves=[]
    for move in movesArray # Show the moves unnumered
      unnumeredMoves.push(_ISPRINTF("     {1:s}",PBMoves.getName(move)))
    end  
    ret = ret.sort + unnumeredMoves.sort
    return ret
  end  
end