/**
 * Main application logic for the Health & Wellness Tracker
 */

// Initialize all trackers
console.log('Health & Wellness App Initializing...');

// Initialize the fitness tracker
const fitnessTracker = new FitnessTracker();
fitnessTracker.loadFromLocalStorage();
console.log('Fitness tracker loaded', fitnessTracker.getActivities().length, 'activities');

// Initialize the habit tracker
const habitTracker = new HabitTracker();
habitTracker.loadFromLocalStorage();
console.log('Habit tracker loaded', habitTracker.getHabits().length, 'habits');

// Initialize the nutrition tracker
const nutritionTracker = new NutritionTracker();
nutritionTracker.loadFromLocalStorage();
console.log('Nutrition tracker loaded', nutritionTracker.getMeals().length, 'meals');

// Initialize the sleep tracker
const sleepTracker = new SleepTracker();
sleepTracker.loadFromLocalStorage();
console.log('Sleep tracker loaded', sleepTracker.getSleepRecords().length, 'records');

// Initialize the health connection manager
const healthConnectionManager = new HealthConnectionManager();
healthConnectionManager.loadFromLocalStorage();
console.log('Health connections loaded', healthConnectionManager.getConnections().length, 'connections');

// Set up event listeners once the DOM is fully loaded
document.addEventListener('DOMContentLoaded', function() {
  // Set up event listeners for all forms
  setupEventListeners();
  
  // Update the dashboard with current data
  updateDashboard();
});

/**
 * Set up all event listeners for the application
 */
function setupEventListeners() {
  // Activity form
  const addActivityForm = document.getElementById('add-activity-form');
  if (addActivityForm) {
    addActivityForm.addEventListener('submit', handleActivityFormSubmit);
  }
  
  // Steps form
  const addStepsForm = document.getElementById('add-steps-form');
  if (addStepsForm) {
    addStepsForm.addEventListener('submit', handleStepsFormSubmit);
  }
  
  // Habit form
  const addHabitForm = document.getElementById('add-habit-form');
  if (addHabitForm) {
    addHabitForm.addEventListener('submit', handleHabitFormSubmit);
  }
  
  // Check-in form
  const habitCheckInForm = document.getElementById('habit-check-in-form');
  if (habitCheckInForm) {
    habitCheckInForm.addEventListener('submit', handleCheckInFormSubmit);
  }
  
  // Meal form
  const addMealForm = document.getElementById('add-meal-form');
  if (addMealForm) {
    addMealForm.addEventListener('submit', handleMealFormSubmit);
  }
  
  // Sleep form
  const addSleepForm = document.getElementById('add-sleep-form');
  if (addSleepForm) {
    addSleepForm.addEventListener('submit', handleSleepFormSubmit);
  }
  
  // Connection form
  const addConnectionForm = document.getElementById('add-connection-form');
  if (addConnectionForm) {
    addConnectionForm.addEventListener('submit', handleConnectionFormSubmit);
  }
  
  // Connection type selector
  const connectionType = document.getElementById('connection-type');
  if (connectionType) {
    connectionType.addEventListener('change', function() {
      // Hide all specific fields
      document.getElementById('apple-health-fields').style.display = 'none';
      document.getElementById('google-fit-fields').style.display = 'none';
      document.getElementById('fitness-watch-fields').style.display = 'none';
      
      // Show fields for selected connection type
      const selectedType = this.value;
      if (selectedType === 'apple-health') {
        document.getElementById('apple-health-fields').style.display = 'block';
      } else if (selectedType === 'google-fit') {
        document.getElementById('google-fit-fields').style.display = 'block';
      } else if (selectedType === 'fitness-watch') {
        document.getElementById('fitness-watch-fields').style.display = 'block';
      }
    });
  }
  
  // Connect buttons
  const connectButtons = document.querySelectorAll('.btn-connect');
  connectButtons.forEach(button => {
    button.addEventListener('click', function() {
      const service = this.getAttribute('data-service');
      document.getElementById('connection-type').value = service;
      
      // Trigger the change event to show/hide appropriate fields
      const event = new Event('change');
      document.getElementById('connection-type').dispatchEvent(event);
      
      // Show the modal
      const modal = new bootstrap.Modal(document.getElementById('addConnectionModal'));
      modal.show();
    });
  });
}

/**
 * Handle the activity form submission
 * @param {Event} event - Form submission event
 */
function handleActivityFormSubmit(event) {
  event.preventDefault();
  
  const name = document.getElementById('activity-name').value;
  const calories = parseInt(document.getElementById('activity-calories').value);
  const duration = parseInt(document.getElementById('activity-duration').value);
  const type = document.getElementById('activity-type').value;
  
  const activity = new Activity(name, calories, duration, type);
  
  if (fitnessTracker.addActivity(activity)) {
    // Update the UI
    updateDashboard();
    
    // Reset the form
    event.target.reset();
    
    // Hide the modal
    const modal = bootstrap.Modal.getInstance(document.getElementById('logActivityModal'));
    modal.hide();
    
    // Show success message
    showMessage('Activity added successfully!', 'success');
  } else {
    showMessage('Please fill in all fields correctly.', 'danger');
  }
}

/**
 * Handle the steps form submission
 * @param {Event} event - Form submission event
 */
function handleStepsFormSubmit(event) {
  event.preventDefault();
  
  const steps = parseInt(document.getElementById('steps-count-input').value);
  
  if (fitnessTracker.addSteps(steps)) {
    // Update the UI
    updateDashboard();
    
    // Reset the form
    event.target.reset();
    
    // Hide the modal
    const modal = bootstrap.Modal.getInstance(document.getElementById('addStepsModal'));
    modal.hide();
    
    // Show success message
    showMessage('Steps added successfully!', 'success');
  } else {
    showMessage('Please enter a valid number of steps.', 'danger');
  }
}

/**
 * Handle the habit form submission
 * @param {Event} event - Form submission event
 */
function handleHabitFormSubmit(event) {
  event.preventDefault();
  
  const name = document.getElementById('habit-name').value;
  const description = document.getElementById('habit-description').value;
  const frequency = document.getElementById('habit-frequency').value;
  const category = document.getElementById('habit-category').value;
  const trigger = document.getElementById('habit-trigger').value;
  const alternative = document.getElementById('habit-alternative').value;
  const reminderTime = document.getElementById('habit-reminder-time').value;
  
  const habitId = 'habit_' + Date.now();
  const habit = new BadHabit(
    habitId,
    name,
    description,
    frequency,
    category,
    trigger,
    alternative,
    reminderTime
  );
  
  if (habitTracker.addHabit(habit)) {
    // Update the UI
    updateDashboard();
    
    // Reset the form
    event.target.reset();
    
    // Hide the modal
    const modal = bootstrap.Modal.getInstance(document.getElementById('addHabitModal'));
    modal.hide();
    
    // Show success message
    showMessage('Habit added successfully!', 'success');
  } else {
    showMessage('Please fill in all required fields.', 'danger');
  }
}

/**
 * Handle the habit check-in form submission
 * @param {Event} event - Form submission event
 */
function handleCheckInFormSubmit(event) {
  event.preventDefault();
  
  const habitId = document.getElementById('check-in-habit-id').value;
  const success = document.getElementById('check-in-success-yes').checked;
  const dateStr = document.getElementById('check-in-date').value;
  const date = new Date(dateStr);
  
  const result = habitTracker.recordCheckIn(habitId, date, success);
  
  if (result) {
    // Update the UI
    updateDashboard();
    
    // Reset the form
    event.target.reset();
    
    // Hide the modal
    const modal = bootstrap.Modal.getInstance(document.getElementById('check-in-modal'));
    modal.hide();
    
    // Show success message
    showMessage('Check-in recorded successfully!', 'success');
  } else {
    showMessage('Unable to record check-in. Please try again.', 'danger');
  }
}

/**
 * Delete a habit
 * @param {string} habitId - ID of the habit to delete
 */
function deleteHabit(habitId) {
  if (confirm('Are you sure you want to delete this habit?')) {
    if (habitTracker.deleteHabit(habitId)) {
      updateDashboard();
      showMessage('Habit deleted successfully!', 'success');
    } else {
      showMessage('Unable to delete habit. Please try again.', 'danger');
    }
  }
}

/**
 * Open the check-in modal for a habit
 * @param {string} habitId - ID of the habit to check in
 * @param {string} habitName - Name of the habit to display
 */
function openCheckInModal(habitId, habitName) {
  // Set the habit ID in the form
  document.getElementById('check-in-habit-id').value = habitId;
  
  // Set the title
  const modalTitle = document.querySelector('#check-in-modal .modal-title');
  modalTitle.textContent = `Check-in: ${habitName}`;
  
  // Set today's date
  const today = new Date();
  const yyyy = today.getFullYear();
  const mm = String(today.getMonth() + 1).padStart(2, '0');
  const dd = String(today.getDate()).padStart(2, '0');
  document.getElementById('check-in-date').value = `${yyyy}-${mm}-${dd}`;
  
  // Show the modal
  const modal = new bootstrap.Modal(document.getElementById('check-in-modal'));
  modal.show();
}

/**
 * Handle the meal form submission
 * @param {Event} event - Form submission event
 */
function handleMealFormSubmit(event) {
  event.preventDefault();
  
  const name = document.getElementById('meal-name').value;
  const description = document.getElementById('meal-description').value;
  const calories = parseInt(document.getElementById('meal-calories').value);
  const protein = parseInt(document.getElementById('meal-protein').value || '0');
  const carbs = parseInt(document.getElementById('meal-carbs').value || '0');
  const fat = parseInt(document.getElementById('meal-fat').value || '0');
  const category = document.getElementById('meal-category').value;
  
  // Get the date from the time input
  const timeStr = document.getElementById('meal-time').value || '12:00';
  const now = new Date();
  const [hours, minutes] = timeStr.split(':');
  now.setHours(parseInt(hours), parseInt(minutes), 0, 0);
  
  const meal = new Meal(name, description, calories, protein, carbs, fat, category, now);
  
  if (nutritionTracker.addMeal(meal)) {
    // Update the UI
    updateDashboard();
    
    // Reset the form
    event.target.reset();
    
    // Hide the modal
    const modal = bootstrap.Modal.getInstance(document.getElementById('addMealModal'));
    modal.hide();
    
    // Show success message
    showMessage('Meal added successfully!', 'success');
  } else {
    showMessage('Please fill in all required fields.', 'danger');
  }
}

/**
 * Handle the sleep form submission
 * @param {Event} event - Form submission event
 */
function handleSleepFormSubmit(event) {
  event.preventDefault();
  
  const dateStr = document.getElementById('sleep-date').value;
  const bedtimeStr = document.getElementById('sleep-bedtime').value;
  const waketimeStr = document.getElementById('sleep-waketime').value;
  const quality = parseInt(document.getElementById('sleep-quality').value);
  
  // Create Date objects for bedtime and waketime
  const [year, month, day] = dateStr.split('-');
  const [bedHours, bedMinutes] = bedtimeStr.split(':');
  const [wakeHours, wakeMinutes] = waketimeStr.split(':');
  
  const bedtime = new Date(year, month - 1, day, bedHours, bedMinutes);
  
  // If waketime is earlier than bedtime, assume it's the next day
  let waketime = new Date(year, month - 1, day, wakeHours, wakeMinutes);
  if (waketime < bedtime) {
    waketime.setDate(waketime.getDate() + 1);
  }
  
  // Get any selected disturbances
  const disturbances = [];
  const selectedDisturbance = document.querySelector('input[name="sleep-disturbances"]:checked').value;
  if (selectedDisturbance !== 'none') {
    disturbances.push(selectedDisturbance);
  }
  
  // Create a notes string from any additional notes
  const notes = document.getElementById('sleep-notes')?.value || '';
  
  const sleepRecord = new SleepRecord(bedtime, waketime, quality, notes, disturbances);
  
  if (sleepTracker.addSleepRecord(sleepRecord)) {
    // Update the UI
    updateDashboard();
    
    // Reset the form
    event.target.reset();
    
    // Hide the modal
    const modal = bootstrap.Modal.getInstance(document.getElementById('addSleepModal'));
    modal.hide();
    
    // Show success message
    showMessage('Sleep record added successfully!', 'success');
  } else {
    showMessage('Please fill in all required fields.', 'danger');
  }
}

/**
 * Handle connection form submission
 * @param {Event} event - Form submission event
 */
function handleConnectionFormSubmit(event) {
  event.preventDefault();
  
  const connectionType = document.getElementById('connection-type').value;
  const syncFrequency = document.getElementById('sync-frequency').value;
  
  // Get settings and data types based on the connection type
  let settings = {};
  let dataTypes = [];
  
  if (connectionType === 'apple-health') {
    dataTypes = [];
    if (document.getElementById('apple-steps').checked) dataTypes.push('steps');
    if (document.getElementById('apple-workouts').checked) dataTypes.push('workouts');
    if (document.getElementById('apple-sleep').checked) dataTypes.push('sleep');
    if (document.getElementById('apple-nutrition').checked) dataTypes.push('nutrition');
  } 
  else if (connectionType === 'google-fit') {
    dataTypes = [];
    if (document.getElementById('google-steps').checked) dataTypes.push('steps');
    if (document.getElementById('google-workouts').checked) dataTypes.push('workouts');
    if (document.getElementById('google-sleep').checked) dataTypes.push('sleep');
    if (document.getElementById('google-nutrition').checked) dataTypes.push('nutrition');
  } 
  else if (connectionType === 'fitness-watch') {
    const brand = document.getElementById('watch-brand').value;
    settings = { brand };
    
    dataTypes = [];
    if (document.getElementById('watch-steps').checked) dataTypes.push('steps');
    if (document.getElementById('watch-workouts').checked) dataTypes.push('workouts');
    if (document.getElementById('watch-sleep').checked) dataTypes.push('sleep');
    if (document.getElementById('watch-heart-rate').checked) dataTypes.push('heart-rate');
  }
  
  // Create a connection
  const connection = new HealthConnection(connectionType, settings, dataTypes, syncFrequency);
  
  // Show connecting message
  showMessage('Connecting to health data source...', 'info');
  
  // Add the connection
  healthConnectionManager.addConnection(connection)
    .then(result => {
      updateConnectionsView();
      updateDashboard();
      
      // Reset the form
      event.target.reset();
      
      // Hide the modal
      const modal = bootstrap.Modal.getInstance(document.getElementById('addConnectionModal'));
      modal.hide();
      
      // Show success message
      showMessage(`Successfully connected to ${connection.getDisplayName()}`, 'success');
    })
    .catch(error => {
      console.error('Connection error:', error);
      showMessage('Failed to connect. Please try again.', 'danger');
    });
}

/**
 * Update the dashboard with current data
 */
function updateDashboard() {
  updateFitnessStats();
  updateActivitiesList();
  updateHabitStats();
  updateHabitsList();
  updateNutritionStats();
  updateMealsList();
  updateNutritionChart();
  updateSleepStats();
  updateSleepRecordsList();
  updateSleepChart();
  updateConnectionsView();
}

/**
 * Update fitness statistics on the dashboard
 */
function updateFitnessStats() {
  const stepsCount = document.getElementById('steps-count');
  const caloriesCount = document.getElementById('calories-count');
  const activitiesCount = document.getElementById('activities-count');
  
  if (stepsCount) stepsCount.textContent = fitnessTracker.getTotalSteps().toLocaleString();
  if (caloriesCount) caloriesCount.textContent = fitnessTracker.getTotalCalories().toLocaleString();
  if (activitiesCount) activitiesCount.textContent = fitnessTracker.getActivitiesCount().toString();
}

/**
 * Update the activities list on the dashboard
 */
function updateActivitiesList() {
  const activitiesList = document.getElementById('activities-list');
  const noActivities = document.getElementById('no-activities');
  const allActivitiesList = document.getElementById('all-activities-list');
  const noAllActivities = document.getElementById('no-all-activities');
  
  const activities = fitnessTracker.getActivities();
  
  // Update the dashboard activities list (recent activities only)
  if (activitiesList && noActivities) {
    if (activities.length === 0) {
      activitiesList.style.display = 'none';
      noActivities.style.display = 'block';
    } else {
      activitiesList.style.display = 'block';
      noActivities.style.display = 'none';
      
      // Clear the list
      activitiesList.innerHTML = '';
      
      // Add recent activities (up to 5)
      const recentActivities = activities.slice(0, 5);
      
      recentActivities.forEach(activity => {
        const activityElement = document.createElement('div');
        activityElement.className = 'card mb-2';
        activityElement.innerHTML = `
          <div class="card-body">
            <div class="d-flex justify-content-between align-items-center">
              <div>
                <h6 class="mb-1">${activity.name}</h6>
                <p class="text-muted mb-0 small">${activity.getFormattedDate()} | ${activity.duration} mins | ${activity.type}</p>
              </div>
              <div>
                <span class="badge bg-primary rounded-pill">${activity.calories} cal</span>
              </div>
            </div>
          </div>
        `;
        
        activitiesList.appendChild(activityElement);
      });
    }
  }
  
  // Update the all activities list (for the Activity tab)
  if (allActivitiesList && noAllActivities) {
    if (activities.length === 0) {
      allActivitiesList.style.display = 'none';
      noAllActivities.style.display = 'block';
    } else {
      allActivitiesList.style.display = 'block';
      noAllActivities.style.display = 'none';
      
      // Clear the list
      allActivitiesList.innerHTML = '';
      
      // Sort activities by date (newest first)
      const sortedActivities = [...activities].sort((a, b) => b.date - a.date);
      
      sortedActivities.forEach(activity => {
        const activityElement = document.createElement('div');
        activityElement.className = 'card mb-2';
        activityElement.innerHTML = `
          <div class="card-body">
            <div class="d-flex justify-content-between align-items-center">
              <div>
                <h6 class="mb-1">${activity.name}</h6>
                <p class="text-muted mb-0 small">${activity.getFormattedDate()} | ${activity.duration} mins | ${activity.type}</p>
              </div>
              <div>
                <span class="badge bg-primary rounded-pill">${activity.calories} cal</span>
              </div>
            </div>
          </div>
        `;
        
        allActivitiesList.appendChild(activityElement);
      });
    }
  }
}

/**
 * Update habit statistics on the dashboard
 */
function updateHabitStats() {
  const habitsCount = document.getElementById('habits-count');
  const currentStreakCount = document.getElementById('current-streak-count');
  const successRateCount = document.getElementById('success-rate-count');
  
  const stats = habitTracker.getOverallProgress() || { currentStreak: 0, bestStreak: 0, successRate: 0 };
  
  if (habitsCount) habitsCount.textContent = habitTracker.getHabits().length.toString();
  if (currentStreakCount) currentStreakCount.textContent = (stats.currentStreak || 0).toString();
  if (successRateCount) successRateCount.textContent = `${Math.round(stats.successRate || 0)}%`;
}

/**
 * Update the habits list on the dashboard
 */
function updateHabitsList() {
  const habitsList = document.getElementById('habits-list');
  const noHabits = document.getElementById('no-habits');
  const allHabitsList = document.getElementById('all-habits-list');
  const noAllHabits = document.getElementById('no-all-habits');
  
  const habits = habitTracker.getHabits();
  
  // Update the dashboard habits list (recent habits only)
  if (habitsList && noHabits) {
    if (habits.length === 0) {
      habitsList.style.display = 'none';
      noHabits.style.display = 'block';
    } else {
      habitsList.style.display = 'block';
      noHabits.style.display = 'none';
      
      // Clear the list
      habitsList.innerHTML = '';
      
      // Add recent habits (up to 3)
      const recentHabits = habits.slice(0, 3);
      
      recentHabits.forEach(habit => {
        const habitElement = createHabitElement(habit);
        habitsList.appendChild(habitElement);
      });
    }
  }
  
  // Update the all habits list (for the Habits tab)
  if (allHabitsList && noAllHabits) {
    if (habits.length === 0) {
      allHabitsList.style.display = 'none';
      noAllHabits.style.display = 'block';
    } else {
      allHabitsList.style.display = 'block';
      noAllHabits.style.display = 'none';
      
      // Clear the list
      allHabitsList.innerHTML = '';
      
      // Sort habits by date (newest first)
      const sortedHabits = [...habits].sort((a, b) => b.startDate - a.startDate);
      
      sortedHabits.forEach(habit => {
        const habitElement = createHabitElement(habit, true);
        allHabitsList.appendChild(habitElement);
      });
    }
  }
}

/**
 * Create a habit element to display
 * @param {BadHabit} habit - The habit to create an element for
 * @param {boolean} showDetails - Whether to show additional details
 * @returns {HTMLElement} The created element
 */
function createHabitElement(habit, showDetails = false) {
  const element = document.createElement('div');
  element.className = 'card mb-3';
  
  const streakInfo = habit.updateStreaks();
  const weeklyProgress = habit.getWeeklyProgress();
  
  let progressHtml = '';
  for (let i = 6; i >= 0; i--) {
    const day = new Date();
    day.setDate(day.getDate() - i);
    const dateKey = habit.formatDateKey(day);
    
    const dayName = ['S', 'M', 'T', 'W', 'T', 'F', 'S'][day.getDay()];
    let statusClass = 'bg-light';
    
    if (weeklyProgress[dateKey] === true) {
      statusClass = 'bg-success';
    } else if (weeklyProgress[dateKey] === false) {
      statusClass = 'bg-danger';
    }
    
    progressHtml += `
      <div class="col px-1">
        <div class="text-center small text-muted">${dayName}</div>
        <div class="rounded-circle ${statusClass}" style="width: 20px; height: 20px; margin: 0 auto;"></div>
      </div>
    `;
  }
  
  let detailsHtml = '';
  if (showDetails) {
    detailsHtml = `
      <div class="mt-3">
        <div class="d-flex justify-content-between small text-muted mb-2">
          <div>Category: ${habit.category}</div>
          <div>Frequency: ${habit.frequency}</div>
        </div>
        <div class="small text-muted mb-2">Tracking for: ${habit.getDaysSinceStart()} days</div>
        <p class="small mb-0">${habit.description}</p>
        
        ${habit.trigger ? `<p class="small mb-0"><strong>Trigger:</strong> ${habit.trigger}</p>` : ''}
        ${habit.alternative ? `<p class="small mb-0"><strong>Alternative:</strong> ${habit.alternative}</p>` : ''}
      </div>
    `;
  }
  
  element.innerHTML = `
    <div class="card-body">
      <div class="d-flex justify-content-between align-items-center">
        <h6 class="mb-0">${habit.name}</h6>
        <div>
          <button class="btn btn-sm btn-outline-primary me-1" onclick="openCheckInModal('${habit.id}', '${habit.name}')">
            Check-in
          </button>
          
          ${showDetails ? `
            <button class="btn btn-sm btn-outline-danger" onclick="deleteHabit('${habit.id}')">
              <i class="bi bi-trash"></i>
            </button>
          ` : ''}
        </div>
      </div>
      
      <div class="mt-2 d-flex justify-content-between align-items-center">
        <div class="small text-muted">Current streak: ${streakInfo.currentStreak} days</div>
        <div class="small text-muted">Best: ${streakInfo.bestStreak} days</div>
      </div>
      
      <div class="mt-2">
        <div class="row g-0">
          ${progressHtml}
        </div>
      </div>
      
      ${detailsHtml}
    </div>
  `;
  
  return element;
}

/**
 * Update nutrition statistics
 */
function updateNutritionStats() {
  const nutritionCalories = document.getElementById('nutrition-calories');
  const nutritionProtein = document.getElementById('nutrition-protein');
  const nutritionCarbs = document.getElementById('nutrition-carbs');
  const nutritionFat = document.getElementById('nutrition-fat');
  
  const todaySummary = nutritionTracker.getNutritionSummaryByDate(new Date());
  
  if (nutritionCalories) nutritionCalories.textContent = todaySummary.calories.toString();
  if (nutritionProtein) nutritionProtein.textContent = `${todaySummary.protein}g`;
  if (nutritionCarbs) nutritionCarbs.textContent = `${todaySummary.carbs}g`;
  if (nutritionFat) nutritionFat.textContent = `${todaySummary.fat}g`;
}

/**
 * Update meals list
 */
function updateMealsList() {
  const mealsList = document.getElementById('meals-list');
  
  if (!mealsList) return;
  
  // Get today's meals
  const today = new Date();
  const meals = nutritionTracker.getMealsByDate(today);
  
  // Clear the list
  mealsList.innerHTML = '';
  
  if (meals.length === 0) {
    mealsList.innerHTML = `
      <div class="text-center py-4">
        <p class="text-muted">No meals logged yet today.</p>
        <button class="btn btn-primary" data-bs-toggle="modal" data-bs-target="#addMealModal">
          Log Your First Meal
        </button>
      </div>
    `;
  } else {
    // Sort meals by time (earliest first)
    const sortedMeals = [...meals].sort((a, b) => a.date - b.date);
    
    // Add each meal
    sortedMeals.forEach(meal => {
      const mealElement = document.createElement('div');
      mealElement.className = 'card mb-2';
      mealElement.innerHTML = `
        <div class="card-body">
          <div class="d-flex justify-content-between align-items-center">
            <div>
              <h6 class="mb-1">${meal.name}</h6>
              <p class="text-muted mb-0 small">${meal.getFormattedTime()} | ${meal.category} | ${meal.description || '-'}</p>
            </div>
            <div>
              <span class="badge bg-primary rounded-pill">${meal.calories} cal</span>
            </div>
          </div>
          
          <div class="mt-2 d-flex">
            <div class="me-3 small">
              <span class="text-primary">P:</span> ${meal.protein}g
            </div>
            <div class="me-3 small">
              <span class="text-primary">C:</span> ${meal.carbs}g
            </div>
            <div class="small">
              <span class="text-primary">F:</span> ${meal.fat}g
            </div>
          </div>
        </div>
      `;
      
      mealsList.appendChild(mealElement);
    });
  }
}

/**
 * Update nutrition chart
 */
function updateNutritionChart() {
  const chartCanvas = document.getElementById('nutrition-chart');
  
  if (!chartCanvas) return;
  
  const ctx = chartCanvas.getContext('2d');
  
  // Get the weekly nutrition data
  const weeklyData = nutritionTracker.getWeeklyNutritionSummary();
  
  // Prepare data for Chart.js
  const labels = weeklyData.map(day => {
    const date = new Date(day.date);
    return date.toLocaleDateString('en-US', { weekday: 'short' });
  });
  
  const caloriesData = weeklyData.map(day => day.calories);
  const proteinData = weeklyData.map(day => day.protein);
  const carbsData = weeklyData.map(day => day.carbs);
  const fatData = weeklyData.map(day => day.fat);
  
  // Create or update the chart
  if (window.nutritionChart) {
    window.nutritionChart.data.labels = labels;
    window.nutritionChart.data.datasets[0].data = caloriesData;
    window.nutritionChart.data.datasets[1].data = proteinData;
    window.nutritionChart.data.datasets[2].data = carbsData;
    window.nutritionChart.data.datasets[3].data = fatData;
    window.nutritionChart.update();
  } else {
    window.nutritionChart = new Chart(ctx, {
      type: 'bar',
      data: {
        labels: labels,
        datasets: [
          {
            label: 'Calories',
            data: caloriesData,
            backgroundColor: 'rgba(255, 99, 132, 0.5)',
            borderColor: 'rgb(255, 99, 132)',
            borderWidth: 1,
            yAxisID: 'y'
          },
          {
            label: 'Protein (g)',
            data: proteinData,
            backgroundColor: 'rgba(54, 162, 235, 0.5)',
            borderColor: 'rgb(54, 162, 235)',
            borderWidth: 1,
            yAxisID: 'y1'
          },
          {
            label: 'Carbs (g)',
            data: carbsData,
            backgroundColor: 'rgba(255, 206, 86, 0.5)',
            borderColor: 'rgb(255, 206, 86)',
            borderWidth: 1,
            yAxisID: 'y1'
          },
          {
            label: 'Fat (g)',
            data: fatData,
            backgroundColor: 'rgba(75, 192, 192, 0.5)',
            borderColor: 'rgb(75, 192, 192)',
            borderWidth: 1,
            yAxisID: 'y1'
          }
        ]
      },
      options: {
        responsive: true,
        interaction: {
          mode: 'index',
          intersect: false,
        },
        scales: {
          y: {
            type: 'linear',
            display: true,
            position: 'left',
            title: {
              display: true,
              text: 'Calories'
            }
          },
          y1: {
            type: 'linear',
            display: true,
            position: 'right',
            title: {
              display: true,
              text: 'Macros (g)'
            },
            grid: {
              drawOnChartArea: false,
            },
          }
        }
      }
    });
  }
}

/**
 * Update sleep statistics
 */
function updateSleepStats() {
  const sleepDuration = document.getElementById('sleep-duration');
  const sleepQuality = document.getElementById('sleep-quality');
  const sleepConsistency = document.getElementById('sleep-consistency');
  
  const stats = sleepTracker.getStats();
  
  if (sleepDuration) sleepDuration.textContent = `${stats.averageDuration.toFixed(1)} hrs`;
  if (sleepQuality) sleepQuality.textContent = `${Math.round(stats.averageQuality * 20)}%`;
  if (sleepConsistency) sleepConsistency.textContent = `${Math.round(stats.consistency)}%`;
}

/**
 * Update the sleep records list
 */
function updateSleepRecordsList() {
  const sleepRecordsList = document.getElementById('sleep-records-list');
  
  if (!sleepRecordsList) return;
  
  // Get all sleep records
  const records = sleepTracker.getSleepRecords();
  
  // Clear the list
  sleepRecordsList.innerHTML = '';
  
  if (records.length === 0) {
    sleepRecordsList.innerHTML = `
      <div class="text-center py-4">
        <p class="text-muted">No sleep records logged yet.</p>
        <button class="btn btn-primary" data-bs-toggle="modal" data-bs-target="#addSleepModal">
          Log Your First Sleep Record
        </button>
      </div>
    `;
  } else {
    // Sort records by date (newest first)
    const sortedRecords = [...records].sort((a, b) => b.startTime - a.startTime);
    
    // Add recent records (up to 5)
    const recentRecords = sortedRecords.slice(0, 5);
    
    recentRecords.forEach(record => {
      const recordElement = document.createElement('div');
      recordElement.className = 'card mb-2';
      
      const duration = record.getDuration().toFixed(1);
      const qualityDesc = record.getQualityDescription();
      const qualityStars = '★'.repeat(record.quality) + '☆'.repeat(5 - record.quality);
      
      recordElement.innerHTML = `
        <div class="card-body">
          <div class="d-flex justify-content-between align-items-center">
            <div>
              <h6 class="mb-1">${record.getFormattedDate()}</h6>
              <p class="text-muted mb-0 small">
                Bedtime: ${record.getFormattedTime(record.startTime)} | 
                Wake: ${record.getFormattedTime(record.endTime)}
              </p>
            </div>
            <div class="text-end">
              <span class="badge bg-primary rounded-pill">${duration} hrs</span>
              <div class="small text-warning">${qualityStars}</div>
            </div>
          </div>
          
          ${record.notes || record.disturbances.length > 0 ? `
            <div class="mt-2 small">
              ${record.disturbances.length > 0 ? `<div>Disturbances: ${record.disturbances.join(', ')}</div>` : ''}
              ${record.notes ? `<div>Notes: ${record.notes}</div>` : ''}
            </div>
          ` : ''}
          
          <div class="mt-2">
            <button class="btn btn-sm btn-outline-danger" onclick="deleteSleepRecord('${record.id}')">
              <i class="bi bi-trash"></i>
            </button>
          </div>
        </div>
      `;
      
      sleepRecordsList.appendChild(recordElement);
    });
  }
}

/**
 * Update the sleep chart
 */
function updateSleepChart() {
  const chartCanvas = document.getElementById('sleep-chart');
  
  if (!chartCanvas) return;
  
  const ctx = chartCanvas.getContext('2d');
  
  // Get the weekly sleep data
  const weeklyData = sleepTracker.getWeeklySleepSummary();
  
  // Prepare data for Chart.js
  const labels = weeklyData.map(day => {
    const date = new Date(day.date);
    return date.toLocaleDateString('en-US', { weekday: 'short' });
  });
  
  const durationData = weeklyData.map(day => day.duration);
  const qualityData = weeklyData.map(day => day.quality * 20); // Convert 1-5 to percentage
  
  // Create or update the chart
  if (window.sleepChart) {
    window.sleepChart.data.labels = labels;
    window.sleepChart.data.datasets[0].data = durationData;
    window.sleepChart.data.datasets[1].data = qualityData;
    window.sleepChart.update();
  } else {
    window.sleepChart = new Chart(ctx, {
      type: 'bar',
      data: {
        labels: labels,
        datasets: [
          {
            label: 'Duration (hours)',
            data: durationData,
            backgroundColor: 'rgba(75, 192, 192, 0.5)',
            borderColor: 'rgb(75, 192, 192)',
            borderWidth: 1,
            yAxisID: 'y'
          },
          {
            type: 'line',
            label: 'Quality (%)',
            data: qualityData,
            backgroundColor: 'rgba(255, 159, 64, 0.5)',
            borderColor: 'rgb(255, 159, 64)',
            borderWidth: 2,
            yAxisID: 'y1',
            tension: 0.1
          }
        ]
      },
      options: {
        responsive: true,
        interaction: {
          mode: 'index',
          intersect: false,
        },
        scales: {
          y: {
            type: 'linear',
            display: true,
            position: 'left',
            title: {
              display: true,
              text: 'Hours'
            },
            suggestedMin: 0,
            suggestedMax: 10
          },
          y1: {
            type: 'linear',
            display: true,
            position: 'right',
            title: {
              display: true,
              text: 'Quality (%)'
            },
            min: 0,
            max: 100,
            grid: {
              drawOnChartArea: false,
            },
          }
        }
      }
    });
  }
}

/**
 * Delete a sleep record
 * @param {string} recordId - ID of the record to delete
 */
function deleteSleepRecord(recordId) {
  if (confirm('Are you sure you want to delete this sleep record?')) {
    if (sleepTracker.deleteSleepRecord(recordId)) {
      updateDashboard();
      showMessage('Sleep record deleted successfully!', 'success');
    } else {
      showMessage('Unable to delete sleep record. Please try again.', 'danger');
    }
  }
}

/**
 * Update the connections view
 */
function updateConnectionsView() {
  const connectedDevicesList = document.getElementById('connected-devices-list');
  const noConnectedDevices = document.getElementById('no-connected-devices');
  const lastSyncTime = document.getElementById('last-sync-time');
  const syncedWorkoutsCount = document.getElementById('synced-workouts-count');
  const syncedStepsCount = document.getElementById('synced-steps-count');
  const syncedCaloriesCount = document.getElementById('synced-calories-count');
  
  const connections = healthConnectionManager.getConnections();
  const stats = healthConnectionManager.getAggregateStats();
  
  // Update stats
  if (lastSyncTime) {
    lastSyncTime.textContent = stats.lastSync ? new Date(stats.lastSync).toLocaleString() : 'Never';
  }
  if (syncedWorkoutsCount) syncedWorkoutsCount.textContent = stats.workouts.toString();
  if (syncedStepsCount) syncedStepsCount.textContent = stats.steps.toLocaleString();
  if (syncedCaloriesCount) syncedCaloriesCount.textContent = stats.calories.toLocaleString();
  
  // Update connected devices list
  if (connectedDevicesList && noConnectedDevices) {
    if (connections.length === 0) {
      if (connectedDevicesList) connectedDevicesList.innerHTML = '';
      if (noConnectedDevices) noConnectedDevices.style.display = 'block';
    } else {
      if (noConnectedDevices) noConnectedDevices.style.display = 'none';
      
      // Clear the list
      connectedDevicesList.innerHTML = '';
      
      // Add connected devices
      connections.forEach(connection => {
        const deviceElement = document.createElement('div');
        deviceElement.className = 'card mb-3';
        
        const dataTypes = connection.dataTypes.map(type => {
          return `<span class="badge bg-light text-dark me-1">${type}</span>`;
        }).join('');
        
        deviceElement.innerHTML = `
          <div class="card-body">
            <div class="d-flex justify-content-between align-items-center">
              <div>
                <h6 class="mb-1">${connection.getDisplayName()}</h6>
                <p class="text-muted mb-0 small">Last sync: ${connection.getFormattedLastSync()}</p>
                <div class="mt-1">
                  ${dataTypes}
                </div>
              </div>
              <div>
                <button class="btn btn-sm btn-outline-primary me-1" 
                  onclick="syncConnection('${connection.id}')"
                  ${connection.connected ? '' : 'disabled'}>
                  <i class="bi bi-arrow-repeat"></i> Sync
                </button>
                <button class="btn btn-sm btn-outline-danger" 
                  onclick="disconnectDevice('${connection.id}')">
                  <i class="bi bi-x-circle"></i> Disconnect
                </button>
              </div>
            </div>
            <div class="mt-2">
              <div class="row">
                <div class="col-4">
                  <div class="small text-muted">Workouts</div>
                  <div class="fw-bold">${connection.stats.workouts}</div>
                </div>
                <div class="col-4">
                  <div class="small text-muted">Steps</div>
                  <div class="fw-bold">${connection.stats.steps.toLocaleString()}</div>
                </div>
                <div class="col-4">
                  <div class="small text-muted">Calories</div>
                  <div class="fw-bold">${connection.stats.calories.toLocaleString()}</div>
                </div>
              </div>
            </div>
          </div>
        `;
        
        connectedDevicesList.appendChild(deviceElement);
      });
    }
  }
}

/**
 * Sync a specific connection
 * @param {string} connectionId - ID of the connection to sync
 */
function syncConnection(connectionId) {
  const connection = healthConnectionManager.getConnectionById(connectionId);
  
  if (!connection) {
    showMessage('Connection not found.', 'danger');
    return;
  }
  
  showMessage(`Syncing data from ${connection.getDisplayName()}...`, 'info');
  
  connection.syncData()
    .then(result => {
      // Potential TODO: Process the new data to update tracker stats
      
      updateConnectionsView();
      updateDashboard();
      
      showMessage(`Successfully synced data from ${connection.getDisplayName()}`, 'success');
    })
    .catch(error => {
      console.error('Sync error:', error);
      showMessage('Failed to sync data. Please try again.', 'danger');
    });
}

/**
 * Disconnect a device
 * @param {string} connectionId - ID of the connection to disconnect
 */
function disconnectDevice(connectionId) {
  const connection = healthConnectionManager.getConnectionById(connectionId);
  
  if (!connection) {
    showMessage('Connection not found.', 'danger');
    return;
  }
  
  if (confirm(`Are you sure you want to disconnect ${connection.getDisplayName()}?`)) {
    showMessage(`Disconnecting ${connection.getDisplayName()}...`, 'info');
    
    healthConnectionManager.removeConnection(connectionId)
      .then(result => {
        updateConnectionsView();
        updateDashboard();
        
        showMessage(`Successfully disconnected ${connection.getDisplayName()}`, 'success');
      })
      .catch(error => {
        console.error('Disconnect error:', error);
        showMessage('Failed to disconnect. Please try again.', 'danger');
      });
  }
}

/**
 * Display a message to the user
 * @param {string} message - Message to display
 * @param {string} type - Type of message (success, danger, warning, info)
 */
function showMessage(message, type = 'info') {
  // Create a toast container if it doesn't exist
  let toastContainer = document.querySelector('.toast-container');
  
  if (!toastContainer) {
    toastContainer = document.createElement('div');
    toastContainer.className = 'toast-container position-fixed bottom-0 end-0 p-3';
    document.body.appendChild(toastContainer);
  }
  
  // Create a unique ID for this toast
  const toastId = 'toast-' + Date.now();
  
  // Create the toast element
  const toastHtml = `
    <div id="${toastId}" class="toast" role="alert" aria-live="assertive" aria-atomic="true">
      <div class="toast-header">
        <strong class="me-auto">Health & Wellness Tracker</strong>
        <button type="button" class="btn-close" data-bs-dismiss="toast" aria-label="Close"></button>
      </div>
      <div class="toast-body bg-${type} text-${type === 'warning' || type === 'info' ? 'dark' : 'white'}">
        ${message}
      </div>
    </div>
  `;
  
  // Add the toast to the container
  toastContainer.innerHTML += toastHtml;
  
  // Initialize and show the toast
  const toastElement = document.getElementById(toastId);
  const toast = new bootstrap.Toast(toastElement, { delay: 5000 });
  toast.show();
  
  // Remove the toast element when hidden
  toastElement.addEventListener('hidden.bs.toast', function() {
    toastElement.remove();
  });
}