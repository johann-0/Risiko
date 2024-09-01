extends Node2D

const COLORS: Array = [Color.BLUE, Color.RED, Color.GREEN, Color.YELLOW] 
var curColorID: int = 0:
	set(newID):
		if newID < 0 or newID > len(COLORS):
			curColorID = 0
		else:
			curColorID = newID
		
		# Adjust the sprite window
		$Sprite.offset.y = 8 * newID;
		#$Sprite.get_rect().wi #idk what i was gonna write here
var facingRight: bool = true:
	set(newFacingRight):
		if facingRight == true && newFacingRight == false:
			$Sprite.frame -=1
		elif facingRight == false && newFacingRight == true:
			$Sprite.frame += 1
		facingRight = newFacingRight
var soldiers: int = 0:
	set(newSoldiers):
		soldiers = newSoldiers
		$Strength.text = str(soldiers)

func _ready():
	$Sprite.frame += 1;




