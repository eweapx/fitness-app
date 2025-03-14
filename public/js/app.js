// Initialize the trackers
const fitnessTracker = new FitnessTracker();
const habitTracker = new HabitTracker();

// Set up event listeners when the document is ready
document.addEventListener('DOMContentLoaded', function() {
  console.log('Health & Wellness App Initializing...');
  
  // Initialize trackers by loading data from localStorage
  initializeTrackers();
  
  // Set up event listeners for all forms and interactive elements
  setupEventListeners();
  
  // Update the dashboard with initial data
  updateDashboard();
});

/**
 * Initialize trackers by loading data from localStorage
 */
function initializeTrackers() {
  // Load data from localStorage via the tracker classes
  console.log('Fitness tracker loaded', fitnessTracker.getActivitiesCount(), 'activities');
  console.log('Habit tracker loaded', habitTracker.getHabits().length, 'habits');
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
}

/**
 * Handle the activity form submission
 * @param {Event} event - Form submission event
 */
function handleActivityFormSubmit(event) {
  event.preventDefault();
  
  // Get form values
  const name = document.getElementById('activity-name').value;
  const calories = document.getElementById('activity-calories').value;
  const duration = document.getElementById('activity-duration').value;
  const type = document.getElementById('activity-type').value;
  
  // Create and add the activity
  const activity = new Activity(name, calories, duration, type);
  
  if (fitnessTracker.addActivity(activity)) {
    // Close the modal
    const modal = bootstrap.Modal.getInstance(document.getElementById('logActivityModal'));
    modal.hide();
    
    // Reset the form
    event.target.reset();
    
    // Update the dashboard
    updateDashboard();
    
    // Show success message
    showMessage('Activity logged successfully!', 'success');
  } else {
    // Show error message
    showMessage('Please fill in all required fields correctly.', 'danger');
  }
}

/**
 * Handle the steps form submission
 * @param {Event} event - Form submission event
 */
function handleStepsFormSubmit(event) {
  event.preventDefault();
  
  // Get steps value
  const steps = document.getElementById('steps-count-input').value;
  
  if (fitnessTracker.addSteps(steps)) {
    // Close the modal
    const modal = bootstrap.Modal.getInstance(document.getElementById('addStepsModal'));
    modal.hide();
    
    // Reset the form
    event.target.reset();
    
    // Update the dashboard
    updateDashboard();
    
    // Show success message
    showMessage('Steps added successfully!', 'success');
  } else {
    // Show error message
    showMessage('Please enter a valid number of steps.', 'danger');
  }
}

/**
 * Handle the habit form submission
 * @param {Event} event - Form submission event
 */
function handleHabitFormSubmit(event) {
  event.preventDefault();
  
  // Get form values
  const name = document.getElementById('habit-name').value;
  const description = document.getElementById('habit-description').value;
  const frequency = document.getElementById('habit-frequency').value;
  const category = document.getElementById('habit-category').value;
  const trigger = document.getElementById('habit-trigger').value;
  const alternative = document.getElementById('habit-alternative').value;
  const reminderTime = document.getElementById('habit-reminder-time').value;
  
  // Create and add the habit
  const habit = new BadHabit(
    null, // id will be generated automatically
    name,
    description,
    frequency,
    category,
    trigger,
    alternative,
    reminderTime
  );
  
  if (habitTracker.addHabit(habit)) {
    // Close the modal
    const modal = bootstrap.Modal.getInstance(document.getElementById('addHabitModal'));
    modal.hide();
    
    // Reset the form
    event.target.reset();
    
    // Update the dashboard
    updateDashboard();
    
    // Show success message
    showMessage('Habit added successfully!', 'success');
  } else {
    // Show error message
    showMessage('Please fill in all required fields.', 'danger');
  }
}

/**
 * Handle the habit check-in form submission
 * @param {Event} event - Form submission event
 */
function handleCheckInFormSubmit(event) {
  event.preventDefault();
  
  // Get form values
  const habitId = document.getElementById('check-in-habit-id').value;
  const dateStr = document.getElementById('check-in-date').value;
  const success = document.querySelector('input[name="check-in-success"]:checked').value === 'true';
  
  // Create date object
  const date = new Date(dateStr);
  
  // Record the check-in
  const result = habitTracker.recordCheckIn(habitId, date, success);
  
  if (result) {
    // Close the modal
    const modal = bootstrap.Modal.getInstance(document.getElementById('check-in-modal'));
    modal.hide();
    
    // Update the dashboard
    updateDashboard();
    
    // Show success message
    const message = success 
      ? `Great job! You've maintained a streak of ${result.currentStreak} days.` 
      : 'Check-in recorded. Keep trying, you can do it!';
    
    showMessage(message, success ? 'success' : 'warning');
  } else {
    // Show error message
    showMessage('Error recording check-in. Please try again.', 'danger');
  }
}

/**
 * Delete a habit
 * @param {string} habitId - ID of the habit to delete
 */
function deleteHabit(habitId) {
  if (confirm('Are you sure you want to delete this habit tracking? This cannot be undone.')) {
    if (habitTracker.deleteHabit(habitId)) {
      // Update the dashboard
      updateDashboard();
      
      // Show success message
      showMessage('Habit deleted successfully.', 'success');
    } else {
      // Show error message
      showMessage('Error deleting habit. Please try again.', 'danger');
    }
  }
}

/**
 * Open the check-in modal for a habit
 * @param {string} habitId - ID of the habit to check in
 * @param {string} habitName - Name of the habit to display
 */
function openCheckInModal(habitId, habitName) {
  // Set the habit ID in the hidden field
  document.getElementById('check-in-habit-id').value = habitId;
  
  // Update the modal title
  const modalTitle = document.querySelector('#check-in-modal .modal-title');
  modalTitle.textContent = `Check-in for: ${habitName}`;
  
  // Set today's date as default
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
 * Update the dashboard with current data
 */
function updateDashboard() {
  // Update fitness statistics
  updateFitnessStats();
  
  // Update activities list
  updateActivitiesList();
  
  // Update habit statistics
  updateHabitStats();
  
  // Update habits list
  updateHabitsList();
}

/**
 * Update fitness statistics on the dashboard
 */
function updateFitnessStats() {
  // Update steps count
  const stepsCountElement = document.getElementById('steps-count');
  if (stepsCountElement) {
    stepsCountElement.textContent = fitnessTracker.getTotalSteps().toLocaleString();
  }
  
  // Update calories count
  const caloriesCountElement = document.getElementById('calories-count');
  if (caloriesCountElement) {
    caloriesCountElement.textContent = fitnessTracker.getTotalCalories().toLocaleString();
  }
  
  // Update activities count
  const activitiesCountElement = document.getElementById('activities-count');
  if (activitiesCountElement) {
    activitiesCountElement.textContent = fitnessTracker.getActivitiesCount().toLocaleString();
  }
}

/**
 * Update the activities list on the dashboard
 */
function updateActivitiesList() {
  // Get elements
  const activitiesListElement = document.getElementById('activities-list');
  const noActivitiesElement = document.getElementById('no-activities');
  const allActivitiesListElement = document.getElementById('all-activities-list');
  const noAllActivitiesElement = document.getElementById('no-all-activities');
  
  // Get activities
  const activities = fitnessTracker.getActivities();
  
  // Check if we have activities
  if (activities.length > 0) {
    // Hide "no activities" message on the dashboard
    if (noActivitiesElement) {
      noActivitiesElement.style.display = 'none';
    }
    
    // Hide "no activities" message on the activities tab
    if (noAllActivitiesElement) {
      noAllActivitiesElement.style.display = 'none';
    }
    
    // Update dashboard activities list (recent 3)
    if (activitiesListElement) {
      activitiesListElement.innerHTML = '';
      
      // Display the 3 most recent activities
      const recentActivities = [...activities].sort((a, b) => b.date - a.date).slice(0, 3);
      
      recentActivities.forEach(activity => {
        const activityElement = document.createElement('div');
        activityElement.className = 'activity-item d-flex align-items-center mb-3 p-2 border-bottom';
        
        // Determine icon class based on activity type
        let iconClass = 'bi-activity';
        let iconBg = 'bg-primary';
        
        if (activity.type === 'running') {
          iconClass = 'bi-emoji-smile';
          iconBg = 'bg-success';
        } else if (activity.type === 'cycling') {
          iconClass = 'bi-bicycle';
          iconBg = 'bg-info';
        } else if (activity.type === 'weights') {
          iconClass = 'bi-vinyl';
          iconBg = 'bg-danger';
        } else if (activity.type === 'swimming') {
          iconClass = 'bi-water';
          iconBg = 'bg-warning';
        }
        
        activityElement.innerHTML = `
          <div class="activity-icon ${iconBg} text-white">
            <i class="bi ${iconClass}"></i>
          </div>
          <div>
            <h6 class="mb-0">${activity.name}</h6>
            <div class="text-muted small d-flex">
              <span class="me-3"><i class="bi bi-stopwatch me-1"></i> ${activity.duration} min</span>
              <span><i class="bi bi-fire me-1"></i> ${activity.calories} cal</span>
            </div>
            <div class="text-muted small">${activity.getFormattedDate()}</div>
          </div>
        `;
        
        activitiesListElement.appendChild(activityElement);
      });
    }
    
    // Update all activities list
    if (allActivitiesListElement) {
      allActivitiesListElement.innerHTML = '';
      
      // Sort by date (newest first)
      const sortedActivities = [...activities].sort((a, b) => b.date - a.date);
      
      sortedActivities.forEach(activity => {
        const activityElement = document.createElement('div');
        activityElement.className = 'activity-item d-flex align-items-center mb-3 p-2 border-bottom';
        
        // Determine icon class based on activity type
        let iconClass = 'bi-activity';
        let iconBg = 'bg-primary';
        
        if (activity.type === 'running') {
          iconClass = 'bi-emoji-smile';
          iconBg = 'bg-success';
        } else if (activity.type === 'cycling') {
          iconClass = 'bi-bicycle';
          iconBg = 'bg-info';
        } else if (activity.type === 'weights') {
          iconClass = 'bi-vinyl';
          iconBg = 'bg-danger';
        } else if (activity.type === 'swimming') {
          iconClass = 'bi-water';
          iconBg = 'bg-warning';
        }
        
        activityElement.innerHTML = `
          <div class="activity-icon ${iconBg} text-white">
            <i class="bi ${iconClass}"></i>
          </div>
          <div class="flex-grow-1">
            <h6 class="mb-0">${activity.name}</h6>
            <div class="text-muted small d-flex">
              <span class="me-3"><i class="bi bi-stopwatch me-1"></i> ${activity.duration} min</span>
              <span><i class="bi bi-fire me-1"></i> ${activity.calories} cal</span>
            </div>
            <div class="text-muted small">${activity.getFormattedDate()}</div>
          </div>
        `;
        
        allActivitiesListElement.appendChild(activityElement);
      });
    }
  } else {
    // Show "no activities" message on the dashboard
    if (noActivitiesElement) {
      noActivitiesElement.style.display = 'block';
    }
    
    // Show "no activities" message on the activities tab
    if (noAllActivitiesElement) {
      noAllActivitiesElement.style.display = 'block';
    }
    
    // Clear activities lists
    if (activitiesListElement) {
      activitiesListElement.innerHTML = '';
    }
    
    if (allActivitiesListElement) {
      allActivitiesListElement.innerHTML = '';
    }
  }
}

/**
 * Update habit statistics on the dashboard
 */
function updateHabitStats() {
  // Get overall progress
  const progress = habitTracker.getOverallProgress();
  
  // Update habits count
  const habitsCountElement = document.getElementById('habits-count');
  if (habitsCountElement) {
    habitsCountElement.textContent = progress.totalHabits.toLocaleString();
  }
  
  // Update current streak count
  const currentStreakElement = document.getElementById('current-streak-count');
  if (currentStreakElement) {
    currentStreakElement.textContent = progress.avgCurrentStreak.toLocaleString();
  }
  
  // Update success rate
  const successRateElement = document.getElementById('success-rate-count');
  if (successRateElement) {
    successRateElement.textContent = `${progress.successRate}%`;
  }
}

/**
 * Update the habits list on the dashboard
 */
function updateHabitsList() {
  // Get elements
  const habitsListElement = document.getElementById('habits-list');
  const noHabitsElement = document.getElementById('no-habits');
  const allHabitsListElement = document.getElementById('all-habits-list');
  const noAllHabitsElement = document.getElementById('no-all-habits');
  
  // Get habits
  const habits = habitTracker.getHabits();
  
  // Check if we have habits
  if (habits.length > 0) {
    // Hide "no habits" message on the dashboard
    if (noHabitsElement) {
      noHabitsElement.style.display = 'none';
    }
    
    // Hide "no habits" message on the habits tab
    if (noAllHabitsElement) {
      noAllHabitsElement.style.display = 'none';
    }
    
    // Update dashboard habits list (recent 3)
    if (habitsListElement) {
      habitsListElement.innerHTML = '';
      
      // Display up to 3 habits
      const displayHabits = habits.slice(0, 3);
      
      displayHabits.forEach(habit => {
        const habitElement = createHabitElement(habit);
        habitsListElement.appendChild(habitElement);
      });
    }
    
    // Update all habits list
    if (allHabitsListElement) {
      allHabitsListElement.innerHTML = '';
      
      habits.forEach(habit => {
        const habitElement = createHabitElement(habit, true);
        allHabitsListElement.appendChild(habitElement);
      });
    }
  } else {
    // Show "no habits" message on the dashboard
    if (noHabitsElement) {
      noHabitsElement.style.display = 'block';
    }
    
    // Show "no habits" message on the habits tab
    if (noAllHabitsElement) {
      noAllHabitsElement.style.display = 'block';
    }
    
    // Clear habits lists
    if (habitsListElement) {
      habitsListElement.innerHTML = '';
    }
    
    if (allHabitsListElement) {
      allHabitsListElement.innerHTML = '';
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
  const habitElement = document.createElement('div');
  habitElement.className = 'habit-item d-flex align-items-center mb-3 p-2 border-bottom';
  
  // Determine icon class based on habit category
  let iconClass = 'bi-exclamation-triangle';
  let iconBg = 'bg-secondary';
  
  if (habit.category === 'screen') {
    iconClass = 'bi-phone';
    iconBg = 'bg-info';
  } else if (habit.category === 'food') {
    iconClass = 'bi-cup-straw';
    iconBg = 'bg-danger';
  } else if (habit.category === 'productivity') {
    iconClass = 'bi-alarm';
    iconBg = 'bg-warning';
  } else if (habit.category === 'health') {
    iconClass = 'bi-heart';
    iconBg = 'bg-danger';
  } else if (habit.category === 'spending') {
    iconClass = 'bi-cash-coin';
    iconBg = 'bg-success';
  }
  
  // Create the basic habit item
  let habitHTML = `
    <div class="habit-icon ${iconBg} text-white">
      <i class="bi ${iconClass}"></i>
    </div>
    <div class="flex-grow-1">
      <div class="d-flex justify-content-between align-items-center">
        <h6 class="mb-0">${habit.name}</h6>
        <div>
          <span class="badge bg-primary me-2">${habit.currentStreak} days</span>
          <button class="btn btn-sm btn-outline-success me-1" onclick="openCheckInModal('${habit.id}', '${habit.name}')">
            <i class="bi bi-check-circle"></i> Check-in
          </button>
          <button class="btn btn-sm btn-outline-danger" onclick="deleteHabit('${habit.id}')">
            <i class="bi bi-trash"></i>
          </button>
        </div>
      </div>
      <div class="text-muted small">Tracking since ${habit.getFormattedStartDate()}</div>
  `;
  
  // Add additional details if requested
  if (showDetails) {
    habitHTML += `
      <div class="mt-2">
        <div class="mb-1">
          <strong>Why quit:</strong> ${habit.description || 'Not specified'}
        </div>
        <div class="mb-1">
          <strong>Frequency:</strong> ${habit.frequency}
        </div>
        <div class="mb-1">
          <strong>Trigger:</strong> ${habit.trigger || 'Not specified'}
        </div>
        <div class="mb-1">
          <strong>Alternative:</strong> ${habit.alternative || 'Not specified'}
        </div>
        <div class="progress mt-2" style="height: 10px;">
          <div class="progress-bar bg-success" role="progressbar" style="width: ${habit.currentStreak * 10}%"></div>
        </div>
      </div>
    `;
  }
  
  habitHTML += '</div>';
  habitElement.innerHTML = habitHTML;
  
  return habitElement;
}

/**
 * Display a message to the user
 * @param {string} message - Message to display
 * @param {string} type - Type of message (success, danger, warning, info)
 */
function showMessage(message, type = 'info') {
  // Create toast element
  const toastElement = document.createElement('div');
  toastElement.className = `toast align-items-center text-white bg-${type} border-0`;
  toastElement.setAttribute('role', 'alert');
  toastElement.setAttribute('aria-live', 'assertive');
  toastElement.setAttribute('aria-atomic', 'true');
  
  toastElement.innerHTML = `
    <div class="d-flex">
      <div class="toast-body">
        ${message}
      </div>
      <button type="button" class="btn-close btn-close-white me-2 m-auto" data-bs-dismiss="toast" aria-label="Close"></button>
    </div>
  `;
  
  // Add the toast to the container
  const toastContainer = document.getElementById('toast-container');
  toastContainer.appendChild(toastElement);
  
  // Initialize and show the toast
  const toast = new bootstrap.Toast(toastElement, { autohide: true, delay: 3000 });
  toast.show();
  
  // Remove the toast after it's hidden
  toastElement.addEventListener('hidden.bs.toast', function() {
    toastElement.remove();
  });
}