/**
 * Meal class for storing nutrition data
 */
class Meal {
  /**
   * Create a new Meal
   * @param {string} name - Meal name (e.g., Breakfast, Lunch)
   * @param {string} description - Description of the meal
   * @param {number} calories - Total calories
   * @param {number} protein - Protein in grams
   * @param {number} carbs - Carbohydrates in grams
   * @param {number} fat - Fat in grams
   * @param {string} category - Meal category (breakfast, lunch, dinner, snack, dessert)
   * @param {Date} date - Date and time of meal
   */
  constructor(name, description, calories, protein, carbs, fat, category, date = new Date()) {
    this.id = Date.now().toString();
    this.name = name;
    this.description = description;
    this.calories = calories;
    this.protein = protein || 0;
    this.carbs = carbs || 0;
    this.fat = fat || 0;
    this.category = category;
    this.date = date instanceof Date ? date : new Date(date);
  }

  /**
   * Get a formatted date string
   * @returns {string} Formatted date string
   */
  getFormattedDate() {
    const options = { 
      weekday: 'short', 
      month: 'short', 
      day: 'numeric',
      hour: '2-digit',
      minute: '2-digit'
    };
    return this.date.toLocaleDateString('en-US', options);
  }

  /**
   * Get a formatted time string
   * @returns {string} Formatted time string
   */
  getFormattedTime() {
    const options = {
      hour: '2-digit',
      minute: '2-digit'
    };
    return this.date.toLocaleTimeString('en-US', options);
  }

  /**
   * Validate if the meal has all required fields
   * @returns {boolean} True if the meal is valid
   */
  isValid() {
    return (
      this.name && 
      this.name.trim() !== '' && 
      this.calories && 
      Number(this.calories) > 0 &&
      this.category
    );
  }
}

/**
 * NutritionTracker class to manage nutrition data
 */
class NutritionTracker {
  constructor() {
    this.meals = [];
    this.goals = {
      calories: 2000,
      protein: 120,
      carbs: 225,
      fat: 65
    };
    this.loadFromLocalStorage();
  }

  /**
   * Add a new meal to the tracker
   * @param {Meal} meal - The meal to add
   * @returns {boolean} True if the meal was added successfully
   */
  addMeal(meal) {
    if (meal.isValid()) {
      this.meals.push(meal);
      this.saveToLocalStorage();
      return true;
    }
    return false;
  }

  /**
   * Get all meals
   * @returns {Array} List of meals
   */
  getMeals() {
    return this.meals;
  }

  /**
   * Get meals for a specific date
   * @param {Date} date - The date to filter by
   * @returns {Array} List of meals for the given date
   */
  getMealsByDate(date) {
    const dateStr = this.formatDateKey(date);
    return this.meals.filter(meal => {
      return this.formatDateKey(meal.date) === dateStr;
    });
  }

  /**
   * Format a date as YYYY-MM-DD for filtering
   * @param {Date} date - Date to format
   * @returns {string} Formatted date
   */
  formatDateKey(date) {
    const d = new Date(date);
    const year = d.getFullYear();
    const month = String(d.getMonth() + 1).padStart(2, '0');
    const day = String(d.getDate()).padStart(2, '0');
    
    return `${year}-${month}-${day}`;
  }

  /**
   * Get nutrition summary for a specific date
   * @param {Date} date - The date to summarize
   * @returns {Object} Nutrition summary with calories, protein, carbs, fat
   */
  getNutritionSummaryByDate(date) {
    const meals = this.getMealsByDate(date);
    
    return meals.reduce((summary, meal) => {
      summary.calories += Number(meal.calories);
      summary.protein += Number(meal.protein);
      summary.carbs += Number(meal.carbs);
      summary.fat += Number(meal.fat);
      return summary;
    }, {
      calories: 0,
      protein: 0,
      carbs: 0,
      fat: 0
    });
  }

  /**
   * Get daily nutrition summaries for the past week
   * @returns {Array} Array of daily nutrition summaries
   */
  getWeeklyNutritionSummary() {
    const result = [];
    const today = new Date();
    
    for (let i = 6; i >= 0; i--) {
      const date = new Date(today);
      date.setDate(today.getDate() - i);
      
      const summary = this.getNutritionSummaryByDate(date);
      result.push({
        date: date,
        summary: summary
      });
    }
    
    return result;
  }

  /**
   * Get nutrition goals
   * @returns {Object} Nutrition goals
   */
  getGoals() {
    return this.goals;
  }

  /**
   * Update nutrition goals
   * @param {Object} newGoals - New nutrition goals
   */
  updateGoals(newGoals) {
    this.goals = {
      ...this.goals,
      ...newGoals
    };
    this.saveToLocalStorage();
  }

  /**
   * Save nutrition data to localStorage
   */
  saveToLocalStorage() {
    localStorage.setItem('nutritionMeals', JSON.stringify(this.meals));
    localStorage.setItem('nutritionGoals', JSON.stringify(this.goals));
  }

  /**
   * Load nutrition data from localStorage
   */
  loadFromLocalStorage() {
    try {
      const savedMeals = localStorage.getItem('nutritionMeals');
      const savedGoals = localStorage.getItem('nutritionGoals');
      
      if (savedMeals) {
        const parsedMeals = JSON.parse(savedMeals);
        this.meals = parsedMeals.map(meal => {
          return new Meal(
            meal.name,
            meal.description,
            meal.calories,
            meal.protein,
            meal.carbs,
            meal.fat,
            meal.category,
            new Date(meal.date)
          );
        });
      }
      
      if (savedGoals) {
        this.goals = JSON.parse(savedGoals);
      }
    } catch (error) {
      console.error('Error loading nutrition data from localStorage:', error);
    }
  }

  /**
   * Clear all nutrition tracking data
   */
  reset() {
    this.meals = [];
    this.goals = {
      calories: 2000,
      protein: 120,
      carbs: 225,
      fat: 65
    };
    this.saveToLocalStorage();
  }
}