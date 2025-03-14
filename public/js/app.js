/**
 * Main application file that integrates all modules
 * and provides the UI interaction logic
 */

// Wait for the DOM to be fully loaded
document.addEventListener('DOMContentLoaded', function() {
  console.log('Health & Wellness App Initializing...');
  
  // Initialize both trackers
  initializeTrackers();
  
  // Set up event listeners for the UI
  setupEventListeners();
  
  // Update the dashboard with current data
  updateDashboard();
});

/**
 * Initialize trackers by loading data from localStorage
 */
function initializeTrackers() {
  // These are global instances declared in their respective files
  if (typeof tracker !== 'undefined') {
    tracker.loadFromLocalStorage();
    console.log('Fitness tracker loaded', tracker.getActivitiesCount(), 'activities');
  }
  
  if (typeof habitTracker !== 'undefined') {
    habitTracker.loadFromLocalStorage();
    console.log('Habit tracker loaded', habitTracker.getHabits().length, 'habits');
  }
}

/**
 * Set up all event listeners for the application
 */
function setupEventListeners() {
  // Activity form submission
  const activityForm = document.getElementById('add-activity-form');
  if (activityForm) {
    activityForm.addEventListener('submit', handleActivityFormSubmit);
  }
  
  // Steps form submission
  const stepsForm = document.getElementById('add-steps-form');
  if (stepsForm) {
    stepsForm.addEventListener('submit', handleStepsFormSubmit);
  }
  
  // Habit form submission
  const habitForm = document.getElementById('add-habit-form');
  if (habitForm) {
    habitForm.addEventListener('submit', handleHabitFormSubmit);
  }
  
  // Check-in form submission
  const checkInForm = document.getElementById('habit-check-in-form');
  if (checkInForm) {
    checkInForm.addEventListener('submit', handleCheckInFormSubmit);
  }
  
  // Delete habit buttons
  document.addEventListener('click', function(event) {
    if (event.target.classList.contains('delete-habit-btn')) {
      const habitId = event.target.dataset.habitId;
      deleteHabit(habitId);
    }
  });
  
  // Workout plan start buttons
  document.addEventListener('click', function(event) {
    if (event.target.classList.contains('start-workout-btn')) {
      const workoutId = event.target.dataset.workoutId;
      startWorkout(workoutId);
    }
  });
}

/**
 * Handle the activity form submission
 * @param {Event} event - Form submission event
 */
function handleActivityFormSubmit(event) {
  event.preventDefault();
  
  const nameInput = document.getElementById('activity-name');
  const caloriesInput = document.getElementById('activity-calories');
  const durationInput = document.getElementById('activity-duration');
  const typeInput = document.getElementById('activity-type');
  
  if (nameInput && caloriesInput && durationInput && typeInput) {
    const name = nameInput.value.trim();
    const calories = parseInt(caloriesInput.value);
    const duration = parseInt(durationInput.value);
    const type = typeInput.value;
    
    if (name && !isNaN(calories) && !isNaN(duration) && type) {
      const activity = new Activity(name, calories, duration, type);
      
      if (tracker.addActivity(activity)) {
        // Reset form
        event.target.reset();
        
        // Update UI
        updateDashboard();
        
        // Show success message
        showMessage('Activity added successfully!', 'success');
      } else {
        showMessage('Failed to add activity. Please check your inputs.', 'danger');
      }
    } else {
      showMessage('Please fill in all fields correctly.', 'warning');
    }
  }
}

/**
 * Handle the steps form submission
 * @param {Event} event - Form submission event
 */
function handleStepsFormSubmit(event) {
  event.preventDefault();
  
  const stepsInput = document.getElementById('steps-count-input');
  
  if (stepsInput) {
    const steps = parseInt(stepsInput.value);
    
    if (!isNaN(steps) && steps > 0) {
      if (tracker.addSteps(steps)) {
        // Reset form
        event.target.reset();
        
        // Update UI
        updateDashboard();
        
        // Show success message
        showMessage('Steps added successfully!', 'success');
      } else {
        showMessage('Failed to add steps. Please try again.', 'danger');
      }
    } else {
      showMessage('Please enter a valid number of steps.', 'warning');
    }
  }
}

/**
 * Handle the habit form submission
 * @param {Event} event - Form submission event
 */
function handleHabitFormSubmit(event) {
  event.preventDefault();
  
  const nameInput = document.getElementById('habit-name');
  const descriptionInput = document.getElementById('habit-description');
  const frequencyInput = document.getElementById('habit-frequency');
  const categoryInput = document.getElementById('habit-category');
  const triggerInput = document.getElementById('habit-trigger');
  const alternativeInput = document.getElementById('habit-alternative');
  const reminderTimeInput = document.getElementById('habit-reminder-time');
  
  if (nameInput && frequencyInput && categoryInput) {
    const name = nameInput.value.trim();
    const description = descriptionInput ? descriptionInput.value.trim() : '';
    const frequency = frequencyInput.value;
    const category = categoryInput.value;
    const trigger = triggerInput ? triggerInput.value.trim() : '';
    const alternative = alternativeInput ? alternativeInput.value.trim() : '';
    const reminderTime = reminderTimeInput ? reminderTimeInput.value : '';
    
    if (name && frequency && category) {
      const habit = new BadHabit(
        null, // ID will be generated
        name,
        description,
        frequency,
        category,
        trigger,
        alternative,
        reminderTime
      );
      
      if (habitTracker.addHabit(habit)) {
        // Reset form
        event.target.reset();
        
        // Update UI
        updateHabitsList();
        updateDashboard();
        
        // Show success message
        showMessage('Habit added successfully!', 'success');
      } else {
        showMessage('Failed to add habit. Please check your inputs.', 'danger');
      }
    } else {
      showMessage('Please fill in all required fields.', 'warning');
    }
  }
}

/**
 * Handle the habit check-in form submission
 * @param {Event} event - Form submission event
 */
function handleCheckInFormSubmit(event) {
  event.preventDefault();
  
  const habitIdInput = document.getElementById('check-in-habit-id');
  const successInput = document.getElementById('check-in-success');
  const dateInput = document.getElementById('check-in-date');
  
  if (habitIdInput && successInput) {
    const habitId = habitIdInput.value;
    const success = successInput.value === 'true';
    const date = dateInput && dateInput.value 
      ? new Date(dateInput.value) 
      : new Date();
    
    if (habitId) {
      const result = habitTracker.recordCheckIn(habitId, date, success);
      
      if (result) {
        // Reset form
        event.target.reset();
        
        // Update UI
        updateHabitsList();
        updateDashboard();
        
        // Show success message
        showMessage('Check-in recorded successfully!', 'success');
      } else {
        showMessage('Failed to record check-in. Please try again.', 'danger');
      }
    } else {
      showMessage('Please select a habit to check in.', 'warning');
    }
  }
}

/**
 * Delete a habit
 * @param {string} habitId - ID of the habit to delete
 */
function deleteHabit(habitId) {
  if (confirm('Are you sure you want to delete this habit? This action cannot be undone.')) {
    if (habitTracker.deleteHabit(habitId)) {
      // Update UI
      updateHabitsList();
      updateDashboard();
      
      // Show success message
      showMessage('Habit deleted successfully!', 'success');
    } else {
      showMessage('Failed to delete habit. Please try again.', 'danger');
    }
  }
}

/**
 * Start a workout plan
 * @param {string} workoutId - ID of the workout to start
 */
function startWorkout(workoutId) {
  // This would integrate with the workout plans module
  console.log('Starting workout:', workoutId);
  showMessage('Workout started! Let\'s get moving!', 'success');
}

/**
 * Update the dashboard with current data
 */
function updateDashboard() {
  // Update fitness stats
  if (typeof tracker !== 'undefined') {
    updateFitnessStats();
    updateActivitiesList();
  }
  
  // Update habit stats
  if (typeof habitTracker !== 'undefined') {
    updateHabitStats();
    updateHabitsList();
  }
}

/**
 * Update fitness statistics on the dashboard
 */
function updateFitnessStats() {
  const stepsCount = document.getElementById('steps-count');
  const caloriesCount = document.getElementById('calories-count');
  const activitiesCount = document.getElementById('activities-count');
  
  if (stepsCount) {
    stepsCount.textContent = tracker.getTotalSteps().toLocaleString();
  }
  
  if (caloriesCount) {
    caloriesCount.textContent = tracker.getTotalCalories().toLocaleString();
  }
  
  if (activitiesCount) {
    activitiesCount.textContent = tracker.getActivitiesCount().toLocaleString();
  }
}

/**
 * Update the activities list on the dashboard
 */
function updateActivitiesList() {
  const activitiesList = document.getElementById('activities-list');
  const noActivitiesMsg = document.getElementById('no-activities');
  
  if (activitiesList) {
    const activities = tracker.getActivities();
    
    // Clear current list
    activitiesList.innerHTML = '';
    
    if (activities.length === 0) {
      if (noActivitiesMsg) {
        noActivitiesMsg.style.display = 'block';
      }
    } else {
      if (noActivitiesMsg) {
        noActivitiesMsg.style.display = 'none';
      }
      
      // Sort activities by date (newest first)
      activities.sort((a, b) => new Date(b.date) - new Date(a.date));
      
      // Add activities to the list
      activities.forEach(activity => {
        const activityElement = createActivityElement(activity);
        activitiesList.appendChild(activityElement);
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
  
  if (habitsCount || currentStreakCount || successRateCount) {
    const stats = habitTracker.getOverallProgress();
    
    if (habitsCount) {
      habitsCount.textContent = stats.totalHabits.toLocaleString();
    }
    
    if (currentStreakCount) {
      // Find the maximum current streak across all habits
      const maxCurrentStreak = habitTracker.getHabits().reduce(
        (max, habit) => Math.max(max, habit.streak.current), 0
      );
      currentStreakCount.textContent = maxCurrentStreak.toLocaleString();
    }
    
    if (successRateCount) {
      successRateCount.textContent = stats.successRate.toFixed(1) + '%';
    }
  }
}

/**
 * Update the habits list on the dashboard
 */
function updateHabitsList() {
  const habitsList = document.getElementById('habits-list');
  const noHabitsMsg = document.getElementById('no-habits');
  
  if (habitsList) {
    const habits = habitTracker.getHabits();
    
    // Clear current list
    habitsList.innerHTML = '';
    
    if (habits.length === 0) {
      if (noHabitsMsg) {
        noHabitsMsg.style.display = 'block';
      }
    } else {
      if (noHabitsMsg) {
        noHabitsMsg.style.display = 'none';
      }
      
      // Sort habits by name
      habits.sort((a, b) => a.name.localeCompare(b.name));
      
      // Add habits to the list
      habits.forEach(habit => {
        const habitElement = createHabitElement(habit);
        habitsList.appendChild(habitElement);
      });
    }
  }
}

/**
 * Create a habit element to display
 * @param {BadHabit} habit - The habit to create an element for
 * @returns {HTMLElement} The created element
 */
function createHabitElement(habit) {
  const habitElement = document.createElement('div');
  habitElement.className = 'habit-item mb-3 p-3 border rounded';
  habitElement.dataset.habitId = habit.id;
  
  // Get the category icon
  let categoryIcon = 'bi-question-circle';
  let categoryColor = '#6c757d';
  
  switch (habit.category.toLowerCase()) {
    case 'screen':
      categoryIcon = 'bi-phone';
      categoryColor = '#e74c3c';
      break;
    case 'food':
      categoryIcon = 'bi-cup-hot';
      categoryColor = '#f39c12';
      break;
    case 'productivity':
      categoryIcon = 'bi-hourglass';
      categoryColor = '#3498db';
      break;
    case 'health':
      categoryIcon = 'bi-heart';
      categoryColor = '#2ecc71';
      break;
    case 'spending':
      categoryIcon = 'bi-cash-coin';
      categoryColor = '#9b59b6';
      break;
  }
  
  // Calculate days since start
  const daysSinceStart = habit.getDaysSinceStart();
  
  habitElement.innerHTML = `
    <div class="d-flex justify-content-between align-items-start">
      <div class="d-flex">
        <div class="habit-icon me-3" style="color: ${categoryColor}">
          <i class="${categoryIcon} fs-4"></i>
        </div>
        <div>
          <h5 class="mb-1">${habit.name}</h5>
          <div class="text-muted small mb-2">${habit.description || 'No description'}</div>
          <div class="d-flex flex-wrap mt-2">
            <span class="badge bg-secondary me-2 mb-1">${habit.frequency}</span>
            <span class="badge bg-info me-2 mb-1">${daysSinceStart} days</span>
            <span class="badge bg-success me-2 mb-1">${habit.streak.current} day streak</span>
          </div>
        </div>
      </div>
      <div>
        <button class="btn btn-sm btn-outline-danger delete-habit-btn" data-habit-id="${habit.id}">
          <i class="bi bi-trash"></i>
        </button>
      </div>
    </div>
    
    <div class="mt-3">
      <div class="progress" style="height: 8px;">
        <div class="progress-bar bg-success" role="progressbar" 
             style="width: ${habit.streak.current * 10}%;" 
             aria-valuenow="${habit.streak.current}" 
             aria-valuemin="0" 
             aria-valuemax="10"></div>
      </div>
      <div class="d-flex justify-content-between mt-1">
        <small class="text-muted">Current streak: ${habit.streak.current} days</small>
        <small class="text-muted">Longest: ${habit.streak.longest} days</small>
      </div>
    </div>
    
    <div class="mt-3">
      <button class="btn btn-sm btn-primary check-in-btn" 
              onclick="openCheckInModal('${habit.id}', '${habit.name}')">
        <i class="bi bi-check2-circle me-1"></i> Check-in
      </button>
      <button class="btn btn-sm btn-outline-secondary view-details-btn"
              onclick="viewHabitDetails('${habit.id}')">
        <i class="bi bi-graph-up me-1"></i> View Progress
      </button>
    </div>
  `;
  
  return habitElement;
}

/**
 * Open the check-in modal for a habit
 * @param {string} habitId - ID of the habit to check in
 * @param {string} habitName - Name of the habit to display
 */
function openCheckInModal(habitId, habitName) {
  const modal = document.getElementById('check-in-modal');
  const habitIdInput = document.getElementById('check-in-habit-id');
  const modalTitle = document.querySelector('#check-in-modal .modal-title');
  
  if (modal && habitIdInput && modalTitle) {
    habitIdInput.value = habitId;
    modalTitle.textContent = `Check-in: ${habitName}`;
    
    // Open the modal using Bootstrap's modal method
    const bsModal = new bootstrap.Modal(modal);
    bsModal.show();
  }
}

/**
 * View detailed progress for a habit
 * @param {string} habitId - ID of the habit to view
 */
function viewHabitDetails(habitId) {
  const habit = habitTracker.getHabitById(habitId);
  
  if (habit) {
    // This would open a detailed view of the habit progress
    console.log('Viewing details for habit:', habit.name);
    alert(`Detailed progress view for ${habit.name} will be implemented in a future update.`);
  }
}

/**
 * Display a message to the user
 * @param {string} message - Message to display
 * @param {string} type - Type of message (success, danger, warning, info)
 */
function showMessage(message, type = 'info') {
  // Create toast element
  const toastContainer = document.getElementById('toast-container');
  
  if (!toastContainer) {
    // Create a toast container if it doesn't exist
    const container = document.createElement('div');
    container.id = 'toast-container';
    container.className = 'toast-container position-fixed bottom-0 end-0 p-3';
    document.body.appendChild(container);
  }
  
  const toastId = 'toast-' + Date.now();
  const toast = document.createElement('div');
  toast.className = `toast align-items-center text-white bg-${type} border-0`;
  toast.setAttribute('role', 'alert');
  toast.setAttribute('aria-live', 'assertive');
  toast.setAttribute('aria-atomic', 'true');
  toast.id = toastId;
  
  toast.innerHTML = `
    <div class="d-flex">
      <div class="toast-body">
        ${message}
      </div>
      <button type="button" class="btn-close btn-close-white me-2 m-auto" data-bs-dismiss="toast" aria-label="Close"></button>
    </div>
  `;
  
  document.getElementById('toast-container').appendChild(toast);
  
  // Use Bootstrap's toast method to show the toast
  const bsToast = new bootstrap.Toast(toast);
  bsToast.show();
  
  // Remove the toast after it's hidden
  toast.addEventListener('hidden.bs.toast', function() {
    document.getElementById(toastId).remove();
  });
}