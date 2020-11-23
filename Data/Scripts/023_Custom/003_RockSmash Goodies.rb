#===============================================================================
# * Probability can be anything. (recommend 100)
# * Length always needs to be: totalItems-1
# * Items is the list of items you want to encounter.
#     Here you can see Dome Fossil is there multiple times.
#     This just means the chance will be higher to encounter the item.
# * Item, Probability
#     This is the likelihood of you actually getting the item.
#     In these cases: 5/100.
#     The higher this number, the more chance to find it.
#     If you have 100 and the item is found at all, you should receive it.
# * I suggest adding multiple of an item that you want to be more common than
#     than others.  But your choice.
# * Credit "Nickalooose" if used.
#===============================================================================
PROBABILITY=100
ROCKSMAMUKEMSLENGTH=8
ROCKSMAMUKEMS = [   # Item, probability
     [:DOMEFOSSIL,25],
     [:HELIXFOSSIL,25],
     [:CLAWFOSSIL,25],
     [:ROOTFOSSIL,25],
     [:REDSHARD,100],
     [:YELLOWSHARD,100],
     [:BLUESHARD,100],
     [:GREENSHARD,100],
     [:REVIVE,10]
]
  
  # the rest of the code is in 011_PField_FieldMoves, around line 600