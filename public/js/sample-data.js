/**
 * Sample data initializer for Health & Fitness Tracker
 * This adds example data for demonstration purposes when certain sections are empty
 */

/**
 * Initialize sample data for empty sections
 */
function initializeSampleData() {
  // Check if nutrition section is empty and add sample meals
  if (nutritionTracker.getMeals().length === 0) {
    addSampleMeals();
  }
  
  // Check if sleep section is empty and add sample sleep records
  if (sleepTracker.getSleepRecords().length === 0) {
    addSampleSleepRecords();
  }
  
  // Check if habits section is empty and add sample habits
  if (habitTracker.getHabits().length === 0) {
    addSampleHabits();
  }
  
  // Update the dashboard to reflect the new data
  updateDashboard();
}

/**
 * Add sample meals to the nutrition tracker
 */
function addSampleMeals() {
  console.log('Adding sample meals data...');
  
  // Create dates for the past week
  const today = new Date();
  const yesterday = new Date(today);
  yesterday.setDate(yesterday.getDate() - 1);
  const twoDaysAgo = new Date(today);
  twoDaysAgo.setDate(twoDaysAgo.getDate() - 2);
  const threeDaysAgo = new Date(today);
  threeDaysAgo.setDate(threeDaysAgo.getDate() - 3);
  
  // Sample breakfast
  const breakfast1 = new Meal(
    'Oatmeal with Berries',
    'Steel-cut oats with mixed berries and honey',
    350,
    12,
    45,
    6,
    'breakfast',
    new Date(today.setHours(8, 30, 0, 0))
  );
  
  // Sample lunch
  const lunch1 = new Meal(
    'Grilled Chicken Salad',
    'Grilled chicken breast with mixed greens, cherry tomatoes, and balsamic dressing',
    420,
    35,
    25,
    12,
    'lunch',
    new Date(today.setHours(13, 0, 0, 0))
  );
  
  // Sample dinner
  const dinner1 = new Meal(
    'Salmon with Roasted Vegetables',
    'Baked salmon fillet with roasted Brussels sprouts and sweet potatoes',
    580,
    40,
    30,
    24,
    'dinner',
    new Date(today.setHours(19, 0, 0, 0))
  );
  
  // Sample snack
  const snack1 = new Meal(
    'Greek Yogurt with Almonds',
    'Plain Greek yogurt with a handful of almonds and a drizzle of honey',
    220,
    18,
    15,
    10,
    'snack',
    new Date(today.setHours(16, 0, 0, 0))
  );
  
  // Yesterday's meals
  const breakfast2 = new Meal(
    'Scrambled Eggs with Toast',
    'Scrambled eggs with whole grain toast and avocado',
    390,
    22,
    30,
    15,
    'breakfast',
    new Date(yesterday.setHours(8, 15, 0, 0))
  );
  
  const lunch2 = new Meal(
    'Turkey Sandwich',
    'Turkey and cheese sandwich with lettuce, tomato on whole grain bread',
    450,
    28,
    40,
    14,
    'lunch',
    new Date(yesterday.setHours(12, 30, 0, 0))
  );
  
  // Two days ago meals
  const dinner2 = new Meal(
    'Vegetable Stir Fry',
    'Tofu and mixed vegetable stir fry with brown rice',
    420,
    20,
    50,
    12,
    'dinner',
    new Date(twoDaysAgo.setHours(19, 30, 0, 0))
  );
  
  // Add all meals to the tracker
  nutritionTracker.addMeal(breakfast1);
  nutritionTracker.addMeal(lunch1);
  nutritionTracker.addMeal(dinner1);
  nutritionTracker.addMeal(snack1);
  nutritionTracker.addMeal(breakfast2);
  nutritionTracker.addMeal(lunch2);
  nutritionTracker.addMeal(dinner2);
  
  console.log('Added sample meals:', nutritionTracker.getMeals().length);
}

/**
 * Add sample sleep records to the sleep tracker
 */
function addSampleSleepRecords() {
  console.log('Adding sample sleep records...');
  
  // Create dates for the past week
  const today = new Date();
  const yesterday = new Date(today);
  yesterday.setDate(yesterday.getDate() - 1);
  const twoDaysAgo = new Date(today);
  twoDaysAgo.setDate(twoDaysAgo.getDate() - 2);
  const threeDaysAgo = new Date(today);
  threeDaysAgo.setDate(threeDaysAgo.getDate() - 3);
  const fourDaysAgo = new Date(today);
  fourDaysAgo.setDate(fourDaysAgo.getDate() - 4);
  
  // Last night's sleep
  const sleepLast = new SleepRecord(
    new Date(yesterday.setHours(23, 0, 0, 0)),
    new Date(today.setHours(7, 30, 0, 0)),
    4,
    'Slept well overall',
    []
  );
  
  // Two nights ago
  const sleepTwoNights = new SleepRecord(
    new Date(twoDaysAgo.setHours(22, 30, 0, 0)),
    new Date(yesterday.setHours(6, 45, 0, 0)),
    3,
    'Woke up once during the night',
    ['Noise']
  );
  
  // Three nights ago
  const sleepThreeNights = new SleepRecord(
    new Date(threeDaysAgo.setHours(23, 15, 0, 0)),
    new Date(twoDaysAgo.setHours(7, 0, 0, 0)),
    5,
    'Excellent sleep',
    []
  );
  
  // Four nights ago
  const sleepFourNights = new SleepRecord(
    new Date(fourDaysAgo.setHours(22, 45, 0, 0)),
    new Date(threeDaysAgo.setHours(6, 30, 0, 0)),
    4,
    'Good sleep',
    []
  );
  
  // Add all sleep records to the tracker
  sleepTracker.addSleepRecord(sleepLast);
  sleepTracker.addSleepRecord(sleepTwoNights);
  sleepTracker.addSleepRecord(sleepThreeNights);
  sleepTracker.addSleepRecord(sleepFourNights);
  
  console.log('Added sample sleep records:', sleepTracker.getSleepRecords().length);
}

/**
 * Add sample habits to the habit tracker
 */
function addSampleHabits() {
  console.log('Adding sample habits...');
  
  // Habit 1: Social Media
  const habit1 = new BadHabit(
    'habit_' + Date.now(),
    'Excessive Social Media',
    'Spending too much time scrolling through social media feeds',
    'daily',
    'screen',
    'Boredom, waiting, morning routine',
    'Read a book, take a short walk, practice mindfulness',
    '08:00'
  );
  
  // Create a start date 10 days ago
  const startDate = new Date();
  startDate.setDate(startDate.getDate() - 10);
  habit1.startDate = startDate;
  
  // Add some check-ins for this habit
  const today = new Date();
  for (let i = 0; i < 7; i++) {
    const date = new Date(today);
    date.setDate(date.getDate() - i);
    // Alternating success pattern (more successes than failures)
    habit1.addCheckIn(date, i % 3 !== 0);
  }
  
  // Habit 2: Late-night snacking
  const habit2 = new BadHabit(
    'habit_' + (Date.now() + 1),
    'Late-night Snacking',
    'Eating unhealthy snacks after dinner',
    'daily',
    'food',
    'Watching TV at night, stress',
    'Drink herbal tea, brush teeth after dinner',
    '21:00'
  );
  
  // Set start date 15 days ago
  const startDate2 = new Date();
  startDate2.setDate(startDate2.getDate() - 15);
  habit2.startDate = startDate2;
  
  // Add some check-ins
  for (let i = 0; i < 5; i++) {
    const date = new Date(today);
    date.setDate(date.getDate() - i);
    // More successful recently
    habit2.addCheckIn(date, i < 3);
  }
  
  // Add habits to the tracker
  habitTracker.addHabit(habit1);
  habitTracker.addHabit(habit2);
  
  console.log('Added sample habits:', habitTracker.getHabits().length);
}

// Initialize sample data when the script loads
document.addEventListener('DOMContentLoaded', function() {
  // Wait a moment to ensure all trackers are initialized
  setTimeout(initializeSampleData, 500);
});