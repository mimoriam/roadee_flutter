const publishableKey =
    "pk_test_51RI9CyRpgPtVkfaJxxhx5OeqsBwzNSVKnTk1WhcB6whsqbT4oMRvEco6ToghnM8ymGEQzgH7vuc0MrtPM4lRqWd600mA9s1LiV";
const secretKey =
    "sk_test_51RI9CyRpgPtVkfaJINJnPNrGvshbAGW8QZknU1zdPFqThsXm9xXiYfKEnGIIvnKRCHNr8nYFcrDaofJOa3BVaPdh00ECBaeiiS";

const mapBoxToken =
    "pk.eyJ1IjoibWltb3JpYSIsImEiOiJjbWE2b2Z4MjMwbm04MmxzZmlyaGtmOXduIn0.TraFSTz7MLoFqXtMiXPVLA";

const Map<int, String> serviceSelectedIndex = {0: "Towing", 1: "Flat Tire", 2: "Battery", 3: "Fuel"};

const Map<int, List<Map<String, int>>> serviceSelectedIndexPayment = {
  0: [
    {"Towing": 50},
  ],
  1: [
    {"Flat Tire": 50},
  ],
  2: [
    {"Battery": 50},
  ],
  3: [
    {"Fuel": 50},
  ],
};
