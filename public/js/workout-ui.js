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
let workoutStartTime = null;
let restTimerInterval = null; // Declaration kept to prevent errors, but functionality removed

/**
 * Initialize workout UI with enhanced error handling and cleanup
 */
function initializeWorkoutUI() {
  try {
    console.log("Initializing workout UI...");
    
    // Track registered handlers for cleanup
    const registeredHandlers = new Map();
    
    // Enhanced safe function to add event listeners with tracking
    const safeAddEventListener = (selector, event, handler) => {
      try {
        const element = typeof selector === 'string' ? document.querySelector(selector) : selector;
        if (!element) {
          console.warn(`Element not found for selector: ${typeof selector === 'string' ? selector : 'DOM Element'}`);
          return false;
        }
        
        // Generate a unique key for this handler
        const handlerKey = `${event}_${generateUUID()}`;
        
        // Store reference to original handler for cleanup
        registeredHandlers.set(handlerKey, { element, event, handler });
        
        // Remove any existing listeners first to prevent duplicates
        // Note: This only works if the handler is exactly the same function reference
        try {
          element.removeEventListener(event, handler);
        } catch (removeError) {
          console.warn(`Could not remove previous listener: ${removeError.message}`);
          // Continue anyway - the old handler might not exist
        }
        
        // Add the event listener
        element.addEventListener(event, handler);
        console.log(`Added ${event} listener to ${typeof selector === 'string' ? selector : 'DOM Element'}`);
        return true;
      } catch (error) {
        console.error(`Error adding event listener to ${typeof selector === 'string' ? selector : 'DOM Element'}:`, error);
        return false;
      }
    };
    
    // Setup global cleanup for page unload to prevent memory leaks
    const cleanupFunction = () => {
      try {
        console.log("Cleaning up workout UI resources...");
        
        // Stop any running timers
        stopWorkoutTimer();
        
        // Clean up registered event handlers
        registeredHandlers.forEach(({ element, event, handler }) => {
          try {
            if (element && element.removeEventListener) {
              element.removeEventListener(event, handler);
            }
          } catch (e) {
            console.warn(`Could not remove event listener during cleanup: ${e.message}`);
          }
        });
        
        // Clear the handlers map
        registeredHandlers.clear();
        
        console.log("Workout UI cleanup completed");
      } catch (error) {
        console.error("Error during workout UI cleanup:", error);
      }
    };
    
    // Register the cleanup function for page unload
    window.addEventListener('beforeunload', cleanupFunction);
    
    // Extra safety measure: if the workout modal closes, ensure timers are stopped
    document.querySelectorAll('.modal').forEach(modal => {
      modal.addEventListener('hidden.bs.modal', () => {
        // Only stop timers if this is the active workout modal
        if (modal.id === 'activeWorkoutModal') {
          console.log("Active workout modal closed - ensuring timers are stopped");
          stopWorkoutTimer();
        }
      });
    });
    
    // Connect main UI buttons for workout management
    const createEmptyWorkoutBtn = document.getElementById('create-empty-workout');
    if (createEmptyWorkoutBtn) {
      safeAddEventListener(createEmptyWorkoutBtn, 'click', () => {
        // Start an empty workout without a template
        startWorkout(null);
      });
    }
    
    // Rest timer input initialization removed as per requirements
    
    // Set up event listeners for workout creation safely
    const createWorkoutBtn = document.getElementById('create-workout-btn');
    if (createWorkoutBtn) {
      safeAddEventListener(createWorkoutBtn, 'click', handleCreateWorkout);
    }
    
    // Set up event listeners for exercise management
    const addExerciseBtn = document.getElementById('add-exercise-btn');
    if (addExerciseBtn) {
      safeAddEventListener(addExerciseBtn, 'click', handleAddExercise);
    }
    
    const addSetBtn = document.getElementById('add-set-btn');
    if (addSetBtn) {
      safeAddEventListener(addSetBtn, 'click', addNewSet);
    }
    
    const addWorkoutExerciseBtn = document.getElementById('add-workout-exercise-btn');
    if (addWorkoutExerciseBtn) {
      safeAddEventListener(addWorkoutExerciseBtn, 'click', () => {
        try {
          // Clear exercise form
          const exerciseForm = document.getElementById('exercise-form');
          if (exerciseForm) {
            exerciseForm.reset();
          }
          
          // Reset sets
          initializeExerciseSets();
          
          // Show exercise modal
          if (exerciseModal) {
            const exerciseModalObj = new bootstrap.Modal(exerciseModal);
            exerciseModalObj.show();
          }
        } catch (error) {
          console.error("Error showing exercise modal:", error);
          showToast("There was an error with the exercise form. Please try again.", "danger");
        }
      });
    }
    
    // Set up event listeners for workout completion
    const completeWorkoutBtn = document.getElementById('complete-workout-btn');
    if (completeWorkoutBtn) {
      safeAddEventListener(completeWorkoutBtn, 'click', handleCompleteWorkout);
    }
    
    const discardWorkoutBtn = document.getElementById('discard-workout-btn');
    if (discardWorkoutBtn) {
      safeAddEventListener(discardWorkoutBtn, 'click', handleDiscardWorkout);
    }
    
    // Initialize workout library and routines
    initializeWorkoutLibrary();
    
    console.log("Workout UI initialization complete");
  } catch (error) {
    console.error("Error initializing workout UI:", error);
    showToast("Error initializing workout interface. Please refresh the page.", "danger");
  }
}

/**
 * Initialize workout library and routines
 */
function initializeWorkoutLibrary() {
  try {
    // Set up library selection if the element exists
    const exerciseLibrary = document.querySelector('.exercise-library');
    if (exerciseLibrary) {
      exerciseLibrary.addEventListener('click', handleExerciseLibrarySelection);
    }
    
    // Initialize exercise sets
    initializeExerciseSets();
    
    // Load and display routines
    loadWorkoutRoutines();
    
    console.log("Workout library initialized");
  } catch (error) {
    console.error("Error initializing workout library:", error);
  }
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
  showToast(`Workout plan "${name}" created successfully!`, 'success');
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
 * Initialize exercise sets in the exercise modal
 */
function initializeExerciseSets() {
  try {
    const setsContainer = document.getElementById('exercise-sets-container');
    if (!setsContainer) return;
    
    // Clear existing sets
    setsContainer.innerHTML = '';
    
    // Add initial set
    addNewSet();
    
    console.log("Exercise sets initialized");
  } catch (error) {
    console.error("Error initializing exercise sets:", error);
  }
}

/**
 * Add a new set to the exercise form
 */
function addNewSet() {
  try {
    const setsContainer = document.getElementById('exercise-sets-container');
    if (!setsContainer) return;
    
    const setIndex = setsContainer.children.length;
    
    // Create set row
    const setRow = document.createElement('div');
    setRow.className = 'd-flex align-items-center exercise-set mb-2';
    setRow.dataset.setIndex = setIndex.toString();
    
    setRow.innerHTML = `
      <div class="set-number me-2" style="width: 30px">${setIndex + 1}</div>
      <div class="flex-grow-1 row g-0">
        <div class="col-4 pe-1">
          <input type="number" class="form-control form-control-sm set-weight" placeholder="lbs" inputmode="numeric">
        </div>
        <div class="col-4 px-1">
          <input type="number" class="form-control form-control-sm set-reps" placeholder="reps" inputmode="numeric">
        </div>
        <div class="col-4 ps-1 d-flex align-items-center">
          <button class="btn btn-sm btn-outline-danger remove-set-btn">
            <i class="bi bi-dash-circle"></i>
          </button>
        </div>
      </div>
    `;
    
    // Add event listener to remove button
    const removeButton = setRow.querySelector('.remove-set-btn');
    removeButton.addEventListener('click', (event) => {
      removeSet(event.currentTarget);
    });
    
    setsContainer.appendChild(setRow);
  } catch (error) {
    console.error("Error adding exercise set:", error);
  }
}

/**
 * Remove a set from the exercise form
 * @param {HTMLElement} button - The remove button that was clicked
 */
function removeSet(button) {
  try {
    // Find the parent set row
    const setRow = button.closest('.exercise-set');
    if (!setRow) return;
    
    const setsContainer = document.getElementById('exercise-sets-container');
    if (!setsContainer) return;
    
    // Don't remove if it's the only set
    if (setsContainer.children.length <= 1) {
      showToast("At least one set is required", "warning");
      return;
    }
    
    // Remove the set
    setRow.remove();
    
    // Renumber remaining sets
    Array.from(setsContainer.children).forEach((row, index) => {
      row.dataset.setIndex = index.toString();
      row.querySelector('.set-number').textContent = (index + 1).toString();
    });
  } catch (error) {
    console.error("Error removing exercise set:", error);
  }
}

/**
 * Handle exercise selection from library
 * @param {Event} event - Click event
 */
function handleExerciseLibrarySelection(event) {
  try {
    // Find the clicked exercise item
    const exerciseItem = event.target.closest('.exercise-library-item');
    if (!exerciseItem) return;
    
    // Get exercise details
    const exerciseName = exerciseItem.dataset.name;
    const exerciseType = exerciseItem.dataset.type;
    const exerciseEquipment = exerciseItem.dataset.equipment;
    
    // Fill exercise form
    const nameInput = document.getElementById('exercise-name');
    const typeSelect = document.getElementById('exercise-type');
    if (nameInput) nameInput.value = exerciseName;
    if (typeSelect) {
      Array.from(typeSelect.options).forEach(option => {
        if (option.value === exerciseType) option.selected = true;
      });
    }
    
    const equipmentInput = document.getElementById('exercise-equipment');
    if (equipmentInput) equipmentInput.value = exerciseEquipment || '';
    
    // Close the dropdown if open
    const dropdown = exerciseItem.closest('.dropdown-menu');
    if (dropdown) {
      const bsDropdown = bootstrap.Dropdown.getInstance(dropdown);
      if (bsDropdown) bsDropdown.hide();
    }
  } catch (error) {
    console.error("Error selecting exercise from library:", error);
  }
}

/**
 * Handle adding an exercise to the workout
 */
function handleAddExercise() {
  try {
    // Get exercise form data
    const form = document.getElementById('exercise-form');
    if (!form) return;
    
    const nameInput = document.getElementById('exercise-name');
    const typeSelect = document.getElementById('exercise-type');
    
    const name = nameInput ? nameInput.value.trim() : '';
    const type = typeSelect ? typeSelect.value : '';
    
    // Validate required fields
    if (!name || !type) {
      if (!name) nameInput.classList.add('is-invalid');
      if (!type) typeSelect.classList.add('is-invalid');
      return;
    }
    
    // Get all sets data
    const sets = [];
    const setElements = document.querySelectorAll('.exercise-set');
    let valid = true;
    
    setElements.forEach(setElement => {
      const weightInput = setElement.querySelector('.set-weight');
      const repsInput = setElement.querySelector('.set-reps');
      
      const weight = weightInput ? parseFloat(weightInput.value) : 0;
      const reps = repsInput ? parseInt(repsInput.value, 10) : 0;
      
      // Validate set data
      if (isNaN(weight) || weight <= 0) {
        weightInput.classList.add('is-invalid');
        valid = false;
      }
      
      if (isNaN(reps) || reps <= 0) {
        repsInput.classList.add('is-invalid');
        valid = false;
      }
      
      if (valid) {
        sets.push({ weight, reps });
      }
    });
    
    if (!valid) return;
    
    // Get the workout
    const workout = workoutManager.getWorkoutById(currentWorkoutId);
    if (!workout) {
      showToast("Workout not found", "danger");
      return;
    }
    
    // Create exercise object
    const exercise = {
      id: currentExerciseId || generateUUID(),
      name,
      type,
      sets
    };
    
    // Add or update exercise
    if (currentExerciseId) {
      workout.updateExercise(currentExerciseId, exercise);
      showToast(`Exercise "${name}" updated`, "success");
    } else {
      workout.addExercise(exercise);
      showToast(`Exercise "${name}" added to workout`, "success");
    }
    
    // Reset form
    form.reset();
    currentExerciseId = null;
    
    // Close modal
    const modal = bootstrap.Modal.getInstance(exerciseModal);
    if (modal) modal.hide();
    
    // Update exercises display
    renderWorkoutExercises(workout);
  } catch (error) {
    console.error("Error adding exercise:", error);
    showToast("Error adding exercise", "danger");
  }
}

/**
 * Edit an exercise in the current workout
 * @param {string} exerciseId - ID of the exercise to edit
 */
function editExercise(exerciseId) {
  try {
    // Get the workout
    const workout = workoutManager.getWorkoutById(currentWorkoutId);
    if (!workout) return;
    
    // Find the exercise
    const exercise = workout.exercises.find(ex => ex.id === exerciseId);
    if (!exercise) return;
    
    // Set current exercise ID
    currentExerciseId = exerciseId;
    
    // Fill form with exercise data
    const nameInput = document.getElementById('exercise-name');
    const typeSelect = document.getElementById('exercise-type');
    
    if (nameInput) nameInput.value = exercise.name;
    if (typeSelect) {
      Array.from(typeSelect.options).forEach(option => {
        if (option.value === exercise.type) option.selected = true;
      });
    }
    
    // Clear and populate sets
    const setsContainer = document.getElementById('exercise-sets-container');
    if (setsContainer) {
      setsContainer.innerHTML = '';
      
      exercise.sets.forEach((set, index) => {
        const setRow = document.createElement('div');
        setRow.className = 'd-flex align-items-center exercise-set mb-2';
        setRow.dataset.setIndex = index.toString();
        
        setRow.innerHTML = `
          <div class="set-number me-2" style="width: 30px">${index + 1}</div>
          <div class="flex-grow-1 row g-0">
            <div class="col-4 pe-1">
              <input type="number" class="form-control form-control-sm set-weight" placeholder="lbs" inputmode="numeric" value="${set.weight}">
            </div>
            <div class="col-4 px-1">
              <input type="number" class="form-control form-control-sm set-reps" placeholder="reps" inputmode="numeric" value="${set.reps}">
            </div>
            <div class="col-4 ps-1 d-flex align-items-center">
              <button class="btn btn-sm btn-outline-danger remove-set-btn">
                <i class="bi bi-dash-circle"></i>
              </button>
            </div>
          </div>
        `;
        
        // Add event listener to remove button
        const removeButton = setRow.querySelector('.remove-set-btn');
        removeButton.addEventListener('click', (event) => {
          removeSet(event.currentTarget);
        });
        
        setsContainer.appendChild(setRow);
      });
      
      // If no sets, add one empty set
      if (exercise.sets.length === 0) {
        addNewSet();
      }
    }
    
    // Show modal
    const modal = new bootstrap.Modal(exerciseModal);
    modal.show();
  } catch (error) {
    console.error("Error editing exercise:", error);
    showToast("Error editing exercise", "danger");
  }
}

/**
 * Remove an exercise from the current workout
 * @param {string} exerciseId - ID of the exercise to remove
 */
function removeExercise(exerciseId) {
  try {
    // Get the workout
    const workout = workoutManager.getWorkoutById(currentWorkoutId);
    if (!workout) return;
    
    // Find the exercise
    const exercise = workout.exercises.find(ex => ex.id === exerciseId);
    if (!exercise) return;
    
    // Confirm removal
    if (confirm(`Are you sure you want to remove "${exercise.name}" from this workout?`)) {
      workout.removeExercise(exerciseId);
      showToast(`Exercise "${exercise.name}" removed`, "success");
      renderWorkoutExercises(workout);
    }
  } catch (error) {
    console.error("Error removing exercise:", error);
    showToast("Error removing exercise", "danger");
  }
}

/**
 * Edit a workout routine
 * @param {string} routineId - ID of the routine to edit
 */
function editWorkout(routineId) {
  try {
    // Get the routine
    const routine = workoutManager.getRoutineById(routineId);
    if (!routine) return;
    
    // Fill form with routine data
    const nameInput = document.getElementById('workout-name');
    const descInput = document.getElementById('workout-description');
    
    if (nameInput) nameInput.value = routine.name;
    if (descInput) descInput.value = routine.description || '';
    
    // Show modal
    const modal = new bootstrap.Modal(workoutModal);
    modal.show();
    
    // Update form and button text
    const form = document.getElementById('workout-form');
    if (form) {
      form.dataset.mode = 'edit';
      form.dataset.routineId = routineId;
    }
    
    const submitButton = document.getElementById('create-workout-btn');
    if (submitButton) {
      submitButton.textContent = 'Update Workout Plan';
      submitButton.removeEventListener('click', handleCreateWorkout);
      submitButton.addEventListener('click', () => {
        const name = nameInput.value.trim();
        const description = descInput.value.trim();
        
        if (!name) {
          nameInput.classList.add('is-invalid');
          return;
        }
        
        // Update routine
        routine.name = name;
        routine.description = description;
        workoutManager.updateRoutine(routine);
        
        // Hide modal
        const modalInstance = bootstrap.Modal.getInstance(workoutModal);
        modalInstance.hide();
        
        // Reset form
        form.reset();
        form.dataset.mode = 'create';
        delete form.dataset.routineId;
        submitButton.textContent = 'Create Workout Plan';
        
        // Reload routines
        loadWorkoutRoutines();
        
        // Show success message
        showToast(`Workout plan "${name}" updated successfully!`, 'success');
      }, { once: true });
    }
  } catch (error) {
    console.error("Error editing workout:", error);
    showToast("Error editing workout plan", "danger");
  }
}

/**
 * Delete a workout routine
 * @param {string} routineId - ID of the routine to delete
 */
function deleteWorkout(routineId) {
  try {
    // Get the routine
    const routine = workoutManager.getRoutineById(routineId);
    if (!routine) return;
    
    // Confirm deletion
    if (confirm(`Are you sure you want to delete the "${routine.name}" workout plan?`)) {
      workoutManager.removeRoutine(routineId);
      showToast(`Workout plan "${routine.name}" deleted`, "success");
      loadWorkoutRoutines();
    }
  } catch (error) {
    console.error("Error deleting workout:", error);
    showToast("Error deleting workout plan", "danger");
  }
}

/**
 * Handle completing a workout
 */
function handleCompleteWorkout() {
  try {
    // Get the workout
    const workout = workoutManager.getWorkoutById(currentWorkoutId);
    if (!workout) return;
    
    // Check if any exercises were added
    if (workout.exercises.length === 0) {
      if (!confirm('You haven\'t added any exercises to this workout. Are you sure you want to complete it?')) {
        return;
      }
    }
    
    // Complete the workout
    const completedWorkout = workoutManager.completeWorkout(currentWorkoutId);
    if (!completedWorkout) {
      showToast("Error completing workout", "danger");
      return;
    }
    
    // Get workout name for display
    const workoutName = document.getElementById('active-workout-name').textContent;
    
    // Create activity from workout
    const activity = new Activity(
      workoutName,
      completedWorkout.caloriesBurned || 0,
      completedWorkout.duration || 0,
      'weights',
      new Date(),
      completedWorkout.id,
      null,
      null,
      {
        category: 'weights',
        exercises: completedWorkout.exercises.map(ex => ({
          name: ex.name,
          type: ex.type,
          sets: ex.sets
        }))
      }
    );
    
    // Add to fitness tracker
    const fitnessTracker = new FitnessTracker();
    fitnessTracker.loadFromLocalStorage();
    fitnessTracker.addActivity(activity);
    fitnessTracker.saveToLocalStorage();
    
    // Stop timer
    stopWorkoutTimer();
    
    // Hide modal
    const modal = bootstrap.Modal.getInstance(activeWorkoutModal);
    modal.hide();
    
    // Update UI
    loadWorkoutRoutines();
    
    // Reset state
    currentWorkoutId = null;
    currentExerciseId = null;
    workoutStartTime = null;
    
    // Show success message
    showToast(`Workout "${workoutName}" completed successfully!`, 'success');
    
    // Update dashboard if it exists
    if (typeof updateDashboard === 'function') {
      updateDashboard();
    }
  } catch (error) {
    console.error("Error completing workout:", error);
    showToast("Error completing workout", "danger");
  }
}

/**
 * Handle discarding a workout
 */
function handleDiscardWorkout() {
  try {
    // Get the workout
    const workout = workoutManager.getWorkoutById(currentWorkoutId);
    if (!workout) return;
    
    // Confirm discard
    if (confirm('Are you sure you want to discard this workout? All progress will be lost.')) {
      // Discard the workout
      workoutManager.discardWorkout(currentWorkoutId);
      
      // Stop timer
      stopWorkoutTimer();
      
      // Hide modal
      const modal = bootstrap.Modal.getInstance(activeWorkoutModal);
      modal.hide();
      
      // Reset state
      currentWorkoutId = null;
      currentExerciseId = null;
      workoutStartTime = null;
      
      // Show message
      showToast('Workout discarded', 'warning');
    }
  } catch (error) {
    console.error("Error discarding workout:", error);
    showToast("Error discarding workout", "danger");
  }
}

/**
 * Render the exercises for a workout
 * @param {Object} workout - The workout to render exercises for
 */
function renderWorkoutExercises(workout) {
  try {
    const exercisesContainer = document.getElementById('workout-exercises-container');
    if (!exercisesContainer || !workout) return;
    
    exercisesContainer.innerHTML = '';
    
    if (workout.exercises.length === 0) {
      exercisesContainer.innerHTML = `
        <div class="text-center py-4">
          <p class="text-muted">No exercises added yet. Add your first exercise to get started.</p>
        </div>
      `;
      return;
    }
    
    // Create exercise cards
    workout.exercises.forEach(exercise => {
      const card = document.createElement('div');
      card.className = 'card mb-3';
      
      let setsHtml = '';
      
      if (exercise.sets && exercise.sets.length > 0) {
        setsHtml = `
          <div class="mt-2 small">
            <div class="d-flex fw-bold text-muted mb-1">
              <div style="width: 60px">Set</div>
              <div style="width: 60px">Weight</div>
              <div style="width: 60px">Reps</div>
            </div>
            ${exercise.sets.map((set, idx) => `
              <div class="d-flex mb-1">
                <div style="width: 60px">${idx + 1}</div>
                <div style="width: 60px">${set.weight} lbs</div>
                <div style="width: 60px">${set.reps}</div>
              </div>
            `).join('')}
          </div>
        `;
      }
      
      card.innerHTML = `
        <div class="card-body">
          <div class="d-flex justify-content-between align-items-start">
            <h5 class="card-title">${exercise.name}</h5>
            <div>
              <button class="btn btn-sm btn-outline-primary edit-exercise-btn me-1" data-id="${exercise.id}">
                <i class="bi bi-pencil"></i>
              </button>
              <button class="btn btn-sm btn-outline-danger remove-exercise-btn" data-id="${exercise.id}">
                <i class="bi bi-trash"></i>
              </button>
            </div>
          </div>
          <p class="card-text text-muted mb-1">${exercise.type}</p>
          ${setsHtml}
        </div>
      `;
      
      // Add event listeners
      card.querySelector('.edit-exercise-btn').addEventListener('click', () => editExercise(exercise.id));
      card.querySelector('.remove-exercise-btn').addEventListener('click', () => removeExercise(exercise.id));
      
      exercisesContainer.appendChild(card);
    });
  } catch (error) {
    console.error("Error rendering workout exercises:", error);
  }
}

/**
 * Start the workout timer with comprehensive error handling
 */
function startWorkoutTimer() {
  try {
    if (workoutTimerInterval) {
      clearInterval(workoutTimerInterval);
    }
    
    workoutStartTime = workoutStartTime || new Date();
    
    workoutTimerInterval = setInterval(() => {
      try {
        const now = new Date();
        const elapsed = Math.floor((now - workoutStartTime) / 1000);
        
        const hours = Math.floor(elapsed / 3600);
        const minutes = Math.floor((elapsed % 3600) / 60);
        const seconds = elapsed % 60;
        
        const timerElement = document.getElementById('workout-timer');
        if (timerElement) {
          timerElement.textContent = `${hours.toString().padStart(2, '0')}:${minutes.toString().padStart(2, '0')}:${seconds.toString().padStart(2, '0')}`;
        }
        
        // Update workout duration in the workout object
        if (currentWorkoutId) {
          const workout = workoutManager.getWorkoutById(currentWorkoutId);
          if (workout) {
            workout.duration = elapsed;
          }
        }
      } catch (timerError) {
        console.error("Error updating workout timer:", timerError);
        // Attempt recovery by continuing interval
      }
    }, 1000);
  } catch (error) {
    console.error("Error starting workout timer:", error);
    showToast("Error starting workout timer", "warning");
  }
}

/**
 * Stop the workout timer
 */
function stopWorkoutTimer() {
  try {
    if (workoutTimerInterval) {
      clearInterval(workoutTimerInterval);
      workoutTimerInterval = null;
      console.log("Workout timer stopped");
    }
  } catch (error) {
    console.error("Error stopping workout timer:", error);
  }
}

// Initialize workout UI when DOM is loaded
document.addEventListener('DOMContentLoaded', initializeWorkoutUI);