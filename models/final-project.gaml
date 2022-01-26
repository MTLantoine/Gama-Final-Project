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
	float surface <- 250#m;
	geometry shape <- square(surface);
	
	// TREE
	
	int nb_tree_init <- 10;
	
	int nb_trees -> {length(tree)};
	
	float prey_proba_spread <- 0.0001;
	
	// WAPITI
	
	int nb_wapiti <- 2;
	
	string tree_at_location <- "tree_at_location";
	string not_available_location <- "not_available_location";
	
    predicate tree_location <- new_predicate(tree_at_location);
	predicate choose_tree <- new_predicate("choose a tree");
	predicate is_available <- new_predicate("eat tree");
	predicate can_eat <- new_predicate("can eat");
	predicate find_tree <- new_predicate("find tree");
	predicate eat_tree <- new_predicate("eat tree");
	
	init {
		create tree number: nb_tree_init;
		
		create wapiti number: nb_wapiti;
	}
}

species wapiti skills: [moving] control: simple_bdi {
    
    float view_dist <- 20.0 #m;
    float speed <- 1#km/#h;
    rgb color <- rgb(155, 107, 89);
    point target;
    
    init {
        do add_desire(find_tree);
    }
    
    perceive target: tree where (each.size < 1#m and each.size > 0.2#m) in: view_dist {
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
    
    plan eat_tree intention: is_available {
    	if (target = nil) {
    		do add_subintention(get_current_intention(), choose_tree, true);
    		do current_intention_on_hold();
    	} else {
    		do goto target: target;
    		if (target = location) {
    			tree current_tree <- tree first_with (target = each.location);
    			if (current_tree.size < 1#m and current_tree.size > 0.2#m) {
    				do add_belief(is_available);
    				ask current_tree {
    					size <- 0.0;
    				}
    			} else {
    				do add_belief(new_predicate(not_available_location, ["location_value"::target]));
    			}
    			target <- nil;
    		}
    	}
    }
    
    plan choose_closest_tree intention: choose_tree instantaneous: true {
    	list<point> possible_trees <- get_beliefs_with_name(tree_at_location) collect (point(get_predicate(mental_state (each)).values["location_value"]));
    	list<point> not_available_trees <- get_beliefs_with_name(not_available_location) collect (point(get_predicate(mental_state (each)).values["location_value"]));
    	possible_trees <- possible_trees - not_available_trees;
    	if (empty(possible_trees)) {
    		do remove_intention(eat_tree, true);
    	} else {
    		target <- (possible_trees with_min_of (each distance_to self)).location;
    	}
    	do remove_intention(choose_tree, true);
    }
    
    aspect default {
      draw circle(3#m) color: color border: #black;
      draw circle(view_dist) color: color border: #black empty: true;
    }
}

species tree {
	float max_perimeter <- 50.0 #m;
	float max_height <- 50.0 #m;
	float tree_grow<- rnd(0.01#cm, 0.02#cm);
	float size <- rnd(0.2 #m, 0.3 #m) max: max_height update: size + tree_grow;
	float proba_spread <- prey_proba_spread;
	bool can_spread <- true;
	rgb color <- (size > 0) ? rgb(112, 137, 53) : #brown;
	
	reflex spread when: (size >= max_height / 4) and (flip(proba_spread)) and (can_spread = true) {
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

experiment TreeBdi type: gui {

	output {
		display map type: opengl {
			species tree;
			
			species wapiti;
		}
	
//		monitor "Number of aspens" value: nb_aspens;
//		monitor "Number of cottonwoods" value: nb_cottonwoods;
//		monitor "Number of willows" value: nb_willows;
	}
}