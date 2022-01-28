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
	
	int nb_tree_init <- 100;
	
	int nb_trees -> {length(tree)};
	
	float tree_proba_spread <- 0.0001;
	
	// WAPITI
	
	int nb_wapiti_init <- 3;
	int nb_wapitis -> {length(wapiti)};
	
	float wapiti_max_energy <- 1.0;
	float wapiti_max_transfert <- 0.1;
	float wapiti_energy_consum <- 0.0005;
	float wapiti_reproduction <- 0.0005;
	
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
		
		create wapiti number: nb_wapiti_init;
	}
}

species tree {
	float max_perimeter <- 50.0 #m;
	float max_height <- rnd(30.0, 50.0) #m;
	float tree_grow<- rnd(0.02#cm, 0.04#cm);
	float size <- rnd(0.2 #m, 0.3 #m) max: max_height update: size + tree_grow;
	float proba_spread <- tree_proba_spread;
	bool can_spread <- true;
	
	float colorChange <- 0.0 max: 1.0 update: colorChange+0.00005;
	rgb changingColor <- rgb(int(152 * (1 - colorChange)), 251, int(152 * (1 - colorChange))) update: rgb(int(152 * (1 - colorChange)), 251, int(152 * (1 - colorChange)));
	
	reflex spread when: (size >= 2.0#m) and (flip(proba_spread)) and (can_spread = true) {
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
    
    reflex die when: size <= 0 {
		do die;
	}
	
	aspect default {
		draw triangle(500#cm + size / 3) color: changingColor border: #black;	
	}
}

species wapiti skills: [moving] control: simple_bdi {
    
    float view_dist <- 20.0 #m;
    float speed <- 1#km/#h;
    point target;
    string sexe <- any(["male", "female"]);
    float proba_spread <- wapiti_reproduction;
    rgb color <- sexe = "female" ? rgb(182, 165, 143) : rgb(155, 107, 89);
    image_file my_icon <- sexe = "female" ? image_file("../includes/data/wapiti-female.png") : image_file("../includes/data/wapiti-male.png");
    
    // ENERGY
	float max_energy <- wapiti_max_energy;
	float max_transfert <- wapiti_max_transfert;
	float energy_consum <- wapiti_energy_consum;
	int possible_reproduction <- rnd(1, 3);
    float energy <- rnd(max_energy) update: energy - energy_consum max: max_energy;
    
    init {
        do add_desire(find_tree);
    }
    
    perceive target: tree in: view_dist {
    	focus id: tree_at_location var:location;
	    ask myself {
	        do remove_intention(find_tree, false);
	    }
    }
    
    rule belief: tree_location new_desire: is_available strength: 2.0;
    rule belief: eat_tree new_desire: can_eat strength: 5.0;
        
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
    			if (!dead(current_tree) and current_tree.size < 2#m) {
    				do add_belief(is_available);
    				ask current_tree {
    					size <- size - 0.25#cm;
    					myself.energy <- myself.energy + 0.1;
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
    
    reflex reproduce when: (energy > 0.6 and flip(proba_spread) and sexe="female" and possible_reproduction > 0) {
    	int nb_child <- 1;
    	possible_reproduction <- possible_reproduction - 1;
		create species(self) number: nb_child {
			location <- myself.location;
		}
    }
    
    reflex die when: energy <= 0 {
		do die;
	}
    
    aspect icon {
      draw my_icon size: 15;
      draw circle(view_dist) color: color border: #black empty: true;
    }
}

experiment TreeBdi type: gui {
	parameter "Initial number of trees: " var: nb_tree_init min: 0 max: 500 category: "Tree";
	parameter "Initial number of wapiti: " var: nb_wapiti_init min: 0 max: 50 category: "Wapiti";
	parameter "Wapiti max energy: " var: wapiti_max_energy category: "Wapiti";
	parameter "Wapiti energy consumption: " var: wapiti_energy_consum category: "Wapiti";

	output {
		display map type: opengl {
			species tree;
			
			species wapiti aspect: icon;
		}
		
		display Population_information refresh: every(1000#cycles) {
			chart "Species evolution" type: series size: {1,0.5} position: {0, 0} {
				data "number_of_trees" value: nb_trees color: #blue;
				data "number_of_wapitis" value: nb_wapitis color: #red;
			}
		}
	
		monitor "Number of trees" value: nb_trees;
		monitor "Number of wapitis" value: nb_wapitis;
	}
}