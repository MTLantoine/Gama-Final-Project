/**
* Name: finalproject
* Based on the internal empty template. 
* Author: Antoine MORTELIER & Louis DUTOIT
* Tags: 
*/


model finalproject

global {
	
	// SIMULATION
	
	float step <- 1#minute;
	float surface <- 1#km;
	geometry shape <- square(surface);
	
	// TREE
	
	int nb_aspen_init <- 5;
	int nb_cottonwood_init <- 5;
	int nb_willow_init <- 5;
	
	int nb_aspens -> {length(aspen)};
	int nb_cottonwoods -> {length(cottonwood)};
	int nb_willows -> {length(willow)};
	
	float prey_proba_spread <- 0.0001;
	
	// WAPITI
	
	int nb_wapiti <- 10;
	
	string tree_at_location <- "tree_at_location";
	string not_available_location <- "not_available_location";
	
    predicate tree_location <- new_predicate(tree_at_location);
	predicate choose_tree <- new_predicate("choose a tree");
	predicate is_available <- new_predicate("eat tree");
	predicate can_eat <- new_predicate("can eat");
	predicate find_tree <- new_predicate("find tree");
	predicate eat_tree <- new_predicate("eat tree");
	
	init {
		create aspen number: nb_aspen_init;
		create cottonwood number: nb_cottonwood_init;
		create willow number: nb_willow_init;
		
		create wapiti number: nb_wapiti;
	}
}

species wapiti skills: [moving] control: simple_bdi {
    
    float view_dist <- 20.0 #m;
    float speed <- 1#km/#h;
    rgb color <- rgb(155, 107, 89);
    point target;
    int gold_sold;
    
    init {
        do add_desire(find_tree);
    }
    
    perceive target: tree where (each.size < 1#m) in: view_dist {
    focus id: tree_at_location var:location;
	    ask myself {
	        do remove_intention(find_tree, false);
	    }
    }
    
    rule belief: tree_location new_desire: is_available strength: 2.0;
    rule belief: eat_tree new_desire: can_eat strength: 3.0;
        
    plan lets_wander intention: find_tree  {
        do wander;
    }
    
//    plan eat_tree intention: is_available {
//    	if (target = nil) {
//    		do add_subintention(get_current_intention(), choose_tree, true);
//    	}
//    }
    
    aspect default {
      draw circle(3#m) color: color border: #black;
      draw circle(view_dist) color: color border: #black empty: true;
    }
}

species tree {
	float max_perimeter <- 50.0 #m;
	float max_height <- 50.0 #m;
	float tree_grow<- rnd(0.000057#cm, 0.000114#cm);
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
			
			species wapiti;
		}
	
//		monitor "Number of aspens" value: nb_aspens;
//		monitor "Number of cottonwoods" value: nb_cottonwoods;
//		monitor "Number of willows" value: nb_willows;
	}
}