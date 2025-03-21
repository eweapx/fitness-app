/**
 * Main application logic for the Health & Wellness Tracker
 */

// Initialize all trackers
console.log('Health & Wellness App Initializing...');

// Initialize the fitness tracker
window.fitnessTracker = new FitnessTracker();
window.fitnessTracker.loadFromLocalStorage();
console.log('Fitness tracker loaded', window.fitnessTracker.getActivities().length, 'activities');

// Initialize the habit tracker
window.habitTracker = new HabitTracker();
window.habitTracker.loadFromLocalStorage();
console.log('Habit tracker loaded', window.habitTracker.getHabits().length, 'habits');

// Initialize the nutrition tracker
window.nutritionTracker = new NutritionTracker();
window.nutritionTracker.loadFromLocalStorage();
console.log('Nutrition tracker loaded', window.nutritionTracker.getMeals().length, 'meals');

// Initialize the sleep tracker
window.sleepTracker = new SleepTracker();
window.sleepTracker.loadFromLocalStorage();
console.log('Sleep tracker loaded', window.sleepTracker.getSleepRecords().length, 'records');

// Initialize the health connection manager
window.healthConnectionManager = new HealthConnectionManager();
window.healthConnectionManager.loadFromLocalStorage();
console.log('Health connections loaded', window.healthConnectionManager.getConnections().length, 'connections');

// Initialize the health snapshot tracker
window.healthSnapshotTracker = new HealthSnapshotTracker();
window.healthSnapshotTracker.loadFromLocalStorage();
console.log('Health snapshots loaded', window.healthSnapshotTracker.getSnapshots().length, 'snapshots');

// Initialize form speech input
window.formSpeechInput = new FormSpeechInput();
console.log('Form speech input initialized');

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
  
  // Initialize speech recognition for voice commands
  initializeSpeechRecognition();
  
  // Sync data from all health connections if any exist
  if (window.healthConnectionManager.getConnections().length > 0) {
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
  
  window.healthConnectionManager.syncAllConnections()
    .then(results => {
      // Process all the synced data
      if (results.results && results.results.length > 0) {
        results.results.forEach(result => {
          if (result.data) {
            // Update steps if available
            if (result.data.steps && result.data.steps > 0) {
              window.fitnessTracker.addSteps(result.data.steps);
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
                window.fitnessTracker.addActivity(activity);
              });
            }
            
            // Add sleep data if available
            if (result.data.sleep && window.sleepTracker) {
              const sleep = result.data.sleep;
              const sleepRecord = new SleepRecord(
                new Date(sleep.startTime),
                new Date(sleep.endTime),
                sleep.quality,
                'Synced from connected device',
                []
              );
              window.sleepTracker.addSleepRecord(sleepRecord);
            }
          }
        });
        
        // Save updated data
        window.fitnessTracker.saveToLocalStorage();
        window.sleepTracker.saveToLocalStorage();
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
  // Tab navigation - handle section switching
  const navLinks = document.querySelectorAll('[data-section]');
  navLinks.forEach(link => {
    link.addEventListener('click', function(e) {
      e.preventDefault();
      const targetSection = this.getAttribute('data-section');
      showSection(targetSection);
      
      // Update active state in nav
      document.querySelectorAll('.nav-link').forEach(navLink => {
        navLink.classList.remove('active');
      });
      if (this.classList.contains('nav-link')) {
        this.classList.add('active');
      }
    });
  });
  
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
  
  // Deload (Habit Breaking) form
  const addHabitForm = document.getElementById('add-habit-form');
  if (addHabitForm) {
    addHabitForm.addEventListener('submit', handleHabitFormSubmit);
    
    // Show/hide custom habit field based on selection
    const habitTypeSelect = document.getElementById('habit-type');
    if (habitTypeSelect) {
      habitTypeSelect.addEventListener('change', function() {
        const customHabitContainer = document.getElementById('custom-habit-container');
        if (this.value === 'other') {
          customHabitContainer.classList.remove('d-none');
        } else {
          customHabitContainer.classList.add('d-none');
        }
      });
    }
    
    // Update deload duration value display
    const deloadDurationSlider = document.getElementById('deload-duration');
    if (deloadDurationSlider) {
      deloadDurationSlider.addEventListener('input', function() {
        document.getElementById('deload-duration-value').textContent = this.value + ' days';
      });
    }
  }
  
  // Check-in form
  const checkInForm = document.getElementById('check-in-form');
  if (checkInForm) {
    checkInForm.addEventListener('submit', handleCheckInFormSubmit);
    
    // Show difficulty rating when user clicks success/failure buttons
    const successBtn = document.getElementById('checkin-success');
    const failureBtn = document.getElementById('checkin-failure');
    
    if (successBtn && failureBtn) {
      successBtn.addEventListener('click', function() {
        this.classList.add('active');
        failureBtn.classList.remove('active');
        document.getElementById('difficulty-container').classList.remove('d-none');
        checkInForm.setAttribute('data-success', 'true');
      });
      
      failureBtn.addEventListener('click', function() {
        this.classList.add('active');
        successBtn.classList.remove('active');
        document.getElementById('difficulty-container').classList.remove('d-none');
        checkInForm.setAttribute('data-success', 'false');
      });
    }
  }
  
  // Deload view toggle (list vs calendar)
  const habitViewButtons = document.querySelectorAll('[data-habits-view]');
  habitViewButtons.forEach(button => {
    button.addEventListener('click', function() {
      const view = this.getAttribute('data-habits-view');
      toggleHabitsView(view);
      
      // Update active state
      habitViewButtons.forEach(btn => btn.classList.remove('active'));
      this.classList.add('active');
    });
  });
  
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
  
  if (window.fitnessTracker.addActivity(activity)) {
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
  
  if (window.fitnessTracker.addSteps(steps)) {
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
  
  // Check if we're using a predefined habit or custom one
  const habitType = document.getElementById('habit-type')?.value;
  let name = '';
  
  if (habitType === 'other') {
    // Get the custom habit name from the custom field
    name = document.getElementById('custom-habit-name')?.value;
  } else {
    // Use the selected habit from the dropdown
    name = document.getElementById('habit-type')?.options[document.getElementById('habit-type')?.selectedIndex]?.text || '';
  }
  
  // Get other form values
  const description = document.getElementById('habit-description').value;
  const frequency = document.getElementById('habit-frequency').value;
  const frequencyUnit = document.getElementById('frequency-unit')?.value || 'daily';
  const category = document.getElementById('habit-category').value;
  const trigger = document.getElementById('habit-trigger').value;
  const alternative = document.getElementById('habit-alternative').value;
  const reminderTime = document.getElementById('habit-reminder-time').value;
  const deloadDuration = document.getElementById('deload-duration')?.value || 21;
  
  const habitId = 'habit_' + Date.now();
  const habit = new BadHabit(
    habitId,
    name,
    description,
    frequency,
    frequencyUnit,
    category,
    trigger,
    alternative,
    reminderTime,
    deloadDuration
  );
  
  if (window.habitTracker.addHabit(habit)) {
    // Update the UI
    updateDashboard();
    
    // Reset the form
    event.target.reset();
    
    // Hide the modal
    const modal = bootstrap.Modal.getInstance(document.getElementById('addHabitModal'));
    modal.hide();
    
    // Show success message
    showMessage(`Starting 21-day deload for "${name}" - Check in daily to track your progress!`, 'success');
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
  const successValue = event.target.getAttribute('data-success') === 'true';
  const dateStr = document.getElementById('check-in-date').value;
  const date = new Date(dateStr);
  const difficultyLevel = parseInt(document.querySelector('input[name="difficulty-level"]:checked')?.value || '3');
  const notes = document.getElementById('check-in-notes')?.value || '';
  
  // Record the check-in
  const result = window.habitTracker.recordCheckIn(habitId, date, successValue);
  
  if (result) {
    // Record the difficulty level
    window.habitTracker.recordDifficulty(habitId, date, difficultyLevel);
    
    // Add notes if any were provided
    if (notes.trim()) {
      window.habitTracker.addNote(habitId, date, notes);
    }
    
    // Update the UI
    updateDashboard();
    
    // Reset the form
    event.target.reset();
    
    // Hide the modal
    const modal = bootstrap.Modal.getInstance(document.getElementById('check-in-modal'));
    modal.hide();
    
    // Show success message
    showMessage('Check-in recorded successfully!', 'success');
    
    // Update habit streaks and update list
    updateHabitsList();
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
    if (window.habitTracker.deleteHabit(habitId)) {
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
  
  if (window.nutritionTracker.addMeal(meal)) {
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
  
  if (window.sleepTracker.addSleepRecord(sleepRecord)) {
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
/**
 * Switch to the specified section
 * @param {string} sectionName - Name of the section to show
 */
function showSection(sectionName) {
  // Hide all sections
  document.querySelectorAll('.section-content').forEach(section => {
    section.classList.add('d-none');
  });
  
  // Show the target section
  const targetSection = document.getElementById(`${sectionName}-section`);
  if (targetSection) {
    targetSection.classList.remove('d-none');
    
    // Update section-specific content if needed
    if (sectionName === 'activities') {
      updateActivityStatistics();
      updateActivitiesList();
      updateActivityCalendar();
      updateActivityChart();
    } else if (sectionName === 'nutrition') {
      updateNutritionStats();
      updateMealsList();
      updateNutritionChart();
    } else if (sectionName === 'sleep') {
      updateSleepStats();
      updateSleepRecordsList();
      updateSleepChart();
    } else if (sectionName === 'habits') {
      updateHabitStats();
      updateHabitsList();
      
      // Check if calendar view should be shown
      const calendarViewActive = document.querySelector('[data-habits-view="calendar"]')?.classList.contains('active');
      if (calendarViewActive) {
        toggleHabitsView('calendar');
      } else {
        toggleHabitsView('list');
      }
    } else if (sectionName === 'connections') {
      updateConnectionsList();
    }
  }
  
  // Save last section to localStorage
  localStorage.setItem('lastSection', sectionName);
}

/**
 * Toggle between habit list and calendar views
 * @param {string} view - View to show ('list' or 'calendar')
 */
function toggleHabitsView(view) {
  const listView = document.getElementById('habits-list-view');
  const calendarView = document.getElementById('habits-calendar-view');
  
  if (!listView || !calendarView) return;
  
  if (view === 'list') {
    listView.classList.remove('d-none');
    calendarView.classList.add('d-none');
    updateHabitsList();
  } else if (view === 'calendar') {
    listView.classList.add('d-none');
    calendarView.classList.remove('d-none');
    updateHabitsCalendar();
  }
}

/**
 * Update the habits calendar view
 */
function updateHabitsCalendar() {
  const calendarContainer = document.getElementById('habits-calendar');
  if (!calendarContainer) return;
  
  // Clear the container
  calendarContainer.innerHTML = '';
  
  // Get current date
  const today = new Date();
  const currentMonth = today.getMonth();
  const currentYear = today.getFullYear();
  
  // Get all habits
  const habits = window.habitTracker.getHabits();
  
  // Create a header with month and year
  const header = document.createElement('div');
  header.className = 'd-flex justify-content-between align-items-center mb-3';
  header.innerHTML = `
    <h5 class="mb-0">${new Date(currentYear, currentMonth).toLocaleString('default', { month: 'long' })} ${currentYear}</h5>
    <div>
      <button class="btn btn-sm btn-outline-secondary" id="prev-month-btn">
        <i class="bi bi-chevron-left"></i>
      </button>
      <button class="btn btn-sm btn-outline-secondary ms-1" id="next-month-btn">
        <i class="bi bi-chevron-right"></i>
      </button>
    </div>
  `;
  calendarContainer.appendChild(header);
  
  // Create a table for the calendar
  const table = document.createElement('table');
  table.className = 'table table-bordered calendar-table';
  
  // Create the header row with day names
  const headerRow = document.createElement('tr');
  ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'].forEach(day => {
    const th = document.createElement('th');
    th.textContent = day;
    headerRow.appendChild(th);
  });
  
  const thead = document.createElement('thead');
  thead.appendChild(headerRow);
  table.appendChild(thead);
  
  // Create the body with date cells
  const tbody = document.createElement('tbody');
  
  // Get the first day of the month
  const firstDay = new Date(currentYear, currentMonth, 1);
  const startingDay = firstDay.getDay(); // 0 = Sunday, 1 = Monday, etc.
  
  // Get the number of days in the month
  const daysInMonth = new Date(currentYear, currentMonth + 1, 0).getDate();
  
  // Create the rows for the calendar
  let date = 1;
  for (let i = 0; i < 6; i++) {
    // Break if we've gone beyond the days in the month
    if (date > daysInMonth) break;
    
    const row = document.createElement('tr');
    
    // Create cells for each day of the week
    for (let j = 0; j < 7; j++) {
      const cell = document.createElement('td');
      
      if (i === 0 && j < startingDay) {
        // Empty cells before the first day of the month
        cell.innerHTML = '';
      } else if (date > daysInMonth) {
        // Empty cells after the last day of the month
        cell.innerHTML = '';
      } else {
        // Cells with dates
        cell.innerHTML = `<div class="calendar-date">${date}</div>`;
        
        // Add check-ins for this date if any
        const checkDate = new Date(currentYear, currentMonth, date);
        const formattedDate = formatDateYYYYMMDD(checkDate);
        
        // Create a container for the habit statuses
        const statusContainer = document.createElement('div');
        statusContainer.className = 'habit-status-container';
        
        // Add a status indicator for each habit
        habits.forEach(habit => {
          if (habit.checkIns && habit.checkIns[formattedDate]) {
            const checkIn = habit.checkIns[formattedDate];
            const status = document.createElement('div');
            status.className = `habit-status ${checkIn.success ? 'success' : 'failure'}`;
            status.setAttribute('data-bs-toggle', 'tooltip');
            status.setAttribute('title', `${habit.name}: ${checkIn.success ? 'Success' : 'Missed'}`);
            statusContainer.appendChild(status);
          }
        });
        
        cell.appendChild(statusContainer);
        
        // Highlight today's date
        if (date === today.getDate() && currentMonth === today.getMonth() && currentYear === today.getFullYear()) {
          cell.classList.add('today');
        }
        
        date++;
      }
      
      row.appendChild(cell);
    }
    
    tbody.appendChild(row);
  }
  
  table.appendChild(tbody);
  calendarContainer.appendChild(table);
  
  // Add event listeners to prev/next month buttons
  const prevMonthBtn = document.getElementById('prev-month-btn');
  const nextMonthBtn = document.getElementById('next-month-btn');
  
  if (prevMonthBtn) {
    prevMonthBtn.addEventListener('click', () => {
      // Update the current month/year
      window.currentHabitsCalendarMonth = (window.currentHabitsCalendarMonth || currentMonth) - 1;
      window.currentHabitsCalendarYear = window.currentHabitsCalendarYear || currentYear;
      
      if (window.currentHabitsCalendarMonth < 0) {
        window.currentHabitsCalendarMonth = 11;
        window.currentHabitsCalendarYear--;
      }
      
      updateHabitsCalendar();
    });
  }
  
  if (nextMonthBtn) {
    nextMonthBtn.addEventListener('click', () => {
      // Update the current month/year
      window.currentHabitsCalendarMonth = (window.currentHabitsCalendarMonth || currentMonth) + 1;
      window.currentHabitsCalendarYear = window.currentHabitsCalendarYear || currentYear;
      
      if (window.currentHabitsCalendarMonth > 11) {
        window.currentHabitsCalendarMonth = 0;
        window.currentHabitsCalendarYear++;
      }
      
      updateHabitsCalendar();
    });
  }
  
  // Initialize tooltips
  const tooltipTriggerList = [].slice.call(document.querySelectorAll('[data-bs-toggle="tooltip"]'));
  tooltipTriggerList.map(function (tooltipTriggerEl) {
    return new bootstrap.Tooltip(tooltipTriggerEl);
  });
}

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
  window.healthConnectionManager.addConnection(connection)
    .then(result => {
      // Process the synced data from initial connection
      if (result.syncResult && result.syncResult.data) {
        const syncData = result.syncResult.data;
        
        // Update steps if available
        if (syncData.steps && syncData.steps > 0) {
          window.fitnessTracker.addSteps(syncData.steps);
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
            window.fitnessTracker.addActivity(activity);
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
          window.sleepTracker.addSleepRecord(sleepRecord);
        }
        
        // Save updated data
        window.fitnessTracker.saveToLocalStorage();
        window.sleepTracker.saveToLocalStorage();
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
  updateActivityStatistics();
  updateActivityCalendar();
  
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
  
  if (stepsCount) stepsCount.textContent = window.fitnessTracker.getTotalSteps().toLocaleString();
  if (caloriesCount) caloriesCount.textContent = window.fitnessTracker.getTotalCalories().toLocaleString();
  if (activitiesCount) activitiesCount.textContent = window.fitnessTracker.getActivitiesCount().toString();
}

/**
 * Update activity statistics in the Activities section
 */
function updateActivityStatistics() {
  const weeklyCaloriesStat = document.getElementById('weekly-calories-stat');
  const weeklyDurationStat = document.getElementById('weekly-duration-stat');
  const monthlyActivitiesStat = document.getElementById('monthly-activities-stat');
  const avgDurationStat = document.getElementById('avg-duration-stat');
  
  if (weeklyCaloriesStat) {
    weeklyCaloriesStat.textContent = window.fitnessTracker.getWeeklyCalories().toLocaleString();
  }
  
  if (weeklyDurationStat) {
    weeklyDurationStat.textContent = window.fitnessTracker.getWeeklyDuration().toLocaleString();
  }
  
  if (monthlyActivitiesStat) {
    monthlyActivitiesStat.textContent = window.fitnessTracker.getActivitiesThisMonth().length.toString();
  }
  
  if (avgDurationStat) {
    avgDurationStat.textContent = window.fitnessTracker.getAverageDuration().toString();
  }
}

/**
 * Update the activity calendar
 */
function updateActivityCalendar() {
  const calendarContainer = document.getElementById('activity-calendar');
  if (!calendarContainer) return;
  
  // Clear the container
  calendarContainer.innerHTML = '';
  
  // Get current date to determine current month/week
  const today = new Date();
  const currentMonth = today.getMonth();
  const currentYear = today.getFullYear();
  
  // Check which view is active
  const monthViewActive = document.getElementById('month-view-btn')?.classList.contains('active');
  const weekViewActive = document.getElementById('week-view-btn')?.classList.contains('active');
  
  // Get activity data organized by date
  const activityData = window.fitnessTracker.getCalendarActivityData();
  
  if (monthViewActive || (!monthViewActive && !weekViewActive)) {
    // Month view (default)
    renderMonthCalendar(calendarContainer, currentYear, currentMonth, activityData);
  } else if (weekViewActive) {
    // Week view
    renderWeekCalendar(calendarContainer, today, activityData);
  }
  
  // Add event listeners to the view buttons if they exist
  const monthViewBtn = document.getElementById('month-view-btn');
  const weekViewBtn = document.getElementById('week-view-btn');
  
  if (monthViewBtn && weekViewBtn) {
    // Remove any existing listeners
    const newMonthBtn = monthViewBtn.cloneNode(true);
    const newWeekBtn = weekViewBtn.cloneNode(true);
    
    monthViewBtn.parentNode.replaceChild(newMonthBtn, monthViewBtn);
    weekViewBtn.parentNode.replaceChild(newWeekBtn, weekViewBtn);
    
    // Add new listeners
    newMonthBtn.addEventListener('click', () => {
      newMonthBtn.classList.add('active');
      newWeekBtn.classList.remove('active');
      updateActivityCalendar();
    });
    
    newWeekBtn.addEventListener('click', () => {
      newWeekBtn.classList.add('active');
      newMonthBtn.classList.remove('active');
      updateActivityCalendar();
    });
  }
}

/**
 * Render a month calendar view
 * @param {HTMLElement} container - The container for the calendar
 * @param {number} year - The year to display
 * @param {number} month - The month to display (0-11)
 * @param {Object} activityData - Activity data organized by date
 */
function renderMonthCalendar(container, year, month, activityData) {
  // Get the first day of the month
  const firstDay = new Date(year, month, 1);
  const startingDayOfWeek = firstDay.getDay(); // 0 (Sunday) to 6 (Saturday)
  
  // Get the number of days in the month
  const daysInMonth = new Date(year, month + 1, 0).getDate();
  
  // Create month header
  const monthNames = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];
  
  const monthHeader = document.createElement('div');
  monthHeader.className = 'w-100 mb-3 text-center';
  monthHeader.innerHTML = `<h5>${monthNames[month]} ${year}</h5>`;
  container.appendChild(monthHeader);
  
  // Create the day headers (Sun - Sat)
  const dayHeaders = document.createElement('div');
  dayHeaders.className = 'w-100 d-flex mb-2';
  
  const daysOfWeek = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
  daysOfWeek.forEach(day => {
    const dayHeader = document.createElement('div');
    dayHeader.className = 'flex-1 text-center fw-bold';
    dayHeader.style.width = 'calc(100% / 7)';
    dayHeader.textContent = day;
    dayHeaders.appendChild(dayHeader);
  });
  
  container.appendChild(dayHeaders);
  
  // Create the calendar grid
  const calendarGrid = document.createElement('div');
  calendarGrid.className = 'd-flex flex-wrap w-100';
  
  // Create empty cells for days before the first day of the month
  for (let i = 0; i < startingDayOfWeek; i++) {
    const emptyDay = document.createElement('div');
    emptyDay.className = 'calendar-day empty';
    emptyDay.style.width = 'calc(100% / 7)';
    emptyDay.style.height = '100px';
    emptyDay.style.padding = '5px';
    calendarGrid.appendChild(emptyDay);
  }
  
  // Create cells for each day of the month
  for (let day = 1; day <= daysInMonth; day++) {
    const date = new Date(year, month, day);
    const dateKey = formatDateYYYYMMDD(date);
    const isToday = date.toDateString() === new Date().toDateString();
    
    const dayCell = document.createElement('div');
    dayCell.className = `calendar-day ${isToday ? 'border border-primary' : ''}`;
    dayCell.style.width = 'calc(100% / 7)';
    dayCell.style.height = '100px';
    dayCell.style.padding = '5px';
    dayCell.style.overflow = 'hidden';
    
    // Add day number
    const dayNumber = document.createElement('div');
    dayNumber.className = `calendar-day-number ${isToday ? 'text-primary fw-bold' : ''}`;
    dayNumber.textContent = day;
    dayCell.appendChild(dayNumber);
    
    // Add activity indicators if there are activities on this day
    if (activityData[dateKey]) {
      const activities = activityData[dateKey];
      
      const activityIndicator = document.createElement('div');
      activityIndicator.className = 'activity-indicator mt-1 small';
      
      // Show a badge with the number of activities
      activityIndicator.innerHTML = `
        <span class="badge bg-primary rounded-pill">
          ${activities.count} ${activities.count === 1 ? 'activity' : 'activities'}
        </span>
        <div class="text-muted small">${activities.calories} cal</div>
      `;
      
      // Show activity types as small colored dots
      if (activities.types && activities.types.length > 0) {
        const typeColors = {
          running: 'success',
          cycling: 'info',
          swimming: 'primary',
          weights: 'warning',
          other: 'secondary'
        };
        
        const typesList = document.createElement('div');
        typesList.className = 'd-flex gap-1 mt-1 flex-wrap';
        
        activities.types.forEach(type => {
          const typeColor = typeColors[type] || 'secondary';
          const typeDot = document.createElement('span');
          typeDot.className = `badge bg-${typeColor} rounded-circle p-1`;
          typeDot.setAttribute('title', type);
          typesList.appendChild(typeDot);
        });
        
        activityIndicator.appendChild(typesList);
      }
      
      dayCell.appendChild(activityIndicator);
    }
    
    calendarGrid.appendChild(dayCell);
  }
  
  container.appendChild(calendarGrid);
}

/**
 * Render a week calendar view
 * @param {HTMLElement} container - The container for the calendar
 * @param {Date} date - The date within the week to display
 * @param {Object} activityData - Activity data organized by date
 */
function renderWeekCalendar(container, date, activityData) {
  // Calculate the first day of the week (Sunday)
  const firstDayOfWeek = new Date(date);
  firstDayOfWeek.setDate(date.getDate() - date.getDay());
  
  // Create week header
  const weekStart = firstDayOfWeek.toLocaleDateString('en-US', { month: 'short', day: 'numeric' });
  const weekEnd = new Date(firstDayOfWeek);
  weekEnd.setDate(firstDayOfWeek.getDate() + 6);
  const weekEndStr = weekEnd.toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' });
  
  const weekHeader = document.createElement('div');
  weekHeader.className = 'w-100 mb-3 text-center';
  weekHeader.innerHTML = `<h5>${weekStart} - ${weekEndStr}</h5>`;
  container.appendChild(weekHeader);
  
  // Create the week container
  const weekContainer = document.createElement('div');
  weekContainer.className = 'w-100';
  
  // Create each day of the week
  for (let i = 0; i < 7; i++) {
    const currentDate = new Date(firstDayOfWeek);
    currentDate.setDate(firstDayOfWeek.getDate() + i);
    const dateKey = formatDateYYYYMMDD(currentDate);
    const isToday = currentDate.toDateString() === new Date().toDateString();
    
    const dayRow = document.createElement('div');
    dayRow.className = `d-flex p-2 mb-2 align-items-center ${isToday ? 'bg-light rounded' : ''}`;
    
    // Day name and date
    const dayName = currentDate.toLocaleDateString('en-US', { weekday: 'short', month: 'short', day: 'numeric' });
    const dayLabel = document.createElement('div');
    dayLabel.className = 'col-md-3';
    dayLabel.innerHTML = `<strong class="${isToday ? 'text-primary' : ''}">${dayName}</strong>`;
    
    // Activity summary
    const activitySummary = document.createElement('div');
    activitySummary.className = 'col-md-9';
    
    if (activityData[dateKey]) {
      const activities = activityData[dateKey];
      
      activitySummary.innerHTML = `
        <div class="d-flex align-items-center">
          <span class="badge bg-primary rounded-pill me-2">${activities.count} activities</span>
          <span class="text-muted me-3">${activities.calories} calories</span>
          <span class="text-muted">${activities.duration} minutes</span>
        </div>
        <div class="small mt-1">
          ${activities.types.join(', ')}
        </div>
      `;
    } else {
      activitySummary.innerHTML = `
        <div class="text-muted">No activities recorded</div>
      `;
    }
    
    dayRow.appendChild(dayLabel);
    dayRow.appendChild(activitySummary);
    weekContainer.appendChild(dayRow);
  }
  
  container.appendChild(weekContainer);
}

/**
 * Update the activities list on the dashboard
 */
function updateActivitiesList() {
  const activitiesList = document.getElementById('activities-list');
  const noActivities = document.getElementById('no-activities');
  const allActivitiesList = document.getElementById('all-activities-list');
  const noAllActivities = document.getElementById('no-all-activities');
  
  const activities = window.fitnessTracker.getActivities();
  
  /**
   * Creates an activity card element with separate view details button
   * @param {Activity} activity - The activity to create a card for
   * @returns {HTMLElement} The created activity card
   */
  function createActivityCard(activity) {
    const activityElement = document.createElement('div');
    activityElement.className = 'card mb-2 activity-card';
    activityElement.dataset.activityId = activity.id;
    
    // Prepare additional info elements
    const locationInfo = activity.location ? `<i class="bi bi-geo-alt"></i> ${activity.location}` : '';
    const distanceInfo = activity.distance ? `<i class="bi bi-arrows-move"></i> ${activity.distance.toFixed(2)} km` : '';
    const intensityInfo = `<i class="bi bi-lightning-charge"></i> ${activity.getIntensityDescription()}`;
    
    // Check if this activity has goals
    const hasGoals = activity.goals && activity.goals.enabled;
    const goalStatus = hasGoals ? activity.checkGoalStatus() : null;
    const goalBadge = hasGoals ? 
      `<span class="badge ${goalStatus.overall ? 'bg-success' : 'bg-warning'} rounded-pill me-1">
        <i class="bi ${goalStatus.overall ? 'bi-check-lg' : 'bi-exclamation'}"></i>
        ${goalStatus.overall ? 'Goals Met' : 'In Progress'}
      </span>` : '';
    
    // Create the inner structure with separate card content and info button
    activityElement.innerHTML = `
      <div class="card-body">
        <div class="d-flex justify-content-between align-items-center mb-2">
          <div class="activity-info">
            <h6 class="mb-1">${activity.name}</h6>
            <p class="text-muted mb-0 small">${activity.getFormattedDate()} | ${activity.duration} mins | ${activity.type}</p>
          </div>
          <div class="d-flex align-items-center">
            ${goalBadge}
            <span class="badge bg-primary rounded-pill me-2">${activity.calories} cal</span>
            <button type="button" class="btn btn-sm btn-outline-primary view-details-btn">
              <i class="bi bi-info-circle"></i>
            </button>
          </div>
        </div>
        
        <div class="activity-details small text-muted d-flex flex-wrap gap-2">
          ${intensityInfo}
          ${distanceInfo ? `<span class="me-2">${distanceInfo}</span>` : ''}
          ${locationInfo ? `<span>${locationInfo}</span>` : ''}
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
  if (activitiesList && noActivities) {
    if (activities.length === 0) {
      activitiesList.style.display = 'none';
      noActivities.style.display = 'block';
    } else {
      // Set up activity filters and sorting
      setupActivityFiltersAndSort();
      
      // Apply current filters and sorting
      applyActivityFiltersAndSort();
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
  const deloadProgressStat = document.getElementById('deload-progress-stat');
  
  const stats = window.habitTracker.getOverallProgress() || { currentStreak: 0, bestStreak: 0, successRate: 0 };
  const habits = window.habitTracker.getHabits();
  
  if (habitsCount) habitsCount.textContent = habits.length.toString();
  if (currentStreakCount) currentStreakCount.textContent = (stats.currentStreak || 0).toString();
  if (successRateCount) successRateCount.textContent = `${Math.round(stats.successRate || 0)}%`;
  
  // Calculate deload progress across all habits
  if (deloadProgressStat) {
    if (habits.length === 0) {
      deloadProgressStat.textContent = '0%';
    } else {
      let totalProgress = 0;
      habits.forEach(habit => {
        totalProgress += habit.getProgressPercentage();
      });
      const avgProgress = Math.round(totalProgress / habits.length);
      deloadProgressStat.textContent = `${avgProgress}%`;
      
      // Also update the progress bar if it exists
      const progressBar = document.getElementById('overall-deload-progress');
      if (progressBar) {
        progressBar.style.width = `${avgProgress}%`;
        progressBar.setAttribute('aria-valuenow', avgProgress.toString());
      }
    }
  }
  
  // Update category statistics
  updateHabitCategoryStats(habits);
}

/**
 * Update the habit category statistics
 * @param {Array} habits - Array of habits to analyze
 */
function updateHabitCategoryStats(habits) {
  const categoryCountsElement = document.getElementById('habit-category-counts');
  if (!categoryCountsElement) return;
  
  // Create a map of category counts
  const categoryCounts = {};
  habits.forEach(habit => {
    const category = habit.category;
    if (!categoryCounts[category]) {
      categoryCounts[category] = 0;
    }
    categoryCounts[category]++;
  });
  
  // Clear the element
  categoryCountsElement.innerHTML = '';
  
  // Add a bar for each category
  Object.keys(categoryCounts).forEach(category => {
    const count = categoryCounts[category];
    const percentage = Math.round((count / habits.length) * 100);
    
    const categoryBar = document.createElement('div');
    categoryBar.className = 'mb-3';
    categoryBar.innerHTML = `
      <div class="d-flex justify-content-between align-items-center mb-1">
        <small>${getCategoryFriendlyName(category)}</small>
        <small class="text-muted">${count}</small>
      </div>
      <div class="progress" style="height: 8px;">
        <div class="progress-bar bg-${getCategoryColor(category)}" role="progressbar" 
             style="width: ${percentage}%" aria-valuenow="${percentage}" 
             aria-valuemin="0" aria-valuemax="100"></div>
      </div>
    `;
    
    categoryCountsElement.appendChild(categoryBar);
  });
}

/**
 * Get a friendly name for a habit category
 * @param {string} category - Habit category code
 * @returns {string} User-friendly category name
 */
function getCategoryFriendlyName(category) {
  const names = {
    'smoking': 'Smoking',
    'drinking': 'Drinking',
    'social-media': 'Social Media',
    'junk-food': 'Junk Food',
    'procrastination': 'Procrastination',
    'other': 'Other'
  };
  
  return names[category] || category.charAt(0).toUpperCase() + category.slice(1);
}

/**
 * Get a color for a habit category
 * @param {string} category - Habit category
 * @returns {string} Bootstrap color class
 */
function getCategoryColor(category) {
  const colors = {
    'smoking': 'danger',
    'drinking': 'warning',
    'social-media': 'info',
    'junk-food': 'success',
    'procrastination': 'primary',
    'other': 'secondary'
  };
  
  return colors[category] || 'primary';
}

/**
 * Update the habits list on the dashboard
 */
function updateHabitsList() {
  const habitsList = document.getElementById('habits-list');
  const noHabits = document.getElementById('no-habits');
  const allHabitsList = document.getElementById('all-habits-list');
  const noAllHabits = document.getElementById('no-all-habits');
  
  const habits = window.habitTracker.getHabits();
  
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
  
  // Progress percentage for the deload
  const progressPercentage = habit.getProgressPercentage();
  
  // Current deload target
  const currentTarget = habit.getCurrentTarget();
  
  // Days remaining in deload
  const startDate = new Date(habit.startDate);
  const targetDate = new Date(startDate);
  targetDate.setDate(startDate.getDate() + habit.deloadDuration);
  const today = new Date();
  const daysRemaining = Math.max(0, Math.ceil((targetDate - today) / (1000 * 60 * 60 * 24)));
  
  // Progress chart for week
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
  
  // Status description
  const statusDescription = habit.getStatusDescription();
  
  let detailsHtml = '';
  if (showDetails) {
    detailsHtml = `
      <div class="mt-3">
        <div class="d-flex justify-content-between small text-muted mb-2">
          <div>Category: ${getCategoryFriendlyName(habit.category)}</div>
          <div>Starting Frequency: ${habit.frequency} times ${habit.frequencyUnit}</div>
        </div>
        <div class="d-flex justify-content-between small text-muted mb-2">
          <div>Started: ${habit.getFormattedStartDate()}</div>
          <div>Target End: ${habit.getFormattedTargetDate()}</div>
        </div>
        <p class="small mb-2">${habit.description}</p>
        
        ${habit.trigger ? `<p class="small mb-0"><strong>Trigger:</strong> ${habit.trigger}</p>` : ''}
        ${habit.alternative ? `<p class="small mb-0"><strong>Alternative:</strong> ${habit.alternative}</p>` : ''}
        
        <div class="mt-3">
          <h6 class="small">Habit Difficulty Over Time</h6>
          <div id="difficulty-chart-${habit.id}" class="difficulty-chart" style="height: 100px;"></div>
          <div class="small text-muted text-center">Past 7 Check-ins</div>
        </div>
      </div>
    `;
    
    // Render difficulty chart after the element is added to the DOM
    setTimeout(() => {
      renderDifficultyChart(habit);
    }, 0);
  }
  
  // Create status badge based on progress
  let statusBadge = '';
  if (progressPercentage >= 90) {
    statusBadge = '<span class="badge bg-success">Almost Done!</span>';
  } else if (progressPercentage >= 50) {
    statusBadge = '<span class="badge bg-info">Halfway There</span>';
  } else if (progressPercentage >= 25) {
    statusBadge = '<span class="badge bg-primary">Making Progress</span>';
  } else {
    statusBadge = '<span class="badge bg-secondary">Just Started</span>';
  }
  
  element.innerHTML = `
    <div class="card-body">
      <div class="d-flex justify-content-between align-items-center">
        <div>
          <h6 class="mb-0">${habit.name} ${statusBadge}</h6>
          <div class="small text-muted">${statusDescription}</div>
        </div>
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
      
      <div class="mt-3">
        <div class="d-flex justify-content-between align-items-center mb-1">
          <small>Deload Progress</small>
          <small>${progressPercentage}%</small>
        </div>
        <div class="progress" style="height: 8px;">
          <div class="progress-bar bg-${getCategoryColor(habit.category)}" role="progressbar" 
               style="width: ${progressPercentage}%" aria-valuenow="${progressPercentage}" 
               aria-valuemin="0" aria-valuemax="100"></div>
        </div>
        <div class="d-flex justify-content-between mt-1">
          <small class="text-muted">Current target: ${currentTarget} times ${habit.frequencyUnit}</small>
          <small class="text-muted">${daysRemaining} days remaining</small>
        </div>
      </div>
      
      <div class="mt-3">
        <div class="d-flex justify-content-between align-items-center">
          <div class="small text-muted">Current streak: ${streakInfo.currentStreak} days</div>
          <div class="small text-muted">Best: ${streakInfo.bestStreak} days</div>
        </div>
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
 * Render a difficulty chart for a habit
 * @param {BadHabit} habit - The habit to render a chart for
 */
function renderDifficultyChart(habit) {
  const chartContainer = document.getElementById(`difficulty-chart-${habit.id}`);
  if (!chartContainer) return;
  
  // Get difficulty data from last 7 check-ins
  const difficultyData = [];
  const difficultyLabels = [];
  
  const checkIns = Object.entries(habit.checkIns)
    .sort((a, b) => new Date(a[0]) - new Date(b[0]))
    .slice(-7);
  
  checkIns.forEach(([dateKey, checkIn]) => {
    if (checkIn.difficulty) {
      difficultyData.push(checkIn.difficulty);
      const date = new Date(dateKey);
      difficultyLabels.push(date.toLocaleDateString('en-US', { month: 'short', day: 'numeric' }));
    }
  });
  
  // Create chart
  if (difficultyData.length > 0) {
    const ctx = document.createElement('canvas');
    chartContainer.appendChild(ctx);
    
    new Chart(ctx, {
      type: 'line',
      data: {
        labels: difficultyLabels,
        datasets: [{
          label: 'Difficulty Level',
          data: difficultyData,
          borderColor: '#6c757d',
          backgroundColor: 'rgba(108, 117, 125, 0.2)',
          tension: 0.2,
          fill: true
        }]
      },
      options: {
        scales: {
          y: {
            beginAtZero: true,
            max: 5,
            stepSize: 1
          }
        },
        plugins: {
          legend: {
            display: false
          }
        },
        responsive: true,
        maintainAspectRatio: false
      }
    });
  } else {
    chartContainer.innerHTML = '<div class="text-center text-muted small py-3">No difficulty data yet</div>';
  }
}

/**
 * Update nutrition statistics
 */
function updateNutritionStats() {
  const nutritionCalories = document.getElementById('nutrition-calories');
  const nutritionProtein = document.getElementById('nutrition-protein');
  const nutritionCarbs = document.getElementById('nutrition-carbs');
  const nutritionFat = document.getElementById('nutrition-fat');
  
  const todaySummary = window.nutritionTracker.getNutritionSummaryByDate(new Date());
  
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
  const meals = window.nutritionTracker.getMealsByDate(today);
  
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
  const weeklyData = window.nutritionTracker.getWeeklyNutritionSummary();
  
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
 * Set up activity filters and sorting
 */
function setupActivityFiltersAndSort() {
  const filterButtons = document.querySelectorAll('#activity-filter-buttons button');
  const sortDropdown = document.getElementById('activity-sort');
  const searchInput = document.getElementById('activity-search');
  
  // Add event listeners to filter buttons if they don't already have them
  filterButtons.forEach(button => {
    // Clone and replace to remove any existing listeners
    const newButton = button.cloneNode(true);
    button.parentNode.replaceChild(newButton, button);
    
    newButton.addEventListener('click', () => {
      // Remove active class from all buttons
      filterButtons.forEach(btn => btn.classList.remove('active'));
      
      // Add active class to clicked button
      newButton.classList.add('active');
      
      // Apply filters
      applyActivityFiltersAndSort();
    });
  });
  
  // Add event listener to sort dropdown if it doesn't already have one
  if (sortDropdown) {
    // Clone and replace to remove any existing listeners
    const newDropdown = sortDropdown.cloneNode(true);
    sortDropdown.parentNode.replaceChild(newDropdown, sortDropdown);
    
    newDropdown.addEventListener('change', () => {
      applyActivityFiltersAndSort();
    });
  }
  
  // Add event listener to search input if it doesn't already have one
  if (searchInput) {
    // Clone and replace to remove any existing listeners
    const newInput = searchInput.cloneNode(true);
    searchInput.parentNode.replaceChild(newInput, searchInput);
    
    // Use input event for real-time filtering as user types
    newInput.addEventListener('input', debounce(() => {
      applyActivityFiltersAndSort();
    }, 300)); // Debounce to avoid excessive filtering while typing
  }
}

/**
 * Apply activity filters and sorting
 */
function applyActivityFiltersAndSort() {
  const activitiesList = document.getElementById('activities-list');
  const noActivities = document.getElementById('no-activities');
  
  if (!activitiesList || !noActivities) return;
  
  // Get current filter settings
  const activeFilterBtn = document.querySelector('#activity-filter-buttons button.active');
  const filterType = activeFilterBtn ? activeFilterBtn.dataset.filter : 'all';
  
  const sortDropdown = document.getElementById('activity-sort');
  const sortBy = sortDropdown ? sortDropdown.value : 'date-desc';
  
  const searchInput = document.getElementById('activity-search');
  const searchText = searchInput ? searchInput.value.trim() : '';
  
  // Get and filter activities
  let filteredActivities = window.fitnessTracker.getActivities();
  
  // Apply type filter
  if (filterType && filterType !== 'all') {
    filteredActivities = filteredActivities.filter(activity => activity.type === filterType);
  }
  
  // Apply search filter
  if (searchText) {
    filteredActivities = window.fitnessTracker.searchActivities(searchText);
    
    // Also apply type filter to search results if needed
    if (filterType && filterType !== 'all') {
      filteredActivities = filteredActivities.filter(activity => activity.type === filterType);
    }
  }
  
  // Apply sorting
  filteredActivities = window.fitnessTracker.getSortedActivities(sortBy);
  
  // First apply search if provided
  if (searchText) {
    filteredActivities = window.fitnessTracker.searchActivities(searchText);
  }
  
  // Then apply type filter if not 'all'
  if (filterType && filterType !== 'all') {
    filteredActivities = filteredActivities.filter(activity => activity.type === filterType);
  }
  
  // Finally apply sorting
  switch(sortBy) {
    case 'date-asc':
      filteredActivities.sort((a, b) => a.date - b.date);
      break;
    case 'duration-desc':
      filteredActivities.sort((a, b) => Number(b.duration) - Number(a.duration));
      break;
    case 'calories-desc':
      filteredActivities.sort((a, b) => Number(b.calories) - Number(a.calories));
      break;
    case 'date-desc':
    default:
      filteredActivities.sort((a, b) => b.date - a.date);
      break;
  }
  
  // Display filtered and sorted activities
  if (filteredActivities.length === 0) {
    activitiesList.innerHTML = '';
    activitiesList.style.display = 'none';
    noActivities.style.display = 'block';
  } else {
    activitiesList.style.display = 'block';
    noActivities.style.display = 'none';
    
    // Clear the list
    activitiesList.innerHTML = '';
    
    // Create and add activity cards
    filteredActivities.forEach(activity => {
      const activityElement = createActivityCard(activity);
      activitiesList.appendChild(activityElement);
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
  
  const stats = window.sleepTracker.getStats();
  
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
  const records = window.sleepTracker.getSleepRecords();
  
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
  const weeklyData = window.sleepTracker.getWeeklySleepSummary();
  
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
  
  // Special handling for weight input - use 5 pound increments
  if (inputId === 'other-weight-input') {
    // Add number options to the wheel in 5-pound increments
    for (let i = 0; i <= maxValue; i += 5) {
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
  } else {
    // For other inputs (reps, sets) use standard increments of 1
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
      // Ensure input value is preserved
      const currentValue = parseInt(input.value) || 0;
      
      // Show the scroll wheel and update its position
      container.style.display = 'block';
      input.style.display = 'none';
      
      // Ensure the wheel is properly positioned and values are visible
      updateScrollWheelPosition(input, currentValue);
      
      // Make sure all number options are visible and properly highlighted
      input.scrollWheel.options.forEach(option => {
        // Make sure all options are visible
        option.style.visibility = 'visible'; 
        // Highlight the selected value
        if (parseInt(option.dataset.value) === currentValue) {
          option.classList.add('selected-value');
        } else {
          option.classList.remove('selected-value');
        }
      });
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
    
    let value;
    
    // Special handling for weight input - snap to 5-pound increments
    if (input.id === 'other-weight-input') {
      // Convert index to a value in 5-pound increments
      // Ensure the index is within reasonable bounds before multiplying
      const safeIndex = Math.max(0, Math.min(maxValue / 5, index));
      value = safeIndex * 5;
    } else {
      // For other inputs use standard values
      value = Math.max(0, Math.min(maxValue, index));
    }
    
    // Update the visual position of the wheel
    wheel.style.transform = `translateY(${newY}px)`;
    
    // Update the input value and ensure it's preserved
    if (input.value !== value.toString()) {
      input.value = value;
    }
    input.scrollWheel.currentValue = value;
    
    // Highlight the current value and ensure all options are visible
    const options = input.scrollWheel.options;
    options.forEach(option => {
      // Ensure all options remain visible while scrolling
      option.style.visibility = 'visible';
      
      // For weight input, we need to compare with the option's dataset value
      if (parseInt(option.dataset.value) === value) {
        option.classList.add('selected-value');
        // Ensure this option is visible by scrolling to it if needed
        option.style.opacity = '1';
      } else {
        option.classList.remove('selected-value');
        
        // Fade out options that are far from the current selection for a nicer visual effect
        const optVal = parseInt(option.dataset.value);
        const distance = Math.abs(optVal - value);
        if (input.id === 'other-weight-input') {
          // For weight inputs, adjust distance based on 5-pound increments
          if (distance <= 20) { // Only nearby options fully visible
            option.style.opacity = 1 - (distance / 25);
          } else {
            option.style.opacity = '0.1';  // Far options barely visible
          }
        } else {
          // For standard inputs
          if (distance <= 4) { // Only nearby options fully visible
            option.style.opacity = 1 - (distance / 5);
          } else {
            option.style.opacity = '0.1';  // Far options barely visible
          }
        }
      }
    });
    
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
  if (!input || !input.scrollWheel) return;
  
  const { wheel, optionHeight } = input.scrollWheel;
  
  // Special handling for weight input with 5lb increments
  let position;
  let index;
  
  if (input.id === 'other-weight-input') {
    // For weight inputs, we need to handle 5lb increments
    // First, round the value to the nearest 5-pound increment
    const roundedValue = Math.round(value / 5) * 5;
    
    // Now calculate the index based on the rounded value (each 5lb increment is one option)
    index = roundedValue / 5;
    position = -(index * optionHeight) + (input.scrollWheel.container.offsetHeight / 2 - optionHeight / 2);
    
    // Update the input value to show the rounded value
    input.value = roundedValue;
    input.scrollWheel.currentValue = roundedValue;
  } else {
    // For other inputs (sets, reps), use standard positioning
    index = value;
    position = -(index * optionHeight) + (input.scrollWheel.container.offsetHeight / 2 - optionHeight / 2);
    
    // Update the input value
    input.value = value;
    input.scrollWheel.currentValue = value;
  }
  
  // Apply the visual transformation
  wheel.style.transition = 'transform 0.3s ease-out';
  wheel.style.transform = `translateY(${position}px)`;
  input.scrollWheel.currentY = position;
  
  // Make sure selected value is highlighted and all options are visible
  const options = input.scrollWheel.options;
  options.forEach(option => {
    // Ensure all options are visible during and after scrolling
    option.style.visibility = 'visible';
    
    // Check if this option is the selected value
    if (parseInt(option.dataset.value) === input.scrollWheel.currentValue) {
      option.classList.add('selected-value');
    } else {
      option.classList.remove('selected-value');
    }
  });
  
  // Remove the transition after it completes
  setTimeout(() => {
    if (wheel) wheel.style.transition = '';
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
    if (window.sleepTracker.deleteSleepRecord(recordId)) {
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
  const activities = window.fitnessTracker.getActivities();
  
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
  const activities = window.fitnessTracker.getActivities();
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
  
  const connections = window.healthConnectionManager.getConnections();
  const stats = window.healthConnectionManager.getAggregateStats();
  
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
  const connection = window.healthConnectionManager.getConnectionById(connectionId);
  
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
          window.fitnessTracker.addSteps(result.data.steps);
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
            
            window.fitnessTracker.addActivity(activity);
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
          window.sleepTracker.addSleepRecord(sleepRecord);
        }
      }
      
      // Save updated data
      window.fitnessTracker.saveToLocalStorage();
      window.sleepTracker.saveToLocalStorage();
      
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
  const connection = window.healthConnectionManager.getConnectionById(connectionId);
  
  if (!connection) {
    showMessage('Connection not found.', 'danger');
    return;
  }
  
  if (confirm(`Are you sure you want to disconnect ${connection.getDisplayName()}?`)) {
    showMessage(`Disconnecting ${connection.getDisplayName()}...`, 'info');
    
    window.healthConnectionManager.removeConnection(connectionId)
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
  const activity = window.fitnessTracker.getActivityById(activityId);
  
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
  const success = window.fitnessTracker.updateActivity(activityId, {
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
    const activity = window.fitnessTracker.getActivityById(activityId);
    
    // First delete the activity from the fitness tracker
    const success = window.fitnessTracker.deleteActivity(activityId);
    
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
        const connection = window.healthConnectionManager.getConnectionById(activity.sourceConnection);
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
  const loginErrorElement = loginForm ? document.getElementById('login-error') : null;
  
  // Registration form handling
  const registerForm = document.getElementById('register-form');
  const registerErrorElement = registerForm ? document.getElementById('register-error') : null;
  
  // Profile settings form
  const profileSettingsForm = document.getElementById('profile-settings-form');
  const settingsNameInput = profileSettingsForm ? document.getElementById('settings-name') : null;
  const settingsEmailInput = profileSettingsForm ? document.getElementById('settings-email') : null;
  
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
  if (profileSettingsForm && settingsNameInput && settingsEmailInput) {
    profileSettingsForm.addEventListener('submit', function(event) {
      event.preventDefault();
      
      const name = settingsNameInput.value;
      const email = settingsEmailInput.value;
      
      const currentUser = authManager.getCurrentUser();
      if (currentUser) {
        currentUser.updateProfile({ name, email });
        authManager.saveToLocalStorage();
        
        // Update UI
        const userNameElement = document.getElementById('user-name');
        if (userNameElement) {
          userNameElement.textContent = name;
        }
        
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
  
  // Check if elements exist before trying to access them
  if (isLoggedIn) {
    // Show user profile, hide auth buttons
    if (authButtons) authButtons.style.display = 'none';
    if (userProfile) userProfile.style.display = 'block';
    
    // Update user name
    const currentUser = authManager.getCurrentUser();
    if (currentUser && userNameElement) {
      userNameElement.textContent = currentUser.name;
    }
  } else {
    // Show auth buttons, hide user profile
    if (authButtons) authButtons.style.display = 'block';
    if (userProfile) userProfile.style.display = 'none';
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
      console.log('Exercise preset clicked:', this.dataset);
      const exerciseName = this.dataset.name;
      activityNameInput.value = exerciseName;
      
      // Check if this is a weight training exercise with additional data
      if (this.dataset.equipment) {
        console.log('Setting up weight training exercise with equipment:', this.dataset.equipment);
        // Set workout category to weights
        const weightsRadio = document.getElementById('workout-weights');
        if (weightsRadio) {
          weightsRadio.checked = true;
          document.getElementById('activity-type').value = 'weights';
          weightTrainingOptions.style.display = 'block';
          
          // Select the appropriate equipment type
          const equipment = this.dataset.equipment;
          const equipmentRadio = document.getElementById(`equipment-${equipment}`);
          
          if (equipmentRadio) {
            equipmentRadio.checked = true;
            
            // Update UI based on equipment type
            updateEquipmentOptions(equipment);
            
            // Set sets and reps values
            if (this.dataset.sets) {
              const setsInput = document.getElementById('sets-input');
              if (setsInput) {
                const setsValue = parseInt(this.dataset.sets);
                setsInput.value = setsValue;
                console.log('Setting sets to:', setsValue);
                // Update the scroll wheel
                updateScrollWheelPosition(setsInput, setsValue);
              }
            }
            
            if (this.dataset.reps) {
              const repsInput = document.getElementById('reps-input');
              if (repsInput) {
                const repsValue = parseInt(this.dataset.reps);
                repsInput.value = repsValue;
                console.log('Setting reps to:', repsValue);
                // Update the scroll wheel
                updateScrollWheelPosition(repsInput, repsValue);
              }
            }
            
            // Handle weight
            if (this.dataset.weight && equipment !== 'bodyweight') {
              const weight = parseFloat(this.dataset.weight);
              console.log('Setting weight to:', weight);
              
              if (equipment === 'barbell') {
                // For barbell, calculate which plates to add to match the weight
                const barWeight = 45; // Standard barbell weight
                let plateWeight = weight - barWeight;
                
                // Clear existing plates
                const clearBtn = document.getElementById('clear-plates-btn');
                if (clearBtn) {
                  clearBtn.click();
                
                  // If there's weight to add beyond the bar
                  if (plateWeight > 0) {
                    // Weight needs to be distributed on both sides
                    plateWeight = plateWeight / 2;
                    
                    // Standard plate weights (descending order)
                    const plateWeights = [45, 35, 25, 15, 10, 5, 2.5];
                    let remainingWeight = plateWeight;
                    
                    // Add plates to match the target weight as closely as possible
                    plateWeights.forEach(pw => {
                      while (remainingWeight >= pw) {
                        // Find and click the button for this plate weight
                        const plateButtons = document.querySelectorAll('.plate-btn');
                        for (const btn of plateButtons) {
                          if (parseFloat(btn.dataset.weight) === pw) {
                            btn.click();
                            break;
                          }
                        }
                        remainingWeight -= pw;
                      }
                    });
                  }
                }
              } else {
                // For dumbbell or machine, just set the weight input
                const otherWeightInput = document.getElementById('other-weight-input');
                if (otherWeightInput) {
                  otherWeightInput.value = weight;
                  updateScrollWheelPosition(otherWeightInput, weight);
                }
              }
            }
          }
          
          // Update exercise presets visibility
          updateExercisePresets('weights');
        }
      } else {
        // Assume cardio exercise if no equipment data
        console.log('Setting up cardio exercise');
        const cardioRadio = document.getElementById('workout-cardio');
        if (cardioRadio) {
          cardioRadio.checked = true;
          weightTrainingOptions.style.display = 'none';
          updateExercisePresets('cardio');
        }
      }
    });
  });
  
  // Initialize scroll wheels with higher ranges
  initializeScrollWheel('other-weight-input', 1000); // Weight can go up to 1000 lbs
  initializeScrollWheel('sets-input', 50); // Sets can go up to 50
  initializeScrollWheel('reps-input', 50); // Reps can go up to 50
  
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
        otherWeightInput.max = 200; // Max dumbbell weight still 200lbs for typical users
      } else {
        otherWeightInput.max = 1000; // Machine weight up to 1000lbs
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
 * Initialize speech recognition for voice commands
 */
function initializeSpeechRecognition() {
  console.log('Initializing speech recognition from app.js');
  
  // Create the speech recognizer instance if it doesn't exist yet
  if (!window.speechRecognizer) {
    try {
      window.speechRecognizer = new SpeechRecognizer();
      console.log('Speech recognizer instance created');
      
      // Initialize recovery properties
      window.speechRecognizer.recoveryAttempt = 0;
      window.speechRecognizer.lastRecoveryTime = 0;
      window.speechRecognizer.inRecoveryMode = false;
    } catch (error) {
      console.error('Failed to create speech recognizer:', error);
      // Schedule a retry with exponential backoff
      setTimeout(() => {
        console.log('Retrying speech recognizer initialization...');
        initializeSpeechRecognition();
      }, 2000);
      return;
    }
  } else {
    console.log('Using existing speech recognizer instance');
    
    // Check if the instance needs to be reset
    if (window.speechRecognizer.recognition) {
      try {
        const state = window.speechRecognizer.recognition.state;
        // If recognition is in an invalid state, reset it
        if (state === 'active') {
          console.log('Stopping active recognition during initialization');
          try {
            window.speechRecognizer.stopListening();
          } catch (e) {
            console.warn('Could not stop existing recognition:', e);
            // Force reset if stopping fails
            try {
              window.speechRecognizer.resetRecognitionState();
            } catch (resetError) {
              console.error('Error during recognition reset:', resetError);
            }
          }
        }
      } catch (stateError) {
        // Some browsers don't expose the state property
        console.warn('Could not check recognition state, attempting reset:', stateError);
        try {
          window.speechRecognizer.resetRecognitionState();
        } catch (resetError) {
          console.error('Error during recognition reset:', resetError);
        }
      }
    } else {
      // If the recognition object is missing, reinitialize
      try {
        window.speechRecognizer.initializeSpeechRecognition();
        console.log('Reinitialized missing recognition object');
      } catch (error) {
        console.error('Failed to reinitialize speech recognition:', error);
      }
    }
  }

  // Make sure the microphone button exists in the DOM
  if (typeof window.addMicrophoneButton === 'function') {
    try {
      window.addMicrophoneButton();
      console.log('Added/verified microphone button');
    } catch (error) {
      console.error('Error adding microphone button:', error);
    }
  } else {
    console.error('addMicrophoneButton function not found - speech-recognition.js may not be loaded');
  }
  
  // Set up click handler for the voice command toggle button
  const voiceCommandBtn = document.getElementById('voice-command-toggle');
  if (voiceCommandBtn) {
    try {
      // Remove any existing listeners to avoid duplication
      const newBtn = voiceCommandBtn.cloneNode(true);
      voiceCommandBtn.parentNode.replaceChild(newBtn, voiceCommandBtn);
      
      // Add the click event listener with error handling
      newBtn.addEventListener('click', function() {
        if (window.speechRecognizer) {
          try {
            window.speechRecognizer.toggleListening();
            console.log('Voice command button clicked, toggling speech recognition');
          } catch (error) {
            console.error('Error toggling speech recognition:', error);
            
            // Handle InvalidStateError specially
            if (error.name === 'InvalidStateError') {
              showToast('Resetting speech recognition...', 'info');
              setTimeout(() => {
                try {
                  window.speechRecognizer.resetRecognitionState();
                  console.log('Reset recognition state after toggle error');
                } catch (resetError) {
                  console.error('Error during recognition reset:', resetError);
                  showToast('Speech recognition error. Please try again.', 'error');
                }
              }, 500);
            } else {
              showToast('Speech recognition error. Please try again.', 'error');
            }
          }
        } else {
          console.error('Speech recognizer not initialized');
          showToast('Speech recognition not available', 'error');
        }
      });
      
      console.log('Voice command button event listener set up');
    } catch (error) {
      console.error('Error setting up voice command button:', error);
    }
  } else {
    console.warn('Voice command button not found in the DOM after setup');
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
  
  if (window.healthSnapshotTracker.addSnapshot(snapshot)) {
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
  const recentSnapshot = window.healthSnapshotTracker.getMostRecentSnapshot();
  
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