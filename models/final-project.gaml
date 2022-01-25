/**
* Name: finalproject
* Based on the internal empty template. 
* Author: Antoine MORTELIER & Louis DUTOIT
* Tags: 
*/


model finalproject

global {
	
	float step <- 1 #day;	
	int nb_aspen_init <- 5;
	int nb_cottonwood_init <- 5;
	int nb_willow_init <- 5;
	
	int nb_aspens -> {length(aspen)};
	int nb_cottonwoods -> {length(cottonwood)};
	int nb_willows -> {length(willow)};
	
	float prey_proba_spread <- 0.0001;
	
	float surface <- 250 #m;
	geometry shape <- square(surface);
	
	init {
		create aspen number: nb_aspen_init;
		create cottonwood number: nb_cottonwood_init;
		create willow number: nb_willow_init;
	}
}

species tree {
	float max_perimeter <- 20.0 #m;
	float max_height <- 50.0 #m;
	float tree_grow<- rnd(0.10 #cm, 0.15 #cm);
	float size <- rnd(2.0 #m, 5.0 #m) max: max_height update: size + tree_grow;
	float proba_spread <- prey_proba_spread;
	bool can_spread <- true;
	rgb color <- #green;
	
	reflex spread when: (size >= max_height / 2) and (flip(proba_spread)) and (can_spread = true) {
		int nb_seeds <- 3;
		create species(self) number: nb_seeds {
			point new_location <- myself.location + {rnd(-max_perimeter, max_perimeter), rnd(-max_perimeter, max_perimeter)};
			float new_x <- new_location.x;
			new_x <- (new_x < 0.0) ? (new_x + surface) : new_x;
			new_x <- (new_x > surface) ? (new_x - surface) : new_x;
			float new_y <- new_location.y;
			new_y <- (new_y < 0.0) ? (new_y + surface) : new_y;
			new_y <- (new_y > surface) ? (new_y - surface) : new_y;
			new_location <- {new_x, new_y};
			location <- new_location;
			myself.can_spread <- false;
		}
	}
	
	aspect default {
		draw triangle(200 #cm + size) color: color border: #black;	
	}
}

species aspen parent: tree {
	float max_height <- 20.0 #m;
	rgb color <- (size > 0) ? rgb(224, 150, 20) : #brown;
	aspect default {
		draw square(200 #cm + size) color: color border: #black;	
	}
}

species cottonwood parent: tree {
	float max_height <- 40.0 #m;
	rgb color <- (size > 0) ? rgb(112, 137, 53) : #brown;
	aspect default {
		draw square(200 #cm + size) color: color border: #black;	
	}
}

species willow parent: tree {
	float max_height <- 8.0 #m;
	rgb color <- (size > 0) ? rgb(51, 71, 1) : #brown;
	aspect default {
		draw square(50 #cm + size) color: color border: #black;	
	}
}

experiment TreeBdi type: gui {

	output {
		display map type: opengl {
			species aspen;
			species cottonwood;
			species willow;
		}
	
		monitor "Number of aspens" value: nb_aspens;
		monitor "Number of cottonwoods" value: nb_cottonwoods;
		monitor "Number of willows" value: nb_willows;
	}
}