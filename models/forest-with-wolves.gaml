/**
* Name: finalproject
* Based on the internal empty template. 
* Author: Antoine MORTELIER & Louis DUTOIT
* Tags: 
*/

// Simulation avec les trois espèces, les loups, les arbres et les wapitis


model finalproject

global {
	
	// SIMULATION
	
	float step <- 1#minute;
	float surface <- 250#m;
	geometry shape <- square(surface);
	
	// TREE
	
	int nb_tree_init <- 300;
	
	int nb_trees -> {length(tree)};
	
	float tree_proba_spread <- 0.0001;
	
	// WAPITI
	
	int nb_wapiti_init <- 20;
	int nb_wapitis -> {length(wapiti)};
	
	float wapiti_max_energy <- 1.0;
	float wapiti_energy_consum <- 0.001;
	float wapiti_reproduction <- 0.004;
	
	string tree_at_location <- "tree_at_location";
	string not_available_location <- "not_available_location";
	
    predicate tree_location <- new_predicate(tree_at_location);
	predicate choose_tree <- new_predicate("choose a tree");
	predicate is_available <- new_predicate("eat tree");
	predicate can_eat_tree <- new_predicate("can eat tree");
	predicate find_tree <- new_predicate("find tree");
	predicate eat_tree <- new_predicate("eat tree");
	
	// WOLF
	
	int nb_wolf_init <- 1;
	int nb_wolves -> {length(wolf)};
	
	float wolf_max_energy <- 1.0;
	float wolf_energy_consum <- 0.001;
	float wolf_reproduction <- 0.001;
	
	string wapiti_at_location <- "wapiti_at_location";
	string no_wapiti_location <- "no_wapiti_location";
	
    predicate wapiti_location <- new_predicate(wapiti_at_location);
	predicate choose_wapiti <- new_predicate("choose a wapiti");
	predicate is_alive <- new_predicate("eat wapiti");
	predicate can_eat_wapiti <- new_predicate("can eat wapiti");
	predicate find_wapiti <- new_predicate("find wapiti");
	predicate eat_wapiti <- new_predicate("eat wapiti");
	
	init {
		create tree number: nb_tree_init;
		create wapiti number: nb_wapiti_init;
		create wolf number: nb_wolf_init;
	}
	
	reflex stop_simulation when: (nb_wapitis = 0) or (nb_wolves = 0) {
		do pause;
	}
}

// Espèce arbres

species tree {
	float max_perimeter <- 50.0 #m;
	float max_height <- rnd(30.0, 50.0) #m;
	float tree_grow<- rnd(0.08#cm, 0.1#cm);
	float size <- rnd(0.2 #m, 0.3 #m) max: max_height update: size + tree_grow;
	float proba_spread <- tree_proba_spread;
	bool can_spread <- true;

// Changement de couleur en fonction de l'age de l'arbre

	float colorChange <- 0.0 max: 1.0 update: colorChange+0.00005;
	rgb changingColor <- rgb(int(152 * (1 - colorChange)), 251, int(152 * (1 - colorChange))) update: rgb(int(152 * (1 - colorChange)), 251, int(152 * (1 - colorChange)));

// Gestion de la propagation des arbres

	reflex spread when: (size >= 1.0#m) and (flip(proba_spread)) and (can_spread = true) {
		int nb_seeds <- 4;
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

// Espèce animal, permet de faire hériter les espèces loup / wapiti

species animal skills: [moving] control: simple_bdi {
    
    float view_dist;
    float speed;
    point target;
    string sexe <- any(["male", "female"]);
    float proba_spread;
    rgb color <- sexe = "female" ? rgb(182, 165, 143) : rgb(155, 107, 89);
    
    // Gestion de l'énergie des animaux
    
	float max_energy;
	float energy_consum;
	int possible_reproduction;
    float energy <- rnd(max_energy) update: energy - energy_consum max: max_energy;
    
   
   // Reproduction selon la quantité d'énergie
    
    reflex reproduce when: ((energy > 0.6 and flip(proba_spread) and sexe="female" and possible_reproduction > 0) or (possible_reproduction <= -10 and flip(proba_spread))) {
    	int nb_child <- 1;
    	possible_reproduction <- possible_reproduction - 1;
		create species(self) number: nb_child {
			location <- myself.location;
			energy <- myself.energy / 2;
		}
		energy <- energy / 2;
    }
    
    reflex die when: energy <= 0 {
		do die;
	}
    
    aspect default {
      draw circle(200#cm) color: #black;
      draw circle(view_dist) color: color border: #black empty: true;
    }
}

// Gestion des wapitis, hérite d'animal

species wapiti parent: animal {
	float view_dist <- 20.0 #m;
    float speed <- 1.0#km/#h;
    image_file my_icon <- sexe = "female" ? image_file("../includes/data/wapiti-female.png") : image_file("../includes/data/wapiti-male.png");
    float proba_spread <- wapiti_reproduction;
    
    // ENERGY
	float max_energy <- wapiti_max_energy;
	float energy_consum <- wapiti_energy_consum;
	
	int possible_reproduction <- rnd(6, 10);
	
	// Les wapitis démarrent avec la volonté de trouver des arbres
	
	init {
        do add_desire(find_tree);
    }
    
    // Gestion de la perception des arbres
    perceive target: tree in: view_dist {
    	focus id: tree_at_location var:location;
	    ask myself {
	        do remove_intention(find_tree, false);
	    }
    }
    
    // Belief des wapitis
    rule belief: tree_location new_desire: is_available strength: 2.0;
    rule belief: eat_tree new_desire: can_eat_tree strength: 5.0;
    
    // Les wapitis se déplacent aléatoirement à la recherche d'un arbre
    plan lets_wander intention: find_tree  {
        do wander;
    }
    
 	// Permet aux wapitis de manger les arbres
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
    					size <- size - 0.5#cm;
    					myself.energy <- myself.energy + 0.1;
    				}
    			} else {
    				do add_belief(new_predicate(not_available_location, ["location_value"::target]));
    			}
    			target <- nil;
    		}
    	}
    }
    
    // Les wapitis cherchent l'arbre le plus proche
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
    
    aspect icon {
      draw my_icon size: 15;
      draw circle(view_dist) color: color border: #black empty: true;
    }
}

// Espèce loup, hérite d'animal

species wolf parent: animal {
	float view_dist <- 10.0 #m;
    float speed <- 0.8#km/#h;
    image_file my_icon <- image_file("../includes/data/wolf.png");
    float proba_spread <- wolf_reproduction;
    wapiti wapiti_perceived <- nil;
    
    // ENERGY
	float max_energy <- wolf_max_energy;
	float energy_consum <- wolf_energy_consum;
	
	int possible_reproduction <- -10;
	
	// Les loups démarrent avec la volonté de trouver des wapitis
	init {
        do add_desire(find_wapiti);
    }
    
    // Dès qu'un loup détecte un wapiti, il va sur sa position
    
    perceive target: wapiti where (each.energy > 0) in: view_dist {
    	focus id: wapiti_at_location var:location;
    	myself.wapiti_perceived <- self;
	    ask myself {
	        do remove_intention(find_wapiti, false);
	    }
    }
    
    // Belief des wapitis
    rule belief: wapiti_location new_desire: is_alive strength: 2.0;
    rule belief: eat_wapiti new_desire: can_eat_wapiti strength: 5.0;
    
    // Les loups se déplacent alétoirement jusqu'a trouver un wapiti
    plan lets_wander intention: find_wapiti {
        do wander;
    }
    
    // Les loups mangent les wapitis qu'ils croisent
    plan eat_wapiti intention: is_alive{
    	if (target = nil) {
    		do add_subintention(get_current_intention(), choose_wapiti, true);
    		do current_intention_on_hold();
    	} else {
    		do goto target: target;
    		if (target = location) {
    			wapiti current_wapiti <- wapiti first_with (target = each.location);
    			if (!dead(current_wapiti)) {
    				do add_belief(is_alive);
    				ask current_wapiti {
    					float wapiti_energy <- myself.energy + energy > max_energy ? max_energy : myself.energy + energy;
    					myself.energy <- wapiti_energy;
    					do die;
    				}
    			} else {
    				do add_belief(new_predicate(no_wapiti_location, ["location_value"::target]));
    			}
    			target <- nil;
    		}
    	}
    }
    
    // Les loups choisissent le wapiti le plus proche
    plan choose_closest_wapiti intention: choose_wapiti instantaneous: true {
    	list<point> possible_wapiti <- get_beliefs_with_name(wapiti_at_location) collect (point(get_predicate(mental_state (each)).values["location_value"]));
    	list<point> no_available_wapitis <- get_beliefs_with_name(no_wapiti_location) collect (point(get_predicate(mental_state (each)).values["location_value"]));
    	possible_wapiti <- possible_wapiti - no_available_wapitis;
    	if (empty(possible_wapiti)) {
    		do remove_intention(eat_wapiti, true);
    	} else {
    		target <- (possible_wapiti with_min_of (each distance_to self)).location;
    	}
    	do remove_intention(choose_wapiti, true);
    }
    
    aspect icon {
      draw my_icon size: 8;
      draw circle(view_dist) color: color border: #black empty: true;
    }
}

// Experiment

experiment TreeBdi type: gui {
	parameter "Initial number of trees: " var: nb_tree_init min: 0 max: 500 category: "Tree";
	parameter "Initial number of wapiti: " var: nb_wapiti_init min: 0 max: 50 category: "Wapiti";
	parameter "Wapiti max energy: " var: wapiti_max_energy category: "Wapiti";
	parameter "Wapiti energy consumption: " var: wapiti_energy_consum category: "Wapiti";
	parameter "Initial number of wolves: " var: nb_wolf_init min: 0 max: 50 category: "Wolf";
	parameter "Wolf max energy: " var: wolf_max_energy category: "Wolf";
	parameter "Wolf energy consumption: " var: wolf_energy_consum category: "Wolf";

	output {
		display map type: opengl {
			species tree;
			
			species wapiti aspect: icon;
			species wolf aspect: icon;
		}
		
		display Population_information refresh: every(200#cycles) {
			chart "Species evolution" type: series size: {1,0.5} position: {0, 0} {
				data "number_of_trees" value: nb_trees color: #green;
				data "number_of_wapitis" value: nb_wapitis color: rgb(155, 107, 89);
				data "number_of_wolves" value: nb_wolves color: #red;
			}
		}
//	
		monitor "Number of trees" value: nb_trees;
		monitor "Number of wapitis" value: nb_wapitis;
		monitor "Number of wolves" value: nb_wolves;
	}
}