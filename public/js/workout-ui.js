/**
 * Workout User Interface Module for the Health & Fitness Tracker
 * Handles the UI interaction for workout tracking functionality
 */

// Initialize the workout manager
let workoutManager = new WorkoutManager();

// References to workout UI elements
const workoutModal = document.getElementById('workoutModal');
const exerciseModal = document.getElementById('exerciseModal');
const activeWorkoutModal = document.getElementById('activeWorkoutModal');

// Current workout state
let currentWorkoutId = null;
let currentExerciseId = null;
let workoutTimerInterval = null;
let restTimerInterval = null;
let workoutStartTime = null;

/**
 * Initialize workout UI
 */
function initializeWorkoutUI() {
  // Connect main UI buttons for workout management
  const createEmptyWorkoutBtn = document.getElementById('create-empty-workout');
  if (createEmptyWorkoutBtn) {
    createEmptyWorkoutBtn.addEventListener('click', () => {
      // Start an empty workout without a template
      startWorkout(null);
    });
  }
  
  // Set up event listeners for workout creation
  document.getElementById('create-workout-btn').addEventListener('click', handleCreateWorkout);
  
  // Set up event listeners for exercise management
  document.getElementById('add-exercise-btn').addEventListener('click', handleAddExercise);
  document.getElementById('add-set-btn').addEventListener('click', addNewSet);
  document.getElementById('add-workout-exercise-btn').addEventListener('click', () => {
    // Clear exercise form
    document.getElementById('exercise-form').reset();
    // Reset sets
    initializeExerciseSets();
    // Show exercise modal
    const exerciseModalObj = new bootstrap.Modal(exerciseModal);
    exerciseModalObj.show();
  });
  
  // Set up event listeners for workout completion
  document.getElementById('complete-workout-btn').addEventListener('click', handleCompleteWorkout);
  document.getElementById('discard-workout-btn').addEventListener('click', handleDiscardWorkout);
  
  // Set up rest timer
  document.querySelector('.rest-timer-btn').addEventListener('click', toggleRestTimer);
  
  // Set up library selection
  document.querySelector('.exercise-library').addEventListener('click', handleExerciseLibrarySelection);
  
  // Initialize exercise sets
  initializeExerciseSets();
  
  // Load and display routines
  loadWorkoutRoutines();
}

/**
 * Load and display workout routines
 */
function loadWorkoutRoutines() {
  const routines = workoutManager.getRoutines();
  const routinesContainer = document.getElementById('workout-routines-container');
  
  if (!routinesContainer) return;
  
  routinesContainer.innerHTML = '';
  
  if (routines.length === 0) {
    routinesContainer.innerHTML = `
      <div class="text-center py-4">
        <p class="text-muted">No workout routines created yet. Create your first routine to get started.</p>
        <button class="btn btn-primary" data-bs-toggle="modal" data-bs-target="#workoutModal">
          <i class="bi bi-plus-circle me-1"></i> Create Workout Plan
        </button>
      </div>
    `;
    return;
  }
  
  // Sort routines by last used date (most recent first)
  routines.sort((a, b) => {
    if (!a.lastUsed) return 1;
    if (!b.lastUsed) return -1;
    return new Date(b.lastUsed) - new Date(a.lastUsed);
  });
  
  // Create routine cards
  routines.forEach(routine => {
    const card = document.createElement('div');
    card.className = 'card mb-3 workout-routine-card';
    card.innerHTML = `
      <div class="card-body">
        <div class="d-flex justify-content-between align-items-start">
          <h5 class="card-title">${routine.name}</h5>
          <div class="dropdown">
            <button class="btn btn-sm btn-outline-secondary" type="button" data-bs-toggle="dropdown">
              <i class="bi bi-three-dots-vertical"></i>
            </button>
            <ul class="dropdown-menu">
              <li><a class="dropdown-item edit-routine" href="#" data-id="${routine.id}">Edit</a></li>
              <li><a class="dropdown-item delete-routine" href="#" data-id="${routine.id}">Delete</a></li>
            </ul>
          </div>
        </div>
        <p class="card-text text-muted">${routine.description || 'No description'}</p>
        <p class="card-text"><small>${routine.exercises.length} exercises: ${routine.getSummary()}</small></p>
        <div class="d-flex justify-content-between align-items-center">
          <button class="btn btn-primary start-workout" data-id="${routine.id}">Start Workout</button>
          <small class="text-muted">${routine.lastUsed ? `Last used: ${new Date(routine.lastUsed).toLocaleDateString()}` : 'Never used'}</small>
        </div>
      </div>
    `;
    
    // Add event listeners
    card.querySelector('.start-workout').addEventListener('click', () => startWorkout(routine.id));
    card.querySelector('.edit-routine').addEventListener('click', () => editWorkout(routine.id));
    card.querySelector('.delete-routine').addEventListener('click', () => deleteWorkout(routine.id));
    
    routinesContainer.appendChild(card);
  });
  
  // Add "Create New" button
  const createNew = document.createElement('div');
  createNew.className = 'text-center mt-4';
  createNew.innerHTML = `
    <button class="btn btn-outline-primary" data-bs-toggle="modal" data-bs-target="#workoutModal">
      <i class="bi bi-plus-circle me-1"></i> Create New Workout Plan
    </button>
  `;
  routinesContainer.appendChild(createNew);
}

/**
 * Handle workout creation form submission
 */
function handleCreateWorkout() {
  const nameInput = document.getElementById('workout-name');
  const descInput = document.getElementById('workout-description');
  
  const name = nameInput.value.trim();
  const description = descInput.value.trim();
  
  if (!name) {
    nameInput.classList.add('is-invalid');
    return;
  }
  
  // Create new workout routine
  const routine = new WorkoutRoutine(null, name, description);
  workoutManager.addRoutine(routine);
  
  // Hide modal
  const modal = bootstrap.Modal.getInstance(workoutModal);
  modal.hide();
  
  // Reset form
  document.getElementById('workout-form').reset();
  
  // Reload routines
  loadWorkoutRoutines();
  
  // Show success message
  showMessage(`Workout plan "${name}" created successfully!`, 'success');
}

/**
 * Start a workout from a routine
 * @param {string|null} routineId - ID of the routine to start, or null for empty workout
 */
function startWorkout(routineId) {
  let workout;
  
  if (routineId) {
    // Get the routine if an ID was provided
    const routine = workoutManager.getRoutineById(routineId);
    if (!routine) return;
    
    // Start a workout from the routine
    workout = workoutManager.startWorkout(routine);
    
    // Update UI with routine details
    document.getElementById('active-workout-name').textContent = routine.name;
    document.getElementById('active-workout-description').textContent = routine.description || 'No description';
  } else {
    // Start an empty workout
    workout = workoutManager.startWorkout(null);
    
    // Set default values for empty workout
    document.getElementById('active-workout-name').textContent = 'Quick Workout';
    document.getElementById('active-workout-description').textContent = 'Custom workout session';
  }
  
  currentWorkoutId = workout.id;
  workoutStartTime = new Date();
  
  // Populate exercises (will be empty for new workout)
  renderWorkoutExercises(workout);
  
  // Start workout timer
  startWorkoutTimer();
  
  // Show active workout modal
  const modal = new bootstrap.Modal(activeWorkoutModal);
  modal.show();
}

/**
 * Render workout exercises in the active workout modal
 * @param {Object} workout - Current workout
 */
function renderWorkoutExercises(workout) {
  const container = document.getElementById('workout-exercises-container');
  container.innerHTML = '';
  
  if (!workout || !workout.exercises || workout.exercises.length === 0) {
    container.innerHTML = `
      <div class="text-center py-4 empty-state">
        <p class="text-muted">No exercises added yet. Click "Add Exercise" to begin.</p>
      </div>
    `;
    document.getElementById('workout-exercise-count').textContent = '0';
    return;
  }
  
  // Update exercise count
  document.getElementById('workout-exercise-count').textContent = workout.exercises.length.toString();
  
  // Create exercise cards
  workout.exercises.forEach((exercise, index) => {
    const card = document.createElement('div');
    card.className = 'card mb-3 exercise-card';
    card.dataset.exerciseId = exercise.id;
    
    // Create header with exercise name and actions
    const header = document.createElement('div');
    header.className = 'card-header d-flex justify-content-between align-items-center';
    header.innerHTML = `
      <h5 class="mb-0">${exercise.name}</h5>
      <div class="btn-group">
        <button class="btn btn-sm btn-outline-primary edit-exercise" title="Edit">
          <i class="bi bi-pencil"></i>
        </button>
        <button class="btn btn-sm btn-outline-danger remove-exercise" title="Remove">
          <i class="bi bi-trash"></i>
        </button>
      </div>
    `;
    
    // Create body with sets
    const body = document.createElement('div');
    body.className = 'card-body';
    
    // Create sets table
    const setsTable = document.createElement('div');
    setsTable.className = 'exercise-sets';
    
    // Add table header
    setsTable.innerHTML = `
      <div class="d-flex exercise-set-header">
        <div style="width: 40px">Set</div>
        <div class="flex-grow-1 row g-0">
          <div class="col-4">Weight</div>
          <div class="col-4">Reps</div>
          <div class="col-4">Done</div>
        </div>
      </div>
    `;
    
    // Add sets
    exercise.sets.forEach((set, setIndex) => {
      const setRow = document.createElement('div');
      setRow.className = 'd-flex align-items-center exercise-set';
      setRow.dataset.setIndex = setIndex.toString();
      
      setRow.innerHTML = `
        <div class="set-number" style="width: 40px">${setIndex + 1}</div>
        <div class="flex-grow-1 row g-0">
          <div class="col-4 pe-1">
            <input type="number" class="form-control form-control-sm set-weight" value="${set.weight}" inputmode="numeric">
          </div>
          <div class="col-4 px-1">
            <input type="number" class="form-control form-control-sm set-reps" value="${set.reps}" inputmode="numeric">
          </div>
          <div class="col-4 ps-1">
            <div class="form-check d-flex justify-content-center">
              <input class="form-check-input set-complete" type="checkbox" ${set.completed ? 'checked' : ''}>
            </div>
          </div>
        </div>
      `;
      
      // Add event listeners to update the set
      const weightInput = setRow.querySelector('.set-weight');
      const repsInput = setRow.querySelector('.set-reps');
      const completeCheck = setRow.querySelector('.set-complete');
      
      weightInput.addEventListener('change', () => {
        const weight = parseFloat(weightInput.value) || 0;
        workoutManager.updateSetInWorkout(exercise.id, setIndex, { weight });
      });
      
      repsInput.addEventListener('change', () => {
        const reps = parseInt(repsInput.value) || 0;
        workoutManager.updateSetInWorkout(exercise.id, setIndex, { reps });
      });
      
      completeCheck.addEventListener('change', () => {
        workoutManager.updateSetInWorkout(exercise.id, setIndex, { completed: completeCheck.checked });
        
        // Add completed class to row for styling
        if (completeCheck.checked) {
          setRow.classList.add('set-completed');
        } else {
          setRow.classList.remove('set-completed');
        }
      });
      
      // Add completed class if already completed
      if (set.completed) {
        setRow.classList.add('set-completed');
      }
      
      setsTable.appendChild(setRow);
    });
    
    // Add button to add a new set
    const addSetBtn = document.createElement('button');
    addSetBtn.className = 'btn btn-sm btn-outline-primary mt-2';
    addSetBtn.innerHTML = '<i class="bi bi-plus-circle me-1"></i> Add Set';
    addSetBtn.addEventListener('click', () => {
      // Add new set to the exercise
      workoutManager.addSetToExercise(exercise.id);
      
      // Re-render the workout
      renderWorkoutExercises(workoutManager.currentWorkout);
    });
    
    // Add notes if available
    let notesSection = '';
    if (exercise.notes) {
      notesSection = `
        <div class="exercise-notes mt-2">
          <small class="text-muted">${exercise.notes}</small>
        </div>
      `;
    }
    
    // Assemble the card
    body.appendChild(setsTable);
    body.appendChild(addSetBtn);
    if (exercise.notes) {
      const notesDiv = document.createElement('div');
      notesDiv.className = 'exercise-notes mt-2';
      notesDiv.innerHTML = `<small class="text-muted">${exercise.notes}</small>`;
      body.appendChild(notesDiv);
    }
    
    card.appendChild(header);
    card.appendChild(body);
    container.appendChild(card);
    
    // Add event listeners
    card.querySelector('.edit-exercise').addEventListener('click', () => editExercise(exercise.id));
    card.querySelector('.remove-exercise').addEventListener('click', () => removeExercise(exercise.id));
  });
}

/**
 * Initialize exercise sets in the exercise modal
 */
function initializeExerciseSets() {
  const setsContainer = document.getElementById('exercise-sets');
  const setElements = setsContainer.querySelectorAll('.set-container');
  
  // Remove all but the first set
  if (setElements.length > 1) {
    for (let i = 1; i < setElements.length; i++) {
      setElements[i].remove();
    }
  }
  
  // Reset first set
  if (setElements.length > 0) {
    const firstSet = setElements[0];
    firstSet.dataset.setIndex = '0';
    firstSet.querySelector('.set-number').textContent = '1';
    firstSet.querySelector('.set-weight').value = '';
    firstSet.querySelector('.set-reps').value = '';
    firstSet.querySelector('.set-complete').checked = false;
  }
  
  // Add event listener to remove buttons
  document.querySelectorAll('.remove-set-btn').forEach(btn => {
    btn.addEventListener('click', removeSet);
  });
}

/**
 * Add a new set to the exercise form
 */
function addNewSet() {
  const setsContainer = document.getElementById('exercise-sets');
  const setElements = setsContainer.querySelectorAll('.set-container');
  const newIndex = setElements.length;
  
  const setTemplate = setElements[0].cloneNode(true);
  setTemplate.dataset.setIndex = newIndex.toString();
  setTemplate.querySelector('.set-number').textContent = (newIndex + 1).toString();
  setTemplate.querySelector('.set-weight').value = '';
  setTemplate.querySelector('.set-reps').value = '';
  setTemplate.querySelector('.set-complete').checked = false;
  
  // Add event listener to remove button
  setTemplate.querySelector('.remove-set-btn').addEventListener('click', removeSet);
  
  setsContainer.appendChild(setTemplate);
}

/**
 * Remove a set from the exercise form
 * @param {Event} event - Click event
 */
function removeSet(event) {
  const setContainer = event.target.closest('.set-container');
  const setsContainer = document.getElementById('exercise-sets');
  const setElements = setsContainer.querySelectorAll('.set-container');
  
  // Don't remove if it's the only set
  if (setElements.length <= 1) {
    return;
  }
  
  // Remove the set
  setContainer.remove();
  
  // Update set numbers
  setsContainer.querySelectorAll('.set-container').forEach((set, index) => {
    set.dataset.setIndex = index.toString();
    set.querySelector('.set-number').textContent = (index + 1).toString();
  });
}

/**
 * Handle exercise selection from library
 * @param {Event} event - Click event
 */
function handleExerciseLibrarySelection(event) {
  event.preventDefault();
  
  const target = event.target;
  if (!target.classList.contains('dropdown-item')) {
    return;
  }
  
  const name = target.dataset.name;
  const equipment = target.dataset.equipment;
  
  if (name) {
    document.getElementById('exercise-name').value = name;
  }
  
  if (equipment) {
    document.querySelector(`#equipment-${equipment}`).checked = true;
  }
}

/**
 * Handle adding an exercise to the workout
 */
function handleAddExercise() {
  const nameInput = document.getElementById('exercise-name');
  const name = nameInput.value.trim();
  
  if (!name) {
    nameInput.classList.add('is-invalid');
    return;
  }
  
  // Get equipment type
  const equipmentType = document.querySelector('input[name="equipment-type"]:checked').value;
  
  // Get sets data
  const setElements = document.querySelectorAll('.set-container');
  const sets = [];
  
  setElements.forEach(setEl => {
    const weightInput = setEl.querySelector('.set-weight');
    const repsInput = setEl.querySelector('.set-reps');
    const completeCheck = setEl.querySelector('.set-complete');
    
    sets.push({
      weight: parseFloat(weightInput.value) || 0,
      reps: parseInt(repsInput.value) || 0,
      completed: completeCheck.checked
    });
  });
  
  // Get notes
  const notes = document.getElementById('exercise-notes').value.trim();
  
  // Create exercise object
  const exercise = {
    id: currentExerciseId || crypto.randomUUID(),
    name,
    equipment: equipmentType,
    sets,
    notes
  };
  
  // Add or update exercise in workout
  if (currentExerciseId) {
    // Update existing exercise
    workoutManager.updateExerciseInWorkout(currentExerciseId, exercise);
    currentExerciseId = null;
  } else {
    // Add new exercise
    workoutManager.addExerciseToWorkout(exercise);
  }
  
  // Hide modal
  const modal = bootstrap.Modal.getInstance(exerciseModal);
  modal.hide();
  
  // Reset form
  document.getElementById('exercise-form').reset();
  initializeExerciseSets();
  
  // Re-render workout
  renderWorkoutExercises(workoutManager.currentWorkout);
}

/**
 * Edit an exercise in the current workout
 * @param {string} exerciseId - ID of the exercise to edit
 */
function editExercise(exerciseId) {
  const exercise = workoutManager.currentWorkout.exercises.find(ex => ex.id === exerciseId);
  if (!exercise) return;
  
  // Set current exercise ID
  currentExerciseId = exerciseId;
  
  // Populate form
  document.getElementById('exercise-name').value = exercise.name;
  document.getElementById('exercise-notes').value = exercise.notes || '';
  
  // Set equipment type
  if (exercise.equipment) {
    const equipmentRadio = document.querySelector(`#equipment-${exercise.equipment}`);
    if (equipmentRadio) {
      equipmentRadio.checked = true;
    }
  }
  
  // Reset sets container
  const setsContainer = document.getElementById('exercise-sets');
  setsContainer.innerHTML = '';
  
  // Create set template
  const setTemplate = `
    <div class="set-container mb-2" data-set-index="INDEX">
      <div class="d-flex align-items-center">
        <div class="me-2 set-number">NUMBER</div>
        <div class="flex-grow-1 row g-0">
          <div class="col-5 pe-1">
            <input type="number" class="form-control set-weight" placeholder="Weight" inputmode="numeric" min="0" max="999" value="WEIGHT">
          </div>
          <div class="col-4 px-1">
            <input type="number" class="form-control set-reps" placeholder="Reps" inputmode="numeric" min="1" max="100" value="REPS">
          </div>
          <div class="col-3 ps-1 d-flex">
            <button type="button" class="btn btn-outline-danger btn-sm remove-set-btn" tabindex="-1">
              <i class="bi bi-trash"></i>
            </button>
            <div class="form-check ms-1">
              <input class="form-check-input set-complete" type="checkbox" title="Completed" CHECKED>
            </div>
          </div>
        </div>
      </div>
    </div>
  `;
  
  // Add sets
  exercise.sets.forEach((set, index) => {
    const setHtml = setTemplate
      .replace('INDEX', index.toString())
      .replace('NUMBER', (index + 1).toString())
      .replace('WEIGHT', set.weight.toString())
      .replace('REPS', set.reps.toString())
      .replace('CHECKED', set.completed ? 'checked' : '');
    
    setsContainer.insertAdjacentHTML('beforeend', setHtml);
  });
  
  // Add event listeners to remove buttons
  document.querySelectorAll('.remove-set-btn').forEach(btn => {
    btn.addEventListener('click', removeSet);
  });
  
  // Show exercise modal
  const modal = new bootstrap.Modal(exerciseModal);
  modal.show();
}

/**
 * Remove an exercise from the current workout
 * @param {string} exerciseId - ID of the exercise to remove
 */
function removeExercise(exerciseId) {
  if (confirm('Are you sure you want to remove this exercise?')) {
    // Filter out the exercise
    workoutManager.currentWorkout.exercises = workoutManager.currentWorkout.exercises.filter(
      ex => ex.id !== exerciseId
    );
    
    // Re-render workout
    renderWorkoutExercises(workoutManager.currentWorkout);
  }
}

/**
 * Edit a workout routine
 * @param {string} routineId - ID of the routine to edit
 */
function editWorkout(routineId) {
  const routine = workoutManager.getRoutineById(routineId);
  if (!routine) return;
  
  // To be implemented
  alert('Edit workout feature coming soon!');
}

/**
 * Delete a workout routine
 * @param {string} routineId - ID of the routine to delete
 */
function deleteWorkout(routineId) {
  if (confirm('Are you sure you want to delete this workout plan?')) {
    workoutManager.deleteRoutine(routineId);
    loadWorkoutRoutines();
    showMessage('Workout plan deleted successfully', 'success');
  }
}

/**
 * Handle completing a workout
 */
function handleCompleteWorkout() {
  if (!workoutManager.currentWorkout) return;
  
  // Complete the workout
  const completedWorkout = workoutManager.completeWorkout();
  
  // Stop timers
  stopWorkoutTimer();
  stopRestTimer();
  
  // Hide modal
  const modal = bootstrap.Modal.getInstance(activeWorkoutModal);
  modal.hide();
  
  // Show success message
  showMessage('Workout completed and saved to your activity log!', 'success');
  
  // Reset current workout
  currentWorkoutId = null;
  
  // Update workout history display
  // To be implemented: updateWorkoutHistory();
}

/**
 * Handle discarding a workout
 */
function handleDiscardWorkout() {
  if (confirm('Are you sure you want to discard this workout? All progress will be lost.')) {
    // Discard the workout
    workoutManager.discardWorkout();
    
    // Stop timers
    stopWorkoutTimer();
    stopRestTimer();
    
    // Hide modal
    const modal = bootstrap.Modal.getInstance(activeWorkoutModal);
    modal.hide();
    
    // Reset current workout
    currentWorkoutId = null;
    
    // Show message
    showMessage('Workout discarded', 'info');
  }
}

/**
 * Start the workout timer
 */
function startWorkoutTimer() {
  // Clear any existing interval
  stopWorkoutTimer();
  
  // Update the display immediately
  updateWorkoutTimer();
  
  // Set up interval to update every second
  workoutTimerInterval = setInterval(updateWorkoutTimer, 1000);
}

/**
 * Update the workout timer display
 */
function updateWorkoutTimer() {
  if (!workoutStartTime) return;
  
  const now = new Date();
  const elapsedMs = now - workoutStartTime;
  const elapsedSeconds = Math.floor(elapsedMs / 1000);
  
  const minutes = Math.floor(elapsedSeconds / 60);
  const seconds = elapsedSeconds % 60;
  
  document.getElementById('workout-duration').textContent = 
    `${minutes}:${seconds.toString().padStart(2, '0')}`;
}

/**
 * Stop the workout timer
 */
function stopWorkoutTimer() {
  if (workoutTimerInterval) {
    clearInterval(workoutTimerInterval);
    workoutTimerInterval = null;
  }
}

/**
 * Toggle the rest timer
 */
function toggleRestTimer() {
  const timerBtn = document.querySelector('.rest-timer-btn');
  const timerDisplay = document.querySelector('.rest-timer-display');
  
  if (restTimerInterval) {
    // Stop timer
    stopRestTimer();
    timerBtn.textContent = 'Start Rest';
    timerBtn.classList.remove('btn-danger');
    timerBtn.classList.add('btn-outline-primary');
  } else {
    // Start 60 second timer
    let seconds = 60;
    timerDisplay.textContent = '01:00';
    timerBtn.textContent = 'Cancel';
    timerBtn.classList.remove('btn-outline-primary');
    timerBtn.classList.add('btn-danger');
    
    // Play start sound
    // playSound('timer-start');
    
    restTimerInterval = setInterval(() => {
      seconds--;
      if (seconds <= 0) {
        stopRestTimer();
        timerDisplay.textContent = 'Done!';
        timerBtn.textContent = 'Start Rest';
        timerBtn.classList.remove('btn-danger');
        timerBtn.classList.add('btn-outline-primary');
        // Play end sound
        // playSound('timer-end');
        
        // Reset to 00:00 after 3 seconds
        setTimeout(() => {
          if (!restTimerInterval) {
            timerDisplay.textContent = '00:00';
          }
        }, 3000);
      } else {
        const mins = Math.floor(seconds / 60);
        const secs = seconds % 60;
        timerDisplay.textContent = `${mins.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}`;
      }
    }, 1000);
  }
}

/**
 * Stop the rest timer
 */
function stopRestTimer() {
  if (restTimerInterval) {
    clearInterval(restTimerInterval);
    restTimerInterval = null;
  }
}

/**
 * Show a message to the user
 * @param {string} message - Message to display
 * @param {string} type - Type of message (success, danger, warning, info)
 */
function showMessage(message, type = 'info') {
  // Check if toast container exists, create if needed
  let toastContainer = document.querySelector('.toast-container');
  
  if (!toastContainer) {
    toastContainer = document.createElement('div');
    toastContainer.className = 'toast-container position-fixed bottom-0 end-0 p-3';
    document.body.appendChild(toastContainer);
  }
  
  // Create toast
  const toastId = `toast-${Date.now()}`;
  const toast = document.createElement('div');
  toast.className = `toast align-items-center text-white bg-${type}`;
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
  
  toastContainer.appendChild(toast);
  
  // Initialize and show the toast
  const bsToast = new bootstrap.Toast(toast, {
    autohide: true,
    delay: 5000
  });
  
  bsToast.show();
  
  // Remove toast from DOM after hidden
  toast.addEventListener('hidden.bs.toast', () => {
    toast.remove();
  });
}

// Initialize workout UI when document is loaded
document.addEventListener('DOMContentLoaded', initializeWorkoutUI);