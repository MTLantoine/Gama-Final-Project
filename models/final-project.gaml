/**
* Name: finalproject
* Based on the internal empty template. 
* Author: Antoine MORTELIER & Louis DUTOIT
* Tags: 
*/


model finalproject

global {
	int nb_trees_init <- 20;
	int nb_aspen_init <- rnd(nb_trees_init);
	int nb_cottonwood_init <- rnd(nb_trees_init - nb_aspen_init);
	int nb_willow_init <- nb_trees_init - nb_aspen_init - nb_cottonwood_init;
	
	int nb_aspens -> {length(aspen)};
	int nb_cottonwoods -> {length(cottonwood)};
	int nb_willows -> {length(willow)};
	
	float prey_proba_spread <- 0.001;
	
	geometry shape <- square(1 #km);
	
	// Les arbres grandissent d'environ 45cm par an, soit environ 0,12cm par jour.
	float step <- 1#day;	
	
	init {
		create aspen number: nb_aspen_init;
		create cottonwood number: nb_cottonwood_init;
		create willow number: nb_willow_init;
	}
}

species tree {
	float max_perimeter <- 50.0;
	float max_height <- 50.0 #m;
	float tree_grow<- rnd(0.10 #cm, 0.15 #cm);
	float size <- rnd(2.0 #m, 5.0 #m) max: max_height update: size + tree_grow;
	float proba_spread <- prey_proba_spread;
	bool can_spread <- true;
	rgb color <- #green;
	
	reflex spread when: (size >= max_height / 2) and (flip(proba_spread)) and (can_spread = true) {
		int nb_seeds <- 1;
		create species(self) number: nb_seeds {
			location <- myself.location + {rnd(-max_perimeter, max_perimeter), rnd(-max_perimeter, max_perimeter)};
			myself.can_spread <- false;
		}
	}
	
	aspect default {
		draw pyramid(200 #cm + size) color: color border: #black;	
	}
}

species aspen parent: tree {
	float max_height <- 20.0 #m;
	rgb color <- (size > 0) ? rgb(224, 150, 20) : #brown;
	aspect default {
		draw triangle(200 #cm + size) color: color border: #black;	
	}
}

species cottonwood parent: tree {
	float max_height <- 40.0 #m;
	rgb color <- (size > 0) ? rgb(74, 93, 36) : #brown;
	aspect default {
		draw triangle(200 #cm + size) color: color border: #black;	
	}
}

species willow parent: tree {
	float max_height <- 8.0 #m;
	rgb color <- (size > 0) ? rgb(51, 71, 1) : #brown;
	aspect default {
		draw circle(50 #cm + size) color: color border: #black;	
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