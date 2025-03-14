/**
 * Workout and Routines Module for the Health & Fitness Tracker
 */

/**
 * WorkoutRoutine class for storing workout routines
 */
class WorkoutRoutine {
  /**
   * Create a new workout routine
   * @param {string} id - Unique identifier
   * @param {string} name - Routine name
   * @param {string} description - Routine description
   * @param {Array} exercises - List of exercises in the routine
   * @param {Date} createdAt - Date when the routine was created
   * @param {Date} lastUsed - Date when the routine was last used
   */
  constructor(id = null, name, description, exercises = [], createdAt = new Date(), lastUsed = null) {
    this.id = id || crypto.randomUUID();
    this.name = name;
    this.description = description;
    this.exercises = exercises;
    this.createdAt = createdAt;
    this.lastUsed = lastUsed;
  }

  /**
   * Add an exercise to the routine
   * @param {Object} exercise - Exercise details
   * @returns {boolean} Success indicator
   */
  addExercise(exercise) {
    if (!exercise.name) {
      return false;
    }
    
    // Generate ID if not provided
    if (!exercise.id) {
      exercise.id = crypto.randomUUID();
    }
    
    this.exercises.push(exercise);
    return true;
  }

  /**
   * Remove an exercise from the routine
   * @param {string} exerciseId - ID of the exercise to remove
   * @returns {boolean} Success indicator
   */
  removeExercise(exerciseId) {
    const initialLength = this.exercises.length;
    this.exercises = this.exercises.filter(ex => ex.id !== exerciseId);
    return initialLength !== this.exercises.length;
  }

  /**
   * Reorder exercises in the routine
   * @param {number} fromIndex - Original position
   * @param {number} toIndex - New position
   * @returns {boolean} Success indicator
   */
  reorderExercise(fromIndex, toIndex) {
    if (fromIndex < 0 || fromIndex >= this.exercises.length || 
        toIndex < 0 || toIndex >= this.exercises.length) {
      return false;
    }
    
    const [removed] = this.exercises.splice(fromIndex, 1);
    this.exercises.splice(toIndex, 0, removed);
    return true;
  }

  /**
   * Get a summary description of the routine
   * @param {number} maxExercises - Maximum number of exercises to include in summary
   * @returns {string} Summary description
   */
  getSummary(maxExercises = 3) {
    if (this.exercises.length === 0) {
      return "No exercises added yet";
    }
    
    const exerciseNames = this.exercises.slice(0, maxExercises).map(ex => ex.name);
    let summary = exerciseNames.join(", ");
    
    if (this.exercises.length > maxExercises) {
      summary += ` and ${this.exercises.length - maxExercises} more`;
    }
    
    return summary;
  }

  /**
   * Update the last used date to now
   */
  updateLastUsed() {
    this.lastUsed = new Date();
  }
}

/**
 * WorkoutManager class to manage workout routines and sessions
 */
class WorkoutManager {
  constructor() {
    this.routines = [];
    this.currentWorkout = null;
    this.exerciseDatabase = [
      // Default exercise library
      { id: "ex1", name: "Bench Press", category: "chest", equipment: "barbell" },
      { id: "ex2", name: "Squats", category: "legs", equipment: "barbell" },
      { id: "ex3", name: "Deadlift", category: "back", equipment: "barbell" },
      { id: "ex4", name: "Pull-ups", category: "back", equipment: "bodyweight" },
      { id: "ex5", name: "Push-ups", category: "chest", equipment: "bodyweight" },
      { id: "ex6", name: "Dumbbell Rows", category: "back", equipment: "dumbbell" },
      { id: "ex7", name: "Shoulder Press", category: "shoulders", equipment: "barbell" },
      { id: "ex8", name: "Lunges", category: "legs", equipment: "bodyweight" },
      { id: "ex9", name: "Bicep Curls", category: "arms", equipment: "dumbbell" },
      { id: "ex10", name: "Tricep Extensions", category: "arms", equipment: "cable" }
    ];
    
    // Load saved data
    this.loadFromLocalStorage();
  }

  /**
   * Add a new workout routine
   * @param {WorkoutRoutine} routine - The routine to add
   * @returns {boolean} Success indicator
   */
  addRoutine(routine) {
    if (!routine.name) {
      return false;
    }
    
    this.routines.push(routine);
    this.saveToLocalStorage();
    return true;
  }

  /**
   * Get all workout routines
   * @returns {Array} List of workout routines
   */
  getRoutines() {
    return [...this.routines];
  }

  /**
   * Get a specific routine by ID
   * @param {string} id - Routine ID
   * @returns {WorkoutRoutine|null} The routine or null if not found
   */
  getRoutineById(id) {
    return this.routines.find(routine => routine.id === id) || null;
  }

  /**
   * Update an existing routine
   * @param {string} id - ID of the routine to update
   * @param {Object} updates - Properties to update
   * @returns {boolean} Success indicator
   */
  updateRoutine(id, updates) {
    const index = this.routines.findIndex(routine => routine.id === id);
    if (index === -1) {
      return false;
    }
    
    // Apply updates to the routine
    this.routines[index] = { ...this.routines[index], ...updates };
    this.saveToLocalStorage();
    return true;
  }

  /**
   * Delete a routine
   * @param {string} id - ID of the routine to delete
   * @returns {boolean} Success indicator
   */
  deleteRoutine(id) {
    const initialLength = this.routines.length;
    this.routines = this.routines.filter(routine => routine.id !== id);
    const success = initialLength !== this.routines.length;
    
    if (success) {
      this.saveToLocalStorage();
    }
    
    return success;
  }

  /**
   * Start a new workout session
   * @param {WorkoutRoutine|null} routine - Optional routine to start with
   * @returns {Object} The current workout session
   */
  startWorkout(routine = null) {
    // Create a new workout session
    this.currentWorkout = {
      id: crypto.randomUUID(),
      startTime: new Date(),
      endTime: null,
      exercises: [],
      notes: "",
      completed: false
    };
    
    // If a routine was provided, copy its exercises to the workout
    if (routine) {
      routine.exercises.forEach(exercise => {
        this.addExerciseToWorkout({
          id: crypto.randomUUID(),
          name: exercise.name,
          sets: this.generateSetsFromTemplate(exercise),
          notes: exercise.notes || "",
          originalExerciseId: exercise.id
        });
      });
      
      // Update the last used date of the routine
      routine.updateLastUsed();
      this.updateRoutine(routine.id, { lastUsed: routine.lastUsed });
    }
    
    return this.currentWorkout;
  }

  /**
   * Generate sets based on an exercise template
   * @param {Object} exercise - Exercise template
   * @returns {Array} Generated sets
   */
  generateSetsFromTemplate(exercise) {
    // If the exercise has predefined sets, use those
    if (exercise.sets && exercise.sets.length > 0) {
      return exercise.sets.map(set => ({
        weight: set.weight || 0,
        reps: set.reps || 0,
        completed: false
      }));
    }
    
    // Otherwise generate default sets (3 sets of 10 reps)
    return [
      { weight: 0, reps: 10, completed: false },
      { weight: 0, reps: 10, completed: false },
      { weight: 0, reps: 10, completed: false }
    ];
  }

  /**
   * Add an exercise to the current workout
   * @param {Object} exercise - Exercise details
   * @returns {boolean} Success indicator
   */
  addExerciseToWorkout(exercise) {
    if (!this.currentWorkout) {
      return false;
    }
    
    // If no sets provided, add default sets
    if (!exercise.sets || !exercise.sets.length) {
      exercise.sets = [
        { weight: 0, reps: 10, completed: false },
        { weight: 0, reps: 10, completed: false },
        { weight: 0, reps: 10, completed: false }
      ];
    }
    
    this.currentWorkout.exercises.push(exercise);
    return true;
  }

  /**
   * Update an exercise in the current workout
   * @param {string} exerciseId - ID of the exercise to update
   * @param {Object} updates - Fields to update
   * @returns {boolean} Success indicator
   */
  updateExerciseInWorkout(exerciseId, updates) {
    if (!this.currentWorkout) {
      return false;
    }
    
    const index = this.currentWorkout.exercises.findIndex(ex => ex.id === exerciseId);
    if (index === -1) {
      return false;
    }
    
    this.currentWorkout.exercises[index] = { ...this.currentWorkout.exercises[index], ...updates };
    return true;
  }

  /**
   * Update a set in the current workout
   * @param {string} exerciseId - ID of the exercise containing the set
   * @param {number} setIndex - Index of the set to update
   * @param {Object} updates - Fields to update (weight, reps, completed)
   * @returns {boolean} Success indicator
   */
  updateSetInWorkout(exerciseId, setIndex, updates) {
    if (!this.currentWorkout) {
      return false;
    }
    
    const exercise = this.currentWorkout.exercises.find(ex => ex.id === exerciseId);
    if (!exercise || setIndex < 0 || setIndex >= exercise.sets.length) {
      return false;
    }
    
    exercise.sets[setIndex] = { ...exercise.sets[setIndex], ...updates };
    return true;
  }

  /**
   * Add a new set to an exercise in the current workout
   * @param {string} exerciseId - ID of the exercise
   * @param {Object} set - Set details (weight, reps)
   * @returns {boolean} Success indicator
   */
  addSetToExercise(exerciseId, set = { weight: 0, reps: 0, completed: false }) {
    if (!this.currentWorkout) {
      return false;
    }
    
    const exercise = this.currentWorkout.exercises.find(ex => ex.id === exerciseId);
    if (!exercise) {
      return false;
    }
    
    exercise.sets.push(set);
    return true;
  }

  /**
   * Remove a set from an exercise in the current workout
   * @param {string} exerciseId - ID of the exercise
   * @param {number} setIndex - Index of the set to remove
   * @returns {boolean} Success indicator
   */
  removeSetFromExercise(exerciseId, setIndex) {
    if (!this.currentWorkout) {
      return false;
    }
    
    const exercise = this.currentWorkout.exercises.find(ex => ex.id === exerciseId);
    if (!exercise || setIndex < 0 || setIndex >= exercise.sets.length) {
      return false;
    }
    
    exercise.sets.splice(setIndex, 1);
    return true;
  }

  /**
   * Complete the current workout
   * @param {string} notes - Optional notes about the workout
   * @returns {Object} The completed workout
   */
  completeWorkout(notes = "") {
    if (!this.currentWorkout) {
      return null;
    }
    
    this.currentWorkout.endTime = new Date();
    this.currentWorkout.notes = notes;
    this.currentWorkout.completed = true;
    
    // Calculate duration in seconds
    const durationMs = this.currentWorkout.endTime - this.currentWorkout.startTime;
    this.currentWorkout.duration = Math.floor(durationMs / 1000);
    
    // Calculate total volume (weight * reps across all sets)
    let totalVolume = 0;
    let completedSets = 0;
    let totalSets = 0;
    
    this.currentWorkout.exercises.forEach(exercise => {
      exercise.sets.forEach(set => {
        totalSets++;
        if (set.completed) {
          completedSets++;
          totalVolume += set.weight * set.reps;
        }
      });
    });
    
    this.currentWorkout.totalVolume = totalVolume;
    this.currentWorkout.completionRate = totalSets > 0 ? (completedSets / totalSets) : 0;
    
    // Convert the workout to an activity for the main tracker
    const activity = new Activity(
      "Workout: " + (this.currentWorkout.routineName || "Custom"),
      this.estimateCaloriesBurned(this.currentWorkout),
      Math.floor(this.currentWorkout.duration / 60), // Convert seconds to minutes
      "weights",
      this.currentWorkout.startTime
    );
    
    // Add workout details to the activity
    activity.workoutDetails = {
      exercises: this.currentWorkout.exercises.map(ex => ({
        name: ex.name,
        sets: ex.sets.filter(set => set.completed).length,
        totalSets: ex.sets.length,
        volume: ex.sets.reduce((sum, set) => sum + (set.weight * set.reps), 0)
      })),
      totalVolume: this.currentWorkout.totalVolume,
      duration: this.currentWorkout.duration
    };
    
    // Add the activity to the fitness tracker
    if (window.fitnessTracker) {
      window.fitnessTracker.addActivity(activity);
    }
    
    // Store the completed workout in the workout history
    this.saveWorkoutToHistory(this.currentWorkout);
    
    // Clear the current workout
    const completedWorkout = { ...this.currentWorkout };
    this.currentWorkout = null;
    
    return completedWorkout;
  }

  /**
   * Discard the current workout session without saving
   */
  discardWorkout() {
    this.currentWorkout = null;
  }

  /**
   * Estimate calories burned during a workout
   * @param {Object} workout - The workout to estimate calories for
   * @returns {number} Estimated calories burned
   */
  estimateCaloriesBurned(workout) {
    if (!workout) {
      return 0;
    }
    
    // Simple estimation based on duration
    // A more accurate model would consider intensity, weight, and exercise types
    const minutes = Math.floor(workout.duration / 60);
    
    // Average calorie burn rate for weight training: ~5 calories per minute
    return minutes * 5;
  }

  /**
   * Find exercises in the database by name or category
   * @param {string} query - Search query
   * @returns {Array} Matching exercises
   */
  findExercises(query) {
    if (!query || query.trim() === "") {
      return this.exerciseDatabase;
    }
    
    query = query.toLowerCase().trim();
    
    return this.exerciseDatabase.filter(exercise => 
      exercise.name.toLowerCase().includes(query) || 
      exercise.category.toLowerCase().includes(query)
    );
  }

  /**
   * Add a custom exercise to the database
   * @param {Object} exercise - Exercise details
   * @returns {boolean} Success indicator
   */
  addCustomExercise(exercise) {
    if (!exercise.name) {
      return false;
    }
    
    // Generate ID if not provided
    if (!exercise.id) {
      exercise.id = crypto.randomUUID();
    }
    
    // Set default category if not provided
    if (!exercise.category) {
      exercise.category = "custom";
    }
    
    this.exerciseDatabase.push(exercise);
    this.saveToLocalStorage();
    return true;
  }

  /**
   * Calculate barbell plate configuration
   * @param {number} targetWeight - The target weight to achieve
   * @param {number} barWeight - Weight of the barbell (default: 45lbs)
   * @param {Array} availablePlates - Available plate weights in descending order
   * @returns {Array} Plates to add to each side of the bar
   */
  calculatePlatesNeeded(targetWeight, barWeight = 45, availablePlates = [45, 35, 25, 10, 5, 2.5]) {
    // Sort plates in descending order
    availablePlates.sort((a, b) => b - a);
    
    // Weight that needs to be added with plates (divide by 2 for each side)
    const plateWeight = Math.max(0, targetWeight - barWeight) / 2;
    
    const plates = [];
    let remainingWeight = plateWeight;
    
    // Greedy algorithm to select plates
    for (const plate of availablePlates) {
      while (remainingWeight >= plate) {
        plates.push(plate);
        remainingWeight -= plate;
      }
    }
    
    return plates;
  }

  /**
   * Save workout history to localStorage
   * @param {Object} workout - Completed workout to save
   */
  saveWorkoutToHistory(workout) {
    const history = JSON.parse(localStorage.getItem('workoutHistory') || '[]');
    history.push(workout);
    localStorage.setItem('workoutHistory', JSON.stringify(history));
  }

  /**
   * Get workout history
   * @param {number} limit - Maximum number of workouts to return
   * @returns {Array} Workout history
   */
  getWorkoutHistory(limit = 0) {
    const history = JSON.parse(localStorage.getItem('workoutHistory') || '[]');
    
    // Sort by date, newest first
    history.sort((a, b) => new Date(b.startTime) - new Date(a.startTime));
    
    return limit > 0 ? history.slice(0, limit) : history;
  }

  /**
   * Get the current workout session
   * @returns {Object|null} Current workout or null if none active
   */
  getCurrentWorkout() {
    return this.currentWorkout;
  }

  /**
   * Save data to localStorage
   */
  saveToLocalStorage() {
    // Save routines
    localStorage.setItem('workoutRoutines', JSON.stringify(this.routines));
    
    // Save exercise database
    localStorage.setItem('exerciseDatabase', JSON.stringify(this.exerciseDatabase));
  }

  /**
   * Load data from localStorage
   */
  loadFromLocalStorage() {
    // Load routines
    const savedRoutines = localStorage.getItem('workoutRoutines');
    if (savedRoutines) {
      try {
        const routines = JSON.parse(savedRoutines);
        
        // Convert plain objects to WorkoutRoutine instances
        this.routines = routines.map(r => {
          const routine = new WorkoutRoutine(
            r.id, 
            r.name, 
            r.description, 
            r.exercises, 
            new Date(r.createdAt), 
            r.lastUsed ? new Date(r.lastUsed) : null
          );
          return routine;
        });
      } catch (error) {
        console.error('Error loading workout routines', error);
        this.routines = [];
      }
    }
    
    // Load exercise database
    const savedExercises = localStorage.getItem('exerciseDatabase');
    if (savedExercises) {
      try {
        this.exerciseDatabase = JSON.parse(savedExercises);
      } catch (error) {
        console.error('Error loading exercise database', error);
        // Keep default exercise database
      }
    }
  }
}

// Create a global instance of the workout manager
window.workoutManager = new WorkoutManager();

/**
 * Functions for the workout UI
 */

/**
 * Initialize the workout UI
 */
function initWorkoutUI() {
  // Add event listeners for workout-related buttons
  document.addEventListener('DOMContentLoaded', function() {
    // Workout plan creation
    const createWorkoutBtn = document.querySelector('#workoutModal .btn-primary');
    if (createWorkoutBtn) {
      createWorkoutBtn.addEventListener('click', handleCreateWorkoutPlan);
    }
    
    // Start workout button
    const workoutButtons = document.querySelectorAll('.start-workout-btn');
    workoutButtons.forEach(btn => {
      btn.addEventListener('click', function() {
        const routineId = this.getAttribute('data-routine-id');
        startWorkoutSession(routineId);
      });
    });
    
    // Create empty workout button
    const emptyWorkoutBtn = document.getElementById('create-empty-workout');
    if (emptyWorkoutBtn) {
      emptyWorkoutBtn.addEventListener('click', function() {
        startWorkoutSession();
      });
    }
    
    // Update workout plans list
    updateWorkoutPlansList();
  });
}

/**
 * Handle creating a new workout plan
 */
function handleCreateWorkoutPlan() {
  const form = document.getElementById('workout-form');
  if (!form) return;
  
  const name = form.querySelector('#workout-name').value;
  const description = form.querySelector('#workout-description').value;
  
  if (!name) {
    showMessage('Please enter a workout name', 'danger');
    return;
  }
  
  const routine = new WorkoutRoutine(null, name, description);
  
  if (window.workoutManager.addRoutine(routine)) {
    // Close the modal
    const modal = bootstrap.Modal.getInstance(document.getElementById('workoutModal'));
    if (modal) {
      modal.hide();
    }
    
    // Update the workout plans list
    updateWorkoutPlansList();
    
    // Reset the form
    form.reset();
    
    showMessage('Workout plan created successfully', 'success');
  } else {
    showMessage('Failed to create workout plan', 'danger');
  }
}

/**
 * Update the workout plans list in the UI
 */
function updateWorkoutPlansList() {
  const container = document.getElementById('workout-list');
  const noPlansMessage = document.getElementById('no-workout-plans');
  
  if (!container) return;
  
  const routines = window.workoutManager.getRoutines();
  
  // Show/hide the no plans message
  if (noPlansMessage) {
    noPlansMessage.style.display = routines.length > 0 ? 'none' : 'block';
  }
  
  // Clear the container
  container.innerHTML = '';
  
  // Add routines to the container
  routines.forEach(routine => {
    const element = createWorkoutPlanElement(routine);
    container.appendChild(element);
  });
  
  // Add event listeners to start workout buttons
  const startButtons = container.querySelectorAll('.start-workout-btn');
  startButtons.forEach(btn => {
    btn.addEventListener('click', function() {
      const routineId = this.getAttribute('data-routine-id');
      startWorkoutSession(routineId);
    });
  });
}

/**
 * Create a workout plan element for display
 * @param {WorkoutRoutine} routine - The routine to create an element for
 * @returns {HTMLElement} The created element
 */
function createWorkoutPlanElement(routine) {
  const exerciseCount = routine.exercises.length;
  const lastUsedText = routine.lastUsed ? `Last used: ${formatDate(routine.lastUsed)}` : 'Never used';
  
  const col = document.createElement('div');
  col.className = 'col-md-6 mb-3';
  
  col.innerHTML = `
    <div class="card h-100">
      <div class="card-body">
        <h5 class="card-title">${routine.name}</h5>
        <p class="card-text">${routine.description || 'No description'}</p>
        <div class="text-muted small mb-2">
          ${exerciseCount} exercise${exerciseCount !== 1 ? 's' : ''} · ${lastUsedText}
        </div>
        <div class="d-flex justify-content-between align-items-center">
          <button class="btn btn-sm btn-outline-primary start-workout-btn" data-routine-id="${routine.id}">
            Start Workout
          </button>
          <div class="dropdown">
            <button class="btn btn-sm btn-outline-secondary dropdown-toggle" type="button" data-bs-toggle="dropdown">
              Actions
            </button>
            <ul class="dropdown-menu dropdown-menu-end">
              <li><a class="dropdown-item edit-routine-btn" href="#" data-routine-id="${routine.id}">Edit</a></li>
              <li><a class="dropdown-item delete-routine-btn" href="#" data-routine-id="${routine.id}">Delete</a></li>
            </ul>
          </div>
        </div>
      </div>
    </div>
  `;
  
  // Add event listener for edit and delete buttons
  const editBtn = col.querySelector('.edit-routine-btn');
  const deleteBtn = col.querySelector('.delete-routine-btn');
  
  if (editBtn) {
    editBtn.addEventListener('click', function(e) {
      e.preventDefault();
      const routineId = this.getAttribute('data-routine-id');
      editWorkoutPlan(routineId);
    });
  }
  
  if (deleteBtn) {
    deleteBtn.addEventListener('click', function(e) {
      e.preventDefault();
      const routineId = this.getAttribute('data-routine-id');
      deleteWorkoutPlan(routineId);
    });
  }
  
  return col;
}

/**
 * Edit a workout plan
 * @param {string} routineId - ID of the routine to edit
 */
function editWorkoutPlan(routineId) {
  const routine = window.workoutManager.getRoutineById(routineId);
  if (!routine) {
    showMessage('Workout plan not found', 'danger');
    return;
  }
  
  // Open the edit modal (implement this)
  // ...
  
  showMessage('Edit functionality not yet implemented', 'info');
}

/**
 * Delete a workout plan
 * @param {string} routineId - ID of the routine to delete
 */
function deleteWorkoutPlan(routineId) {
  if (confirm('Are you sure you want to delete this workout plan?')) {
    if (window.workoutManager.deleteRoutine(routineId)) {
      updateWorkoutPlansList();
      showMessage('Workout plan deleted successfully', 'success');
    } else {
      showMessage('Failed to delete workout plan', 'danger');
    }
  }
}

/**
 * Start a workout session
 * @param {string|null} routineId - Optional ID of routine to use
 */
function startWorkoutSession(routineId = null) {
  let routine = null;
  
  if (routineId) {
    routine = window.workoutManager.getRoutineById(routineId);
    if (!routine) {
      showMessage('Workout plan not found', 'danger');
      return;
    }
  }
  
  // Start a new workout
  const workout = window.workoutManager.startWorkout(routine);
  
  // Create the workout view
  createWorkoutSessionView(workout, routine);
}

/**
 * Create the workout session view
 * @param {Object} workout - The current workout
 * @param {WorkoutRoutine|null} routine - The routine being used, if any
 */
function createWorkoutSessionView(workout, routine = null) {
  // Create a full-screen view for the workout session
  const sessionView = document.createElement('div');
  sessionView.id = 'workout-session-view';
  sessionView.className = 'container-fluid bg-light';
  
  // Header with title and close button
  sessionView.innerHTML = `
    <div class="row py-3 bg-primary text-white">
      <div class="col-2">
        <button id="discard-workout-btn" class="btn btn-outline-light btn-sm">
          <i class="bi bi-x-lg"></i>
        </button>
      </div>
      <div class="col-8 text-center">
        <h5 class="mb-0">${routine ? routine.name : 'Custom Workout'}</h5>
      </div>
      <div class="col-2 text-end">
        <button id="finish-workout-btn" class="btn btn-success btn-sm">
          <i class="bi bi-check-lg"></i>
        </button>
      </div>
    </div>
    
    <div class="rest-timer d-none">
      <i class="bi bi-stopwatch me-1"></i>
      <span id="timer-display">00:00</span>
    </div>
    
    <div id="workout-content" class="p-3">
      <div id="exercises-container">
        <!-- Exercises will be added here -->
      </div>
      
      <div class="mt-4">
        <button id="add-exercise-btn" class="btn btn-primary w-100">
          <i class="bi bi-plus-lg me-2"></i>Add Exercise
        </button>
      </div>
    </div>
  `;
  
  // Add the view to the body
  document.body.appendChild(sessionView);
  
  // Add exercises from the workout
  const exercisesContainer = sessionView.querySelector('#exercises-container');
  
  if (workout.exercises.length > 0) {
    workout.exercises.forEach(exercise => {
      const exerciseElement = createExerciseElement(exercise);
      exercisesContainer.appendChild(exerciseElement);
    });
  } else {
    exercisesContainer.innerHTML = `
      <div class="alert alert-info">
        <i class="bi bi-info-circle me-2"></i>
        No exercises added yet. Click "Add Exercise" to get started.
      </div>
    `;
  }
  
  // Add event listeners
  sessionView.querySelector('#discard-workout-btn').addEventListener('click', function() {
    if (confirm('Are you sure you want to discard this workout?')) {
      window.workoutManager.discardWorkout();
      sessionView.remove();
    }
  });
  
  sessionView.querySelector('#finish-workout-btn').addEventListener('click', function() {
    const completedWorkout = window.workoutManager.completeWorkout();
    if (completedWorkout) {
      showMessage('Workout completed successfully', 'success');
      sessionView.remove();
    }
  });
  
  sessionView.querySelector('#add-exercise-btn').addEventListener('click', function() {
    showExerciseSelector(workout);
  });
  
  // Setup timer functionality
  setupRestTimer();
}

/**
 * Create an exercise element for the workout session
 * @param {Object} exercise - The exercise to create an element for
 * @returns {HTMLElement} The created element
 */
function createExerciseElement(exercise) {
  const exerciseElement = document.createElement('div');
  exerciseElement.className = 'card mb-3 exercise-card';
  exerciseElement.setAttribute('data-exercise-id', exercise.id);
  
  exerciseElement.innerHTML = `
    <div class="card-header bg-secondary text-white d-flex justify-content-between align-items-center">
      <h6 class="mb-0">${exercise.name}</h6>
      <div>
        <button class="btn btn-sm btn-light rest-timer-btn" title="Start Rest Timer">
          <i class="bi bi-stopwatch"></i>
        </button>
        <button class="btn btn-sm btn-light add-set-btn" title="Add Set">
          <i class="bi bi-plus-lg"></i>
        </button>
      </div>
    </div>
    <div class="card-body">
      <div class="sets-container">
        <!-- Set rows will be added here -->
      </div>
      <div class="mt-3 text-center">
        <button class="btn btn-sm btn-outline-primary rest-timer-btn">
          <i class="bi bi-stopwatch me-1"></i>Rest Timer
        </button>
      </div>
    </div>
  `;
  
  // Add sets
  const setsContainer = exerciseElement.querySelector('.sets-container');
  
  exercise.sets.forEach((set, index) => {
    const setElement = createSetElement(exercise.id, index, set);
    setsContainer.appendChild(setElement);
  });
  
  // Add event listeners
  exerciseElement.querySelector('.add-set-btn').addEventListener('click', function() {
    const newSet = { weight: 0, reps: 0, completed: false };
    if (window.workoutManager.addSetToExercise(exercise.id, newSet)) {
      const setIndex = exercise.sets.length - 1;
      const setElement = createSetElement(exercise.id, setIndex, newSet);
      setsContainer.appendChild(setElement);
    }
  });
  
  const restTimerBtns = exerciseElement.querySelectorAll('.rest-timer-btn');
  restTimerBtns.forEach(btn => {
    btn.addEventListener('click', function() {
      startRestTimer();
    });
  });
  
  return exerciseElement;
}

/**
 * Create a set element for an exercise
 * @param {string} exerciseId - ID of the parent exercise
 * @param {number} setIndex - Index of the set
 * @param {Object} set - The set data (weight, reps, completed)
 * @returns {HTMLElement} The created set element
 */
function createSetElement(exerciseId, setIndex, set) {
  const setElement = document.createElement('div');
  setElement.className = 'set-row d-flex align-items-center mb-2';
  setElement.setAttribute('data-set-index', setIndex);
  
  setElement.innerHTML = `
    <div class="set-number me-2">${setIndex + 1}</div>
    
    <div class="me-2">
      <input type="number" class="form-control form-control-sm weight-input" 
        value="${set.weight}" min="0" step="5" inputmode="numeric" pattern="[0-9]*"
        placeholder="lbs">
      <div class="text-muted small text-center previous-weight">Last: 135 lbs</div>
    </div>
    
    <div class="me-2">
      <input type="number" class="form-control form-control-sm reps-input" 
        value="${set.reps}" min="0" inputmode="numeric" pattern="[0-9]*"
        placeholder="reps">
    </div>
    
    <div class="ms-auto">
      <input type="checkbox" class="form-check-input complete-set-checkbox" 
        ${set.completed ? 'checked' : ''}>
    </div>
  `;
  
  // Add event listeners
  const weightInput = setElement.querySelector('.weight-input');
  const repsInput = setElement.querySelector('.reps-input');
  const completedCheckbox = setElement.querySelector('.complete-set-checkbox');
  
  weightInput.addEventListener('change', function() {
    const weight = parseFloat(this.value) || 0;
    window.workoutManager.updateSetInWorkout(exerciseId, setIndex, { weight });
  });
  
  repsInput.addEventListener('change', function() {
    const reps = parseInt(this.value) || 0;
    window.workoutManager.updateSetInWorkout(exerciseId, setIndex, { reps });
  });
  
  completedCheckbox.addEventListener('change', function() {
    const completed = this.checked;
    window.workoutManager.updateSetInWorkout(exerciseId, setIndex, { completed });
    
    // Update the UI to reflect completion status
    if (completed) {
      setElement.classList.add('bg-light');
    } else {
      setElement.classList.remove('bg-light');
    }
  });
  
  return setElement;
}

/**
 * Show the exercise selector modal
 * @param {Object} workout - The current workout
 */
function showExerciseSelector(workout) {
  // Check if modal already exists
  let modal = document.getElementById('exercise-selector-modal');
  
  if (!modal) {
    // Create the modal
    modal = document.createElement('div');
    modal.id = 'exercise-selector-modal';
    modal.className = 'modal fade';
    modal.tabIndex = -1;
    modal.setAttribute('aria-hidden', 'true');
    
    modal.innerHTML = `
      <div class="modal-dialog modal-dialog-scrollable">
        <div class="modal-content">
          <div class="modal-header">
            <h5 class="modal-title">Add Exercise</h5>
            <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
          </div>
          <div class="modal-body">
            <div class="mb-3">
              <input type="text" class="form-control" id="exercise-search" placeholder="Search exercises...">
            </div>
            
            <ul class="nav nav-tabs" id="exercise-tabs" role="tablist">
              <li class="nav-item" role="presentation">
                <button class="nav-link active" id="all-exercises-tab" data-bs-toggle="tab" 
                  data-bs-target="#all-exercises" type="button" role="tab" aria-selected="true">
                  All
                </button>
              </li>
              <li class="nav-item" role="presentation">
                <button class="nav-link" id="chest-exercises-tab" data-bs-toggle="tab" 
                  data-bs-target="#chest-exercises" type="button" role="tab" aria-selected="false">
                  Chest
                </button>
              </li>
              <li class="nav-item" role="presentation">
                <button class="nav-link" id="back-exercises-tab" data-bs-toggle="tab" 
                  data-bs-target="#back-exercises" type="button" role="tab" aria-selected="false">
                  Back
                </button>
              </li>
              <li class="nav-item" role="presentation">
                <button class="nav-link" id="legs-exercises-tab" data-bs-toggle="tab" 
                  data-bs-target="#legs-exercises" type="button" role="tab" aria-selected="false">
                  Legs
                </button>
              </li>
              <li class="nav-item" role="presentation">
                <button class="nav-link" id="arms-exercises-tab" data-bs-toggle="tab" 
                  data-bs-target="#arms-exercises" type="button" role="tab" aria-selected="false">
                  Arms
                </button>
              </li>
            </ul>
            
            <div class="tab-content mt-3" id="exercise-tabs-content">
              <div class="tab-pane fade show active" id="all-exercises" role="tabpanel">
                <div class="exercise-list" id="all-exercises-list">
                  <!-- Exercises will be added here -->
                  <div class="text-center py-3">Loading exercises...</div>
                </div>
              </div>
              
              <div class="tab-pane fade" id="chest-exercises" role="tabpanel">
                <div class="exercise-list" id="chest-exercises-list">
                  <!-- Chest exercises will be added here -->
                </div>
              </div>
              
              <div class="tab-pane fade" id="back-exercises" role="tabpanel">
                <div class="exercise-list" id="back-exercises-list">
                  <!-- Back exercises will be added here -->
                </div>
              </div>
              
              <div class="tab-pane fade" id="legs-exercises" role="tabpanel">
                <div class="exercise-list" id="legs-exercises-list">
                  <!-- Legs exercises will be added here -->
                </div>
              </div>
              
              <div class="tab-pane fade" id="arms-exercises" role="tabpanel">
                <div class="exercise-list" id="arms-exercises-list">
                  <!-- Arms exercises will be added here -->
                </div>
              </div>
            </div>
          </div>
          <div class="modal-footer">
            <button type="button" class="btn btn-outline-secondary" data-bs-dismiss="modal">Cancel</button>
            <button type="button" class="btn btn-primary" id="add-custom-exercise-btn">Create Custom</button>
          </div>
        </div>
      </div>
    `;
    
    document.body.appendChild(modal);
  }
  
  // Load exercises into the modal
  loadExercisesIntoSelector();
  
  // Initialize the Bootstrap modal
  const modalInstance = new bootstrap.Modal(modal);
  modalInstance.show();
  
  // Add event listener for search input
  const searchInput = modal.querySelector('#exercise-search');
  searchInput.addEventListener('input', function() {
    const query = this.value.trim();
    filterExercises(query);
  });
  
  // Add event listener for custom exercise button
  const customExerciseBtn = modal.querySelector('#add-custom-exercise-btn');
  customExerciseBtn.addEventListener('click', function() {
    modalInstance.hide();
    showCustomExerciseModal(workout);
  });
}

/**
 * Load exercises into the exercise selector
 */
function loadExercisesIntoSelector() {
  const allExercisesList = document.getElementById('all-exercises-list');
  const chestExercisesList = document.getElementById('chest-exercises-list');
  const backExercisesList = document.getElementById('back-exercises-list');
  const legsExercisesList = document.getElementById('legs-exercises-list');
  const armsExercisesList = document.getElementById('arms-exercises-list');
  
  // Clear the lists
  allExercisesList.innerHTML = '';
  chestExercisesList.innerHTML = '';
  backExercisesList.innerHTML = '';
  legsExercisesList.innerHTML = '';
  armsExercisesList.innerHTML = '';
  
  // Get all exercises
  const exercises = window.workoutManager.findExercises('');
  
  // Group exercises by category
  const chestExercises = exercises.filter(ex => ex.category === 'chest');
  const backExercises = exercises.filter(ex => ex.category === 'back');
  const legsExercises = exercises.filter(ex => ex.category === 'legs');
  const armsExercises = exercises.filter(ex => ex.category === 'arms');
  
  // Add exercises to the lists
  exercises.forEach(exercise => {
    const element = createExerciseSelectorItem(exercise);
    allExercisesList.appendChild(element);
  });
  
  chestExercises.forEach(exercise => {
    const element = createExerciseSelectorItem(exercise);
    chestExercisesList.appendChild(element);
  });
  
  backExercises.forEach(exercise => {
    const element = createExerciseSelectorItem(exercise);
    backExercisesList.appendChild(element);
  });
  
  legsExercises.forEach(exercise => {
    const element = createExerciseSelectorItem(exercise);
    legsExercisesList.appendChild(element);
  });
  
  armsExercises.forEach(exercise => {
    const element = createExerciseSelectorItem(exercise);
    armsExercisesList.appendChild(element);
  });
  
  // Add messages if lists are empty
  if (chestExercises.length === 0) {
    chestExercisesList.innerHTML = '<div class="text-muted text-center py-3">No chest exercises found</div>';
  }
  
  if (backExercises.length === 0) {
    backExercisesList.innerHTML = '<div class="text-muted text-center py-3">No back exercises found</div>';
  }
  
  if (legsExercises.length === 0) {
    legsExercisesList.innerHTML = '<div class="text-muted text-center py-3">No legs exercises found</div>';
  }
  
  if (armsExercises.length === 0) {
    armsExercisesList.innerHTML = '<div class="text-muted text-center py-3">No arms exercises found</div>';
  }
}

/**
 * Create an exercise item for the selector
 * @param {Object} exercise - The exercise
 * @returns {HTMLElement} The created element
 */
function createExerciseSelectorItem(exercise) {
  const element = document.createElement('div');
  element.className = 'exercise-item';
  element.setAttribute('data-exercise-id', exercise.id);
  
  element.innerHTML = `
    <div class="d-flex justify-content-between align-items-center">
      <div>
        <div class="fw-bold">${exercise.name}</div>
        <div class="text-muted small">${exercise.equipment || 'No equipment'}</div>
      </div>
      <button class="btn btn-sm btn-outline-primary add-to-workout-btn">Add</button>
    </div>
  `;
  
  // Add event listener for the add button
  element.querySelector('.add-to-workout-btn').addEventListener('click', function() {
    addExerciseToWorkout(exercise);
    
    // Close the modal
    const modal = bootstrap.Modal.getInstance(document.getElementById('exercise-selector-modal'));
    if (modal) {
      modal.hide();
    }
  });
  
  return element;
}

/**
 * Filter exercises in the selector by query
 * @param {string} query - Search query
 */
function filterExercises(query) {
  const exercises = window.workoutManager.findExercises(query);
  const allExercisesList = document.getElementById('all-exercises-list');
  
  // Clear the list
  allExercisesList.innerHTML = '';
  
  if (exercises.length === 0) {
    allExercisesList.innerHTML = '<div class="text-muted text-center py-3">No exercises found</div>';
    return;
  }
  
  // Add matching exercises to the list
  exercises.forEach(exercise => {
    const element = createExerciseSelectorItem(exercise);
    allExercisesList.appendChild(element);
  });
}

/**
 * Show modal for creating a custom exercise
 * @param {Object} workout - The current workout
 */
function showCustomExerciseModal(workout) {
  // Check if modal already exists
  let modal = document.getElementById('custom-exercise-modal');
  
  if (!modal) {
    // Create the modal
    modal = document.createElement('div');
    modal.id = 'custom-exercise-modal';
    modal.className = 'modal fade';
    modal.tabIndex = -1;
    modal.setAttribute('aria-hidden', 'true');
    
    modal.innerHTML = `
      <div class="modal-dialog">
        <div class="modal-content">
          <div class="modal-header">
            <h5 class="modal-title">Create Custom Exercise</h5>
            <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
          </div>
          <div class="modal-body">
            <form id="custom-exercise-form">
              <div class="mb-3">
                <label for="custom-exercise-name" class="form-label">Exercise Name</label>
                <input type="text" class="form-control" id="custom-exercise-name" required>
              </div>
              
              <div class="mb-3">
                <label for="custom-exercise-category" class="form-label">Category</label>
                <select class="form-select" id="custom-exercise-category">
                  <option value="chest">Chest</option>
                  <option value="back">Back</option>
                  <option value="legs">Legs</option>
                  <option value="shoulders">Shoulders</option>
                  <option value="arms">Arms</option>
                  <option value="core">Core</option>
                  <option value="cardio">Cardio</option>
                  <option value="other">Other</option>
                </select>
              </div>
              
              <div class="mb-3">
                <label for="custom-exercise-equipment" class="form-label">Equipment</label>
                <select class="form-select" id="custom-exercise-equipment">
                  <option value="barbell">Barbell</option>
                  <option value="dumbbell">Dumbbell</option>
                  <option value="machine">Machine</option>
                  <option value="cable">Cable</option>
                  <option value="bodyweight">Bodyweight</option>
                  <option value="other">Other</option>
                </select>
              </div>
            </form>
          </div>
          <div class="modal-footer">
            <button type="button" class="btn btn-outline-secondary" data-bs-dismiss="modal">Cancel</button>
            <button type="button" class="btn btn-primary" id="save-custom-exercise-btn">Save & Add</button>
          </div>
        </div>
      </div>
    `;
    
    document.body.appendChild(modal);
  }
  
  // Initialize the Bootstrap modal
  const modalInstance = new bootstrap.Modal(modal);
  modalInstance.show();
  
  // Add event listener for the save button
  const saveBtn = modal.querySelector('#save-custom-exercise-btn');
  saveBtn.addEventListener('click', function() {
    const name = modal.querySelector('#custom-exercise-name').value;
    const category = modal.querySelector('#custom-exercise-category').value;
    const equipment = modal.querySelector('#custom-exercise-equipment').value;
    
    if (!name) {
      alert('Please enter an exercise name');
      return;
    }
    
    // Create and add the custom exercise
    const exercise = {
      id: crypto.randomUUID(),
      name,
      category,
      equipment
    };
    
    if (window.workoutManager.addCustomExercise(exercise)) {
      // Add the exercise to the current workout
      addExerciseToWorkout(exercise);
      
      // Close the modal
      modalInstance.hide();
      
      showMessage('Custom exercise added to your workout', 'success');
    } else {
      showMessage('Failed to create custom exercise', 'danger');
    }
  });
}

/**
 * Add an exercise to the current workout
 * @param {Object} exercise - The exercise to add
 */
function addExerciseToWorkout(exercise) {
  const workout = window.workoutManager.getCurrentWorkout();
  if (!workout) {
    showMessage('No active workout session', 'danger');
    return;
  }
  
  // Create exercise entry for the workout
  const workoutExercise = {
    id: crypto.randomUUID(),
    name: exercise.name,
    originalExerciseId: exercise.id,
    notes: "",
    sets: [
      { weight: 0, reps: 0, completed: false },
      { weight: 0, reps: 0, completed: false },
      { weight: 0, reps: 0, completed: false }
    ]
  };
  
  if (window.workoutManager.addExerciseToWorkout(workoutExercise)) {
    // Get the exercises container
    const exercisesContainer = document.getElementById('exercises-container');
    
    // Remove any "no exercises" message
    const noExercisesMessage = exercisesContainer.querySelector('.alert');
    if (noExercisesMessage) {
      noExercisesMessage.remove();
    }
    
    // Create and add the exercise element
    const exerciseElement = createExerciseElement(workoutExercise);
    exercisesContainer.appendChild(exerciseElement);
    
    showMessage(`Added ${exercise.name} to your workout`, 'success');
  } else {
    showMessage('Failed to add exercise to workout', 'danger');
  }
}

/**
 * Setup the rest timer functionality
 */
function setupRestTimer() {
  const timerDisplay = document.getElementById('timer-display');
  const timerContainer = document.querySelector('.rest-timer');
  
  if (!timerDisplay || !timerContainer) return;
  
  let timerInterval = null;
  let seconds = 0;
  
  // Format seconds as MM:SS
  function formatTime(totalSeconds) {
    const mins = Math.floor(totalSeconds / 60);
    const secs = totalSeconds % 60;
    return `${mins.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}`;
  }
  
  // Update the timer display
  function updateTimerDisplay() {
    timerDisplay.textContent = formatTime(seconds);
  }
  
  // Start the timer
  window.startRestTimer = function(duration = 90) {
    // Clear any existing timer
    if (timerInterval) {
      clearInterval(timerInterval);
    }
    
    // Reset and start
    seconds = duration;
    updateTimerDisplay();
    timerContainer.classList.remove('d-none');
    
    timerInterval = setInterval(() => {
      seconds--;
      
      if (seconds <= 0) {
        clearInterval(timerInterval);
        
        // Play notification sound
        const audio = new Audio('data:audio/wav;base64,//uQRAAAAWMSLwUIYAAsYkXgoQwAEaYLWfkWgAI0wWs/ItAAAGDgYtAgAyN+QWaAAihwMWm4G8QQRDiMcCBcH3Cc+CDv/7xA4Tvh9Rz/y8QADBwMWgQAZG/ILNAARQ4GLTcDeIIIhxGOBAuD7hOfBB3/94gcJ3w+o5/5eIAIAAAVwWgQAVQ2ORaIQwEMAJiDg95G4nQL7mQVWI6GwRcfsZAcsKkJvxgxEjzFUgfHoSQ9Qq7KNwqHwuB13MA4a1q/DmBrHgPcmjiGoh//EwC5nGPEmS4RcfkVKOhJf+WOgoxJclFz3kgn//dBA+ya1GhurNn8zb//9NNutNuhz31f////9vt///z+IdAEAAAK4LQIAKobHItEIYCGAExBwe8jcToF9zIKrEdDYIuP2MgOWFSE34wYiR5iqQPj0JIeoVdlG4VD4XA67mAcNa1fhzA1jwHuTRxDUQ//iYBczjHiTJcIuPyKlHQkv/LHQUYkuSi57yQT//uggfZNajQ3Vm//Lm//GT//GMzL//Fj///vt///+LwAAAKCLQIAKobHItEIYCGAExBwe8jcToF9zIKrEdDYIuP2MgOWFSE34wYiR5iqQPj0JIeoVdlG4VD4XA67mAcNa1fhzA1jwHuTRxDUQ//iYBczjHiTJcIuPyKlHQkv/LHQUYkuSi57yQT//uggfZNajQ3Vm//Lm///GMzL//Fj////vt///+LwAAAKCLQIAKobHItEIYCGAExBwe8jcToF9zIKrEdDYIuP2MgOWFSE34wYiR5iqQPj0JIeoVdlG4VD4XA67mAcNa1fhzA1jwHuTRxDUQ//iYBczjHiTJcIuPyKlHQkv/LHQUYkuSi57yQT//uggfZNajQ3Vm//Lm///GMzL//Fj////vt///+LwAAAKA=');
        audio.play();
        
        // Flash the timer
        let flashCount = 0;
        const flashInterval = setInterval(() => {
          timerContainer.classList.toggle('bg-danger');
          flashCount++;
          
          if (flashCount > 5) {
            clearInterval(flashInterval);
            timerContainer.classList.remove('bg-danger');
            timerContainer.classList.add('d-none');
          }
        }, 500);
      } else {
        updateTimerDisplay();
      }
    }, 1000);
  };
  
  // Allow clicking on the timer to dismiss it
  timerContainer.addEventListener('click', function() {
    if (timerInterval) {
      clearInterval(timerInterval);
    }
    timerContainer.classList.add('d-none');
  });
}

/**
 * Format date helper function
 * @param {Date|string} date - Date to format
 * @returns {string} Formatted date
 */
function formatDate(date) {
  if (!date) return 'N/A';
  
  if (typeof date === 'string') {
    date = new Date(date);
  }
  
  return date.toLocaleDateString('en-US', {
    year: 'numeric',
    month: 'short',
    day: 'numeric'
  });
}

// Initialize the workout UI when the script loads
initWorkoutUI();