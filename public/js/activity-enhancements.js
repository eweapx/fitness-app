/**
 * Activity Enhancements Module
 * Handles personal records, activity comparison, and exercise progress tracking
 */

// Initialize enhancements when the document is ready
document.addEventListener('DOMContentLoaded', () => {
  // Initialize event listeners for the enhancements
  setupPersonalRecordsEvents();
  setupComparisonEvents();
  setupExerciseProgressEvents();
});

/**
 * Set up event listeners for personal records section
 */
function setupPersonalRecordsEvents() {
  // Set up record type selector buttons
  const recordTypeButtons = document.querySelectorAll('[data-record-type]');
  recordTypeButtons.forEach(button => {
    button.addEventListener('click', (e) => {
      // Set active button
      recordTypeButtons.forEach(btn => btn.classList.remove('active'));
      e.target.classList.add('active');
      
      // Update displayed records
      updatePersonalRecords(e.target.dataset.recordType);
    });
  });
}

/**
 * Update personal records display based on selected type
 * @param {string} recordType - Type of records to display (running, cycling, swimming, weights)
 */
function updatePersonalRecords(recordType = 'running') {
  const recordsContainer = document.getElementById('personal-records-container');
  const noRecordsMessage = document.getElementById('no-records');
  
  // Get records from the fitness tracker
  const records = fitnessTracker.getPersonalRecords();
  const typeRecords = records[recordType];
  
  // Check if we have records for this type
  if (!typeRecords || Object.values(typeRecords).every(val => val === 0 || val === Infinity)) {
    noRecordsMessage.classList.remove('d-none');
    // Clear any existing records
    const existingRecords = recordsContainer.querySelectorAll('.record-item');
    existingRecords.forEach(item => item.remove());
    return;
  }
  
  // Hide the no records message
  noRecordsMessage.classList.add('d-none');
  
  // Create records list
  let recordsHTML = `<div class="record-list">`;
  
  // Format records based on activity type
  if (recordType === 'running' || recordType === 'swimming') {
    if (typeRecords.distance > 0) {
      recordsHTML += createRecordItem('Longest Distance', `${typeRecords.distance.toFixed(2)} km`, 'bi-arrows-expand');
    }
    if (typeRecords.duration > 0) {
      recordsHTML += createRecordItem('Longest Duration', formatDuration(typeRecords.duration * 60), 'bi-clock');
    }
    if (typeRecords.calories > 0) {
      recordsHTML += createRecordItem('Most Calories', typeRecords.calories, 'bi-fire');
    }
    if (typeRecords.pace < Infinity) {
      recordsHTML += createRecordItem('Best Pace', formatPace(typeRecords.pace), 'bi-speedometer');
    }
  } else if (recordType === 'cycling') {
    if (typeRecords.distance > 0) {
      recordsHTML += createRecordItem('Longest Distance', `${typeRecords.distance.toFixed(2)} km`, 'bi-arrows-expand');
    }
    if (typeRecords.duration > 0) {
      recordsHTML += createRecordItem('Longest Duration', formatDuration(typeRecords.duration * 60), 'bi-clock');
    }
    if (typeRecords.calories > 0) {
      recordsHTML += createRecordItem('Most Calories', typeRecords.calories, 'bi-fire');
    }
    if (typeRecords.speed > 0) {
      recordsHTML += createRecordItem('Top Speed', `${typeRecords.speed} km/h`, 'bi-speedometer2');
    }
  } else if (recordType === 'weights') {
    if (typeRecords.mostCalories > 0) {
      recordsHTML += createRecordItem('Most Calories', typeRecords.mostCalories, 'bi-fire');
    }
    if (typeRecords.longestWorkout > 0) {
      recordsHTML += createRecordItem('Longest Workout', formatDuration(typeRecords.longestWorkout * 60), 'bi-clock');
    }
    
    // Additional weight-specific records from workout details
    const maxWeightRecord = getMaxWeightRecord();
    if (maxWeightRecord) {
      recordsHTML += createRecordItem(
        `Max Weight (${maxWeightRecord.exercise})`, 
        `${maxWeightRecord.weight} lbs`, 
        'bi-award'
      );
    }
  }
  
  recordsHTML += `</div>`;
  
  // Update the container with the new records
  recordsContainer.innerHTML = recordsHTML;
}

/**
 * Create HTML for a single record item
 * @param {string} title - Record title
 * @param {string|number} value - Record value
 * @param {string} iconClass - Bootstrap icon class
 * @returns {string} HTML for the record item
 */
function createRecordItem(title, value, iconClass) {
  return `
    <div class="record-item d-flex align-items-center mb-3">
      <div class="record-icon me-3">
        <i class="bi ${iconClass} fs-4 text-primary"></i>
      </div>
      <div class="record-info">
        <div class="record-title text-muted small">${title}</div>
        <div class="record-value fw-bold">${value}</div>
      </div>
    </div>
  `;
}

/**
 * Find the maximum weight lifted for any exercise
 * @returns {Object|null} Exercise name and weight or null if none found
 */
function getMaxWeightRecord() {
  let maxWeight = 0;
  let exerciseName = '';
  
  fitnessTracker.getActivities().forEach(activity => {
    if (activity.workoutDetails && 
        activity.workoutDetails.exercises && 
        activity.workoutDetails.exercises.length > 0) {
      
      activity.workoutDetails.exercises.forEach(exercise => {
        if (exercise.weight && Number(exercise.weight) > maxWeight) {
          maxWeight = Number(exercise.weight);
          exerciseName = exercise.name;
        }
      });
    }
  });
  
  return maxWeight > 0 ? { exercise: exerciseName, weight: maxWeight } : null;
}

/**
 * Set up event listeners for activity comparison section
 */
function setupComparisonEvents() {
  // Set up comparison form submission
  const comparisonForm = document.getElementById('comparison-form');
  if (comparisonForm) {
    comparisonForm.addEventListener('submit', (e) => {
      e.preventDefault();
      
      const activity1 = document.getElementById('comparison-activity-1').value;
      const activity2 = document.getElementById('comparison-activity-2').value;
      
      if (activity1 && activity2) {
        compareActivities(activity1, activity2);
      }
    });
  }
  
  // Populate activity dropdowns when activities section becomes visible
  document.addEventListener('shown.bs.tab', function(e) {
    if (e.target.getAttribute('href') === '#activities-tab' || 
        e.target.getAttribute('data-bs-target') === '#activities-section') {
      populateComparisonDropdowns();
    }
  });
}

/**
 * Populate the activity comparison dropdowns with available activities
 */
function populateComparisonDropdowns() {
  const dropdown1 = document.getElementById('comparison-activity-1');
  const dropdown2 = document.getElementById('comparison-activity-2');
  
  if (!dropdown1 || !dropdown2) return;
  
  // Clear existing options except the default one
  dropdown1.innerHTML = '<option value="">Select first activity</option>';
  dropdown2.innerHTML = '<option value="">Select second activity</option>';
  
  // Get recent activities
  const activities = fitnessTracker.getSortedActivities('date-desc').slice(0, 10);
  
  // Add activities to dropdowns
  activities.forEach(activity => {
    const option = document.createElement('option');
    option.value = activity.id;
    option.textContent = `${activity.name} (${activity.getFormattedDate()})`;
    
    const option2 = option.cloneNode(true);
    
    dropdown1.appendChild(option);
    dropdown2.appendChild(option2);
  });
}

/**
 * Compare two activities and display the results
 * @param {string} id1 - ID of first activity
 * @param {string} id2 - ID of second activity
 */
function compareActivities(id1, id2) {
  const comparisonResults = document.getElementById('comparison-results');
  const noComparisonMsg = document.getElementById('no-comparison');
  
  // Get activities by ID
  const activity1 = fitnessTracker.getActivityById(id1);
  const activity2 = fitnessTracker.getActivityById(id2);
  
  if (!activity1 || !activity2) {
    comparisonResults.classList.add('d-none');
    noComparisonMsg.classList.remove('d-none');
    noComparisonMsg.innerHTML = '<p class="text-danger">One or both activities not found.</p>';
    return;
  }
  
  // Get comparison data
  const comparison = fitnessTracker.compareActivities(id1, id2);
  
  // Hide no comparison message
  noComparisonMsg.classList.add('d-none');
  
  // Build comparison table
  let comparisonHTML = `
    <h6 class="mb-3">Comparing Activities</h6>
    <div class="table-responsive">
      <table class="table table-sm">
        <thead>
          <tr>
            <th>Metric</th>
            <th>${activity1.name}</th>
            <th>${activity2.name}</th>
            <th>Difference</th>
          </tr>
        </thead>
        <tbody>
  `;
  
  // Duration row
  comparisonHTML += `
    <tr>
      <td>Duration</td>
      <td>${formatDuration(activity1.duration * 60)}</td>
      <td>${formatDuration(activity2.duration * 60)}</td>
      <td class="${comparison.duration.diff > 0 ? 'text-success' : comparison.duration.diff < 0 ? 'text-danger' : ''}">
        ${comparison.duration.diff > 0 ? '+' : ''}${formatDuration(comparison.duration.diff * 60)} 
        (${comparison.duration.percent > 0 ? '+' : ''}${comparison.duration.percent}%)
      </td>
    </tr>
  `;
  
  // Calories row
  comparisonHTML += `
    <tr>
      <td>Calories</td>
      <td>${activity1.calories}</td>
      <td>${activity2.calories}</td>
      <td class="${comparison.calories.diff > 0 ? 'text-success' : comparison.calories.diff < 0 ? 'text-danger' : ''}">
        ${comparison.calories.diff > 0 ? '+' : ''}${comparison.calories.diff} 
        (${comparison.calories.percent > 0 ? '+' : ''}${comparison.calories.percent}%)
      </td>
    </tr>
  `;
  
  // Only show distance if both activities have it
  if (activity1.distance > 0 || activity2.distance > 0) {
    comparisonHTML += `
      <tr>
        <td>Distance</td>
        <td>${activity1.distance ? activity1.distance.toFixed(2) + ' km' : 'N/A'}</td>
        <td>${activity2.distance ? activity2.distance.toFixed(2) + ' km' : 'N/A'}</td>
        <td class="${comparison.distance.diff > 0 ? 'text-success' : comparison.distance.diff < 0 ? 'text-danger' : ''}">
          ${activity1.distance && activity2.distance ? 
            `${comparison.distance.diff > 0 ? '+' : ''}${comparison.distance.diff.toFixed(2)} km 
            (${comparison.distance.percent > 0 ? '+' : ''}${comparison.distance.percent}%)` : 
            'N/A'}
        </td>
      </tr>
    `;
  }
  
  // Intensity row
  comparisonHTML += `
    <tr>
      <td>Intensity</td>
      <td>${activity1.getIntensityDescription()}</td>
      <td>${activity2.getIntensityDescription()}</td>
      <td class="${comparison.intensity.diff > 0 ? 'text-success' : comparison.intensity.diff < 0 ? 'text-danger' : ''}">
        ${comparison.intensity.diff > 0 ? '+' : ''}${comparison.intensity.diff} level${Math.abs(comparison.intensity.diff) !== 1 ? 's' : ''}
      </td>
    </tr>
  `;
  
  // Only show pace if both activities have distance > 0
  if (activity1.distance > 0 && activity2.distance > 0) {
    comparisonHTML += `
      <tr>
        <td>Pace</td>
        <td>${formatPace(comparison.pace.activity1)}</td>
        <td>${formatPace(comparison.pace.activity2)}</td>
        <td class="${comparison.pace.diff < 0 ? 'text-success' : comparison.pace.diff > 0 ? 'text-danger' : ''}">
          ${comparison.pace.diff < 0 ? '+' : ''}${formatPace(Math.abs(comparison.pace.diff))} ${comparison.pace.diff < 0 ? 'faster' : 'slower'}
        </td>
      </tr>
    `;
  }
  
  comparisonHTML += `
        </tbody>
      </table>
    </div>
  `;
  
  // Update the comparison results
  comparisonResults.innerHTML = comparisonHTML;
  comparisonResults.classList.remove('d-none');
}

/**
 * Format pace (minutes per distance unit) into a readable string
 * @param {number} pace - Pace in minutes per km/mile
 * @returns {string} Formatted pace string
 */
function formatPace(pace) {
  if (!pace || pace === Infinity || pace === 0) return 'N/A';
  
  const minutes = Math.floor(pace);
  const seconds = Math.round((pace - minutes) * 60);
  
  return `${minutes}:${seconds.toString().padStart(2, '0')} min/km`;
}

/**
 * Set up event listeners for exercise progress section
 */
function setupExerciseProgressEvents() {
  // Set up exercise selector
  const exerciseSelect = document.getElementById('exercise-progress-select');
  if (exerciseSelect) {
    exerciseSelect.addEventListener('change', () => {
      const exerciseName = exerciseSelect.value;
      if (exerciseName) {
        updateExerciseProgress(exerciseName);
      } else {
        // Hide chart and show "select exercise" message
        document.getElementById('exercise-progress-chart').classList.add('d-none');
        document.getElementById('no-exercise-data').classList.add('d-none');
        document.getElementById('no-exercise-selected').classList.remove('d-none');
      }
    });
  }
  
  // Populate exercise dropdown when activities section becomes visible
  document.addEventListener('shown.bs.tab', function(e) {
    if (e.target.getAttribute('href') === '#activities-tab' || 
        e.target.getAttribute('data-bs-target') === '#activities-section') {
      populateExerciseDropdown();
    }
  });
}

/**
 * Populate the exercise progress dropdown with available exercises
 */
function populateExerciseDropdown() {
  const exerciseSelect = document.getElementById('exercise-progress-select');
  
  if (!exerciseSelect) return;
  
  // Clear existing options except the default one
  exerciseSelect.innerHTML = '<option value="">Select an exercise</option>';
  
  // Get all unique exercise names from weight training activities
  const exerciseNames = new Set();
  
  fitnessTracker.getActivities().forEach(activity => {
    if (activity.workoutDetails && 
        activity.workoutDetails.category === 'weights' && 
        activity.workoutDetails.exercises) {
      
      activity.workoutDetails.exercises.forEach(exercise => {
        if (exercise.name) {
          exerciseNames.add(exercise.name);
        }
      });
    }
  });
  
  // Add exercise names to dropdown
  Array.from(exerciseNames).sort().forEach(name => {
    const option = document.createElement('option');
    option.value = name;
    option.textContent = name;
    exerciseSelect.appendChild(option);
  });
}

/**
 * Update the exercise progress chart for the selected exercise
 * @param {string} exerciseName - Name of the exercise to display progress for
 */
function updateExerciseProgress(exerciseName) {
  const progressData = fitnessTracker.getExerciseProgress(exerciseName);
  const chartCanvas = document.getElementById('exercise-progress-chart');
  const noDataMsg = document.getElementById('no-exercise-data');
  const noExerciseMsg = document.getElementById('no-exercise-selected');
  
  // Hide the "no exercise selected" message
  noExerciseMsg.classList.add('d-none');
  
  // Check if we have data
  if (!progressData || progressData.dates.length === 0) {
    chartCanvas.classList.add('d-none');
    noDataMsg.classList.remove('d-none');
    return;
  }
  
  // Hide "no data" message and show chart
  noDataMsg.classList.add('d-none');
  chartCanvas.classList.remove('d-none');
  
  // Create/update chart
  if (window.exerciseProgressChart) {
    window.exerciseProgressChart.destroy();
  }
  
  // Create datasets for the chart
  const datasets = [
    {
      label: 'Weight (lbs)',
      data: progressData.weights,
      borderColor: 'rgba(54, 162, 235, 1)',
      backgroundColor: 'rgba(54, 162, 235, 0.2)',
      yAxisID: 'y',
      tension: 0.1
    },
    {
      label: 'Total Reps',
      data: progressData.reps,
      borderColor: 'rgba(255, 99, 132, 1)',
      backgroundColor: 'rgba(255, 99, 132, 0.2)',
      yAxisID: 'y1',
      tension: 0.1
    }
  ];
  
  // Create the chart
  window.exerciseProgressChart = new Chart(chartCanvas, {
    type: 'line',
    data: {
      labels: progressData.dates,
      datasets: datasets
    },
    options: {
      responsive: true,
      interaction: {
        mode: 'index',
        intersect: false,
      },
      stacked: false,
      scales: {
        y: {
          type: 'linear',
          display: true,
          position: 'left',
          title: {
            display: true,
            text: 'Weight (lbs)'
          }
        },
        y1: {
          type: 'linear',
          display: true,
          position: 'right',
          title: {
            display: true,
            text: 'Reps'
          },
          grid: {
            drawOnChartArea: false
          }
        }
      },
      plugins: {
        title: {
          display: true,
          text: `Progress for ${exerciseName}`
        },
        tooltip: {
          callbacks: {
            afterBody: function(context) {
              const index = context[0].dataIndex;
              return `Sets: ${progressData.sets[index]}`;
            }
          }
        }
      }
    }
  });
}

/**
 * Update all enhanced activity sections
 */
function updateActivityEnhancements() {
  // Update personal records for the currently selected type
  const activeRecordType = document.querySelector('[data-record-type].active');
  if (activeRecordType) {
    updatePersonalRecords(activeRecordType.dataset.recordType);
  } else {
    updatePersonalRecords('running');
  }
  
  // Update comparison dropdowns
  populateComparisonDropdowns();
  
  // Update exercise progress dropdown
  populateExerciseDropdown();
  
  // Update exercise progress chart if an exercise is selected
  const exerciseSelect = document.getElementById('exercise-progress-select');
  if (exerciseSelect && exerciseSelect.value) {
    updateExerciseProgress(exerciseSelect.value);
  }
}

/**
 * Set up Activity Goals form toggle
 */
function setupActivityGoalsToggle() {
  const goalsCheckbox = document.getElementById('activity-goals-enabled');
  const goalsContainer = document.getElementById('goals-container');
  
  if (goalsCheckbox && goalsContainer) {
    goalsCheckbox.addEventListener('change', () => {
      if (goalsCheckbox.checked) {
        goalsContainer.classList.remove('d-none');
      } else {
        goalsContainer.classList.add('d-none');
      }
    });
  }
}

// Initialize activity enhancements
document.addEventListener('DOMContentLoaded', () => {
  setupActivityGoalsToggle();
  
  // Add the enhancements update to the existing updateActivitiesList function
  const originalUpdateActivitiesList = window.updateActivitiesList;
  if (typeof originalUpdateActivitiesList === 'function') {
    window.updateActivitiesList = function() {
      originalUpdateActivitiesList();
      updateActivityEnhancements();
    };
  }
  
  // Update activity form handler to include the new fields
  const activityForm = document.getElementById('add-activity-form');
  if (activityForm) {
    activityForm.addEventListener('submit', handleEnhancedActivityFormSubmit);
  }
});

/**
 * Handle the enhanced activity form submission with new fields
 * @param {Event} event - Form submission event
 */
function handleEnhancedActivityFormSubmit(event) {
  event.preventDefault();
  
  // Get basic activity data
  const name = document.getElementById('activity-name').value;
  const type = document.getElementById('activity-type').value;
  const duration = Number(document.getElementById('activity-duration').value);
  const calories = Number(document.getElementById('activity-calories').value);
  const date = new Date(document.getElementById('activity-date').value);
  
  // Get enhanced activity data
  const location = document.getElementById('activity-location').value;
  const intensity = Number(document.getElementById('activity-intensity').value);
  const distance = Number(document.getElementById('activity-distance').value || 0);
  
  // Get goals data if enabled
  const goalsEnabled = document.getElementById('activity-goals-enabled').checked;
  let goals = { enabled: false };
  
  if (goalsEnabled) {
    goals = {
      enabled: true,
      calorieTarget: Number(document.getElementById('goal-calories').value || 0),
      durationTarget: Number(document.getElementById('goal-duration').value || 0),
      distanceTarget: Number(document.getElementById('goal-distance').value || 0)
    };
  }
  
  // Create activity with enhanced data
  const activity = new Activity(
    name, calories, duration, type, date, null, null, null, null,
    intensity, location, goals, distance
  );
  
  // Add activity
  if (fitnessTracker.addActivity(activity)) {
    // Update UI
    updateDashboard();
    
    // Close modal
    const modal = bootstrap.Modal.getInstance(document.getElementById('addActivityModal'));
    if (modal) {
      modal.hide();
    }
    
    // Show success message
    showToast('Activity added successfully', 'success');
    
    // Reset form
    event.target.reset();
  } else {
    showToast('Please fill in all required fields', 'error');
  }
}