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
  // Add custom styles for swipe-to-delete
  const style = document.createElement('style');
  style.textContent = `
    .activity-card {
      position: relative;
      overflow: hidden;
      touch-action: pan-y;
      user-select: none;
    }
    .activity-card .card-body {
      background-color: white;
      position: relative;
      z-index: 1;
    }
    .swipe-delete-btn {
      z-index: 0;
      font-size: 1.5rem;
    }
    .swipe-hint {
      position: absolute;
      top: 50%;
      right: 10px;
      transform: translateY(-50%);
      font-size: 0.8rem;
      color: #6c757d;
      pointer-events: none;
      animation: pulse 2s infinite;
    }
    @keyframes pulse {
      0% { opacity: 0.3; }
      50% { opacity: 0.8; }
      100% { opacity: 0.3; }
    }
  `;
  document.head.appendChild(style);
  
  // Set up event listeners for all forms
  setupEventListeners();
  
  // Set up authentication system
  setupAuthSystem();
  
  // Initialize the health snapshot features
  initializeHealthSnapshot();
  
  // Initialize the enhanced workout form
  initializeWorkoutForm();
  
  // Sync data from all health connections if any exist
  if (healthConnectionManager.getConnections().length > 0) {
    syncAllHealthConnections();
  }
  
  // Update the dashboard with current data
  updateDashboard();
});

/**
 * Sync data from all health connections
 */
function syncAllHealthConnections() {
  showMessage('Syncing data from all connected health sources...', 'info');
  
  healthConnectionManager.syncAllConnections()
    .then(results => {
      // Process all the synced data
      if (results.results && results.results.length > 0) {
        results.results.forEach(result => {
          if (result.data) {
            // Update steps if available
            if (result.data.steps && result.data.steps > 0) {
              fitnessTracker.addSteps(result.data.steps);
            }
            
            // Add workouts if available
            if (result.data.workouts && result.data.workouts.length > 0) {
              result.data.workouts.forEach(workout => {
                const activity = new Activity(
                  `${workout.type.charAt(0).toUpperCase() + workout.type.slice(1)}`,
                  workout.calories,
                  workout.duration,
                  workout.type,
                  workout.date
                );
                fitnessTracker.addActivity(activity);
              });
            }
            
            // Add sleep data if available
            if (result.data.sleep && sleepTracker) {
              const sleep = result.data.sleep;
              const sleepRecord = new SleepRecord(
                new Date(sleep.startTime),
                new Date(sleep.endTime),
                sleep.quality,
                'Synced from connected device',
                []
              );
              sleepTracker.addSleepRecord(sleepRecord);
            }
          }
        });
        
        // Save updated data
        fitnessTracker.saveToLocalStorage();
        sleepTracker.saveToLocalStorage();
      }
      
      updateDashboard();
      showMessage('Successfully synced data from all health sources', 'success');
    })
    .catch(error => {
      console.error('Sync error:', error);
      showMessage('Error syncing data from health sources', 'danger');
    });
}

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
  
  // Health Snapshot form
  const healthSnapshotForm = document.getElementById('health-snapshot-form');
  if (healthSnapshotForm) {
    healthSnapshotForm.addEventListener('submit', handleHealthSnapshotFormSubmit);
  }
  
  // Capture Snapshot button
  const captureSnapshotBtn = document.getElementById('capture-snapshot-btn');
  if (captureSnapshotBtn) {
    captureSnapshotBtn.addEventListener('click', openHealthSnapshotModal);
  }
  
  // Water intake slider
  const waterIntakeSlider = document.getElementById('water-intake');
  if (waterIntakeSlider) {
    waterIntakeSlider.addEventListener('input', updateWaterIntakeValue);
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
      // Process the synced data from initial connection
      if (result.syncResult && result.syncResult.data) {
        const syncData = result.syncResult.data;
        
        // Update steps if available
        if (syncData.steps && syncData.steps > 0) {
          fitnessTracker.addSteps(syncData.steps);
        }
        
        // Add workouts if available
        if (syncData.workouts && syncData.workouts.length > 0) {
          syncData.workouts.forEach(workout => {
            const activity = new Activity(
              `${workout.type.charAt(0).toUpperCase() + workout.type.slice(1)}`,
              workout.calories,
              workout.duration,
              workout.type,
              workout.date
            );
            fitnessTracker.addActivity(activity);
          });
        }
        
        // Add sleep data if available
        if (syncData.sleep && sleepTracker) {
          const sleep = syncData.sleep;
          const sleepRecord = new SleepRecord(
            new Date(sleep.startTime),
            new Date(sleep.endTime),
            sleep.quality,
            'Synced from ' + connection.getDisplayName(),
            []
          );
          sleepTracker.addSleepRecord(sleepRecord);
        }
        
        // Save updated data
        fitnessTracker.saveToLocalStorage();
        sleepTracker.saveToLocalStorage();
      }
      
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
  updateActivityChart();
  updateConnectionsView();
  updateHealthSnapshotWidget();
  
  // Set up global click handler to reset any partially swiped cards
  setupGlobalClickHandlers();
}

/**
 * Set up global click handlers
 */
function setupGlobalClickHandlers() {
  // Add a single document click handler to reset any swiped cards
  if (!window.hasResetClickHandler) {
    document.addEventListener('click', function(e) {
      // Find all activity cards
      const activityCards = document.querySelectorAll('.activity-card');
      
      // Reset any cards that might be in a swiped state
      activityCards.forEach(card => {
        // If the card has a resetSwipe method, use it
        if (typeof card.resetSwipe === 'function') {
          card.resetSwipe();
        } else {
          // Fallback for older cards that might not have the method
          const cardBody = card.querySelector('.card-body');
          if (cardBody && cardBody.style.transform && 
              cardBody.style.transform !== 'translateX(0px)' && 
              cardBody.style.transform !== 'translateX(0)') {
            
            cardBody.style.transform = 'translateX(0)';
            
            // Also reset any visible delete buttons
            const deleteBtn = card.querySelector('.swipe-delete-btn');
            if (deleteBtn) {
              deleteBtn.style.opacity = '0';
            }
          }
        }
      });
    });
    window.hasResetClickHandler = true;
  }
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
  
  /**
   * Creates an activity card element with separate view details button
   * @param {Activity} activity - The activity to create a card for
   * @returns {HTMLElement} The created activity card
   */
  function createActivityCard(activity) {
    const activityElement = document.createElement('div');
    activityElement.className = 'card mb-2 activity-card';
    activityElement.dataset.activityId = activity.id;
    
    // Create the inner structure with separate card content and info button
    activityElement.innerHTML = `
      <div class="card-body">
        <div class="d-flex justify-content-between align-items-center">
          <div class="activity-info">
            <h6 class="mb-1">${activity.name}</h6>
            <p class="text-muted mb-0 small">${activity.getFormattedDate()} | ${activity.duration} mins | ${activity.type}</p>
          </div>
          <div class="d-flex align-items-center">
            <span class="badge bg-primary rounded-pill me-2">${activity.calories} cal</span>
            <button type="button" class="btn btn-sm btn-outline-primary view-details-btn">
              <i class="bi bi-info-circle"></i>
            </button>
          </div>
        </div>
      </div>
    `;
    
    // Add swipe functionality
    setupSwipeToDelete(activityElement, activity.id);
    
    // Add view details button functionality - keep this independent of the swipe
    const viewButton = activityElement.querySelector('.view-details-btn');
    if (viewButton) {
      viewButton.addEventListener('click', (e) => {
        e.preventDefault(); // Prevent default behavior
        e.stopPropagation(); // Stop event propagation
        // Prevent any potential touch event from continuing
        if (e.cancelable) e.preventDefault();
        // Open the activity modal
        openActivityModal(activity.id);
        return false;
      });
    }
    
    return activityElement;
  }
  
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
        const activityElement = createActivityCard(activity);
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
        const activityElement = createActivityCard(activity);
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
  const qualityData = weeklyData.map(day => day.quality); // Already converted in getWeeklySleepSummary
  
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
 * Initialize a scroll wheel for numeric inputs
 * @param {string} inputId - ID of the input element
 * @param {number} maxValue - Maximum value for the input
 */
function initializeScrollWheel(inputId, maxValue) {
  const input = document.getElementById(inputId);
  if (!input) return;
  
  // Create container for the scroll wheel
  const container = document.createElement('div');
  container.className = 'scroll-wheel-container';
  container.style.cssText = `
    position: relative;
    display: none;
    height: 150px;
    overflow: hidden;
    background: #f8f9fa;
    border-radius: 8px;
    margin: 10px 0;
    touch-action: pan-y;
  `;
  
  // Create the scroll wheel
  const wheel = document.createElement('div');
  wheel.className = 'scroll-wheel';
  wheel.style.cssText = `
    position: absolute;
    width: 100%;
    text-align: center;
    transform: translateY(0);
    transition: transform 0.2s ease-out;
  `;
  
  // Add number options to the wheel
  for (let i = 0; i <= maxValue; i++) {
    const option = document.createElement('div');
    option.className = 'scroll-wheel-option';
    option.textContent = i;
    option.dataset.value = i;
    option.style.cssText = `
      height: 40px;
      line-height: 40px;
      font-size: 20px;
      user-select: none;
    `;
    wheel.appendChild(option);
  }
  
  container.appendChild(wheel);
  input.parentNode.insertBefore(container, input.nextSibling);
  
  // Add a selection indicator line
  const selectionLine = document.createElement('div');
  selectionLine.className = 'selection-line';
  selectionLine.style.cssText = `
    position: absolute;
    left: 0;
    right: 0;
    top: 50%;
    height: 40px;
    transform: translateY(-50%);
    border-top: 1px solid #ddd;
    border-bottom: 1px solid #ddd;
    pointer-events: none;
    background-color: rgba(0, 123, 255, 0.1);
  `;
  container.appendChild(selectionLine);
  
  // Store references and state
  input.scrollWheel = {
    container,
    wheel,
    options: wheel.querySelectorAll('.scroll-wheel-option'),
    optionHeight: 40,
    startY: 0,
    currentY: 0,
    lastY: 0,
    currentValue: parseInt(input.value) || 0
  };
  
  // Set initial position based on input value
  const initialValue = parseInt(input.value) || 0;
  updateScrollWheelPosition(input, initialValue);
  
  // Set up input mode toggle
  input.addEventListener('click', function() {
    // Check if the container is already visible
    if (container.style.display === 'block') {
      container.style.display = 'none';
      input.style.display = 'block';
    } else {
      container.style.display = 'block';
      input.style.display = 'none';
      updateScrollWheelPosition(input, parseInt(input.value) || 0);
    }
  });
  
  // Set up touch events for scroll wheel
  let isDragging = false;
  
  container.addEventListener('touchstart', function(e) {
    const touch = e.touches[0];
    input.scrollWheel.startY = touch.clientY;
    input.scrollWheel.lastY = input.scrollWheel.currentY;
    isDragging = true;
    e.preventDefault();
  }, { passive: false });
  
  container.addEventListener('touchmove', function(e) {
    if (!isDragging) return;
    
    const touch = e.touches[0];
    const deltaY = touch.clientY - input.scrollWheel.startY;
    
    // Calculate new position
    const newY = input.scrollWheel.lastY + deltaY;
    input.scrollWheel.currentY = newY;
    
    // Calculate value based on scroll position
    const offset = newY % input.scrollWheel.optionHeight;
    const index = Math.round((newY - offset) / -input.scrollWheel.optionHeight);
    
    let value = Math.max(0, Math.min(maxValue, index));
    
    // Update the visual position of the wheel
    wheel.style.transform = `translateY(${newY}px)`;
    
    // Update the input value
    input.value = value;
    input.scrollWheel.currentValue = value;
    
    e.preventDefault();
  }, { passive: false });
  
  container.addEventListener('touchend', function() {
    if (!isDragging) return;
    isDragging = false;
    
    // Snap to nearest option
    const value = input.scrollWheel.currentValue;
    updateScrollWheelPosition(input, value);
    
    // Trigger change event on the input
    input.dispatchEvent(new Event('change', { bubbles: true }));
  });
  
  // Sync scroll wheel when input changes
  input.addEventListener('change', function() {
    const value = parseInt(this.value) || 0;
    this.value = Math.max(0, Math.min(maxValue, value));
    updateScrollWheelPosition(this, this.value);
  });
}

/**
 * Update the position of a scroll wheel to show the selected value
 * @param {HTMLElement} input - The input element
 * @param {number} value - The value to display
 */
function updateScrollWheelPosition(input, value) {
  if (!input.scrollWheel) return;
  
  const { wheel, optionHeight } = input.scrollWheel;
  const position = -(value * optionHeight) + (input.scrollWheel.container.offsetHeight / 2 - optionHeight / 2);
  
  wheel.style.transition = 'transform 0.3s ease-out';
  wheel.style.transform = `translateY(${position}px)`;
  input.scrollWheel.currentY = position;
  input.scrollWheel.currentValue = value;
  input.value = value;
  
  // Remove the transition after it completes
  setTimeout(() => {
    wheel.style.transition = '';
  }, 300);
}

/**
 * Set up double tap to toggle between input modes
 * @param {string} inputId - ID of the input element
 */
function setupDoubleTapToggle(inputId) {
  const input = document.getElementById(inputId);
  if (!input || !input.scrollWheel) return;
  
  let lastTap = 0;
  
  input.addEventListener('click', function(e) {
    const currentTime = new Date().getTime();
    const tapLength = currentTime - lastTap;
    
    if (tapLength < 500 && tapLength > 0) {
      // Double tap detected
      if (input.scrollWheel.container.style.display === 'block') {
        // Switch to manual input
        input.scrollWheel.container.style.display = 'none';
        input.style.display = 'block';
        input.focus();
      } else {
        // Switch to scroll wheel
        input.scrollWheel.container.style.display = 'block';
        input.style.display = 'none';
        updateScrollWheelPosition(input, parseInt(input.value) || 0);
      }
      e.preventDefault();
    }
    
    lastTap = currentTime;
  });
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
 * Update activity chart
 */
// Store current chart type
let currentChartType = 'doughnut';

function updateActivityChart() {
  const chartCanvas = document.getElementById('activity-chart');
  
  if (!chartCanvas) return;
  
  const ctx = chartCanvas.getContext('2d');
  
  // Get activities
  const activities = fitnessTracker.getActivities();
  
  // Group activities by type and calculate total calories
  const activityTypes = ['running', 'cycling', 'weights', 'swimming', 'other'];
  const activityLabels = ['Running', 'Cycling', 'Weights', 'Swimming', 'Other'];
  const typeCalories = {};
  
  activityTypes.forEach(type => {
    typeCalories[type] = 0;
  });
  
  // Calculate total calories for each activity type
  activities.forEach(activity => {
    const type = activity.type.toLowerCase();
    if (typeCalories.hasOwnProperty(type)) {
      typeCalories[type] += activity.calories;
    } else {
      typeCalories['other'] += activity.calories;
    }
  });
  
  // Create chart config based on chart type
  const chartConfig = getChartConfig(currentChartType, activityTypes, activityLabels, typeCalories);
  
  // Create or update chart
  if (window.activityChart) {
    // If chart type has changed, destroy and recreate
    if (window.activityChart.config.type !== chartConfig.type) {
      window.activityChart.destroy();
      window.activityChart = new Chart(ctx, chartConfig);
    } else {
      // Just update the data
      window.activityChart.data = chartConfig.data;
      window.activityChart.options = chartConfig.options;
      window.activityChart.update();
    }
  } else {
    window.activityChart = new Chart(ctx, chartConfig);
  }
  
  // Add event listeners for chart type buttons if they haven't been added yet
  if (!window.chartButtonsInitialized) {
    initChartTypeButtons();
    window.chartButtonsInitialized = true;
  }
}

// Handle chart type button clicks
function initChartTypeButtons() {
  const doughnutBtn = document.getElementById('chart-type-doughnut');
  const barBtn = document.getElementById('chart-type-bar');
  const lineBtn = document.getElementById('chart-type-line');
  
  if (doughnutBtn && barBtn && lineBtn) {
    doughnutBtn.addEventListener('click', () => {
      setActiveChartButton(doughnutBtn);
      currentChartType = 'doughnut';
      updateActivityChart();
    });
    
    barBtn.addEventListener('click', () => {
      setActiveChartButton(barBtn);
      currentChartType = 'bar';
      updateActivityChart();
    });
    
    lineBtn.addEventListener('click', () => {
      setActiveChartButton(lineBtn);
      currentChartType = 'line';
      updateActivityChart();
    });
  }
}

// Set active chart button
function setActiveChartButton(activeButton) {
  const buttons = [
    document.getElementById('chart-type-doughnut'),
    document.getElementById('chart-type-bar'),
    document.getElementById('chart-type-line')
  ];
  
  buttons.forEach(btn => {
    if (btn && btn === activeButton) {
      btn.classList.add('active');
    } else if (btn) {
      btn.classList.remove('active');
    }
  });
}

// Get chart configuration based on chart type
function getChartConfig(chartType, activityTypes, activityLabels, typeCalories) {
  const data = activityTypes.map(type => typeCalories[type]);
  const colors = [
    'rgba(255, 99, 132, 0.7)',   // Red for running
    'rgba(54, 162, 235, 0.7)',   // Blue for cycling
    'rgba(255, 206, 86, 0.7)',   // Yellow for weights
    'rgba(75, 192, 192, 0.7)',   // Teal for swimming
    'rgba(153, 102, 255, 0.7)'   // Purple for other
  ];
  const borderColors = [
    'rgb(255, 99, 132)',
    'rgb(54, 162, 235)',
    'rgb(255, 206, 86)',
    'rgb(75, 192, 192)',
    'rgb(153, 102, 255)'
  ];
  
  let config = {
    type: chartType,
    data: {
      labels: activityLabels,
      datasets: [{
        data: data,
        backgroundColor: chartType === 'line' ? colors[0] : colors,
        borderColor: chartType === 'line' ? borderColors[0] : borderColors,
        borderWidth: 1
      }]
    },
    options: {
      responsive: true,
      plugins: {
        legend: {
          position: 'bottom',
          display: chartType !== 'bar'
        },
        title: {
          display: true,
          text: 'Calories Burned by Activity Type'
        }
      }
    }
  };
  
  // Add specific configurations based on chart type
  if (chartType === 'doughnut' || chartType === 'pie') {
    config.options.plugins.tooltip = {
      callbacks: {
        label: function(context) {
          const label = context.label || '';
          const value = context.formattedValue;
          const total = context.dataset.data.reduce((acc, val) => acc + val, 0);
          const percentage = total > 0 ? Math.round((context.raw / total) * 100) : 0;
          return `${label}: ${value} calories (${percentage}%)`;
        }
      }
    };
  } else if (chartType === 'bar') {
    config.options.scales = {
      y: {
        beginAtZero: true,
        title: {
          display: true,
          text: 'Calories Burned'
        }
      },
      x: {
        title: {
          display: true,
          text: 'Activity Type'
        }
      }
    };
  } else if (chartType === 'line') {
    // For line chart, we need time-based data
    // We'll convert activity types data to time-based daily data
    const dailyData = getDailyActivityData(activityTypes);
    
    config.data.labels = dailyData.labels;
    config.data.datasets = activityTypes.map((type, index) => {
      return {
        label: activityLabels[index],
        data: dailyData.datasets[type],
        backgroundColor: colors[index],
        borderColor: borderColors[index],
        tension: 0.1,
        fill: false
      };
    });
    
    config.options.scales = {
      y: {
        beginAtZero: true,
        title: {
          display: true,
          text: 'Calories Burned'
        }
      },
      x: {
        title: {
          display: true,
          text: 'Date'
        }
      }
    };
  }
  
  return config;
}

// Get daily activity data for line chart
function getDailyActivityData(activityTypes) {
  const activities = fitnessTracker.getActivities();
  const days = 7; // Last 7 days
  
  // Create date labels for the last 7 days
  const labels = [];
  const datasets = {};
  
  activityTypes.forEach(type => {
    datasets[type] = [];
  });
  
  // Generate dates and initialize data points
  for (let i = days - 1; i >= 0; i--) {
    const date = new Date();
    date.setDate(date.getDate() - i);
    
    // Format date as short day name
    const label = date.toLocaleDateString('en-US', { weekday: 'short' });
    labels.push(label);
    
    // Initialize calorie counts for each activity type on this day
    const dateString = date.toISOString().split('T')[0];
    
    activityTypes.forEach(type => {
      datasets[type].push(
        activities.filter(a => {
          const activityDate = new Date(a.date);
          return activityDate.toISOString().split('T')[0] === dateString && 
                 a.type.toLowerCase() === type;
        }).reduce((total, activity) => total + activity.calories, 0)
      );
    });
  }
  
  return { labels, datasets };
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
  const syncAllButton = document.getElementById('sync-all-button');
  
  const connections = healthConnectionManager.getConnections();
  const stats = healthConnectionManager.getAggregateStats();
  
  // Update stats
  if (lastSyncTime) {
    lastSyncTime.textContent = stats.lastSync ? new Date(stats.lastSync).toLocaleString() : 'Never';
  }
  if (syncedWorkoutsCount) syncedWorkoutsCount.textContent = stats.workouts.toString();
  if (syncedStepsCount) syncedStepsCount.textContent = stats.steps.toLocaleString();
  if (syncedCaloriesCount) syncedCaloriesCount.textContent = stats.calories.toLocaleString();
  
  // Update sync all button
  if (syncAllButton) {
    if (connections.length > 0) {
      syncAllButton.disabled = false;
      syncAllButton.onclick = syncAllHealthConnections;
    } else {
      syncAllButton.disabled = true;
    }
  }
  
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
      // Process the synced data to update our trackers
      if (result.data) {
        // Update steps if available
        if (result.data.steps && result.data.steps > 0) {
          fitnessTracker.addSteps(result.data.steps);
        }
        
        // Add workouts if available
        if (result.data.workouts && result.data.workouts.length > 0) {
          result.data.workouts.forEach(workout => {
            const activity = new Activity(
              `${workout.type.charAt(0).toUpperCase() + workout.type.slice(1)}`,
              workout.calories,
              workout.duration,
              workout.type,
              workout.date
            );
            
            // Store the source information for this activity
            activity.sourceConnection = workout.sourceConnection || connection.id;
            activity.sourceId = workout.sourceId;
            
            fitnessTracker.addActivity(activity);
          });
        }
        
        // Add sleep data if available
        if (result.data.sleep && sleepTracker) {
          const sleep = result.data.sleep;
          const sleepRecord = new SleepRecord(
            new Date(sleep.startTime),
            new Date(sleep.endTime),
            sleep.quality,
            'Synced from ' + connection.getDisplayName(),
            []
          );
          sleepTracker.addSleepRecord(sleepRecord);
        }
      }
      
      // Save updated data
      fitnessTracker.saveToLocalStorage();
      sleepTracker.saveToLocalStorage();
      
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

/**
 * Open activity modal for viewing and editing an activity
 * @param {string} activityId - ID of the activity to edit
 */
function openActivityModal(activityId) {
  // Get the activity from the fitness tracker
  const activity = fitnessTracker.getActivityById(activityId);
  
  if (!activity) {
    showMessage('Activity not found', 'danger');
    return;
  }
  
  // Create a modal if it doesn't exist
  let modal = document.getElementById('editActivityModal');
  
  if (!modal) {
    modal = document.createElement('div');
    modal.className = 'modal fade';
    modal.id = 'editActivityModal';
    modal.tabIndex = '-1';
    modal.setAttribute('aria-labelledby', 'editActivityModalLabel');
    modal.setAttribute('aria-hidden', 'true');
    
    // Set up modal HTML
    modal.innerHTML = `
      <div class="modal-dialog">
        <div class="modal-content">
          <div class="modal-header">
            <h5 class="modal-title" id="editActivityModalLabel">Edit Activity</h5>
            <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
          </div>
          <div class="modal-body">
            <form id="editActivityForm">
              <input type="hidden" id="edit-activity-id">
              <div class="mb-3">
                <label for="edit-activity-name" class="form-label">Activity Name</label>
                <input type="text" class="form-control" id="edit-activity-name" required>
              </div>
              <div class="mb-3">
                <label for="edit-activity-calories" class="form-label">Calories Burned</label>
                <input type="number" class="form-control" id="edit-activity-calories" min="0" required>
              </div>
              <div class="mb-3">
                <label for="edit-activity-duration" class="form-label">Duration (minutes)</label>
                <input type="number" class="form-control" id="edit-activity-duration" min="1" required>
              </div>
              <div class="mb-3">
                <label for="edit-activity-type" class="form-label">Type</label>
                <select class="form-select" id="edit-activity-type" required>
                  <option value="running">Running</option>
                  <option value="cycling">Cycling</option>
                  <option value="swimming">Swimming</option>
                  <option value="weights">Weights</option>
                  <option value="yoga">Yoga</option>
                  <option value="other">Other</option>
                </select>
              </div>
              <div class="mb-3">
                <label for="edit-activity-date" class="form-label">Date</label>
                <input type="datetime-local" class="form-control" id="edit-activity-date" required>
              </div>
              <div class="d-flex justify-content-between">
                <button type="submit" class="btn btn-primary">Save Changes</button>
                <button type="button" class="btn btn-danger" id="delete-activity-btn" onclick="return false;">Delete Activity</button>
              </div>
            </form>
          </div>
        </div>
      </div>
    `;
    
    document.body.appendChild(modal);
  }
  
  // Get modal element after it's been added to the DOM
  modal = document.getElementById('editActivityModal');
  
  // Add event listeners for form submission 
  const form = document.getElementById('editActivityForm');
  if (form) {
    // Clear existing event listeners by cloning
    const newForm = form.cloneNode(true);
    form.parentNode.replaceChild(newForm, form);
    
    // Add event listener for form submission
    newForm.addEventListener('submit', handleEditActivityFormSubmit);
    
    // Add direct onclick handler to the delete button (more reliable than event listeners)
    const deleteBtn = newForm.querySelector('#delete-activity-btn');
    if (deleteBtn) {
      // Store the activity ID directly on the button for reference
      deleteBtn.setAttribute('data-activity-id', activity.id);
      // Direct onclick handler
      deleteBtn.onclick = function() {
        const activityId = this.getAttribute('data-activity-id');
        handleDeleteActivity(activityId);
        return false; // Prevent form submission
      };
    }
  }
  
  // Populate the form with activity data
  document.getElementById('edit-activity-id').value = activity.id;
  document.getElementById('edit-activity-name').value = activity.name;
  document.getElementById('edit-activity-calories').value = activity.calories;
  document.getElementById('edit-activity-duration').value = activity.duration;
  document.getElementById('edit-activity-type').value = activity.type;
  
  // Format the date for datetime-local input
  const activityDate = new Date(activity.date);
  const formattedDate = activityDate.toISOString().slice(0, 16);
  document.getElementById('edit-activity-date').value = formattedDate;
  
  // Open the modal
  const bsModal = new bootstrap.Modal(document.getElementById('editActivityModal'));
  bsModal.show();
}

/**
 * Handle the edit activity form submission
 * @param {Event} event - Form submission event
 */
function handleEditActivityFormSubmit(event) {
  event.preventDefault();
  
  const activityId = document.getElementById('edit-activity-id').value;
  const name = document.getElementById('edit-activity-name').value;
  const calories = Number(document.getElementById('edit-activity-calories').value);
  const duration = Number(document.getElementById('edit-activity-duration').value);
  const type = document.getElementById('edit-activity-type').value;
  const date = new Date(document.getElementById('edit-activity-date').value);
  
  // Update the activity
  const success = fitnessTracker.updateActivity(activityId, {
    name,
    calories,
    duration,
    type,
    date
  });
  
  if (success) {
    // Close the modal
    const modal = bootstrap.Modal.getInstance(document.getElementById('editActivityModal'));
    modal.hide();
    
    // Update the UI
    updateFitnessStats();
    updateActivitiesList();
    updateActivityChart();
    
    showMessage('Activity updated successfully', 'success');
  } else {
    showMessage('Error updating activity', 'danger');
  }
}

/**
 * Handle deleting an activity
 * @param {string} activityId - ID of the activity to delete
 */
function handleDeleteActivity(activityId) {
  // Store a flag to track if the delete was already confirmed (for when called from swipe)
  const activityCard = document.querySelector(`.activity-card[data-activity-id="${activityId}"]`);
  const isSwipeDeleteConfirmed = activityCard && activityCard.dataset.deleteConfirmed === 'true';
  
  // Only show confirmation if not already confirmed from swipe
  if (isSwipeDeleteConfirmed || confirm('Are you sure you want to delete this activity?')) {
    const activity = fitnessTracker.getActivityById(activityId);
    
    // First delete the activity from the fitness tracker
    const success = fitnessTracker.deleteActivity(activityId);
    
    if (success) {
      // Close the modal if it's open
      const modalElement = document.getElementById('editActivityModal');
      if (modalElement) {
        const modal = bootstrap.Modal.getInstance(modalElement);
        if (modal) modal.hide();
      }
      
      // Update the UI
      updateFitnessStats();
      updateActivitiesList();
      updateActivityChart();
      
      // If the activity was synced from a health source, update the connection
      if (activity && activity.sourceConnection) {
        // Tell the connected health source to delete this activity
        const connection = healthConnectionManager.getConnectionById(activity.sourceConnection);
        if (connection) {
          connection.deleteActivityFromSource(activity.sourceId)
            .then(() => {
              console.log(`Successfully deleted activity from health source: ${activity.sourceConnection}`);
              showMessage('Activity deleted from device and app', 'success');
            })
            .catch(error => {
              console.error(`Failed to delete activity from health source: ${error}`);
              showMessage('Activity deleted from app, but failed to delete from connected device', 'warning');
            });
        } else {
          showMessage('Activity deleted successfully', 'success');
        }
      } else {
        showMessage('Activity deleted successfully', 'success');
      }
    } else {
      showMessage('Error deleting activity', 'danger');
    }
  }
}

/**
 * Set up the authentication system
 */
function setupAuthSystem() {
  // Get references to DOM elements
  const authButtons = document.getElementById('auth-buttons');
  const userProfile = document.getElementById('user-profile');
  const userNameElement = document.getElementById('user-name');
  
  // Login form handling
  const loginForm = document.getElementById('login-form');
  const loginErrorElement = document.getElementById('login-error');
  
  // Registration form handling
  const registerForm = document.getElementById('register-form');
  const registerErrorElement = document.getElementById('register-error');
  
  // Profile settings form
  const profileSettingsForm = document.getElementById('profile-settings-form');
  const settingsNameInput = document.getElementById('settings-name');
  const settingsEmailInput = document.getElementById('settings-email');
  
  // Preferences form
  const preferencesForm = document.getElementById('preferences-settings-form');
  
  // Security form
  const securityForm = document.getElementById('security-settings-form');
  
  // Logout button
  const logoutButton = document.getElementById('logout-button');
  const profileSettings = document.getElementById('profile-settings');
  
  // Check if user is already logged in
  if (authManager.isLoggedIn()) {
    // Update UI for logged-in state
    updateAuthUI(true);
  } else {
    // Update UI for logged-out state
    updateAuthUI(false);
  }
  
  // Login form submission
  if (loginForm) {
    loginForm.addEventListener('submit', function(event) {
      event.preventDefault();
      
      const email = document.getElementById('login-email').value;
      const password = document.getElementById('login-password').value;
      
      const result = authManager.login(email, password);
      
      if (result.success) {
        // Hide the modal
        const loginModal = bootstrap.Modal.getInstance(document.getElementById('loginModal'));
        loginModal.hide();
        
        // Update UI
        updateAuthUI(true);
        
        // Show success message
        showMessage(`Welcome back, ${result.user.name}!`, 'success');
        
        // Reset the form
        loginForm.reset();
      } else {
        // Show error message
        loginErrorElement.textContent = result.message;
        loginErrorElement.style.display = 'block';
      }
    });
  }
  
  // Registration form submission
  if (registerForm) {
    registerForm.addEventListener('submit', function(event) {
      event.preventDefault();
      
      const name = document.getElementById('register-name').value;
      const email = document.getElementById('register-email').value;
      const password = document.getElementById('register-password').value;
      const confirmPassword = document.getElementById('register-password-confirm').value;
      
      // Check if passwords match
      if (password !== confirmPassword) {
        registerErrorElement.textContent = 'Passwords do not match';
        registerErrorElement.style.display = 'block';
        return;
      }
      
      // Register the user
      const result = authManager.register(name, email, password);
      
      if (result.success) {
        // Hide the modal
        const registerModal = bootstrap.Modal.getInstance(document.getElementById('registerModal'));
        registerModal.hide();
        
        // Update UI
        updateAuthUI(true);
        
        // Show success message
        showMessage(`Account created successfully. Welcome, ${result.user.name}!`, 'success');
        
        // Reset the form
        registerForm.reset();
      } else {
        // Show error message
        registerErrorElement.textContent = result.message;
        registerErrorElement.style.display = 'block';
      }
    });
  }
  
  // Profile settings form submission
  if (profileSettingsForm) {
    profileSettingsForm.addEventListener('submit', function(event) {
      event.preventDefault();
      
      const name = settingsNameInput.value;
      const email = settingsEmailInput.value;
      
      const currentUser = authManager.getCurrentUser();
      if (currentUser) {
        currentUser.updateProfile({ name, email });
        authManager.saveToLocalStorage();
        
        // Update UI
        userNameElement.textContent = name;
        
        // Show success message
        showMessage('Profile updated successfully', 'success');
      }
    });
  }
  
  // Preferences form submission
  if (preferencesForm) {
    preferencesForm.addEventListener('submit', function(event) {
      event.preventDefault();
      
      const units = document.querySelector('input[name="units"]:checked')?.value || 'metric';
      const calorieGoal = document.getElementById('daily-calorie-goal').value;
      const stepsGoal = document.getElementById('daily-steps-goal').value;
      
      const currentUser = authManager.getCurrentUser();
      if (currentUser) {
        currentUser.updateProfile({
          preferences: {
            units,
            calorieGoal: parseInt(calorieGoal, 10) || 2000,
            stepsGoal: parseInt(stepsGoal, 10) || 10000
          }
        });
        authManager.saveToLocalStorage();
        
        // Show success message
        showMessage('Preferences updated successfully', 'success');
      }
    });
  }
  
  // Security form submission
  if (securityForm) {
    securityForm.addEventListener('submit', function(event) {
      event.preventDefault();
      
      const currentPassword = document.getElementById('current-password').value;
      const newPassword = document.getElementById('new-password').value;
      const confirmNewPassword = document.getElementById('confirm-new-password').value;
      
      // Validate inputs
      if (!currentPassword || !newPassword || !confirmNewPassword) {
        showMessage('Please fill in all password fields', 'danger');
        return;
      }
      
      if (newPassword !== confirmNewPassword) {
        showMessage('New passwords do not match', 'danger');
        return;
      }
      
      const currentUser = authManager.getCurrentUser();
      if (currentUser && currentUser.checkPassword(currentPassword)) {
        // Update password
        currentUser.password = newPassword;
        authManager.saveToLocalStorage();
        
        // Show success message
        showMessage('Password updated successfully', 'success');
        
        // Reset form
        securityForm.reset();
      } else {
        showMessage('Current password is incorrect', 'danger');
      }
    });
  }
  
  // Profile settings button click
  if (profileSettings) {
    profileSettings.addEventListener('click', function() {
      const currentUser = authManager.getCurrentUser();
      if (currentUser) {
        // Fill form with current user data
        settingsNameInput.value = currentUser.name;
        settingsEmailInput.value = currentUser.email;
        
        // Fill preferences form
        if (currentUser.preferences) {
          const unitValue = currentUser.preferences.units || 'metric';
          document.getElementById(`units-${unitValue}`).checked = true;
          
          if (currentUser.preferences.calorieGoal) {
            document.getElementById('daily-calorie-goal').value = currentUser.preferences.calorieGoal;
          }
          
          if (currentUser.preferences.stepsGoal) {
            document.getElementById('daily-steps-goal').value = currentUser.preferences.stepsGoal;
          }
        }
        
        // Show the modal
        const settingsModal = new bootstrap.Modal(document.getElementById('userSettingsModal'));
        settingsModal.show();
      }
    });
  }
  
  // Logout button click
  if (logoutButton) {
    logoutButton.addEventListener('click', function() {
      authManager.logout();
      updateAuthUI(false);
      showMessage('You have been logged out', 'info');
    });
  }
}

/**
 * Update the UI based on authentication state
 * @param {boolean} isLoggedIn - Whether the user is logged in
 */
function updateAuthUI(isLoggedIn) {
  const authButtons = document.getElementById('auth-buttons');
  const userProfile = document.getElementById('user-profile');
  const userNameElement = document.getElementById('user-name');
  
  if (isLoggedIn) {
    // Show user profile, hide auth buttons
    authButtons.style.display = 'none';
    userProfile.style.display = 'block';
    
    // Update user name
    const currentUser = authManager.getCurrentUser();
    if (currentUser) {
      userNameElement.textContent = currentUser.name;
    }
  } else {
    // Show auth buttons, hide user profile
    authButtons.style.display = 'block';
    userProfile.style.display = 'none';
  }
}

/**
 * Set up swipe-to-delete functionality for an element
 * @param {HTMLElement} element - The element to enable swipe-to-delete on
 * @param {string} itemId - ID of the item to delete when swiped
 */
/**
 * Initialize the health snapshot features
 */
function initializeHealthSnapshot() {
  // Initialize the water intake slider value display
  updateWaterIntakeValue();
  
  // Update the snapshot widget with the most recent data
  updateHealthSnapshotWidget();
}

/**
 * Initialize the enhanced workout form features
 */
function initializeWorkoutForm() {
  // Get form elements
  const workoutCategoryRadios = document.querySelectorAll('input[name="workout-category"]');
  const equipmentTypeRadios = document.querySelectorAll('input[name="equipment-type"]');
  const weightTrainingOptions = document.getElementById('weight-training-options');
  const barbellWeightSelector = document.getElementById('barbell-weight-selector');
  const otherWeightSelector = document.getElementById('other-weight-selector');
  const plateBtns = document.querySelectorAll('.plate-btn');
  const clearPlatesBtn = document.getElementById('clear-plates-btn');
  const selectedPlatesDisplay = document.getElementById('selected-plates-display');
  const barbellTotalWeight = document.getElementById('barbell-total-weight');
  const exercisePresets = document.querySelectorAll('.exercise-preset-list .dropdown-item');
  const activityNameInput = document.getElementById('activity-name');
  
  // Selected plates array
  let selectedPlates = [];
  
  // Set up workout category toggle
  workoutCategoryRadios.forEach(radio => {
    radio.addEventListener('change', function() {
      // Show/hide weight training options based on category
      if (this.value === 'weights') {
        weightTrainingOptions.style.display = 'block';
        
        // Show proper weight selection based on equipment type
        const equipmentType = document.querySelector('input[name="equipment-type"]:checked').value;
        updateEquipmentOptions(equipmentType);
        
        // Update activity type
        document.getElementById('activity-type').value = 'weights';
      } else {
        weightTrainingOptions.style.display = 'none';
      }
      
      // Show/hide exercise presets based on category
      updateExercisePresets(this.value);
    });
  });
  
  // Set up equipment type toggle
  equipmentTypeRadios.forEach(radio => {
    radio.addEventListener('change', function() {
      updateEquipmentOptions(this.value);
    });
  });
  
  // Set up plate buttons
  plateBtns.forEach(btn => {
    btn.addEventListener('click', function() {
      const weight = parseFloat(this.dataset.weight);
      
      // Add this plate to the selected plates
      selectedPlates.push(weight);
      
      // Sort plates from heaviest to lightest (for visual display)
      selectedPlates.sort((a, b) => b - a);
      
      // Update UI
      updateSelectedPlates();
      updateBarbellWeight();
    });
  });
  
  // Set up clear plates button
  if (clearPlatesBtn) {
    clearPlatesBtn.addEventListener('click', function() {
      selectedPlates = [];
      updateSelectedPlates();
      updateBarbellWeight();
    });
  }
  
  // Set up exercise presets
  exercisePresets.forEach(preset => {
    preset.addEventListener('click', function(e) {
      e.preventDefault();
      const exerciseName = this.dataset.name;
      activityNameInput.value = exerciseName;
    });
  });
  
  // Initialize scroll wheels
  initializeScrollWheel('other-weight-input', 200);
  initializeScrollWheel('sets-input', 20);
  initializeScrollWheel('reps-input', 100);
  
  // Double tap to switch input mode
  setupDoubleTapToggle('other-weight-input');
  setupDoubleTapToggle('sets-input');
  setupDoubleTapToggle('reps-input');
  
  /**
   * Update the UI based on the selected equipment type
   * @param {string} equipmentType - The selected equipment type
   */
  function updateEquipmentOptions(equipmentType) {
    if (equipmentType === 'barbell') {
      barbellWeightSelector.style.display = 'block';
      otherWeightSelector.style.display = 'none';
    } else if (equipmentType === 'bodyweight') {
      barbellWeightSelector.style.display = 'none';
      otherWeightSelector.style.display = 'none';
    } else {
      // Dumbbell or machine
      barbellWeightSelector.style.display = 'none';
      otherWeightSelector.style.display = 'block';
      
      // Update max weight for dumbbells vs machines
      const otherWeightInput = document.getElementById('other-weight-input');
      if (equipmentType === 'dumbbell') {
        otherWeightInput.max = 200;
      } else {
        otherWeightInput.max = 1000;
      }
    }
  }
  
  /**
   * Update the selected plates display
   */
  function updateSelectedPlates() {
    selectedPlatesDisplay.innerHTML = '';
    
    if (selectedPlates.length === 0) {
      selectedPlatesDisplay.innerHTML = '<span class="text-muted">No plates selected</span>';
      return;
    }
    
    // Create a visual representation of the plates
    selectedPlates.forEach((weight, index) => {
      const plateElement = document.createElement('span');
      plateElement.className = 'plate-badge';
      plateElement.textContent = weight + ' lb';
      
      // Add a remove button
      const removeBtn = document.createElement('button');
      removeBtn.className = 'btn-close btn-close-white ms-1';
      removeBtn.setAttribute('aria-label', 'Remove');
      removeBtn.style.fontSize = '0.5rem';
      
      // Set up remove button click handler
      removeBtn.addEventListener('click', function() {
        selectedPlates.splice(index, 1);
        updateSelectedPlates();
        updateBarbellWeight();
      });
      
      plateElement.appendChild(removeBtn);
      selectedPlatesDisplay.appendChild(plateElement);
    });
  }
  
  /**
   * Update the barbell total weight display
   */
  function updateBarbellWeight() {
    const totalWeight = Activity.calculateBarbellWeight(selectedPlates);
    barbellTotalWeight.textContent = totalWeight;
  }
  
  /**
   * Show/hide exercise presets based on workout category
   * @param {string} category - The workout category (cardio or weights)
   */
  function updateExercisePresets(category) {
    const cardioPresets = document.querySelectorAll('.cardio-presets');
    const weightPresets = document.querySelectorAll('.weight-presets');
    
    if (category === 'cardio') {
      cardioPresets.forEach(item => item.style.display = 'block');
      weightPresets.forEach(item => item.style.display = 'none');
    } else {
      cardioPresets.forEach(item => item.style.display = 'none');
      weightPresets.forEach(item => item.style.display = 'block');
    }
  }
}

/**
 * Update the water intake value display when the slider changes
 */
function updateWaterIntakeValue() {
  const slider = document.getElementById('water-intake');
  const valueDisplay = document.getElementById('water-intake-value');
  
  if (slider && valueDisplay) {
    valueDisplay.textContent = slider.value;
    
    // Update the value display when the slider changes
    slider.addEventListener('input', function() {
      valueDisplay.textContent = this.value;
    });
  }
}

/**
 * Open the health snapshot modal
 */
function openHealthSnapshotModal() {
  // Set default values
  document.getElementById('water-intake').value = 0;
  updateWaterIntakeValue();
  
  // Clear previous values
  document.getElementById('heart-rate').value = '';
  document.getElementById('energy-level').selectedIndex = 0;
  document.getElementById('hydration').selectedIndex = 0;
  document.getElementById('mood').selectedIndex = 0;
  document.getElementById('snapshot-notes').value = '';
  document.getElementById('include-location').checked = false;
  
  // Clear any previously selected stress level
  const stressRadios = document.querySelectorAll('input[name="stress-level"]');
  stressRadios.forEach(radio => radio.checked = false);
  
  // Show the modal
  const modal = new bootstrap.Modal(document.getElementById('healthSnapshotModal'));
  modal.show();
}

/**
 * Handle the health snapshot form submission
 * @param {Event} event - Form submission event
 */
function handleHealthSnapshotFormSubmit(event) {
  event.preventDefault();
  
  // Get values from the form
  const heartRate = parseInt(document.getElementById('heart-rate').value);
  const energyLevel = parseInt(document.getElementById('energy-level').value);
  const hydration = document.getElementById('hydration').value;
  const waterIntake = parseInt(document.getElementById('water-intake').value);
  const mood = parseInt(document.getElementById('mood').value);
  
  // Get selected stress level
  let stressLevel = 0;
  const selectedStressRadio = document.querySelector('input[name="stress-level"]:checked');
  if (selectedStressRadio) {
    stressLevel = parseInt(selectedStressRadio.value);
  }
  
  const notes = document.getElementById('snapshot-notes').value;
  const includeLocation = document.getElementById('include-location').checked;
  
  // Get location if requested
  let location = null;
  if (includeLocation) {
    // In a real app, we would use the Geolocation API
    // For this demo, we'll just use a placeholder
    location = {
      latitude: 40.7128,
      longitude: -74.0060,
      accuracy: 10,
      timestamp: new Date()
    };
  }
  
  // Create a new health snapshot
  const snapshot = new HealthSnapshot(
    heartRate,
    energyLevel,
    hydration,
    waterIntake,
    mood,
    stressLevel,
    notes,
    location
  );
  
  if (healthSnapshotTracker.addSnapshot(snapshot)) {
    // Update the UI
    updateHealthSnapshotWidget();
    
    // Reset the form
    event.target.reset();
    
    // Hide the modal
    const modal = bootstrap.Modal.getInstance(document.getElementById('healthSnapshotModal'));
    modal.hide();
    
    // Show success message
    showMessage('Health snapshot captured successfully!', 'success');
  } else {
    showMessage('Please fill in all required fields correctly.', 'danger');
  }
}

/**
 * Update the health snapshot widget with the most recent data
 */
function updateHealthSnapshotWidget() {
  // Get the most recent snapshot
  const recentSnapshot = healthSnapshotTracker.getMostRecentSnapshot();
  
  // Get the snapshot button
  const captureBtn = document.getElementById('capture-snapshot-btn');
  
  if (recentSnapshot) {
    // If there's a recent snapshot, update the button to show when it was taken
    if (captureBtn) {
      const timeAgo = getTimeAgo(recentSnapshot.timestamp);
      captureBtn.innerHTML = `
        <i class="bi bi-camera"></i> Update Snapshot
        <span class="d-block small mt-1">Last update: ${timeAgo}</span>
      `;
    }
  }
}

/**
 * Get a human-readable string for how long ago a date was
 * @param {Date} date - The date to check
 * @returns {string} Human-readable time difference
 */
function getTimeAgo(date) {
  const now = new Date();
  const diffMs = now - date;
  const diffSec = Math.floor(diffMs / 1000);
  const diffMin = Math.floor(diffSec / 60);
  const diffHour = Math.floor(diffMin / 60);
  const diffDay = Math.floor(diffHour / 24);
  
  if (diffDay > 0) {
    return diffDay === 1 ? '1 day ago' : `${diffDay} days ago`;
  } else if (diffHour > 0) {
    return diffHour === 1 ? '1 hour ago' : `${diffHour} hours ago`;
  } else if (diffMin > 0) {
    return diffMin === 1 ? '1 minute ago' : `${diffMin} minutes ago`;
  } else {
    return 'Just now';
  }
}

/**
 * Set up swipe-to-delete functionality for an element
 * @param {HTMLElement} element - The element to enable swipe-to-delete on
 * @param {string} itemId - ID of the item to delete when swiped
 */
function setupSwipeToDelete(element, itemId) {
  let touchStartX = 0;
  let touchEndX = 0;
  let touchStartY = 0;
  let touchEndY = 0;
  let initialTransform = 'translateX(0px)';
  let deleteThreshold = 100; // How far to swipe to trigger delete
  let isSwiping = false;
  let touchTarget = null;
  let resetTimeoutId = null;
  
  // Add a delete button that will be revealed on swipe
  const deleteButton = document.createElement('div');
  deleteButton.className = 'swipe-delete-btn';
  deleteButton.innerHTML = '<i class="bi bi-trash"></i>';
  deleteButton.style.cssText = `
    position: absolute;
    right: 0;
    top: 0;
    bottom: 0;
    background-color: #dc3545;
    color: white;
    display: flex;
    align-items: center;
    justify-content: center;
    width: 80px;
    opacity: 0;
    transition: opacity 0.3s;
  `;
  
  // Position the parent element for proper layering
  element.style.position = 'relative';
  element.style.overflow = 'hidden';
  
  // Add the card container to handle the sliding
  const cardContainer = element.querySelector('.card-body');
  if (cardContainer) {
    cardContainer.style.transition = 'transform 0.3s';
    element.appendChild(deleteButton);
    
    // Store the activity ID on the delete button
    deleteButton.dataset.itemId = itemId;
    
    // Add a reset method to this element
    element.resetSwipe = function() {
      // Skip reset if this card is no longer in the DOM
      if (!document.body.contains(element)) {
        return;
      }
      
      if (cardContainer) {
        // Clear any pending reset timeouts
        if (resetTimeoutId) {
          clearTimeout(resetTimeoutId);
          resetTimeoutId = null;
        }
        
        // Force a reflow to ensure smooth transition back
        void cardContainer.offsetWidth;
        
        // Reset card position
        cardContainer.style.transform = 'translateX(0)';
        deleteButton.style.opacity = '0';
        
        // Add a class briefly to help identify recently reset cards
        element.classList.add('just-reset');
        setTimeout(() => {
          if (document.body.contains(element)) {
            element.classList.remove('just-reset');
          }
        }, 300);
      }
    };
    
    // Find the view details button to exclude it from swipe handling
    const viewDetailsBtn = element.querySelector('.view-details-btn');
    
    // Touch event handlers
    element.addEventListener('touchstart', function(e) {
      // Don't initiate swipe if we're touching the view details button
      touchTarget = e.target;
      
      // Check if touch started on or inside the view details button
      if (viewDetailsBtn && (viewDetailsBtn === touchTarget || viewDetailsBtn.contains(touchTarget))) {
        return;
      }
      
      touchStartX = e.touches[0].clientX;
      touchStartY = e.touches[0].clientY;
      initialTransform = cardContainer.style.transform || 'translateX(0px)';
      isSwiping = false;
    }, { passive: true });
    
    element.addEventListener('touchmove', function(e) {
      // Don't handle swipe if we started on the view details button
      if (viewDetailsBtn && (viewDetailsBtn === touchTarget || viewDetailsBtn.contains(touchTarget))) {
        return;
      }
      
      touchEndX = e.touches[0].clientX;
      touchEndY = e.touches[0].clientY;
      
      // Determine if this is a horizontal swipe (and not a vertical scroll)
      const xDiff = touchStartX - touchEndX;
      const yDiff = Math.abs(touchStartY - touchEndY);
      
      // Only treat as swipe if horizontal movement is greater than vertical
      // and if we're moving left (negative values)
      if (xDiff > 10 && xDiff > yDiff) {
        isSwiping = true;
        
        // Only allow swiping left (negative values)
        if (xDiff > 0) {
          // Prevent scrolling when swiping horizontally
          e.preventDefault();
          
          cardContainer.style.transform = `translateX(-${xDiff}px)`;
          
          // Show delete button with appropriate opacity
          const opacity = Math.min(xDiff / deleteThreshold, 1);
          deleteButton.style.opacity = opacity;
        }
      }
    }, { passive: false });  // Set passive to false to allow preventDefault
    
    element.addEventListener('touchend', function(e) {
      // Don't handle swipe if we started on the view details button
      if (viewDetailsBtn && (viewDetailsBtn === touchTarget || viewDetailsBtn.contains(touchTarget))) {
        return;
      }
      
      // Only process if we were actually swiping horizontally
      if (isSwiping) {
        const swipeDistance = touchStartX - touchEndX;
        
        if (swipeDistance > deleteThreshold) {
          // Swiped far enough to delete - show the confirm dialog
          cardContainer.style.transform = 'translateX(-80px)';
          deleteButton.style.opacity = 1;
          
          // Clear any previous reset timeouts
          if (resetTimeoutId) {
            clearTimeout(resetTimeoutId);
          }
          
          // Set a timeout to reset the card if the user doesn't respond to the dialog
          resetTimeoutId = setTimeout(() => {
            // If the card is still in a swiped state after 3 seconds, reset it
            if (cardContainer.style.transform !== 'translateX(0px)' && 
                cardContainer.style.transform !== 'translateX(0)') {
              element.resetSwipe();
            }
          }, 3000);
          
          // Ask for confirmation
          if (confirm('Are you sure you want to delete this activity?')) {
            // If confirmed, animate fully and delete
            cardContainer.style.transform = 'translateX(-100%)';
            
            // Clear the reset timeout since we're proceeding with the deletion
            if (resetTimeoutId) {
              clearTimeout(resetTimeoutId);
            }
            
            // Delete after animation completes
            setTimeout(() => {
              handleDeleteActivity(itemId);
            }, 300);
          } else {
            // User canceled, animate back to original position
            element.resetSwipe();
          }
        } else {
          // Not swiped far enough, reset position
          element.resetSwipe();
        }
        
        // Reset swiping flag
        isSwiping = false;
      } else {
        // If we weren't swiping at all, make sure we're reset
        element.resetSwipe();
      }
      
      // Set an auto-reset timeout for any card that remains partially swiped
      // This handles cases where the user might tap away or not complete a swipe action
      setTimeout(() => {
        if (cardContainer.style.transform && 
            cardContainer.style.transform !== 'translateX(0px)' && 
            cardContainer.style.transform !== 'translateX(0)' &&
            cardContainer.style.transform !== 'translateX(-100%)') {
          // Only reset if in a partial state (not fully deleted or at rest)
          element.resetSwipe();
        }
      }, 3500);
    }, { passive: true });
    
    // Add click handler to delete button
    deleteButton.addEventListener('click', function(e) {
      e.stopPropagation();
      const itemToDelete = this.dataset.itemId;
      handleDeleteActivity(itemToDelete);
    });
  }
}